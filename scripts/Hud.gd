extends CanvasLayer

# Notifies `Main` node that the button has been pressed
signal start_game

# === WAVE HUD ===
var _wave_letters := ["W","A","V","E"]
var _wave_nodes: Array[Sprite2D] = []  # Sprite2D per letter
var _wave_complete := false

var _wave_outline_spr: Sprite2D
var _wave_outline_vp: SubViewport

func show_message(text):
	$Message.text = text
	if text == "Get Ready!":
		$Message.position.y = 135
	else:
		$Message.position.y = 204
	if text == "WAVE READY! Press T to use ultimate!":
		$MessageTimer.wait_time = 5
	else:
		$MessageTimer.wait_time = 2
	$Message.show()
	$MessageTimer.start()

func show_game_over(prevScore):
	show_message("Game Over")
	$ScoreLabel.text = "Your score was: " + str(prevScore)
	# Wait until the MessageTimer has counted down.
	await $MessageTimer.timeout

	$Message.text = "Collect the waves"
	$Message.show()
	# Make a one-shot timer and wait for it to finish.
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()
	$Message.hide()

func update_score(score):
	$ScoreLabel.text = str(score)

func _on_start_button_pressed():
	$StartButton.hide()
	start_game.emit()

func _on_message_timer_timeout():
	$Message.hide()

func init_wave_ui(font_size: int = 48) -> void:
	if _wave_nodes.size() > 0:
		return

	var ff: FontFile = load("res://fonts/Xolonium-Regular.ttf")
	var gap := 8
	var tile := Vector2i(Vector2(font_size * 1.2, font_size * 1.2))
	var total_w := 0

	# per-letter sprites (stay additive_glow)
	for ch in _wave_letters:
		var vp := SubViewport.new()
		vp.disable_3d = true
		vp.transparent_bg = true
		vp.size = tile

		var lbl := Label.new()
		lbl.text = ch
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", ff)
		lbl.add_theme_font_size_override("font_size", font_size)
		lbl.size = tile
		vp.add_child(lbl)

		var spr := Sprite2D.new()
		spr.centered = false
		spr.texture = vp.get_texture()

		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/additive_glow.gdshader")
		mat.set_shader_parameter("emission_strength", 0.0)  # off until collected
		mat.set_shader_parameter("base_on_right", false)
		mat.set_shader_parameter("mid", 0.5)
		mat.set_shader_parameter("falloff", 0.0)
		mat.set_shader_parameter("anim_amount", 0.0)
		spr.material = mat

		add_child(spr)
		_wave_nodes.append(spr)
		spr.add_child(vp)  # keep viewport alive

		total_w += tile.x
		if ch != "E":
			total_w += gap

	# ONE outline sprite for the whole word (behind letters)
	_wave_outline_vp = SubViewport.new()
	_wave_outline_vp.disable_3d = true
	_wave_outline_vp.transparent_bg = true
	_wave_outline_vp.size = Vector2i(total_w, tile.y)

	var container := Control.new()
	container.size = _wave_outline_vp.size
	_wave_outline_vp.add_child(container)

	var x := 0
	for ch in _wave_letters:
		var l := Label.new()
		l.text = ch
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", ff)
		l.add_theme_font_size_override("font_size", font_size)
		l.position = Vector2(x, 0)
		l.size = Vector2(tile)
		container.add_child(l)

		x += tile.x
		if ch != "E":
			x += gap

	_wave_outline_spr = Sprite2D.new()
	_wave_outline_spr.centered = false
	_wave_outline_spr.texture = _wave_outline_vp.get_texture()

	var omat := ShaderMaterial.new()
	omat.shader = load("res://shaders/glow_outline.gdshader")
	omat.set_shader_parameter("outline_width", 2.0)
	omat.set_shader_parameter("emission_strength", 0.0)  # off until complete
	_wave_outline_spr.material = omat
	add_child(_wave_outline_spr)
	# keep the outline viewport alive & rendering
	add_child(_wave_outline_vp)
	_wave_outline_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# layering: outline behind letters
	_wave_outline_spr.z_index = 999
	for spr in _wave_nodes:
		spr.z_index = 1000

	# place row at top-center + outline
	_position_wave_ui(total_w, gap)

	# reposition on window resize
	if not get_viewport().is_connected("size_changed", Callable(self, "_on_vp_resize")):
		get_viewport().connect("size_changed", Callable(self, "_on_vp_resize"))

func _on_vp_resize():
	# recompute layout
	var gap := 8
	var total_w := 0
	for spr in _wave_nodes:
		total_w += int(spr.texture.get_width())
	total_w += gap * (_wave_nodes.size() - 1)
	_position_wave_ui(total_w, gap)

func _position_wave_ui(total_w: int, gap: int) -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var start_x := int((vp.x - total_w) / 2)
	var y := 52

	# outline sprite top-left
	if _wave_outline_spr:
		_wave_outline_spr.position = Vector2(start_x, y)

	# letters
	var x := start_x
	for spr in _wave_nodes:
		spr.position = Vector2(x, y)
		x += spr.texture.get_width() + gap
		spr.z_index = 1000

func set_wave_flags(flags: Dictionary) -> void:
	if _wave_complete:   # once complete, don't downgrade emission back to per-letter
		return
	if _wave_nodes.size() != _wave_letters.size():
		return
	var all_ok := true
	for i in range(_wave_letters.size()):
		var collected := bool(flags.get(_wave_letters[i], false))
		var spr: Sprite2D = _wave_nodes[i]
		var mat := spr.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("emission_strength", 1.6 if collected else 0.0)
			mat.set_shader_parameter("anim_amount", 0.0)
		spr.modulate = Color(1,1,1,1) if collected else Color(0.6,0.6,0.6,1)
		all_ok = all_ok and collected
	if all_ok:
		set_wave_complete(true)

var _wave_pulse: Tween

func set_wave_complete(on: bool) -> void:
	if on: print("WAVE COMPLETE at ", Time.get_ticks_msec())
	_wave_complete = on

	if _wave_pulse and _wave_pulse.is_valid():
		_wave_pulse.kill()

	if on:
		# baseline bright + warm flicker on letters
		for spr in _wave_nodes:
			var mat := spr.material as ShaderMaterial
			if mat:
				mat.set_shader_parameter("emission_strength", 4.0)
				mat.set_shader_parameter("anim_amount", 0.7)
			spr.modulate = Color(1,1,1,1)

		# outline on
		if _wave_outline_spr:
			var omat := _wave_outline_spr.material as ShaderMaterial
			if omat:
				omat.set_shader_parameter("emission_strength", 2.2)

		# one-shot flash
		_flash_wave_once()

		# continuous parallel pulse
		_wave_pulse = create_tween().set_loops().set_parallel()
		for spr in _wave_nodes:
			var mat := spr.material as ShaderMaterial
			if not mat: continue
			_wave_pulse.tween_property(mat, "shader_parameter/emission_strength", 6.0, 0.45)
			_wave_pulse.tween_property(mat, "shader_parameter/emission_strength", 3.2, 0.45)
			_wave_pulse.tween_property(spr, "scale", Vector2(1.12, 1.12), 0.45)
			_wave_pulse.tween_property(spr, "scale", Vector2(1.00, 1.00), 0.45)

		if _wave_outline_spr:
			var om := _wave_outline_spr.material as ShaderMaterial
			if om:
				_wave_pulse.tween_property(om, "shader_parameter/emission_strength", 3.4, 0.45)
				_wave_pulse.tween_property(om, "shader_parameter/emission_strength", 2.0, 0.45)
	else:
		for spr in _wave_nodes:
			var mat := spr.material as ShaderMaterial
			if mat:
				mat.set_shader_parameter("emission_strength", 0.0)
				mat.set_shader_parameter("anim_amount", 0.0)
			spr.scale = Vector2.ONE
		if _wave_outline_spr:
			var om := _wave_outline_spr.material as ShaderMaterial
			if om:
				om.set_shader_parameter("emission_strength", 0.0)

# Clear WAVE UI back to "not collected"
func reset_wave_ui() -> void:
	_wave_complete = false
	if _wave_pulse and _wave_pulse.is_valid():
		_wave_pulse.kill()
	for spr in _wave_nodes:
		if spr == null: continue
		spr.modulate = Color(0.6, 0.6, 0.6, 1.0)
		var mat := spr.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("emission_strength", 0.0)
			mat.set_shader_parameter("anim_amount", 0.0)
	if _wave_outline_spr:
		var om := _wave_outline_spr.material as ShaderMaterial
		if om:
			om.set_shader_parameter("emission_strength", 0.0)
		_wave_outline_spr.scale = Vector2.ONE

func _ready() -> void:
	# Make this CanvasLayer render above anything else that might exist
	if layer < 50:
		layer = 50

func _flash_wave_once() -> void:
	# super-obvious one-shot pop (scale + bright)
	var t := create_tween().set_parallel()
	for spr in _wave_nodes:
		var mat := spr.material as ShaderMaterial
		if mat:
			t.tween_property(mat, "shader_parameter/emission_strength", 7.0, 0.08)
			t.tween_property(mat, "shader_parameter/emission_strength", 4.0, 0.20)
		t.tween_property(spr, "scale", Vector2(1.25, 1.25), 0.08)
		t.tween_property(spr, "scale", Vector2(1.00, 1.00), 0.20)

	if _wave_outline_spr:
		var om := _wave_outline_spr.material as ShaderMaterial
		if om:
			t.tween_property(om, "shader_parameter/emission_strength", 4.0, 0.08)
			t.tween_property(om, "shader_parameter/emission_strength", 2.2, 0.20)
