class_name Projectile
extends Node2D
## Снаряды башен: стрела (самонаводящаяся), ядро (дуга, взрыв).
## Снаряды гоблинов (kind начинается с "e_"): зелье, камень, ядро повозки, копьё ворона —
## летят в точку и бьют солдат/героя по площади.

var main: Node
var kind := "arrow"
var target: Enemy = null
var start := Vector2.ZERO
var dest := Vector2.ZERO
var dmg := 0.0
var splash := 0.0
var t := 0.0
var dur := 0.9
var arc_h := 110.0
var prev := Vector2.ZERO
var spin := 0.0
var trail: Array = []

const ENEMY_PROJ := {
	"e_mage": {"sprite": "mage", "dur": 0.7, "arc": 60.0, "scale": 0.35, "spin": 8.0},
	"e_rock": {"sprite": "rock", "dur": 0.8, "arc": 70.0, "scale": 0.3, "spin": 4.0},
	"e_cart": {"sprite": "cart", "dur": 0.9, "arc": 90.0, "scale": 0.45, "spin": 0.0},
	"e_crow": {"sprite": "crow", "dur": 0.45, "arc": 0.0, "scale": 0.45, "spin": 0.0},
}


func setup(m: Node, k: String, from: Vector2, tgt: Enemy, to: Vector2, damage: float, spl: float) -> void:
	main = m
	kind = k
	start = from
	position = from
	prev = from
	target = tgt
	dest = to
	dmg = damage
	splash = spl
	if kind == "arrow" or kind == "bolt":
		dur = clampf(from.distance_to(to) / (520.0 if kind == "arrow" else 750.0), 0.1, 0.5)
	elif ENEMY_PROJ.has(kind):
		dur = ENEMY_PROJ[kind].dur
		arc_h = ENEMY_PROJ[kind].arc


func _process(delta: float) -> void:
	t += delta
	spin += delta
	if kind == "bomb" or kind == "e_cart":
		trail.push_front(position)
		if trail.size() > 9:
			trail.pop_back()
	var k := clampf(t / dur, 0.0, 1.0)
	prev = position
	if kind == "arrow" or kind == "bolt":
		if target != null and is_instance_valid(target) and not target.dead:
			dest = target.hit_point()
		var arc := sin(k * PI) * (25.0 if kind == "arrow" else 8.0)
		position = start.lerp(dest, k) + Vector2(0, -arc)
		if k >= 1.0:
			if target != null and is_instance_valid(target) and not target.dead:
				target.take_damage(dmg, Enemy.Dmg.PHYSICAL)
			queue_free()
	else:
		var arc := sin(k * PI) * arc_h
		position = start.lerp(dest, k) + Vector2(0, -arc)
		if k >= 1.0:
			if kind == "bomb":
				main.explode(dest, splash, dmg, Enemy.Dmg.PHYSICAL)
			else:
				main.enemy_projectile_hit(kind, dest, splash, dmg)
			queue_free()
	queue_redraw()


func _draw() -> void:
	var dir := (position - prev)
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	if kind == "arrow" and SpriteLib.has("archer", "proj"):
		SpriteLib.draw_centered(self, SpriteLib.frames("archer", "proj")[0], 0.5, Vector2.ZERO, dir.angle())
	elif kind == "bolt":
		draw_set_transform(Vector2.ZERO, dir.angle(), Vector2.ONE)
		draw_line(Vector2(-14, 0), Vector2(8, 0), Art.OUTLINE, 4)
		draw_line(Vector2(-13, 0), Vector2(7, 0), Color(0.5, 0.33, 0.18), 2.5)
		draw_colored_polygon(PackedVector2Array([Vector2(13, 0), Vector2(6, -4), Vector2(6, 4)]), Color(0.75, 0.75, 0.8))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	elif kind == "arrow":
		draw_set_transform(Vector2.ZERO, dir.angle(), Vector2.ONE)
		draw_line(Vector2(-9, 0), Vector2(6, 0), Color(0.45, 0.3, 0.15), 2)
		draw_colored_polygon(PackedVector2Array([Vector2(9, 0), Vector2(5, -2.5), Vector2(5, 2.5)]), Color(0.8, 0.8, 0.85))
		draw_line(Vector2(-9, 0), Vector2(-12, -3), Color.WHITE, 1.5)
		draw_line(Vector2(-9, 0), Vector2(-12, 3), Color.WHITE, 1.5)
	elif kind == "bomb":
		_draw_fire_trail(6.0)
		Art.circle_o(self, Vector2.ZERO, 5, Color(0.15, 0.15, 0.17), 1.5)
		draw_circle(Vector2(-1.5, -1.5), 1.5, Color(0.6, 0.6, 0.65))
		draw_circle(Vector2(4, -4), 2 + randf() * 1.5, Color(1, 0.7, 0.2))
	else:
		var cfg: Dictionary = ENEMY_PROJ[kind]
		var fr := SpriteLib.frames(cfg.sprite, "proj")
		if fr.is_empty():
			Art.circle_o(self, Vector2.ZERO, 5, Color(0.4, 0.4, 0.45), 1.5)
			return
		if kind == "e_cart":
			_draw_fire_trail(7.0)
		var rot := dir.angle() if kind == "e_crow" else spin * float(cfg.spin)
		SpriteLib.draw_centered(self, fr[0], cfg.scale, Vector2.ZERO, rot)


## Огненный след за ядром.
func _draw_fire_trail(r: float) -> void:
	for i in trail.size():
		var f := float(i) / trail.size()
		var p: Vector2 = trail[i] - position
		draw_circle(p, r * (1.3 - f), Color(1, 0.35, 0.05, 0.35 * (1.0 - f)))
		draw_circle(p, r * (0.9 - f * 0.7), Color(1, 0.7 - f * 0.4, 0.15, 0.8 * (1.0 - f)))
	draw_circle(Vector2.ZERO, r * 1.6 + sin(t * 40.0), Color(1, 0.5, 0.1, 0.35))
