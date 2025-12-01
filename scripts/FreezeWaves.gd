extends Node2D
class_name FreezeWaves

@export var speed: float = 380.0      # px/sec expansion
@export var width: float = 18.0       # ring thickness
@export var life: float = 1.8         # seconds until a ring dies

var _view_size := Vector2.ZERO
var _rings: Array = [] # each: {pos:Vector2, r:float, t:float}

func setup(view_size: Vector2) -> void:
	_view_size = view_size
	# nice additive look for the arc we draw
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat

func spawn(at: Vector2) -> void:
	_rings.append({"pos": at, "r": 0.0, "t": life})
	queue_redraw()

func get_rings() -> Array:
	return _rings

func get_width() -> float:
	return width

func hits_circle(center: Vector2, radius: float) -> bool:
	# ring–circle intersection
	for w in _rings:
		var d := center.distance_to(w.pos)
		var half := width * 0.5 + radius
		if d >= w.r - half and d <= w.r + half:
			return true
	return false

func _process(delta: float) -> void:
	if _rings.is_empty(): return
	var changed := false
	for i in range(_rings.size() - 1, -1, -1):
		var w = _rings[i]
		w.r += speed * delta
		w.t -= delta
		_rings[i] = w
		changed = true
		var max_r := _view_size.length() # larger than screen diagonal
		if w.t <= 0.0 or w.r > max_r:
			_rings.remove_at(i)
			changed = true
	if changed:
		queue_redraw()

func _draw() -> void:
	# draw each ring as an additive arc, fading with remaining life
	for w in _rings:
		var a : float = clamp(w.t / life, 0.0, 1.0)
		var col := Color(1.0, 0.95, 0.3, a) # warm yellow
		# point_count scales with radius to keep it smooth
		var pts : int = max(48, int(w.r * 0.35))
		draw_arc(w.pos, w.r, 0.0, TAU, pts, col, width, true)

func clear() -> void:
	_rings.clear()
	queue_redraw()
