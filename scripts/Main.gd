extends Node2D

@export var ship_scene: PackedScene
@export var ship_texture: Texture2D
@export var bullet_texture: Texture2D     # used by Factory (already set there)
@export var asteroid_texture: Texture2D  

enum GameState { TITLE, PLAYING, GAME_OVER }
var state: GameState = GameState.TITLE

## Runtime state variables
var debris_particles: Array = []  # List of active debris
var score
var wave_flags := {"W": false, "A": false, "V": false, "E": false}
var wave_ready: bool = false

var _bg: Background

var _nebula: Sprite2D
var _neb_scroll := Vector2.ZERO
var _stars: Starfield

@onready var ShipScene: PackedScene = preload("res://scenes/Ship.tscn")
@onready var ship: ShipNode = $Ship     
@onready var bullets: Bullets = $Bullets
@onready var asteroids: Asteroids = $Asteroids
@onready var collisions: CollisionSystem = $CollisionSystem
@onready var fire_timer: Timer = $AutoFireTimer
@onready var waves: FreezeWaves = $Waves

func _ready():
	ship.hide()
	randomize()
	await get_tree().process_frame
	ship.body_texture = ship_texture
	ship.fired.connect(_on_ship_fired)

	_bg = Background.new()
	add_child(_bg)                     # background behind gameplay
	_bg.z_index = -20            # gradient/stars base
	_build_nebula_layer()
	
	bullet_texture = Utils2D.make_round_bullet_tex(80)
	bullets.texture = bullet_texture
	
	# hook collision events
	collisions.bullet_hit_asteroid.connect(_on_bullet_hit_asteroid)
	collisions.ship_hit.connect(_on_ship_hit)
	
	$HUD.init_wave_ui()                 # creates the W A V E icons on HUD
	$HUD.set_wave_flags(wave_flags)     # start dim
	
	waves.setup(get_viewport_rect().size)

func _new_game():
	state = GameState.PLAYING
	_reset_game()
	var vp := get_viewport_rect().size
	ship.show()
	ship.reset_at(vp * 0.5)
	# Kick off asteroids with a safe bubble around ship
	var avoid := (ship.radius + asteroids.radius()) * 3.0
	asteroids.setup(vp, ship.global_position, avoid)
	$HUD.update_score(score)
	$HUD.show_message("Get Ready!")
	$Music.play()

func _reset_game():
	score = 0
	if fire_timer and not fire_timer.is_stopped():
		fire_timer.stop()
	bullets.clear()
	asteroids.clear()
	
	# Clear any floating letters still in the scene
	for n in get_tree().get_nodes_in_group("letters"):
		n.queue_free()

	# Reset collection state + HUD
	wave_flags = {"W": false, "A": false, "V": false, "E": false}
	wave_ready = false  
	$HUD.reset_wave_ui()
	$HUD.set_wave_flags(wave_flags)
	$HUD.set_wave_complete(false)
	
	if is_instance_valid(waves):
		waves.clear()         

func _process(delta: float):
	#Main game loop.  Handle input, integrate movement, perform
	#collision detection and schedule redraws.
	_handle_input()

	# Parallax scroll by the ship's actual velocity
	var v := ship.get_velocity()
	if is_instance_valid(_bg):
		_bg.scroll_by_velocity(v, delta)
	if is_instance_valid(_stars):
		_stars.scroll_by_velocity(v, delta)
	if is_instance_valid(_nebula):
		var parallax := 0.04
		var tex_sz := _nebula.texture.get_size()
		var vp_sz  := get_viewport_rect().size
		var world_to_tex := Vector2(tex_sz.x / vp_sz.x, tex_sz.y / vp_sz.y)
		_neb_scroll += -v * delta * parallax * world_to_tex
		var neb_mat := _nebula.material as ShaderMaterial
		if neb_mat:
			neb_mat.set_shader_parameter("u_scroll", _neb_scroll)
	
	# Subtle squash based on velocity along facing
	var facing := Vector2.RIGHT.rotated(ship.rotation)
	var accel_along := facing.dot(v)
	var squash: float = clamp(accel_along * 0.02, -0.12, 0.12)
	var body := ship.get_node_or_null("Body") as Sprite2D
	if body:
		body.scale = Vector2(1.0 + squash, 1.0 - squash)

	for i in range(debris_particles.size() - 1, -1, -1):
		var d = debris_particles[i]
		if !is_instance_valid(d.node):
			debris_particles.remove_at(i)
			continue
		d.node.global_position += d.vel * delta
		d.life -= delta
		d.node.scale *= 0.96
		d.node.modulate.a = d.life * 2.0
		if d.life <= 0.0:
			d.node.queue_free()
			debris_particles.remove_at(i)
	
	# letter pickups (ship touching letters)
	var sr := ship.radius
	var ship_pos := ship.global_position
	for n in get_tree().get_nodes_in_group("letters"):
		var L := n as FlyingLetter
		if L == null:
			continue
		if ship_pos.distance_to(L.global_position) <= sr + L.get_radius():
			_mark_letter(L.letter)
			L.queue_free()

func _handle_input():
	# Ignore everything if we’re not actually playing
	if state != GameState.PLAYING:
		return
		
	if Input.is_action_just_pressed("fire"):
		ship.request_fire()
		fire_timer.start()
	if Input.is_action_just_released("fire"):
		fire_timer.stop()

	if Input.is_action_just_pressed("pulse"):
		ship.pulse_outline()

	if Input.is_action_just_pressed("time_stop") and wave_ready:
		waves.spawn(ship.global_position)

@export var debug_draw_collision: bool = false

func _draw():
	if not debug_draw_collision: return
	draw_circle(ship.global_position, ship.radius, Color(1,0,0,0.3))
	for a in asteroids.items():
		draw_circle(a.pos, asteroids.radius(), Color(0,1,0,0.3))
	for b in bullets.items():
		draw_circle(b.pos, bullets.radius(), Color(1,1,0,0.3))

func _pulse_outline_emission():
	if is_instance_valid(ship):
		ship.call("pulse_outline")

func _spawn_debris(pos: Vector2):
	var count := randi() % 5 + 6
	for i in count:
		var d := Sprite2D.new()
		d.texture = bullets.texture            
		d.scale = Vector2(0.25, 0.25) * randf_range(0.5, 1.0)
		d.rotation = randf() * TAU
		d.global_position = pos
		d.modulate.a = 1.0
		var vel := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(60, 140)
		add_child(d)
		debris_particles.append({"node": d, "vel": vel, "life": 0.4 + randf() * 0.2})

func _build_nebula_layer():
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)

	_nebula = Sprite2D.new()
	_nebula.texture = tex
	_nebula.centered = false
	_nebula.modulate = Color(1,1,1,1)       # ensure not transparent
	_nebula.z_as_relative = false
	_nebula.z_index = -5                    # above Background, below stars/ship
	add_child(_nebula)

	var vp := get_viewport_rect().size
	_nebula.scale = vp / tex.get_size()     # stretch to screen

	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/nebula_background.gdshader")
	var noise_tex := load("res://shaders/nebula_noise.tres")
	mat.set_shader_parameter("noise_tex", noise_tex)
	mat.set_shader_parameter("u_scale", 1.6)
	mat.set_shader_parameter("u_coverage", 0.65)    # start a bit higher to verify
	mat.set_shader_parameter("u_softness", 0.08)
	mat.set_shader_parameter("u_intensity", 0.22)
	mat.set_shader_parameter("u_debug", false)      # set true once to sanity-check
	_nebula.material = mat

func _on_ship_fired(xform: Transform2D):
	if state != GameState.PLAYING:
		return
	bullets.spawn(xform)
	ship.pulse_outline()
	
func _on_bullet_hit_asteroid(at: Vector2, bullet_vel: Vector2):
	score += 1
	$HUD.update_score(score)
	
	# 60% chance to drop a flying wobbling letter
	if randf() < 0.60:
		_spawn_flying_letter(at)
	
	_spawn_debris(at)
	await FX.hit_stop(0.06, 0.3)
	await FX.screenshake(self, clamp(bullet_vel.length() * 0.01, 20.0, 10.0), 0.2)

func _on_ship_hit():
	state = GameState.GAME_OVER
	if fire_timer and not fire_timer.is_stopped():
		fire_timer.stop()
	ship.hide()
	$HUD.show_game_over(score)
	_reset_game()
	$Music.stop()
	$DeathSound.play()

func _on_auto_fire_timer_timeout():
	if state != GameState.PLAYING:
		return
	ship.request_fire()

func _spawn_flying_letter(at: Vector2) -> void:
	var letters := ["W", "A", "V", "E"]
	var L := FlyingLetter.new()
	L.letter = letters[randi() % letters.size()] 
	L.position = at
	L.vel = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(70.0, 120.0)
	L.z_index = 20 # above rocks
	add_child(L)

func _mark_letter(collected_letter: String) -> void:
	if not wave_flags.has(collected_letter):
		return
	if wave_flags[collected_letter]:
		return
		
	wave_flags[collected_letter] = true
	$HUD.set_wave_flags(wave_flags)
	
	if wave_flags["W"] and wave_flags["A"] and wave_flags["V"] and wave_flags["E"]:
		wave_ready = true
		$HUD.set_wave_complete(true)
		$HUD.show_message("WAVE READY! Press T to use ultimate!")
