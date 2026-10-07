class_name Hud
extends Control
## Интерфейс: ресурсы, волны, герой, способности, пауза/скорость, экран победы/поражения.
## Клики обрабатывает main.gd через click(); сам Control мышь не перехватывает.

var main: Node
var vol_popup: VolumePopup
var t := 0.0
var end_t := -1.0   # время с момента показа экрана победы
var star_sounded := [false, false, false]
const R_UPG := Rect2(530, 536, 220, 70)

const R_TOP := Rect2(8, 8, 330, 42)
const R_CALL := Rect2(346, 8, 210, 42)
const R_PAUSE := Rect2(1176, 8, 44, 42)
const R_SPEED := Rect2(1226, 8, 46, 42)
const R_SOUND := Rect2(1126, 8, 44, 42)
const BTN_SIZE := 66.0
const BTN_Y := 644.0

var icons := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1280, 720)
	vol_popup = VolumePopup.new()
	add_child(vol_popup)
	vol_popup.setup(R_SOUND)
	for id in GameData.BUTTONS:
		var path := "res://assets/ui/icon_%s.png" % id
		icons[id] = load(path) if ResourceLoader.exists(path) else null


func btn_rect(i: int) -> Rect2:
	return Rect2(10 + i * (BTN_SIZE + 10), BTN_Y, BTN_SIZE, BTN_SIZE)


func _process(delta: float) -> void:
	t += delta
	if main.game_state != "play":
		end_t = 0.0 if end_t < 0.0 else end_t + delta
	else:
		end_t = -1.0
		star_sounded = [false, false, false]
	queue_redraw()


## Возвращает true, если клик пришёлся на интерфейс.
func click(p: Vector2) -> bool:
	if Platform.ad_open:
		return true
	if main.game_state != "play":
		if main.overlay != null:
			return true
		if R_UPG.has_point(p):
			main.open_upgrades()
			return true
		for b in end_buttons():
			if b[1].has_point(p):
				match b[0]:
					"next": main.next_level()
					"retry": main.restart()
					"levels": main.go_menu()
		return true
	if not main.buff_choice.is_empty():
		for i in main.buff_choice.size():
			if buff_rect(i).has_point(p):
				main.pick_buff(main.buff_choice[i])
		return true
	if R_PAUSE.has_point(p):
		main.toggle_pause()
		return true
	if R_SPEED.has_point(p):
		main.toggle_speed()
		return true
	if R_SOUND.has_point(p):
		vol_popup.toggle()
		return true
	if get_tree().paused:
		return true
	if R_CALL.has_point(p):
		if main.can_call_wave():
			main.start_next_wave()
		return true
	if R_TOP.has_point(p):
		return true
	for i in GameData.BUTTONS.size():
		if btn_rect(i).has_point(p):
			main.press_button(GameData.BUTTONS[i])
			return true
	if main.can_call_wave():
		for i in main.next_wave_paths():
			if p.distance_to(main.ENTRY_POINTS[i]) < 26.0:
				main.start_next_wave()
				return true
	return false


func buff_rect(i: int) -> Rect2:
	return Rect2(316 + i * 348, 236, 300, 250)


func _panel(r: Rect2, col: Color = Color(0.2, 0.16, 0.12, 0.92)) -> void:
	draw_rect(r.grow(3), Color(0.08, 0.06, 0.05))
	draw_rect(r, col)
	draw_rect(r.grow(-3), Color(0.55, 0.45, 0.3, 0.5), false, 1.5)


func _draw() -> void:
	_draw_world_overlays()
	# --- верхняя панель
	_panel(R_TOP)
	Art.icon_heart(self, Vector2(30, 27), 8)
	Art.text(self, Vector2(46, 36), str(main.lives), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 60)
	Art.icon_coin(self, Vector2(112, 29), 9)
	Art.text(self, Vector2(128, 36), str(main.gold), 20, Color(1, 0.88, 0.4), HORIZONTAL_ALIGNMENT_LEFT, 80)
	var wi := Art.ui_tex("icon_wave")
	if wi:
		draw_texture_rect(wi, Rect2(200, 13, 29, 28), false)
	else:
		Art.icon_skull(self, Vector2(214, 27), 8)
	Art.text(self, Vector2(230, 36), "  ВОЛНА %d/%d" % [main.wave_index, main.WAVES.size()], 18,
		Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 110)
	# --- кнопка волны
	if main.can_call_wave():
		var pulse := 0.5 + 0.5 * sin(t * 5.0)
		_panel(R_CALL, Color(0.35, 0.15, 0.1, 0.95).lerp(Color(0.55, 0.2, 0.12), pulse))
		var c := R_CALL.position + Vector2(22, 21)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -9), c + Vector2(9, 0), c + Vector2(-7, 9)]),
			Color(1, 0.85, 0.3))
		var label := "НАЧАТЬ ВОЛНУ" if main.wave_index == 0 else "ВЫЗВАТЬ ВОЛНУ"
		var bonus: int = main.early_bonus()
		if bonus > 0:
			label = "ВОЛНА +%d" % bonus
		Art.text(self, R_CALL.position + Vector2(38, 29), label, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 170)
		if main.next_wave_timer > 0.0:
			var k: float = main.next_wave_timer / GameData.WAVE_GAP
			draw_rect(Rect2(R_CALL.position + Vector2(4, 36), Vector2((R_CALL.size.x - 8) * k, 3)), Color(1, 0.8, 0.3))
	# --- пауза / скорость
	_panel(R_PAUSE)
	if get_tree().paused:
		var c2 := R_PAUSE.get_center()
		draw_colored_polygon(PackedVector2Array([c2 + Vector2(-6, -10), c2 + Vector2(10, 0), c2 + Vector2(-6, 10)]), Color.WHITE)
	else:
		draw_rect(Rect2(R_PAUSE.get_center() + Vector2(-8, -10), Vector2(6, 20)), Color.WHITE)
		draw_rect(Rect2(R_PAUSE.get_center() + Vector2(2, -10), Vector2(6, 20)), Color.WHITE)
	_panel(R_SPEED, Color(0.35, 0.25, 0.1) if Engine.time_scale > 1.0 else Color(0.2, 0.16, 0.12, 0.92))
	Art.text(self, R_SPEED.get_center() + Vector2(0, 7), "x%d" % int(Engine.time_scale), 18, Color.WHITE)
	_panel(R_SOUND)
	Art.megaphone(self, R_SOUND.get_center(), SplashScreen.music_on, 0.75)
	# --- герой и способности
	for i in GameData.BUTTONS.size():
		_draw_button(i)
	# --- сообщение
	if main.message_t > 0.0:
		var a := clampf(main.message_t, 0.0, 1.0)
		Art.text(self, Vector2(640, 120), main.message, 30, Color(1, 0.9, 0.5, a), HORIZONTAL_ALIGNMENT_CENTER, -1, 6)
	_draw_boss_bar()
	_draw_buff_badges()
	# --- вспышка урона
	if main.damage_flash > 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(1, 0, 0, main.damage_flash * 0.3), false, 30)
	if not main.buff_choice.is_empty() and main.game_state == "play":
		_draw_buff_choice()
	elif get_tree().paused and main.game_state == "play":
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.35))
		Art.text(self, Vector2(640, 370), "ПАУЗА", 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
	if main.game_state != "play":
		_draw_end()


func _draw_world_overlays() -> void:
	# индикаторы входа следующей волны
	if main.can_call_wave() and main.game_state == "play":
		for i in main.next_wave_paths():
			var p: Vector2 = main.ENTRY_POINTS[i]
			var pulse := 1.0 + 0.12 * sin(t * 6.0)
			draw_circle(p, 26 * pulse, Color(0.9, 0.2, 0.15, 0.35))
			Art.circle_o(self, p, 19, Color(0.25, 0.1, 0.08), 3)
			if main.next_wave_timer > 0.0:
				var k: float = main.next_wave_timer / GameData.WAVE_GAP
				draw_arc(p, 19, -PI / 2, -PI / 2 + TAU * k, 32, Color(1, 0.8, 0.3), 3)
			var wi2 := Art.ui_tex("icon_wave")
			if wi2:
				draw_texture_rect(wi2, Rect2(p - Vector2(13, 13), Vector2(26, 26)), false)
			else:
				Art.icon_skull(self, p + Vector2(0, -2), 9)
	# прицел способности / движения героя
	var m := get_global_mouse_position()
	if main.targeting == "meteor":
		Art.ellipse(self, m, 65, 40, Color(1, 0.4, 0.1, 0.2))
		Art.ellipse_outline(self, m, 65, 40, Color(1, 0.5, 0.2, 0.9), 2)
	elif GameData.HEROES.has(main.targeting):
		var ok: bool = main.near_road(m, 45.0)
		Art.ellipse_outline(self, m, 30, 14, Color(1, 0.85, 0.3, 0.9) if ok else Color(1, 0.3, 0.3, 0.9), 2.5)
		if ok:
			var hd: Dictionary = GameData.HEROES[main.targeting]
			if hd.has("ranged"):
				var rr: float = hd.ranged.range
				Art.ellipse_outline(self, m, rr, rr * 0.72, Color(1, 1, 1, 0.35), 1.5)
	elif main.selected_hero() != null:
		var ok2: bool = main.near_road(m, 60.0)
		Art.ellipse_outline(self, m, 16, 8, Color(0.4, 1.0, 0.4, 0.8) if ok2 else Color(1, 0.3, 0.3, 0.8), 2)


func _draw_button(i: int) -> void:
	var id: String = GameData.BUTTONS[i]
	var r := btn_rect(i)
	var c := r.get_center()
	if not Shop.owned(id):
		draw_rect(r.grow(2), Color(0.06, 0.04, 0.03))
		var lt: Texture2D = icons.get(id)
		if lt != null:
			draw_texture_rect(lt, r, false, Color(0.3, 0.3, 0.3))
		_lock(c)
		return
	var hero: Hero = main.heroes.get(id)
	var cd: float = main.cooldowns[id]
	var aiming: bool = main.targeting == id
	# рамка состояния
	if aiming:
		draw_rect(r.grow(5), Color(1, 0.9, 0.4, 0.5 + 0.4 * sin(t * 8.0)))
	elif hero != null:
		draw_rect(r.grow(5), Color(0.4, 1.0, 0.4, 0.9) if hero.selected else Color(1, 0.8, 0.3, 0.55))
	draw_rect(r.grow(2), Color(0.06, 0.04, 0.03))
	var tex: Texture2D = icons.get(id)
	if tex != null:
		draw_texture_rect(tex, r, false)
	else:
		draw_rect(r, Color(0.3, 0.2, 0.12))
		Art.text(self, c + Vector2(0, 6), id, 12, Color.WHITE)
	if hero != null:
		# герой на поле: полоска оставшегося времени
		var k := clampf(hero.lifetime / hero.duration, 0.0, 1.0)
		draw_rect(Rect2(r.position + Vector2(4, r.size.y - 9), Vector2(r.size.x - 8, 5)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(r.position + Vector2(4, r.size.y - 9), Vector2((r.size.x - 8) * k, 5)), Color(1, 0.85, 0.3))
		Art.hp_bar(self, Vector2(c.x, r.position.y - 9), r.size.x - 8, hero.hp / hero.max_hp)
	elif cd > 0.0:
		# откат: значок чёрный, сверху отсчёт
		draw_rect(r, Color(0, 0, 0, 0.78))
		var total: float = main.hero_cooldown(id)
		var k2 := cd / total
		draw_arc(c, r.size.x * 0.36, -PI / 2, -PI / 2 + TAU * k2, 32, Color(1, 0.8, 0.3, 0.8), 3)
		Art.text(self, c + Vector2(0, 9), "%d" % ceili(cd), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, -1, 5)
	Art.text(self, r.position + Vector2(10, 16), str(i + 1), 13, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER, -1, 3)
	if r.has_point(get_global_mouse_position()):
		var nm: String = GameData.HEROES[id].name if GameData.HEROES.has(id) else GameData.ABILITIES[id].name
		Art.text(self, Vector2(c.x + 40, r.position.y - 22), nm, 15, Color.WHITE)


func _draw_boss_bar() -> void:
	var b = main.boss
	if b == null or not is_instance_valid(b) or b.dead:
		return
	var r := Rect2(440, 62, 400, 18)
	_panel(r.grow(4), Color(0.15, 0.08, 0.06, 0.95))
	var k := clampf(b.hp / b.max_hp, 0.0, 1.0)
	draw_rect(r, Color(0.1, 0.03, 0.03))
	draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), Color(0.85, 0.15, 0.1) if not b.enraged else Color(1, 0.35 + 0.2 * sin(t * 10.0), 0.1))
	for f in [0.65, 0.35, 0.15]:
		var x: float = r.position.x + r.size.x * f
		draw_line(Vector2(x, r.position.y - 2), Vector2(x, r.end.y + 2), Color(1, 0.85, 0.4), 2)
	Art.text(self, Vector2(640, r.position.y + 14), "КОРОЛЬ ГОБЛИНОВ", 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, -1, 4)


func _draw_buff_badges() -> void:
	for i in main.buffs.size():
		var c := Vector2(584 + i * 36, 29)
		Art.circle_o(self, c, 14, Color(0.3, 0.2, 0.12), 2)
		draw_arc(c, 14, 0, TAU, 20, Color(1, 0.8, 0.3), 1.5)
		_buff_icon(main.buffs[i], c, 0.24)
		if c.distance_to(get_global_mouse_position()) < 15:
			var bd: Dictionary = GameData.BUFFS[main.buffs[i]]
			Art.text(self, c + Vector2(-14, 42), bd.name + ": " + bd.desc, 14, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 500)


func _buff_icon(id: String, c: Vector2, k: float) -> void:
	var ic: String = GameData.BUFFS[id].icon
	match ic:
		"crossbow", "mage":
			Art.draw_tower(self, ic, 2, t, 0.0, Transform2D(0, Vector2(k, k), 0, c + Vector2(0, 40 * k)))
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"knight":
			var fr := SpriteLib.frames("knight", "idle")
			if not fr.is_empty():
				SpriteLib.draw_frame(self, fr[0], 90.0 * k / fr[0].get_height(), false, c + Vector2(0, 44 * k))
		"coin":
			Art.icon_coin(self, c + Vector2(-8, 4) * k * 2.5, 22 * k)
			Art.icon_coin(self, c + Vector2(8, -4) * k * 2.5, 22 * k)
		_:
			var tex: Texture2D = icons.get(ic)
			if tex != null:
				var s := 100.0 * k
				draw_texture_rect(tex, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)


func _draw_buff_choice() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.55))
	Art.text(self, Vector2(640, 190), "Выберите бонус перед волной %d" % (main.wave_index + 1), 32, Color(1, 0.9, 0.5), HORIZONTAL_ALIGNMENT_CENTER, -1, 6)
	Art.text(self, Vector2(640, 220), "действует до конца боя", 16, Color(0.9, 0.9, 0.85))
	var m := get_global_mouse_position()
	for i in main.buff_choice.size():
		var id: String = main.buff_choice[i]
		var bd: Dictionary = GameData.BUFFS[id]
		var r := buff_rect(i)
		var hov := r.has_point(m)
		if hov:
			r = r.grow(6)
		draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.4))
		draw_rect(r.grow(3), Color(0.1, 0.06, 0.03))
		draw_rect(r, Color(1, 0.85, 0.35) if hov else Color(0.9, 0.68, 0.18))
		draw_rect(r.grow(-8), Color(0.22, 0.3, 0.45) if hov else Color(0.18, 0.24, 0.36))
		var c := r.position + Vector2(r.size.x * 0.5, 90)
		draw_circle(c, 52, Color(1, 0.9, 0.5, 0.12 + (0.1 if hov else 0.0)))
		_buff_icon(id, c, 1.0)
		Art.text(self, Vector2(c.x, r.position.y + 176), bd.name, 22, Color.WHITE)
		Art.text(self, Vector2(c.x, r.position.y + 206), bd.desc, 14, Color(0.95, 0.9, 0.75))


## Кнопки экрана итогов: [id, область]. «Продолжить» — только после победы.
func end_buttons() -> Array:
	if main.game_state == "win" and main.level < Levels.count():
		return [["levels", Rect2(398, 440, 84, 84)], ["next", Rect2(500, 444, 240, 75)],
			["retry", Rect2(758, 440, 84, 84)]]
	return [["levels", Rect2(530, 440, 84, 84)], ["retry", Rect2(666, 440, 84, 84)]]


func _draw_end() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.6))
	var win: bool = main.game_state == "win"
	draw_rect(Rect2(380, 210, 520, 410).grow(4), Color(0.08, 0.05, 0.04, 0.9))
	draw_rect(Rect2(380, 210, 520, 410), Color(0.2, 0.15, 0.11, 0.95))
	draw_rect(Rect2(380, 210, 520, 410).grow(-6), Color(0.9, 0.7, 0.3, 0.6), false, 2)
	# надпись Победа / Поражение — над звёздами, с «выпрыгиванием»
	var title := Art.ui_tex("title_win" if win else "title_lose")
	if title != null:
		var k := clampf(end_t / 0.35, 0.0, 1.0)
		var sc := 0.4 + 0.6 * k + 0.12 * sin(k * PI)
		var h := 140.0 * sc
		var w := h * title.get_width() / title.get_height()
		draw_texture_rect(title, Rect2(640 - w * 0.5, 175 - h * 0.5, w, h), false, Color(1, 1, 1, k))
	Art.text(self, Vector2(640, 262), "УРОВЕНЬ %d" % main.level, 16, Color(0.95, 0.85, 0.6))
	for i in 3:
		_drop_star(i, Vector2(570 + i * 70, 320))
	if win:
		Art.text(self, Vector2(640, 384), "Сердец осталось: %d   ·   Убито: %d" % [main.lives, main.kills], 17, Color(0.9, 0.9, 0.8))
	else:
		Art.text(self, Vector2(640, 366), "Замок пал на волне %d" % main.wave_index, 18, Color.WHITE)
		Art.text(self, Vector2(640, 392), "Убито врагов: %d" % main.kills, 16, Color(0.9, 0.9, 0.8))
	# награда монетами
	Art.icon_coin(self, Vector2(590, 418), 10)
	Art.text(self, Vector2(606, 425), "+%d монет" % main.coins_earned, 18, Color(1, 0.88, 0.4), HORIZONTAL_ALIGNMENT_LEFT, 160)
	var hov := get_global_mouse_position()
	var ut := Art.ui_tex("btn_upgrades")
	if ut:
		var ur := R_UPG.grow(4) if R_UPG.has_point(hov) else R_UPG
		draw_texture_rect(ut, ur, false)
		var fs := Shop.stars_free()
		if fs > 0:
			Art.star_icon(self, ur.position + Vector2(ur.size.x - 4, 6), 34, true)
			Art.text(self, ur.position + Vector2(ur.size.x - 4, 13), str(fs), 14, Color(0.3, 0.15, 0.0), HORIZONTAL_ALIGNMENT_CENTER, -1, 0)
	for b in end_buttons():
		var r: Rect2 = b[1]
		var grow := 4.0 if r.has_point(hov) else 0.0
		var rr := r.grow(grow)
		match b[0]:
			"next":
				var t1 := Art.ui_tex("btn_continue")
				if t1: draw_texture_rect(t1, rr, false)
			"retry":
				var t2 := Art.ui_tex("btn_retry")
				if t2: draw_texture_rect(t2, rr, false)
			"levels":
				_levels_btn(rr)


## Круглая кнопка «к списку уровней» в стиле кнопки повтора (синяя с золотом).
func _levels_btn(r: Rect2) -> void:
	var c := r.get_center()
	var rad := r.size.x * 0.5
	draw_circle(c, rad, Color(0.45, 0.22, 0.05))
	draw_circle(c, rad - 2, Color(1, 0.75, 0.15))
	draw_circle(c, rad - 9, Color(0.45, 0.22, 0.05))
	draw_circle(c, rad - 11, Color(0.1, 0.3, 0.85))
	var g := Color(1, 0.8, 0.2)
	for i in 3:
		for j in 3:
			var p := c + Vector2((i - 1) * 15, (j - 1) * 15)
			draw_rect(Rect2(p - Vector2(5.5, 5.5), Vector2(11, 11)), Color(0.45, 0.22, 0.05))
			draw_rect(Rect2(p - Vector2(4.5, 4.5), Vector2(9, 9)), g)


## Сначала тёмные силуэты, затем заработанные звёзды по очереди падают сверху и «прилипают».
func _drop_star(i: int, c: Vector2) -> void:
	var size := 62.0 if i == 1 else 54.0
	if i == 1:
		c.y -= 10
	Art.star_icon(self, c, size, false)
	if main.game_state != "win" or i >= main.stars_earned:
		return
	var start := 0.6 + i * 0.45
	var k := (end_t - start) / 0.35
	if k < 0.0:
		return
	if k >= 1.0 and not star_sounded[i]:
		star_sounded[i] = true
		main.sfx.play("star")
	if k < 1.0:
		var e := k * k
		var pos := c + Vector2(0, -260.0 * (1.0 - e))
		Art.star_icon(self, pos, size * (1.6 - 0.6 * e), true, minf(1.0, k * 3.0))
	else:
		var bk := minf(1.0, (k - 1.0) * 3.0)
		var bounce := 1.0 + 0.25 * sin(bk * PI) * (1.0 - bk * 0.3)
		Art.star_icon(self, c, size * bounce, true)
		if bk < 1.0:
			for j in 8:
				var d := Vector2.from_angle(j * TAU / 8.0) * (20.0 + 40.0 * bk)
				draw_circle(c + d, 4.0 * (1.0 - bk), Color(1, 0.9, 0.4, 1.0 - bk))


func _star(c: Vector2, r: float, on: bool) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var rr := r if i % 2 == 0 else r * 0.45
		var a := -PI / 2 + i * TAU / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	Art.poly_o(self, pts, Color(1, 0.82, 0.2) if on else Color(0.3, 0.3, 0.3), 3)


func _lock(c: Vector2) -> void:
	var col := Color(0.12, 0.09, 0.07)
	draw_arc(c + Vector2(0, -6), 10, PI, TAU, 14, col, 5)
	draw_line(c + Vector2(-10, -6), c + Vector2(-10, 1), col, 5)
	draw_line(c + Vector2(10, -6), c + Vector2(10, 1), col, 5)
	draw_rect(Rect2(c + Vector2(-15, 0), Vector2(30, 22)), col)
	draw_rect(Rect2(c + Vector2(-12, 3), Vector2(24, 16)), Color(0.75, 0.68, 0.55))
	draw_circle(c + Vector2(0, 10), 3.5, col)
