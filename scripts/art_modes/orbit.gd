class_name ArtOrbit
extends ArtModeBase
## Orbit — particles settle into circling bands around the finger.

const RADIAL_SPRING := 42.0
const MAX_RADIAL_ACCEL := 8000.0
const FAR_INWARD := 900.0
const BASE_TANGENT := 1800.0
const DRAG_RING := 1.6
const DRAG_NEAR := 1.1
const DRAG_FAR := 2.4
const DRAG_FREE := 0.45
const MAX_SPEED := 1800.0


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    if not touch_active:
        idle_all(positions, velocities, dt, DRAG_FREE)
        return
    var radius := settings.orbit_radius if settings else AppSettings.DEFAULT_ORBIT_RADIUS
    var speed_mul := settings.orbit_speed if settings else 1.0
    var attract_mul := settings.orbit_attract if settings else 1.0
    var capture := radius * 2.5
    var band := radius * 0.4
    var fade_span := maxf(capture - radius - band, 1.0)
    var spring := RADIAL_SPRING * attract_mul
    var far_pull := FAR_INWARD * attract_mul * dt
    var spin := BASE_TANGENT * speed_mul * dt
    var max_speed_sq := MAX_SPEED * MAX_SPEED
    var keep_ring := exp(-DRAG_RING * dt)
    var keep_near := exp(-DRAG_NEAR * dt)
    var keep_far := exp(-DRAG_FAR * dt)
    for i in positions.size():
        var pos := positions[i]
        var vel := velocities[i]
        var to_core := anchor - pos
        var dist := to_core.length()
        if dist > 0.5:
            var radial := to_core / dist # toward center
            var orbit_err := dist - radius
            if dist > capture:
                # Far field: gentle inward only, no tangent slingshot.
                vel = (vel + radial * far_pull) * keep_far
            else:
                # Capped spring toward the ring (not the center).
                var radial_accel := clampf(orbit_err * spring, -MAX_RADIAL_ACCEL, MAX_RADIAL_ACCEL)
                vel -= radial * (radial_accel * dt)
                var tangent_scale := 1.0
                if dist > radius + band:
                    # Fade tangent outside the band so outer particles don't spray.
                    tangent_scale = clampf(1.0 - (dist - radius - band) / fade_span, 0.15, 1.0)
                vel += Vector2(-radial.y, radial.x) * (spin * tangent_scale)
                vel *= keep_ring if absf(orbit_err) < band else keep_near
        else:
            vel *= keep_ring
        if vel.length_squared() > max_speed_sq:
            vel = vel.normalized() * MAX_SPEED
        velocities[i] = vel
    idle_drift_all(positions, velocities, dt, 1.0)
    integrate_all(positions, velocities, dt)
