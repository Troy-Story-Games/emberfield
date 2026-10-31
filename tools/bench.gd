extends SceneTree
## Headless frame-time benchmark for every art mode and audio style.
## Godot --headless --path . -s res://tools/bench.gd [-- --frames=240 --counts=5000,12000]

const WARMUP := 30
const CYCLE := 120
const HELD := 90

var _frames: int = 240
var _counts: PackedInt32Array = PackedInt32Array([5000, 12000])
var _sim: ParticleSimulator
var _done: bool = false


func _initialize() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--frames="):
            _frames = int(arg.trim_prefix("--frames="))
        elif arg.begins_with("--counts="):
            _counts = PackedInt32Array()
            for part in arg.trim_prefix("--counts=").split(","):
                _counts.append(int(part))

    _sim = (load("res://scenes/particle_canvas.tscn") as PackedScene).instantiate() as ParticleSimulator
    _sim.settings = AppSettings.new()
    root.add_child(_sim)


func _process(_delta: float) -> bool:
    if _done:
        return true
    _done = true
    var sim := _sim
    sim.set_process(false)
    var touch := TouchInput.new()
    sim.bind_touch(touch)

    var cases: Array = []
    for mode_id in AppSettings.ArtMode.size():
        if mode_id == AppSettings.ArtMode.AUDIO:
            for style_id in AppSettings.AudioStyle.size():
                cases.append([mode_id, style_id, AppSettings.ColorPreset.FIRE])
        else:
            cases.append([mode_id, 0, AppSettings.ColorPreset.FIRE])
    cases.append([AppSettings.ArtMode.WAVE, 0, AppSettings.ColorPreset.SPARKLE])

    print("%-28s %10s %10s" % ["case", "count", "ms/frame"])
    for count in _counts:
        for c in cases:
            var s := AppSettings.new()
            s.art_mode = c[0]
            s.audio_style = c[1]
            s.color_preset = c[2]
            s.particle_count = count
            sim.apply_settings(s)
            var feed: AudioFeed = sim.get("_audio_feed")
            if feed != null:
                feed.stop()
            var ms := _run(sim, touch, feed, s)
            var label := AppSettings.art_mode_name(s.art_mode)
            if s.art_mode == AppSettings.ArtMode.AUDIO:
                label += "/" + AppSettings.audio_style_name(s.audio_style)
            if s.color_preset == AppSettings.ColorPreset.SPARKLE:
                label += " +sparkle"
            print("%-28s %10d %10.2f" % [label, count, ms])
    return true


func _run(sim: ParticleSimulator, touch: TouchInput, feed: AudioFeed, s: AppSettings) -> float:
    var dt := 1.0 / 60.0
    var size := Vector2(1080, 1920)
    var start := 0
    for f in WARMUP + _frames:
        if f == WARMUP:
            start = Time.get_ticks_usec()
        var phase := f % CYCLE
        var t := float(f) * dt
        var prev := touch.last_anchor
        touch.is_active = phase < HELD
        touch.just_pressed = phase == 0
        touch.just_released = phase == HELD
        touch.last_anchor = size * 0.5 + Vector2(cos(t * 1.3), sin(t * 1.7)) * 300.0
        touch.velocity = (touch.last_anchor - prev) / dt
        if s.art_mode == AppSettings.ArtMode.AUDIO and feed != null:
            _fake_audio(feed, t)
        sim._process(dt)
    return float(Time.get_ticks_usec() - start) / 1000.0 / float(_frames)


func _fake_audio(feed: AudioFeed, t: float) -> void:
    if feed.bands.size() != AudioFeed.BAND_COUNT:
        feed.bands.resize(AudioFeed.BAND_COUNT)
        feed.band_delta.resize(AudioFeed.BAND_COUNT)
    if feed.waveform.size() != AudioFeed.WAVE_POINTS:
        feed.waveform.resize(AudioFeed.WAVE_POINTS)
    var beat := fmod(t, 0.5) < 1.0 / 60.0
    for i in AudioFeed.BAND_COUNT:
        var v := 0.4 + 0.4 * sin(t * 3.0 + float(i) * 0.7)
        feed.band_delta[i] = maxf(0.0, v - feed.bands[i])
        feed.bands[i] = v
    for i in AudioFeed.WAVE_POINTS:
        feed.waveform[i] = 0.5 * sin(t * 20.0 + float(i) * 0.3)
    feed.level = 0.8
    feed.bass = feed.bands[0]
    feed.mids = feed.bands[6]
    feed.beat_hit = beat
    feed.division_hit = beat
    feed.tempo_confidence = 0.8
    feed.bps = 2.0
    feed.amp = 0.1
