extends Node2D
class_name Bullets

@export var texture: Texture2D        
@export var speed: float = 400.0
@export var life: float = 1.5
@export var bullet_scale: float = 0.2
@export var radius_frac: float = 0.90
@export var auto_generate_tex: bool = true
@export var gen_px: int = 80          # size of the generated texture
@export var tuning: Tuning

var _view_size: Vector2 = Vector2.ZERO
var _items: Array = []                # each: {pos, vel, life, node}
var _pool: Array[Node2D] = []         # reusable bullet nodes
var _bullet_material: Material        # shared material (no per-bullet shader)

func _ready() -> void:
	_view_size = get_viewport_rect().size
	_ensure_tex()
	_ensure_material()

func _ensure_tex() -> void:
	if auto_generate_tex and texture == null:
		texture = Utils2D.make_round_bullet_tex(gen_px)

func _ensure_material() -> void:
	if _bullet_material != null:
		return
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_bullet_material = mat

func _get_bullet_node(at: Vector2) -> Node2D:
	var node: Node2D
	if _pool.size() > 0:
		node = _pool.pop_back()
		node.show()
	else:
		# New node created via Factory once, then reused
		node = Factory.make_bullet_node(at, texture, self, bullet_scale)
		var sprite := node.get_child(0) as Sprite2D
		if sprite:
			sprite.material = _bullet_material
	node.global_position = at
	return node

func spawn(xform: Transform2D) -> void:
	_ensure_tex()
	_ensure_material()

	# direction = local +X of the muzzle transform
	var dir: Vector2 = xform.basis_xform(Vector2.RIGHT).normalized()
	var pos: Vector2 = xform.origin
	var vel: Vector2 = dir * speed

	var node := _get_bullet_node(pos)

	var b := {
		"pos": pos,
		"vel": vel,
		"life": life,
		"node": node,
	}
	_items.append(b)

func _process(delta: float) -> void:
	if _items.is_empty():
		return

	var i := _items.size() - 1
	while i >= 0:
		var b = _items[i]
		var pos: Vector2 = b.pos + b.vel * delta
		pos = _wrap(pos)

		var remaining: float = b.life - delta

		if b.has("node") and is_instance_valid(b.node):
			b.node.global_position = pos

		if remaining <= 0.0:
			if b.has("node") and is_instance_valid(b.node):
				b.node.hide()
				_pool.append(b.node)
			_items.remove_at(i)
		else:
			b.pos = pos
			b.life = remaining
			_items[i] = b
		i -= 1

func _wrap(p: Vector2) -> Vector2:
	var s := _view_size
	if p.x < 0.0:
		p.x += s.x
	elif p.x > s.x:
		p.x -= s.x
	if p.y < 0.0:
		p.y += s.y
	elif p.y > s.y:
		p.y -= s.y
	return p

func items() -> Array:
	return _items

func radius() -> float:
	_ensure_tex()
	return Utils2D.sprite_radius(texture, bullet_scale, radius_frac)

func clear() -> void:
	# free active bullets
	for b in _items:
		if b.has("node") and is_instance_valid(b.node):
			b.node.queue_free()
	_items.clear()

	# free pooled bullets
	for n in _pool:
		if is_instance_valid(n):
			n.queue_free()
	_pool.clear()
