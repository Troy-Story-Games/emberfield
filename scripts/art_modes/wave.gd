class_name ArtWave
extends ArtModeBase
## Pulse — one ring on first press, then edge-recycling stream while held.

const RING_RADIUS := 280.0
const RING_IMPULSE := 1600.0
const STREAM_FRACTION := 0.008
const STREAM_MIN := 12
const STREAM_MAX := 120
const EMIT_JITTER := 3.0
const KICK_SPEED := 1100.0
const DRAG_CONE_HALF_ANGLE := 0.55
const DRAG_SPEED_THRESHOLD := 80.0
const DRAG_EMIT := 0.15
const DRAG_IDLE := 0.55

var _emit_point: Vector2 = Vector2.ZERO
var _spawn_cursor: int = 0
var _count: int = 0
var _batch: int = 0
var _dragging: bool = false
var _jet_dir: Vector2 = Vector2.ZERO
var _do_pulse: bool = false
var _stream_started: bool = false
var _kick_speed: float = KICK_SPEED
var _ring_impulse: float = RING_IMPULSE
var _emit_mul: float = 1.0


func begin_frame(anchor: Vector2, _dt: float, _positions: PackedVector2Array = PackedVector2Array()) -> void:
    _emit_point = anchor
    _dragging = touch_active and touch_velocity.length() >= DRAG_SPEED_THRESHOLD
    if _dragging:
        _jet_dir = -touch_velocity.normalized()

    _emit_mul = 1.0
    var kick_mul := 1.0
    var ring_mul := 1.0
    if settings:
        _emit_mul = settings.pulse_emit_rate
        kick_mul = settings.pulse_kick_speed
        ring_mul = settings.pulse_ring_power
    _kick_speed = KICK_SPEED * kick_mul
    _ring_impulse = RING_IMPULSE * ring_mul

    if just_pressed:
        _do_pulse = true
        _stream_started = false
    elif touch_active:
        _do_pulse = false
        _stream_started = true
    else:
        _do_pulse = false
        _stream_started = false


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    _count = positions.size()
    _batch = clampi(int(float(_count) * STREAM_FRACTION * _emit_mul), STREAM_MIN, STREAM_MAX)
    if _count == 0:
        return
    var keep := exp(-DRAG_EMIT * dt)

    if _do_pulse:
        for i in _count:
            var to_p := positions[i] - anchor
            var dist := to_p.length()
            var vel := velocities[i]
            if dist < RING_RADIUS and dist > 0.5:
                var falloff := 1.0 - dist / RING_RADIUS
                vel += to_p * (_ring_impulse * (0.4 + falloff * 0.6) / dist)
            elif dist <= 0.5:
                var angle := float(i) * 2.399963
                vel += Vector2(cos(angle), sin(angle)) * _ring_impulse * 0.85
            velocities[i] = vel * keep
        integrate_all(positions, velocities, dt)
        return

    if not (touch_active and _stream_started):
        idle_all(positions, velocities, dt, DRAG_IDLE)
        return

    # Stream: a rolling batch re-emits from the finger; everyone else drifts and
    # recycles back to the finger when they leave the screen.
    idle_drift_all(positions, velocities, dt, keep)
    var cursor := _spawn_cursor % _count
    for k in mini(_batch, _count):
        var i := (cursor + k) % _count
        var dir := _emit_direction(i)
        positions[i] = _emit_point + dir * randf_range(0.0, EMIT_JITTER)
        velocities[i] = dir * randf_range(_kick_speed * 0.85, _kick_speed * 1.25)
    var min_x := bounds.position.x
    var max_x := bounds.end.x
    var min_y := bounds.position.y
    var max_y := bounds.end.y
    for i in _count:
        var vel := velocities[i]
        var pos := positions[i] + vel * dt
        if pos.x < min_x or pos.x > max_x or pos.y < min_y or pos.y > max_y:
            pos = _emit_point
            velocities[i] = _emit_direction(i) * _kick_speed
        positions[i] = pos


func end_frame() -> void:
    if touch_active and _stream_started and _count > 0:
        _spawn_cursor = (_spawn_cursor + _batch) % _count
    if _do_pulse:
        _do_pulse = false
        _stream_started = touch_active


func _emit_direction(i: int) -> Vector2:
    if _dragging:
        var base_angle := _jet_dir.angle()
        var spread := randf_range(-DRAG_CONE_HALF_ANGLE, DRAG_CONE_HALF_ANGLE)
        spread += sin(float(i) * 0.37) * DRAG_CONE_HALF_ANGLE * 0.15
        return Vector2.from_angle(base_angle + spread)
    var angle := float(i) * 2.399963 + float(_spawn_cursor) * 0.01
    return Vector2(cos(angle), sin(angle))
