class_name AppSettings
extends RefCounted
## Persistent app settings via ConfigFile.

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "visualizer"

const MIN_PARTICLES := 1
const MAX_PARTICLES := 12000
const DEFAULT_PARTICLES := 5000
const MIN_WIDTH := 150.0
const MAX_WIDTH := 1000.0
const DEFAULT_WIDTH := 250.0
const MIN_LENGTH := 0.0
const MAX_LENGTH := 1.0
const DEFAULT_LENGTH := 0.5

const MIN_VORTEX_RADIUS := 6.0
const MAX_VORTEX_RADIUS := 48.0
const DEFAULT_VORTEX_RADIUS := 14.0
const MIN_VORTEX_SPEED := 0.25
const MAX_VORTEX_SPEED := 2.5
const DEFAULT_VORTEX_SPEED := 1.0
const MIN_VORTEX_PULL := 0.25
const MAX_VORTEX_PULL := 10.0
const DEFAULT_VORTEX_PULL := 1.0
const MIN_REPEL_STRENGTH := 0.5
const MAX_REPEL_STRENGTH := 10.0
const DEFAULT_REPEL_STRENGTH := 1.0

const MIN_MUL := 0.25
const MAX_MUL := 2.5
const DEFAULT_MUL := 1.0

const MIN_ORBIT_RADIUS := 40.0
const MAX_ORBIT_RADIUS := 220.0
const DEFAULT_ORBIT_RADIUS := 90.0
const MIN_MAGNET_GAP := 40.0
const MAX_MAGNET_GAP := 240.0
const DEFAULT_MAGNET_GAP := 120.0

const MIN_TOUCH_VOLUME := 0.0
const MAX_TOUCH_VOLUME := 1.0
const DEFAULT_TOUCH_VOLUME := 0.7
const MIN_TOUCH_OCTAVES := 1.0
const MAX_TOUCH_OCTAVES := 4.0
const DEFAULT_TOUCH_OCTAVES := 2.0
const DEFAULT_TOUCH_TONE := 1.0
const DEFAULT_TOUCH_GLIDE := 1.0
const MIN_TOUCH_ENVELOPE := 0.005
const MAX_TOUCH_ATTACK := 0.4
const DEFAULT_TOUCH_ATTACK := 0.012
const MAX_TOUCH_RELEASE := 0.8
const DEFAULT_TOUCH_RELEASE := 0.08
## Engine.max_fps choices; 0 is uncapped. 60 keeps 90/120 Hz phones cool and judder-free.
const FRAME_RATES: Array[int] = [30, 60, 0]
const DEFAULT_MAX_FPS := 60

const _FIRES: Array[Color] = [
    Color(1.0, 0.15, 0.05),
    Color(1.0, 0.45, 0.05),
    Color(1.0, 0.75, 0.1),
    Color(1.0, 0.9, 0.35),
]
const _OCEANS: Array[Color] = [
    Color(0.1, 0.85, 0.95),
    Color(0.15, 0.45, 1.0),
    Color(0.05, 0.7, 0.75),
    Color(0.35, 0.55, 1.0),
]
const _NEONS: Array[Color] = [
    Color(1.0, 0.1, 0.85),
    Color(0.1, 1.0, 0.95),
    Color(0.55, 1.0, 0.1),
]
const _SUNSETS: Array[Color] = [
    Color(0.85, 0.2, 0.35),
    Color(1.0, 0.4, 0.2),
    Color(1.0, 0.65, 0.25),
    Color(1.0, 0.85, 0.45),
]
const _CANDIES: Array[Color] = [
    Color(1.0, 0.2, 0.65),
    Color(0.75, 0.25, 1.0),
    Color(0.2, 0.95, 1.0),
    Color(1.0, 0.45, 0.85),
]

enum ArtMode {
    WAVE,
    PARTICLE,
    GRAVITY,
    LIGHTNING,
    LINEAR,
    BLACK_HOLE,
    SINK,
    BEAM,
    ORBIT,
    RIPPLE,
    MAGNET,
    AUDIO,
    FLUID,
    FIREWORKS,
}

enum AudioSource {
    MICROPHONE,
    PLAYBACK,
}

enum AudioStyle {
    PULSE,
    EQUALIZER,
    SWIRL,
    EQUALIZER_VERTICAL,
    EQUALIZER_CIRCULAR,
    WAVEFORM,
    DRAW,
    GALAXY,
}

enum DrawAlgorithm {
    BASIC,
    BASIC_TIGHT,
    FIBONACCI,
    FIBONACCI_TIGHT,
    COIL,
}

enum WaveDirection {
    HORIZONTAL,
    VERTICAL,
}

enum AudioRange {
    MUSIC,
    VOICE,
    HEAVY,
    ROCK,
    QUIET,
    BRIGHT,
}

enum TouchScale {
    MAJOR,
    NATURAL_MINOR,
    MAJOR_PENTATONIC,
    MINOR_PENTATONIC,
    DORIAN,
    CHROMATIC,
}

enum TouchRegister {
    LOW,
    MID,
    HIGH,
}

enum TouchWave {
    SAW,
    SQUARE,
    SINE,
}

enum ColorPreset {
    WHITE,
    RAINBOW,
    FIRE,
    OCEAN,
    NEON,
    AURORA,
    SUNSET,
    MONO,
    CANDY,
    SPARKLE,
}

enum VortexDirection {
    CW,
    CCW,
    ALTERNATE,
}

enum IdleMode {
    DRIFT,
    SWIRL,
    LATTICE,
    BOIDS,
    RAIN,
}

var art_mode: ArtMode = ArtMode.WAVE
var invert: bool = false
var auto_control: bool = false
var glow: bool = true
## Drops the Audio beat flash and the Lightning bolts, for photosensitive viewers.
var reduce_flashing: bool = false
var show_fps: bool = false
var max_fps: int = DEFAULT_MAX_FPS
var hint_shown: bool = false
var color_preset: ColorPreset = ColorPreset.FIRE
var idle_mode: IdleMode = IdleMode.DRIFT
var particle_count: int = DEFAULT_PARTICLES
var width: float = DEFAULT_WIDTH
var length: float = DEFAULT_LENGTH
var particle_color: Color = Color.WHITE
var bg_color: Color = Color.BLACK

var vortex_radius: float = DEFAULT_VORTEX_RADIUS
var vortex_speed: float = DEFAULT_VORTEX_SPEED
var vortex_pull: float = DEFAULT_VORTEX_PULL
var vortex_direction: VortexDirection = VortexDirection.ALTERNATE
var repel_strength: float = DEFAULT_REPEL_STRENGTH

var bh_strength: float = 1.0
var bh_damping: float = 1.0
var bh_explode: float = 0.7

var pulse_emit_rate: float = 1.0
var pulse_kick_speed: float = 0.5
var pulse_ring_power: float = 1.0
var sparkle_time: float = 0.0

var sink_attract: float = 1.0
var sink_inflow: float = 1.0
var sink_radius: float = 1.0

var flow_field: float = 1.0
var flow_pull: float = 1.0

var lightning_attract: float = 1.0
var lightning_discharge: float = 1.0
var lightning_charge_time: float = 1.0

var beam_speed: float = 1.0
var beam_attract: float = 1.0
var beam_cone: float = 1.0

var orbit_radius: float = DEFAULT_ORBIT_RADIUS
var orbit_speed: float = 1.0
var orbit_attract: float = 1.0

var ripple_speed: float = 1.0
var ripple_power: float = 1.0
var ripple_rate: float = 1.0

var magnet_gap: float = DEFAULT_MAGNET_GAP
var magnet_attract: float = 1.0
var magnet_repel: float = 1.0

var fluid_scale: float = 1.0
var fluid_speed: float = 1.0
var fluid_stir: float = 1.0

var fw_size: float = 1.0
var fw_gravity: float = 1.0
var fw_rate: float = 1.0

var audio_source: AudioSource = AudioSource.MICROPHONE
var audio_style: AudioStyle = AudioStyle.PULSE
var audio_style_auto: bool = false
var audio_wave_direction: WaveDirection = WaveDirection.HORIZONTAL
var audio_range: AudioRange = AudioRange.MUSIC
var audio_draw_algorithm: DrawAlgorithm = DrawAlgorithm.BASIC
var audio_galaxy_arms: int = 3
var audio_sensitivity: float = 1.6
var audio_smooth: float = 0.5

var touch_audio: bool = false
var touch_audio_volume: float = DEFAULT_TOUCH_VOLUME
var touch_audio_root: int = 0
var touch_audio_register: TouchRegister = TouchRegister.HIGH
var touch_audio_scale: TouchScale = TouchScale.MAJOR
var touch_audio_octaves: float = DEFAULT_TOUCH_OCTAVES
var touch_audio_glide: float = DEFAULT_TOUCH_GLIDE
var touch_audio_tone: float = DEFAULT_TOUCH_TONE
var touch_audio_attack: float = DEFAULT_TOUCH_ATTACK
var touch_audio_release: float = DEFAULT_TOUCH_RELEASE
var touch_audio_wave: TouchWave = TouchWave.SAW


func load_from_disk() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(CONFIG_PATH) != OK:
        return
    art_mode = int(cfg.get_value(SECTION, "art_mode", ArtMode.WAVE)) as ArtMode
    invert = bool(cfg.get_value(SECTION, "invert", false))
    auto_control = bool(cfg.get_value(SECTION, "auto_control", false))
    glow = bool(cfg.get_value(SECTION, "glow", true))
    reduce_flashing = bool(cfg.get_value(SECTION, "reduce_flashing", false))
    show_fps = bool(cfg.get_value(SECTION, "show_fps", false))
    max_fps = int(cfg.get_value(SECTION, "max_fps", DEFAULT_MAX_FPS))
    if not FRAME_RATES.has(max_fps):
        max_fps = DEFAULT_MAX_FPS
    hint_shown = bool(cfg.get_value(SECTION, "hint_shown", false))
    color_preset = int(cfg.get_value(SECTION, "color_preset", ColorPreset.FIRE)) as ColorPreset
    idle_mode = int(cfg.get_value(SECTION, "idle_mode", IdleMode.DRIFT)) as IdleMode
    particle_count = clampi(int(cfg.get_value(SECTION, "particle_count", DEFAULT_PARTICLES)), MIN_PARTICLES, MAX_PARTICLES)
    width = clampf(float(cfg.get_value(SECTION, "width", DEFAULT_WIDTH)), MIN_WIDTH, MAX_WIDTH)
    length = clampf(float(cfg.get_value(SECTION, "length", DEFAULT_LENGTH)), MIN_LENGTH, MAX_LENGTH)
    particle_color = cfg.get_value(SECTION, "particle_color", Color.WHITE) as Color
    bg_color = cfg.get_value(SECTION, "bg_color", Color.BLACK) as Color
    vortex_radius = clampf(float(cfg.get_value(SECTION, "vortex_radius", DEFAULT_VORTEX_RADIUS)), MIN_VORTEX_RADIUS, MAX_VORTEX_RADIUS)
    vortex_speed = clampf(float(cfg.get_value(SECTION, "vortex_speed", DEFAULT_VORTEX_SPEED)), MIN_VORTEX_SPEED, MAX_VORTEX_SPEED)
    vortex_pull = clampf(float(cfg.get_value(SECTION, "vortex_pull", DEFAULT_VORTEX_PULL)), MIN_VORTEX_PULL, MAX_VORTEX_PULL)
    vortex_direction = int(cfg.get_value(SECTION, "vortex_direction", VortexDirection.ALTERNATE)) as VortexDirection
    repel_strength = clampf(float(cfg.get_value(SECTION, "repel_strength", DEFAULT_REPEL_STRENGTH)), MIN_REPEL_STRENGTH, MAX_REPEL_STRENGTH)
    bh_strength = clampf(float(cfg.get_value(SECTION, "bh_strength", 1.0)), 0.5, 3.0)
    bh_damping = clampf(float(cfg.get_value(SECTION, "bh_damping", 1.0)), 0.5, 3.0)
    bh_explode = clampf(float(cfg.get_value(SECTION, "bh_explode", 0.7)), 0.25, 2.0)
    pulse_emit_rate = _mul(cfg, "pulse_emit_rate", 1.0)
    pulse_kick_speed = _mul(cfg, "pulse_kick_speed", 0.5)
    pulse_ring_power = _mul(cfg, "pulse_ring_power", 1.0)
    sink_attract = _mul(cfg, "sink_attract", 1.0)
    sink_inflow = _mul(cfg, "sink_inflow", 1.0)
    sink_radius = clampf(float(cfg.get_value(SECTION, "sink_radius", 1.0)), 0.5, 2.0)
    flow_field = _mul(cfg, "flow_field", 1.0)
    flow_pull = _mul(cfg, "flow_pull", 1.0)
    lightning_attract = _mul(cfg, "lightning_attract", 1.0)
    lightning_discharge = _mul(cfg, "lightning_discharge", 1.0)
    lightning_charge_time = clampf(float(cfg.get_value(SECTION, "lightning_charge_time", 1.0)), 0.5, 2.0)
    beam_speed = _mul(cfg, "beam_speed", 1.0)
    beam_attract = _mul(cfg, "beam_attract", 1.0)
    beam_cone = _mul(cfg, "beam_cone", 1.0)
    orbit_radius = clampf(float(cfg.get_value(SECTION, "orbit_radius", DEFAULT_ORBIT_RADIUS)), MIN_ORBIT_RADIUS, MAX_ORBIT_RADIUS)
    orbit_speed = _mul(cfg, "orbit_speed", 1.0)
    orbit_attract = _mul(cfg, "orbit_attract", 1.0)
    ripple_speed = _mul(cfg, "ripple_speed", 1.0)
    ripple_power = _mul(cfg, "ripple_power", 1.0)
    ripple_rate = clampf(float(cfg.get_value(SECTION, "ripple_rate", 1.0)), 0.5, 2.0)
    magnet_gap = clampf(float(cfg.get_value(SECTION, "magnet_gap", DEFAULT_MAGNET_GAP)), MIN_MAGNET_GAP, MAX_MAGNET_GAP)
    magnet_attract = _mul(cfg, "magnet_attract", 1.0)
    magnet_repel = _mul(cfg, "magnet_repel", 1.0)
    fluid_scale = _mul(cfg, "fluid_scale", 1.0)
    fluid_speed = _mul(cfg, "fluid_speed", 1.0)
    fluid_stir = _mul(cfg, "fluid_stir", 1.0)
    fw_size = _mul(cfg, "fw_size", 1.0)
    fw_gravity = _mul(cfg, "fw_gravity", 1.0)
    fw_rate = _mul(cfg, "fw_rate", 1.0)
    audio_galaxy_arms = clampi(int(cfg.get_value(SECTION, "audio_galaxy_arms", 3)), 2, 4)
    audio_source = int(cfg.get_value(SECTION, "audio_source", AudioSource.MICROPHONE)) as AudioSource
    audio_style = clampi(int(cfg.get_value(SECTION, "audio_style", AudioStyle.PULSE)), 0, AudioStyle.size() - 1) as AudioStyle
    audio_style_auto = bool(cfg.get_value(SECTION, "audio_style_auto", false))
    audio_wave_direction = clampi(int(cfg.get_value(SECTION, "audio_wave_direction", WaveDirection.HORIZONTAL)), 0, WaveDirection.size() - 1) as WaveDirection
    audio_range = clampi(int(cfg.get_value(SECTION, "audio_range", AudioRange.MUSIC)), 0, AudioRange.size() - 1) as AudioRange
    audio_draw_algorithm = clampi(int(cfg.get_value(SECTION, "audio_draw_algorithm", DrawAlgorithm.BASIC)), 0, DrawAlgorithm.size() - 1) as DrawAlgorithm
    audio_sensitivity = _mul(cfg, "audio_sensitivity", 1.6)
    audio_smooth = _mul(cfg, "audio_smooth", 0.5)
    touch_audio = bool(cfg.get_value(SECTION, "touch_audio", false))
    touch_audio_volume = clampf(float(cfg.get_value(SECTION, "touch_audio_volume", DEFAULT_TOUCH_VOLUME)), MIN_TOUCH_VOLUME, MAX_TOUCH_VOLUME)
    touch_audio_root = clampi(int(cfg.get_value(SECTION, "touch_audio_root", 0)), 0, 11)
    touch_audio_register = clampi(int(cfg.get_value(SECTION, "touch_audio_register", TouchRegister.HIGH)), 0, TouchRegister.size() - 1) as TouchRegister
    touch_audio_scale = clampi(int(cfg.get_value(SECTION, "touch_audio_scale", TouchScale.MAJOR)), 0, TouchScale.size() - 1) as TouchScale
    touch_audio_octaves = clampf(float(cfg.get_value(SECTION, "touch_audio_octaves", DEFAULT_TOUCH_OCTAVES)), MIN_TOUCH_OCTAVES, MAX_TOUCH_OCTAVES)
    touch_audio_glide = clampf(float(cfg.get_value(SECTION, "touch_audio_glide", DEFAULT_TOUCH_GLIDE)), 0.0, 1.0)
    touch_audio_tone = _mul(cfg, "touch_audio_tone", DEFAULT_TOUCH_TONE)
    touch_audio_attack = clampf(float(cfg.get_value(SECTION, "touch_audio_attack", DEFAULT_TOUCH_ATTACK)), MIN_TOUCH_ENVELOPE, MAX_TOUCH_ATTACK)
    touch_audio_release = clampf(float(cfg.get_value(SECTION, "touch_audio_release", DEFAULT_TOUCH_RELEASE)), MIN_TOUCH_ENVELOPE, MAX_TOUCH_RELEASE)
    touch_audio_wave = clampi(int(cfg.get_value(SECTION, "touch_audio_wave", TouchWave.SAW)), 0, TouchWave.size() - 1) as TouchWave


func reset_to_defaults() -> void:
    art_mode = ArtMode.WAVE
    invert = false
    auto_control = false
    glow = true
    reduce_flashing = false
    show_fps = false
    max_fps = DEFAULT_MAX_FPS
    color_preset = ColorPreset.FIRE
    idle_mode = IdleMode.DRIFT
    particle_count = DEFAULT_PARTICLES
    width = DEFAULT_WIDTH
    length = DEFAULT_LENGTH
    particle_color = Color.WHITE
    bg_color = Color.BLACK
    vortex_radius = DEFAULT_VORTEX_RADIUS
    vortex_speed = DEFAULT_VORTEX_SPEED
    vortex_pull = DEFAULT_VORTEX_PULL
    vortex_direction = VortexDirection.ALTERNATE
    repel_strength = DEFAULT_REPEL_STRENGTH
    bh_strength = 1.0
    bh_damping = 1.0
    bh_explode = 0.7
    pulse_emit_rate = 1.0
    pulse_kick_speed = 0.5
    pulse_ring_power = 1.0
    sparkle_time = 0.0
    sink_attract = 1.0
    sink_inflow = 1.0
    sink_radius = 1.0
    flow_field = 1.0
    flow_pull = 1.0
    lightning_attract = 1.0
    lightning_discharge = 1.0
    lightning_charge_time = 1.0
    beam_speed = 1.0
    beam_attract = 1.0
    beam_cone = 1.0
    orbit_radius = DEFAULT_ORBIT_RADIUS
    orbit_speed = 1.0
    orbit_attract = 1.0
    ripple_speed = 1.0
    ripple_power = 1.0
    ripple_rate = 1.0
    magnet_gap = DEFAULT_MAGNET_GAP
    magnet_attract = 1.0
    magnet_repel = 1.0
    fluid_scale = 1.0
    fluid_speed = 1.0
    fluid_stir = 1.0
    fw_size = 1.0
    fw_gravity = 1.0
    fw_rate = 1.0
    audio_galaxy_arms = 3
    audio_source = AudioSource.MICROPHONE
    audio_style = AudioStyle.PULSE
    audio_style_auto = false
    audio_wave_direction = WaveDirection.HORIZONTAL
    audio_range = AudioRange.MUSIC
    audio_draw_algorithm = DrawAlgorithm.BASIC
    audio_sensitivity = 1.6
    audio_smooth = 0.5
    touch_audio = false
    touch_audio_volume = DEFAULT_TOUCH_VOLUME
    touch_audio_root = 0
    touch_audio_register = TouchRegister.HIGH
    touch_audio_scale = TouchScale.MAJOR
    touch_audio_octaves = DEFAULT_TOUCH_OCTAVES
    touch_audio_glide = DEFAULT_TOUCH_GLIDE
    touch_audio_tone = DEFAULT_TOUCH_TONE
    touch_audio_attack = DEFAULT_TOUCH_ATTACK
    touch_audio_release = DEFAULT_TOUCH_RELEASE
    touch_audio_wave = TouchWave.SAW


func save_to_disk() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value(SECTION, "art_mode", int(art_mode))
    cfg.set_value(SECTION, "invert", invert)
    cfg.set_value(SECTION, "auto_control", auto_control)
    cfg.set_value(SECTION, "glow", glow)
    cfg.set_value(SECTION, "reduce_flashing", reduce_flashing)
    cfg.set_value(SECTION, "show_fps", show_fps)
    cfg.set_value(SECTION, "max_fps", max_fps)
    cfg.set_value(SECTION, "hint_shown", hint_shown)
    cfg.set_value(SECTION, "color_preset", int(color_preset))
    cfg.set_value(SECTION, "idle_mode", int(idle_mode))
    cfg.set_value(SECTION, "particle_count", particle_count)
    cfg.set_value(SECTION, "width", width)
    cfg.set_value(SECTION, "length", length)
    cfg.set_value(SECTION, "particle_color", particle_color)
    cfg.set_value(SECTION, "bg_color", bg_color)
    cfg.set_value(SECTION, "vortex_radius", vortex_radius)
    cfg.set_value(SECTION, "vortex_speed", vortex_speed)
    cfg.set_value(SECTION, "vortex_pull", vortex_pull)
    cfg.set_value(SECTION, "vortex_direction", int(vortex_direction))
    cfg.set_value(SECTION, "repel_strength", repel_strength)
    cfg.set_value(SECTION, "bh_strength", bh_strength)
    cfg.set_value(SECTION, "bh_damping", bh_damping)
    cfg.set_value(SECTION, "bh_explode", bh_explode)
    cfg.set_value(SECTION, "pulse_emit_rate", pulse_emit_rate)
    cfg.set_value(SECTION, "pulse_kick_speed", pulse_kick_speed)
    cfg.set_value(SECTION, "pulse_ring_power", pulse_ring_power)
    cfg.set_value(SECTION, "sink_attract", sink_attract)
    cfg.set_value(SECTION, "sink_inflow", sink_inflow)
    cfg.set_value(SECTION, "sink_radius", sink_radius)
    cfg.set_value(SECTION, "flow_field", flow_field)
    cfg.set_value(SECTION, "flow_pull", flow_pull)
    cfg.set_value(SECTION, "lightning_attract", lightning_attract)
    cfg.set_value(SECTION, "lightning_discharge", lightning_discharge)
    cfg.set_value(SECTION, "lightning_charge_time", lightning_charge_time)
    cfg.set_value(SECTION, "beam_speed", beam_speed)
    cfg.set_value(SECTION, "beam_attract", beam_attract)
    cfg.set_value(SECTION, "beam_cone", beam_cone)
    cfg.set_value(SECTION, "orbit_radius", orbit_radius)
    cfg.set_value(SECTION, "orbit_speed", orbit_speed)
    cfg.set_value(SECTION, "orbit_attract", orbit_attract)
    cfg.set_value(SECTION, "ripple_speed", ripple_speed)
    cfg.set_value(SECTION, "ripple_power", ripple_power)
    cfg.set_value(SECTION, "ripple_rate", ripple_rate)
    cfg.set_value(SECTION, "magnet_gap", magnet_gap)
    cfg.set_value(SECTION, "magnet_attract", magnet_attract)
    cfg.set_value(SECTION, "magnet_repel", magnet_repel)
    cfg.set_value(SECTION, "fluid_scale", fluid_scale)
    cfg.set_value(SECTION, "fluid_speed", fluid_speed)
    cfg.set_value(SECTION, "fluid_stir", fluid_stir)
    cfg.set_value(SECTION, "fw_size", fw_size)
    cfg.set_value(SECTION, "fw_gravity", fw_gravity)
    cfg.set_value(SECTION, "fw_rate", fw_rate)
    cfg.set_value(SECTION, "audio_galaxy_arms", audio_galaxy_arms)
    cfg.set_value(SECTION, "audio_source", int(audio_source))
    cfg.set_value(SECTION, "audio_style", int(audio_style))
    cfg.set_value(SECTION, "audio_style_auto", audio_style_auto)
    cfg.set_value(SECTION, "audio_wave_direction", int(audio_wave_direction))
    cfg.set_value(SECTION, "audio_range", int(audio_range))
    cfg.set_value(SECTION, "audio_draw_algorithm", int(audio_draw_algorithm))
    cfg.set_value(SECTION, "audio_sensitivity", audio_sensitivity)
    cfg.set_value(SECTION, "audio_smooth", audio_smooth)
    cfg.set_value(SECTION, "touch_audio", touch_audio)
    cfg.set_value(SECTION, "touch_audio_volume", touch_audio_volume)
    cfg.set_value(SECTION, "touch_audio_root", touch_audio_root)
    cfg.set_value(SECTION, "touch_audio_register", int(touch_audio_register))
    cfg.set_value(SECTION, "touch_audio_scale", int(touch_audio_scale))
    cfg.set_value(SECTION, "touch_audio_octaves", touch_audio_octaves)
    cfg.set_value(SECTION, "touch_audio_glide", touch_audio_glide)
    cfg.set_value(SECTION, "touch_audio_tone", touch_audio_tone)
    cfg.set_value(SECTION, "touch_audio_attack", touch_audio_attack)
    cfg.set_value(SECTION, "touch_audio_release", touch_audio_release)
    cfg.set_value(SECTION, "touch_audio_wave", int(touch_audio_wave))
    cfg.save(CONFIG_PATH)


func _mul(cfg: ConfigFile, key: String, default_v: float) -> float:
    return clampf(float(cfg.get_value(SECTION, key, default_v)), MIN_MUL, MAX_MUL)


static func art_mode_name(mode: ArtMode) -> String:
    match mode:
        ArtMode.WAVE:
            return "Pulse"
        ArtMode.PARTICLE:
            return "Vortex"
        ArtMode.GRAVITY:
            return "Repel"
        ArtMode.LIGHTNING:
            return "Lightning"
        ArtMode.LINEAR:
            return "Flow"
        ArtMode.BLACK_HOLE:
            return "Black Hole"
        ArtMode.SINK:
            return "Sink"
        ArtMode.BEAM:
            return "Beam"
        ArtMode.ORBIT:
            return "Orbit"
        ArtMode.RIPPLE:
            return "Ripple"
        ArtMode.MAGNET:
            return "Magnet"
        ArtMode.AUDIO:
            return "Audio"
        ArtMode.FLUID:
            return "Fluid"
        ArtMode.FIREWORKS:
            return "Fireworks"
    return "Pulse"


static func frame_rate_name(fps: int) -> String:
    match fps:
        30:
            return "30 FPS (battery saver)"
        60:
            return "60 FPS"
    return "Unlimited"


static func audio_source_name(source: AudioSource) -> String:
    match source:
        AudioSource.MICROPHONE:
            return "Microphone"
        AudioSource.PLAYBACK:
            return "Playback"
    return "Microphone"


static func touch_scale_name(scale: TouchScale) -> String:
    match scale:
        TouchScale.MAJOR:
            return "Major"
        TouchScale.NATURAL_MINOR:
            return "Natural minor"
        TouchScale.MAJOR_PENTATONIC:
            return "Major pentatonic"
        TouchScale.MINOR_PENTATONIC:
            return "Minor pentatonic"
        TouchScale.DORIAN:
            return "Dorian"
        TouchScale.CHROMATIC:
            return "Chromatic"
    return "Major"


static func touch_register_name(register: TouchRegister) -> String:
    match register:
        TouchRegister.LOW:
            return "Low"
        TouchRegister.MID:
            return "Mid"
        TouchRegister.HIGH:
            return "High"
    return "High"


static func touch_register_midi(register: TouchRegister) -> int:
    match register:
        TouchRegister.LOW:
            return 24
        TouchRegister.MID:
            return 48
        TouchRegister.HIGH:
            return 60
    return 60


static func touch_wave_name(wave: TouchWave) -> String:
    match wave:
        TouchWave.SAW:
            return "Saw"
        TouchWave.SQUARE:
            return "Square"
        TouchWave.SINE:
            return "Sine"
    return "Saw"


static func note_name(root: int) -> String:
    var names := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    return names[clampi(root, 0, names.size() - 1)]


static func audio_range_name(range_id: AudioRange) -> String:
    match range_id:
        AudioRange.MUSIC:
            return "Music"
        AudioRange.VOICE:
            return "Voice"
        AudioRange.HEAVY:
            return "Heavy"
        AudioRange.ROCK:
            return "Rock"
        AudioRange.QUIET:
            return "Quiet"
        AudioRange.BRIGHT:
            return "Bright"
    return "Music"


static func audio_style_name(style: AudioStyle) -> String:
    match style:
        AudioStyle.PULSE:
            return "Pulse"
        AudioStyle.EQUALIZER:
            return "Equalizer"
        AudioStyle.SWIRL:
            return "Swirl"
        AudioStyle.EQUALIZER_VERTICAL:
            return "Vertical equalizer"
        AudioStyle.EQUALIZER_CIRCULAR:
            return "Circular equalizer"
        AudioStyle.WAVEFORM:
            return "Waveform"
        AudioStyle.DRAW:
            return "Draw"
        AudioStyle.GALAXY:
            return "Galaxy"
    return "Pulse"


static func draw_algorithm_name(algorithm: DrawAlgorithm) -> String:
    match algorithm:
        DrawAlgorithm.BASIC:
            return "Basic"
        DrawAlgorithm.BASIC_TIGHT:
            return "Basic tight"
        DrawAlgorithm.FIBONACCI:
            return "Fibonacci"
        DrawAlgorithm.FIBONACCI_TIGHT:
            return "Fibonacci tight"
        DrawAlgorithm.COIL:
            return "Coil"
    return "Basic"


static func wave_direction_name(direction: WaveDirection) -> String:
    match direction:
        WaveDirection.HORIZONTAL:
            return "Horizontal"
        WaveDirection.VERTICAL:
            return "Vertical"
    return "Horizontal"


static func idle_mode_name(mode: IdleMode) -> String:
    match mode:
        IdleMode.DRIFT:
            return "Drift"
        IdleMode.SWIRL:
            return "Swirl"
        IdleMode.LATTICE:
            return "Lattice"
        IdleMode.BOIDS:
            return "Boids"
        IdleMode.RAIN:
            return "Rain"
    return "Drift"


static func vortex_direction_name(dir: VortexDirection) -> String:
    match dir:
        VortexDirection.CW:
            return "Clockwise"
        VortexDirection.CCW:
            return "Counter-clockwise"
        VortexDirection.ALTERNATE:
            return "Alternate"
    return "Alternate"


static func color_preset_name(preset: ColorPreset) -> String:
    match preset:
        ColorPreset.WHITE:
            return "White"
        ColorPreset.RAINBOW:
            return "Rainbow"
        ColorPreset.FIRE:
            return "Fire"
        ColorPreset.OCEAN:
            return "Ocean"
        ColorPreset.NEON:
            return "Neon"
        ColorPreset.AURORA:
            return "Aurora"
        ColorPreset.SUNSET:
            return "Sunset"
        ColorPreset.MONO:
            return "Mono"
        ColorPreset.CANDY:
            return "Candy"
        ColorPreset.SPARKLE:
            return "Sparkle"
    return "White"


func color_for_index(i: int, count: int) -> Color:
    var n := maxi(count, 1)
    var t := float(i) / float(n)
    match color_preset:
        ColorPreset.WHITE:
            return particle_color
        ColorPreset.RAINBOW:
            return Color.from_hsv(t, 0.85, 1.0)
        ColorPreset.FIRE:
            return _FIRES[i % _FIRES.size()]
        ColorPreset.OCEAN:
            return _OCEANS[i % _OCEANS.size()]
        ColorPreset.NEON:
            return _NEONS[i % _NEONS.size()]
        ColorPreset.AURORA:
            return Color.from_hsv(fmod(0.28 + t * 0.45, 1.0), 0.7, 1.0)
        ColorPreset.SUNSET:
            return _SUNSETS[i % _SUNSETS.size()]
        ColorPreset.MONO:
            var g := lerpf(0.35, 1.0, t)
            return Color(g, g, g)
        ColorPreset.CANDY:
            return _CANDIES[i % _CANDIES.size()]
        ColorPreset.SPARKLE:
            var base := fmod(float(i) * 0.61803398875, 1.0)
            var hue := fmod(base + sparkle_time * 0.22 + sin(sparkle_time * 3.1 + float(i) * 0.07) * 0.08, 1.0)
            if hue < 0.0:
                hue += 1.0
            var twinkle := 0.75 + 0.25 * absf(sin(sparkle_time * 7.0 + float(i) * 0.31))
            var sat := 0.7 + 0.3 * absf(sin(sparkle_time * 1.7 + float(i) * 0.13))
            return Color.from_hsv(hue, sat, twinkle)
    return particle_color
