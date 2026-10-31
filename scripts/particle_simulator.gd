class_name ParticleSimulator
extends Node
## CPU particle simulation + MultiMesh rendering with dual-viewport trails.

signal settings_applied
signal auto_mode_changed(settings: AppSettings)

const MAX_DT := 1.0 / 30.0
const GLOW_SIZE_SCALE := 1.4
## 1.0 keeps trails at the window resolution. 0.5 quarters fill and bandwidth.
const TRAIL_RESOLUTION_SCALE := 1.0
## 8-float 2D transform (two padding slots) plus RGBA. See MultiMesh.set_buffer.
const _INSTANCE_STRIDE := 12
const _ArtBlackHole := preload("res://scripts/art_modes/black_hole.gd")
const _ArtSink := preload("res://scripts/art_modes/sink.gd")
const _ArtBeam := preload("res://scripts/art_modes/beam.gd")
const _ArtOrbit := preload("res://scripts/art_modes/orbit.gd")
const _ArtRipple := preload("res://scripts/art_modes/ripple.gd")
const _ArtMagnet := preload("res://scripts/art_modes/magnet.gd")
const _ArtAudio := preload("res://scripts/art_modes/audio.gd")
const _ArtFluid := preload("res://scripts/art_modes/fluid.gd")
const _ArtFireworks := preload("res://scripts/art_modes/fireworks.gd")
const _TouchSynth := preload("res://scripts/audio/touch_synth.gd")

@export var trail_viewport_a_path: NodePath
@export var trail_viewport_b_path: NodePath
@export var particles_root_a_path: NodePath
@export var particles_root_b_path: NodePath
@export var composite_rect_path: NodePath
@export var lightning_layer_path: NodePath

var settings: AppSettings

var positions: PackedVector2Array = PackedVector2Array()
var velocities: PackedVector2Array = PackedVector2Array()

var _modes: Dictionary = {}
var _current_mode: ArtModeBase
var _auto: AutoControl = AutoControl.new()

var _viewport_size: Vector2 = Vector2(1080, 1920)
var _ping: bool = false

var _mm_a: MultiMeshInstance2D
var _mm_b: MultiMeshInstance2D
var _mm_head: MultiMeshInstance2D
var _trail_a: SubViewport
var _trail_b: SubViewport
var _composite: ColorRect
var _composite_mat: ShaderMaterial
var _lightning: Node2D

var _audio_feed: AudioFeed
var _touch_synth: TouchSynth
var _style_hold: float = 0.0
var _draw_head_lit: bool = false
var _bolt_segments: Array = [] # [{from, to, life}]
var _glow_texture: GradientTexture2D
var _glow_material: CanvasItemMaterial
var _instance_buffer: PackedFloat32Array = PackedFloat32Array()
## Palette colors per particle; rebuilt only when the palette or count changes.
var _base_colors: PackedColorArray = PackedColorArray()
var _colors_key: Array = []
var _sparkle_hues: PackedColorArray = PackedColorArray()

var touch: TouchInput


func _ready() -> void:
    _trail_a = get_node(trail_viewport_a_path) as SubViewport
    _trail_b = get_node(trail_viewport_b_path) as SubViewport
    _composite = get_node(composite_rect_path) as ColorRect
    _lightning = get_node(lightning_layer_path) as Node2D

    _glow_texture = _make_glow_texture()
    _glow_material = CanvasItemMaterial.new()
    _glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

    _mm_a = _ensure_multimesh(get_node(particles_root_a_path))
    _mm_b = _ensure_multimesh(get_node(particles_root_b_path))
    _mm_head = _ensure_head_overlay()

    _composite_mat = _composite.material as ShaderMaterial
    if _composite_mat == null:
        _composite_mat = ShaderMaterial.new()
        _composite_mat.shader = load("res://shaders/composite.gdshader")
        _composite.material = _composite_mat

    _modes = {
        AppSettings.ArtMode.WAVE: ArtWave.new(),
        AppSettings.ArtMode.PARTICLE: ArtParticle.new(),
        AppSettings.ArtMode.GRAVITY: ArtGravity.new(),
        AppSettings.ArtMode.LIGHTNING: ArtLightning.new(),
        AppSettings.ArtMode.LINEAR: ArtLinear.new(),
        AppSettings.ArtMode.BLACK_HOLE: _ArtBlackHole.new(),
        AppSettings.ArtMode.SINK: _ArtSink.new(),
        AppSettings.ArtMode.BEAM: _ArtBeam.new(),
        AppSettings.ArtMode.ORBIT: _ArtOrbit.new(),
        AppSettings.ArtMode.RIPPLE: _ArtRipple.new(),
        AppSettings.ArtMode.MAGNET: _ArtMagnet.new(),
        AppSettings.ArtMode.AUDIO: _ArtAudio.new(),
        AppSettings.ArtMode.FLUID: _ArtFluid.new(),
        AppSettings.ArtMode.FIREWORKS: _ArtFireworks.new(),
    }
    _audio_feed = AudioFeed.new()
    _audio_feed.name = "AudioFeed"
    add_child(_audio_feed)
    (_modes[AppSettings.ArtMode.AUDIO] as ArtAudio).feed = _audio_feed
    _touch_synth = _TouchSynth.new()
    _touch_synth.name = "TouchSynth"
    add_child(_touch_synth)
    var lightning := _modes[AppSettings.ArtMode.LIGHTNING] as ArtLightning
    lightning.discharged.connect(_on_lightning_discharged)

    _viewport_size = get_viewport().get_visible_rect().size
    get_viewport().size_changed.connect(_on_viewport_resized)
    _configure_viewports()
    _auto.setup(_viewport_size)

    if settings == null:
        settings = AppSettings.new()
        settings.load_from_disk()

    apply_settings(settings)


func _sync_audio_feed() -> void:
    if _audio_feed == null or settings == null:
        return
    if settings.art_mode == AppSettings.ArtMode.AUDIO:
        _audio_feed.apply_audio_settings(settings)
        _audio_feed.start()
    else:
        _audio_feed.stop()


func set_audio_suspended(suspended: bool) -> void:
    if _audio_feed != null:
        _audio_feed.set_suspended(suspended)


func bind_touch(touch_input: TouchInput) -> void:
    touch = touch_input


func apply_settings(s: AppSettings) -> void:
    settings = s
    for mode in _modes.values():
        (mode as ArtModeBase).bind_settings(s)
        (mode as ArtModeBase).setup(_viewport_size)
    _current_mode = _modes[s.art_mode]
    _auto.enabled = s.auto_control
    _auto.setup(_viewport_size)

    if positions.size() != s.particle_count:
        _resize_particles(s.particle_count)
    elif _colors_key != _color_key():
        _rebuild_instance_buffer()

    _update_glow_visuals()
    _update_particle_scale()
    _update_composite_uniforms()
    _sync_audio_feed()
    if _touch_synth != null:
        _touch_synth.apply_settings(s)
    settings_applied.emit()


func _on_viewport_resized() -> void:
    _viewport_size = get_viewport().get_visible_rect().size
    _configure_viewports()
    for mode in _modes.values():
        (mode as ArtModeBase).setup(_viewport_size)
    _auto.setup(_viewport_size)


func _configure_viewports() -> void:
    var scale := TRAIL_RESOLUTION_SCALE
    var sz := Vector2i(
        maxi(2, int(_viewport_size.x * scale)),
        maxi(2, int(_viewport_size.y * scale))
    )
    for vp in [_trail_a, _trail_b]:
        vp.size = sz
        vp.transparent_bg = true
        vp.handle_input_locally = false
        vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

    # Positions stay in window pixels. Parent scale maps them into the trail target.
    var world_scale := Vector2(scale, scale)
    for root_path in [particles_root_a_path, particles_root_b_path]:
        var world := get_node_or_null(root_path) as Node2D
        if world:
            world.scale = world_scale

    if _composite:
        _composite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _make_glow_texture() -> GradientTexture2D:
    var grad := Gradient.new()
    grad.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
    grad.colors = PackedColorArray([
        Color(1, 1, 1, 1),
        Color(1, 1, 1, 0.55),
        Color(1, 1, 1, 0),
    ])
    var tex := GradientTexture2D.new()
    tex.gradient = grad
    tex.width = 64
    tex.height = 64
    tex.fill = GradientTexture2D.FILL_RADIAL
    tex.fill_from = Vector2(0.5, 0.5)
    tex.fill_to = Vector2(0.5, 0.0)
    return tex


func _ensure_multimesh(parent: Node) -> MultiMeshInstance2D:
    var mm := parent.get_node_or_null("Particles") as MultiMeshInstance2D
    if mm == null:
        mm = MultiMeshInstance2D.new()
        mm.name = "Particles"
        parent.add_child(mm)

    var mesh := QuadMesh.new()
    mesh.size = Vector2.ONE

    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_2D
    multimesh.use_colors = true
    multimesh.mesh = mesh
    multimesh.instance_count = 0
    mm.multimesh = multimesh
    return mm


func _ensure_head_overlay() -> MultiMeshInstance2D:
    var layer := _composite.get_parent() if _composite != null else null
    var mm: MultiMeshInstance2D = null
    if layer != null:
        mm = layer.get_node_or_null("DrawHead") as MultiMeshInstance2D
    if mm == null:
        mm = MultiMeshInstance2D.new()
        mm.name = "DrawHead"
        if layer != null:
            layer.add_child(mm)
    mm.z_index = 5
    mm.visible = false
    var mesh := QuadMesh.new()
    mesh.size = Vector2.ONE
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_2D
    multimesh.use_colors = true
    multimesh.mesh = mesh
    multimesh.instance_count = 0
    mm.multimesh = multimesh
    return mm


## Keeps existing particles so dragging the Number slider does not reshuffle the screen.
func _resize_particles(count: int) -> void:
    var old := positions.size()
    positions.resize(count)
    velocities.resize(count)
    for i in range(old, count):
        positions[i] = Vector2(randf() * _viewport_size.x, randf() * _viewport_size.y)
        velocities[i] = Vector2(randf_range(-80, 80), randf_range(-80, 80))

    for mm in [_mm_a, _mm_b]:
        mm.multimesh.instance_count = count
    _rebuild_instance_buffer()


func _color_key() -> Array:
    return [settings.color_preset, positions.size(), settings.particle_color]


## Identity rotation, current positions, and colors. Uploaded later in one set_buffer call.
func _rebuild_instance_buffer() -> void:
    var count := positions.size()
    _base_colors.resize(count)
    for i in count:
        _base_colors[i] = settings.color_for_index(i, count)
    _colors_key = _color_key()
    var buf := PackedFloat32Array()
    buf.resize(count * _INSTANCE_STRIDE)
    for i in count:
        var base := i * _INSTANCE_STRIDE
        var p := positions[i]
        var col := _base_colors[i]
        buf[base] = 1.0
        buf[base + 3] = p.x
        buf[base + 5] = 1.0
        buf[base + 7] = p.y
        buf[base + 8] = col.r
        buf[base + 9] = col.g
        buf[base + 10] = col.b
        buf[base + 11] = col.a
    _instance_buffer = buf


func _update_glow_visuals() -> void:
    var glow_on := settings != null and settings.glow
    for mm_node in [_mm_a, _mm_b, _mm_head]:
        if mm_node == null:
            continue
        if glow_on:
            mm_node.texture = _glow_texture
            mm_node.material = _glow_material
        else:
            mm_node.texture = null
            mm_node.material = null


func _update_particle_scale() -> void:
    # Map Width 100–1000 → ~2–20 px (larger when glow is on).
    var px := clampf(settings.width * 0.02, 1.0, 24.0)
    if settings.glow:
        px *= GLOW_SIZE_SCALE
    for mm_node in [_mm_a, _mm_b, _mm_head]:
        if mm_node == null or mm_node.multimesh == null:
            continue
        var mesh := mm_node.multimesh.mesh as QuadMesh
        if mesh:
            mesh.size = Vector2(px, px)


func _update_composite_uniforms() -> void:
    if _composite_mat == null:
        return
    _composite_mat.set_shader_parameter("invert_amount", 1.0 if settings.invert else 0.0)
    _composite_mat.set_shader_parameter("bg_color", settings.bg_color)


func _process(delta: float) -> void:
    var dt := minf(delta, MAX_DT)
    _simulate(dt)
    if settings and settings.color_preset == AppSettings.ColorPreset.SPARKLE:
        settings.sparkle_time += dt
    _render_trails()
    _update_lightning(dt)


func _simulate(dt: float) -> void:
    var user_active := touch != null and touch.is_active
    var current_mode_id := int(settings.art_mode) if settings else 0
    _auto.update(dt, user_active, current_mode_id)
    if settings and _auto.enabled and not user_active and _auto.pending_art_mode >= 0:
        settings.art_mode = _auto.pending_art_mode as AppSettings.ArtMode
        _auto.pending_art_mode = -1
        apply_settings(settings)
        settings.save_to_disk()
        auto_mode_changed.emit(settings)

    var anchor: Vector2
    var active: bool
    var just_p: bool
    var just_r: bool
    var tvel: Vector2

    if user_active:
        anchor = touch.last_anchor
        active = true
        just_p = touch.just_pressed
        just_r = touch.just_released
        tvel = touch.velocity
    elif _auto.active:
        anchor = _auto.anchor
        active = true
        just_p = _auto.just_pressed
        just_r = _auto.just_released
        tvel = _auto.velocity
    else:
        # On the release frame, keep the last touch/auto anchor for explode etc.
        just_r = (touch != null and touch.just_released) or _auto.just_released
        just_p = false
        active = false
        tvel = Vector2.ZERO
        if just_r and touch != null and touch.last_anchor != Vector2.ZERO:
            anchor = touch.last_anchor
        elif just_r:
            anchor = _auto.anchor
        else:
            anchor = _viewport_size * 0.5

    var mode := _current_mode
    mode.touch_active = active
    mode.just_pressed = just_p
    mode.just_released = just_r
    mode.touch_velocity = tvel
    mode.begin_idle_frame(dt, velocities, positions)
    mode.begin_frame(anchor, dt, positions)

    mode.apply_all(positions, velocities, anchor, dt)

    mode.end_frame()
    if _touch_synth != null:
        _touch_synth.set_point(anchor, active, _viewport_size)
    _advance_audio_style(dt)


func _advance_audio_style(dt: float) -> void:
    if settings == null or settings.art_mode != AppSettings.ArtMode.AUDIO or not settings.audio_style_auto:
        _style_hold = 0.0
        return
    _style_hold += dt
    var on_beat := _audio_feed != null and _audio_feed.beat_hit and _style_hold >= 8.0
    if not on_beat and _style_hold < 20.0:
        return
    _style_hold = 0.0
    var count := AppSettings.AudioStyle.size()
    if count < 2:
        return
    var next := (int(settings.audio_style) + 1) % count
    settings.audio_style = next as AppSettings.AudioStyle
    settings.save_to_disk()
    auto_mode_changed.emit(settings)


func _render_trails() -> void:
    var write_vp: SubViewport
    var read_vp: SubViewport
    var write_mm: MultiMeshInstance2D

    if _ping:
        write_vp = _trail_a
        read_vp = _trail_b
        write_mm = _mm_a
    else:
        write_vp = _trail_b
        read_vp = _trail_a
        write_mm = _mm_b

    _ping = not _ping

    # The read target only needs to keep last frame's texture for the fade blit.
    write_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    read_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED

    # Remap: 0.5 ≈ old 1.0 trails; 1.0 is much longer.
    var fade: float
    if settings.length <= 0.5:
        fade = lerpf(0.70, 0.985, settings.length * 2.0)
    else:
        fade = lerpf(0.985, 0.998, (settings.length - 0.5) * 2.0)

    var count := positions.size()
    if _instance_buffer.size() != count * _INSTANCE_STRIDE or _base_colors.size() != count:
        _rebuild_instance_buffer()
    var buf := _instance_buffer
    for i in count:
        var base := i * _INSTANCE_STRIDE
        var p := positions[i]
        buf[base + 3] = p.x
        buf[base + 7] = p.y
    if settings.color_preset == AppSettings.ColorPreset.SPARKLE:
        _write_sparkle_colors(buf, count)
    var draw_audio: ArtAudio = null
    if settings.art_mode == AppSettings.ArtMode.AUDIO and settings.audio_style == AppSettings.AudioStyle.DRAW:
        draw_audio = _current_mode as ArtAudio
    if draw_audio != null:
        # Particles parked at the draw head are hidden here and drawn by the head overlay.
        var flags := draw_audio.trail_flags()
        var flagged := flags.size() == count
        for i in count:
            var scale := 1.0 if not flagged or flags[i] != 0 else 0.0
            buf[i * _INSTANCE_STRIDE] = scale
            buf[i * _INSTANCE_STRIDE + 5] = scale
    elif _draw_head_lit:
        for i in count:
            buf[i * _INSTANCE_STRIDE] = 1.0
            buf[i * _INSTANCE_STRIDE + 5] = 1.0
    _draw_head_lit = draw_audio != null
    # Audio mode breathes with loudness and flashes on beats; free, since it is one modulate.
    # Reduce flashing keeps a gentle breath and drops the beat flash.
    var bright := 1.0
    if settings.art_mode == AppSettings.ArtMode.AUDIO and _audio_feed != null:
        if settings.reduce_flashing:
            bright = lerpf(0.85, 1.0, _audio_feed.level)
        else:
            bright = lerpf(0.6, 1.15, _audio_feed.level) + 0.35 * _audio_feed.beat
    write_mm.modulate = Color(bright, bright, bright)
    _instance_buffer = buf
    write_mm.multimesh.buffer = buf
    # set_buffer does not emit changed, so the canvas item must redraw explicitly.
    write_mm.queue_redraw()
    _render_draw_head(draw_audio)

    var fade_sprite := write_vp.get_node_or_null("FadeSprite") as Sprite2D
    if fade_sprite == null:
        fade_sprite = Sprite2D.new()
        fade_sprite.name = "FadeSprite"
        fade_sprite.centered = false
        fade_sprite.z_index = -10
        write_vp.add_child(fade_sprite)
        write_mm.z_index = 0

    fade_sprite.texture = read_vp.get_texture()
    fade_sprite.modulate = Color(1, 1, 1, fade)
    fade_sprite.position = Vector2.ZERO

    _mm_a.visible = write_mm == _mm_a
    _mm_b.visible = write_mm == _mm_b

    _composite_mat.set_shader_parameter("trail_tex", write_vp.get_texture())
    _composite_mat.set_shader_parameter("invert_amount", 1.0 if settings.invert else 0.0)
    _composite_mat.set_shader_parameter("bg_color", settings.bg_color)

    write_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    write_vp.transparent_bg = true


func _render_draw_head(draw_audio: ArtAudio) -> void:
    if _mm_head == null:
        return
    if draw_audio == null:
        _mm_head.visible = false
        return
    var count := positions.size()
    var ids := draw_audio.head_ids()
    var n := ids.size()
    var multimesh := _mm_head.multimesh
    if multimesh.instance_count != n:
        multimesh.instance_count = n
    if n == 0:
        _mm_head.visible = false
        return
    var buf := PackedFloat32Array()
    buf.resize(n * _INSTANCE_STRIDE)
    const HEAD_SCALE := 2.8
    for j in n:
        var i := ids[j]
        if i >= count:
            continue
        var base := j * _INSTANCE_STRIDE
        var p := positions[i]
        var col := _base_colors[i].lerp(Color(1.0, 1.0, 1.0, 1.0), 0.92)
        buf[base] = HEAD_SCALE
        buf[base + 3] = p.x
        buf[base + 5] = HEAD_SCALE
        buf[base + 7] = p.y
        buf[base + 8] = col.r
        buf[base + 9] = col.g
        buf[base + 10] = col.b
        buf[base + 11] = col.a
    multimesh.buffer = buf
    _mm_head.visible = true
    _mm_head.queue_redraw()


## Same look as AppSettings.color_for_index for Sparkle, using a hue table instead
## of Color.from_hsv: rgb = v * (1 - s + s * pure_hue).
func _write_sparkle_colors(buf: PackedFloat32Array, count: int) -> void:
    const HUE_STEPS := 256
    if _sparkle_hues.size() != HUE_STEPS:
        _sparkle_hues.resize(HUE_STEPS)
        for h in HUE_STEPS:
            _sparkle_hues[h] = Color.from_hsv(float(h) / float(HUE_STEPS), 1.0, 1.0)
    var t := settings.sparkle_time
    var drift := t * 0.22
    var wobble := t * 3.1
    var twinkle_t := t * 7.0
    var sat_t := t * 1.7
    for i in count:
        var fi := float(i)
        var hue := fposmod(fmod(fi * 0.61803398875, 1.0) + drift + sin(wobble + fi * 0.07) * 0.08, 1.0)
        var val := 0.75 + 0.25 * absf(sin(twinkle_t + fi * 0.31))
        var sat := 0.7 + 0.3 * absf(sin(sat_t + fi * 0.13))
        var pure := _sparkle_hues[int(hue * HUE_STEPS) % HUE_STEPS]
        var floor_v := val * (1.0 - sat)
        var lift := val * sat
        var base := i * _INSTANCE_STRIDE
        buf[base + 8] = floor_v + lift * pure.r
        buf[base + 9] = floor_v + lift * pure.g
        buf[base + 10] = floor_v + lift * pure.b
        buf[base + 11] = 1.0


func _on_lightning_discharged(center: Vector2, targets: PackedVector2Array) -> void:
    # The particles still strike; only the bright, flickering bolts are skipped.
    if settings != null and settings.reduce_flashing:
        return
    for t in targets:
        _bolt_segments.append({
            "from": center,
            "to": t,
            "life": 0.18,
        })
    _lightning.queue_redraw()


func _update_lightning(dt: float) -> void:
    if _bolt_segments.is_empty():
        return
    var i := 0
    while i < _bolt_segments.size():
        _bolt_segments[i]["life"] -= dt
        if _bolt_segments[i]["life"] <= 0.0:
            _bolt_segments.remove_at(i)
        else:
            i += 1
    _lightning.queue_redraw()


func draw_lightning(canvas: CanvasItem) -> void:
    var bolt_col := settings.particle_color if settings.color_preset == AppSettings.ColorPreset.WHITE else Color(0.85, 0.95, 1.0)
    for bolt in _bolt_segments:
        var life: float = bolt["life"]
        var alpha := clampf(life / 0.18, 0.0, 1.0)
        var col := Color(bolt_col.r, bolt_col.g, bolt_col.b, alpha)
        _draw_jagged_bolt(canvas, bolt["from"], bolt["to"], col)


func _draw_jagged_bolt(canvas: CanvasItem, from: Vector2, to: Vector2, col: Color) -> void:
    var points := PackedVector2Array()
    points.append(from)
    var segments := 6
    for s in range(1, segments):
        var t := float(s) / float(segments)
        var p := from.lerp(to, t)
        var perp := (to - from).normalized().orthogonal()
        p += perp * randf_range(-18.0, 18.0)
        points.append(p)
    points.append(to)
    for i in range(points.size() - 1):
        canvas.draw_line(points[i], points[i + 1], col, 2.0, true)
