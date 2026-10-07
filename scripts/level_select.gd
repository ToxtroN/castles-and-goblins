extends Node2D
## Экран выбора уровня: 15 плиток 5×3, звёзды над пройденными, замки на закрытых.
## Следующий уровень открывается, когда предыдущий пройден хотя бы на 1 звезду.

const COLS := 5
const TILE := 112.0
const GAP_X := 70.0
const GAP_Y := 62.0
const ORIGIN := Vector2(640 - (COLS * TILE + (COLS - 1) * GAP_X) * 0.5, 170)
const R_BACK := Rect2(24, 20, 64, 64)
const R_SOUND := Rect2(1192, 20, 64, 64)
const R_UPG := Rect2(1010, 636, 250, 80)
const PER_PAGE := 15
const R_PREV := Rect2(30, 330, 70, 100)
const R_NEXT := Rect2(1180, 330, 70, 100)

static var page := 0

var bg: Texture2D
var stars: Array = []
var music: AudioStreamPlayer
var t := 0.0
var hovered := -1
var fade := 1.0
var leaving := ""
var vol_popup: VolumePopup


func _ready() -> void:
	bg = load("res://assets/splash_bg.png")
	stars = Levels.load_stars()
	music = AudioStreamPlayer.new()
	var st: AudioStream = load("res://assets/splash_music.mp3")
	if st is AudioStreamMP3:
		st.loop = true
	music.stream = st
	add_child(music)
	music.play()
	vol_popup = VolumePopup.new()
	add_child(vol_popup)
	vol_popup.setup(R_SOUND)


func pages() -> int:
	return int(ceil(Levels.count() / float(PER_PAGE)))


func page_levels() -> Array:
	var res: Array = []
	for i in range(page * PER_PAGE, mini((page + 1) * PER_PAGE, Levels.count())):
		res.append(i)
	return res


func tile_rect(i: int) -> Rect2:
	var k := i % PER_PAGE
	var c := k % COLS
	var r := k / COLS
	return Rect2(ORIGIN + Vector2(c * (TILE + GAP_X), r * (TILE + GAP_Y)), Vector2(TILE, TILE))


func _process(delta: float) -> void:
	t += delta
	if leaving != "":
		fade = minf(1.0, fade + delta * 2.5)
		if fade >= 1.0:
			var target := leaving
			leaving = "done"
			if target == "upgrades":
				get_tree().change_scene_to_file.call_deferred("res://scenes/upgrades.tscn")
			elif target == "back":
				get_tree().change_scene_to_file.call_deferred("res://scenes/splash.tscn")
			elif target != "done":
				get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")
	else:
		fade = maxf(0.0, fade - delta * 2.5)
	hovered = -1
	var m := get_global_mouse_position()
	for i in page_levels():
		if tile_rect(i).has_point(m):
			hovered = i
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if leaving != "":
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		leaving = "back"
		return
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if not pressed:
		return
	var p := get_global_mouse_position()
	if R_BACK.has_point(p):
		leaving = "back"
		return
	if R_SOUND.has_point(p):
		vol_popup.toggle()
		return
	if R_PREV.has_point(p) and page > 0:
		page -= 1
		return
	if R_NEXT.has_point(p) and page < pages() - 1:
		page += 1
		return
	for i in page_levels():
		if tile_rect(i).has_point(p) and Levels.unlocked(i + 1, stars):
			Levels.current = i + 1
			leaving = "play"
			if SplashScreen.music_on:
				var tw := create_tween()
				tw.tween_property(music, "volume_db", -40.0, 0.4)
			return


# ---------------------------------------------------------------- ОТРИСОВКА
func _draw() -> void:
	draw_texture_rect(bg, Rect2(0, 0, 1280, 720), false)
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.25))
	# заголовок на ленте
	var ribbon := Rect2(380, 34, 520, 74)
	draw_rect(ribbon.grow(4), Color(0.08, 0.05, 0.04))
	draw_rect(ribbon, Color(0.5, 0.1, 0.08))
	draw_rect(ribbon.grow(-6), Color(1, 0.8, 0.35), false, 2)
	Art.text(self, Vector2(640, 86), "ВЫБОР УРОВНЯ", 40, Color(1, 0.88, 0.45), HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
	# всего звёзд
	var total := 0
	for s in stars:
		total += s
	_star(Vector2(1000, 71), 16, true)
	Art.text(self, Vector2(1022, 80), "%d / %d" % [total, Levels.count() * 3], 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 140)
	for i in page_levels():
		_draw_tile(i)
	if page > 0:
		_arrow(R_PREV, -1.0)
	if page < pages() - 1:
		_arrow(R_NEXT, 1.0)
	if pages() > 1:
		for k in pages():
			draw_circle(Vector2(640 + (k - (pages() - 1) * 0.5) * 26, 690), 7 if k == page else 5,
				Color(1, 0.85, 0.35) if k == page else Color(1, 1, 1, 0.5))
	_draw_round_btn(R_BACK, "back")
	_draw_round_btn(R_SOUND, "sound")
	if fade > 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, fade))


func _draw_tile(i: int) -> void:
	var r := tile_rect(i)
	var open := Levels.unlocked(i + 1, stars)
	var hov := hovered == i and open
	var lift := -4.0 if hov else 0.0
	r.position.y += lift
	# тень
	draw_rect(Rect2(r.position + Vector2(5, 8), r.size), Color(0, 0, 0, 0.35))
	# золотая рамка
	var gold := Color(0.95, 0.72, 0.15) if open else Color(0.55, 0.5, 0.45)
	var gold_hi := Color(1, 0.9, 0.45) if open else Color(0.7, 0.66, 0.6)
	draw_rect(r.grow(3), Color(0.1, 0.06, 0.03))
	draw_rect(r, gold)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 8)), gold_hi)
	draw_rect(Rect2(r.position, Vector2(8, r.size.y)), gold_hi)
	# уголки
	for cx in [0.0, 1.0]:
		for cy in [0.0, 1.0]:
			var cpt := r.position + Vector2(cx * r.size.x, cy * r.size.y)
			draw_rect(Rect2(cpt - Vector2(9, 9), Vector2(18, 18)), gold_hi)
			draw_rect(Rect2(cpt - Vector2(9, 9), Vector2(18, 18)), Color(0.45, 0.3, 0.05), false, 2)
	# красное поле
	var inner := r.grow(-13)
	var red := Color(0.62, 0.1, 0.08) if open else Color(0.28, 0.24, 0.22)
	if hov:
		red = red.lightened(0.15)
	draw_rect(inner.grow(2), Color(0.1, 0.03, 0.02))
	draw_rect(inner, red)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x, inner.size.y * 0.4)), Color(1, 1, 1, 0.06))
	var c := inner.get_center()
	if open:
		Art.text(self, c + Vector2(0, 16), str(i + 1), 44, Color(1, 0.88, 0.45), HORIZONTAL_ALIGNMENT_CENTER, -1, 7)
		# звёзды над плиткой
		var s: int = stars[i]
		for k in 3:
			var off := (k - 1) * 30.0
			var up := -8.0 if k == 1 else 0.0
			_star(Vector2(r.get_center().x + off, r.position.y - 16 + up), 14 if k == 1 else 12, k < s)
	else:
		_lock(c)


func _lock(c: Vector2) -> void:
	var col := Color(0.12, 0.09, 0.07)
	draw_arc(c + Vector2(0, -8), 15, PI, TAU, 16, col, 7)
	draw_line(c + Vector2(-15, -8), c + Vector2(-15, 2), col, 7)
	draw_line(c + Vector2(15, -8), c + Vector2(15, 2), col, 7)
	draw_rect(Rect2(c + Vector2(-22, 0), Vector2(44, 32)), col)
	draw_rect(Rect2(c + Vector2(-18, 4), Vector2(36, 24)), Color(0.6, 0.55, 0.5))
	draw_circle(c + Vector2(0, 13), 5, col)
	draw_rect(Rect2(c + Vector2(-2, 14), Vector2(4, 9)), col)


func _star(c: Vector2, r: float, on: bool) -> void:
	Art.star_icon(self, c, r * 2.3, on)


func _draw_round_btn(r: Rect2, kind: String) -> void:
	var c := r.get_center()
	var hov := r.has_point(get_global_mouse_position())
	draw_circle(c, 33, Color(0.08, 0.05, 0.04))
	draw_circle(c, 30, Color(0.5, 0.14, 0.1) if hov else Color(0.38, 0.1, 0.08))
	draw_arc(c, 30, 0, TAU, 32, Color(1, 0.8, 0.35), 2.5)
	if kind == "back":
		var col := Color(1, 0.88, 0.55)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 0), c + Vector2(0, -13), c + Vector2(0, 13)]), col)
		draw_rect(Rect2(c + Vector2(-2, -5), Vector2(16, 10)), col)
	else:
		Art.megaphone(self, c, SplashScreen.music_on, 1.0)


func _arrow(r: Rect2, dir: float) -> void:
	var c := r.get_center()
	var hov := r.has_point(get_global_mouse_position())
	var pts := PackedVector2Array([c + Vector2(26 * dir, 0), c + Vector2(-20 * dir, -42), c + Vector2(-20 * dir, 42)])
	var big := PackedVector2Array([c + Vector2(32 * dir, 0), c + Vector2(-24 * dir, -50), c + Vector2(-24 * dir, 50)])
	draw_colored_polygon(big, Color(0.08, 0.05, 0.04))
	draw_colored_polygon(pts, Color(1, 0.8, 0.3) if hov else Color(0.85, 0.6, 0.15))
