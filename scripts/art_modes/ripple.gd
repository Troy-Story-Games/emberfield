class_name ArtRipple
extends ArtModeBase
## Ripple — expanding wave rings from the touch point.

const BASE_EXPAND := 400.0
const BASE_INTERVAL := 0.35
const RING_WIDTH := 28.0
const BASE_KICK := 1600.0
const DRAG_HELD := 0.55
const DRAG_FREE := 0.5
const MAX_RINGS := 8

var _ring_centers: PackedVector2Array = PackedVector2Array()
var _ring_radii: PackedFloat32Array = PackedFloat32Array()
var _ring_signs: PackedFloat32Array = PackedFloat32Array()
var _spawn_timer: float = 0.0
var _ring_sign: float = 1.0
var _max_radius: float = 2000.0


func begin_frame(anchor: Vector2, dt: float, _positions: PackedVector2Array = PackedVector2Array()) -> void:
    var speed_mul := 1.0
    var rate_mul := 1.0
    if settings:
        speed_mul = settings.ripple_speed
        rate_mul = settings.ripple_rate
    var expand := BASE_EXPAND * speed_mul
    var interval := BASE_INTERVAL / maxf(rate_mul, 0.01)
    _max_radius = bounds.size.length() * 0.75

    if just_pressed:
        _spawn_timer = 0.0
        _add_ring(anchor)

    if touch_active:
        _spawn_timer += dt
        while _spawn_timer >= interval:
            _spawn_timer -= interval
            _add_ring(anchor)
            if _ring_radii.size() > MAX_RINGS:
                _remove_ring(0)

    var k := 0
    while k < _ring_radii.size():
        _ring_radii[k] += expand * dt
        if _ring_radii[k] > _max_radius:
            _remove_ring(k)
        else:
            k += 1


func _add_ring(center: Vector2) -> void:
    _ring_centers.append(center)
    _ring_radii.append(0.0)
    _ring_signs.append(_ring_sign)
    _ring_sign = -_ring_sign


func _remove_ring(k: int) -> void:
    _ring_centers.remove_at(k)
    _ring_radii.remove_at(k)
    _ring_signs.remove_at(k)


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, _anchor: Vector2, dt: float) -> void:
    var rings := _ring_radii.size()
    if rings == 0:
        idle_all(positions, velocities, dt, DRAG_FREE)
        return
    var kick := BASE_KICK * (settings.ripple_power if settings else 1.0)
    var keep := exp(-DRAG_HELD * dt)
    # A particle is inside ring k's band when inner^2 < dist^2 < outer^2.
    var inner_sq := PackedFloat32Array()
    var outer_sq := PackedFloat32Array()
    inner_sq.resize(rings)
    outer_sq.resize(rings)
    for k in rings:
        var inner := maxf(_ring_radii[k] - RING_WIDTH, 0.5)
        var outer := _ring_radii[k] + RING_WIDTH
        inner_sq[k] = inner * inner
        outer_sq[k] = outer * outer
    var centers := _ring_centers
    var radii := _ring_radii
    var signs := _ring_signs
    for i in positions.size():
        var pos := positions[i]
        var vel := velocities[i]
        for k in rings:
            var to_p := pos - centers[k]
            var dist_sq := to_p.length_squared()
            if dist_sq > inner_sq[k] and dist_sq < outer_sq[k]:
                var dist := sqrt(dist_sq)
                var falloff := 1.0 - absf(dist - radii[k]) / RING_WIDTH
                vel += to_p * (kick * signs[k] * falloff * falloff / dist)
        velocities[i] = vel * keep
    idle_drift_all(positions, velocities, dt, 1.0)
    integrate_all(positions, velocities, dt)
