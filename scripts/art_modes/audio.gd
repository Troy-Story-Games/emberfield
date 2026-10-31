class_name ArtAudio
extends ArtModeBase
## Audio — particles react to microphone or playback spectrum bands.

const PULSE_SPRING := 16.0
const PULSE_KICK := 2400.0
const BEAT_KICK := 900.0
const COL_SPRING := 22.0
const COL_KICK := 2800.0
const WAVE_SPRING := 48.0
const WAVE_KICK := 700.0
const BAR_REACH := 0.96
## Bars drawn across the screen; bands are interpolated between them.
const EQ_COLUMNS := 40
const EQ_RAYS := 72
## Fraction of each bar slot the particles fill (the rest is the gap).
const BAR_FILL := 0.72
const GALAXY_SEGMENTS := 48
## Fraction of particles in the central bulge.
const GALAXY_CORE := 0.15
## How far each arm winds from core to rim, in radians.
const GALAXY_WIND := 3.6
const GALAXY_SPIN_BASE := 0.25
const GALAXY_SPIN_MIDS := 2.2
const LEARNED_BEAT := 320.0
const DRAW_SPRING := 120.0
const DRAW_BEAT := 260.0
const HEAD_RESERVE := 100
const SWIRL_SPIN := 2600.0
const SWIRL_RADIAL := 26.0
const SWIRL_FLING := 3400.0
const TOUCH_PULL := 520.0
const MAX_SPEED := 4200.0
const DRAG_HELD := 0.85
const DRAG_FREE := 1.2

var feed: AudioFeed

var _bass: float = 0.0
var _mids: float = 0.0
var _level: float = 0.0
var _beat_pulse: float = 0.0
var _bands: PackedFloat32Array = PackedFloat32Array()
var _band_delta: PackedFloat32Array = PackedFloat32Array()
var _spans: PackedFloat32Array = PackedFloat32Array()
var _beat_kick: float = 0.0
var _galaxy_rot: float = 0.0
var _wave: PackedFloat32Array = PackedFloat32Array()
var _wave_dir: int = 0
var _center: Vector2 = Vector2.ZERO
var _touch: Vector2 = Vector2.ZERO
var _count: int = 1
var _style: int = 0
var _draw_active: bool = false
var _draw_alg: int = -1
var _draw_pos: Vector2 = Vector2.ZERO
var _draw_heading: Vector2 = Vector2.RIGHT
var _draw_dir_idx: int = 0
var _draw_angle: float = 0.0
var _curve_sign: float = 1.0
var _fib_hold: int = 0
var _fib_drift: float = 0.0
var _run_travel: float = 0.0
var _straight_every: int = 4
var _straight_half: bool = false
var _straight_want_every: int = 4
var _straight_want_half: bool = false
var _straight_hold: float = 0.0
var _straight_count: int = 0
var _since_beat: float = 0.0
var _half_fired: bool = false
var _cover: PackedInt32Array = PackedInt32Array()
var _cover_decay: float = 0.0
var _recent_pts: PackedVector2Array = PackedVector2Array()
var _recent_next: int = 0
var _draw_step_acc: float = 0.0
var _draw_rate: float = 0.0
var _run_origin: Vector2 = Vector2.ZERO
var _run_dir: Vector2 = Vector2.RIGHT
var _run_idx: int = 0
var _prev_origin: Vector2 = Vector2.ZERO
var _prev_dir: Vector2 = Vector2.ZERO
var _draw_placed: int = 0
var _fifo_head: int = 0
var _fifo_len: int = 0
var _fib_a: int = 0
var _fib_b: int = 1
var _draw_targets: PackedVector2Array = PackedVector2Array()
var _draw_headings: PackedVector2Array = PackedVector2Array()
var _trail_fifo: PackedInt32Array = PackedInt32Array()
var _on_trail: PackedByteArray = PackedByteArray()
var _just_spawned: PackedByteArray = PackedByteArray()
var _reserve_ids: PackedInt32Array = PackedInt32Array()
var _reserve_count: int = 0


func begin_frame(anchor: Vector2, dt: float, positions: PackedVector2Array = PackedVector2Array()) -> void:
	_count = maxi(positions.size(), 1)
	_style = int(settings.audio_style) if settings else 0
	if feed != null:
		feed.poll(dt)
		_bass = feed.bass
		_mids = feed.mids
		_level = feed.level
		_bands = feed.bands
		_band_delta = feed.band_delta
		_wave = feed.waveform
		_beat_pulse = 1.0 if feed.beat_hit else 0.0
	else:
		_bass = 0.0
		_mids = 0.0
		_level = 0.0
		_beat_pulse = 0.0
		_wave = PackedFloat32Array()
	if _bands.size() != AudioFeed.BAND_COUNT or _band_delta.size() != AudioFeed.BAND_COUNT:
		_bands = PackedFloat32Array()
		_bands.resize(AudioFeed.BAND_COUNT)
		_band_delta = PackedFloat32Array()
		_band_delta.resize(AudioFeed.BAND_COUNT)
	_spans.resize(AudioFeed.BAND_COUNT)
	for b in AudioFeed.BAND_COUNT:
		_spans[b] = _span(_bands[b])
	_beat_kick = _beat_pulse * LEARNED_BEAT
	_wave_dir = int(settings.audio_wave_direction) if settings else 0
	_center = bounds.get_center()
	_touch = anchor
	if _style == AppSettings.AudioStyle.DRAW:
		var alg := int(settings.audio_draw_algorithm) if settings else 0
		if not _draw_active or alg != _draw_alg or _draw_targets.size() != _count:
			_draw_alg = alg
			_reset_draw()
			_draw_active = true
		_advance_draw(dt, positions)
	else:
		_draw_active = false


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, _anchor: Vector2, dt: float) -> void:
	var keep := exp(-DRAG_HELD * dt)
	match _style:
		AppSettings.AudioStyle.EQUALIZER:
			_equalizer_all(positions, velocities, dt, keep)
		AppSettings.AudioStyle.EQUALIZER_VERTICAL:
			_equalizer_vertical_all(positions, velocities, dt, keep)
		AppSettings.AudioStyle.EQUALIZER_CIRCULAR:
			_equalizer_circular_all(positions, velocities, dt, keep)
		AppSettings.AudioStyle.WAVEFORM:
			_waveform_all(positions, velocities, dt, keep)
		AppSettings.AudioStyle.DRAW:
			_draw_all(positions, velocities, dt, keep)
		AppSettings.AudioStyle.SWIRL:
			_swirl_all(positions, velocities, dt, keep)
		AppSettings.AudioStyle.GALAXY:
			_galaxy_all(positions, velocities, dt, keep)
		_:
			_pulse_all(positions, velocities, dt, keep)
	_finish_all(positions, velocities, dt)
	integrate_all(positions, velocities, dt)


## Touch warp, Draw head parking, and the speed limit, shared by every style.
func _finish_all(positions: PackedVector2Array, velocities: PackedVector2Array, dt: float) -> void:
	var n := positions.size()
	var max_sq := MAX_SPEED * MAX_SPEED
	var warp := touch_active
	var pull := TOUCH_PULL * dt
	var draw := _style == AppSettings.AudioStyle.DRAW and _on_trail.size() == n
	var head := _visual_head() if draw else Vector2.ZERO
	for i in n:
		var vel := velocities[i]
		if warp:
			var to := _touch - positions[i]
			vel += to * (pull / maxf(to.length(), 48.0))
		if draw and _on_trail[i] == 0:
			positions[i] = head
			vel = Vector2.ZERO
			_just_spawned[i] = 0
		if vel.length_squared() > max_sq:
			vel = vel.normalized() * MAX_SPEED
		velocities[i] = vel


func _pulse_all(positions: PackedVector2Array, velocities: PackedVector2Array, dt: float, keep: float) -> void:
	if _level < 0.02 and _beat_pulse <= 0.0:
		idle_drift_all(positions, velocities, dt, exp(-DRAG_FREE * dt))
		return
	var reach := minf(bounds.size.x, bounds.size.y)
	var rest_r := lerpf(reach * 0.16, reach * 0.4, _span(_bass))
	var spring := PULSE_SPRING * dt
	var push := _bass_rise() * PULSE_KICK + _beat_pulse * BEAT_KICK
	for i in positions.size():
		var offset := positions[i] - _center
		var dist := offset.length()
		if dist < 1.0:
			var seed := float(i) * 2.399963
			offset = Vector2(cos(seed), sin(seed))
			dist = 1.0
		var n := offset / dist
		velocities[i] = (velocities[i] + n * ((rest_r - dist) * spring + push)) * keep


## Resamples the bands into `count` columns with linear interpolation, so bar
## shapes follow the spectrum smoothly instead of stepping every 16th of the screen.
func _resample_bands(count: int, spans: PackedFloat32Array, deltas: PackedFloat32Array) -> void:
	spans.resize(count)
	deltas.resize(count)
	var last := AudioFeed.BAND_COUNT - 1
	for c in count:
		var x := (float(c) + 0.5) / float(count) * float(last)
		var b0 := mini(int(x), last)
		var b1 := mini(b0 + 1, last)
		var f := x - float(b0)
		spans[c] = lerpf(_spans[b0], _spans[b1], f)
		deltas[c] = lerpf(_band_delta[b0], _band_delta[b1], f)


func _equalizer_all(positions: PackedVector2Array, velocities: PackedVector2Array, dt: float, keep: float) -> void:
	var cols := EQ_COLUMNS
	var spans := PackedFloat32Array()
	var deltas := PackedFloat32Array()
	_resample_bands(cols, spans, deltas)
	var rows := maxi(1, ceili(float(_count) / float(cols)))
	var col_w := bounds.size.x / float(cols)
	var bar_w := col_w * BAR_FILL
	var left := bounds.position.x
	var bottom := bounds.end.y
	var top := bounds.position.y
	var reach := bounds.size.y * BAR_REACH
	var spring := COL_SPRING * dt
	var beat := Vector2(0.0, -_beat_kick)
	for i in positions.size():
		var col := i % cols
		@warning_ignore("integer_division")
		var row := i / cols
		var spread := fmod(float(i) * 0.61803398875, 1.0) - 0.5
		var target := Vector2(
			left + (float(col) + 0.5) * col_w + spread * bar_w,
			clampf(bottom - (float(row) + 0.5) / float(rows) * spans[col] * reach, top, bottom)
		)
		var vel := velocities[i] + (target - positions[i]) * spring
		vel += Vector2(spread * 0.9, -1.0) * (deltas[col] * COL_KICK) + beat
		velocities[i] = vel * keep


func _equalizer_vertical_all(positions: PackedVector2Array, velocities: PackedVector2Array, dt: float, keep: float) -> void:
	var bars := EQ_COLUMNS
	var spans := PackedFloat32Array()
	var deltas := PackedFloat32Array()
	_resample_bands(bars, spans, deltas)
	var depths := maxi(1, ceili(float(_count) / float(bars)))
	var row_h := bounds.size.y / float(bars)
	var bar_h := row_h * BAR_FILL
	var left := bounds.position.x
	var bottom := bounds.end.y
	var reach := bounds.size.x * BAR_REACH
	var spring := COL_SPRING * dt
	var beat := Vector2(_beat_kick, 0.0)
	for i in positions.size():
		var band := i % bars
		@warning_ignore("integer_division")
		var depth := i / bars
		var spread := fmod(float(i) * 0.61803398875, 1.0) - 0.5
		var target := Vector2(
			left + (float(depth) + 0.5) / float(depths) * spans[band] * reach,
			bottom - (float(band) + 0.5) * row_h + spread * bar_h
		)
		var vel := velocities[i] + (target - positions[i]) * spring
		vel += Vector2(1.0, spread * 0.5) * (deltas[band] * COL_KICK) + beat
		velocities[i] = vel * keep


func _equalizer_circular_all(positions: PackedVector2Array, velocities: PackedVector2Array, dt: float, keep: float) -> void:
	var rays := EQ_RAYS
	var spans := PackedFloat32Array()
	var deltas := PackedFloat32Array()
	_resample_bands(rays, spans, deltas)
	var layers := maxi(1, ceili(float(_count) / float(rays)))
	var reach := minf(bounds.size.x, bounds.size.y)
	var inner := reach * 0.08
	var spring := COL_SPRING * dt
	var ray_arc := TAU / float(rays) * BAR_FILL
	var lo := bounds.position
	var hi := bounds.end
	for i in positions.size():
		var ray := i % rays
		@warning_ignore("integer_division")
		var layer := i / rays
		var spread := fmod(float(i) * 0.61803398875, 1.0) - 0.5
		var angle := (float(ray) + 0.5) / float(rays) * TAU - PI * 0.5 + spread * ray_arc
		var dir := Vector2(cos(angle), sin(angle))
		var outer := maxf(reach * 0.46 * spans[ray], inner)
		var radius := lerpf(inner, outer, (float(layer) + 0.5) / float(layers))
		var target := (_center + dir * radius).clamp(lo, hi)
		var vel := velocities[i] + (target - positions[i]) * spring
		vel += dir * (deltas[ray] * COL_KICK + _beat_kick)
		velocities[i] = vel * keep


func _waveform_all(positions: PackedVector2Array, velocities: PackedVector2Array, dt: float, keep: float) -> void:
	var points := _wave.size()
	var last := maxi(points - 1, 1)
	var n := positions.size()
	var vertical := _wave_dir == AppSettings.WaveDirection.VERTICAL
	var spring := WAVE_SPRING * dt
	var beat := Vector2(_beat_kick, 0.0) if vertical else Vector2(0.0, -_beat_kick)
	var quiet := _level < 0.02
	# The ribbon thickens with loudness.
	var thickness := 6.0 + 26.0 * _level
	var amp_x := bounds.size.x * 0.42
	var amp_y := bounds.size.y * 0.42
	for i in n:
		# Spread particles evenly along the line and sample the waveform between points.
		var along := (float(i) + 0.5) / float(n)
		var sample := 0.0
		var slope := 0.0
		if points > 1:
			var x := along * float(last)
			var k0 := mini(int(x), last - 1)
			var f := x - float(k0)
			sample = lerpf(_wave[k0], _wave[k0 + 1], f)
			slope = _wave[k0 + 1] - _wave[k0]
		var ribbon := (fmod(float(i) * 0.61803398875, 1.0) - 0.5) * thickness
		var target: Vector2
		var kick: Vector2
		if vertical:
			target = Vector2(_center.x + sample * amp_x + ribbon, bounds.position.y + along * bounds.size.y)
			kick = Vector2(slope, 0.0)
		else:
			target = Vector2(bounds.position.x + along * bounds.size.x, _center.y - sample * amp_y + ribbon)
			kick = Vector2(0.0, -slope)
		target = target.clamp(bounds.position, bounds.end)
		var pos := positions[i]
		var vel := velocities[i] + (target - pos) * spring + kick * WAVE_KICK + beat
		if quiet:
			vel = apply_idle_drift(i, vel, pos, dt)
		velocities[i] = vel * keep


func _swirl_all(positions: PackedVector2Array, velocities: PackedVector2Array, dt: float, keep: float) -> void:
	var bands := AudioFeed.BAND_COUNT
	var spin := (480.0 + _span(_mids) * SWIRL_SPIN) * dt
	var spring := SWIRL_RADIAL * dt
	var reach := minf(bounds.size.x, bounds.size.y)
	var r_min := reach * 0.1
	var r_max := reach * 0.42
	var quiet := _level < 0.02
	for i in positions.size():
		var pos := positions[i]
		var offset := pos - _center
		var dist := offset.length()
		if dist < 1.0:
			var seed := float(i) * 2.399963
			offset = Vector2(cos(seed), sin(seed)) * 8.0
			dist = 8.0
		var radial := offset / dist
		var sector := clampi(int((atan2(offset.y, offset.x) + PI) / TAU * float(bands)), 0, bands - 1)
		var target_r := lerpf(r_min, r_max, _spans[sector])
		var vel := velocities[i] + Vector2(-radial.y, radial.x) * spin
		vel += radial * ((target_r - dist) * spring + _band_delta[sector] * SWIRL_FLING + _beat_kick)
		if quiet:
			vel = apply_idle_drift(i, vel, pos, dt)
		velocities[i] = vel * keep


## Spiral galaxy: mids spin it, bass widens the arms and core, and the spectrum
## runs along each arm (inner = bass, outer = treble), bulging where it is loud.
func _galaxy_all(positions: PackedVector2Array, velocities: PackedVector2Array, dt: float, keep: float) -> void:
	var arms := clampi(settings.audio_galaxy_arms if settings else 3, 2, 4)
	_galaxy_rot = fmod(_galaxy_rot + (GALAXY_SPIN_BASE + GALAXY_SPIN_MIDS * _span(_mids)) * dt, TAU)
	var spans := PackedFloat32Array()
	var deltas := PackedFloat32Array()
	_resample_bands(GALAXY_SEGMENTS, spans, deltas)
	var reach := minf(bounds.size.x, bounds.size.y) * 0.47
	var bass := _span(_bass)
	var core_r := reach * (0.05 + 0.13 * bass)
	var width := reach * (0.025 + 0.065 * bass)
	var arm_step := TAU / float(arms)
	var spring := COL_SPRING * dt
	var lo := bounds.position
	var hi := bounds.end
	for i in positions.size():
		var fi := float(i)
		var h1 := fmod(fi * 0.61803398875, 1.0)
		var h2 := fmod(fi * 0.75487766625, 1.0)
		var target: Vector2
		var dir: Vector2
		var kick := 0.0
		if h1 < GALAXY_CORE:
			var angle := fmod(fi * 0.56984029, 1.0) * TAU + _galaxy_rot * 1.6
			dir = Vector2(cos(angle), sin(angle))
			target = _center + dir * (core_r * sqrt(h2))
		else:
			var u := (h1 - GALAXY_CORE) / (1.0 - GALAXY_CORE)
			var seg := mini(int(u * float(GALAXY_SEGMENTS)), GALAXY_SEGMENTS - 1)
			var angle := _galaxy_rot + float(i % arms) * arm_step + u * GALAXY_WIND
			dir = Vector2(cos(angle), sin(angle))
			var radius := reach * (0.1 + 0.9 * u) * (0.82 + 0.3 * spans[seg])
			var spread := (h2 - 0.5) * width * (0.5 + u)
			target = _center + dir * radius + Vector2(-dir.y, dir.x) * spread
			kick = deltas[seg] * COL_KICK * 0.5
		target = target.clamp(lo, hi)
		var vel := velocities[i] + (target - positions[i]) * spring + dir * (kick + _beat_kick)
		velocities[i] = vel * keep


func _draw_all(positions: PackedVector2Array, velocities: PackedVector2Array, dt: float, keep: float) -> void:
	var n := positions.size()
	if _on_trail.size() != n:
		return
	var spring := DRAW_SPRING * dt
	var beat := _beat_pulse * DRAW_BEAT
	for i in n:
		if _on_trail[i] == 0:
			continue
		var vel := velocities[i] + (_draw_targets[i] - positions[i]) * spring
		if beat > 0.0:
			var angle := float(i) * 2.399963
			vel += Vector2(cos(angle), sin(angle)) * beat
		velocities[i] = vel * keep


func _span(energy: float) -> float:
	# Bands arrive dB-scaled and auto-gained; the power curve restores contrast between bars.
	return clampf(pow(clampf(energy, 0.0, 1.0), 1.8), 0.03, 1.0)


func _advance_draw(dt: float, positions: PackedVector2Array) -> void:
	var confidence := feed.tempo_confidence if feed != null else 0.0
	var beats := feed.bps if feed != null else 1.0
	var loud := 0.0
	if feed != null:
		loud = clampf((feed.level - 0.04) / 0.5, 0.0, 1.0)
	var target := 0.0
	if loud > 0.0:
		var cruise := loud * (180.0 + confidence * maxf(beats, 1.0) * 24.0)
		target = cruise * (1.0 + loud * loud * 6.0)
	var blend := 1.0 - exp(-dt / 0.18)
	_draw_rate = lerpf(_draw_rate, target, blend)
	if _draw_rate < 1.0 and target <= 0.0:
		_draw_rate = 0.0
		return
	_draw_step_acc += dt * _draw_rate
	var steps := mini(int(_draw_step_acc), 32)
	_draw_step_acc -= float(steps)
	var curve_turn := false
	var straight_turn := false
	if feed != null:
		if feed.tempo_confidence >= 0.45:
			curve_turn = feed.division_hit
		else:
			curve_turn = feed.beat_hit
		straight_turn = _straight_turn_due(dt)
	_decay_cover(dt)
	for _step in steps:
		_draw_step(curve_turn if _is_curve() else straight_turn, positions)
		curve_turn = false
		straight_turn = false


func _draw_step(on_turn: bool, positions: PackedVector2Array) -> void:
	var step := _draw_step_length()
	var heading: Vector2
	if _is_curve():
		if _draw_alg == AppSettings.DrawAlgorithm.FIBONACCI_TIGHT:
			step *= 0.7
		_bend_curve(on_turn)
		_apply_cover_steer()
		heading = _steer_curve(Vector2.RIGHT.rotated(_draw_angle), step)
		_draw_angle = heading.angle()
		_note_heading(heading)
	else:
		if on_turn:
			_bend_straight()
		var chosen := _draw_dir_idx
		var dir := _draw_dir(chosen)
		var inward := _inward_from_nearest_edge()
		var leaving := not _step_inside(chosen, step)
		var grazing := dir.dot(inward) < 0.25 and _near_wall(step * 8.0)
		if leaving or grazing:
			chosen = _cut_inward(step)
			if not _step_inside(chosen, step):
				chosen = _escape_corner(step)
		else:
			var folded := _avoid_fold(chosen)
			if _step_inside(folded, step):
				chosen = folded
		_commit_run(chosen)
		_draw_dir_idx = chosen
		heading = _draw_dir(chosen)
		_draw_angle = heading.angle()
	var direction := heading * step
	var next := _draw_pos + direction
	if not _draw_inside(next):
		var inset := bounds.grow(-1.0)
		next.x = clampf(next.x, inset.position.x, inset.end.x)
		next.y = clampf(next.y, inset.position.y, inset.end.y)
		if next.distance_squared_to(_draw_pos) < 0.25:
			var toward := bounds.get_center() - next
			if toward.length_squared() > 1.0:
				var pushed := next + toward.normalized() * step
				if _draw_inside(pushed):
					next = pushed
					var out := _nearest_dir(toward)
					_commit_run(out)
					_draw_dir_idx = out
					heading = _draw_dir(out)
					_draw_angle = heading.angle()
					direction = heading * step
	_draw_pos = next
	_draw_heading = direction
	_run_travel += step
	_deposit_trail(positions)


func _is_curve() -> bool:
	return (
		_draw_alg == AppSettings.DrawAlgorithm.FIBONACCI
		or _draw_alg == AppSettings.DrawAlgorithm.FIBONACCI_TIGHT
		or _draw_alg == AppSettings.DrawAlgorithm.COIL
	)


func _bend_straight() -> void:
	var amp_v := feed.amp if feed != null else 0.0
	var sign := 1 if amp_v > 0.0 else -1
	if _draw_alg == AppSettings.DrawAlgorithm.BASIC_TIGHT:
		var intense := _draw_loud() >= 0.55
		if not intense and _run_travel < minf(bounds.size.x, bounds.size.y) / 8.0:
			return
		_draw_dir_idx = posmod(_draw_dir_idx + sign, 8)
	else:
		_draw_dir_idx = posmod(_draw_dir_idx + sign * 2, 8)


func _draw_loud() -> float:
	if feed == null:
		return 0.0
	return clampf((feed.level - 0.04) / 0.5, 0.0, 1.0)


func _straight_turn_due(dt: float) -> bool:
	if feed == null:
		return false
	if feed.tempo_confidence < 0.45:
		return feed.beat_hit
	_update_straight_division(dt)
	var period := 1.0 / maxf(feed.bps, 0.5)
	if feed.beat_hit:
		_straight_count += 1
		_since_beat = 0.0
		_half_fired = false
		return _straight_count % maxi(_straight_every, 1) == 0
	_since_beat += dt
	if _straight_half and not _half_fired and _since_beat >= period * 0.5:
		_half_fired = true
		return true
	return false


func _update_straight_division(dt: float) -> void:
	var loud := _draw_loud()
	var want := 4
	var half := false
	if loud >= 0.55:
		want = 2
	if loud >= 0.85:
		want = 1
	if want == 1 and feed != null and feed.bps > 0.0:
		var travel := _draw_rate * _draw_step_length() * (1.0 / feed.bps)
		if travel > minf(bounds.size.x, bounds.size.y) / 6.0:
			half = true
	if want != _straight_want_every or half != _straight_want_half:
		_straight_want_every = want
		_straight_want_half = half
		_straight_hold = 0.0
	_straight_hold += dt
	if _straight_hold >= 0.28:
		_straight_every = want
		_straight_half = half


func _apply_cover_steer() -> void:
	var aim := _cover_aim()
	if aim.length_squared() < 0.01:
		return
	var side := minf(bounds.size.x, bounds.size.y)
	var trapped := clampf(1.0 - _recent_span() / (side * 0.45), 0.0, 1.0)
	var blend := lerpf(0.05, 0.4, trapped)
	_draw_angle += wrapf(aim.angle() - _draw_angle, -PI, PI) * blend


func _remember_cover(point: Vector2) -> void:
	_mark_cover(point)
	if _recent_pts.size() < 36:
		_recent_pts.append(point)
		return
	_recent_pts[_recent_next] = point
	_recent_next = (_recent_next + 1) % 36


func _mark_cover(point: Vector2) -> void:
	if _cover.size() != 48:
		_cover.resize(48)
		_cover.fill(0)
	var cols := 6
	var rows := 8
	var u := clampf((point.x - bounds.position.x) / maxf(bounds.size.x, 1.0), 0.0, 0.999)
	var v := clampf((point.y - bounds.position.y) / maxf(bounds.size.y, 1.0), 0.0, 0.999)
	var cell := int(v * float(rows)) * cols + int(u * float(cols))
	_cover[cell] = _cover[cell] + 1


func _cover_aim() -> Vector2:
	if _cover.size() != 48:
		return Vector2.ZERO
	var cols := 6
	var rows := 8
	var cell_w := bounds.size.x / float(cols)
	var cell_h := bounds.size.y / float(rows)
	var best_n := 0x7fffffff
	var best_d := 1.0e20
	var best := Vector2.ZERO
	var found := false
	for i in _cover.size():
		var center := bounds.position + Vector2((float(i % cols) + 0.5) * cell_w, (float(i / cols) + 0.5) * cell_h)
		var dist := _draw_pos.distance_squared_to(center)
		var n := _cover[i]
		if n < best_n or (n == best_n and dist < best_d):
			best_n = n
			best_d = dist
			best = center
			found = true
	if not found:
		return Vector2.ZERO
	var aim := best - _draw_pos
	if aim.length_squared() < 4.0:
		return Vector2.ZERO
	return aim.normalized()


func _recent_span() -> float:
	if _recent_pts.size() < 8:
		return minf(bounds.size.x, bounds.size.y)
	var lo := _recent_pts[0]
	var hi := _recent_pts[0]
	for point in _recent_pts:
		lo = lo.min(point)
		hi = hi.max(point)
	return maxf(hi.x - lo.x, hi.y - lo.y)


func _decay_cover(dt: float) -> void:
	if _cover.is_empty():
		return
	_cover_decay += dt
	if _cover_decay < 0.35:
		return
	_cover_decay = 0.0
	for i in _cover.size():
		if _cover[i] > 0:
			_cover[i] -= 1


func _bend_curve(on_turn: bool) -> void:
	if _draw_alg == AppSettings.DrawAlgorithm.COIL:
		if on_turn:
			_curve_sign = -_curve_sign
		var loud := 0.0
		if feed != null:
			loud = clampf((feed.level - 0.04) / 0.5, 0.0, 1.0)
		_draw_angle += _curve_sign * lerpf(0.03, 0.18, loud)
		return
	var tight := _draw_alg == AppSettings.DrawAlgorithm.FIBONACCI_TIGHT
	if _fib_hold <= 0:
		var n := _next_fib()
		if n == 0:
			_curve_sign = -_curve_sign
		_fib_hold = 8 if tight else 16
		var unit := 0.11 if tight else 0.04
		_fib_drift = _curve_sign * float(n) * unit
	_fib_hold -= 1
	_draw_angle += _fib_drift
	if on_turn:
		var extra := 0.55 if tight else 0.28
		_draw_angle += _curve_sign * extra


func _steer_curve(heading: Vector2, step: float) -> Vector2:
	var h := heading.normalized() if heading.length_squared() > 0.0001 else Vector2.RIGHT
	var limit := _fold_limit()
	var leaving := not _draw_inside(_draw_pos + h * step)
	var inward := _inward_from_nearest_edge()
	var grazing := h.dot(inward) < 0.2 and _near_wall(step * 4.0)
	if not leaving and not grazing and not _heading_folds(h, limit):
		return h
	_draw_dir_idx = _nearest_dir(h)
	var chosen := _draw_dir_idx
	if leaving or grazing:
		chosen = _heading_off_wall(step)
	if not _step_inside(chosen, step):
		chosen = _escape_corner(step)
	if _heading_folds(_draw_dir(chosen), limit):
		chosen = _avoid_fold(chosen)
	_draw_dir_idx = chosen
	return _draw_dir(chosen)


func _note_heading(heading: Vector2) -> void:
	var h := heading.normalized() if heading.length_squared() > 0.0001 else Vector2.RIGHT
	if _run_dir.length_squared() < 0.0001 or h.dot(_run_dir.normalized()) < 0.45:
		_prev_origin = _run_origin
		_prev_dir = _run_dir
		_run_origin = _draw_pos
		_run_dir = h
		_run_idx = _nearest_dir(h)
		_run_travel = 0.0


func _fold_limit() -> float:
	var side := minf(bounds.size.x, bounds.size.y)
	if _draw_alg == AppSettings.DrawAlgorithm.FIBONACCI_TIGHT or _draw_alg == AppSettings.DrawAlgorithm.COIL:
		return side / 40.0
	return side / 18.0


func _turn_delta(prev: int, nxt: int) -> int:
	return posmod(nxt - prev + 4, 8) - 4


func _commit_run(idx: int) -> void:
	if idx == _run_idx:
		return
	_prev_origin = _run_origin
	_prev_dir = _run_dir
	_run_origin = _draw_pos
	_run_idx = idx
	_run_dir = _draw_dir(idx)
	_run_travel = 0.0


func _avoid_fold(proposed: int) -> int:
	var limit := _fold_limit()
	if not _heading_folds(_draw_dir(proposed), limit):
		return proposed
	var best := _run_idx
	var best_away := _away_score(_draw_dir(best))
	var step := _draw_step_length()
	for sign in [-1, 1]:
		var idx := posmod(_run_idx + sign, 8)
		var dir := _draw_dir(idx)
		if _heading_folds(dir, limit):
			continue
		if not _draw_inside(_draw_pos + dir * step):
			continue
		var away := _away_score(dir)
		if away > best_away:
			best_away = away
			best = idx
	return best


func _heading_folds(heading: Vector2, limit: float) -> bool:
	if _folds_into(heading, _prev_dir, _prev_origin, limit):
		return true
	return _folds_into(heading, _run_dir, _run_origin, limit)


func _folds_into(heading: Vector2, axis: Vector2, origin: Vector2, limit: float) -> bool:
	if axis.length_squared() < 0.0001:
		return false
	var axis_n := axis.normalized()
	if heading.dot(axis_n) >= -0.85:
		return false
	return _perp_to(origin, axis_n) < limit


func _perp_to(origin: Vector2, axis_n: Vector2) -> float:
	var rel := _draw_pos - origin
	return (rel - axis_n * rel.dot(axis_n)).length()


func _away_score(heading: Vector2) -> float:
	return _away_from(heading, _prev_dir, _prev_origin) + _away_from(heading, _run_dir, _run_origin)


func _away_from(heading: Vector2, axis: Vector2, origin: Vector2) -> float:
	if axis.length_squared() < 0.0001:
		return 0.0
	var axis_n := axis.normalized()
	var rel := _draw_pos - origin
	var perp := rel - axis_n * rel.dot(axis_n)
	if perp.length_squared() < 1.0:
		return absf(heading.cross(axis_n))
	return heading.dot(perp.normalized())


func _visual_head() -> Vector2:
	var heading := _draw_heading
	if heading.length_squared() < 0.0001:
		return _draw_pos
	var along := clampf(_draw_step_acc, 0.0, 1.0) * _draw_step_length()
	return _draw_pos + heading.normalized() * along


func _next_fib() -> int:
	var value := _fib_a
	var nxt := (_fib_a + _fib_b) % 8
	_fib_a = _fib_b
	_fib_b = nxt
	return value


func _draw_dir(idx: int) -> Vector2:
	var raw := Vector2.RIGHT
	match posmod(idx, 8):
		0:
			raw = Vector2(1, 0)
		1:
			raw = Vector2(1, 1)
		2:
			raw = Vector2(0, 1)
		3:
			raw = Vector2(-1, 1)
		4:
			raw = Vector2(-1, 0)
		5:
			raw = Vector2(-1, -1)
		6:
			raw = Vector2(0, -1)
		_:
			raw = Vector2(1, -1)
	return raw.normalized()


func _draw_step_length() -> float:
	return minf(bounds.size.x, bounds.size.y) / 320.0


func _draw_inside(point: Vector2) -> bool:
	return bounds.grow(-1.0).has_point(point)


func _step_inside(idx: int, step: float) -> bool:
	return _draw_inside(_draw_pos + _draw_dir(idx) * step)


func _nearest_dir(dir: Vector2) -> int:
	var best := 0
	var best_dot := -2.0
	var n := dir.normalized() if dir.length_squared() > 0.0001 else Vector2.UP
	for d in 8:
		var score := _draw_dir(d).dot(n)
		if score > best_dot:
			best_dot = score
			best = d
	return best


func _cut_inward(step: float) -> int:
	var inward := _inward_from_nearest_edge()
	var to_center := bounds.get_center() - _draw_pos
	if to_center.length_squared() > 1.0:
		inward = (inward + to_center.normalized()).normalized()
	var best := -1
	var best_score := 0.2
	for d in 8:
		if not _step_inside(d, step):
			continue
		var dir := _draw_dir(d)
		if _heading_folds(dir, _fold_limit()):
			continue
		var score := dir.dot(inward)
		if score > best_score:
			best_score = score
			best = d
	if best >= 0:
		return best
	return _escape_corner(step)


func _escape_corner(step: float) -> int:
	var toward := bounds.get_center() - _draw_pos
	if toward.length_squared() < 1.0:
		toward = Vector2.UP
	else:
		toward = toward.normalized()
	var best := _nearest_dir(toward)
	var best_score := -2.0
	var found := false
	for d in 8:
		if not _step_inside(d, step):
			continue
		var score := _draw_dir(d).dot(toward)
		if score > best_score:
			best_score = score
			best = d
			found = true
	if found:
		return best
	return _nearest_dir(toward)


func _heading_off_wall(step: float) -> int:
	var heading := _draw_dir(_draw_dir_idx)
	var inward := _inward_from_nearest_edge()
	var leaving := not _draw_inside(_draw_pos + heading * step)
	var grazing := heading.dot(inward) < 0.2 and _near_wall(step * 4.0)
	if not leaving and not grazing:
		return _draw_dir_idx
	var best_quick := -1
	var best_quick_score := -2.0
	var best_any := -1
	var best_any_score := -2.0
	for d in 8:
		var dir := _draw_dir(d)
		if not _draw_inside(_draw_pos + dir * step):
			continue
		var score := dir.dot(inward)
		if score > best_any_score:
			best_any_score = score
			best_any = d
		if absi(_turn_delta(_draw_dir_idx, d)) <= 2 and score > best_quick_score:
			best_quick_score = score
			best_quick = d
	if best_quick >= 0:
		return best_quick
	if best_any >= 0:
		return best_any
	var safest := _draw_dir_idx
	var safest_dist := -1.0
	for d in 8:
		var dir := _draw_dir(d)
		var dist := _inset_distance(_draw_pos + dir * step)
		if dist > safest_dist:
			safest_dist = dist
			safest = d
	return safest


func _inward_from_nearest_edge() -> Vector2:
	var left := _draw_pos.x - bounds.position.x
	var right := bounds.end.x - _draw_pos.x
	var top := _draw_pos.y - bounds.position.y
	var bottom := bounds.end.y - _draw_pos.y
	if minf(left, right) <= minf(top, bottom):
		return Vector2.RIGHT if left < right else Vector2.LEFT
	return Vector2.DOWN if top < bottom else Vector2.UP


func _near_wall(margin: float) -> bool:
	return (
		_draw_pos.x < bounds.position.x + margin
		or _draw_pos.x > bounds.end.x - margin
		or _draw_pos.y < bounds.position.y + margin
		or _draw_pos.y > bounds.end.y - margin
	)


func _inset_distance(point: Vector2) -> float:
	return minf(
		minf(point.x - bounds.position.x, bounds.end.x - point.x),
		minf(point.y - bounds.position.y, bounds.end.y - point.y)
	)


func _reset_draw() -> void:
	_draw_placed = 0
	_fifo_head = 0
	_fifo_len = 0
	_fib_a = 0
	_fib_b = 1
	_draw_dir_idx = 0
	_draw_angle = 0.0
	_curve_sign = 1.0
	_fib_hold = 0
	_fib_drift = 0.0
	_run_travel = 0.0
	_straight_every = 4
	_straight_half = false
	_straight_want_every = 4
	_straight_want_half = false
	_straight_hold = 0.0
	_straight_count = 0
	_since_beat = 0.0
	_half_fired = false
	_cover_decay = 0.0
	_recent_pts = PackedVector2Array()
	_recent_next = 0
	_cover.resize(48)
	_cover.fill(0)
	_draw_step_acc = 0.0
	_draw_rate = 0.0
	_draw_targets.resize(_count)
	_draw_headings.resize(_count)
	_trail_fifo.resize(_count)
	_on_trail.resize(_count)
	_just_spawned.resize(_count)
	_reserve_ids.resize(_count)
	_on_trail.fill(0)
	_just_spawned.fill(0)
	_reserve_count = _count
	for i in _count:
		_reserve_ids[i] = i
	var margin := _draw_step_length() * 2.0
	var lo := bounds.position + Vector2(margin, margin)
	var hi := bounds.end - Vector2(margin, margin)
	if hi.x <= lo.x or hi.y <= lo.y:
		_draw_pos = bounds.get_center()
	else:
		_draw_pos = Vector2(randf_range(lo.x, hi.x), randf_range(lo.y, hi.y))
	_draw_heading = Vector2(_draw_step_length(), 0.0)
	_run_origin = _draw_pos
	_run_dir = Vector2.RIGHT
	_run_idx = 0
	_prev_origin = _draw_pos
	_prev_dir = Vector2.ZERO
	for i in _count:
		_draw_targets[i] = _draw_pos


func _deposit_trail(positions: PackedVector2Array) -> void:
	var keep := mini(HEAD_RESERVE, _count)
	if _reserve_count <= keep and _oldest_trail() < 0:
		return
	if _reserve_count <= keep:
		_refill_reserve(positions)
	if _reserve_count <= keep:
		return
	var idx := _reserve_ids[0]
	_reserve_count -= 1
	_reserve_ids[0] = _reserve_ids[_reserve_count]
	_on_trail[idx] = 1
	_draw_targets[idx] = _draw_pos
	_draw_headings[idx] = _draw_heading
	_trail_fifo[(_fifo_head + _fifo_len) % _count] = idx
	_fifo_len += 1
	if _is_curve():
		_remember_cover(_draw_pos)


func _refill_reserve(positions: PackedVector2Array) -> void:
	var idx := _oldest_trail()
	if idx < 0:
		return
	_fifo_head = (_fifo_head + 1) % _count
	_fifo_len -= 1
	_on_trail[idx] = 0
	_draw_targets[idx] = _draw_pos
	_draw_headings[idx] = _draw_heading
	if idx < positions.size():
		positions[idx] = _draw_pos
	if idx < _just_spawned.size():
		_just_spawned[idx] = 1
	_reserve_ids[_reserve_count] = idx
	_reserve_count += 1


## Trail entries leave in the order they were laid, so the oldest is the FIFO head.
func _oldest_trail() -> int:
	if _fifo_len <= 0:
		return -1
	return _trail_fifo[_fifo_head]


## 0 for particles parked at the draw head, 1 for particles on the trail.
func trail_flags() -> PackedByteArray:
	return _on_trail


## Particles parked at the draw head (exactly the unused reserve).
func head_ids() -> PackedInt32Array:
	return _reserve_ids.slice(0, _reserve_count)


func _bass_rise() -> float:
	var total := 0.0
	var n := mini(3, _band_delta.size())
	if n == 0:
		return 0.0
	for i in n:
		total += _band_delta[i]
	return total / float(n)
