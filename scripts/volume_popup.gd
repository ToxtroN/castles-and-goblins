class_name VolumePopup
extends Node2D
## Всплывающий бегунок громкости под значком мегафона.
## Громкость общая (шина Master) и сохраняется в user://settings.cfg.
## Внизу бегунка — 0, звук выключен (мегафон перечёркнут).

const SETTINGS := "user://settings.cfg"
const W := 56.0
const H := 210.0
const TRACK_TOP := 22.0
const TRACK_BOTTOM := 168.0

static var volume := 0.8
static var _loaded := false

var anchor := Rect2()     # область значка мегафона (координаты экрана)
var open := false
var dragging := false
var t := 0.0
var close_t := -1.0       # отсчёт до автозакрытия после выбора громкости
var idle_t := 0.0         # сколько времени окно открыто без касаний


static func load_volume() -> void:
	if _loaded:
		return
	_loaded = true
	var cf := ConfigFile.new()
	if cf.load(SETTINGS) == OK:
		volume = float(cf.get_value("audio", "volume", 0.8))
	apply()


static func set_volume(v: float, save := true) -> void:
	volume = clampf(v, 0.0, 1.0)
	if volume < 0.03:
		volume = 0.0
	apply()
	if save:
		var cf := ConfigFile.new()
		cf.load(SETTINGS)
		cf.set_value("audio", "volume", volume)
		cf.save(SETTINGS)


static func apply() -> void:
	SplashScreen.music_on = volume > 0.0
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, volume <= 0.0 or Platform.muted)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.001)))


## Клавиша M / быстрое выключение: 0 ↔ прошлая громкость.
static var _before_mute := 0.8


static func toggle_mute() -> void:
	if volume > 0.0:
		_before_mute = volume
		set_volume(0.0)
	else:
		set_volume(maxf(_before_mute, 0.3))


func setup(icon_rect: Rect2) -> void:
	anchor = icon_rect
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 100
	load_volume()


func panel_rect() -> Rect2:
	return Rect2(anchor.get_center().x - W * 0.5, anchor.end.y + 8, W, H)


func toggle() -> void:
	open = not open
	dragging = false
	close_t = -1.0
	idle_t = 0.0


func _process(delta: float) -> void:
	t += delta
	if not open:
		return
	queue_redraw()
	if dragging:
		idle_t = 0.0
		return
	# громкость выбрана — окно закрывается само
	if close_t > 0.0:
		close_t -= delta
		if close_t <= 0.0:
			_close()
		return
	idle_t += delta
	if idle_t > 4.0:
		_close()


func _close() -> void:
	open = false
	dragging = false
	close_t = -1.0
	idle_t = 0.0
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not open:
		return
	var pr := panel_rect()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if pr.has_point(event.position):
				dragging = true
				close_t = -1.0
				_set_from(event.position.y)
				get_viewport().set_input_as_handled()
			elif not anchor.has_point(event.position):
				_close()   # клик мимо — закрыть (клик по значку обработает сама сцена)
				get_viewport().set_input_as_handled()
		else:
			if dragging:
				dragging = false
				close_t = 0.6
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		_set_from(event.position.y)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and pr.has_point(event.position):
		_set_from(event.position.y)
		if not event.pressed:
			close_t = 0.6
		get_viewport().set_input_as_handled()


func _set_from(y: float) -> void:
	var top := panel_rect().position.y + TRACK_TOP
	var bottom := panel_rect().position.y + TRACK_BOTTOM
	set_volume(1.0 - clampf((y - top) / (bottom - top), 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	if not open:
		return
	draw_set_transform(-global_position, 0, Vector2.ONE)
	var r := panel_rect()
	var c := r.get_center().x
	# панель
	draw_rect(r.grow(4), Color(0.08, 0.05, 0.04, 0.95))
	draw_rect(r, Color(0.38, 0.1, 0.08, 0.97))
	draw_rect(r.grow(-3), Color(1, 0.8, 0.35), false, 2)
	# дорожка
	var top := r.position.y + TRACK_TOP
	var bottom := r.position.y + TRACK_BOTTOM
	draw_line(Vector2(c, top), Vector2(c, bottom), Color(0.08, 0.05, 0.04), 12)
	var ky: float = lerpf(bottom, top, volume)
	draw_line(Vector2(c, ky), Vector2(c, bottom), Color(1, 0.78, 0.25), 8)
	draw_line(Vector2(c, top), Vector2(c, ky), Color(0.3, 0.25, 0.22), 8)
	# ручка
	draw_circle(Vector2(c, ky), 13, Color(0.08, 0.05, 0.04))
	draw_circle(Vector2(c, ky), 11, Color(1, 0.85, 0.35))
	draw_circle(Vector2(c - 3, ky - 3), 4, Color(1, 1, 0.8, 0.8))
	# процент и значок «выкл» внизу
	Art.text(self, Vector2(c, r.end.y - 10), "%d%%" % int(round(volume * 100)) if volume > 0 else "ВЫКЛ", 13,
		Color(1, 0.9, 0.6), HORIZONTAL_ALIGNMENT_CENTER, -1, 3)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
