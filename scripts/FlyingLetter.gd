extends Node2D
class_name FlyingLetter

@export var letter: String = "W"
@export var color: Color = Color(1.0, 0.95, 0.3)
@export var font_size: int = 64
@export var life: float = 5.0
var vel: Vector2 = Vector2.ZERO

var _t := 0.0
var _sprite: Sprite2D
var _vp: SubViewport
var _pickup_radius: float = 24.0

func get_radius() -> float:
	return _pickup_radius

func _ready() -> void:
	add_to_group("letters")

	# font + text metrics
	var ff: FontFile = load("res://fonts/Xolonium-Regular.ttf")
	var text_size: Vector2 = ff.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pad := Vector2(10, 10)

	# viewport with a Label that renders the glyph
	_vp = SubViewport.new()
	_vp.disable_3d = true
	_vp.transparent_bg = true
	_vp.size = Vector2i((text_size + pad).ceil())
	add_child(_vp)

	var lbl := Label.new()
	lbl.text = letter
	lbl.modulate = color
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", ff)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.size = _vp.size
	_vp.add_child(lbl)

	# sprite that shows the viewport texture + wobble/emission shader
	_sprite = Sprite2D.new()
	_sprite.centered = true
	_sprite.texture = _vp.get_texture()

	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/wobble_emissive.gdshader") # <- uses modulate alpha
	mat.set_shader_parameter("amp", 0.012)
	mat.set_shader_parameter("freq", 10.0)
	mat.set_shader_parameter("speed", 1.2)
	mat.set_shader_parameter("emission_strength", 1.2)
	_sprite.material = mat
	add_child(_sprite)

	# pickup radius ~ 40% of the rendered size
	_pickup_radius = max(_vp.size.x, _vp.size.y) * 0.4

func _process(delta: float) -> void:
	_t += delta
	position += vel * delta

	# subtle wobble at node level
	rotation = sin(_t * 6.0) * 0.18
	scale = Vector2(1.0, 1.0) + Vector2(0.05, -0.05) * sin(_t * 8.0)

	# wrap and fade (shader reads modulate.a)
	position = Utils2D.wrap(position, get_viewport_rect().size)
	life -= delta
	var t : float = clamp(life / 5.0, 0.0, 1.0)
	modulate.a = t
	if life <= 0.0:
		queue_free()
