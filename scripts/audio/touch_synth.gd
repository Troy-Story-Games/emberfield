class_name TouchSynth
extends Node
## One-voice pad. Vertical position picks a scale note; horizontal position sets loudness.

const _SCALES: Array = [
	[0, 2, 4, 5, 7, 9, 11],
	[0, 2, 3, 5, 7, 8, 10],
	[0, 2, 4, 7, 9],
	[0, 3, 5, 7, 10],
	[0, 2, 3, 5, 7, 9, 10],
	[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
]

var _settings: AppSettings
var _enabled: bool = false
var _gate: bool = false
var _anchor: Vector2 = Vector2.ZERO
var _bounds: Vector2 = Vector2(1080, 1920)
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _mix_rate: float = 44100.0
var _phase: float = 0.0
var _lp: float = 0.0
var _env: float = 0.0
var _freq: float = 440.0
var _target_freq: float = 440.0
var _cutoff: float = 800.0
var _finger_gain: float = 1.0


func apply_settings(s: AppSettings) -> void:
	_settings = s
	var enabled := s.touch_audio and s.art_mode != AppSettings.ArtMode.AUDIO
	if not enabled:
		_enabled = false
		_gate = false
		_stop()
		return
	_enabled = true
	_ensure_player()
	var vol := clampf(s.touch_audio_volume, 0.0, 1.0)
	_player.volume_db = -80.0 if vol <= 0.001 else linear_to_db(vol)
	if _gate:
		_retarget()


func set_point(anchor: Vector2, active: bool, bounds: Vector2) -> void:
	_anchor = anchor
	_bounds = bounds
	if not _enabled:
		_gate = false
		return
	_gate = active
	if active:
		_retarget()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _playback == null:
		_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if _playback == null:
		return
	_fill()


func _retarget() -> void:
	if _settings == null:
		return
	_target_freq = _note_freq()
	_cutoff = _cutoff_hz()
	_finger_gain = _finger_volume()


func _note_freq() -> float:
	var height := maxf(_bounds.y, 1.0)
	var y := clampf(_anchor.y / height, 0.0, 0.9999)
	var along := 1.0 - y
	var scale_id := clampi(int(_settings.touch_audio_scale), 0, _SCALES.size() - 1)
	var scale: Array = _SCALES[scale_id]
	var degrees := scale.size()
	var steps := maxi(int(round(_settings.touch_audio_octaves * float(degrees))), 1)
	var pos := clampf(along * float(steps), 0.0, float(steps) - 0.0001)
	var glide := clampf(_settings.touch_audio_glide, 0.0, 1.0)
	var blended := lerpf(round(pos), pos, glide)
	return _freq_at(blended, scale, degrees, steps)


func _freq_at(pos: float, scale: Array, degrees: int, steps: int) -> float:
	var max_index := steps - 1
	var i0 := clampi(int(floor(pos)), 0, max_index)
	var i1 := mini(i0 + 1, max_index)
	var frac := pos - float(i0)
	var midi := lerpf(_midi_at(i0, scale, degrees), _midi_at(i1, scale, degrees), frac)
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


func _midi_at(index: int, scale: Array, degrees: int) -> float:
	var octave := int(index / degrees)
	return float(AppSettings.touch_register_midi(_settings.touch_audio_register) + _settings.touch_audio_root + octave * 12 + int(scale[index % degrees]))


func _finger_volume() -> float:
	var width := maxf(_bounds.x, 1.0)
	return clampf(_anchor.x / width, 0.0, 1.0)


func _cutoff_hz() -> float:
	var tone := _settings.touch_audio_tone if _settings != null else 1.0
	var amount := clampf((tone - AppSettings.MIN_MUL) / (AppSettings.MAX_MUL - AppSettings.MIN_MUL), 0.0, 1.0)
	var hz := lerpf(280.0, 9000.0, amount)
	return minf(hz, _mix_rate * 0.45)


func _fill() -> void:
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	var rate := _mix_rate
	var target_env := 1.0 if _gate else 0.0
	var attack := AppSettings.DEFAULT_TOUCH_ATTACK
	var release := AppSettings.DEFAULT_TOUCH_RELEASE
	var wave := AppSettings.TouchWave.SAW
	if _settings != null:
		attack = _settings.touch_audio_attack
		release = _settings.touch_audio_release
		wave = _settings.touch_audio_wave
	var env_time := attack if target_env > _env else release
	var env_step := 1.0 - exp(-1.0 / (rate * maxf(env_time, 0.001)))
	var freq_step := 1.0 - exp(-1.0 / (rate * 0.004))
	var cutoff := _cutoff
	var gain := _finger_gain
	var lp_step := 1.0 - exp(-TAU * cutoff / rate)
	for _i in frames:
		_env += (target_env - _env) * env_step
		_freq += (_target_freq - _freq) * freq_step
		var raw := _wave_sample(wave)
		_phase = fmod(_phase + _freq / rate, 1.0)
		_lp += lp_step * (raw - _lp)
		var sample := _lp * _env * gain * 0.28
		_playback.push_frame(Vector2(sample, sample))


func _wave_sample(wave: AppSettings.TouchWave) -> float:
	match wave:
		AppSettings.TouchWave.SQUARE:
			return 1.0 if _phase < 0.5 else -1.0
		AppSettings.TouchWave.SINE:
			return sin(_phase * TAU)
		_:
			return _phase * 2.0 - 1.0


func _ensure_player() -> void:
	if _player != null and is_instance_valid(_player):
		return
	var gen := AudioStreamGenerator.new()
	_mix_rate = AudioServer.get_mix_rate()
	gen.mix_rate = _mix_rate
	gen.buffer_length = 0.03
	_player = AudioStreamPlayer.new()
	_player.name = "TouchVoice"
	_player.stream = gen
	_player.bus = "Master"
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func _stop() -> void:
	_env = 0.0
	_lp = 0.0
	if _player != null and is_instance_valid(_player):
		_player.stop()
		_player.queue_free()
	_player = null
	_playback = null
