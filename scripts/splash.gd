class_name SplashScreen
extends Node2D
## Заставка и главное меню Castles and Goblins.
## Этап 1: арт + музыка + «Нажмите, чтобы продолжить».
## Этап 2: меню «Новая игра» / «Выход».
## Мегафон в правом верхнем углу включает/выключает музыку заставки.

static var intro_seen := false   # при возврате из игры сразу показываем меню
static var music_on := true

const R_SOUND := Rect2(1206, 14, 60, 60)
const R_NEW := Rect2(490, 470, 300, 62)
const R_EXIT := Rect2(490, 550, 300, 62)

var art: Texture2D
var bg: Texture2D
var music: AudioStreamPlayer
var stage := "intro"   # intro | menu | leaving
var t := 0.0
var menu_t := 0.0
var fade := 1.0        # затемнение при входе/выходе
var hovered := ""


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	art = load("res://assets/splash.png")
	bg = load("res://assets/splash_bg.png")
	music = AudioStreamPlayer.new()
	var stream: AudioStream = load("res://assets/splash_music.mp3")
	if stream is AudioStreamMP3:
		stream.loop = true
	music.stream = stream
	add_child(music)
	music.play()
	vol_popup = VolumePopup.new()
	add_child(vol_popup)
	vol_popup.setup(R_SOUND)
	if intro_seen:
		stage = "menu"
		menu_t = 1.0
	Yandex.game_ready()


var vol_popup: VolumePopup


func _apply_sound() -> void:
	pass


func _process(delta: float) -> void:
	t += delta
	if stage == "menu":
		menu_t = minf(1.0, menu_t + delta * 3.0)
	if stage == "leaving":
		fade = minf(1.0, fade + delta * 2.0)
		if music_on:
			music.volume_db = linear_to_db(maxf(0.001, 1.0 - fade))
		if fade >= 1.0:
			stage = "done"
			get_tree().change_scene_to_file.call_deferred("res://scenes/level_select.tscn")
			return
	elif stage == "done":
		return
	else:
		fade = maxf(0.0, fade - delta * 1.5)
	hovered = _hit(get_global_mouse_position())
	queue_redraw()


func _hit(p: Vector2) -> String:
	if R_SOUND.has_point(p):
		return "sound"
	if stage == "menu" and menu_t > 0.5:
		if R_NEW.has_point(p):
			return "new"
		if R_EXIT.has_point(p) and not Platform.on_web:
			return "exit"
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if stage == "leaving" or stage == "done":
		return
	var pressed := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	elif event is InputEventScreenTouch and event.pressed:
		pressed = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and stage == "menu" and not Platform.on_web:
			get_tree().quit()
			return
		if event.keycode == KEY_M:
			VolumePopup.toggle_mute()
			return
		if stage == "intro":
			_to_menu()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_start_game()
		return
	if not pressed:
		return
	var id := _hit(get_global_mouse_position())
	if id == "sound":
		_toggle_sound()
	elif stage == "intro":
		_to_menu()
	elif id == "new":
		_start_game()
	elif id == "exit":
		get_tree().quit()


func _toggle_sound() -> void:
	vol_popup.toggle()


func _to_menu() -> void:
	stage = "menu"
	intro_seen = true


func _start_game() -> void:
	stage = "leaving"


# ---------------------------------------------------------------- ОТРИСОВКА
func _draw() -> void:
	# размытый фон на всю ширину + сам арт по высоте в центре
	draw_texture_rect(bg, Rect2(0, 0, 1280, 720), false)
	var h := 720.0
	var w := h * art.get_width() / art.get_height()
	var x := (1280.0 - w) * 0.5
	for i in 12:  # мягкая тень по краям арта
		var a := 0.05 * (12 - i) / 12.0
		draw_rect(Rect2(x - i * 3, 0, w + i * 6, h), Color(0, 0, 0, a), false, 3)
	draw_texture_rect(art, Rect2(x, 0, w, h), false)

	if stage == "intro":
		var a := 0.8 + 0.2 * sin(t * 3.0)
		draw_rect(Rect2(0, 640, 1280, 56), Color(0, 0, 0, 0.45))
		Art.text(self, Vector2(640, 678), "Нажмите, чтобы продолжить", 26, Color(1, 0.92, 0.6, a),
			HORIZONTAL_ALIGNMENT_CENTER, -1, 6)
	else:
		_draw_menu()

	_draw_megaphone(R_SOUND)
	if fade > 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, fade))


func _draw_menu() -> void:
	var k := ease(menu_t, 0.4)
	var panel := Rect2(450, 440, 380, 116 if Platform.on_web else 196)
	panel.position.y += (1.0 - k) * 40.0
	var off := Vector2(0, (1.0 - k) * 40.0)
	draw_rect(panel.grow(4), Color(0.08, 0.05, 0.04, 0.85 * k))
	draw_rect(panel, Color(0.35, 0.08, 0.07, 0.88 * k))
	draw_rect(panel.grow(-5), Color(0.95, 0.75, 0.3, 0.7 * k), false, 2)
	_button(Rect2(R_NEW.position + off, R_NEW.size), "НОВАЯ ИГРА", hovered == "new", k)
	if not Platform.on_web:   # в браузере «Выход» не нужен
		_button(Rect2(R_EXIT.position + off, R_EXIT.size), "ВЫХОД", hovered == "exit", k)


func _button(r: Rect2, label: String, hov: bool, k: float) -> void:
	var base := Color(0.55, 0.38, 0.12) if hov else Color(0.3, 0.2, 0.12)
	base.a = k
	draw_rect(r.grow(3), Color(0.08, 0.05, 0.04, k))
	draw_rect(r, base)
	draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.45)), Color(1, 1, 1, 0.08 * k))
	draw_rect(r.grow(-3), Color(0.95, 0.78, 0.35, k), false, 2)
	var col := Color(1, 0.92, 0.6, k) if hov else Color(0.98, 0.9, 0.75, k)
	Art.text(self, r.get_center() + Vector2(0, 10), label, 28 if hov else 26, col, HORIZONTAL_ALIGNMENT_CENTER, -1, 5)


func _draw_megaphone(r: Rect2) -> void:
	var hov := hovered == "sound"
	draw_circle(r.get_center(), 30, Color(0.08, 0.05, 0.04, 0.9))
	draw_circle(r.get_center(), 27, Color(0.45, 0.12, 0.1) if hov else Color(0.32, 0.1, 0.08))
	draw_arc(r.get_center(), 27, 0, TAU, 32, Color(0.95, 0.75, 0.3), 2)
	var c := r.get_center() + Vector2(-6, 0)
	var gold := Color(1, 0.88, 0.55)
	# раструб
	var horn := PackedVector2Array([c + Vector2(-10, -5), c + Vector2(6, -14), c + Vector2(6, 14), c + Vector2(-10, 5)])
	draw_colored_polygon(horn, gold)
	draw_rect(Rect2(c + Vector2(-15, -5), Vector2(6, 10)), gold)
	# ручка
	draw_line(c + Vector2(-6, 5), c + Vector2(-3, 13), gold, 3)
	if music_on:
		for i in 2:
			draw_arc(c + Vector2(8, 0), 7 + i * 6, -0.8, 0.8, 10, gold, 2.5)
	else:
		draw_line(r.get_center() + Vector2(-17, -17), r.get_center() + Vector2(17, 17), Color(0.08, 0.05, 0.04), 7)
		draw_line(r.get_center() + Vector2(-17, -17), r.get_center() + Vector2(17, 17), Color(1, 0.3, 0.25), 4)
