extends Node
class_name CollisionSystem

@export var ship_path: NodePath
@export var bullets_path: NodePath
@export var asteroids_path: NodePath
@export var waves_path: NodePath
@export_range(0.70, 1.00, 0.01)
var asteroid_intersection_factor: float = 0.75   # < 1.0 → require overlap before colliding

signal bullet_hit_asteroid(at: Vector2, bullet_vel: Vector2)
signal ship_hit()

var ship: ShipNode
var bullets: Bullets
var asteroids: Asteroids
var waves: FreezeWaves

func _ready() -> void:
	if ship_path != NodePath(): ship = get_node(ship_path) as ShipNode
	if bullets_path != NodePath(): bullets = get_node(bullets_path) as Bullets
	if asteroids_path != NodePath(): asteroids = get_node(asteroids_path) as Asteroids
	if waves_path != NodePath(): waves = get_node(waves_path) as FreezeWaves

func _process(_delta: float) -> void:
	if !ship or !bullets or !asteroids: return
	var br := bullets.radius()
	var ar := asteroids.radius()
	var bitems := bullets.items()
	var aitems := asteroids.items()

	# bullets ↔ asteroids
	for bi in range(bitems.size() - 1, -1, -1):
		var b = bitems[bi]
		var hit_ai := -1
		for ai in range(aitems.size() - 1, -1, -1):
			var a = aitems[ai]
			if b.pos.distance_to(a.pos) <= br + ar:
				hit_ai = ai
				break
		if hit_ai != -1:
			emit_signal("bullet_hit_asteroid", b.pos, b.vel)
			asteroids.respawn_at(hit_ai, ship.global_position) # pass the ship position so we respawn on the opposite half
			if b.has("node") and is_instance_valid(b.node): b.node.queue_free()
			bitems.remove_at(bi)

	# asteroids ↔ asteroids: flip direction on collision
	for i in range(aitems.size()):
		for j in range(i + 1, aitems.size()):
			var a = aitems[i]
			var b = aitems[j]
			var delta: Vector2 = a.pos - b.pos
			var dist := delta.length()

			# Require a bit of *overlap* before we say "colliding"
			var touch := (2.0 * ar) * asteroid_intersection_factor 

			if dist <= touch:
				# 1) reverse velocities
				a.vel = -a.vel
				b.vel = -b.vel

				# 2) separate slightly, but keep a tiny overlap so it doesn't look like popping
				var n := (delta / dist) if dist > 0.0 else Vector2.RIGHT.rotated(randf() * TAU)
				var eps := 0.1
				var push : float = max(0.0, (touch - dist + eps) * 0.5)
				a.pos += n * push
				b.pos -= n * push

				# 3) reflect in scene
				if a.has("node") and is_instance_valid(a.node): a.node.global_position = a.pos
				if b.has("node") and is_instance_valid(b.node): b.node.global_position = b.pos

				# write back
				aitems[i] = a
				aitems[j] = b

	# ship ↔ asteroid
	var ship_r := ship.radius
	for a in aitems:
		if ship.global_position.distance_to(a.pos) <= ship_r + ar:
			emit_signal("ship_hit")
			break
	
	# time-stop wave ↔ asteroids : freeze on contact
	if waves:
		var rings := waves.get_rings()
		if not rings.is_empty():
			var waves_ar := asteroids.radius()
			var waves_aitems := asteroids.items()
			for i in range(waves_aitems.size()):
				var a = waves_aitems[i]
				# skip if already frozen
				if a.has("frozen") and a.frozen:
					continue
				if waves.hits_circle(a.pos, waves_ar):
					asteroids.freeze_index(i)
