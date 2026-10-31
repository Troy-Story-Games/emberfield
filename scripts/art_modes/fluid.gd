class_name ArtFluid
extends ArtModeBase
## Fluid — smoke-like wisps carried by a slowly drifting curl field; touch stirs it.

## The flow is the curl of a stream function built from three warped, rotating
## octaves of vortex cells plus a rising current (see _build_field).
const CELL := 620.0
## Per octave: (frequency multiple, weight, starting rotation).
const OCTAVES: Array[Vector3] = [Vector3(1.0, 1.0, 0.0), Vector3(2.13, 0.55, 0.9), Vector3(4.37, 0.28, 2.1)]
## Domain warp strength, as a fraction of the cell size.
const WARP := 0.3
const FLOW_SPEED := 130.0
## Upward drift, in px/s, so smoke rises and meanders instead of circling in place.
const RISE := 55.0
## How quickly particles settle back onto the ambient flow (per second).
const EASE := 1.6
const STIR_RADIUS := 170.0
const STIR_CARRY := 0.65
const STIR_SWIRL := 420.0
const PUFF := 520.0
## Spacing of the precomputed field grid, in pixels.
const GRID := 48.0

var _time: float = 0.0
var _scale: float = 1.0
var _speed: float = 1.0
var _stir: float = 1.0
var _grid: PackedVector2Array = PackedVector2Array()
var _psi: PackedFloat32Array = PackedFloat32Array()


func begin_frame(_anchor: Vector2, dt: float, _positions: PackedVector2Array = PackedVector2Array()) -> void:
    _scale = settings.fluid_scale if settings else 1.0
    _speed = settings.fluid_speed if settings else 1.0
    _stir = settings.fluid_stir if settings else 1.0
    _time += dt * _speed


## Samples the stream function psi on a grid one cell larger than the screen on every
## side, then takes its curl with central differences: v = (dpsi/dy, -dpsi/dx). Any psi
## gives a divergence-free flow, so particles never bunch up, and the grid keeps all the
## trig out of the per-particle loop.
func _build_field(cols: int, rows: int, min_x: float, min_y: float) -> void:
    var pc := cols + 2
    var pr := rows + 2
    _psi.resize(pc * pr)
    var k := TAU / (CELL * _scale)
    var speed := FLOW_SPEED * _speed
    var t := _time
    var warp := CELL * _scale * WARP
    var kw := k * 0.5
    # Rising current that slowly sways: psi = rise * (x cos a + y sin a).
    var sway := sin(t * 0.13) * 0.45
    var rise_x := RISE * _speed * cos(sway)
    var rise_y := RISE * _speed * sin(sway)
    # Per-octave constants, hoisted out of the grid loop.
    var octaves := OCTAVES.size()
    var oct_k := PackedFloat32Array()
    var oct_amp := PackedFloat32Array()
    var oct_cos := PackedFloat32Array()
    var oct_sin := PackedFloat32Array()
    var oct_pu := PackedFloat32Array()
    var oct_pv := PackedFloat32Array()
    for o in octaves:
        var oct: Vector3 = OCTAVES[o]
        var ko := k * oct.x
        var r := oct.z + t * (0.05 + 0.03 * float(o)) * (1.0 if o % 2 == 0 else -1.0)
        oct_k.append(ko)
        oct_amp.append(speed * oct.y / ko)
        oct_cos.append(cos(r))
        oct_sin.append(sin(r))
        oct_pu.append(t * (0.31 + 0.11 * float(o)))
        oct_pv.append(-t * (0.23 + 0.07 * float(o)) + 1.7 * float(o))
    for oy in pr:
        for ox in pc:
            var x := min_x + float(ox - 1) * GRID - GRID
            var y := min_y + float(oy - 1) * GRID - GRID
            # Domain warp bends the cells so no regular grid of eddies shows through.
            var wx := x + warp * sin(y * kw + t * 0.21)
            var wy := y + warp * sin(x * kw * 1.3 - t * 0.17 + 1.1)
            var psi := rise_x * x + rise_y * y
            for o in octaves:
                var c := oct_cos[o]
                var sn := oct_sin[o]
                var ko := oct_k[o]
                var u := wx * c + wy * sn
                var v := -wx * sn + wy * c
                psi += oct_amp[o] * sin(ko * u + oct_pu[o]) * sin(ko * v + oct_pv[o])
            _psi[oy * pc + ox] = psi
    _grid.resize(cols * rows)
    var inv := 1.0 / (2.0 * GRID)
    for gy in rows:
        for gx in cols:
            var c := (gy + 1) * pc + gx + 1
            var dpsi_dy := (_psi[c + pc] - _psi[c - pc]) * inv
            var dpsi_dx := (_psi[c + 1] - _psi[c - 1]) * inv
            _grid[gy * cols + gx] = Vector2(dpsi_dy, -dpsi_dx)


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    var min_x := bounds.position.x
    var min_y := bounds.position.y
    var w := bounds.size.x
    var h := bounds.size.y
    var cols := int(ceil(w / GRID)) + 2
    var rows := int(ceil(h / GRID)) + 2
    _build_field(cols, rows, min_x, min_y)
    var ease := 1.0 - exp(-EASE * dt)

    var stirring := touch_active
    var radius := STIR_RADIUS * sqrt(_stir)
    var inv_r2 := 1.0 / (radius * radius)
    var carry := STIR_CARRY * minf(_stir, 1.5)
    var carried := touch_velocity * carry
    var swirl := STIR_SWIRL * _stir * dt
    var puff := PUFF * _stir if just_pressed else 0.0
    var inv_cell := 1.0 / GRID
    var grid := _grid
    for i in positions.size():
        var pos := positions[i]
        var fx := (pos.x - min_x) * inv_cell
        var fy := (pos.y - min_y) * inv_cell
        var ix := clampi(int(fx), 0, cols - 2)
        var iy := clampi(int(fy), 0, rows - 2)
        var tx := fx - float(ix)
        var ty := fy - float(iy)
        var base := iy * cols + ix
        var top := grid[base].lerp(grid[base + 1], tx)
        var bottom := grid[base + cols].lerp(grid[base + cols + 1], tx)
        var field := top.lerp(bottom, ty)

        var vel := velocities[i].lerp(field, ease)
        if stirring:
            var d := pos - anchor
            var q := 1.0 - d.length_squared() * inv_r2
            if q > 0.0:
                # Wake: nearby smoke picks up the finger's motion, plus a soft eddy.
                var f := q * q
                var dist := maxf(d.length(), 1.0)
                vel = vel.lerp(carried, f * 0.5)
                vel += Vector2(-d.y, d.x) * (swirl * f / dist)
                vel += d * (puff * f / dist)
        velocities[i] = vel

        # Wrap at the edges so smoke never piles up against a wall.
        pos += vel * dt
        pos.x = min_x + fposmod(pos.x - min_x, w)
        pos.y = min_y + fposmod(pos.y - min_y, h)
        positions[i] = pos
