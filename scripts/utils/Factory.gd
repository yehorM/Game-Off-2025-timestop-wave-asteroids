extends Resource
class_name Factory

static func make_bullet_node(
	at: Vector2, tex: Texture2D = null, parent: Node = null,
	scale: float = 0.1
) -> Node2D:
	if tex == null:
		tex = Utils2D.make_round_bullet_tex(80)
	var root := Node2D.new()
	root.global_position = at

	# --- sprite ---
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.scale = Vector2(scale, scale)

	var fire := Color(1.0, 0.35, 0.05, 1.0) # orange-red
	s.modulate = fire                      # tint the sprite

	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/additive_glow.gdshader")
	mat.set_shader_parameter("emission_strength", 3.0)
	mat.set_shader_parameter("base_on_right", false)    # bullets are centered; either is fine
	mat.set_shader_parameter("period", 0.35)            # faster flicker for bullets
	mat.set_shader_parameter("anim_amount", 0.9)
	mat.set_shader_parameter("heat", 0.3)               # base bias; will still oscillate
	mat.set_shader_parameter("t0", Time.get_ticks_msec() / 1000.0)  # unique per bullet
	s.material = mat

	root.add_child(s)

	if parent: parent.add_child(root)
	return root

static func make_asteroid_node(
	at: Vector2, tex: Texture2D, scale: float,
	wobble_amp: float = 0.0, wobble_freq: float = 10.0, wobble_speed: float = 1.0
) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.scale = Vector2(scale, scale)
	
	# Only attach wobble if requested
	if wobble_amp > 0.0:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/wobble_emissive.gdshader")
		mat.set_shader_parameter("freq", wobble_freq)
		mat.set_shader_parameter("speed", wobble_speed)
		mat.set_shader_parameter("amp", wobble_amp)
		s.material = mat
	
	s.global_position = at
	return s
