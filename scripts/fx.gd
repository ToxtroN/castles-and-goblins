class_name Fx
extends Node2D
## Короткие эффекты: всплывающий текст, взрыв, молния, дымок, метеор.

var main: Node
var kind := "text"
var t := 0.0
var dur := 0.8
var text := ""
var color := Color.WHITE
var a := Vector2.ZERO   # для молнии / метеора — начало
var b := Vector2.ZERO   # конец
var radius := 50.0
var delay := 0.0
var bolt := PackedVector2Array()
var parts: Array = []   # частицы взрыва: [направление, скорость, размер, тип]
# kind == "sprite": проигрывание кадров (смерть, всплеск) с затуханием
var frames: Array = []
var fps := 10.0
var sc := 1.0
var flip := false
var centered := false
var hold := 0.4


func setup(m: Node, k: String, pos: Vector2) -> void:
	main = m
	kind = k
	position = pos
	match kind:
		"sprite":
			if frames.is_empty():
				return
			var i := mini(int(t * fps), frames.size() - 1)
			var fade_start := dur - 0.3
			var al := 1.0 - clampf((t - fade_start) / 0.3, 0.0, 1.0)
			if centered:
				SpriteLib.draw_centered(self, frames[i], sc, Vector2.ZERO, 0.0, Color(1, 1, 1, al))
			else:
				SpriteLib.draw_frame(self, frames[i], sc, flip, Vector2.ZERO, Color(1, 1, 1, al))
		"text": dur = 0.9
		"boom":
			dur = 0.7
			for i in 14:
				parts.append([Vector2.from_angle(randf() * TAU), randf_range(0.5, 1.3), randf_range(0.6, 1.2), 0])
			for i in 8:
				parts.append([Vector2.from_angle(randf_range(PI * 1.1, PI * 1.9)), randf_range(0.6, 1.2), randf_range(0.7, 1.3), 1])
			for i in 5:
				parts.append([Vector2.from_angle(randf() * TAU), randf_range(0.3, 0.7), randf_range(0.8, 1.3), 2])
		"beam": dur = 0.18
		"puff": dur = 0.5
		"meteor": dur = 0.6
		"ring": dur = 0.5


func play(fr: Array, frames_per_sec: float, scale: float, flipped: bool, center: bool, hold_last: float) -> void:
	frames = fr
	fps = frames_per_sec
	sc = scale
	flip = flipped
	centered = center
	hold = hold_last
	dur = fr.size() / fps + hold


func make_bolt() -> void:
	bolt = PackedVector2Array()
	var n := 7
	for i in n + 1:
		var k := float(i) / n
		var p := a.lerp(b, k) - position
		if i > 0 and i < n:
			p += Vector2(randf_range(-7, 7), randf_range(-7, 7))
		bolt.append(p)


func _process(delta: float) -> void:
	if delay > 0.0:
		delay -= delta
		return
	t += delta
	if kind == "beam" and int(t * 60.0) % 3 == 0:
		make_bolt()
	if t >= dur:
		if kind == "meteor":
			main.meteor_impact(b)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if delay > 0.0:
		return
	var k := t / dur
	match kind:
		"sprite":
			if frames.is_empty():
				return
			var i := mini(int(t * fps), frames.size() - 1)
			var fade_start := dur - 0.3
			var al := 1.0 - clampf((t - fade_start) / 0.3, 0.0, 1.0)
			if centered:
				SpriteLib.draw_centered(self, frames[i], sc, Vector2.ZERO, 0.0, Color(1, 1, 1, al))
			else:
				SpriteLib.draw_frame(self, frames[i], sc, flip, Vector2.ZERO, Color(1, 1, 1, al))
		"text":
			var s := 1.0 + maxf(0.0, 0.25 - t) * 2.0
			draw_set_transform(Vector2(0, -k * 30.0), -0.12, Vector2(s, s))
			var c := color
			c.a = 1.0 - maxf(0.0, k - 0.6) / 0.4
			Art.text(self, Vector2(0, 0), text, 18, c)
		"boom":
			_draw_boom(k)
		"beam":
			if bolt.size() > 1:
				draw_polyline(bolt, Color(0.75, 0.45, 1.0, 0.5 * (1.0 - k)), 7.0)
				draw_polyline(bolt, Color(0.95, 0.85, 1.0, 1.0 - k), 2.5)
		"puff":
			for i in 5:
				var ang := i * TAU / 5.0
				draw_circle(Vector2.from_angle(ang) * 12.0 * k + Vector2(0, -k * 10.0), 7.0 * (1.0 - k),
					Color(0.85, 0.85, 0.85, 0.7 * (1.0 - k)))
		"meteor":
			var p := a.lerp(b, k) - position
			var back := (a - b).normalized()
			var side := Vector2(-back.y, back.x)
			# длинный огненный хвост с языками пламени
			for i in 14:
				var f := float(i) / 14.0
				var wob := side * sin(t * 40.0 + i * 1.7) * (2.0 + i * 0.6)
				var tail := p + back * i * 8.0 + wob
				var r := 15.0 * (1.0 - f) + 2.0
				draw_circle(tail, r * 1.25, Color(1, 0.3, 0.05, 0.35 * (1.0 - f)))
				draw_circle(tail, r, Color(1, 0.55 - f * 0.35, 0.1, 0.85 * (1.0 - f)))
			draw_circle(p, 17.0 + sin(t * 50.0) * 2.0, Color(1, 0.45, 0.1, 0.45))
			draw_circle(p, 12, Color(1, 0.8, 0.3))
			Art.circle_o(self, p, 8, Color(0.45, 0.2, 0.08), 2)
			draw_circle(p + Vector2(-2, -2), 3.5, Color(1, 0.95, 0.6))
			for i in 4:
				var sp := p + back * randf_range(10, 60) + side * randf_range(-14, 14)
				draw_circle(sp, randf_range(1.5, 3.0), Color(1, 0.85, 0.3))
		"ring":
			Art.ellipse_outline(self, Vector2.ZERO, radius * k, radius * k * 0.5, Color(1, 1, 1, 1.0 - k), 3)


## Взрыв: вспышка, огненный шар, языки пламени вверх, искры, дым.
func _draw_boom(k: float) -> void:
	var r := radius
	var e := 1.0 - pow(1.0 - minf(k * 2.2, 1.0), 2.0)   # быстрое расширение
	# вспышка
	if k < 0.25:
		draw_circle(Vector2.ZERO, r * 1.1 * e, Color(1, 1, 0.8, 0.7 * (1.0 - k / 0.25)))
	# пятно гари на земле
	Art.ellipse(self, Vector2(0, 4), r * 0.7, r * 0.3, Color(0.15, 0.1, 0.05, 0.4 * (1.0 - k)))
	# дым (позади огня)
	for pt in parts:
		if int(pt[3]) == 2:
			var dir0: Vector2 = pt[0]
			var pos3 := dir0 * r * 0.7 * float(pt[1]) * e + Vector2(0, -k * r * 0.9)
			draw_circle(pos3, r * 0.3 * float(pt[2]) * (0.5 + k), Color(0.45, 0.42, 0.4, 0.45 * (1.0 - k) * clampf((k - 0.15) * 4.0, 0.0, 1.0)))
	# огненный шар
	draw_circle(Vector2(0, -r * 0.2 * k), r * (0.45 + 0.55 * e), Color(1, 0.35, 0.05, 0.55 * (1.0 - k)))
	draw_circle(Vector2(0, -r * 0.25 * k), r * 0.7 * e * (1.0 - k * 0.6), Color(1, 0.6, 0.1, 0.85 * (1.0 - k)))
	draw_circle(Vector2(0, -r * 0.3 * k), r * 0.4 * e * (1.0 - k), Color(1, 0.95, 0.55, 0.95 * (1.0 - k)))
	for pt in parts:
		var dir: Vector2 = pt[0]
		var spd: float = pt[1]
		var sz: float = pt[2]
		match int(pt[3]):
			0:  # искры
				var pos := dir * r * 1.3 * spd * e + Vector2(0, k * k * 25.0)
				draw_circle(pos, 2.5 * sz * (1.0 - k), Color(1, 0.85, 0.3, 1.0 - k))
			1:  # языки пламени вверх
				var pos2 := dir * r * 0.9 * spd * e
				var fl := 9.0 * sz * (1.0 - k)
				draw_colored_polygon(PackedVector2Array([pos2 + Vector2(-fl * 0.6, 0), pos2 + Vector2(fl * 0.6, 0),
					pos2 + Vector2(sin(t * 30.0) * 2.0, -fl * 2.2)]), Color(1, 0.5, 0.1, 0.9 * (1.0 - k)))
				draw_circle(pos2, fl * 0.6, Color(1, 0.8, 0.2, 0.9 * (1.0 - k)))
