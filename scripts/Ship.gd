extends Node2D
class_name ShipNode

signal fired(xform: Transform2D)

@export var accel: float = 200.0
@export var rot_speed: float = 3.0
@export var friction: float = 0.99
@export var max_speed: float = 600.0
@export var radius: float = 18.0
@export var bullet_offset: float = 24.0
@export var body_texture: Texture2D = preload("res://images/ship.png")
@export var body_scale: Vector2 = Vector2(0.25, 0.25)
@export var tuning: Tuning

@onready var body: Sprite2D = $Body
@onready var thruster: GPUParticles2D = $Exhaust/Thruster
var thrust_mat: ParticleProcessMaterial

var vel: Vector2 = Vector2.ZERO

func _tune_thruster_for_web() -> void:
	if thruster == null:
		return

	# Drastically reduce particle count on web
	thruster.amount = min(thruster.amount, 50)  # cap at 50 on HTML5

	# Shorter lifetime means fewer particles alive at once
	thruster.lifetime = min(thruster.lifetime, 0.18)

	# Trails are extra overdraw – kill them on web
	thruster.trail_lifetime = 0.0

	# Make sure they don't spawn too far away
	thruster.draw_passes = 1

	if thrust_mat:
		# Keep same feel but clamp extremes a bit
		thrust_mat.spread = 24.0   # degrees, keep pretty narrow cone

func _ready() -> void:
	if body_texture:
		body.texture = body_texture
	body.scale = body_scale
	# ensure we have a material on the thruster
	if thruster:
		if thruster.process_material == null:
			thruster.process_material = ParticleProcessMaterial.new()
		thrust_mat = thruster.process_material
		thruster.z_index = -1
		thruster.local_coords = false
		
		if OS.has_feature("HTML5"):
			_tune_thruster_for_web()

func _physics_process(delta: float) -> void:
	# rotation from an axis so both keys work cleanly
	var turn := Input.get_axis("turn_left", "turn_right")
	rotation += rot_speed * turn * delta

	var thrusting := Input.is_action_pressed("thrust")
	if thrusting:
		vel += Vector2.RIGHT.rotated(rotation) * accel * delta

	vel *= friction
	vel = vel.limit_length(max_speed)
	global_position = _wrap(global_position + vel * delta)

	# particles
	thruster.emitting = thrusting
	if thrust_mat:
		var sp : float = clamp(vel.length() / max_speed, 0.0, 1.0)
		thrust_mat.initial_velocity_min = 220.0
		thrust_mat.initial_velocity_max = 220.0 + 380.0 * (0.3 + 0.7 * sp)
		thrust_mat.damping_min = 140.0
		thrust_mat.damping_max = 210.0

func request_fire() -> void:
	emit_signal("fired", muzzle_transform())

func muzzle_transform() -> Transform2D:
	var t := global_transform
	t.origin += Vector2.RIGHT.rotated(rotation) * bullet_offset
	return t

func get_velocity() -> Vector2:
	return vel

func reset_at(pos: Vector2) -> void:
	global_position = pos
	rotation = 0.0
	vel = Vector2.ZERO

func pulse_outline() -> void:
	var sm := body.material as ShaderMaterial
	if sm == null:
		sm = ShaderMaterial.new()
		sm.shader = load("res://shaders/glow_outline.gdshader")
		body.material = sm
	# spike then ease back
	sm.set_shader_parameter("emission_strength", 4.0)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v): sm.set_shader_parameter("emission_strength", v), 4.0, 0.6, 0.25)

func _wrap(p: Vector2) -> Vector2:
	var s := get_viewport_rect().size
	if p.x < 0: p.x += s.x
	elif p.x > s.x: p.x -= s.x
	if p.y < 0: p.y += s.y
	elif p.y > s.y: p.y -= s.y
	return p
