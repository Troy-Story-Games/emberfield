class_name AudioFeed
extends Node
## Spectrum analyzer fed by the microphone or native playback capture.

const BUS_NAME := "Analyze"
const BAND_COUNT := 16
const WAVE_POINTS := 160
## Band level is mapped from dB: FLOOR_DB reads as silent, FLOOR_DB + RANGE_DB as full.
const FLOOR_DB := -64.0
const RANGE_DB := 50.0
## Envelope times. Release also scales with the Smooth setting.
const ATTACK_TIME := 0.012
const RELEASE_BASE := 0.04
const RELEASE_PER_SMOOTH := 0.16
## Auto gain: the loudest band is normalized to about full, and the reference decays
## this much per second so quiet passages fill the screen again.
const AGC_DECAY := 0.07
const AGC_MIN := 0.35
## The fast attack makes single-frame rises much larger than the old smoothed bands did;
## this keeps the styles' kick strengths in the range they were tuned for.
const DELTA_SCALE := 0.3
const BEAT_BANDS := 6

static var active: AudioFeed

var bands: PackedFloat32Array = PackedFloat32Array()
var band_delta: PackedFloat32Array = PackedFloat32Array()
var waveform: PackedFloat32Array = PackedFloat32Array()
var bass: float = 0.0
var mids: float = 0.0
var level: float = 0.0
var beat: float = 0.0
var beat_hit: bool = false
var bar_hit: bool = false
var division_hit: bool = false
var turn_every: int = 4
var kick_deviation: float = 0.0
var kick_consistency: float = 0.0
var bps: float = 0.0
var tempo_confidence: float = 0.0
var amp: float = 0.0
var amp_average: float = 0.0
var status_text: String = "Audio off"

var _sensitivity: float = 1.0
var _smooth: float = 1.0
var _source: int = 0
var _running: bool = false
var _awaiting_permission: bool = false
var _suspended: bool = false
var _bus_idx: int = -1
var _analyzer: AudioEffectSpectrumAnalyzer
var _capture: AudioEffectCapture
var _mic: AudioStreamPlayer
var _playback: PlaybackFeed
var _band_lo: PackedFloat32Array = PackedFloat32Array()
var _band_hi: PackedFloat32Array = PackedFloat32Array()
var _band_weight: PackedFloat32Array = PackedFloat32Array()
var _range_gain: float = 1.0
var _waveform_gain: float = 1.0
var _bass_env: float = 0.0
var _beat_cooldown: float = 0.0
var _listen_time: float = 0.0
var _next_beat: float = -1.0
var _beat_period: float = 0.5
var _onset_times: Array[float] = []
var _beat_intervals: Array[float] = []
var _bar_count: int = 0
var _kick_cooldown: float = 0.0
var _kick_env: float = 0.0
var _kick_intervals: Array[float] = []
var _last_kick_time: float = -1.0
var _division_want: int = 4
var _division_hold: float = 0.0
var _agc_peak: float = AGC_MIN
var _raw_prev: PackedFloat32Array = PackedFloat32Array()
var _flux_mean: float = 0.0
var _low_flux: float = 0.0
var _low_flux_mean: float = 0.0
var _wave_peak: float = 0.05
var _wave_scratch: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
    bands.resize(BAND_COUNT)
    band_delta.resize(BAND_COUNT)
    waveform.resize(WAVE_POINTS)
    _band_lo.resize(BAND_COUNT)
    _band_hi.resize(BAND_COUNT)
    _band_weight.resize(BAND_COUNT)
    _raw_prev.resize(BAND_COUNT)
    _layout_bands(40.0, 16000.0, 1.0, 1.0, 1.0, 1.0, false)


func _process(_delta: float) -> void:
    if not _running or not _awaiting_permission:
        return
    if _permission_granted():
        _awaiting_permission = false
        _start_current_source()


func apply_audio_settings(s: AppSettings) -> void:
    _sensitivity = s.audio_sensitivity
    _smooth = s.audio_smooth
    _apply_range(int(s.audio_range))
    var next := int(s.audio_source)
    if _running and next != _source:
        stop()
        _source = next
        start()
    else:
        _source = next


func start() -> void:
    if _running:
        return
    _running = true
    active = self
    _ensure_bus()
    _start_current_source()


func stop() -> void:
    _running = false
    _awaiting_permission = false
    if active == self:
        active = null
    _stop_mic()
    if _playback != null:
        _playback.stop()
    status_text = "Audio off"
    _reset_tempo()


## Releases the microphone while the app is in the background, and reopens it on return.
## Playback capture keeps running under its foreground-service notification: Android
## only grants one capture per consent, so stopping it would re-prompt on every return.
func set_suspended(suspended: bool) -> void:
    if suspended == _suspended:
        return
    _suspended = suspended
    if not _running or _source != AppSettings.AudioSource.MICROPHONE:
        return
    if suspended:
        _stop_mic()
        status_text = "Paused"
    else:
        _start_mic()


func poll(dt: float) -> void:
    if not _running:
        return
    if _source == AppSettings.AudioSource.PLAYBACK and _playback != null:
        _playback.push_available(dt)
    _sample_bands(dt)
    _sample_waveform(dt)
    _sample_amp(dt)


func _start_current_source() -> void:
    if _source == AppSettings.AudioSource.PLAYBACK:
        _stop_mic()
        _start_playback()
    else:
        if _playback != null:
            _playback.stop()
        _start_mic()


func _ensure_bus() -> void:
    _bus_idx = AudioServer.get_bus_index(BUS_NAME)
    if _bus_idx == -1:
        AudioServer.add_bus()
        _bus_idx = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(_bus_idx, BUS_NAME)
        AudioServer.set_bus_send(_bus_idx, "Master")
        _analyzer = AudioEffectSpectrumAnalyzer.new()
        _analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
        # Short history keeps the bars on the beat; 50 ms still holds a full 1024-point FFT.
        _analyzer.buffer_length = 0.05
        AudioServer.add_bus_effect(_bus_idx, _analyzer)
        _capture = AudioEffectCapture.new()
        _capture.buffer_length = 0.25
        AudioServer.add_bus_effect(_bus_idx, _capture)
    else:
        _analyzer = AudioServer.get_bus_effect(_bus_idx, 0) as AudioEffectSpectrumAnalyzer
        _capture = null
        for effect_i in AudioServer.get_bus_effect_count(_bus_idx):
            var effect := AudioServer.get_bus_effect(_bus_idx, effect_i)
            if effect is AudioEffectCapture:
                _capture = effect
                break
        if _capture == null:
            _capture = AudioEffectCapture.new()
            _capture.buffer_length = 0.25
            AudioServer.add_bus_effect(_bus_idx, _capture)
    # Volume is applied after effects, so the analyzer still hears the input.
    AudioServer.set_bus_volume_db(_bus_idx, -80.0)


func _start_mic() -> void:
    if not _ensure_permission():
        return
    # Restarting right away kills input: the old player closes the shared input device
    # only once it's freed, after the new one has already tried to open it.
    if _mic != null and _mic.playing:
        status_text = "Listening"
        return
    if AudioServer.get_input_device_list().is_empty():
        status_text = "Microphone unavailable"
        return
    _stop_mic()
    _mic = AudioStreamPlayer.new()
    _mic.name = "MicPlayer"
    _mic.stream = AudioStreamMicrophone.new()
    _mic.bus = BUS_NAME
    _mic.volume_db = 0.0
    add_child(_mic)
    _mic.play()
    status_text = "Listening"


func _stop_mic() -> void:
    if _mic == null:
        return
    _mic.stop()
    _mic.queue_free()
    _mic = null


func _start_playback() -> void:
    if not _ensure_permission():
        return
    if _playback == null:
        _playback = PlaybackFeed.new()
        _playback.name = "PlaybackFeed"
        _playback.status_changed.connect(_on_playback_status)
        add_child(_playback)
    _playback.start(BUS_NAME)


func _on_playback_status(text: String) -> void:
    status_text = text


func _ensure_permission() -> bool:
    if OS.get_name() != "Android" or _permission_granted():
        _awaiting_permission = false
        return true
    OS.request_permission("android.permission.RECORD_AUDIO")
    _awaiting_permission = true
    status_text = "Permission needed"
    return false


func _permission_granted() -> bool:
    return OS.get_granted_permissions().has("android.permission.RECORD_AUDIO")


func _apply_range(range_id: int) -> void:
    match range_id:
        AppSettings.AudioRange.VOICE:
            _layout_bands(150.0, 4000.0, 1.3, 0.45, 1.6, 0.55, false)
        AppSettings.AudioRange.HEAVY:
            _layout_bands(30.0, 5000.0, 1.15, 1.8, 0.9, 0.45, false)
        AppSettings.AudioRange.ROCK:
            _layout_bands(50.0, 8000.0, 1.1, 1.35, 1.4, 0.7, false)
        AppSettings.AudioRange.QUIET:
            _layout_bands(60.0, 12000.0, 2.2, 0.8, 1.3, 0.9, true)
        AppSettings.AudioRange.BRIGHT:
            _layout_bands(200.0, 16000.0, 1.2, 0.4, 1.0, 1.7, false)
        _:
            _layout_bands(40.0, 16000.0, 1.0, 1.0, 1.0, 1.0, false)


func _layout_bands(freq_min: float, freq_max: float, gain: float, low_w: float, mid_w: float, high_w: float, quiet_wave: bool) -> void:
    _range_gain = gain
    _waveform_gain = gain if quiet_wave else 1.0
    var log_min := log(freq_min)
    var log_max := log(freq_max)
    for i in BAND_COUNT:
        var t0 := float(i) / float(BAND_COUNT)
        var t1 := float(i + 1) / float(BAND_COUNT)
        _band_lo[i] = exp(lerpf(log_min, log_max, t0))
        _band_hi[i] = exp(lerpf(log_min, log_max, t1))
        var t := (float(i) + 0.5) / float(BAND_COUNT)
        if t < 0.5:
            _band_weight[i] = lerpf(low_w, mid_w, t / 0.5)
        else:
            _band_weight[i] = lerpf(mid_w, high_w, (t - 0.5) / 0.5)


func _sample_bands(dt: float) -> void:
    if _bus_idx < 0:
        return
    var inst := AudioServer.get_bus_effect_instance(_bus_idx, 0) as AudioEffectSpectrumAnalyzerInstance
    if inst == null:
        return
    if _raw_prev.size() != BAND_COUNT:
        _raw_prev.resize(BAND_COUNT)
    var attack := 1.0 - exp(-dt / ATTACK_TIME)
    var release := 1.0 - exp(-dt / (RELEASE_BASE + RELEASE_PER_SMOOTH * _smooth))
    # Sensitivity 1.6 is the default and maps to unity gain.
    var gain := _sensitivity / 1.6
    # Rises are reported per 60 Hz frame so kicks feel the same at any frame rate.
    var per_frame := (1.0 / 60.0) / maxf(dt, 0.001) * DELTA_SCALE
    var loudest := 0.0
    var flux := 0.0
    var low_flux := 0.0
    var raws := PackedFloat32Array()
    raws.resize(BAND_COUNT)
    for i in BAND_COUNT:
        var mag: Vector2 = inst.get_magnitude_for_frequency_range(
            _band_lo[i], _band_hi[i], AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX
        )
        var linear := maxf(mag.x, mag.y) * _range_gain * _band_weight[i]
        var raw := clampf((linear_to_db(linear + 1e-7) - FLOOR_DB) / RANGE_DB, 0.0, 1.0)
        raws[i] = raw
        loudest = maxf(loudest, raw)
        var rise := maxf(0.0, raw - _raw_prev[i])
        # Beats follow the kick and bass; hats and snares would fire on every eighth note.
        if i < BEAT_BANDS:
            flux += rise
        if i < 4:
            low_flux += rise
        _raw_prev[i] = raw
    _agc_peak = maxf(maxf(loudest, AGC_MIN), _agc_peak - AGC_DECAY * dt)

    level = 0.0
    for i in BAND_COUNT:
        var target := clampf(raws[i] / _agc_peak * gain, 0.0, 1.0)
        var prev := bands[i]
        bands[i] = lerpf(prev, target, attack if target > prev else release)
        band_delta[i] = maxf(0.0, bands[i] - prev) * per_frame
        level = maxf(level, bands[i])

    bass = (bands[0] + bands[1] + bands[2]) / 3.0
    var mid_sum := 0.0
    for i in range(4, 10):
        mid_sum += bands[i]
    mids = mid_sum / 6.0

    # Onsets: spectral flux against its own running average, so the threshold follows
    # the music instead of a fixed level.
    _beat_cooldown = maxf(0.0, _beat_cooldown - dt)
    beat = maxf(0.0, beat - dt * 3.0)
    var raw_hit := false
    if flux > _flux_mean * 1.8 + 0.08 and level > 0.1 and _beat_cooldown <= 0.0:
        raw_hit = true
        _beat_cooldown = 0.2
    _flux_mean = lerpf(_flux_mean, flux, clampf(dt * 2.0, 0.0, 1.0))
    _low_flux = low_flux
    _bass_env = lerpf(_bass_env, bass, clampf(dt * 1.6, 0.0, 1.0))
    _lock_tempo(dt, raw_hit)
    _track_kicks(dt)


func _reset_tempo() -> void:
    bps = 0.0
    tempo_confidence = 0.0
    amp = 0.0
    amp_average = 0.0
    beat_hit = false
    _listen_time = 0.0
    _next_beat = -1.0
    _beat_period = 0.5
    _onset_times.clear()
    _beat_intervals.clear()
    _bar_count = 0
    bar_hit = false
    division_hit = false
    turn_every = 4
    kick_deviation = 0.0
    kick_consistency = 0.0
    _kick_cooldown = 0.0
    _kick_env = 0.0
    _kick_intervals.clear()
    _last_kick_time = -1.0
    _division_want = 4
    _division_hold = 0.0
    _agc_peak = AGC_MIN
    _flux_mean = 0.0
    _low_flux = 0.0
    _low_flux_mean = 0.0
    _wave_peak = 0.05


func _lock_tempo(dt: float, raw_hit: bool) -> void:
    _listen_time += dt
    if raw_hit:
        if not _onset_times.is_empty():
            var interval := _listen_time - _onset_times[_onset_times.size() - 1]
            if interval >= 0.25 and interval <= 1.5:
                _beat_intervals.append(interval)
                if _beat_intervals.size() > 16:
                    _beat_intervals.pop_front()
        _onset_times.append(_listen_time)
        if _onset_times.size() > 17:
            _onset_times.pop_front()
    _recompute_tempo()
    beat_hit = false
    bar_hit = false
    division_hit = false
    if tempo_confidence < 0.45 or _beat_period <= 0.0:
        if raw_hit:
            _mark_beat()
            _next_beat = _listen_time + maxf(_beat_period, 0.5)
        return
    if _next_beat < 0.0:
        _next_beat = _listen_time + _beat_period
    if raw_hit and absf(_listen_time - _next_beat) <= _beat_period * 0.22:
        _next_beat = lerpf(_next_beat, _listen_time + _beat_period, 0.35)
    if _listen_time >= _next_beat:
        _mark_beat()
        _next_beat += _beat_period
        while _next_beat <= _listen_time:
            _next_beat += _beat_period


func _mark_beat() -> void:
    beat_hit = true
    beat = 1.0
    bar_hit = false
    division_hit = false
    if tempo_confidence < 0.45:
        return
    _bar_count += 1
    bar_hit = _bar_count % 4 == 0
    var every := turn_every if turn_every > 0 else 4
    division_hit = _bar_count % every == 0


func _track_kicks(dt: float) -> void:
    _kick_cooldown = maxf(0.0, _kick_cooldown - dt)
    if _last_kick_time >= 0.0 and _listen_time - _last_kick_time > 0.7:
        _kick_intervals.clear()
        _last_kick_time = -1.0
    if _low_flux > _low_flux_mean * 1.6 + 0.03 and bass > 0.1 and _kick_cooldown <= 0.0:
        _kick_cooldown = 0.07
        if _last_kick_time >= 0.0:
            var interval := _listen_time - _last_kick_time
            if interval >= 0.07 and interval <= 0.45:
                _kick_intervals.append(interval)
                if _kick_intervals.size() > 8:
                    _kick_intervals.pop_front()
        _last_kick_time = _listen_time
    _kick_env = lerpf(_kick_env, bass, clampf(dt * 2.4, 0.0, 1.0))
    _low_flux_mean = lerpf(_low_flux_mean, _low_flux, clampf(dt * 2.4, 0.0, 1.0))
    _measure_kicks()
    _choose_division(dt)


func _measure_kicks() -> void:
    kick_deviation = 0.0
    kick_consistency = 0.0
    if _kick_intervals.size() < 4 or _beat_period <= 0.0 or tempo_confidence < 0.45:
        return
    var sorted: Array = _kick_intervals.duplicate()
    sorted.sort()
    var median: float = sorted[sorted.size() >> 1]
    var spread := 0.0
    for interval in _kick_intervals:
        spread += absf(float(interval) - median)
    spread /= float(_kick_intervals.size())
    kick_consistency = clampf(1.0 - spread / maxf(median, 0.01), 0.0, 1.0)
    var ratio := median / _beat_period
    if ratio < 1.0:
        kick_deviation = clampf((1.0 - ratio) / 0.35, 0.0, 1.0)


func _choose_division(dt: float) -> void:
    var loud := clampf((level - 0.04) / 0.5, 0.0, 1.0)
    var want := 4
    if kick_consistency >= 0.6 and kick_deviation >= 0.35 and loud >= 0.55:
        want = 2
    if kick_consistency >= 0.65 and kick_deviation >= 0.7 and loud >= 0.85:
        want = 1
    if want != _division_want:
        _division_want = want
        _division_hold = 0.0
    _division_hold += dt
    if _division_hold >= 0.28:
        turn_every = _division_want


func _recompute_tempo() -> void:
    if _beat_intervals.size() < 3:
        tempo_confidence = 0.0
        bps = 0.0
        return
    var sorted: Array = _beat_intervals.duplicate()
    sorted.sort()
    var median: float = sorted[sorted.size() >> 1]
    var deviation := 0.0
    for interval in _beat_intervals:
        deviation += absf(float(interval) - median)
    deviation /= float(_beat_intervals.size())
    var stability := clampf(1.0 - deviation / maxf(median, 0.01), 0.0, 1.0)
    var count_conf := clampf(float(_beat_intervals.size()) / 8.0, 0.0, 1.0)
    tempo_confidence = stability * count_conf
    _beat_period = median
    bps = 1.0 / median


func _sample_amp(dt: float) -> void:
    if waveform.is_empty():
        amp = 0.0
        return
    var sum := 0.0
    for sample in waveform:
        sum += sample
    amp = sum / float(waveform.size())
    amp_average = lerpf(amp_average, absf(amp), clampf(dt * 0.15, 0.0, 1.0))


func _sample_waveform(dt: float) -> void:
    if waveform.size() != WAVE_POINTS:
        waveform.resize(WAVE_POINTS)
    if _capture == null:
        return
    var available := _capture.get_frames_available()
    if available < 64:
        return
    var frames := _capture.get_buffer(mini(available, 4096))
    var count := frames.size()
    if count < WAVE_POINTS:
        return
    # Show about 40 ms. Start the window on a rising zero crossing so the line
    # holds still instead of sliding sideways every frame.
    var window := mini(count / 2, 1764)
    var hop := maxi(1, window / WAVE_POINTS)
    window = hop * WAVE_POINTS
    var latest := count - window
    var start := latest
    var search_from := maxi(1, latest - window)
    for k in range(latest, search_from, -1):
        var a := frames[k - 1].x + frames[k - 1].y
        var b := frames[k].x + frames[k].y
        if a < 0.0 and b >= 0.0:
            start = k
            break
    if _wave_scratch.size() != WAVE_POINTS:
        _wave_scratch.resize(WAVE_POINTS)
    var peak := 0.0
    for i in WAVE_POINTS:
        # Average each hop instead of point-sampling it, which aliases into noise.
        var sum := 0.0
        var base := start + i * hop
        for j in hop:
            var f := frames[base + j]
            sum += f.x + f.y
        var v := sum * 0.5 / float(hop)
        _wave_scratch[i] = v
        peak = maxf(peak, absf(v))
    _wave_peak = maxf(maxf(peak, 0.02), _wave_peak - dt * 0.4)
    var gain := 0.9 / _wave_peak * (_sensitivity / 1.6) * _waveform_gain
    var keep := exp(-dt / 0.03)
    for i in WAVE_POINTS:
        var target := clampf(_wave_scratch[i] * gain, -1.0, 1.0)
        waveform[i] = lerpf(target, waveform[i], keep)
