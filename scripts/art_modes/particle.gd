class_name ArtParticle
extends ArtModeBase
## Vortex — tunable swirl while held; stops on release (no explode).

const ATTRACT_STRENGTH := 38000.0
const ATTRACT_SOFT := 10.0
const DRAG_HELD := 0.85
const DRAG_FREE := 0.45
const JITTER_RADIUS := 6.0
const JITTER_RADIUS_2 := 3.0
const BASE_ORBIT_STRENGTH := 1800.0

var _effective_anchor: Vector2 = Vector2.ZERO
var _time: float = 0.0


func begin_frame(anchor: Vector2, dt: float, _positions: PackedVector2Array = PackedVector2Array()) -> void:
    _time += dt
    var a1 := _time * 9.5
    var a2 := _time * 3.1
    _effective_anchor = anchor + Vector2(cos(a1), sin(a1)) * JITTER_RADIUS \
        + Vector2(cos(a2 * 0.7), sin(a2)) * JITTER_RADIUS_2


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, _anchor: Vector2, dt: float) -> void:
    if not touch_active:
        idle_all(positions, velocities, dt, DRAG_FREE)
        return
    var orbit_radius := settings.vortex_radius if settings else 14.0
    var speed_scale := settings.vortex_speed if settings else 1.0
    var pull_scale := settings.vortex_pull if settings else 1.0
    var direction := settings.vortex_direction if settings else AppSettings.VortexDirection.ALTERNATE
    var cluster_radius := orbit_radius * 1.6
    var cluster_sq := cluster_radius * cluster_radius
    var spin_near := BASE_ORBIT_STRENGTH * speed_scale * dt
    var spin_far := spin_near * 0.35
    var attract := ATTRACT_STRENGTH * pull_scale * dt
    var soft_sq := ATTRACT_SOFT * ATTRACT_SOFT
    var ring := 40.0 * dt
    var keep_near := exp(-1.6 * dt)
    var keep_far := exp(-DRAG_HELD * dt)
    # Tangent is (-radial.y, radial.x). CW keeps it, CCW negates it, Alternate negates even indices.
    var even_sign := 1.0 if direction == AppSettings.VortexDirection.CW else -1.0
    var odd_sign := -1.0 if direction == AppSettings.VortexDirection.CCW else 1.0
    var core := _effective_anchor
    for i in positions.size():
        var to_core := core - positions[i]
        var dist_sq := to_core.length_squared()
        var vel := velocities[i] + to_core * (attract / (dist_sq + soft_sq))
        if dist_sq > 0.25:
            var dist := sqrt(dist_sq)
            var radial := to_core / dist
            var tangent := Vector2(-radial.y, radial.x) * (even_sign if (i & 1) == 0 else odd_sign)
            if dist_sq < cluster_sq:
                vel += tangent * spin_near - radial * ((dist - orbit_radius) * ring)
            else:
                vel += tangent * spin_far
        velocities[i] = vel * (keep_near if dist_sq < cluster_sq else keep_far)
    integrate_all(positions, velocities, dt)
