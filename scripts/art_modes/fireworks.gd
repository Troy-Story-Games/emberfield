class_name ArtFireworks
extends ArtModeBase
## Fireworks — tap to burst, hold to keep firing, drag for a comet tail.
## Sparks burn out after a short, staggered life (or fall off screen) and are parked
## out of sight until a burst reuses them.

enum Kind { SPARK, WILLOW, TAIL, EMBER }
enum Shape { PEONY, RING, DOUBLE_RING, WILLOW }

const BURST_FRACTION := 0.08
const BURST_MIN := 60
const BURST_MAX := 900
const BURST_SPEED := 820.0
const BURST_INTERVAL := 0.45
const GRAVITY := 900.0
## Air drag per kind: sparks slow and droop; willows hang and fall slowly; tails fade quickly.
const DRAG := [1.7, 3.2, 2.6, 0.6]
## Burn time range per kind, in seconds. Staggered burnout reads as crackle.
const LIFE := [Vector2(0.9, 1.7), Vector2(2.2, 3.4), Vector2(0.25, 0.6), Vector2(0.3, 1.6)]
const TAIL_PER_SECOND := 260.0
const PARK_DEPTH := 400.0

var _kind: PackedByteArray = PackedByteArray()
var _parked: PackedByteArray = PackedByteArray()
var _life: PackedFloat32Array = PackedFloat32Array()
var _cursor: int = 0
var _timer: float = 0.0
var _tail_acc: float = 0.0
var _shape: int = 0
var _last_frame: int = -10
var _bursts: Array[Vector2] = []
var _size: float = 1.0
var _gravity: float = GRAVITY
var _rate: float = 1.0


func begin_frame(anchor: Vector2, dt: float, _positions: PackedVector2Array = PackedVector2Array()) -> void:
    _size = settings.fw_size if settings else 1.0
    _gravity = GRAVITY * (settings.fw_gravity if settings else 1.0)
    _rate = settings.fw_rate if settings else 1.0
    _bursts.clear()
    if just_pressed:
        _bursts.append(anchor)
        _timer = 0.0
    elif touch_active:
        _timer += dt
        var interval := BURST_INTERVAL / maxf(_rate, 0.05)
        if _timer >= interval:
            _timer -= interval
            _bursts.append(anchor)


func apply_all(positions: PackedVector2Array, velocities: PackedVector2Array, anchor: Vector2, dt: float) -> void:
    var n := positions.size()
    if n == 0:
        return
    var frame := Engine.get_process_frames()
    if _kind.size() != n or frame - _last_frame > 2:
        _enter(n)
    _last_frame = frame

    for center in _bursts:
        _burst(positions, velocities, center, n)
    if touch_active and touch_velocity.length() > 60.0:
        _tail_acc += TAIL_PER_SECOND * dt * minf(_size, 1.5)
        var tail := mini(int(_tail_acc), 24)
        _tail_acc -= float(tail)
        for k in tail:
            var i := _take(n)
            positions[i] = anchor + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
            velocities[i] = -touch_velocity * randf_range(0.05, 0.2) + Vector2.from_angle(randf() * TAU) * randf_range(10.0, 90.0)
            _kind[i] = Kind.TAIL
            _ignite(i)

    var keeps := PackedFloat32Array()
    keeps.resize(DRAG.size())
    for k in DRAG.size():
        keeps[k] = exp(-float(DRAG[k]) * dt)
    var fall := _gravity * dt
    var left := bounds.position.x - 40.0
    var right := bounds.end.x + 40.0
    var floor_y := bounds.end.y + 20.0
    for i in n:
        if _parked[i] != 0:
            continue
        var life := _life[i] - dt
        _life[i] = life
        var vel := velocities[i]
        vel.y += fall
        vel *= keeps[_kind[i]]
        var pos := positions[i] + vel * dt
        if life <= 0.0 or pos.y > floor_y or pos.x < left or pos.x > right:
            _parked[i] = 1
            pos = Vector2(clampf(pos.x, left, right), bounds.end.y + PARK_DEPTH)
            vel = Vector2.ZERO
        positions[i] = pos
        velocities[i] = vel


## Entering the mode: whatever is on screen rains down as embers, then parks.
func _enter(n: int) -> void:
    _kind.resize(n)
    _parked.resize(n)
    _life.resize(n)
    _kind.fill(Kind.EMBER)
    _parked.fill(0)
    for i in n:
        _ignite(i)
    _cursor = 0
    _timer = 0.0


## Oldest-first reuse: the cursor walks the pool, so each burst gets a contiguous
## index range (and so a related run of palette colors).
func _take(n: int) -> int:
    var i := _cursor
    _cursor = (_cursor + 1) % n
    _parked[i] = 0
    return i


func _burst(positions: PackedVector2Array, velocities: PackedVector2Array, center: Vector2, n: int) -> void:
    var count := clampi(int(float(n) * BURST_FRACTION * _size), BURST_MIN, BURST_MAX)
    count = mini(count, n)
    var shape := _shape
    _shape = (_shape + 1) % Shape.size()
    var speed := BURST_SPEED * sqrt(_size)
    var spin := randf() * TAU
    for k in count:
        var i := _take(n)
        var t := float(k) / float(count)
        var angle := spin + t * TAU * 7.0 + randf_range(-0.05, 0.05)
        var kick: float
        var kind := Kind.SPARK
        match shape:
            Shape.RING:
                angle = spin + t * TAU
                kick = speed * randf_range(0.95, 1.05)
            Shape.DOUBLE_RING:
                angle = spin + t * TAU * 2.0
                kick = speed * (1.0 if k % 2 == 0 else 0.55) * randf_range(0.96, 1.04)
            Shape.WILLOW:
                kick = speed * 1.35 * sqrt(randf())
                kind = Kind.WILLOW
            _:
                # Square root of a uniform value fills the disk evenly instead of bunching at the center.
                kick = speed * sqrt(randf()) * randf_range(0.9, 1.1)
        positions[i] = center
        velocities[i] = Vector2(cos(angle), sin(angle)) * kick
        _kind[i] = kind
        _ignite(i)


func _ignite(i: int) -> void:
    var span: Vector2 = LIFE[_kind[i]]
    _life[i] = randf_range(span.x, span.y)
