class_name ArtLinear
extends ArtModeBase
## Flow — directional field from touch; on phone, also follows accelerometer.

const FIELD_STRENGTH := 900.0
const PULL_STRENGTH := 600.0
const SOFT := 80.0
const DRAG := 0.9
const DEFAULT_DIR := Vector2(1, 0)
const ACCEL_DEADZONE := 0.35
const ACCEL_BLEND := 0.85

var _field_dir: Vector2 = DEFAULT_DIR


func begin_frame(_anchor: Vector2, dt: float, _positions: PackedVector2Array = PackedVector2Array()) -> void:
    if touch_active and touch_velocity.length() > 8.0:
        _field_dir = touch_velocity.normalized()
        return

    if DisplayServer.is_touchscreen_available():
        var accel := Input.get_accelerometer()
        var tilt := Vector2(accel.x, -accel.y)
        if tilt.length() >= ACCEL_DEADZONE:
            var tilt_dir := tilt.normalized()
            if touch_active:
                _field_dir = _field_dir.lerp(tilt_dir, ACCEL_BLEND * 0.5).normalized()
            else:
                _field_dir = _field_dir.lerp(tilt_dir, ACCEL_BLEND).normalized()
            return

    if not touch_active:
        _field_dir = _field_dir.rotated(0.15 * dt).normalized()


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    var field_mul := settings.flow_field if settings else 1.0
    var pull := PULL_STRENGTH * (settings.flow_pull if settings else 1.0) * dt
    var perp := Vector2(-_field_dir.y, _field_dir.x)
    var push := _field_dir * FIELD_STRENGTH * field_mul * dt
    var sway := perp * FIELD_STRENGTH * field_mul * 0.25 * dt
    var n := positions.size()
    if not touch_active:
        for i in n:
            var pos := positions[i]
            velocities[i] += push + sway * sin(float(i) * 0.17 + pos.x * 0.01)
        # Same order as apply: field, then idle drift, then drag.
        idle_all(positions, velocities, dt, DRAG)
        return
    var soft_sq := SOFT * SOFT
    var keep := exp(-DRAG * dt)
    for i in n:
        var pos := positions[i]
        var vel := velocities[i] + push + sway * sin(float(i) * 0.17 + pos.x * 0.01)
        var to_anchor := anchor - pos
        var across := to_anchor - _field_dir * to_anchor.dot(_field_dir)
        vel += across * (pull / (across.length_squared() + soft_sq))
        velocities[i] = vel * keep
    integrate_all(positions, velocities, dt)
