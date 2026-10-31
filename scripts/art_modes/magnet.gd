class_name ArtMagnet
extends ArtModeBase
## Magnet — dual attract/repel poles around the touch.

const ATTRACT_STRENGTH := 42000.0
const REPEL_STRENGTH := 42000.0
const SOFT := 24.0
const DRAG_HELD := 0.7
const DRAG_FREE := 0.45
const DRAG_SPEED_THRESHOLD := 80.0

var _axis: Vector2 = Vector2.RIGHT


func begin_frame(_anchor: Vector2, _dt: float, _positions: PackedVector2Array = PackedVector2Array()) -> void:
    if touch_active and touch_velocity.length() >= DRAG_SPEED_THRESHOLD:
        _axis = touch_velocity.normalized()


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    if not touch_active:
        idle_all(positions, velocities, dt, DRAG_FREE)
        return
    var gap := settings.magnet_gap if settings else AppSettings.DEFAULT_MAGNET_GAP
    var attract := ATTRACT_STRENGTH * (settings.magnet_attract if settings else 1.0) * dt
    var repel := REPEL_STRENGTH * (settings.magnet_repel if settings else 1.0) * dt
    var half := gap * 0.5
    var attract_pole := anchor - _axis * half
    var repel_pole := anchor + _axis * half
    var soft_sq := SOFT * SOFT
    var keep := exp(-DRAG_HELD * dt)
    for i in positions.size():
        var pos := positions[i]
        var to_a := attract_pole - pos
        var from_r := pos - repel_pole
        var vel := velocities[i]
        vel += to_a * (attract / (to_a.length_squared() + soft_sq))
        vel += from_r * (repel / (from_r.length_squared() + soft_sq))
        velocities[i] = vel * keep
    idle_drift_all(positions, velocities, dt, 1.0)
    integrate_all(positions, velocities, dt)
