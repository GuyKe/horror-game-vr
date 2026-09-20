class_name ProceduralTextures
extends RefCounted
## Runtime-generated textures (radial glow sprites, grid floor) so the
## project ships with zero image assets, matching the reference project's
## canvas-drawn textures.

## A soft radial gradient from inner_color at the center to outer_color
## (usually transparent) at the edge, used for the sun glow, flame and
## ember sprites.
static func glow_texture(size: int, inner_color: Color, outer_color: Color) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var radius := size / 2.0
	for y in size:
		for x in size:
			var dist := Vector2(x, y).distance_to(center) / radius
			var c := inner_color.lerp(outer_color, clampf(dist, 0.0, 1.0))
			image.set_pixel(x, y, c)
	return ImageTexture.create_from_image(image)


## A rounded rectangle, optionally outlined, used for menu panel/button
## backgrounds (approximating the reference project's hand-drawn canvas UI).
static func rounded_rect_texture(width: int, height: int, radius: float, fill_color: Color, border_color: Color = Color(0, 0, 0, 0), border_width: float = 0.0) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in height:
		for x in width:
			var d := _rounded_rect_sdf(Vector2(x, y), Vector2(width, height), radius)
			if d > 0.0:
				continue
			var c := fill_color
			if border_width > 0.0 and d > -border_width:
				c = border_color
			image.set_pixel(x, y, c)
	return ImageTexture.create_from_image(image)


## Signed distance (in pixels) from a point to a rounded rect's edge;
## negative = inside.
static func _rounded_rect_sdf(p: Vector2, size: Vector2, radius: float) -> float:
	var half := size / 2.0
	var center_p := p - half
	var q := Vector2(absf(center_p.x), absf(center_p.y)) - (half - Vector2(radius, radius))
	var outside := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length()
	var inside := minf(maxf(q.x, q.y), 0.0)
	return outside + inside - radius


## A flat color with a light grid overlay, used for the tutorial baseplate.
static func grid_texture(size: int, base_color: Color, line_color: Color, divisions: int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(base_color)
	var step := size / float(divisions)
	for i in range(divisions + 1):
		var p := int(i * step)
		for k in size:
			image.set_pixel(clampi(p, 0, size - 1), k, line_color)
			image.set_pixel(k, clampi(p, 0, size - 1), line_color)
	return ImageTexture.create_from_image(image)
