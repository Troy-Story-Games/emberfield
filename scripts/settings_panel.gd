extends CanvasLayer
## Settings overlay for art modes and particle/display options.

signal settings_changed(settings: AppSettings)
signal visibility_toggled(open: bool)

const MENU_SIZE := 72.0
const MENU_MARGIN_X := 4.0
const MENU_MARGIN_Y := 2.0
const PHONE_DPI_THRESHOLD := 280
const PHONE_SHORT_SIDE_MAX := 1100.0
const REPO_URL := "https://github.com/Troy-Story-Games/emberfield"
## Seconds without a touch before the menu button fades out of the way.
const MENU_IDLE_FADE := 3.0
const MENU_IDLE_ALPHA := 0.0
const SAVE_DELAY := 0.6

@onready var panel: PanelContainer = %Panel
@onready var mode_option: OptionButton = %ModeOption
@onready var mode_options: VBoxContainer = %ModeOptions
@onready var vortex_options: VBoxContainer = %VortexOptions
@onready var repel_options: VBoxContainer = %RepelOptions
@onready var vortex_radius_slider: HSlider = %VortexRadiusSlider
@onready var vortex_radius_label: Label = %VortexRadiusLabel
@onready var vortex_speed_slider: HSlider = %VortexSpeedSlider
@onready var vortex_speed_label: Label = %VortexSpeedLabel
@onready var vortex_pull_slider: HSlider = %VortexPullSlider
@onready var vortex_pull_label: Label = %VortexPullLabel
@onready var vortex_dir_option: OptionButton = %VortexDirOption
@onready var repel_strength_slider: HSlider = %RepelStrengthSlider
@onready var repel_strength_label: Label = %RepelStrengthLabel
@onready var invert_check: CheckBox = %InvertCheck
@onready var auto_check: CheckBox = %AutoCheck
@onready var glow_check: CheckBox = %GlowCheck
@onready var fps_check: CheckBox = %FpsCheck
@onready var fps_label: Label = %FpsLabel
@onready var idle_option: OptionButton = %IdleOption
@onready var color_option: OptionButton = %ColorOption
@onready var count_slider: HSlider = %CountSlider
@onready var count_label: Label = %CountLabel
@onready var width_slider: HSlider = %WidthSlider
@onready var width_label: Label = %WidthLabel
@onready var length_slider: HSlider = %LengthSlider
@onready var length_label: Label = %LengthLabel
@onready var reset_defaults_button: Button = %ResetDefaultsButton
@onready var close_button: Button = %CloseButton
@onready var menu_button: Button = %MenuButton

var settings: AppSettings
var _updating_ui: bool = false
var _ui_scale: float = 1.0
var _fps_accum: float = 0.0
var _fps_frames: int = 0
var _theme: Theme
var _save_timer: Timer
var _scrim: ColorRect
var _hint: Label
var _about_box: VBoxContainer
var _reduce_flashing_check: CheckBox
var _gate: Control
var _gate_center: CenterContainer
var _gate_card: PanelContainer
var _gate_question: Label
var _gate_answer: LineEdit
var _gate_note: Label
var _gate_expected: int = 0
var _gate_on_pass: Callable
var _menu_idle: float = 0.0
var _menu_tween: Tween
var _menu_target: float = 1.0
var _panel_tween: Tween
var _mode_buttons: Array[Button] = []
var _frame_rate: OptionButton

var _pulse_options: VBoxContainer
var _sink_options: VBoxContainer
var _flow_options: VBoxContainer
var _lightning_options: VBoxContainer
var _bh_options: VBoxContainer
var _beam_options: VBoxContainer
var _orbit_options: VBoxContainer
var _ripple_options: VBoxContainer
var _magnet_options: VBoxContainer
var _fluid_options: VBoxContainer
var _fireworks_options: VBoxContainer
## Sliders wired by property name: [label, slider, title, AppSettings property].
var _setting_rows: Array = []
var _audio_arms_label: Label
var _audio_arms: OptionButton

var _pulse_emit: HSlider
var _pulse_kick: HSlider
var _pulse_ring: HSlider
var _sink_attract: HSlider
var _sink_inflow: HSlider
var _sink_radius: HSlider
var _flow_field: HSlider
var _flow_pull: HSlider
var _lightning_attract: HSlider
var _lightning_discharge: HSlider
var _lightning_charge: HSlider
var _bh_strength: HSlider
var _bh_damping: HSlider
var _bh_explode: HSlider
var _beam_speed: HSlider
var _beam_attract: HSlider
var _beam_cone: HSlider
var _orbit_radius: HSlider
var _orbit_speed: HSlider
var _orbit_attract: HSlider
var _ripple_speed: HSlider
var _ripple_power: HSlider
var _ripple_rate: HSlider
var _magnet_gap: HSlider
var _magnet_attract: HSlider
var _magnet_repel: HSlider
var _audio_options: VBoxContainer
var _audio_source: OptionButton
var _audio_range: OptionButton
var _audio_style: OptionButton
var _audio_style_auto: CheckBox
var _audio_algorithm_label: Label
var _audio_algorithm: OptionButton
var _audio_direction_label: Label
var _audio_direction: OptionButton
var _audio_sensitivity: HSlider
var _audio_smooth: HSlider
var _audio_status: Label
var _hint_label: Label
var _sound_box: VBoxContainer
var _sound_note: Label

var _touch_audio_group: VBoxContainer
var _touch_audio_check: CheckBox
var _touch_audio_extras: VBoxContainer
var _touch_volume: HSlider
var _touch_root: OptionButton
var _touch_register: OptionButton
var _touch_scale: OptionButton
var _touch_octaves: HSlider
var _touch_glide: HSlider
var _touch_tone: HSlider
var _touch_attack: HSlider
var _touch_release: HSlider
var _touch_wave: OptionButton
var _touch_volume_label: Label
var _touch_octaves_label: Label
var _touch_glide_label: Label
var _touch_tone_label: Label
var _touch_attack_label: Label
var _touch_release_label: Label

var _pulse_emit_label: Label
var _pulse_kick_label: Label
var _pulse_ring_label: Label
var _sink_attract_label: Label
var _sink_inflow_label: Label
var _sink_radius_label: Label
var _flow_field_label: Label
var _flow_pull_label: Label
var _lightning_attract_label: Label
var _lightning_discharge_label: Label
var _lightning_charge_label: Label
var _bh_strength_label: Label
var _bh_damping_label: Label
var _bh_explode_label: Label
var _beam_speed_label: Label
var _beam_attract_label: Label
var _beam_cone_label: Label
var _orbit_radius_label: Label
var _orbit_speed_label: Label
var _orbit_attract_label: Label
var _ripple_speed_label: Label
var _ripple_power_label: Label
var _ripple_rate_label: Label
var _magnet_gap_label: Label
var _magnet_attract_label: Label
var _magnet_repel_label: Label
var _audio_sensitivity_label: Label
var _audio_smooth_label: Label


func _ready() -> void:
    var win := get_window()
    if win:
        win.content_scale_factor = 1.0

    _ui_scale = _compute_ui_scale()
    _theme = UiTheme.build()
    _build_scrim()
    _split_settings_tabs()
    _build_mode_grid()
    _build_mode_option_groups()
    _build_touch_audio_group()
    _build_reduce_flashing_row()
    _build_frame_rate_row()
    _build_about()
    _style_overlay()
    _inline_rows(panel)
    _build_first_run_hint()
    _build_grown_up_gate()
    _save_timer = Timer.new()
    _save_timer.one_shot = true
    _save_timer.wait_time = SAVE_DELAY
    _save_timer.timeout.connect(_save_now)
    add_child(_save_timer)
    _apply_ui_scale_to_controls()
    _layout_menu_button()
    _layout_fps_label()
    get_viewport().size_changed.connect(_on_viewport_resized)

    mode_option.clear()
    for mode_id in range(AppSettings.ArtMode.size()):
        mode_option.add_item(AppSettings.art_mode_name(mode_id as AppSettings.ArtMode), mode_id)

    color_option.clear()
    for preset_id in range(AppSettings.ColorPreset.size()):
        color_option.add_item(AppSettings.color_preset_name(preset_id as AppSettings.ColorPreset), preset_id)

    idle_option.clear()
    for idle_id in range(AppSettings.IdleMode.size()):
        idle_option.add_item(AppSettings.idle_mode_name(idle_id as AppSettings.IdleMode), idle_id)

    vortex_dir_option.clear()
    for dir_id in range(AppSettings.VortexDirection.size()):
        vortex_dir_option.add_item(AppSettings.vortex_direction_name(dir_id as AppSettings.VortexDirection), dir_id)

    count_slider.min_value = AppSettings.MIN_PARTICLES
    count_slider.max_value = AppSettings.MAX_PARTICLES
    count_slider.step = 1
    width_slider.min_value = AppSettings.MIN_WIDTH
    width_slider.max_value = AppSettings.MAX_WIDTH
    width_slider.step = 1
    length_slider.min_value = AppSettings.MIN_LENGTH
    length_slider.max_value = AppSettings.MAX_LENGTH
    length_slider.step = 0.01

    vortex_radius_slider.min_value = AppSettings.MIN_VORTEX_RADIUS
    vortex_radius_slider.max_value = AppSettings.MAX_VORTEX_RADIUS
    vortex_radius_slider.step = 1
    vortex_speed_slider.min_value = AppSettings.MIN_VORTEX_SPEED
    vortex_speed_slider.max_value = AppSettings.MAX_VORTEX_SPEED
    vortex_speed_slider.step = 0.05
    vortex_pull_slider.min_value = AppSettings.MIN_VORTEX_PULL
    vortex_pull_slider.max_value = AppSettings.MAX_VORTEX_PULL
    vortex_pull_slider.step = 0.05
    repel_strength_slider.min_value = AppSettings.MIN_REPEL_STRENGTH
    repel_strength_slider.max_value = AppSettings.MAX_REPEL_STRENGTH
    repel_strength_slider.step = 0.05

    mode_option.item_selected.connect(_on_mode_selected)
    invert_check.toggled.connect(_on_invert_toggled)
    auto_check.toggled.connect(_on_auto_toggled)
    glow_check.toggled.connect(_on_glow_toggled)
    fps_check.toggled.connect(_on_fps_toggled)
    color_option.item_selected.connect(_on_color_selected)
    idle_option.item_selected.connect(_on_idle_selected)
    count_slider.value_changed.connect(_on_count_changed)
    width_slider.value_changed.connect(_on_width_changed)
    length_slider.value_changed.connect(_on_length_changed)
    vortex_radius_slider.value_changed.connect(_on_vortex_radius_changed)
    vortex_speed_slider.value_changed.connect(_on_vortex_speed_changed)
    vortex_pull_slider.value_changed.connect(_on_vortex_pull_changed)
    vortex_dir_option.item_selected.connect(_on_vortex_dir_selected)
    repel_strength_slider.value_changed.connect(_on_repel_strength_changed)
    reset_defaults_button.pressed.connect(_on_reset_defaults_pressed)
    close_button.pressed.connect(close)
    menu_button.pressed.connect(toggle)
    _annotate_controls(panel)

    panel.visible = false
    menu_button.visible = true
    _update_mode_options_visibility()


func _build_scrim() -> void:
    # Dim the canvas behind the panel; tapping it closes the panel.
    _scrim = ColorRect.new()
    _scrim.name = "Scrim"
    _scrim.color = Color(0, 0, 0, 0.35)
    _scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _scrim.mouse_filter = Control.MOUSE_FILTER_STOP
    _scrim.visible = false
    _scrim.gui_input.connect(_on_scrim_input)
    add_child(_scrim)
    move_child(_scrim, panel.get_index())


func _on_scrim_input(event: InputEvent) -> void:
    var tapped := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
        or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
    if tapped:
        close()
        get_viewport().set_input_as_handled()


func _build_mode_grid() -> void:
    # Chips are quicker to scan and tap than a dropdown. ModeOption stays as the hidden model.
    var grid := GridContainer.new()
    grid.name = "ModeGrid"
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    var group := ButtonGroup.new()
    for mode_id in range(AppSettings.ArtMode.size()):
        var chip := Button.new()
        chip.text = AppSettings.art_mode_name(mode_id as AppSettings.ArtMode)
        chip.toggle_mode = true
        chip.button_group = group
        chip.focus_mode = Control.FOCUS_NONE
        chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        chip.custom_minimum_size = Vector2(0, 48)
        chip.clip_text = true
        chip.pressed.connect(_on_mode_chip_pressed.bind(mode_id))
        _explain(chip, _mode_tip(mode_id as AppSettings.ArtMode))
        grid.add_child(chip)
        _mode_buttons.append(chip)
    var parent := mode_option.get_parent()
    parent.add_child(grid)
    parent.move_child(grid, mode_option.get_index() + 1)
    mode_option.visible = false


func _on_mode_chip_pressed(mode_id: int) -> void:
    if _updating_ui or settings == null or int(settings.art_mode) == mode_id:
        return
    mode_option.select(mode_id)
    _on_mode_selected(mode_id)


func _sync_mode_grid() -> void:
    if settings == null:
        return
    for mode_id in _mode_buttons.size():
        _mode_buttons[mode_id].set_pressed_no_signal(mode_id == int(settings.art_mode))


func _mode_tip(mode: AppSettings.ArtMode) -> String:
    match mode:
        AppSettings.ArtMode.WAVE:
            return "Pulse: tap for a shockwave, hold to stream particles from your finger."
        AppSettings.ArtMode.PARTICLE:
            return "Vortex: particles spin in a tight whirl around your finger."
        AppSettings.ArtMode.GRAVITY:
            return "Repel: push the particles away from your finger."
        AppSettings.ArtMode.LIGHTNING:
            return "Lightning: hold to charge, and the particles strike outward."
        AppSettings.ArtMode.LINEAR:
            return "Flow: drag to steer a current. Tilt the phone to change its direction."
        AppSettings.ArtMode.BLACK_HOLE:
            return "Black Hole: hold to swallow everything, then let go to explode."
        AppSettings.ArtMode.SINK:
            return "Sink: particles pour into your finger and respawn at the edges."
        AppSettings.ArtMode.BEAM:
            return "Beam: hold to gather, then drag to fire a beam."
        AppSettings.ArtMode.ORBIT:
            return "Orbit: particles settle into rings around your finger."
        AppSettings.ArtMode.RIPPLE:
            return "Ripple: hold to send waves rolling out across the screen."
        AppSettings.ArtMode.MAGNET:
            return "Magnet: one pole pulls and one pushes. Drag to turn the magnet."
        AppSettings.ArtMode.AUDIO:
            return "Audio: particles dance to the microphone or to music playing on this device."
        AppSettings.ArtMode.FLUID:
            return "Fluid: drifting smoke. Drag through it to stir up swirls."
        AppSettings.ArtMode.FIREWORKS:
            return "Fireworks: tap to launch a burst, hold to keep firing, drag for a comet tail."
    return ""


func _build_reduce_flashing_row() -> void:
    _reduce_flashing_check = CheckBox.new()
    _reduce_flashing_check.name = "ReduceFlashingCheck"
    _reduce_flashing_check.text = "Reduce flashing"
    _reduce_flashing_check.toggled.connect(_on_reduce_flashing_toggled)
    var parent := glow_check.get_parent()
    parent.add_child(_reduce_flashing_check)
    parent.move_child(_reduce_flashing_check, glow_check.get_index() + 1)


func _build_frame_rate_row() -> void:
    var parent := fps_check.get_parent()
    var at := fps_check.get_index() + 1
    var label := Label.new()
    label.text = "Frame rate"
    _frame_rate = OptionButton.new()
    _frame_rate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for fps in AppSettings.FRAME_RATES:
        _frame_rate.add_item(AppSettings.frame_rate_name(fps))
    _frame_rate.item_selected.connect(_on_frame_rate_selected)
    parent.add_child(label)
    parent.move_child(label, at)
    parent.add_child(_frame_rate)
    parent.move_child(_frame_rate, at + 1)


func _build_about() -> void:
    var name_label := Label.new()
    name_label.text = "%s %s" % [
        ProjectSettings.get_setting("application/config/name", "Emberfield"),
        ProjectSettings.get_setting("application/config/version", ""),
    ]
    _about_box.add_child(name_label)
    for line in [
        "Free and open source. No ads, no trackers, no accounts.",
        "Audio is analyzed on this device and never recorded, stored or sent.",
    ]:
        var note := Label.new()
        note.text = line
        note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        note.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
        _about_box.add_child(note)
    var link := LinkButton.new()
    link.text = "Source code and issues"
    link.add_theme_color_override("font_color", UiTheme.ACCENT)
    link.add_theme_color_override("font_hover_color", Color(1, 0.75, 0.5))
    link.pressed.connect(_ask_grown_up.bind("This opens the Emberfield page on GitHub in your browser.", _open_repo))
    _about_box.add_child(link)


func _open_repo() -> void:
    OS.shell_open(REPO_URL)


func _style_overlay() -> void:
    panel.theme = _theme
    menu_button.theme = _theme
    menu_button.theme_type_variation = UiTheme.MENU
    menu_button.focus_mode = Control.FOCUS_NONE
    fps_label.theme = _theme
    var title := panel.find_child("Title", true, false) as Label
    if title != null:
        title.text = ProjectSettings.get_setting("application/config/name", "Emberfield")
        title.add_theme_font_size_override("font_size", 26)
    # Idle and Color are plain row labels in the Display section, not headers.
    for header_name in ["ModeLabel", "ModeOptionsLabel", "DisplayLabel", "ParticleLabel"]:
        var header := panel.find_child(header_name, true, false) as Label
        if header != null:
            header.theme_type_variation = UiTheme.HEADER
            header.uppercase = true
    reset_defaults_button.focus_mode = Control.FOCUS_NONE
    close_button.focus_mode = Control.FOCUS_NONE


func _build_first_run_hint() -> void:
    _hint = Label.new()
    _hint.name = "FirstRunHint"
    _hint.text = "Touch and drag to play\nTap ☰ for modes and settings"
    _hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hint.add_theme_font_size_override("font_size", 22)
    _hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
    _hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
    _hint.add_theme_constant_override("outline_size", 6)
    _hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    _hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
    _hint.offset_bottom = -120.0
    _hint.scale = Vector2(_ui_scale, _ui_scale)
    _hint.visible = false
    add_child(_hint)


## Grown-up check in front of what a young child shouldn't reach alone: links out of
## the app, and capturing other apps' audio. Play's Families policy expects one.
func _build_grown_up_gate() -> void:
    _gate = Control.new()
    _gate.name = "GrownUpGate"
    _gate.theme = _theme
    _gate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _gate.mouse_filter = Control.MOUSE_FILTER_STOP
    _gate.visible = false
    add_child(_gate)
    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.6)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _gate.add_child(dim)
    # Upper half of the screen, so the number keyboard doesn't cover it. The container
    # carries the UI scale, because a container resets its child's scale on layout.
    _gate_center = CenterContainer.new()
    _gate_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _gate.add_child(_gate_center)
    var card := PanelContainer.new()
    _gate_card = card
    _gate_center.add_child(card)
    _layout_gate()
    var margin := MarginContainer.new()
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 20)
    card.add_child(margin)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    margin.add_child(box)
    var header := Label.new()
    header.text = "Ask a grown-up"
    header.theme_type_variation = UiTheme.HEADER
    header.uppercase = true
    box.add_child(header)
    _gate_note = Label.new()
    _gate_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _gate_note.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
    box.add_child(_gate_note)
    _gate_question = Label.new()
    _gate_question.add_theme_font_size_override("font_size", 26)
    box.add_child(_gate_question)
    _gate_answer = LineEdit.new()
    _gate_answer.placeholder_text = "Answer"
    _gate_answer.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
    _gate_answer.text_submitted.connect(func(_text: String) -> void: _check_gate())
    box.add_child(_gate_answer)
    var buttons := HBoxContainer.new()
    buttons.add_theme_constant_override("separation", 8)
    box.add_child(buttons)
    var cancel := Button.new()
    cancel.text = "Cancel"
    cancel.focus_mode = Control.FOCUS_NONE
    cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cancel.pressed.connect(_cancel_gate)
    buttons.add_child(cancel)
    var ok := Button.new()
    ok.text = "OK"
    ok.focus_mode = Control.FOCUS_NONE
    ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    ok.pressed.connect(_check_gate)
    buttons.add_child(ok)


## Sizes the gate's upper-half area in unscaled units, then scales it to fill the screen.
func _layout_gate() -> void:
    if _gate_center == null:
        return
    var view := get_viewport().get_visible_rect().size
    _gate_center.position = Vector2.ZERO
    _gate_center.scale = Vector2(_ui_scale, _ui_scale)
    _gate_center.size = Vector2(view.x, view.y * 0.5) / _ui_scale
    _gate_card.custom_minimum_size = Vector2(minf(380.0, view.x / _ui_scale - 32.0), 0)


## Shows the gate and calls on_pass only after a correct answer.
func _ask_grown_up(reason: String, on_pass: Callable) -> void:
    _gate_on_pass = on_pass
    _new_gate_question(reason)
    _gate.visible = true
    _gate_answer.call_deferred("grab_focus")


## Times tables from 6 to 12: instant for most adults, but it skips the ×2, ×5 and ×10
## facts young kids learn first.
func _new_gate_question(note: String) -> void:
    const FACTORS := [6, 7, 8, 9, 11, 12]
    var a: int = FACTORS.pick_random()
    var b: int = FACTORS.pick_random()
    _gate_expected = a * b
    _gate_question.text = "What is %d × %d?" % [a, b]
    _gate_note.text = note
    _gate_answer.text = ""


func _check_gate() -> void:
    if not _gate.visible:
        return
    if _gate_answer.text.strip_edges() != str(_gate_expected):
        _new_gate_question("Not quite. Try this one.")
        _gate_answer.grab_focus()
        return
    var on_pass := _gate_on_pass
    _hide_gate()
    if on_pass.is_valid():
        on_pass.call()


func _cancel_gate() -> void:
    _hide_gate()


func _hide_gate() -> void:
    _gate.visible = false
    _gate_on_pass = Callable()
    _gate_answer.release_focus()
    if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
        DisplayServer.virtual_keyboard_hide()


## Shown once, until the first touch or the panel opens.
func _show_hint_if_new() -> void:
    if _hint == null or settings == null or settings.hint_shown:
        return
    _hint.visible = true
    _hint.pivot_offset = Vector2(_hint.size.x * 0.5, _hint.size.y)


func _dismiss_hint() -> void:
    if _hint == null or not _hint.visible:
        return
    if settings != null and not settings.hint_shown:
        settings.hint_shown = true
        _queue_save()
    var tween := create_tween()
    tween.tween_property(_hint, "modulate:a", 0.0, 0.6)
    tween.tween_callback(_hint.hide)


func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseMotion:
        _wake_menu()
    if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
        _dismiss_hint()


func _wake_menu() -> void:
    _menu_idle = 0.0
    if _menu_target < 1.0:
        _fade_menu(1.0, 0.15)


func _fade_menu(alpha: float, seconds: float) -> void:
    _menu_target = alpha
    if _menu_tween != null:
        _menu_tween.kill()
    _menu_tween = create_tween()
    _menu_tween.tween_property(menu_button, "modulate:a", alpha, seconds)


func _build_mode_option_groups() -> void:
    var pulse := _make_group()
    _pulse_emit_label = _add_slider_row(pulse, "Emit rate", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _pulse_emit = pulse.get_child(pulse.get_child_count() - 1) as HSlider
    _pulse_kick_label = _add_slider_row(pulse, "Kick speed", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 0.5)
    _pulse_kick = pulse.get_child(pulse.get_child_count() - 1) as HSlider
    _pulse_ring_label = _add_slider_row(pulse, "Ring power", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _pulse_ring = pulse.get_child(pulse.get_child_count() - 1) as HSlider
    _pulse_emit.value_changed.connect(_on_pulse_emit_changed)
    _pulse_kick.value_changed.connect(_on_pulse_kick_changed)
    _pulse_ring.value_changed.connect(_on_pulse_ring_changed)
    _pulse_options = pulse
    mode_options.add_child(pulse)

    var sink := _make_group()
    _sink_attract_label = _add_slider_row(sink, "Attract", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _sink_attract = sink.get_child(sink.get_child_count() - 1) as HSlider
    _sink_inflow_label = _add_slider_row(sink, "Inflow speed", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _sink_inflow = sink.get_child(sink.get_child_count() - 1) as HSlider
    _sink_radius_label = _add_slider_row(sink, "Sink radius", 0.5, 2.0, 0.05, 1.0)
    _sink_radius = sink.get_child(sink.get_child_count() - 1) as HSlider
    _sink_attract.value_changed.connect(_on_sink_attract_changed)
    _sink_inflow.value_changed.connect(_on_sink_inflow_changed)
    _sink_radius.value_changed.connect(_on_sink_radius_changed)
    _sink_options = sink
    mode_options.add_child(sink)

    var flow := _make_group()
    _flow_field_label = _add_slider_row(flow, "Field strength", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _flow_field = flow.get_child(flow.get_child_count() - 1) as HSlider
    _flow_pull_label = _add_slider_row(flow, "Pull strength", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _flow_pull = flow.get_child(flow.get_child_count() - 1) as HSlider
    _flow_field.value_changed.connect(_on_flow_field_changed)
    _flow_pull.value_changed.connect(_on_flow_pull_changed)
    _flow_options = flow
    mode_options.add_child(flow)

    var lightning := _make_group()
    _lightning_attract_label = _add_slider_row(lightning, "Attract", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _lightning_attract = lightning.get_child(lightning.get_child_count() - 1) as HSlider
    _lightning_discharge_label = _add_slider_row(lightning, "Discharge kick", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _lightning_discharge = lightning.get_child(lightning.get_child_count() - 1) as HSlider
    _lightning_charge_label = _add_slider_row(lightning, "Charge time", 0.5, 2.0, 0.05, 1.0)
    _lightning_charge = lightning.get_child(lightning.get_child_count() - 1) as HSlider
    _lightning_attract.value_changed.connect(_on_lightning_attract_changed)
    _lightning_discharge.value_changed.connect(_on_lightning_discharge_changed)
    _lightning_charge.value_changed.connect(_on_lightning_charge_changed)
    _lightning_options = lightning
    mode_options.add_child(lightning)

    var bh := _make_group()
    _bh_strength_label = _add_slider_row(bh, "Strength", 0.5, 3.0, 0.05, 1.0)
    _bh_strength = bh.get_child(bh.get_child_count() - 1) as HSlider
    _bh_damping_label = _add_slider_row(bh, "Damping", 0.5, 3.0, 0.05, 1.0)
    _bh_damping = bh.get_child(bh.get_child_count() - 1) as HSlider
    _bh_explode_label = _add_slider_row(bh, "Explode", 0.25, 2.0, 0.05, 0.7)
    _bh_explode = bh.get_child(bh.get_child_count() - 1) as HSlider
    _bh_strength.value_changed.connect(_on_bh_strength_changed)
    _bh_damping.value_changed.connect(_on_bh_damping_changed)
    _bh_explode.value_changed.connect(_on_bh_explode_changed)
    _bh_options = bh
    mode_options.add_child(bh)

    var beam := _make_group()
    _beam_speed_label = _add_slider_row(beam, "Beam speed", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _beam_speed = beam.get_child(beam.get_child_count() - 1) as HSlider
    _beam_attract_label = _add_slider_row(beam, "Attract strength", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _beam_attract = beam.get_child(beam.get_child_count() - 1) as HSlider
    _beam_cone_label = _add_slider_row(beam, "Cone width", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _beam_cone = beam.get_child(beam.get_child_count() - 1) as HSlider
    _beam_speed.value_changed.connect(_on_beam_speed_changed)
    _beam_attract.value_changed.connect(_on_beam_attract_changed)
    _beam_cone.value_changed.connect(_on_beam_cone_changed)
    _beam_options = beam
    mode_options.add_child(beam)

    var orbit := _make_group()
    _orbit_radius_label = _add_slider_row(orbit, "Orbit radius", AppSettings.MIN_ORBIT_RADIUS, AppSettings.MAX_ORBIT_RADIUS, 1.0, AppSettings.DEFAULT_ORBIT_RADIUS)
    _orbit_radius = orbit.get_child(orbit.get_child_count() - 1) as HSlider
    _orbit_speed_label = _add_slider_row(orbit, "Orbit speed", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _orbit_speed = orbit.get_child(orbit.get_child_count() - 1) as HSlider
    _orbit_attract_label = _add_slider_row(orbit, "Attract", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _orbit_attract = orbit.get_child(orbit.get_child_count() - 1) as HSlider
    _orbit_radius.value_changed.connect(_on_orbit_radius_changed)
    _orbit_speed.value_changed.connect(_on_orbit_speed_changed)
    _orbit_attract.value_changed.connect(_on_orbit_attract_changed)
    _orbit_options = orbit
    mode_options.add_child(orbit)

    var ripple := _make_group()
    _ripple_speed_label = _add_slider_row(ripple, "Ring speed", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _ripple_speed = ripple.get_child(ripple.get_child_count() - 1) as HSlider
    _ripple_power_label = _add_slider_row(ripple, "Ring power", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _ripple_power = ripple.get_child(ripple.get_child_count() - 1) as HSlider
    _ripple_rate_label = _add_slider_row(ripple, "Ring rate", 0.5, 2.0, 0.05, 1.0)
    _ripple_rate = ripple.get_child(ripple.get_child_count() - 1) as HSlider
    _ripple_speed.value_changed.connect(_on_ripple_speed_changed)
    _ripple_power.value_changed.connect(_on_ripple_power_changed)
    _ripple_rate.value_changed.connect(_on_ripple_rate_changed)
    _ripple_options = ripple
    mode_options.add_child(ripple)

    var magnet := _make_group()
    _magnet_gap_label = _add_slider_row(magnet, "Pole gap", AppSettings.MIN_MAGNET_GAP, AppSettings.MAX_MAGNET_GAP, 1.0, AppSettings.DEFAULT_MAGNET_GAP)
    _magnet_gap = magnet.get_child(magnet.get_child_count() - 1) as HSlider
    _magnet_attract_label = _add_slider_row(magnet, "Attract", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _magnet_attract = magnet.get_child(magnet.get_child_count() - 1) as HSlider
    _magnet_repel_label = _add_slider_row(magnet, "Repel", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _magnet_repel = magnet.get_child(magnet.get_child_count() - 1) as HSlider
    _magnet_gap.value_changed.connect(_on_magnet_gap_changed)
    _magnet_attract.value_changed.connect(_on_magnet_attract_changed)
    _magnet_repel.value_changed.connect(_on_magnet_repel_changed)
    _magnet_options = magnet
    mode_options.add_child(magnet)

    _fluid_options = _make_group()
    _add_setting_row(_fluid_options, "Field size", "fluid_scale")
    _add_setting_row(_fluid_options, "Flow speed", "fluid_speed")
    _add_setting_row(_fluid_options, "Stir", "fluid_stir")
    mode_options.add_child(_fluid_options)

    _fireworks_options = _make_group()
    _add_setting_row(_fireworks_options, "Burst size", "fw_size")
    _add_setting_row(_fireworks_options, "Gravity", "fw_gravity")
    _add_setting_row(_fireworks_options, "Rate", "fw_rate")
    mode_options.add_child(_fireworks_options)

    var audio := _make_group()
    var source_label := Label.new()
    source_label.text = "Source"
    audio.add_child(source_label)
    _audio_source = OptionButton.new()
    _audio_source.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for source_id in range(AppSettings.AudioSource.size()):
        _audio_source.add_item(AppSettings.audio_source_name(source_id as AppSettings.AudioSource), source_id)
    _audio_source.item_selected.connect(_on_audio_source_selected)
    audio.add_child(_audio_source)
    var range_label := Label.new()
    range_label.text = "Range"
    audio.add_child(range_label)
    _audio_range = OptionButton.new()
    _audio_range.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for range_id in range(AppSettings.AudioRange.size()):
        _audio_range.add_item(AppSettings.audio_range_name(range_id as AppSettings.AudioRange), range_id)
    _audio_range.item_selected.connect(_on_audio_range_selected)
    audio.add_child(_audio_range)
    var style_label := Label.new()
    style_label.text = "Style"
    audio.add_child(style_label)
    _audio_style = OptionButton.new()
    _audio_style.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for style_id in range(AppSettings.AudioStyle.size()):
        _audio_style.add_item(AppSettings.audio_style_name(style_id as AppSettings.AudioStyle), style_id)
    _audio_style.item_selected.connect(_on_audio_style_selected)
    audio.add_child(_audio_style)
    _audio_style_auto = CheckBox.new()
    _audio_style_auto.text = "Auto style"
    _audio_style_auto.toggled.connect(_on_audio_style_auto_toggled)
    audio.add_child(_audio_style_auto)
    _audio_algorithm_label = Label.new()
    _audio_algorithm_label.text = "Algorithm"
    _audio_algorithm_label.visible = false
    audio.add_child(_audio_algorithm_label)
    _audio_algorithm = OptionButton.new()
    _audio_algorithm.visible = false
    _audio_algorithm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for algorithm_id in range(AppSettings.DrawAlgorithm.size()):
        _audio_algorithm.add_item(AppSettings.draw_algorithm_name(algorithm_id as AppSettings.DrawAlgorithm), algorithm_id)
    _audio_algorithm.item_selected.connect(_on_audio_algorithm_selected)
    audio.add_child(_audio_algorithm)
    _audio_direction_label = Label.new()
    _audio_direction_label.text = "Direction"
    _audio_direction_label.visible = false
    audio.add_child(_audio_direction_label)
    _audio_direction = OptionButton.new()
    _audio_direction.visible = false
    _audio_direction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for direction_id in range(AppSettings.WaveDirection.size()):
        _audio_direction.add_item(AppSettings.wave_direction_name(direction_id as AppSettings.WaveDirection), direction_id)
    _audio_direction.item_selected.connect(_on_audio_direction_selected)
    audio.add_child(_audio_direction)
    _audio_arms_label = Label.new()
    _audio_arms_label.text = "Arms"
    _audio_arms_label.visible = false
    audio.add_child(_audio_arms_label)
    _audio_arms = OptionButton.new()
    _audio_arms.visible = false
    _audio_arms.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for arms in [2, 3, 4]:
        _audio_arms.add_item("%d arms" % arms, arms)
    _audio_arms.item_selected.connect(_on_audio_arms_selected)
    audio.add_child(_audio_arms)
    _audio_sensitivity_label = _add_slider_row(audio, "Sensitivity", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _audio_sensitivity = audio.get_child(audio.get_child_count() - 1) as HSlider
    _audio_smooth_label = _add_slider_row(audio, "Smooth", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    _audio_smooth = audio.get_child(audio.get_child_count() - 1) as HSlider
    _audio_sensitivity.value_changed.connect(_on_audio_sensitivity_changed)
    _audio_smooth.value_changed.connect(_on_audio_smooth_changed)
    _audio_status = Label.new()
    _audio_status.text = "Audio off"
    _audio_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    audio.add_child(_audio_status)
    _audio_options = audio
    mode_options.add_child(audio)


func _build_touch_audio_group() -> void:
    var group := VBoxContainer.new()
    group.add_theme_constant_override("separation", 4)
    var title := Label.new()
    title.text = "Touch instrument"
    title.theme_type_variation = UiTheme.HEADER
    title.uppercase = true
    group.add_child(title)
    _touch_audio_check = CheckBox.new()
    _touch_audio_check.text = "On"
    _touch_audio_check.toggled.connect(_on_touch_audio_toggled)
    group.add_child(_touch_audio_check)

    var extras := VBoxContainer.new()
    extras.add_theme_constant_override("separation", 4)
    extras.visible = false
    _touch_volume_label = _add_slider_row(extras, "Volume", AppSettings.MIN_TOUCH_VOLUME, AppSettings.MAX_TOUCH_VOLUME, 0.01, AppSettings.DEFAULT_TOUCH_VOLUME)
    _touch_volume = extras.get_child(extras.get_child_count() - 1) as HSlider
    extras.add_child(_hsep())
    var root_label := Label.new()
    root_label.text = "Root note"
    extras.add_child(root_label)
    _touch_root = OptionButton.new()
    _touch_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for note in 12:
        _touch_root.add_item(AppSettings.note_name(note), note)
    _touch_root.item_selected.connect(_on_touch_root_selected)
    extras.add_child(_touch_root)
    var register_label := Label.new()
    register_label.text = "Register"
    extras.add_child(register_label)
    _touch_register = OptionButton.new()
    _touch_register.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for register_id in range(AppSettings.TouchRegister.size()):
        _touch_register.add_item(AppSettings.touch_register_name(register_id as AppSettings.TouchRegister), register_id)
    _touch_register.item_selected.connect(_on_touch_register_selected)
    extras.add_child(_touch_register)
    var scale_label := Label.new()
    scale_label.text = "Scale"
    extras.add_child(scale_label)
    _touch_scale = OptionButton.new()
    _touch_scale.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for scale_id in range(AppSettings.TouchScale.size()):
        _touch_scale.add_item(AppSettings.touch_scale_name(scale_id as AppSettings.TouchScale), scale_id)
    _touch_scale.item_selected.connect(_on_touch_scale_selected)
    extras.add_child(_touch_scale)
    extras.add_child(_hsep())
    _touch_octaves_label = _add_slider_row(extras, "Octaves", AppSettings.MIN_TOUCH_OCTAVES, AppSettings.MAX_TOUCH_OCTAVES, 1.0, AppSettings.DEFAULT_TOUCH_OCTAVES)
    _touch_octaves = extras.get_child(extras.get_child_count() - 1) as HSlider
    _touch_glide_label = _add_slider_row(extras, "Glide", 0.0, 1.0, 0.01, AppSettings.DEFAULT_TOUCH_GLIDE)
    _touch_glide = extras.get_child(extras.get_child_count() - 1) as HSlider
    extras.add_child(_hsep())
    _touch_tone_label = _add_slider_row(extras, "Tone", AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, AppSettings.DEFAULT_TOUCH_TONE)
    _touch_tone = extras.get_child(extras.get_child_count() - 1) as HSlider
    _touch_attack_label = _add_slider_row(extras, "Attack", AppSettings.MIN_TOUCH_ENVELOPE, AppSettings.MAX_TOUCH_ATTACK, 0.005, AppSettings.DEFAULT_TOUCH_ATTACK)
    _touch_attack = extras.get_child(extras.get_child_count() - 1) as HSlider
    _touch_release_label = _add_slider_row(extras, "Release", AppSettings.MIN_TOUCH_ENVELOPE, AppSettings.MAX_TOUCH_RELEASE, 0.005, AppSettings.DEFAULT_TOUCH_RELEASE)
    _touch_release = extras.get_child(extras.get_child_count() - 1) as HSlider
    var wave_label := Label.new()
    wave_label.text = "Wave"
    extras.add_child(wave_label)
    _touch_wave = OptionButton.new()
    _touch_wave.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for wave_id in range(AppSettings.TouchWave.size()):
        _touch_wave.add_item(AppSettings.touch_wave_name(wave_id as AppSettings.TouchWave), wave_id)
    _touch_wave.item_selected.connect(_on_touch_wave_selected)
    extras.add_child(_touch_wave)
    _touch_volume.value_changed.connect(_on_touch_volume_changed)
    _touch_octaves.value_changed.connect(_on_touch_octaves_changed)
    _touch_glide.value_changed.connect(_on_touch_glide_changed)
    _touch_tone.value_changed.connect(_on_touch_tone_changed)
    _touch_attack.value_changed.connect(_on_touch_attack_changed)
    _touch_release.value_changed.connect(_on_touch_release_changed)
    group.add_child(extras)
    _touch_audio_extras = extras
    _touch_audio_group = group
    _sound_box.add_child(group)


## A 0.25-2.5 multiplier slider bound straight to an AppSettings property.
func _add_setting_row(parent: VBoxContainer, title: String, property: String) -> void:
    var label := _add_slider_row(parent, title, AppSettings.MIN_MUL, AppSettings.MAX_MUL, 0.05, 1.0)
    var slider := parent.get_child(parent.get_child_count() - 1) as HSlider
    slider.value_changed.connect(_on_setting_row_changed.bind(property))
    _setting_rows.append([label, slider, title, property])


func _on_setting_row_changed(value: float, property: String) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.set(property, value)
    _emit_change()


func _on_audio_arms_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.audio_galaxy_arms = _audio_arms.get_item_id(index)
    _emit_change()


func _make_group() -> VBoxContainer:
    var box := VBoxContainer.new()
    box.visible = false
    box.add_theme_constant_override("separation", 4)
    return box


func _add_slider_row(parent: VBoxContainer, title: String, min_v: float, max_v: float, step: float, value: float) -> Label:
    var label := Label.new()
    label.text = "%s: %.2f" % [title, value]
    parent.add_child(label)
    var slider := HSlider.new()
    slider.min_value = min_v
    slider.max_value = max_v
    slider.step = step
    slider.value = value
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(slider)
    var tip := _tip_for_title(title)
    if tip != "":
        _explain(label, tip)
        _explain(slider, tip)
    return label


func _split_settings_tabs() -> void:
    var column := mode_options.get_parent() as VBoxContainer
    var scroll := column.get_parent() as ScrollContainer
    var margin := scroll.get_parent()

    var outer := VBoxContainer.new()
    outer.name = "SettingsColumn"
    outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    outer.add_theme_constant_override("separation", 8)
    margin.add_child(outer)

    var title := column.get_node("Title")
    column.remove_child(title)
    outer.add_child(title)

    var tabs := TabContainer.new()
    tabs.name = "SettingsTabs"
    tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tabs.tab_alignment = TabBar.ALIGNMENT_CENTER
    outer.add_child(tabs)

    var mode_box := _tab_page(tabs, "Mode")
    _sound_box = _tab_page(tabs, "Sound")
    var look_box := _tab_page(tabs, "Look")
    _about_box = _tab_page(tabs, "About")

    _reparent(column, mode_box, "ModeLabel")
    _reparent(column, mode_box, "ModeOption")
    mode_box.add_child(_hsep())
    _reparent(column, mode_box, "ModeOptions")

    _hint_label = Label.new()
    _hint_label.name = "Hint"
    _hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _hint_label.custom_minimum_size = Vector2(0, 48)
    _hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
    _hint_label.text = "Tap a control to read what it does."
    outer.add_child(_hint_label)

    # Side by side, so the buttons take one row of the panel instead of two.
    var buttons := HBoxContainer.new()
    buttons.add_theme_constant_override("separation", 8)
    outer.add_child(buttons)
    for node_name in ["ResetDefaultsButton", "CloseButton"]:
        _reparent(column, buttons, node_name)
        (buttons.get_node(node_name) as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var look_names := [
        "DisplayLabel", "InvertCheck", "AutoCheck", "GlowCheck", "FpsCheck",
        "IdleLabel", "IdleOption", "ColorLabel", "ColorOption",
        "ParticleLabel", "CountLabel", "CountSlider", "WidthLabel", "WidthSlider", "LengthLabel", "LengthSlider",
    ]
    for node_name in look_names:
        if node_name == "ParticleLabel":
            look_box.add_child(_hsep())
        _reparent(column, look_box, node_name)

    _sound_note = Label.new()
    _sound_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _sound_note.text = "Touch audio stays off while the Audio visualizer is running."
    _sound_note.visible = false
    _sound_box.add_child(_sound_note)

    margin.remove_child(scroll)
    scroll.queue_free()


## A tab page: a scroll area with edge fades over it. The holder takes the tab title.
func _tab_page(tabs: TabContainer, title: String) -> VBoxContainer:
    var holder := Control.new()
    holder.name = title
    tabs.add_child(holder)
    var page := ScrollContainer.new()
    page.name = "Scroll"
    page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    page.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    holder.add_child(page)
    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    box.add_theme_constant_override("separation", 8)
    page.add_child(box)
    _add_scroll_fades(holder, page)
    return box


## Fades at the top and bottom edges whenever there is more of the page in that direction.
## Pages fit a 1080x1920 phone without scrolling (tools/settings_fit.gd checks it), so these
## only appear on smaller or landscape screens.
func _add_scroll_fades(holder: Control, page: ScrollContainer) -> void:
    var top := _fade_rect(true)
    var bottom := _fade_rect(false)
    holder.add_child(top)
    holder.add_child(bottom)
    var bar := page.get_v_scroll_bar()
    var update := func() -> void:
        var end := bar.max_value - bar.page
        top.visible = end > 1.0 and bar.value > 1.0
        bottom.visible = end > 1.0 and bar.value < end - 1.0
    bar.changed.connect(update)
    bar.value_changed.connect(func(_value: float) -> void: update.call())
    update.call()


func _fade_rect(at_top: bool) -> TextureRect:
    const HEIGHT := 40.0
    var gradient := Gradient.new()
    var solid := Color(UiTheme.PANEL_BG, 1.0)
    var clear := Color(UiTheme.PANEL_BG, 0.0)
    gradient.colors = PackedColorArray([solid, clear] if at_top else [clear, solid])
    var texture := GradientTexture2D.new()
    texture.gradient = gradient
    texture.fill_from = Vector2(0, 0)
    texture.fill_to = Vector2(0, 1)
    texture.width = 4
    texture.height = 64
    var rect := TextureRect.new()
    rect.texture = texture
    rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    rect.stretch_mode = TextureRect.STRETCH_SCALE
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    rect.visible = false
    rect.anchor_right = 1.0
    # Stop short of the scrollbar so the thumb stays visible under the fade.
    rect.offset_right = -10.0
    if at_top:
        rect.offset_bottom = HEIGHT
    else:
        rect.anchor_top = 1.0
        rect.anchor_bottom = 1.0
        rect.offset_top = -HEIGHT
    return rect


func _reparent(from: Node, to: Node, node_name: String) -> void:
    var node := from.get_node(node_name)
    from.remove_child(node)
    to.add_child(node)


func _hsep() -> HSeparator:
    return HSeparator.new()


## Puts every "label, then slider or dropdown" pair on one row: label on the left,
## control on the right. Halves the height of the option pages so they fit a phone.
func _inline_rows(node: Node) -> void:
    for child in node.get_children():
        _inline_rows(child)
    if not node is VBoxContainer:
        return
    var kids := node.get_children()
    for i in range(kids.size() - 1):
        var label := kids[i] as Label
        var control := kids[i + 1] as Control
        if label == null or label.theme_type_variation == UiTheme.HEADER or label.autowrap_mode != TextServer.AUTOWRAP_OFF:
            continue
        if not (control is HSlider or control is OptionButton):
            continue
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)
        node.add_child(row)
        node.move_child(row, label.get_index())
        node.remove_child(label)
        node.remove_child(control)
        row.add_child(label)
        row.add_child(control)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        if control is HSlider:
            # Sliders are thinner than dropdowns; keep the rows evenly spaced and easy to grab.
            row.custom_minimum_size.y = 30.0
        # Options code hides the label and control together; the row follows the control.
        row.visible = control.visible
        control.visibility_changed.connect(func() -> void: row.visible = control.visible)


func _explain(control: Control, text: String) -> void:
    if control == null or text == "":
        return
    control.tooltip_text = text
    if not control.focus_entered.is_connected(_show_hint):
        control.focus_entered.connect(_show_hint.bind(text))
    if not control.mouse_entered.is_connected(_show_hint):
        control.mouse_entered.connect(_show_hint.bind(text))


func _show_hint(text: String) -> void:
    if _hint_label != null:
        _hint_label.text = text


func _annotate_controls(node: Node) -> void:
    if node is TabBar:
        return
    if node is BaseButton or node is HSlider:
        var control := node as Control
        if control.tooltip_text == "":
            var tip := _tip_for_control(control)
            if tip != "":
                _explain(control, tip)
    for child in node.get_children():
        _annotate_controls(child)


func _tip_for_control(control: Control) -> String:
    if control == vortex_dir_option:
        return "Which way the vortex spins."
    if control == _audio_direction:
        return "Lays the waveform across the screen or up the screen."
    if control is CheckBox or control is Button:
        var titled := _tip_for_title((control as Button).text)
        if titled != "":
            return titled
    var previous := _previous_label(control)
    if previous != "":
        return _tip_for_title(previous)
    return ""


func _previous_label(control: Node) -> String:
    var parent := control.get_parent()
    if parent == null:
        return ""
    var siblings := parent.get_children()
    var index := siblings.find(control)
    if index <= 0:
        return ""
    var earlier := siblings[index - 1]
    if earlier is Label:
        var text := (earlier as Label).text
        var colon := text.find(":")
        if colon >= 0:
            text = text.substr(0, colon)
        return text
    return ""


func _tip_for_title(title: String) -> String:
    match title:
        "Modes", "Mode":
            return "Chooses which art mode is running."
        "Source":
            return "Microphone listens to the room. Playback listens to other apps and asks a grown-up first."
        "Range":
            return "Chooses which frequencies the visualizer listens to."
        "Style":
            return "How the particles draw the sound."
        "Algorithm":
            return "How the line chooses its next direction."
        "Auto style":
            return "Cycles visualizer styles after a beat, or every 20 seconds."
        "Direction":
            return "Lays the waveform across the screen or up the screen."
        "Sensitivity":
            return "Raises or lowers how strongly the sound moves the particles."
        "Smooth":
            return "Slows how quickly the bands follow the sound."
        "On":
            return "Touch the screen to play a note. Up and down sets the pitch, and left and right sets the volume."
        "Volume":
            return "Master loudness of the touch instrument."
        "Root note":
            return "The starting note of the scale."
        "Register":
            return "Shifts the whole range down to a low, middle, or high octave."
        "Scale":
            return "Which notes the touch instrument can play."
        "Octaves":
            return "How many octaves fit between the bottom and top of the screen."
        "Glide":
            return "Steps snaps to notes. Smooth slides between them."
        "Tone":
            return "Opens or closes a filter on the touch instrument."
        "Attack":
            return "How quickly a note fades in."
        "Release":
            return "How quickly a note fades out after you lift."
        "Wave":
            return "The oscillator shape of the touch instrument."
        "Invert":
            return "Swaps the light and dark colors."
        "Auto control":
            return "Moves the touch point and changes art modes on its own. It never opens the Audio visualizer."
        "Glow":
            return "Softens the particles with a glow."
        "Reduce flashing":
            return "Turns off the beat flash in Audio and the Lightning bolts."
        "Show FPS":
            return "Shows the frame rate in the corner."
        "Idle":
            return "What the particles do when nothing is touching the screen."
        "Color":
            return "Color palette for the particles."
        "Number":
            return "How many particles are on screen."
        "Width":
            return "How wide each particle is."
        "Length":
            return "How long the trails last."
        "Reset defaults":
            return "Restores every setting to its default."
        "Close":
            return "Closes this panel."
        "Radius":
            return "Size of the vortex the particles circle."
        "Speed":
            return "How fast this motion runs."
        "Pull":
            return "How strongly particles are drawn into the motion."
        "Emit rate":
            return "How often new pulses leave the touch point."
        "Kick speed":
            return "How hard each pulse throws the particles."
        "Ring power":
            return "How strongly a ring pushes particles as it passes."
        "Attract":
            return "How strongly particles pull toward the touch."
        "Inflow speed":
            return "How fast particles travel into the sink."
        "Sink radius":
            return "How wide the sink is."
        "Field strength":
            return "How strongly the flow field pushes particles."
        "Pull strength":
            return "How strongly the flow gathers around the touch."
        "Discharge kick":
            return "How hard a lightning strike throws the particles."
        "Charge time":
            return "How long the lightning builds before it strikes."
        "Strength":
            return "How strong this effect is."
        "Damping":
            return "How quickly motion inside the black hole slows down."
        "Explode":
            return "How hard particles burst when they escape."
        "Beam speed":
            return "How fast particles travel along the beam."
        "Attract strength":
            return "How tightly particles stay inside the beam."
        "Cone width":
            return "How wide the beam opens."
        "Orbit radius":
            return "How far the orbit sits from the touch."
        "Orbit speed":
            return "How fast particles travel around the orbit."
        "Ring speed":
            return "How fast each ripple travels outward."
        "Ring rate":
            return "How often new ripples start."
        "Pole gap":
            return "Distance between the two magnet poles."
        "Repel":
            return "How strongly the second pole pushes particles away."
        "Field size":
            return "How big the swirls in the smoke are."
        "Flow speed":
            return "How fast the smoke drifts on its own."
        "Stir":
            return "How strongly your finger stirs the smoke."
        "Burst size":
            return "How many sparks each firework throws, and how far."
        "Gravity":
            return "How quickly the sparks fall."
        "Rate":
            return "How often fireworks launch while you hold."
        "Arms":
            return "How many spiral arms the galaxy has."
        _:
            return ""


func _on_viewport_resized() -> void:
    _layout_menu_button()
    _layout_fps_label()
    _apply_ui_scale_to_controls()


func _set_audio_status(text: String) -> void:
    var failed := text in [
        "Playback unavailable",
        "Playback plugin missing",
        "Could not open the capture prompt",
        "Could not open the playback device",
        "Playback capture requires Android 10 or newer",
        "Permission needed",
        "Capture blocked",
        "Microphone unavailable",
    ]
    var shown := "Error: " + text if failed else text
    if _audio_status.text == shown:
        return
    _audio_status.text = shown
    if failed:
        _audio_status.add_theme_color_override("font_color", Color(1.0, 0.32, 0.32))
    elif _audio_status.has_theme_color_override("font_color"):
        _audio_status.remove_theme_color_override("font_color")


func _process(delta: float) -> void:
    if not panel.visible and _menu_target > MENU_IDLE_ALPHA:
        _menu_idle += delta
        if _menu_idle >= MENU_IDLE_FADE:
            _fade_menu(MENU_IDLE_ALPHA, 0.8)
    if _audio_status != null and settings != null and settings.art_mode == AppSettings.ArtMode.AUDIO:
        var feed := AudioFeed.active
        var text := "Audio off"
        if feed != null and feed.status_text != "":
            text = feed.status_text
        _set_audio_status(text)
    if settings == null or not settings.show_fps:
        return
    _fps_accum += delta
    _fps_frames += 1
    if _fps_accum >= 0.25:
        var fps := float(_fps_frames) / _fps_accum
        fps_label.text = "%d FPS" % int(round(fps))
        _fps_accum = 0.0
        _fps_frames = 0


func _compute_ui_scale() -> float:
    var win := get_window()
    if win == null:
        return 1.0
    var dpi := DisplayServer.screen_get_dpi()
    var short_side := mini(win.size.x, win.size.y)
    var is_phone := dpi >= PHONE_DPI_THRESHOLD or (
        DisplayServer.is_touchscreen_available() and short_side > 0.0 and short_side <= PHONE_SHORT_SIDE_MAX
    )
    if is_phone:
        return clampf(float(dpi) / 220.0, 1.5, 2.0)
    return 1.0


func _apply_ui_scale_to_controls() -> void:
    menu_button.pivot_offset = Vector2.ZERO
    menu_button.scale = Vector2(_ui_scale, _ui_scale)
    fps_label.pivot_offset = Vector2(fps_label.size.x, 0.0)
    fps_label.scale = Vector2(_ui_scale, _ui_scale)
    _fit_panel_to_window()
    var panel_size := panel.size
    if panel_size == Vector2.ZERO:
        panel_size = Vector2(520, 1080)
    panel.pivot_offset = panel_size * 0.5
    panel.scale = Vector2(_ui_scale, _ui_scale)
    _layout_gate()


func _fit_panel_to_window() -> void:
    var win := get_window()
    if win == null:
        return
    _set_panel_size(_panel_size_for(Vector2(win.size)))


## Panel size in unscaled units for a window of this many pixels.
## tools/settings_fit.gd calls it with 1080x1920.
func _panel_size_for(window: Vector2) -> Vector2:
    var margin := 24.0
    var avail_w := maxf(window.x - margin * 2.0, 280.0) / _ui_scale
    var avail_h := maxf(window.y - margin * 2.0, 320.0) / _ui_scale
    return Vector2(minf(520.0, avail_w), minf(1080.0, avail_h))


func _set_panel_size(size: Vector2) -> void:
    var width := size.x
    var height := size.y
    panel.offset_left = -width * 0.5
    panel.offset_right = width * 0.5
    panel.offset_top = -height * 0.5
    panel.offset_bottom = height * 0.5


func _layout_menu_button() -> void:
    if menu_button == null:
        return

    var safe := DisplayServer.get_display_safe_area()
    var win_pos := DisplayServer.window_get_position()
    var local_safe_left := maxf(0.0, float(safe.position.x - win_pos.x))
    var local_safe_top := maxf(0.0, float(safe.position.y - win_pos.y))

    var margin_left := MENU_MARGIN_X
    var margin_top := MENU_MARGIN_Y
    if DisplayServer.is_touchscreen_available() and (local_safe_left > 0.0 or local_safe_top > 0.0):
        margin_left = local_safe_left + MENU_MARGIN_X
        margin_top = local_safe_top + MENU_MARGIN_Y

    menu_button.anchor_left = 0.0
    menu_button.anchor_top = 0.0
    menu_button.anchor_right = 0.0
    menu_button.anchor_bottom = 0.0
    menu_button.offset_left = margin_left
    menu_button.offset_top = margin_top
    menu_button.offset_right = margin_left + MENU_SIZE
    menu_button.offset_bottom = margin_top + MENU_SIZE
    menu_button.custom_minimum_size = Vector2(MENU_SIZE, MENU_SIZE)


func _layout_fps_label() -> void:
    if fps_label == null:
        return
    var safe := DisplayServer.get_display_safe_area()
    var win_pos := DisplayServer.window_get_position()
    var win_size := DisplayServer.window_get_size()
    var local_safe_right := maxf(0.0, float((win_pos.x + win_size.x) - (safe.position.x + safe.size.x)))
    var local_safe_top := maxf(0.0, float(safe.position.y - win_pos.y))

    var margin_right := MENU_MARGIN_X
    var margin_top := MENU_MARGIN_Y
    if DisplayServer.is_touchscreen_available() and (local_safe_right > 0.0 or local_safe_top > 0.0):
        margin_right = local_safe_right + MENU_MARGIN_X
        margin_top = local_safe_top + MENU_MARGIN_Y

    fps_label.anchor_left = 1.0
    fps_label.anchor_top = 0.0
    fps_label.anchor_right = 1.0
    fps_label.anchor_bottom = 0.0
    fps_label.offset_right = -margin_right
    fps_label.offset_left = -margin_right - 120.0
    fps_label.offset_top = margin_top
    fps_label.offset_bottom = margin_top + 32.0


func _update_fps_visibility() -> void:
    var on := settings != null and settings.show_fps
    fps_label.visible = on
    if not on:
        _fps_accum = 0.0
        _fps_frames = 0


func bind_settings(s: AppSettings) -> void:
    settings = s
    _sync_ui_from_settings()
    _show_hint_if_new()


func toggle() -> void:
    if panel.visible:
        close()
    else:
        open()


func open() -> void:
    if panel.visible:
        return
    panel.visible = true
    _scrim.visible = true
    _dismiss_hint()
    _wake_menu()
    _animate_panel(true)
    visibility_toggled.emit(true)


func close() -> void:
    # Back and Esc dismiss the grown-up gate before the panel.
    if _gate != null and _gate.visible:
        _cancel_gate()
        return
    if not panel.visible:
        return
    _scrim.visible = false
    _animate_panel(false)
    if _save_timer != null:
        _save_timer.stop()
    _save_now()
    visibility_toggled.emit(false)


func _animate_panel(opening: bool) -> void:
    if _panel_tween != null:
        _panel_tween.kill()
    var full := Vector2(_ui_scale, _ui_scale)
    _panel_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    if opening:
        panel.modulate.a = 0.0
        panel.scale = full * 0.96
        _panel_tween.tween_property(panel, "modulate:a", 1.0, 0.16)
        _panel_tween.tween_property(panel, "scale", full, 0.16)
    else:
        _panel_tween.tween_property(panel, "modulate:a", 0.0, 0.12)
        _panel_tween.tween_property(panel, "scale", full * 0.97, 0.12)
        _panel_tween.chain().tween_callback(func() -> void:
            panel.visible = false
            panel.scale = full
        )


func is_open() -> bool:
    return panel.visible and _scrim.visible


func _sync_ui_from_settings() -> void:
    if settings == null:
        return
    _updating_ui = true
    mode_option.select(int(settings.art_mode))
    invert_check.button_pressed = settings.invert
    auto_check.button_pressed = settings.auto_control
    glow_check.button_pressed = settings.glow
    _reduce_flashing_check.button_pressed = settings.reduce_flashing
    fps_check.button_pressed = settings.show_fps
    _frame_rate.select(maxi(AppSettings.FRAME_RATES.find(settings.max_fps), 0))
    _sync_mode_grid()
    idle_option.select(int(settings.idle_mode))
    color_option.select(int(settings.color_preset))
    count_slider.value = settings.particle_count
    width_slider.value = settings.width
    length_slider.value = settings.length
    vortex_radius_slider.value = settings.vortex_radius
    vortex_speed_slider.value = settings.vortex_speed
    vortex_pull_slider.value = settings.vortex_pull
    vortex_dir_option.select(int(settings.vortex_direction))
    repel_strength_slider.value = settings.repel_strength
    _pulse_emit.value = settings.pulse_emit_rate
    _pulse_kick.value = settings.pulse_kick_speed
    _pulse_ring.value = settings.pulse_ring_power
    _sink_attract.value = settings.sink_attract
    _sink_inflow.value = settings.sink_inflow
    _sink_radius.value = settings.sink_radius
    _flow_field.value = settings.flow_field
    _flow_pull.value = settings.flow_pull
    _lightning_attract.value = settings.lightning_attract
    _lightning_discharge.value = settings.lightning_discharge
    _lightning_charge.value = settings.lightning_charge_time
    _bh_strength.value = settings.bh_strength
    _bh_damping.value = settings.bh_damping
    _bh_explode.value = settings.bh_explode
    _beam_speed.value = settings.beam_speed
    _beam_attract.value = settings.beam_attract
    _beam_cone.value = settings.beam_cone
    _orbit_radius.value = settings.orbit_radius
    _orbit_speed.value = settings.orbit_speed
    _orbit_attract.value = settings.orbit_attract
    _ripple_speed.value = settings.ripple_speed
    _ripple_power.value = settings.ripple_power
    _ripple_rate.value = settings.ripple_rate
    _magnet_gap.value = settings.magnet_gap
    _magnet_attract.value = settings.magnet_attract
    _magnet_repel.value = settings.magnet_repel
    for row in _setting_rows:
        (row[1] as HSlider).value = float(settings.get(row[3]))
    _audio_arms.select(maxi(_audio_arms.get_item_index(settings.audio_galaxy_arms), 0))
    _audio_source.select(int(settings.audio_source))
    _audio_range.select(int(settings.audio_range))
    _audio_style.select(int(settings.audio_style))
    _audio_style_auto.button_pressed = settings.audio_style_auto
    _audio_algorithm.select(int(settings.audio_draw_algorithm))
    _audio_direction.select(int(settings.audio_wave_direction))
    _audio_sensitivity.value = settings.audio_sensitivity
    _audio_smooth.value = settings.audio_smooth
    _touch_audio_check.button_pressed = settings.touch_audio
    _touch_volume.value = settings.touch_audio_volume
    _touch_root.select(settings.touch_audio_root)
    _touch_register.select(int(settings.touch_audio_register))
    _touch_scale.select(int(settings.touch_audio_scale))
    _touch_octaves.value = settings.touch_audio_octaves
    _touch_glide.value = settings.touch_audio_glide
    _touch_tone.value = settings.touch_audio_tone
    _touch_attack.value = settings.touch_audio_attack
    _touch_release.value = settings.touch_audio_release
    _touch_wave.select(int(settings.touch_audio_wave))
    _refresh_labels()
    _update_mode_options_visibility()
    _update_fps_visibility()
    _updating_ui = false


func _update_mode_options_visibility() -> void:
    if settings == null:
        mode_options.visible = false
        return
    var mode := settings.art_mode
    vortex_options.visible = mode == AppSettings.ArtMode.PARTICLE
    repel_options.visible = mode == AppSettings.ArtMode.GRAVITY
    _pulse_options.visible = mode == AppSettings.ArtMode.WAVE
    _sink_options.visible = mode == AppSettings.ArtMode.SINK
    _flow_options.visible = mode == AppSettings.ArtMode.LINEAR
    _lightning_options.visible = mode == AppSettings.ArtMode.LIGHTNING
    _bh_options.visible = mode == AppSettings.ArtMode.BLACK_HOLE
    _beam_options.visible = mode == AppSettings.ArtMode.BEAM
    _orbit_options.visible = mode == AppSettings.ArtMode.ORBIT
    _ripple_options.visible = mode == AppSettings.ArtMode.RIPPLE
    _magnet_options.visible = mode == AppSettings.ArtMode.MAGNET
    _audio_options.visible = mode == AppSettings.ArtMode.AUDIO
    _fluid_options.visible = mode == AppSettings.ArtMode.FLUID
    _fireworks_options.visible = mode == AppSettings.ArtMode.FIREWORKS
    mode_options.visible = true
    auto_check.disabled = mode == AppSettings.ArtMode.AUDIO
    _update_wave_direction_visibility()
    _update_draw_algorithm_visibility()
    _update_touch_audio_visibility()


func _update_touch_audio_visibility() -> void:
    if _touch_audio_group == null:
        return
    if settings == null:
        _touch_audio_group.visible = false
        return
    var show_group := settings.art_mode != AppSettings.ArtMode.AUDIO
    _touch_audio_group.visible = show_group
    _touch_audio_extras.visible = show_group and settings.touch_audio
    if _sound_note != null:
        _sound_note.visible = not show_group


func _update_wave_direction_visibility() -> void:
    var show := settings != null and settings.audio_style == AppSettings.AudioStyle.WAVEFORM
    if _audio_direction_label != null:
        _audio_direction_label.visible = show
    if _audio_direction != null:
        _audio_direction.visible = show
    var galaxy := settings != null and settings.audio_style == AppSettings.AudioStyle.GALAXY
    if _audio_arms_label != null:
        _audio_arms_label.visible = galaxy
    if _audio_arms != null:
        _audio_arms.visible = galaxy


func _update_draw_algorithm_visibility() -> void:
    var show := settings != null and settings.audio_style == AppSettings.AudioStyle.DRAW
    if _audio_algorithm_label != null:
        _audio_algorithm_label.visible = show
    if _audio_algorithm != null:
        _audio_algorithm.visible = show


func _refresh_labels() -> void:
    count_label.text = "Number: %d" % int(count_slider.value)
    width_label.text = "Width: %d" % int(width_slider.value)
    length_label.text = "Length: %.2f" % length_slider.value
    vortex_radius_label.text = "Radius: %d" % int(vortex_radius_slider.value)
    vortex_speed_label.text = "Speed: %.2f" % vortex_speed_slider.value
    vortex_pull_label.text = "Pull: %.2f" % vortex_pull_slider.value
    repel_strength_label.text = "Strength: %.2f" % repel_strength_slider.value
    _pulse_emit_label.text = "Emit rate: %.2f" % _pulse_emit.value
    _pulse_kick_label.text = "Kick speed: %.2f" % _pulse_kick.value
    _pulse_ring_label.text = "Ring power: %.2f" % _pulse_ring.value
    _sink_attract_label.text = "Attract: %.2f" % _sink_attract.value
    _sink_inflow_label.text = "Inflow speed: %.2f" % _sink_inflow.value
    _sink_radius_label.text = "Sink radius: %.2f" % _sink_radius.value
    _flow_field_label.text = "Field strength: %.2f" % _flow_field.value
    _flow_pull_label.text = "Pull strength: %.2f" % _flow_pull.value
    _lightning_attract_label.text = "Attract: %.2f" % _lightning_attract.value
    _lightning_discharge_label.text = "Discharge kick: %.2f" % _lightning_discharge.value
    _lightning_charge_label.text = "Charge time: %.2f" % _lightning_charge.value
    _bh_strength_label.text = "Strength: %.2f" % _bh_strength.value
    _bh_damping_label.text = "Damping: %.2f" % _bh_damping.value
    _bh_explode_label.text = "Explode: %.2f" % _bh_explode.value
    _beam_speed_label.text = "Beam speed: %.2f" % _beam_speed.value
    _beam_attract_label.text = "Attract strength: %.2f" % _beam_attract.value
    _beam_cone_label.text = "Cone width: %.2f" % _beam_cone.value
    _orbit_radius_label.text = "Orbit radius: %d" % int(_orbit_radius.value)
    _orbit_speed_label.text = "Orbit speed: %.2f" % _orbit_speed.value
    _orbit_attract_label.text = "Attract: %.2f" % _orbit_attract.value
    _ripple_speed_label.text = "Ring speed: %.2f" % _ripple_speed.value
    _ripple_power_label.text = "Ring power: %.2f" % _ripple_power.value
    _ripple_rate_label.text = "Ring rate: %.2f" % _ripple_rate.value
    _magnet_gap_label.text = "Pole gap: %d" % int(_magnet_gap.value)
    _magnet_attract_label.text = "Attract: %.2f" % _magnet_attract.value
    _magnet_repel_label.text = "Repel: %.2f" % _magnet_repel.value
    for row in _setting_rows:
        (row[0] as Label).text = "%s: %.2f" % [row[2], (row[1] as HSlider).value]
    _audio_sensitivity_label.text = "Sensitivity: %.2f" % _audio_sensitivity.value
    _audio_smooth_label.text = "Smooth: %.2f" % _audio_smooth.value
    _touch_volume_label.text = "Volume: %.2f" % _touch_volume.value
    _touch_octaves_label.text = "Octaves: %d" % int(_touch_octaves.value)
    _touch_glide_label.text = _glide_label(_touch_glide.value)
    _touch_tone_label.text = "Tone: %.2f" % _touch_tone.value
    _touch_attack_label.text = _ms_label("Attack", _touch_attack.value)
    _touch_release_label.text = _ms_label("Release", _touch_release.value)


func _emit_change() -> void:
    if _updating_ui or settings == null:
        return
    _update_mode_options_visibility()
    settings_changed.emit(settings)
    _queue_save()


## Sliders fire every step while dragged; write the file once they settle.
func _queue_save() -> void:
    if _save_timer != null:
        _save_timer.start()


func _save_now() -> void:
    if settings != null:
        settings.save_to_disk()


func _on_reset_defaults_pressed() -> void:
    if settings == null:
        return
    settings.reset_to_defaults()
    _sync_ui_from_settings()
    settings_changed.emit(settings)
    _queue_save()


func _on_mode_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.art_mode = mode_option.get_item_id(index) as AppSettings.ArtMode
    _sync_mode_grid()
    _emit_change()


func _on_frame_rate_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.max_fps = AppSettings.FRAME_RATES[index]
    _emit_change()


func _on_touch_audio_toggled(pressed: bool) -> void:
    if _updating_ui:
        return
    settings.touch_audio = pressed
    _emit_change()


func _on_touch_volume_changed(value: float) -> void:
    if _updating_ui:
        return
    settings.touch_audio_volume = value
    _touch_volume_label.text = "Volume: %.2f" % value
    _emit_change()


func _on_touch_root_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.touch_audio_root = _touch_root.get_item_id(index)
    _emit_change()


func _on_touch_register_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.touch_audio_register = _touch_register.get_item_id(index) as AppSettings.TouchRegister
    _emit_change()


func _on_touch_scale_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.touch_audio_scale = _touch_scale.get_item_id(index) as AppSettings.TouchScale
    _emit_change()


func _glide_label(value: float) -> String:
    if value <= 0.02:
        return "Glide: Steps"
    if value >= 0.98:
        return "Glide: Smooth"
    return "Glide: %.2f" % value


func _ms_label(title: String, seconds: float) -> String:
    return "%s: %d ms" % [title, int(round(seconds * 1000.0))]


func _on_touch_octaves_changed(value: float) -> void:
    if _updating_ui:
        return
    settings.touch_audio_octaves = value
    _touch_octaves_label.text = "Octaves: %d" % int(value)
    _emit_change()


func _on_touch_glide_changed(value: float) -> void:
    if _updating_ui:
        return
    settings.touch_audio_glide = value
    _touch_glide_label.text = _glide_label(value)
    _emit_change()


func _on_touch_tone_changed(value: float) -> void:
    if _updating_ui:
        return
    settings.touch_audio_tone = value
    _touch_tone_label.text = "Tone: %.2f" % value
    _emit_change()


func _on_touch_attack_changed(value: float) -> void:
    if _updating_ui:
        return
    settings.touch_audio_attack = value
    _touch_attack_label.text = _ms_label("Attack", value)
    _emit_change()


func _on_touch_release_changed(value: float) -> void:
    if _updating_ui:
        return
    settings.touch_audio_release = value
    _touch_release_label.text = _ms_label("Release", value)
    _emit_change()


func _on_touch_wave_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.touch_audio_wave = _touch_wave.get_item_id(index) as AppSettings.TouchWave
    _emit_change()


func _on_invert_toggled(pressed: bool) -> void:
    if _updating_ui:
        return
    settings.invert = pressed
    _emit_change()


func _on_auto_toggled(pressed: bool) -> void:
    if _updating_ui:
        return
    if settings.art_mode == AppSettings.ArtMode.AUDIO:
        _updating_ui = true
        auto_check.button_pressed = false
        _updating_ui = false
        settings.auto_control = false
        return
    settings.auto_control = pressed
    _emit_change()


func _on_glow_toggled(pressed: bool) -> void:
    if _updating_ui:
        return
    settings.glow = pressed
    _emit_change()


func _on_reduce_flashing_toggled(pressed: bool) -> void:
    if _updating_ui:
        return
    settings.reduce_flashing = pressed
    _emit_change()


func _on_fps_toggled(pressed: bool) -> void:
    if _updating_ui:
        return
    settings.show_fps = pressed
    _update_fps_visibility()
    _emit_change()


func _on_color_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.color_preset = color_option.get_item_id(index) as AppSettings.ColorPreset
    _emit_change()


func _on_idle_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.idle_mode = idle_option.get_item_id(index) as AppSettings.IdleMode
    _emit_change()


func _on_count_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.particle_count = int(value)
    _emit_change()


func _on_width_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.width = value
    _emit_change()


func _on_length_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.length = value
    _emit_change()


func _on_vortex_radius_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.vortex_radius = value
    _emit_change()


func _on_vortex_speed_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.vortex_speed = value
    _emit_change()


func _on_vortex_pull_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.vortex_pull = value
    _emit_change()


func _on_vortex_dir_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.vortex_direction = vortex_dir_option.get_item_id(index) as AppSettings.VortexDirection
    _emit_change()


func _on_repel_strength_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.repel_strength = value
    _emit_change()


func _on_pulse_emit_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.pulse_emit_rate = value
    _emit_change()


func _on_pulse_kick_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.pulse_kick_speed = value
    _emit_change()


func _on_pulse_ring_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.pulse_ring_power = value
    _emit_change()


func _on_sink_attract_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.sink_attract = value
    _emit_change()


func _on_sink_inflow_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.sink_inflow = value
    _emit_change()


func _on_sink_radius_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.sink_radius = value
    _emit_change()


func _on_flow_field_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.flow_field = value
    _emit_change()


func _on_flow_pull_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.flow_pull = value
    _emit_change()


func _on_lightning_attract_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.lightning_attract = value
    _emit_change()


func _on_lightning_discharge_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.lightning_discharge = value
    _emit_change()


func _on_lightning_charge_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.lightning_charge_time = value
    _emit_change()


func _on_bh_strength_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.bh_strength = value
    _emit_change()


func _on_bh_damping_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.bh_damping = value
    _emit_change()


func _on_bh_explode_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.bh_explode = value
    _emit_change()


func _on_beam_speed_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.beam_speed = value
    _emit_change()


func _on_beam_attract_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.beam_attract = value
    _emit_change()


func _on_beam_cone_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.beam_cone = value
    _emit_change()


func _on_orbit_radius_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.orbit_radius = value
    _emit_change()


func _on_orbit_speed_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.orbit_speed = value
    _emit_change()


func _on_orbit_attract_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.orbit_attract = value
    _emit_change()


func _on_ripple_speed_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.ripple_speed = value
    _emit_change()


func _on_ripple_power_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.ripple_power = value
    _emit_change()


func _on_ripple_rate_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.ripple_rate = value
    _emit_change()


func _on_magnet_gap_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.magnet_gap = value
    _emit_change()


func _on_magnet_attract_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.magnet_attract = value
    _emit_change()


func _on_audio_source_selected(index: int) -> void:
    if _updating_ui:
        return
    var source := _audio_source.get_item_id(index) as AppSettings.AudioSource
    if source == AppSettings.AudioSource.PLAYBACK and settings.audio_source != source:
        # Stay on the current source until a grown-up confirms.
        _audio_source.select(_audio_source.get_item_index(int(settings.audio_source)))
        _ask_grown_up("Playback listens to audio from other apps on this device.", _set_audio_source.bind(source))
        return
    _set_audio_source(source)


func _set_audio_source(source: AppSettings.AudioSource) -> void:
    settings.audio_source = source
    _audio_source.select(_audio_source.get_item_index(int(source)))
    _emit_change()


func _on_audio_range_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.audio_range = _audio_range.get_item_id(index) as AppSettings.AudioRange
    _emit_change()


func _on_audio_style_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.audio_style = _audio_style.get_item_id(index) as AppSettings.AudioStyle
    _update_wave_direction_visibility()
    _update_draw_algorithm_visibility()
    _emit_change()


func _on_audio_style_auto_toggled(pressed: bool) -> void:
    if _updating_ui:
        return
    settings.audio_style_auto = pressed
    _emit_change()


func _on_audio_algorithm_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.audio_draw_algorithm = _audio_algorithm.get_item_id(index) as AppSettings.DrawAlgorithm
    _emit_change()


func _on_audio_direction_selected(index: int) -> void:
    if _updating_ui:
        return
    settings.audio_wave_direction = _audio_direction.get_item_id(index) as AppSettings.WaveDirection
    _emit_change()


func _on_audio_sensitivity_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.audio_sensitivity = value
    _emit_change()


func _on_audio_smooth_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.audio_smooth = value
    _emit_change()


func _on_magnet_repel_changed(value: float) -> void:
    _refresh_labels()
    if _updating_ui:
        return
    settings.magnet_repel = value
    _emit_change()
