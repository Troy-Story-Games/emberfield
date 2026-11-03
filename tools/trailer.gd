extends SceneTree
## Records the store trailer: a scripted session with visible taps, slider drags and mode
## changes. The track from tools/trailer_music.py is both the soundtrack and the Audio
## mode input. Run under Movie Maker at a fixed 30 fps (needs a GPU window):
## Godot --path . --write-movie C:/tmp/trailer/frame.png --fixed-fps 30 -s res://tools/trailer.gd -- --music=C:/tmp/trailer/music.wav
## Frames before START_FRAME are window setup and settling; the music and the timeline below start there.
## tools/make_trailer.py then crops that lead-in and builds the landscape video.
## Add --along (with music from `trailer_music.py --along`) for the version where the touch
## instrument plays along with the track: square wave, mid register, A natural minor, one sliding touch.

const FPS := 30.0
const START_FRAME := 90
const SETUP_FRAME := 5
const END_TIME := 58.0
const UI_SCALE := 1.5
const MUSIC_DB := -3.0


class Finger extends Node2D:
    var down: bool = false
    var shown: bool = false
    var ripple: float = 1.0

    func _process(delta: float) -> void:
        ripple = minf(ripple + delta / 0.35, 1.0)
        queue_redraw()

    func _draw() -> void:
        if not shown:
            return
        if down:
            draw_circle(Vector2.ZERO, 34.0, Color(1, 1, 1, 0.28))
            draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 48, Color(1, 1, 1, 0.85), 3.0, true)
        else:
            draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 2.0, true)
        if ripple < 1.0:
            draw_arc(Vector2.ZERO, lerpf(34.0, 80.0, ripple), 0.0, TAU, 48, Color(1, 1, 1, 0.6 * (1.0 - ripple)), 3.0, true)


var _music_path: String = ""
var _along: bool = false
var _frame: int = 0
var _main: Node
var _panel: Node
var _settings: AppSettings
var _finger: Finger
var _popup_finger: Finger
var _pos: Vector2 = Vector2(540, 960)


func _initialize() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--music="):
            _music_path = arg.trim_prefix("--music=")
        elif arg == "--along":
            _along = true
    _main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(_main)
    var layer := CanvasLayer.new()
    layer.layer = 128
    _finger = Finger.new()
    layer.add_child(_finger)
    root.add_child(layer)
    _run()


func _process(_delta: float) -> bool:
    _frame += 1
    if _frame == 1:
        load("res://tools/screenshot.gd").fit_window(root, Vector2i(1080, 1920))
    return _frame >= START_FRAME + int(END_TIME * FPS) + 2


func _now() -> float:
    return float(_frame - START_FRAME) / FPS


func _until(t: float) -> void:
    while _now() < t:
        await process_frame


func _run() -> void:
    while _frame < SETUP_FRAME:
        await process_frame
    _setup()
    while _frame < START_FRAME:
        await process_frame
    _start_music()

    # 0-6 s: Fireworks, tapped on the beat.
    var taps := [Vector2(0.3, 0.3), Vector2(0.7, 0.24), Vector2(0.5, 0.42), Vector2(0.25, 0.55),
        Vector2(0.72, 0.5), Vector2(0.45, 0.28), Vector2(0.62, 0.62), Vector2(0.35, 0.4),
        Vector2(0.6, 0.35), Vector2(0.4, 0.5), Vector2(0.55, 0.22)]
    for k in taps.size():
        await _until(0.25 + k * 0.5)
        await _tap(_screen(taps[k]), 0.12)
    _finger.shown = false

    # 6-16 s: Pulse streams the spent sparks back from the edges, then Black Hole:
    # hold to swallow everything, let go to explode.
    await _until(6.0)
    await _tap_control(_panel.get("menu_button"))
    await _wait(0.45)
    await _tap_control(_chip(AppSettings.ArtMode.WAVE))
    await _wait(0.35)
    await _tap_control(_panel.get("close_button"))
    await _until(7.4)
    await _draw_loop(3.0, 0.26)
    await _until(10.5)
    await _tap_control(_panel.get("menu_button"))
    await _wait(0.45)
    await _tap_control(_chip(AppSettings.ArtMode.BLACK_HOLE))
    await _wait(0.35)
    await _tap_control(_panel.get("close_button"))
    await _until(11.8)
    await _hold(_screen(Vector2(0.5, 0.45)), 15.0)

    # 16-27.5 s: Look tab. Candy colors, more particles, wider, longer trails, glow off.
    await _until(16.0)
    await _tap_control(_panel.get("menu_button"))
    await _wait(0.4)
    await _tap_tab(2)
    await _wait(0.35)
    await _pick(_panel.get("color_option"), AppSettings.ColorPreset.CANDY)
    await _wait(0.3)
    await _slide(_panel.get("count_slider"), 0.75, 1.1)
    await _wait(0.2)
    await _slide(_panel.get("width_slider"), 0.25, 0.6)
    await _wait(0.2)
    await _slide(_panel.get("length_slider"), 0.8, 0.6)
    await _wait(0.25)
    await _tap_control(_panel.get("glow_check"))
    await _wait(0.4)
    await _tap_control(_panel.get("close_button"))
    await _until(22.6)
    await _hold(_screen(Vector2(0.45, 0.5)), 24.9)
    await _wait(0.4)
    await _draw_loop(1.6, 0.22)

    # 27.5-42 s: Audio mode with Playback as the source, landing on the drop at 30 s.
    await _until(27.4)
    await _tap_control(_panel.get("menu_button"))
    await _wait(0.4)
    await _tap_tab(0)
    await _wait(0.35)
    await _tap_control(_chip(AppSettings.ArtMode.AUDIO))
    await _until(29.65)
    await _tap_control(_panel.get("close_button"))
    _finger.shown = false
    await _until(35.4)
    await _tap_control(_panel.get("menu_button"))
    await _wait(0.4)
    await _pick(_panel.get("_audio_style"), AppSettings.AudioStyle.GALAXY)
    await _wait(0.3)
    await _tap_control(_panel.get("close_button"))
    _finger.shown = false

    # 42-52 s: Orbit with the touch instrument on, playing a melody over the breakdown.
    await _until(42.0)
    await _tap_control(_panel.get("menu_button"))
    await _wait(0.4)
    await _tap_control(_chip(AppSettings.ArtMode.ORBIT))
    await _wait(0.3)
    await _tap_tab(1)
    await _wait(0.35)
    await _tap_control(_panel.get("_touch_audio_check"))
    await _wait(0.35)
    await _tap_control(_panel.get("close_button"))
    if _along:
        await _play_along()
    else:
        await _play_melody()

    # 52-58 s: back to Fireworks for the end card.
    await _until(51.95)
    _settings.touch_audio = false
    _settings.art_mode = AppSettings.ArtMode.FIREWORKS
    _panel.call("bind_settings", _settings)
    _main.get_node("%ParticleSimulator").call("apply_settings", _settings)
    var finale := [Vector2(0.5, 0.3), Vector2(0.28, 0.42), Vector2(0.72, 0.38), Vector2(0.5, 0.52),
        Vector2(0.35, 0.25), Vector2(0.66, 0.24)]
    for k in finale.size():
        await _until(52.0 + k * 0.5)
        await _tap(_screen(finale[k]), 0.1)
    _finger.shown = false


func _setup() -> void:
    _settings = _main.get("settings")
    _settings.reset_to_defaults()
    _settings.art_mode = AppSettings.ArtMode.FIREWORKS
    _settings.fw_size = 2.0
    _settings.length = 0.7
    _settings.audio_source = AppSettings.AudioSource.PLAYBACK
    _settings.audio_style = AppSettings.AudioStyle.EQUALIZER_CIRCULAR
    _settings.touch_audio_root = 9
    _settings.touch_audio_scale = AppSettings.TouchScale.MINOR_PENTATONIC
    _settings.touch_audio_glide = 0.0
    _settings.touch_audio_volume = 1.0
    _settings.touch_audio_tone = 1.6
    _settings.touch_audio_release = 0.12
    if _along:
        _settings.touch_audio_register = AppSettings.TouchRegister.MID
        _settings.touch_audio_scale = AppSettings.TouchScale.NATURAL_MINOR
        _settings.touch_audio_octaves = 2.0
        _settings.touch_audio_glide = 0.24
        _settings.touch_audio_wave = AppSettings.TouchWave.SQUARE
        _settings.touch_audio_volume = 0.3
        _settings.touch_audio_tone = 1.0
    _settings.hint_shown = true
    _panel = _main.get_node("%SettingsPanel")
    load("res://tools/screenshot.gd").set_ui_scale(_panel, UI_SCALE)
    _panel.call("bind_settings", _settings)
    _panel.call("_dismiss_hint")
    var sim := _main.get_node("%ParticleSimulator")
    sim.call("apply_settings", _settings)
    # Particles spawned before the window shrank to phone size; spread them over the new size.
    var positions: PackedVector2Array = sim.get("positions")
    for i in positions.size():
        positions[i] = Vector2(randf(), randf()) * _view()
    sim.set("positions", positions)


func _start_music() -> void:
    if _music_path == "":
        return
    var stream := AudioStreamWAV.load_from_file(_music_path)
    # One copy is heard (and recorded); the other feeds the muted analyzer, as captured playback would.
    for bus in ["Master", AudioFeed.BUS_NAME]:
        var player := AudioStreamPlayer.new()
        player.stream = stream
        player.bus = bus
        player.volume_db = MUSIC_DB if bus == "Master" else 0.0
        root.add_child(player)
        player.play()


func _play_melody() -> void:
    # A minor pentatonic over two octaves from A4: index 0 is the bottom of the screen.
    # [start time, scale step, seconds held]
    var notes := [
        [44.5, 4, 0.42], [45.0, 3, 0.42], [45.5, 2, 0.42],
        [46.0, 2, 0.68], [46.75, 3, 0.2], [47.0, 4, 0.9],
        [48.0, 5, 0.68], [48.75, 6, 0.2], [49.0, 8, 0.42], [49.5, 7, 0.42],
        [50.0, 6, 0.42], [50.5, 5, 0.42], [51.0, 5, 0.75],
    ]
    var steps := 10
    var size := _view()
    for k in notes.size():
        var n: Array = notes[k]
        var y := size.y * (1.0 - (float(n[1]) + 0.5) / float(steps))
        # Volume follows x, so keep to the right half while drifting for variety.
        var x := size.x * (0.84 + 0.1 * sin(float(k) * 1.3))
        await _glide(Vector2(x, y), maxf(0.04, float(n[0]) - _now() - 0.02))
        await _until(float(n[0]))
        await _tap(Vector2(x, y), float(n[2]))


## The --along melody: A natural minor from A3 (step 0) over two octaves, following the track's
## F - C - G - Am. One unbroken touch slides from note to note, arriving on each beat, while
## sweeping left and right so the volume rises and falls. [time, step]
func _play_along() -> void:
    var notes := [
        [44.5, 5], [45.0, 7], [45.5, 9], [45.75, 7],
        [46.0, 6], [46.5, 4], [47.0, 2], [47.5, 4], [47.75, 6],
        [48.0, 8], [48.5, 10], [49.0, 12], [49.5, 10], [49.75, 8],
        [50.0, 11], [50.5, 9], [51.0, 7], [51.25, 4], [51.5, 7],
    ]
    const SLIDE := 0.13
    const END := 51.85
    var size := _view()
    var at := func(t: float, step: float) -> Vector2:
        var x := 0.7 + 0.25 * sin(TAU * (t - 44.5) / 3.0)
        return Vector2(size.x * x, size.y * (1.0 - (step + 0.5) / 14.0))
    var start: float = notes[0][0]
    await _glide(at.call(start, float(notes[0][1])), maxf(0.04, start - _now() - 0.02))
    await _until(start)
    _press(at.call(start, float(notes[0][1])))
    while _now() < END:
        var t := _now()
        var step := float(notes[0][1])
        for k in range(1, notes.size()):
            var to: float = notes[k][0]
            if t < to - SLIDE:
                break
            var k2 := clampf((t - (to - SLIDE)) / SLIDE, 0.0, 1.0)
            step = lerpf(float(notes[k - 1][1]), float(notes[k][1]), k2 * k2 * (3.0 - 2.0 * k2))
        _move(at.call(t, step))
        await process_frame
    _release()


func _view() -> Vector2:
    return root.get_visible_rect().size


func _screen(frac: Vector2) -> Vector2:
    return frac * _view()


func _wait(seconds: float) -> void:
    await _until(_now() + seconds)


func _chip(mode: AppSettings.ArtMode) -> Control:
    return (_panel.get("_mode_buttons") as Array)[int(mode)]


func _center(control: Control) -> Vector2:
    var local := control.size * 0.5
    # A check box row is as wide as the panel; aim for the box itself.
    if control is CheckBox:
        local.x = minf(local.x, control.size.y * 0.5)
    return control.get_global_transform_with_canvas() * local


func _tap_control(control: Control) -> void:
    await _glide(_center(control), 0.22)
    await _tap(_center(control), 0.1)


func _tap_tab(index: int) -> void:
    var tabs := _panel.find_child("SettingsTabs", true, false) as TabContainer
    var bar := tabs.get_tab_bar()
    var p := bar.get_global_transform_with_canvas() * bar.get_tab_rect(index).get_center()
    await _glide(p, 0.22)
    await _tap(p, 0.1)


## Opens a dropdown, then taps the item. Item rows are evenly spaced in the popup.
func _pick(option: OptionButton, index: int) -> void:
    await _tap_control(option)
    await _wait(0.3)
    var popup := option.get_popup()
    var rect := Rect2(Vector2(popup.position), Vector2(popup.size))
    var p := Vector2(rect.get_center().x, rect.position.y + rect.size.y * (float(index) + 0.5) / float(popup.item_count))
    # Popups draw above every canvas layer, so the finger needs a copy inside the popup.
    _popup_finger = Finger.new()
    _popup_finger.scale = Vector2.ONE / popup.content_scale_factor
    popup.add_child(_popup_finger)
    await _glide(p, 0.3)
    await _tap(p, 0.1)
    await _wait(0.1)
    _popup_finger.queue_free()
    _popup_finger = null
    if option.selected != index:
        push_warning("Dropdown tap missed; selecting item %d directly" % index)
        popup.hide()
        option.select(index)
        option.item_selected.emit(index)


func _slide(slider: HSlider, ratio: float, seconds: float) -> void:
    var xf := slider.get_global_transform_with_canvas()
    var start := (slider.value - slider.min_value) / (slider.max_value - slider.min_value)
    var from := xf * Vector2(slider.size.x * start, slider.size.y * 0.5)
    var to := xf * Vector2(slider.size.x * ratio, slider.size.y * 0.5)
    await _glide(from, 0.25)
    _press(from)
    await _wait(0.08)
    await _glide(to, seconds)
    await _wait(0.08)
    _release()


func _tap(p: Vector2, hold: float) -> void:
    _press(p)
    await _wait(hold)
    _release()


## Holds until `release_at` on the timeline, so slow steps before it don't push the release late.
func _hold(p: Vector2, release_at: float) -> void:
    await _glide(p, 0.2)
    _press(p)
    var t0 := _now()
    while _now() < release_at:
        var a := (_now() - t0) * 3.0
        _move(p + Vector2(cos(a), sin(a * 1.4)) * 18.0)
        await process_frame
    _release()


func _draw_loop(seconds: float, radius: float) -> void:
    var size := _view()
    var at := func(a: float) -> Vector2:
        return size * 0.5 + Vector2(cos(a), sin(a * 2.0) * 0.8) * size.x * radius * 1.4
    await _glide(at.call(0.0), 0.2)
    _press(at.call(0.0))
    var t0 := _now()
    while _now() - t0 < seconds:
        _move(at.call((_now() - t0) * 2.4))
        await process_frame
    _release()


## Moves the finger over `seconds` with easing. While it is down, each step is a drag.
func _glide(to: Vector2, seconds: float) -> void:
    _finger.shown = true
    var from := _pos
    var t0 := _now()
    while true:
        var k := clampf((_now() - t0) / maxf(seconds, 0.001), 0.0, 1.0)
        _move(from.lerp(to, k * k * (3.0 - 2.0 * k)))
        if k >= 1.0:
            return
        await process_frame


func _press(p: Vector2) -> void:
    _pos = p
    _finger.shown = true
    _finger.down = true
    _finger.ripple = 0.0
    _sync_popup_finger()
    var ev := InputEventScreenTouch.new()
    ev.position = p
    ev.pressed = true
    Input.parse_input_event(ev)


func _move(p: Vector2) -> void:
    var rel := p - _pos
    _pos = p
    _sync_popup_finger()
    if not _finger.down or rel == Vector2.ZERO:
        return
    var ev := InputEventScreenDrag.new()
    ev.position = p
    ev.relative = rel
    ev.velocity = rel * FPS
    Input.parse_input_event(ev)


func _release() -> void:
    _finger.down = false
    _sync_popup_finger()
    var ev := InputEventScreenTouch.new()
    ev.position = _pos
    ev.pressed = false
    Input.parse_input_event(ev)


func _sync_popup_finger() -> void:
    _finger.position = _pos
    if _popup_finger == null:
        return
    var popup := _popup_finger.get_parent() as Window
    _popup_finger.position = (_pos - Vector2(popup.position)) / popup.content_scale_factor
    _popup_finger.shown = _finger.shown
    _popup_finger.down = _finger.down
    _popup_finger.ripple = _finger.ripple
