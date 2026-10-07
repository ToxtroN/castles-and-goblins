class_name SpriteLib
## Загрузка кадров анимаций: res://assets/{enemies|units}/<вид>/<анимация>_<N>.png
## Кадры уже выровнены по ногам (низ-центр картинки = точка стояния).

static var _cache := {}


static func frames(kind: String, anim: String) -> Array:
	var key := kind + "/" + anim
	if _cache.has(key):
		return _cache[key]
	var res: Array = []
	for folder in ["enemies", "units"]:
		for i in 32:
			var path := "res://assets/%s/%s/%s_%d.png" % [folder, kind, anim, i]
			if not ResourceLoader.exists(path):
				break
			res.append(load(path))
		if not res.is_empty():
			break
	_cache[key] = res
	return res


static func has(kind: String, anim: String) -> bool:
	return not frames(kind, anim).is_empty()


## Нарисовать кадр так, чтобы точка ног была в (0,0) с учётом масштаба и отражения.
static func draw_frame(ci: CanvasItem, tex: Texture2D, scale: float, flip: bool,
		offset: Vector2 = Vector2.ZERO, modulate: Color = Color.WHITE) -> void:
	var w := tex.get_width() * scale
	var h := tex.get_height() * scale
	ci.draw_set_transform(offset, 0, Vector2(-1 if flip else 1, 1))
	ci.draw_texture_rect(tex, Rect2(-w * 0.5, -h, w, h), false, modulate)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## Кадр по центру (для снарядов/эффектов).
static func draw_centered(ci: CanvasItem, tex: Texture2D, scale: float, pos: Vector2 = Vector2.ZERO,
		rot: float = 0.0, modulate: Color = Color.WHITE) -> void:
	var w := tex.get_width() * scale
	var h := tex.get_height() * scale
	ci.draw_set_transform(pos, rot, Vector2.ONE)
	ci.draw_texture_rect(tex, Rect2(-w * 0.5, -h * 0.5, w, h), false, modulate)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


static var _tex := {}


## Одиночная картинка (башни): res://assets/towers/<name>.png
static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		var path := "res://assets/towers/%s.png" % name
		_tex[name] = load(path) if ResourceLoader.exists(path) else null
	return _tex[name]
