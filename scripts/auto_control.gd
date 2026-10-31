class_name AutoControl
extends RefCounted
## Screensaver-like virtual touch: roam, dwell, tap, and occasional mode switches.

enum Pattern {
    CIRCLE,
    FIGURE8,
    LISSAJOUS,
    SPIRAL,
    ELLIPSE,
    SUNSHINE,
    BUTTERFLY,
    ROSE,
}

enum Phase {
    ROAM,
    DWELL,
    TAP,
}

var enabled: bool = false
var bounds: Rect2 = Rect2(0, 0, 1080, 1920)
var pattern: Pattern = Pattern.CIRCLE
var speed: float = 1.0

## Set by update when an art-mode change is due; consumer clears after applying.
var pending_art_mode: int = -1

var _t: float = 0.0
var _path_timer: float = 0.0
var _path_duration: float = 16.0
var _phase: Phase = Phase.ROAM
var _phase_timer: float = 0.0
var _phase_duration: float = 14.0
var _mode_timer: float = 0.0
var _mode_duration: float = 30.0
var _tap_stage: int = 0 # 0=release, 1=gap, 2=press
var _tap_timer: float = 0.0
var _tap_gap: float = 0.25
var _tap_hold: float = 0.2
var _center: Vector2 = Vector2.ZERO
var _radius: float = 200.0
var _margin: float = 16.0

var anchor: Vector2 = Vector2.ZERO
var active: bool = false
var velocity: Vector2 = Vector2.ZERO
var just_pressed: bool = false
var just_released: bool = false

var _prev_anchor: Vector2 = Vector2.ZERO
var _was_active: bool = false
var _was_enabled: bool = false


func setup(viewport_size: Vector2) -> void:
    bounds = Rect2(Vector2.ZERO, viewport_size)
    _center = bounds.get_center()
    _radius = minf(bounds.size.x, bounds.size.y) * 0.4
    anchor = _center
    _prev_anchor = _center
    _pick_new_pattern()
    _enter_phase(Phase.ROAM)
    _mode_timer = 0.0
    _mode_duration = randf_range(22.0, 45.0)
    pending_art_mode = -1


func update(dt: float, user_touching: bool, current_art_mode: int = 0) -> void:
    just_pressed = false
    just_released = false
    pending_art_mode = -1

    if not enabled or user_touching:
        if _was_active and (not enabled or user_touching):
            just_released = true
        active = false
        _was_active = false
        _was_enabled = enabled and not user_touching
        velocity = Vector2.ZERO
        return

    # Fresh start when auto takes over again.
    if not _was_enabled:
        _pick_new_pattern()
        _enter_phase(Phase.ROAM)
        _mode_timer = 0.0
        _mode_duration = randf_range(22.0, 45.0)
        just_pressed = true

    _was_enabled = true
    _mode_timer += dt
    if _mode_timer >= _mode_duration:
        _mode_timer = 0.0
        _mode_duration = randf_range(22.0, 45.0)
        var mode_count := AppSettings.ArtMode.size()
        if mode_count > 1:
            var next_mode := current_art_mode
            var guard := 0
            while guard < 12:
                next_mode = randi() % mode_count
                guard += 1
                if next_mode != current_art_mode and next_mode != AppSettings.ArtMode.AUDIO:
                    break
            if next_mode != current_art_mode and next_mode != AppSettings.ArtMode.AUDIO:
                pending_art_mode = next_mode

    _phase_timer += dt
    match _phase:
        Phase.DWELL:
            _update_dwell(dt)
        Phase.TAP:
            _update_tap(dt)
        _:
            _update_roam(dt)

    _was_active = active


func _update_roam(dt: float) -> void:
    if not _was_active:
        just_pressed = true

    _t += dt * speed
    _path_timer += dt
    if _path_timer >= _path_duration:
        _pick_new_pattern()

    var next := _sample(_t)
    velocity = (next - _prev_anchor) / maxf(dt, 0.0001)
    _prev_anchor = next
    anchor = next
    active = true

    if _phase_timer >= _phase_duration:
        _pick_next_phase_from_roam()


func _update_dwell(_dt: float) -> void:
    if not _was_active:
        just_pressed = true
    velocity = Vector2.ZERO
    active = true
    _prev_anchor = anchor
    if _phase_timer >= _phase_duration:
        _enter_phase(Phase.ROAM)


func _update_tap(dt: float) -> void:
    _tap_timer += dt
    match _tap_stage:
        0:
            # Release current hold.
            if _was_active:
                just_released = true
            active = false
            velocity = Vector2.ZERO
            _tap_stage = 1
            _tap_timer = 0.0
        1:
            active = false
            velocity = Vector2.ZERO
            if _tap_timer >= _tap_gap:
                _tap_stage = 2
                _tap_timer = 0.0
                just_pressed = true
                active = true
                _prev_anchor = anchor
        2:
            # Brief press, then back to roaming.
            active = true
            velocity = Vector2.ZERO
            if _tap_timer >= _tap_hold:
                _enter_phase(Phase.ROAM)


func _pick_next_phase_from_roam() -> void:
    var roll := randf()
    if roll < 0.55:
        _enter_phase(Phase.ROAM)
        _pick_new_pattern()
    elif roll < 0.85:
        _enter_phase(Phase.DWELL)
    else:
        _enter_phase(Phase.TAP)


func _enter_phase(phase: Phase) -> void:
    _phase = phase
    _phase_timer = 0.0
    match phase:
        Phase.ROAM:
            _phase_duration = randf_range(10.0, 22.0)
        Phase.DWELL:
            _phase_duration = randf_range(3.0, 8.0)
        Phase.TAP:
            _phase_duration = 1.0
            _tap_stage = 0
            _tap_timer = 0.0
            _tap_gap = randf_range(0.15, 0.35)
            _tap_hold = randf_range(0.12, 0.28)


func _pick_new_pattern() -> void:
    _path_timer = 0.0
    _path_duration = randf_range(12.0, 20.0)
    pattern = (randi() % Pattern.size()) as Pattern
    speed = randf_range(0.45, 1.2)
    var half := bounds.size * 0.28
    _center = bounds.get_center() + Vector2(
        randf_range(-half.x, half.x),
        randf_range(-half.y, half.y)
    )
    _radius = minf(bounds.size.x, bounds.size.y) * randf_range(0.32, 0.48)
    # Keep path roughly inside the inset margin.
    var max_r_x := maxf(40.0, minf(_center.x - bounds.position.x, bounds.end.x - _center.x) - _margin)
    var max_r_y := maxf(40.0, minf(_center.y - bounds.position.y, bounds.end.y - _center.y) - _margin)
    _radius = minf(_radius, minf(max_r_x, max_r_y))
    _t = randf() * TAU


func _sample(t: float) -> Vector2:
    var p := _center
    match pattern:
        Pattern.CIRCLE:
            p = _center + Vector2(cos(t), sin(t)) * _radius
        Pattern.FIGURE8:
            p = _center + Vector2(sin(t) * _radius, sin(t * 2.0) * _radius * 0.55)
        Pattern.LISSAJOUS:
            p = _center + Vector2(sin(t * 3.0) * _radius, sin(t * 2.0) * _radius * 0.7)
        Pattern.SPIRAL:
            var r := _radius * (0.35 + 0.65 * (0.5 + 0.5 * sin(t * 0.35)))
            p = _center + Vector2(cos(t * 2.0), sin(t * 2.0)) * r
        Pattern.ELLIPSE:
            p = _center + Vector2(cos(t) * _radius * 1.2, sin(t) * _radius * 0.55)
        Pattern.SUNSHINE:
            var rays := 5.0
            var r := _radius * (0.4 + 0.6 * absf(sin(t * rays)))
            p = _center + Vector2(cos(t), sin(t)) * r
        Pattern.BUTTERFLY:
            var s := sin(t)
            var r := exp(s) - 2.0 * cos(4.0 * t) + pow(sin((2.0 * t - PI) / 24.0), 5.0)
            r = absf(r) * _radius * 0.12
            p = _center + Vector2(sin(t) * r, cos(t) * r)
        Pattern.ROSE:
            var k := 4.0
            var r := _radius * cos(k * t)
            p = _center + Vector2(cos(t), sin(t)) * r

    return Vector2(
        clampf(p.x, bounds.position.x + _margin, bounds.end.x - _margin),
        clampf(p.y, bounds.position.y + _margin, bounds.end.y - _margin)
    )
