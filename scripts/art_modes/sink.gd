class_name ArtSink
extends ArtModeBase
## Sink — inverse Pulse: stream into touch, vanish, respawn at edges.

const SINK_RADIUS := 28.0
const ATTRACT_STRENGTH := 16000.0
const ATTRACT_SOFT := 35.0
const INFLOW_SPEED := 1000.0
const DRAG_HELD := 0.25
const DRAG_IDLE := 0.55
const DRAG_SPEED_THRESHOLD := 80.0
const DRAG_CONE_HALF_ANGLE := 0.55

var _dragging: bool = false
var _inflow_dir: Vector2 = Vector2.ZERO


func begin_frame(anchor: Vector2, _dt: float, _positions: PackedVector2Array = PackedVector2Array()) -> void:
    _dragging = touch_active and touch_velocity.length() >= DRAG_SPEED_THRESHOLD
    if _dragging:
        _inflow_dir = touch_velocity.normalized()


func _random_edge_point() -> Vector2:
    var side := randi() % 4
    match side:
        0:
            return Vector2(randf_range(bounds.position.x, bounds.end.x), bounds.position.y)
        1:
            return Vector2(randf_range(bounds.position.x, bounds.end.x), bounds.end.y)
        2:
            return Vector2(bounds.position.x, randf_range(bounds.position.y, bounds.end.y))
        _:
            return Vector2(bounds.end.x, randf_range(bounds.position.y, bounds.end.y))


func _edge_point_from_dir(outward: Vector2) -> Vector2:
    var center := bounds.get_center()
    var dir := outward.normalized()
    if dir.length_squared() < 0.0001:
        return _random_edge_point()
    var t_x := INF
    var t_y := INF
    if absf(dir.x) > 0.0001:
        var edge_x := bounds.end.x if dir.x > 0.0 else bounds.position.x
        t_x = (edge_x - center.x) / dir.x
    if absf(dir.y) > 0.0001:
        var edge_y := bounds.end.y if dir.y > 0.0 else bounds.position.y
        t_y = (edge_y - center.y) / dir.y
    var t := minf(absf(t_x), absf(t_y))
    return center + dir * t


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    if not touch_active:
        idle_all(positions, velocities, dt, DRAG_IDLE)
        return
    var sink_r := SINK_RADIUS * (settings.sink_radius if settings else 1.0)
    var sink_sq := sink_r * sink_r
    var inflow := INFLOW_SPEED * (settings.sink_inflow if settings else 1.0)
    var attract := ATTRACT_STRENGTH * (settings.sink_attract if settings else 1.0) * dt
    var soft_sq := ATTRACT_SOFT * ATTRACT_SOFT
    var drift := inflow * 0.35 * dt
    var keep := exp(-DRAG_HELD * dt)
    for i in positions.size():
        var to_sink := anchor - positions[i]
        var dist_sq := to_sink.length_squared()
        if dist_sq < sink_sq:
            var pos := _random_edge_point()
            var inward := (anchor - pos).normalized()
            if _dragging:
                var base := (-_inflow_dir).angle()
                inward = Vector2.from_angle(base + randf_range(-DRAG_CONE_HALF_ANGLE, DRAG_CONE_HALF_ANGLE))
                pos = _edge_point_from_dir(-inward)
            positions[i] = pos
            velocities[i] = inward * randf_range(inflow * 0.75, inflow * 1.2)
            continue
        var vel := velocities[i] + to_sink * (attract / (dist_sq + soft_sq))
        if dist_sq > 0.25:
            vel += to_sink * (drift / sqrt(dist_sq))
        velocities[i] = vel * keep
    integrate_all(positions, velocities, dt)
