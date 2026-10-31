extends Node
## Root controller: wires settings, touch, simulator, and UI.

@onready var simulator: ParticleSimulator = %ParticleSimulator
@onready var touch_input: TouchInput = %TouchInput
@onready var settings_panel: Node = %SettingsPanel

var settings: AppSettings = AppSettings.new()


func _ready() -> void:
    settings.load_from_disk()
    # Keep mouse visible on desktop (do not hide cursor).
    # Back is handled in _notification so it can close the settings panel first.
    get_tree().quit_on_go_back = false

    settings_panel.call("bind_settings", settings)
    settings_panel.connect("settings_changed", _on_settings_changed)
    settings_panel.connect("visibility_toggled", _on_settings_visibility)

    var lightning_layer: Node2D = simulator.get_node("DisplayLayer/LightningLayer")
    lightning_layer.set("simulator", simulator)

    simulator.settings = settings
    simulator.bind_touch(touch_input)
    simulator.auto_mode_changed.connect(_on_auto_mode_changed)
    simulator.apply_settings(settings)
    _apply_frame_rate()


func _notification(what: int) -> void:
    match what:
        NOTIFICATION_APPLICATION_PAUSED:
            # Never keep the microphone open in the background.
            simulator.set_audio_suspended(true)
            settings.save_to_disk()
        NOTIFICATION_APPLICATION_RESUMED:
            simulator.set_audio_suspended(false)
        NOTIFICATION_WM_GO_BACK_REQUEST:
            if settings_panel.call("is_open"):
                settings_panel.call("close")
            else:
                settings.save_to_disk()
                get_tree().quit()
        NOTIFICATION_WM_CLOSE_REQUEST:
            settings.save_to_disk()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_settings"):
        settings_panel.call("toggle")
        get_viewport().set_input_as_handled()


func _on_settings_changed(s: AppSettings) -> void:
    simulator.apply_settings(s)
    _apply_frame_rate()


func _apply_frame_rate() -> void:
    Engine.max_fps = settings.max_fps


func _on_auto_mode_changed(s: AppSettings) -> void:
    # Keep the settings panel mode dropdown in sync with Auto Control.
    if settings_panel.has_method("bind_settings"):
        settings_panel.call("bind_settings", s)


func _on_settings_visibility(open: bool) -> void:
    touch_input.set_ui_blocked(open)
