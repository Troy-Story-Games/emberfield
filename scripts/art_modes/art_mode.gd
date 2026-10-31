class_name ArtModeBase
extends RefCounted
## Base class for art-mode force functions.
## Positions/velocities use viewport pixel coordinates.

const IDLE_DRIFT := 110.0
const IDLE_DRIFT_ACTIVE := 35.0
const IDLE_SWIRL := 95.0
const IDLE_LATTICE_SPRING := 140.0
const IDLE_LATTICE_CELL := 48.0
const IDLE_BOIDS_ALIGN := 55.0
const IDLE_BOIDS_COHERE := 10.0
const IDLE_BOIDS_SEPARATE := 160.0
const IDLE_BOIDS_SEP_DIST := 55.0
const IDLE_BOIDS_WANDER := 0.35
const IDLE_RAIN := 220.0
const IDLE_RAIN_JITTER := 40.0

var bounds: Rect2 = Rect2(0, 0, 1080, 1920)
var touch_active: bool = false
var just_pressed: bool = false
var just_released: bool = false
var touch_velocity: Vector2 = Vector2.ZERO
var settings: AppSettings

var _idle_time: float = 0.0
var _idle_velocities: PackedVector2Array = PackedVector2Array()
var _idle_positions: PackedVector2Array = PackedVector2Array()
var _lattice_offset: Vector2 = Vector2.ZERO


func setup(viewport_size: Vector2) -> void:
    bounds = Rect2(Vector2.ZERO, viewport_size)


func bind_settings(s: AppSettings) -> void:
    settings = s


func begin_idle_frame(
    dt: float,
    velocities: PackedVector2Array = PackedVector2Array(),
    positions: PackedVector2Array = PackedVector2Array()
) -> void:
    _idle_time += dt
    _idle_velocities = velocities
    _idle_positions = positions
    _lattice_offset = Vector2(
        sin(_idle_time * 0.35) * 28.0,
        cos(_idle_time * 0.27) * 22.0
    )


func begin_frame(_anchor: Vector2, _dt: float, _positions: PackedVector2Array = PackedVector2Array()) -> void:
    pass


func apply(i: int, positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    pass


## Runs the mode over every particle. Modes override this with an inlined loop;
## a per-particle call costs more than the force math in GDScript.
func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    for i in positions.size():
        apply(i, positions, velocities, anchor, dt)


func end_frame() -> void:
    pass


## Integrate velocity and bounce at screen edges (rain wraps when idle).
func integrate_all(positions: PackedVector2Array, velocities: PackedVector2Array, dt: float) -> void:
    var min_x := bounds.position.x
    var max_x := bounds.end.x
    var min_y := bounds.position.y
    var max_y := bounds.end.y
    var rain_wrap := (
        not touch_active
        and settings != null
        and settings.idle_mode == AppSettings.IdleMode.RAIN
    )
    for i in positions.size():
        var vel := velocities[i]
        var pos := positions[i] + vel * dt
        var hit := false
        if pos.x < min_x:
            pos.x = min_x
            vel.x = absf(vel.x)
            hit = true
        elif pos.x > max_x:
            pos.x = max_x
            vel.x = -absf(vel.x)
            hit = true
        if rain_wrap:
            if pos.y > max_y:
                pos.y = min_y - randf_range(0.0, 12.0)
                pos.x = clampf(pos.x + randf_range(-18.0, 18.0), min_x, max_x)
                vel.y = absf(vel.y) * 0.35 + IDLE_RAIN * 0.4
                vel.x *= 0.5
                hit = true
            elif pos.y < min_y:
                pos.y = min_y
                if vel.y < 0.0:
                    vel.y = absf(vel.y) * 0.2
                hit = true
        elif pos.y < min_y:
            pos.y = min_y
            vel.y = absf(vel.y)
            hit = true
        elif pos.y > max_y:
            pos.y = max_y
            vel.y = -absf(vel.y)
            hit = true
        positions[i] = pos
        if hit:
            velocities[i] = vel


## Untouched frame for every particle: idle drift, damp by drag, integrate.
func idle_all(positions: PackedVector2Array, velocities: PackedVector2Array, dt: float, drag: float) -> void:
    idle_drift_all(positions, velocities, dt, exp(-drag * dt))
    integrate_all(positions, velocities, dt)


## Inlined apply_idle_drift over every particle, then scale velocity by keep.
func idle_drift_all(positions: PackedVector2Array, velocities: PackedVector2Array, dt: float, keep: float) -> void:
    var strength := IDLE_DRIFT_ACTIVE if touch_active else IDLE_DRIFT
    var mode := settings.idle_mode if settings else AppSettings.IdleMode.DRIFT
    var n := positions.size()
    match mode:
        AppSettings.IdleMode.DRIFT:
            var step := strength * dt
            for i in n:
                var pos := positions[i]
                var fi := float(i)
                var flow := Vector2(sin(pos.y * 0.008 + fi * 0.0013), cos(pos.x * 0.007 + fi * 0.0009))
                velocities[i] = (velocities[i] + flow * step) * keep
        AppSettings.IdleMode.SWIRL:
            var center := bounds.get_center()
            var step := IDLE_SWIRL * (strength / IDLE_DRIFT) * dt
            for i in n:
                var to := positions[i] - center
                var dist := to.length()
                var vel := velocities[i]
                if dist >= 0.5:
                    vel += Vector2(-to.y, to.x) * (step / dist)
                velocities[i] = vel * keep
        AppSettings.IdleMode.RAIN:
            var scale := strength / IDLE_DRIFT
            var down := IDLE_RAIN * scale * dt
            var jitter := IDLE_RAIN_JITTER * scale * dt
            var phase := _idle_time * 2.1
            for i in n:
                var vel := velocities[i]
                vel.x += sin(phase + float(i) * 0.17) * jitter
                vel.y += down
                velocities[i] = vel * keep
        _:
            for i in n:
                velocities[i] = apply_idle_drift(i, velocities[i], positions[i], dt) * keep


## Ambient motion when not driven hard by the active art mode.
func apply_idle_drift(i: int, vel: Vector2, pos: Vector2, dt: float) -> Vector2:
    var mode := AppSettings.IdleMode.DRIFT
    if settings:
        mode = settings.idle_mode
    var strength := IDLE_DRIFT_ACTIVE if touch_active else IDLE_DRIFT

    match mode:
        AppSettings.IdleMode.SWIRL:
            return _idle_swirl(vel, pos, dt, strength)
        AppSettings.IdleMode.LATTICE:
            return _idle_lattice(i, vel, pos, dt, strength)
        AppSettings.IdleMode.BOIDS:
            return _idle_boids(i, vel, pos, dt, strength)
        AppSettings.IdleMode.RAIN:
            return _idle_rain(i, vel, dt, strength)
        _:
            var flow := Vector2(
                sin(pos.y * 0.008 + float(i) * 0.0013),
                cos(pos.x * 0.007 + float(i) * 0.0009)
            )
            return vel + flow * strength * dt


func _idle_swirl(vel: Vector2, pos: Vector2, dt: float, strength: float) -> Vector2:
    var center := bounds.get_center()
    var to := pos - center
    var dist := to.length()
    if dist < 0.5:
        return vel
    var tangent := Vector2(-to.y, to.x) / dist
    var swirl_str := IDLE_SWIRL * (strength / IDLE_DRIFT)
    return vel + tangent * swirl_str * dt


func _idle_lattice(i: int, vel: Vector2, pos: Vector2, dt: float, strength: float) -> Vector2:
    var cell := IDLE_LATTICE_CELL
    var cols := maxi(1, int(bounds.size.x / cell))
    var col := i % cols
    var row := int(i / cols)
    var odd := row % 2
    var target := Vector2(
        bounds.position.x + (float(col) + 0.5 + float(odd) * 0.5) * cell,
        bounds.position.y + (float(row) + 0.5) * cell * 0.866
    ) + _lattice_offset
    target.x = clampf(target.x, bounds.position.x, bounds.end.x)
    target.y = clampf(target.y, bounds.position.y, bounds.end.y)
    var spring := (target - pos) * IDLE_LATTICE_SPRING * (strength / IDLE_DRIFT)
    if spring.length() > 400.0:
        spring = spring.normalized() * 400.0
    return vel + spring * dt


func _idle_boids(i: int, vel: Vector2, pos: Vector2, dt: float, strength: float) -> Vector2:
    var n := _idle_velocities.size()
    if n < 4 or _idle_positions.size() != n:
        var flow := Vector2(
            sin(pos.y * 0.008 + float(i) * 0.0013),
            cos(pos.x * 0.007 + float(i) * 0.0009)
        )
        return vel + flow * strength * dt
    var scale := strength / IDLE_DRIFT
    var avg_vel := Vector2.ZERO
    var avg_pos := Vector2.ZERO
    var separate := Vector2.ZERO
    var sep_count := 0
    for k in 4:
        var j := posmod(i * 73856093 + k * 19349663, n)
        if j == i:
            j = (j + 1) % n
        avg_vel += _idle_velocities[j]
        avg_pos += _idle_positions[j]
        var away := pos - _idle_positions[j]
        var dist := away.length()
        if dist > 0.01 and dist < IDLE_BOIDS_SEP_DIST:
            separate += away / (dist * dist)
            sep_count += 1
    avg_vel *= 0.25
    avg_pos *= 0.25

    var align := (avg_vel - vel) * IDLE_BOIDS_ALIGN * scale
    var force := align
    var to_flock := avg_pos - pos
    var flock_dist := to_flock.length()
    if flock_dist > IDLE_BOIDS_SEP_DIST:
        force += to_flock.normalized() * IDLE_BOIDS_COHERE * scale * minf(flock_dist, 120.0) * 0.2
    if sep_count > 0:
        force += separate * IDLE_BOIDS_SEPARATE * scale

    var wander := Vector2(
        sin(pos.y * 0.008 + float(i) * 0.0013),
        cos(pos.x * 0.007 + float(i) * 0.0009)
    )
    force += wander * strength * IDLE_BOIDS_WANDER

    if force.length() > 280.0:
        force = force.normalized() * 280.0
    return vel + force * dt


func _idle_rain(i: int, vel: Vector2, dt: float, strength: float) -> Vector2:
    var scale := strength / IDLE_DRIFT
    var down := Vector2(0.0, IDLE_RAIN * scale)
    var jitter := sin(_idle_time * 2.1 + float(i) * 0.17) * IDLE_RAIN_JITTER * scale
    return vel + (down + Vector2(jitter, 0.0)) * dt
