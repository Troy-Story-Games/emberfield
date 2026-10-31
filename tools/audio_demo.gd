extends SceneTree
## Plays a synthetic 120 BPM track into the muted Analyze bus and screenshots an Audio style.
## Needs a real audio driver and GPU window (not --headless). Nothing is audible: the bus is muted.
## Godot --path . -s res://tools/audio_demo.gd -- --out=C:/tmp/eq --style=1 [--shots=3]

const RATE := 44100.0
const BPM := 120.0

var _out: String = "user://audio"
var _style: int = 0
var _shots: int = 3
var _frame: int = 0
var _main: Node
var _gen: AudioStreamGeneratorPlayback
var _t: float = 0.0
var _rng := RandomNumberGenerator.new()
var _beats: int = 0
var _rise_sum: float = 0.0


func _initialize() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--out="):
            _out = arg.trim_prefix("--out=")
        elif arg.begins_with("--style="):
            _style = int(arg.trim_prefix("--style="))
        elif arg.begins_with("--shots="):
            _shots = int(arg.trim_prefix("--shots="))
    _main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(_main)


func _process(_delta: float) -> bool:
    _frame += 1
    if _frame == 2:
        var s: AppSettings = _main.get("settings")
        s.art_mode = AppSettings.ArtMode.AUDIO
        s.audio_style = _style as AppSettings.AudioStyle
        s.audio_style_auto = false
        s.audio_source = AppSettings.AudioSource.MICROPHONE
        s.hint_shown = true
        _main.get_node("%SettingsPanel").call("bind_settings", s)
        _main.get_node("%SettingsPanel").call("_dismiss_hint")
        _main.get_node("%ParticleSimulator").call("apply_settings", s)
        # Mute the real microphone so only the synthetic track drives the analyzer.
        for node in _main.find_children("MicPlayer", "AudioStreamPlayer", true, false):
            (node as AudioStreamPlayer).volume_db = -80.0
        var player := AudioStreamPlayer.new()
        var stream := AudioStreamGenerator.new()
        stream.mix_rate = RATE
        stream.buffer_length = 0.1
        player.stream = stream
        player.bus = AudioFeed.BUS_NAME
        root.add_child(player)
        player.play()
        _gen = player.get_stream_playback()
    if _gen != null:
        _fill()
    var feed := AudioFeed.active
    if feed != null and OS.get_cmdline_user_args().has("--stats"):
        if feed.beat_hit:
            _beats += 1
        _rise_sum += feed.band_delta[0] + feed.band_delta[1] + feed.band_delta[2]
        if _frame % 60 == 0:
            print("t=%d beats=%d level=%.2f bass=%.2f mids=%.2f rise/frame=%.3f bands=%s" % [_frame / 60, _beats, feed.level, feed.bass, feed.mids, _rise_sum / 60.0 / 3.0, str(feed.bands.slice(0, 16)).left(120)])
            _rise_sum = 0.0
    var first := 300
    var gap := 23
    for k in _shots:
        if _frame == first + k * gap:
            var img := root.get_texture().get_image()
            var path := "%s_%d.png" % [_out, k]
            img.save_png(path)
            print("saved ", path)
    return _frame >= first + _shots * gap


func _fill() -> void:
    var beat := 60.0 / BPM
    var frames := _gen.get_frames_available()
    for n in frames:
        var t := _t
        var in_beat := fmod(t, beat)
        var in_half := fmod(t, beat * 0.5)
        var bar_beat := int(t / beat) % 4
        # Kick: pitch sweep from 110 Hz down to 45 Hz.
        var kick := sin(TAU * (45.0 * in_beat + 65.0 * 0.03 * (1.0 - exp(-in_beat / 0.03)))) * exp(-in_beat * 9.0)
        # Snare on 2 and 4: noise burst plus a 190 Hz body.
        var snare := 0.0
        if bar_beat == 1 or bar_beat == 3:
            snare = (_rng.randf_range(-1.0, 1.0) * 0.6 + sin(TAU * 190.0 * in_beat) * 0.4) * exp(-in_beat * 18.0)
        # Hats on eighths: crude high-passed noise.
        var hat := _rng.randf_range(-1.0, 1.0) * exp(-in_half * 60.0) * 0.35
        # Bass line and a slow chord pad.
        var roots := [55.0, 55.0, 73.4, 65.4]
        var root_hz: float = roots[int(t / (beat * 4.0)) % 4]
        var bass := (fmod(t * root_hz, 1.0) * 2.0 - 1.0) * 0.25
        var pad := (sin(TAU * root_hz * 4.0 * t) + sin(TAU * root_hz * 5.04 * t) + sin(TAU * root_hz * 6.0 * t)) * 0.06
        var lead := sin(TAU * root_hz * 8.0 * (1.0 + 0.5 * float(int(t / (beat * 0.5)) % 3)) * t) * 0.05 * (0.5 + 0.5 * sin(t * 0.7))
        var v := clampf(kick * 0.9 + snare * 0.5 + hat + bass + pad + lead, -1.0, 1.0) * 0.8
        _gen.push_frame(Vector2(v, v))
        _t += 1.0 / RATE
