extends Node2D
class_name Background

@export var nebula_scale := 1.6
@export var nebula_intensity := 0.45
@export var star_count := 450
@export var star_parallax := 0.35

var _nebula: Sprite2D
var _neb_scroll := Vector2.ZERO
var _stars: Starfield

func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)

	# Nebula
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.WHITE)
	var tex := ImageTexture.create_from_image(img)

	_nebula = Sprite2D.new()
	_nebula.texture = tex
	_nebula.centered = false
	_nebula.z_index = -1000
	_nebula.scale = get_viewport_rect().size
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/nebula.gdshader")
	sm.set_shader_parameter("u_scale", nebula_scale)
	sm.set_shader_parameter("u_intensity", nebula_intensity)
	_nebula.material = sm
	add_child(_nebula)

	# Stars
	_stars = Starfield.new()
	_stars.z_index = -900
	_stars.area = get_viewport_rect().size * 2.0
	_stars.star_count = star_count
	_stars.parallax = star_parallax
	add_child(_stars)

func scroll_by_velocity(vel: Vector2, delta: float) -> void:
	if is_instance_valid(_stars):
		_stars.scroll_by_velocity(vel, delta)
	if is_instance_valid(_nebula):
		_neb_scroll += -vel * delta * 0.06
		var neb_mat := _nebula.material as ShaderMaterial
		if neb_mat:
			neb_mat.set_shader_parameter("u_scroll", _neb_scroll / get_viewport_rect().size)
