extends SceneTree
## Checks that every settings page fits a 1080x1920 portrait phone without scrolling.
## Godot --headless --path . -s res://tools/settings_fit.gd [-- --scale=2.0]
## Prints each page's height against the space it has, and exits with code 1 if any
## page overflows. 2.0 is the largest phone UI scale, so it is the tightest case.

const SCREEN := Vector2i(1080, 1920)

var _scale: float = 2.0
var _cases: Array = []
var _frame: int = 0
var _index: int = 0
var _failed: bool = false
var _panel: Node
var _settings: AppSettings = AppSettings.new()


func _initialize() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--scale="):
            _scale = float(arg.trim_prefix("--scale="))
    _panel = (load("res://scenes/settings_panel.tscn") as PackedScene).instantiate()
    root.add_child(_panel)
    # [tab, art mode, audio style, touch instrument on]
    for mode in AppSettings.ArtMode.size():
        if mode != AppSettings.ArtMode.AUDIO:
            _cases.append([0, mode, 0, false])
    for style in AppSettings.AudioStyle.size():
        _cases.append([0, AppSettings.ArtMode.AUDIO, style, false])
    _cases.append([1, AppSettings.ArtMode.WAVE, 0, false])
    _cases.append([1, AppSettings.ArtMode.WAVE, 0, true])
    _cases.append([2, AppSettings.ArtMode.WAVE, 0, false])
    _cases.append([3, AppSettings.ArtMode.WAVE, 0, false])
    print("Settings fit at %dx%d, UI scale %.2f" % [SCREEN.x, SCREEN.y, _scale])


func _process(_delta: float) -> bool:
    _frame += 1
    if _frame == 2:
        _panel.set("_ui_scale", _scale)
        _panel.call("open")
    # The headless window is tiny, so size the panel for the phone screen every frame
    # (the panel refits itself to the real window on resize). Layout is in unscaled
    # units, so the panel's on-screen scale doesn't matter here.
    if _frame >= 2:
        _panel.call("_set_panel_size", _panel.call("_panel_size_for", Vector2(SCREEN)))
    # Apply a case, give the containers two frames to lay out, then measure.
    if _frame < 4 or _frame % 3 != 0:
        return false
    if _index > 0:
        _measure(_cases[_index - 1])
    if _index == _cases.size():
        print("FAIL: a settings page needs scrolling." if _failed else "OK: every page fits.")
        quit(1 if _failed else 0)
        return false
    var c: Array = _cases[_index]
    _settings.art_mode = c[1]
    _settings.audio_style = c[2]
    _settings.touch_audio = c[3]
    _settings.hint_shown = true
    _panel.call("bind_settings", _settings)
    (_panel.find_child("SettingsTabs", true, false) as TabContainer).current_tab = c[0]
    _index += 1
    return false


func _measure(c: Array) -> void:
    var tabs := _panel.find_child("SettingsTabs", true, false) as TabContainer
    var holder := tabs.get_current_tab_control()
    var page := holder.get_node("Scroll") as ScrollContainer
    var need := page.get_child(0) as Control
    var view := page.size.y
    var content := need.get_combined_minimum_size().y
    var label := holder.name
    if c[0] == 0:
        label += " / " + AppSettings.art_mode_name(c[1])
        if c[1] == AppSettings.ArtMode.AUDIO:
            label += " / " + AppSettings.audio_style_name(c[2])
    elif c[3]:
        label += " / touch instrument"
    var fits := content <= view
    _failed = _failed or not fits
    print("%-4s %-36s %4d / %4d" % ["ok" if fits else "OVER", label, int(content), int(view)])
