extends Resource
class_name Utils2D

static func wrap(pos: Vector2, view_size: Vector2) -> Vector2:
	var w := pos
	if w.x < 0.0: w.x += view_size.x
	elif w.x > view_size.x: w.x -= view_size.x
	if w.y < 0.0: w.y += view_size.y
	elif w.y > view_size.y: w.y -= view_size.y
	return w

static func sprite_radius(tex: Texture2D, scale_factor: float, shrink: float = 1.0) -> float:
	if tex == null: return 0.0
	var sz := tex.get_size() * scale_factor
	return min(sz.x, sz.y) * 0.5 * shrink

static func make_round_bullet_tex(
	d: int = 24,
	inner: Color = Color(1.0, 0.85, 0.40, 1.0), # yellow-orange
	outer: Color = Color(1.0, 0.20, 0.00, 1.0)  # red
) -> Texture2D:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	for y in d:
		for x in d:
			var p := Vector2(x + 0.5, y + 0.5) - Vector2(d, d) * 0.5
			var t: float = clamp(p.length() / (d * 0.5), 0.0, 1.0)
			var col := inner.lerp(outer, t)
			var a := 1.0 - pow(t, 1.6)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	return ImageTexture.create_from_image(img)
