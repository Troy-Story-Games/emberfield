class_name PlaybackFeed
extends Node
## Pushes native playback-capture frames into the Analyze bus.

signal status_changed(text: String)

var _player: AudioStreamPlayer
var _gen_playback: AudioStreamGeneratorPlayback
var _capture: Object
var _connected: bool = false
var _src: PackedVector2Array = PackedVector2Array()
var _src_pos: float = 0.0
var _seen_status: String = ""
var _bus_name: String = ""
var _plugin_wait: float = 0.0
var _waiting_for_plugin: bool = false


func start(bus_name: String) -> void:
    stop()
    _bus_name = bus_name
    _plugin_wait = 2.0
    _waiting_for_plugin = true
    if _try_begin():
        return
    _emit_status("Waiting for capture")


func stop() -> void:
    _waiting_for_plugin = false
    _plugin_wait = 0.0
    if _capture != null:
        _capture.call("stop")
    _disconnect_signals()
    _capture = null
    _gen_playback = null
    if _player != null:
        _player.stop()
        _player.queue_free()
        _player = null
    _src = PackedVector2Array()
    _src_pos = 0.0


func push_available(dt: float = 0.0) -> void:
    if _waiting_for_plugin:
        _plugin_wait -= dt
        if _try_begin():
            pass
        elif _plugin_wait <= 0.0:
            _waiting_for_plugin = false
            _emit_status("Playback plugin missing")
    if _capture == null or _gen_playback == null:
        return
    _poll_native_status()
    var raw: PackedFloat32Array = _capture.call("poll_frames")
    var src_rate := float(_capture.call("get_sample_rate"))
    if src_rate < 1000.0:
        return
    var pair_count := int(raw.size() / 2)
    if pair_count > 0:
        var base := _src.size()
        _src.resize(base + pair_count)
        for i in pair_count:
            _src[base + i] = Vector2(raw[i * 2], raw[i * 2 + 1])
    var can := _gen_playback.get_frames_available()
    if can <= 0 or _src.size() < 2:
        return
    var step := src_rate / AudioServer.get_mix_rate()
    var limit := mini(can, 4096)
    if is_equal_approx(step, 1.0):
        # Same rate (48 kHz on most phones): no resampling needed.
        var take := mini(limit, _src.size())
        _gen_playback.push_buffer(_src.slice(0, take))
        _src = _src.slice(take)
        _src_pos = 0.0
        if _src.size() > 24000:
            _src = _src.slice(_src.size() - 12000)
        return
    var out := PackedVector2Array()
    var pos := _src_pos
    var last := float(_src.size() - 1)
    while out.size() < limit and pos < last:
        var i0 := int(pos)
        var frac := pos - float(i0)
        var i1 := mini(i0 + 1, _src.size() - 1)
        out.append(_src[i0].lerp(_src[i1], frac))
        pos += step
    if out.is_empty():
        return
    _gen_playback.push_buffer(out)
    var consumed := int(pos)
    if consumed > 0:
        _src = _src.slice(consumed)
        pos -= float(consumed)
    _src_pos = pos
    if _src.size() > 24000:
        _src = _src.slice(_src.size() - 12000)
        _src_pos = 0.0


func _try_begin() -> bool:
    if not Engine.has_singleton("PlaybackCapture"):
        return false
    var capture: Object = Engine.get_singleton("PlaybackCapture")
    if not bool(capture.call("is_supported")):
        _waiting_for_plugin = false
        _plugin_wait = 0.0
        _emit_status("Playback unavailable")
        return true
    _capture = capture
    _waiting_for_plugin = false
    _open_player()
    return true


func _open_player() -> void:
    _connect_signals()
    var gen := AudioStreamGenerator.new()
    gen.mix_rate = AudioServer.get_mix_rate()
    # Small enough to keep visuals on the beat, large enough to ride out frame hitches.
    gen.buffer_length = 0.08
    _player = AudioStreamPlayer.new()
    _player.name = "PlaybackPlayer"
    _player.stream = gen
    _player.bus = _bus_name
    # Player volume is pre-bus. Keep it at unity so the spectrum effect hears the signal.
    _player.volume_db = 0.0
    add_child(_player)
    _player.play()
    _gen_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
    _src = PackedVector2Array()
    _src_pos = 0.0
    _seen_status = ""
    _emit_status("Waiting for capture")
    _capture.call("start")


func _poll_native_status() -> void:
    if _capture == null or not _capture.has_method("get_status"):
        return
    var native := str(_capture.call("get_status"))
    if native == "" or native == _seen_status:
        return
    _seen_status = native
    _emit_status(native)


func _connect_signals() -> void:
    if _connected or _capture == null:
        return
    if _capture.has_signal("capture_started"):
        _capture.connect("capture_started", _on_capture_started)
    if _capture.has_signal("capture_failed"):
        _capture.connect("capture_failed", _on_capture_failed)
    _connected = true


func _disconnect_signals() -> void:
    if not _connected or _capture == null:
        _connected = false
        return
    if _capture.has_signal("capture_started") and _capture.is_connected("capture_started", _on_capture_started):
        _capture.disconnect("capture_started", _on_capture_started)
    if _capture.has_signal("capture_failed") and _capture.is_connected("capture_failed", _on_capture_failed):
        _capture.disconnect("capture_failed", _on_capture_failed)
    _connected = false


func _on_capture_started() -> void:
    _emit_status("Capturing")


func _on_capture_failed(reason: String) -> void:
    _emit_status(reason if reason != "" else "Capture blocked")


func _emit_status(text: String) -> void:
    _seen_status = text
    status_changed.emit(text)
