class_name ArtBeam
extends ArtModeBase
## Beam — collect at finger, then fire a solid stream along drag direction.

const ATTRACT_STRENGTH := 42000.0
const ATTRACT_SOFT := 12.0
const DRAG_COLLECT := 2.2
const DRAG_BEAM := 0.35
const DRAG_FREE := 0.45
const COLLECT_RADIUS := 40.0
const EJECT_RADIUS := 55.0
const BASE_BEAM_SPEED := 1400.0
const BASE_CONE_HALF := 0.08 # ~4.5 degrees
const DRAG_SPEED_THRESHOLD := 80.0

var _beam_dir: Vector2 = Vector2.RIGHT
var _has_beam_dir: bool = false
var _beaming: bool = false
var _kick_speed: float = BASE_BEAM_SPEED


func begin_frame(_anchor: Vector2, _dt: float, _positions: PackedVector2Array = PackedVector2Array()) -> void:
    if just_released or not touch_active:
        _beaming = false
        _has_beam_dir = false
        return

    if touch_velocity.length() >= DRAG_SPEED_THRESHOLD:
        _beam_dir = touch_velocity.normalized()
        _has_beam_dir = true
        _beaming = true
    else:
        # Same hold: keep firing if already locked; otherwise stay in collect.
        _beaming = _has_beam_dir


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    if not touch_active:
        idle_all(positions, velocities, dt, DRAG_FREE)
        return
    var attract_mul := settings.beam_attract if settings else 1.0
    var cone_mul := settings.beam_cone if settings else 1.0
    _kick_speed = BASE_BEAM_SPEED * (settings.beam_speed if settings else 1.0)
    var attract := ATTRACT_STRENGTH * attract_mul * dt
    var soft_sq := ATTRACT_SOFT * ATTRACT_SOFT
    var n := positions.size()
    if not (_beaming and _has_beam_dir):
        # Collect phase: gather under finger without despawning.
        var collect_sq := COLLECT_RADIUS * COLLECT_RADIUS
        var keep_collect := exp(-DRAG_COLLECT * attract_mul * dt)
        var keep_far := exp(-dt)
        for i in n:
            var to_core := anchor - positions[i]
            var dist_sq := to_core.length_squared()
            var vel := velocities[i] + to_core * (attract / (dist_sq + soft_sq))
            velocities[i] = vel * (keep_collect if dist_sq < collect_sq else keep_far)
        integrate_all(positions, velocities, dt)
        return
    var eject_sq := EJECT_RADIUS * EJECT_RADIUS
    var half := BASE_CONE_HALF * cone_mul
    var keep := exp(-DRAG_BEAM * dt)
    var respawn := _beam_dir.normalized() * _kick_speed
    var min_x := bounds.position.x
    var max_x := bounds.end.x
    var min_y := bounds.position.y
    var max_y := bounds.end.y
    for i in n:
        var pos := positions[i]
        var to_core := anchor - pos
        var dist_sq := to_core.length_squared()
        var vel := velocities[i] + to_core * (attract / (dist_sq + soft_sq))
        if dist_sq < eject_sq:
            var spread := randf_range(-half, half) + sin(float(i) * 0.41) * half * 0.2
            vel = _beam_dir.rotated(spread) * (_kick_speed * randf_range(0.85, 1.2)) - to_core.normalized() * 80.0
        vel *= keep
        # Inlined integrate_and_recycle_at_edge: leaving the screen re-fires from the finger.
        pos += vel * dt
        if pos.x < min_x or pos.x > max_x or pos.y < min_y or pos.y > max_y:
            pos = anchor
            vel = respawn
        positions[i] = pos
        velocities[i] = vel
