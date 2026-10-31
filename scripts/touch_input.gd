class_name TouchInput
extends Node
## Tracks multi-touch and reports the centroid of all active pointers.
## Relies on project setting pointing/emulate_touch_from_mouse for desktop.

signal anchor_changed(anchor: Vector2, active: bool, pointer_count: int)

var _pointers: Dictionary = {} # index -> Vector2
var _ui_blocked: bool = false
var last_anchor: Vector2 = Vector2.ZERO
var is_active: bool = false
var pointer_count: int = 0
var just_pressed: bool = false
var just_released: bool = false
var velocity: Vector2 = Vector2.ZERO

var _prev_anchor: Vector2 = Vector2.ZERO
var _had_active: bool = false


func set_ui_blocked(blocked: bool) -> void:
    _ui_blocked = blocked
    if blocked:
        _pointers.clear()


func _input(event: InputEvent) -> void:
    if _ui_blocked:
        return

    if event is InputEventScreenTouch:
        var st := event as InputEventScreenTouch
        if st.pressed:
            _pointers[st.index] = st.position
        else:
            _pointers.erase(st.index)
        get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag:
        var sd := event as InputEventScreenDrag
        _pointers[sd.index] = sd.position
        get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
    pointer_count = _pointers.size()
    just_pressed = false
    just_released = false

    if pointer_count > 0:
        var sum := Vector2.ZERO
        for pos in _pointers.values():
            sum += pos as Vector2
        last_anchor = sum / float(pointer_count)
        if not _had_active:
            just_pressed = true
            velocity = Vector2.ZERO
        else:
            velocity = (last_anchor - _prev_anchor) / maxf(delta, 0.0001)
        is_active = true
        _had_active = true
        _prev_anchor = last_anchor
    else:
        if _had_active:
            just_released = true
        is_active = false
        _had_active = false
        velocity = Vector2.ZERO

    anchor_changed.emit(last_anchor, is_active, pointer_count)
