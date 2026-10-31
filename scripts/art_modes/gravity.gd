class_name ArtGravity
extends ArtModeBase
## Repel — strong push away from the touch point; strength is tunable.

const REPEL_STRENGTH := 65000.0
const SOFT := 22.0
const DRAG := 0.2
const MAX_ACCEL := 28000.0


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    var strength_mul := settings.repel_strength if settings else 1.0
    if not touch_active:
        idle_all(positions, velocities, dt, DRAG)
        return
    var strength := REPEL_STRENGTH * strength_mul
    var soft_sq := SOFT * SOFT
    var max_a := MAX_ACCEL * strength_mul
    var max_a_sq := max_a * max_a
    var keep := exp(-DRAG * dt)
    for i in positions.size():
        var pos := positions[i]
        var away := pos - anchor
        var force := away * (strength / (away.length_squared() + soft_sq))
        if force.length_squared() > max_a_sq:
            force = force.normalized() * max_a
        velocities[i] += force * dt
    idle_drift_all(positions, velocities, dt, keep)
    integrate_all(positions, velocities, dt)
