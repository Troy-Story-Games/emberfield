class_name ArtLightning
extends ArtModeBase
## Lightning — tunable inward pull while charging, then periodic discharge.

signal discharged(center: Vector2, targets: PackedVector2Array)

const ATTRACT_STRENGTH := 22000.0
const DISCHARGE_KICK := 4200.0
const SOFT := 18.0
const DRAG_CHARGE := 1.1
const DRAG_FREE := 0.5
const CHARGE_TIME := 0.7
const DISCHARGE_RADIUS := 340.0
const MAX_BOLTS := 14

var _charge: float = 0.0
var _pending_discharge: bool = false
var _discharge_center: Vector2 = Vector2.ZERO
var _bolt_targets: PackedVector2Array = PackedVector2Array()
var _charge_time: float = CHARGE_TIME
var _attract: float = ATTRACT_STRENGTH
var _kick: float = DISCHARGE_KICK


func begin_frame(anchor: Vector2, dt: float, _positions: PackedVector2Array = PackedVector2Array()) -> void:
    _pending_discharge = false
    _bolt_targets.clear()

    _charge_time = CHARGE_TIME
    _attract = ATTRACT_STRENGTH
    _kick = DISCHARGE_KICK
    if settings:
        _charge_time = CHARGE_TIME * settings.lightning_charge_time
        _attract = ATTRACT_STRENGTH * settings.lightning_attract
        _kick = DISCHARGE_KICK * settings.lightning_discharge

    if touch_active:
        _charge += dt
        if _charge >= _charge_time:
            _pending_discharge = true
            _discharge_center = anchor
            _charge = 0.0
    else:
        _charge = maxf(0.0, _charge - dt * 0.5)


func end_frame() -> void:
    if _pending_discharge:
        discharged.emit(_discharge_center, _bolt_targets)


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    var n := positions.size()
    if _pending_discharge:
        var keep := exp(-DRAG_FREE * dt)
        for i in n:
            var pos := positions[i]
            var away := pos - _discharge_center
            var dist := away.length()
            var vel := velocities[i]
            if dist < DISCHARGE_RADIUS and dist > 0.5:
                vel += away * (_kick * (1.0 - dist / DISCHARGE_RADIUS) / dist)
                if _bolt_targets.size() < MAX_BOLTS and (i % 37 == 0):
                    _bolt_targets.append(pos)
            velocities[i] = vel * keep
    elif touch_active:
        var attract := _attract * dt
        var soft_sq := SOFT * SOFT
        var keep := exp(-DRAG_CHARGE * dt)
        for i in n:
            var pos := positions[i]
            var to_anchor := anchor - pos
            velocities[i] = (velocities[i] + to_anchor * (attract / (to_anchor.length_squared() + soft_sq))) * keep
        idle_drift_all(positions, velocities, dt, 1.0)
    else:
        idle_all(positions, velocities, dt, DRAG_FREE)
        return
    integrate_all(positions, velocities, dt)
