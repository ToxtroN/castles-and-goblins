extends Node2D
## Экран «Улучшения»: карточки башен и героев, покупка за звёзды.

const R_BACK := Rect2(24, 20, 64, 64)
const R_KING := Rect2(1046, 28, 210, 58)
const R_PANEL := Rect2(300, 110, 680, 520)
var kingdom_open := false
const CARD := Vector2(214, 370)

var bg: Texture2D
var music: AudioStreamPlayer
var t := 0.0
var flash := {}      # id -> время вспышки после покупки
var msg := ""
var msg_t := 0.0
var as_overlay := false   # открыт поверх экрана итогов боя


func _ready() -> void:
	bg = load("res://assets/splash_bg.png")
	music = AudioStreamPlayer.new()
	var st: AudioStream = load("res://assets/splash_music.mp3")
	if st is AudioStreamMP3:
		st.loop = true
	music.stream = st
	add_child(music)
	if not as_overlay:
		music.play()


func card_rect(i: int) -> Rect2:
	var n := Shop.ITEMS.size()
	var gap := 24.0
	var x0 := 640.0 - (n * CARD.x + (n - 1) * gap) * 0.5
	return Rect2(x0 + i * (CARD.x + gap), 228, CARD.x, CARD.y)


func buy_rect(i: int) -> Rect2:
	var r := card_rect(i)
	return Rect2(r.position.x + 22, r.end.y - 62, r.size.x - 44, 46)


func _process(delta: float) -> void:
	t += delta
	msg_t = maxf(0.0, msg_t - delta)
	for k in flash.keys():
		flash[k] -= delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if as_overlay and (event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch):
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_back()
		return
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if not pressed:
		return
	var p := get_global_mouse_position()
	if kingdom_open:
		kingdom_open = false
		return
	if R_BACK.has_point(p):
		_back()
		return
	if R_KING.has_point(p):
		kingdom_open = true
		return
	for i in Shop.ITEMS.size():
		if buy_rect(i).has_point(p) or card_rect(i).has_point(p):
			var it: Dictionary = Shop.ITEMS[i]
			if Shop.owned(it.id):
				if Shop.upgrade_cost(it.id) < 0:
					return
				if Shop.upgrade(it.id):
					flash[it.id] = 0.8
					msg = "%s — уровень %d!" % [it.name, Shop.level_of(it.id)]
				else:
					msg = "Не хватает монет: нужно %d" % Shop.upgrade_cost(it.id)
				msg_t = 2.0
				return
			if Shop.buy(it.id):
				flash[it.id] = 0.8
				msg = "%s — куплено!" % it.name
			else:
				msg = "Не хватает звёзд: нужно %d" % it.price
			msg_t = 2.0
			return


func _back() -> void:
	if kingdom_open:
		kingdom_open = false
		return
	if as_overlay:
		get_parent().get_parent().close_upgrades()
		return
	get_tree().change_scene_to_file.call_deferred("res://scenes/level_select.tscn")


# ---------------------------------------------------------------- ОТРИСОВКА
func _draw() -> void:
	if as_overlay:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.05, 0.03, 0.02, 0.88))
	else:
		draw_texture_rect(bg, Rect2(0, 0, 1280, 720), false)
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.35))
	var title := Art.ui_tex("btn_upgrades")
	if title:
		var h := 120.0
		var w := h * title.get_width() / title.get_height()
		draw_texture_rect(title, Rect2(640 - w * 0.5, 22, w, h), false)
	# звёзды и монеты
	var sr := Rect2(400, 150, 230, 50)
	var cr := Rect2(650, 150, 230, 50)
	for rr in [sr, cr]:
		draw_rect(rr.grow(3), Color(0.08, 0.05, 0.04, 0.9))
		draw_rect(rr, Color(0.25, 0.17, 0.1, 0.95))
	Art.star_icon(self, sr.position + Vector2(30, 25), 40, true)
	Art.text(self, sr.position + Vector2(58, 34), "%d свободно" % Shop.stars_free(), 22, Color(1, 0.88, 0.45),
		HORIZONTAL_ALIGNMENT_LEFT, 170)
	_coin(cr.position + Vector2(30, 25), 16)
	Art.text(self, cr.position + Vector2(58, 34), "%d монет" % Shop.coins(), 22, Color(1, 0.88, 0.45),
		HORIZONTAL_ALIGNMENT_LEFT, 170)
	for i in Shop.ITEMS.size():
		_card(i)
	# заголовки групп
	Art.text(self, Vector2(card_rect(0).get_center().x + 119, 220), "БАШНИ", 18, Color(0.9, 0.85, 0.7))
	Art.text(self, Vector2(card_rect(3).get_center().x, 220), "ГЕРОИ", 18, Color(0.9, 0.85, 0.7))
	Art.text(self, Vector2(640, 625), "Звёзды — покупка новых башен и героев. Монеты за бои — прокачка до 5 уровня.",
		15, Color(0.9, 0.9, 0.85))
	if msg_t > 0.0:
		Art.text(self, Vector2(640, 668), msg, 24, Color(1, 0.9, 0.5, minf(1.0, msg_t * 2.0)), HORIZONTAL_ALIGNMENT_CENTER, -1, 6)
	_back_btn()
	_king_btn()
	if kingdom_open:
		_kingdom_panel()


func _king_btn() -> void:
	var r := R_KING
	var hov := r.has_point(get_global_mouse_position())
	if hov:
		r = r.grow(3)
	draw_rect(r.grow(3), Color(0.08, 0.05, 0.04))
	draw_rect(r, Color(0.45, 0.16, 0.12) if hov else Color(0.36, 0.12, 0.09))
	draw_rect(r.grow(-4), Color(1, 0.8, 0.35, 0.8), false, 2)
	_crown(r.position + Vector2(30, 31), 1.0)
	Art.text(self, r.position + Vector2(56, 27), "КОРОЛЕВСТВО", 16, Color(1, 0.9, 0.6), HORIZONTAL_ALIGNMENT_LEFT, 150)
	var ng := Kingdom.next_goal()
	var sub := "все бонусы открыты" if ng.is_empty() else "след.: %d★" % int(ng.stars)
	Art.text(self, r.position + Vector2(56, 47), sub, 13, Color(0.95, 0.85, 0.7), HORIZONTAL_ALIGNMENT_LEFT, 150)


func _crown(c: Vector2, k: float) -> void:
	var pts := PackedVector2Array([c + Vector2(-15, 8) * k, c + Vector2(-15, -8) * k, c + Vector2(-8, 0) * k,
		c + Vector2(0, -12) * k, c + Vector2(8, 0) * k, c + Vector2(15, -8) * k, c + Vector2(15, 8) * k])
	Art.poly_o(self, pts, Color(1, 0.8, 0.2), 2)
	draw_circle(c + Vector2(0, 3) * k, 2.5 * k, Color(0.85, 0.15, 0.15))


func _kingdom_panel() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.6))
	var r := R_PANEL
	draw_rect(r.grow(4), Color(0.08, 0.05, 0.03))
	draw_rect(r, Color(0.24, 0.17, 0.11))
	draw_rect(r.grow(-7), Color(0.9, 0.7, 0.3, 0.7), false, 2)
	_crown(Vector2(640, r.position.y + 34), 1.4)
	Art.text(self, Vector2(640, r.position.y + 78), "КОРОЛЕВСТВО", 28, Color(1, 0.88, 0.5))
	var total := Shop.stars_total()
	Art.text(self, Vector2(640, r.position.y + 104), "Собрано звёзд: %d из %d. Бонусы действуют во всех боях." % [total, Levels.count() * 3],
		15, Color(0.92, 0.88, 0.8))
	for i in GameData.KINGDOM.size():
		var k: Dictionary = GameData.KINGDOM[i]
		var got: bool = total >= int(k.stars)
		var row := Rect2(r.position.x + 30, r.position.y + 124 + i * 52, r.size.x - 60, 44)
		draw_rect(row, Color(0.2, 0.36, 0.16, 0.95) if got else Color(0.16, 0.12, 0.09, 0.95))
		draw_rect(row, Color(1, 0.8, 0.35, 0.5) if got else Color(0.5, 0.42, 0.3, 0.5), false, 1.5)
		Art.star_icon(self, row.position + Vector2(26, 22), 30, got)
		Art.text(self, row.position + Vector2(62, 29), str(k.stars), 20, Color(1, 0.9, 0.5) if got else Color(0.7, 0.65, 0.55), HORIZONTAL_ALIGNMENT_LEFT, 50)
		Art.text(self, row.position + Vector2(110, 29), k.name, 19, Color.WHITE if got else Color(0.75, 0.72, 0.66), HORIZONTAL_ALIGNMENT_LEFT, 200)
		Art.text(self, row.position + Vector2(300, 29), k.desc, 15, Color(0.92, 0.9, 0.82) if got else Color(0.65, 0.62, 0.56), HORIZONTAL_ALIGNMENT_LEFT, 280)
		if got:
			var c := row.position + Vector2(row.size.x - 24, 22)
			draw_polyline(PackedVector2Array([c + Vector2(-9, 0), c + Vector2(-3, 7), c + Vector2(9, -7)]), Color(0.5, 1, 0.4), 4)
		else:
			Art.text(self, row.position + Vector2(row.size.x - 24, 28), "ещё %d" % (int(k.stars) - total), 13, Color(0.85, 0.7, 0.55), HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
	Art.text(self, Vector2(640, r.end.y - 14), "нажмите, чтобы закрыть", 13, Color(0.8, 0.75, 0.65))


func _card(i: int) -> void:
	var it: Dictionary = Shop.ITEMS[i]
	var r := card_rect(i)
	var own := Shop.owned(it.id)
	var can: bool = not own and Shop.stars_free() >= it.price
	var lvl := Shop.level_of(it.id)
	var ucost := Shop.upgrade_cost(it.id)
	var can_up: bool = own and ucost > 0 and Shop.coins() >= ucost
	var hov := r.has_point(get_global_mouse_position()) and (not own or ucost > 0)
	if hov:
		r.position.y -= 4
	draw_rect(Rect2(r.position + Vector2(5, 8), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r.grow(3), Color(0.1, 0.06, 0.03))
	draw_rect(r, Color(0.95, 0.72, 0.15) if own or can else Color(0.6, 0.55, 0.48))
	var inner := r.grow(-8)
	draw_rect(inner, Color(0.2, 0.32, 0.15) if own else Color(0.45, 0.1, 0.08))
	var f: float = flash.get(it.id, 0.0)
	if f > 0.0:
		draw_rect(inner, Color(1, 1, 0.7, f * 0.6))
	# картинка
	var tex: Texture2D = SpriteLib.tex(it.id) if it.kind == "tower" else Art.ui_tex("icon_" + it.id)
	if tex:
		var box := Rect2(inner.position + Vector2(20, 14), Vector2(inner.size.x - 40, 130))
		var k := minf(box.size.x / tex.get_width(), box.size.y / tex.get_height())
		var sz := tex.get_size() * k
		var mod := Color.WHITE if own or can else Color(0.55, 0.55, 0.55)
		draw_texture_rect(tex, Rect2(box.get_center() - sz * 0.5, sz), false, mod)
	Art.text(self, Vector2(r.get_center().x, inner.position.y + 172), it.name, 18, Color.WHITE)
	_wrap(it.desc, Vector2(r.get_center().x, inner.position.y + 196), 13, inner.size.x - 16)
	# уровень прокачки: 5 делений под картинкой
	var py := inner.position.y + 236
	for k in Shop.MAX_LEVEL:
		var cell := Rect2(r.get_center().x - 70 + k * 29, py, 24, 14)
		draw_rect(cell.grow(1.5), Color(0.08, 0.05, 0.04))
		draw_rect(cell, Color(1, 0.8, 0.25) if k < lvl else Color(0.25, 0.2, 0.17))
	if own:
		var line := ""
		if it.kind == "hero":
			line = "ХП ×%.2f  Урон ×%.2f" % [Shop.hero_hp_mult(it.id), Shop.hero_dmg_mult(it.id)]
		else:
			line = "Урон ×%.2f  Скор. ×%.2f" % [Shop.tower_dmg_mult(it.id), 1.0 / Shop.tower_rate_mult(it.id)]
		Art.text(self, Vector2(r.get_center().x, py + 36), line, 13, Color(0.9, 1, 0.8), HORIZONTAL_ALIGNMENT_CENTER, -1, 3)
	else:
		Art.text(self, Vector2(r.get_center().x, py + 36), "Уровень 1–5 после покупки", 12, Color(0.85, 0.8, 0.7), HORIZONTAL_ALIGNMENT_CENTER, -1, 3)
	# кнопка
	var b := buy_rect(i)
	b.position.y += -4 if hov else 0
	if own and ucost < 0:
		draw_rect(b.grow(2), Color(0.08, 0.05, 0.04))
		draw_rect(b, Color(0.55, 0.42, 0.12))
		Art.text(self, b.get_center() + Vector2(0, 8), "МАКС. УРОВЕНЬ", 17, Color.WHITE)
	elif own:
		draw_rect(b.grow(2), Color(0.08, 0.05, 0.04))
		draw_rect(b, Color(0.2, 0.4, 0.75) if can_up else Color(0.35, 0.3, 0.27))
		draw_rect(b.grow(-3), Color(1, 0.85, 0.35, 0.8), false, 2)
		var ap := b.position + Vector2(22, b.size.y * 0.5)
		Art.poly_o(self, PackedVector2Array([ap + Vector2(0, -11), ap + Vector2(10, 1), ap + Vector2(4, 1),
			ap + Vector2(4, 10), ap + Vector2(-4, 10), ap + Vector2(-4, 1), ap + Vector2(-10, 1)]), Color(0.45, 0.95, 0.35), 1.5)
		_coin(b.get_center() + Vector2(-6, 0), 12)
		Art.text(self, b.get_center() + Vector2(34, 9), str(ucost), 22, Color(1, 0.9, 0.5) if can_up else Color(0.8, 0.7, 0.6))
	else:
		draw_rect(b.grow(2), Color(0.08, 0.05, 0.04))
		draw_rect(b, Color(0.3, 0.55, 0.2) if can else Color(0.35, 0.3, 0.27))
		draw_rect(b.grow(-3), Color(1, 0.85, 0.35, 0.8), false, 2)
		Art.star_icon(self, b.get_center() + Vector2(-22, 0), 32, true)
		Art.text(self, b.get_center() + Vector2(12, 9), str(it.price), 24, Color(1, 0.9, 0.5) if can else Color(0.8, 0.7, 0.6))


func _wrap(s: String, top_center: Vector2, size: int, width: float) -> void:
	var font := ThemeDB.fallback_font
	s = Loc.t(s)
	var words := s.split(" ")
	var lines: Array = []
	var cur := ""
	for w in words:
		var test := w if cur == "" else cur + " " + w
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and cur != "":
			lines.append(cur)
			cur = w
		else:
			cur = test
	lines.append(cur)
	for i in lines.size():
		Art.text(self, top_center + Vector2(0, i * (size + 4)), lines[i], size, Color(0.92, 0.88, 0.8), HORIZONTAL_ALIGNMENT_CENTER, -1, 3)


func _back_btn() -> void:
	var c := R_BACK.get_center()
	var hov := R_BACK.has_point(get_global_mouse_position())
	draw_circle(c, 33, Color(0.08, 0.05, 0.04))
	draw_circle(c, 30, Color(0.5, 0.14, 0.1) if hov else Color(0.38, 0.1, 0.08))
	draw_arc(c, 30, 0, TAU, 32, Color(1, 0.8, 0.35), 2.5)
	var col := Color(1, 0.88, 0.55)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 0), c + Vector2(0, -13), c + Vector2(0, 13)]), col)
	draw_rect(Rect2(c + Vector2(-2, -5), Vector2(16, 10)), col)


func _coin(c: Vector2, r: float) -> void:
	Art.icon_coin(self, c, r)
