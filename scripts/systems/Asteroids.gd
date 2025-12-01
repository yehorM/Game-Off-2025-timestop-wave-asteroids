extends Node2D
class_name Asteroids

@export var texture: Texture2D
@export var asteroid_scale: float = 0.25
@export var min_speed: float = 40.0
@export var max_speed: float = 120.0
@export var count: int = 6
@export var radius_frac: float = 0.70
@export var tuning: Tuning

var _view_size := Vector2.ZERO
var _items: Array = []  # each: {pos, vel, node, spin, frozen}

func setup(view_size: Vector2, avoid_pos: Vector2, avoid_radius: float) -> void:
	_view_size = view_size
	clear()
	for i in count:
		var pos = Vector2(randi() % int(view_size.x), randi() % int(view_size.y))
		while pos.distance_to(avoid_pos) < avoid_radius * 3.0:
			pos = Vector2(randi() % int(view_size.x), randi() % int(view_size.y))
		var angle = randf() * TAU
		var spd = randf_range(min_speed, max_speed)
		var vel = Vector2.RIGHT.rotated(angle) * spd
		var node = Factory.make_asteroid_node(pos, texture, asteroid_scale)
		add_child(node)
		_items.append({
			"pos": pos,
			"vel": vel,
			"node": node,
			"spin": randf_range(-1.0, 1.0),
			"frozen": false
		})

func freeze_current() -> void:
	for i in range(_items.size()):
		var a = _items[i]
		a.frozen = true
		_items[i] = a

func _process(delta: float) -> void:
	for i in range(_items.size()):
		var a = _items[i]
		if not a.frozen:
			a.pos = Utils2D.wrap(a.pos + a.vel * delta, _view_size)
			a.node.rotation += a.spin * delta
		# always keep node in sync
		if a.has("node") and is_instance_valid(a.node):
			a.node.global_position = a.pos
		_items[i] = a

# Pick a random point that's >= half-screen away from avoid_pos
func _pos_far_from(avoid_pos: Vector2) -> Vector2:
	var w := _view_size.x
	var h := _view_size.y
	var margin := 12.0
	var min_dist: float = 0.5 * min(w, h)   # ">= half screen"

	var tries := 0
	while tries < 33:
		var x := randf_range(margin, w - margin)
		var y := randf_range(margin, h - margin)
		var p := Vector2(x, y)
		if p.distance_to(avoid_pos) >= min_dist:
			return p
		tries += 1

	# Fallback after bounded attempts: place exactly min_dist away, clamped to screen
	var ang := randf() * TAU
	var q := avoid_pos + Vector2.RIGHT.rotated(ang) * min_dist
	q.x = clamp(q.x, margin, w - margin)
	q.y = clamp(q.y, margin, h - margin)
	return q

func respawn_at(index: int, avoid_pos: Vector2) -> void:
	var pos := _pos_far_from(avoid_pos)
	var a = _items[index]
	a.pos = pos

	# fresh motion + unfreeze
	var angle = randf() * TAU
	var spd = randf_range(min_speed, max_speed)
	a.vel = Vector2.RIGHT.rotated(angle) * spd
	a.spin = randf_range(-1.0, 1.0)
	a.frozen = false

	if a.has("node") and is_instance_valid(a.node):
		a.node.global_position = pos
	_items[index] = a

func items() -> Array: return _items
func radius() -> float:
	return Utils2D.sprite_radius(texture, asteroid_scale, radius_frac)

func clear() -> void:
	for a in _items:
		if a.has("node") and is_instance_valid(a.node):
			a.node.queue_free()
	_items.clear()

func freeze_index(i: int) -> void:
	if i < 0 or i >= _items.size(): return
	var a = _items[i]
	a.frozen = true
	a.vel = Vector2.ZERO
	a.spin = 0.0
	_items[i] = a
