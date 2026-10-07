class_name Art
## Процедурная графика: всё рисуется примитивами, без внешних ассетов.
## Позже можно заменить на спрайты — достаточно поменять функции draw_*.

const OUTLINE := Color(0.13, 0.1, 0.08)


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, seg: int = 24) -> void:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * i / seg
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)


static func ellipse_outline(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, w: float = 2.0) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var a := TAU * i / 24
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_polyline(pts, col, w, true)


static func shadow(ci: CanvasItem, c: Vector2, rx: float) -> void:
	ellipse(ci, c, rx, rx * 0.42, Color(0, 0, 0, 0.25))


static func circle_o(ci: CanvasItem, c: Vector2, r: float, col: Color, ow: float = 2.0) -> void:
	ci.draw_circle(c, r + ow, OUTLINE)
	ci.draw_circle(c, r, col)


static func rect_o(ci: CanvasItem, r: Rect2, col: Color, ow: float = 2.0) -> void:
	ci.draw_rect(r.grow(ow), OUTLINE)
	ci.draw_rect(r, col)


static func poly_o(ci: CanvasItem, pts: PackedVector2Array, col: Color, ow: float = 2.0) -> void:
	ci.draw_colored_polygon(pts, col)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, OUTLINE, ow, true)


static func hp_bar(ci: CanvasItem, c: Vector2, w: float, ratio: float) -> void:
	var r := Rect2(c.x - w * 0.5, c.y, w, 4)
	ci.draw_rect(r.grow(1), Color(0, 0, 0, 0.8))
	ci.draw_rect(r, Color(0.6, 0.1, 0.1))
	ci.draw_rect(Rect2(r.position, Vector2(w * clampf(ratio, 0, 1), 4)), Color(0.35, 0.9, 0.2))


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, width: float = -1, outline: int = 4) -> void:
	s = Loc.t(s)
	var f := ThemeDB.fallback_font
	var p := pos
	if align == HORIZONTAL_ALIGNMENT_CENTER and width < 0:
		width = 900
		p.x -= 450
	if outline > 0:
		ci.draw_string_outline(f, p, s, align, width, size, outline, OUTLINE)
	ci.draw_string(f, p, s, align, width, size, col)


# ---------------------------------------------------------------- БАШНИ
## Рисует башню с основанием в (0,0). Высота растёт вверх (отрицательный y).
static func tower_height(type: String, level: int) -> float:
	match type:
		"crossbow": return (110.0 + level * 10.0) * 1.2
		"mage": return (135.0 + level * 10.0) * 1.2
		"barracks": return (82.0 + level * 7.0) * 1.2
		_: return 72.0 + level * 5.0


## Нарисовать спрайт так, что его низ-центр в точке foot, высота h. Учитывает текущий transform.
static func sprite_at(ci: CanvasItem, tex: Texture2D, foot: Vector2, h: float, mod: Color = Color.WHITE) -> void:
	var w := h * tex.get_width() / tex.get_height()
	ci.draw_texture_rect(tex, Rect2(foot.x - w * 0.5, foot.y - h, w, h), false, mod)


## Рисует башню с основанием в (0,0). Высота растёт вверх (отрицательный y).
## Верх башни-арбалета (баллиста), который поворачивается; доля высоты спрайта.
const CROSSBOW_TOP := 0.24


static func draw_tower(ci: CanvasItem, type: String, level: int, t: float = 0.0, anim: float = 0.0,
		xf: Transform2D = Transform2D.IDENTITY, aim: float = 1.0) -> void:
	ci.draw_set_transform_matrix(xf)
	shadow(ci, Vector2(0, 8), 40)
	var tex := SpriteLib.tex(type)
	if tex != null:
		var h := tower_height(type, level)
		var squash := 1.0 - anim * 0.04
		if type == "crossbow" and absf(aim - 1.0) > 0.001:
			_crossbow_turned(ci, tex, Vector2(0, 14), h * squash, aim, xf)
		else:
			sprite_at(ci, tex, Vector2(0, 14), h * squash)
		if type == "mage":
			var glow := 0.25 + 0.15 * sin(t * 4.0) + anim * 0.4
			ci.draw_circle(Vector2(0, 14 - h * 0.9), 14.0 + anim * 8.0, Color(0.8, 0.5, 1.0, glow))
	elif type == "barracks":
		var base := SpriteLib.tex("base")
		if base != null:
			sprite_at(ci, base, Vector2(0, 16), 56)
			ci.draw_set_transform_matrix(xf * Transform2D(0, Vector2(0.72, 0.72), 0, Vector2(0, -18)))
			_barracks(ci, level, t)
			ci.draw_set_transform_matrix(xf)
		else:
			ellipse(ci, Vector2(0, 0), 30, 12, Color(0.62, 0.58, 0.52))
			_barracks(ci, level, t)
	else:
		ellipse(ci, Vector2(0, 0), 30, 12, Color(0.62, 0.58, 0.52))
		match type:
			"archer": _archer(ci, level, anim)
			"artillery": _artillery(ci, level, anim)
	# уровень башни цифрой под ней
	circle_o(ci, Vector2(0, 26), 11, Color(0.25, 0.16, 0.08), 2)
	ci.draw_arc(Vector2(0, 26), 11, 0, TAU, 24, Color(1, 0.8, 0.3), 2)
	text(ci, Vector2(0, 33), str(level + 1), 17, Color(1, 0.88, 0.4), HORIZONTAL_ALIGNMENT_CENTER, -1, 3)


static func _archer(ci: CanvasItem, lv: int, anim: float) -> void:
	var h := lv * 7.0
	var wood := Color(0.55, 0.36, 0.2)
	var wood_d := Color(0.4, 0.25, 0.13)
	# опоры
	rect_o(ci, Rect2(-22, -44 - h, 7, 44 + h), wood_d)
	rect_o(ci, Rect2(15, -44 - h, 7, 44 + h), wood_d)
	ci.draw_line(Vector2(-16, -8), Vector2(15, -38 - h), wood_d, 4)
	ci.draw_line(Vector2(15, -8), Vector2(-16, -38 - h), wood_d, 4)
	# площадка
	rect_o(ci, Rect2(-27, -66 - h, 54, 22), wood)
	for i in 5:
		ci.draw_line(Vector2(-27 + i * 11, -66 - h), Vector2(-27 + i * 11, -44 - h), wood_d, 1.5)
	rect_o(ci, Rect2(-29, -48 - h, 58, 6), wood_d)
	# лучники
	var bob := -2.0 if anim > 0 else 0.0
	for x in [-10.0, 10.0]:
		circle_o(ci, Vector2(x, -72 - h + bob), 6, Color(0.25, 0.55, 0.25))
		ci.draw_circle(Vector2(x, -71 - h + bob), 3.5, Color(0.95, 0.78, 0.6))
		ci.draw_arc(Vector2(x + 5, -72 - h + bob), 7, -1.2, 1.2, 8, wood_d, 2)
	if lv >= 2:
		ci.draw_line(Vector2(24, -66 - h), Vector2(24, -96 - h), wood_d, 2)
		poly_o(ci, PackedVector2Array([Vector2(24, -96 - h), Vector2(40, -91 - h), Vector2(24, -86 - h)]),
			Color(0.85, 0.2, 0.2), 1.5)


static func _barracks(ci: CanvasItem, lv: int, t: float) -> void:
	var stone := Color(0.78, 0.76, 0.72)
	var roof_cols := [Color(0.3, 0.45, 0.75), Color(0.22, 0.35, 0.7), Color(0.18, 0.25, 0.6)]
	var h := lv * 5.0
	rect_o(ci, Rect2(-27, -42 - h, 54, 42 + h), stone)
	for y in range(int(-42 - h) + 9, 0, 9):
		ci.draw_line(Vector2(-27, y), Vector2(27, y), Color(0.6, 0.58, 0.54), 1)
	# дверь
	rect_o(ci, Rect2(-8, -20, 16, 20), Color(0.35, 0.22, 0.12))
	ci.draw_circle(Vector2(0, -20), 8, Color(0.35, 0.22, 0.12))
	# окна-бойницы
	for x in [-17.0, 17.0]:
		ci.draw_rect(Rect2(x - 2, -32 - h, 4, 9), Color(0.15, 0.12, 0.1))
	# крыша
	var roof := PackedVector2Array([Vector2(-34, -40 - h), Vector2(34, -40 - h), Vector2(0, -76 - h * 1.5)])
	poly_o(ci, roof, roof_cols[lv])
	if lv >= 1:
		ci.draw_line(Vector2(-34, -40 - h), Vector2(0, -76 - h * 1.5), Color(1, 0.82, 0.2), 2)
		ci.draw_line(Vector2(34, -40 - h), Vector2(0, -76 - h * 1.5), Color(1, 0.82, 0.2), 2)
	# флаг
	var top := Vector2(0, -76 - h * 1.5)
	ci.draw_line(top, top + Vector2(0, -22), OUTLINE, 2)
	var wave := sin(t * 5.0) * 3.0
	poly_o(ci, PackedVector2Array([top + Vector2(1, -22), top + Vector2(17, -18 + wave), top + Vector2(1, -13)]),
		Color(0.9, 0.2, 0.2), 1.5)


static func _mage(ci: CanvasItem, lv: int, t: float, anim: float) -> void:
	var h := lv * 7.0
	var stone := Color(0.55, 0.52, 0.68)
	rect_o(ci, Rect2(-19, -58 - h, 38, 58 + h), stone)
	for y in range(int(-58 - h) + 10, 0, 10):
		ci.draw_line(Vector2(-19, y), Vector2(19, y), Color(0.45, 0.42, 0.58), 1)
	# руна
	var glow := 0.6 + 0.4 * sin(t * 3.0)
	ci.draw_rect(Rect2(-5, -38 - h, 10, 14), Color(0.75, 0.4, 1.0, glow))
	# крыша-конус
	var roof := PackedVector2Array([Vector2(-26, -56 - h), Vector2(26, -56 - h), Vector2(0, -98 - h)])
	poly_o(ci, roof, Color(0.45, 0.2, 0.65))
	if lv >= 1:
		ci.draw_line(Vector2(-20, -64 - h), Vector2(20, -64 - h), Color(1, 0.82, 0.2), 2)
	# сфера
	var orb := Vector2(0, -104 - h)
	var pulse := 1.0 + anim * 4.0
	ci.draw_circle(orb, 10 * pulse, Color(0.8, 0.5, 1.0, 0.25))
	circle_o(ci, orb, 5.5, Color(0.85, 0.7, 1.0), 1.5)
	if lv >= 2:
		for i in 3:
			var a := t * 2.0 + i * TAU / 3.0
			ci.draw_circle(orb + Vector2(cos(a) * 13, sin(a) * 5), 2.5, Color(0.7, 0.9, 1.0))


static func _artillery(ci: CanvasItem, lv: int, anim: float) -> void:
	ellipse(ci, Vector2(0, -8), 30, 20, Art.OUTLINE)
	ellipse(ci, Vector2(0, -9), 28, 18, Color(0.6, 0.55, 0.5))
	ellipse(ci, Vector2(0, -18), 25, 12, Color(0.72, 0.68, 0.62))
	for i in 6:
		var a := i * TAU / 6.0
		ci.draw_rect(Rect2(Vector2(cos(a) * 24 - 3, -18 + sin(a) * 11 - 4), Vector2(6, 6)), Color(0.5, 0.46, 0.42))
	var r := 10.0 + lv * 2.0
	var recoil := anim * 6.0
	var muzzle := Vector2(0, -30 + recoil)
	ellipse(ci, Vector2(0, -20), r + 2, r * 0.7, Art.OUTLINE)
	ellipse(ci, Vector2(0, -21), r, r * 0.6, Color(0.3, 0.3, 0.33))
	ci.draw_line(Vector2(0, -20), muzzle, Color(0.3, 0.3, 0.33), r * 1.3)
	ellipse(ci, muzzle, r * 0.75, r * 0.45, Color(0.08, 0.08, 0.1))
	if lv >= 1:
		ci.draw_arc(Vector2(0, -20), r + 1, PI, TAU, 12, Color(1, 0.82, 0.2), 2)
	for p in [Vector2(20, -2), Vector2(26, -2), Vector2(23, -7)]:
		circle_o(ci, p, 3.5, Color(0.15, 0.15, 0.17), 1)


## Корпус башни рисуется как есть, а баллиста сверху — с отражением по горизонтали (aim: 1 влево … -1 вправо).
static func _crossbow_turned(ci: CanvasItem, tex: Texture2D, foot: Vector2, h: float, aim: float, xf: Transform2D) -> void:
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var w := h * tw / th
	var cut := th * CROSSBOW_TOP
	var top_h := h * CROSSBOW_TOP
	var y0 := foot.y - h
	# корпус
	ci.draw_texture_rect_region(tex, Rect2(foot.x - w * 0.5, y0 + top_h, w, h - top_h), Rect2(0, cut, tw, th - cut))
	# баллиста: масштаб по x = aim вокруг центра башни
	ci.draw_set_transform_matrix(xf * Transform2D(0, Vector2(aim, 1), 0, Vector2(foot.x, 0)))
	ci.draw_texture_rect_region(tex, Rect2(-w * 0.5, y0, w, top_h + 0.5), Rect2(0, 0, tw, cut + 0.5))
	ci.draw_set_transform_matrix(xf)


static func draw_slot(ci: CanvasItem, p: Vector2) -> void:
	var base := SpriteLib.tex("base")
	if base != null:
		shadow(ci, p + Vector2(0, 10), 40)
		sprite_at(ci, base, p + Vector2(0, 16), 56)
		return
	ellipse(ci, p + Vector2(0, 3), 32, 15, Color(0.42, 0.3, 0.18))
	ellipse(ci, p, 30, 13, Color(0.6, 0.45, 0.28))


# ---------------------------------------------------------------- ИКОНКИ
static func megaphone(ci: CanvasItem, center: Vector2, on: bool, k: float = 1.0) -> void:
	var c := center + Vector2(-6, 0) * k
	var gold := Color(1, 0.88, 0.55)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -5) * k, c + Vector2(6, -14) * k,
		c + Vector2(6, 14) * k, c + Vector2(-10, 5) * k]), gold)
	ci.draw_rect(Rect2(c + Vector2(-15, -5) * k, Vector2(6, 10) * k), gold)
	ci.draw_line(c + Vector2(-6, 5) * k, c + Vector2(-3, 13) * k, gold, 3 * k)
	if on:
		for i in 2:
			ci.draw_arc(c + Vector2(8, 0) * k, (7 + i * 6) * k, -0.8, 0.8, 10, gold, 2.5 * k)
	else:
		ci.draw_line(center + Vector2(-16, -16) * k, center + Vector2(16, 16) * k, OUTLINE, 6 * k)
		ci.draw_line(center + Vector2(-16, -16) * k, center + Vector2(16, 16) * k, Color(1, 0.3, 0.25), 3.5 * k)


## Картинки интерфейса (assets/ui): сердце и звезда.
static var _ui := {}   # держим ссылки, иначе текстура освободится до отрисовки


static func ui_tex(name: String) -> Texture2D:
	if Loc.is_en() and ResourceLoader.exists("res://assets/ui/%s_en.png" % name):
		name += "_en"   # английская версия картинки с надписью
	if not _ui.has(name):
		var path := "res://assets/ui/%s.png" % name
		_ui[name] = load(path) if ResourceLoader.exists(path) else null
	return _ui[name]


## Звезда по центру c высотой h. on=false — тёмный силуэт.
static func star_icon(ci: CanvasItem, c: Vector2, h: float, on: bool, alpha: float = 1.0) -> void:
	var tex := ui_tex("star")
	if tex == null:
		return
	var w := h * tex.get_width() / tex.get_height()
	var mod := Color(1, 1, 1, alpha) if on else Color(0.08, 0.06, 0.05, 0.75 * alpha)
	ci.draw_texture_rect(tex, Rect2(c.x - w * 0.5, c.y - h * 0.5, w, h), false, mod)


static func icon_heart(ci: CanvasItem, c: Vector2, s: float) -> void:
	var tex := ui_tex("heart")
	if tex != null:
		var h := s * 3.2
		var w := h * tex.get_width() / tex.get_height()
		ci.draw_texture_rect(tex, Rect2(c.x - w * 0.5, c.y - h * 0.5, w, h), false)
		return
	ci.draw_circle(c + Vector2(-s * 0.45, -s * 0.2), s * 0.55, Color(0.9, 0.15, 0.2))
	ci.draw_circle(c + Vector2(s * 0.45, -s * 0.2), s * 0.55, Color(0.9, 0.15, 0.2))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s, 0), c + Vector2(s, 0), c + Vector2(0, s)]),
		Color(0.9, 0.15, 0.2))


static func icon_coin(ci: CanvasItem, c: Vector2, s: float) -> void:
	circle_o(ci, c, s, Color(1, 0.8, 0.2), 1.5)
	ci.draw_circle(c, s * 0.55, Color(0.9, 0.65, 0.1))


static func icon_skull(ci: CanvasItem, c: Vector2, s: float, col: Color = Color(0.92, 0.9, 0.85)) -> void:
	ci.draw_circle(c, s, col)
	ci.draw_rect(Rect2(c + Vector2(-s * 0.5, s * 0.5), Vector2(s, s * 0.6)), col)
	ci.draw_circle(c + Vector2(-s * 0.4, 0), s * 0.28, OUTLINE)
	ci.draw_circle(c + Vector2(s * 0.4, 0), s * 0.28, OUTLINE)
