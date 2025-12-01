extends Node2D
class_name Starfield

@export var area: Vector2 = Vector2(2048, 2048) # tiling area
@export var star_count: int = 420
@export var parallax: float = 0.25
@export var twinkle_speed: float = 1.6
@export var size_range: Vector2 = Vector2(1.0, 2.2)
@export var color_tint: Color = Color(1, 1, 1, 1)

var _scroll: Vector2 = Vector2.ZERO
var _twinkle_accum: float = 0.0

func _ready() -> void:
	randomize()
	
	# On web, cut the amount to reduce draw calls
	if OS.has_feature("HTML5"):
		star_count = 200  # was 420
	
	_regen()
	set_process(true)

class Star:
	var p: Vector2
	var r: float
	var b: float
	var phase: float

var _stars: Array[Star] = []

func _regen():
	_stars.clear()
	for i in star_count:
		var s := Star.new()
		s.p = Vector2(randf()*area.x, randf()*area.y)
		s.r = randf_range(size_range.x, size_range.y)
		s.b = randf_range(0.65, 1.0)
		s.phase = randf()*TAU
		_stars.append(s)

func _draw():
	var t: float = Time.get_ticks_msec() * 0.001
	for s in _stars:
		var p: Vector2 = s.p + _scroll
		var pos := Vector2(fposmod(p.x, area.x), fposmod(p.y, area.y))
		var tw := 0.72 + 0.28 * sin(t*twinkle_speed + s.phase)
		draw_circle(pos, s.r, Color(color_tint.r, color_tint.g, color_tint.b, tw*s.b))

func scroll_by_velocity(vel: Vector2, delta: float) -> void:
	_scroll += -vel * delta * parallax
	_scroll.x = fposmod(_scroll.x, area.x)
	_scroll.y = fposmod(_scroll.y, area.y)
	queue_redraw()

func _process(delta: float) -> void:
	if OS.has_feature("HTML5"):
		# Only redraw for twinkle ~12 times per second instead of every frame
		_twinkle_accum += delta
		if _twinkle_accum >= 0.08:
			_twinkle_accum = 0.0
			queue_redraw()
	else:
		# Native: keep it full quality
		queue_redraw()
