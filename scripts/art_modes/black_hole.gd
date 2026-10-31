class_name ArtBlackHole
extends ArtModeBase
## Black Hole — trap at a point; milder hold/proximity-scaled explode on release.

const ATTRACT_STRENGTH := 52000.0
const ATTRACT_SOFT := 8.0
const DRAG_HELD := 2.4
const DRAG_TRAP := 4.0
const DRAG_FREE := 0.4
const TRAP_RADIUS := 18.0
const EXPLODE_DURATION := 0.28
const EXPLODE_MIN := 400.0
const EXPLODE_MAX := 3500.0
const HOLD_FOR_MAX := 4.0
const NEAR_RADIUS_MUL := 1.5

var _explode_timer: float = 0.0
var _explode_center: Vector2 = Vector2.ZERO
var _explode_power: float = EXPLODE_MIN
var _hold_time: float = 0.0


func begin_frame(anchor: Vector2, dt: float, positions: PackedVector2Array = PackedVector2Array()) -> void:
    if just_pressed:
        _hold_time = 0.0

    if touch_active:
        _hold_time += dt

    if just_released:
        _explode_timer = EXPLODE_DURATION
        _explode_center = anchor
        var t := clampf(_hold_time / HOLD_FOR_MAX, 0.0, 1.0)
        t = t * t * (3.0 - 2.0 * t)
        var power := lerpf(EXPLODE_MIN, EXPLODE_MAX, t)
        var explode_mul := 0.7
        if settings:
            explode_mul = settings.bh_explode
        power *= explode_mul

        var near_frac := _near_fraction(positions, anchor)
        power *= lerpf(0.25, 1.0, near_frac)
        _explode_power = power
        _hold_time = 0.0

    if _explode_timer > 0.0:
        _explode_timer = maxf(0.0, _explode_timer - dt)


func _near_fraction(positions: PackedVector2Array, anchor: Vector2) -> float:
    var n := positions.size()
    if n <= 0:
        return 0.0
    var near_r := TRAP_RADIUS * NEAR_RADIUS_MUL
    var near_r2 := near_r * near_r
    var near := 0
    for j in n:
        if positions[j].distance_squared_to(anchor) <= near_r2:
            near += 1
    return float(near) / float(n)


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    var strength_mul := settings.bh_strength if settings else 1.0
    var damp_mul := settings.bh_damping if settings else 1.0
    var n := positions.size()
    if _explode_timer > 0.0:
        var keep := exp(-DRAG_FREE * dt)
        var push := _explode_power * (0.4 + _explode_timer / EXPLODE_DURATION * 0.6)
        for i in n:
            var to_p := positions[i] - _explode_center
            var dist := to_p.length()
            var vel := velocities[i]
            if dist > 0.5:
                vel += to_p * (push / dist)
            velocities[i] = vel * keep
    elif touch_active:
        var strength := ATTRACT_STRENGTH * strength_mul * dt
        var soft_sq := ATTRACT_SOFT * ATTRACT_SOFT
        var trap_sq := TRAP_RADIUS * TRAP_RADIUS
        var keep_trap := exp(-DRAG_TRAP * damp_mul * dt)
        var keep_held := exp(-DRAG_HELD * damp_mul * dt)
        for i in n:
            var to_core := anchor - positions[i]
            var dist_sq := to_core.length_squared()
            var vel := velocities[i] + to_core * (strength / (dist_sq + soft_sq))
            velocities[i] = vel * (keep_trap if dist_sq < trap_sq else keep_held)
    else:
        idle_all(positions, velocities, dt, DRAG_FREE)
        return
    integrate_all(positions, velocities, dt)
