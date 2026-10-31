extends SceneTree
## Renders the main scene with a scripted drag and saves screenshots (needs a GPU window).
## Godot --path . --resolution 540x960 -s res://tools/screenshot.gd -- --out=C:/tmp/shot --mode=0 [--style=0] [--panel] [--tab=0] [--taps]
## --taps replaces the drag with a series of short taps around the screen (for Fireworks).

var _out: String = "user://shot"
var _mode: int = -1
var _style: int = -1
var _panel: bool = false
var _tab: int = 0
var _taps: bool = false
var _frame: int = 0
var _main: Node


func _initialize() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--out="):
            _out = arg.trim_prefix("--out=")
        elif arg.begins_with("--mode="):
            _mode = int(arg.trim_prefix("--mode="))
        elif arg.begins_with("--style="):
            _style = int(arg.trim_prefix("--style="))
        elif arg == "--panel":
            _panel = true
        elif arg == "--taps":
            _taps = true
        elif arg.begins_with("--tab="):
            _tab = int(arg.trim_prefix("--tab="))
    _main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(_main)


func _process(_delta: float) -> bool:
    _frame += 1
    var size := root.get_visible_rect().size
    if _frame == 2:
        var s: AppSettings = _main.get("settings")
        if _mode >= 0:
            s.art_mode = _mode as AppSettings.ArtMode
        if _style >= 0:
            s.audio_style = _style as AppSettings.AudioStyle
        s.hint_shown = true
        _main.get_node("%SettingsPanel").call("bind_settings", s)
        _main.get_node("%SettingsPanel").call("_dismiss_hint")
        _main.get_node("%ParticleSimulator").call("apply_settings", s)
    if _taps and _frame >= 10 and _frame < 150:
        var step := (_frame - 10) % 22
        var shot := (_frame - 10) / 22
        var p := Vector2(size.x * (0.25 + 0.5 * fmod(float(shot) * 0.618, 1.0)), size.y * (0.22 + 0.3 * fmod(float(shot) * 0.414, 1.0)))
        if step == 0:
            _touch(p, true)
        elif step == 3:
            _touch(p, false)
    elif _frame >= 10 and _frame < 150:
        var t := float(_frame) * 0.05
        var p := size * 0.5 + Vector2(cos(t), sin(t * 1.3)) * size.x * 0.3
        if _frame == 10:
            _touch(p, true)
        var drag := InputEventScreenDrag.new()
        drag.position = p
        Input.parse_input_event(drag)
    if _frame == 150:
        _save(_out + "_canvas.png")
    if _frame == 151 and not _panel:
        return true
    if _frame == 152:
        _touch(size * 0.5, false)
        var panel := _main.get_node("%SettingsPanel")
        panel.call("open")
        var tabs := panel.find_child("SettingsTabs", true, false) as TabContainer
        if tabs != null:
            tabs.current_tab = _tab
    if _frame == 185:
        _save(_out + "_panel.png")
        return true
    return false


func _touch(p: Vector2, pressed: bool) -> void:
    var ev := InputEventScreenTouch.new()
    ev.position = p
    ev.pressed = pressed
    Input.parse_input_event(ev)


func _save(path: String) -> void:
    var img := root.get_texture().get_image()
    img.save_png(path)
    print("saved ", path)
