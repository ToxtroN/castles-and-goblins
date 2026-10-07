class_name Soldier
extends Node2D
## Наш юнит: рыцарь казармы, лучник казармы, подкрепление. Герой наследуется от него.
## Ближний бой: перехватывает и блокирует гоблинов у точки сбора.
## Дальний (ranged != {}): стоит у точки сбора и стреляет, никого не блокирует.

var main: Node
var tower: Node = null          # казарма-владелец (если есть)
var sprite := "knight"          # папка спрайтов в assets/units
var draw_h := 40.0
var sprite_scale := 1.0
var max_hp := 50.0
var hp := 50.0
var dmg := Vector2(2, 4)
var armor := 0.0
var attack_rate := 1.0
var speed := 90.0
var engage_radius := 65.0
var regen := 3.0
var ranged: Dictionary = {}
var rally := Vector2.ZERO
var formation := Vector2.ZERO
var target: Enemy = null
var attack_cd := 0.0
var dead := false
var lifetime := -1.0
var facing := 1.0
var attack_anim := 0.0
var walk_t := 0.0
var moving_anim := false


func setup(m: Node, rally_point: Vector2, form: Vector2, stats: Dictionary, spr: String = "knight") -> void:
	main = m
	rally = rally_point
	formation = form
	set_sprite(spr, GameData.UNIT_DRAW_H.get(spr, 40.0))
	apply_stats(stats, true)


func set_sprite(spr: String, h: float) -> void:
	sprite = spr
	draw_h = h
	var fr := SpriteLib.frames(sprite, "walk")
	if not fr.is_empty():
		sprite_scale = draw_h / fr[0].get_height()


func apply_stats(stats: Dictionary, heal: bool) -> void:
	max_hp = stats.hp
	dmg = stats.dmg
	armor = stats.get("armor", 0.0)
	ranged = stats.get("ranged", {})
	if heal:
		hp = max_hp


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if dead:
		return
	walk_t += delta
	attack_anim = maxf(0.0, attack_anim - delta * 2.2)
	attack_cd -= delta
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			die()
			return
	moving_anim = false
	if not ranged.is_empty():
		_ranged_tick(delta)
		queue_redraw()
		return
	_validate_target()
	if target != null and not _is_shooter_near(target) and target.blocker != self:
		release_target()   # не держим этого врага — проверим, нет ли рядом стрелка
	if target == null:
		_find_target()
	if target != null:
		var to_t := target.position - position
		if to_t.length() > 22.0:
			var goal := target.position + (position - target.position).normalized() * 18.0
			_move_to(goal, delta)
		else:
			_face(target.position)
			if attack_cd <= 0.0:
				attack_cd = attack_rate
				attack_anim = 1.0
				target.take_damage(randf_range(dmg.x, dmg.y), Enemy.Dmg.PHYSICAL)
				main.sfx.play("sword")
	else:
		_move_to(rally + formation, delta)
		if tower == null:
			hp = minf(max_hp, hp + regen * delta)   # солдаты казармы не лечатся
	queue_redraw()


func _ranged_tick(delta: float) -> void:
	_move_to(rally + formation, delta)
	if moving_anim:
		return
	if tower == null:
		hp = minf(max_hp, hp + regen * 0.5 * delta)
	if attack_cd > 0.0:
		return
	var proj: String = ranged.proj
	var air_ok := proj != "bomb"
	var rng: float = ranged.range
	var best: Enemy = null
	var best_rem := INF
	for e in main.enemies:
		if e.dead or (e.flying and not air_ok):
			continue
		if e.position.distance_to(position) <= rng and e.remaining() < best_rem:
			best = e
			best_rem = e.remaining()
	if best == null:
		return
	_face(best.position)
	attack_cd = ranged.rate
	attack_anim = 1.0
	var d: Vector2 = ranged.dmg
	var from := position + Vector2(facing * draw_h * 0.4, -draw_h * 0.6)
	main.sfx.play("artillery" if proj == "bomb" else "arrow")
	if proj == "bomb":
		main.spawn_projectile("bomb", from, null, best.predict(0.9), randf_range(d.x, d.y), ranged.splash)
	else:
		main.spawn_projectile("arrow", from, best, best.position, randf_range(d.x, d.y), 0.0)


func _face(p: Vector2) -> void:
	if absf(p.x - position.x) > 1.0:
		facing = signf(p.x - position.x)


func _move_to(goal: Vector2, delta: float) -> void:
	var d := goal - position
	if d.length() < 2.0:
		return
	moving_anim = true
	if absf(d.x) > 1.0:
		facing = signf(d.x)
	var sp := speed
	if tower == null:
		sp *= main.zone_speed(position)   # герои вязнут в топи
	position += d.normalized() * minf(sp * delta, d.length())


func _validate_target() -> void:
	if target == null:
		return
	if not is_instance_valid(target) or target.dead:
		release_target()
		return
	var leash := engage_radius + 45.0
	if _is_shooter_near(target) or target.blocker == self:
		leash = engage_radius + 220.0
	if target.position.distance_to(rally) > leash:
		release_target()


func _find_target() -> void:
	var best: Enemy = null
	var best_d := INF
	var best_free := false
	for e in main.enemies:
		if e.dead or e.flying:
			continue
		var d: float = e.position.distance_to(rally)
		# стрелок (алхимик, камнемёт, повозка) в радиусе атаки — бежим к нему сразу
		if _is_shooter_near(e):
			d = e.position.distance_to(position) * 0.01
		elif d > engage_radius:
			continue
		var free: bool = e.blocker == null
		if (free and not best_free) or (free == best_free and d < best_d):
			best = e
			best_d = d
			best_free = free
	if best != null:
		target = best
		if best.blocker == null:
			best.blocker = self


## Наземный стрелок, который может достать нас или уже стреляет по нашим рядом.
const AGGRO := 230.0


func _is_shooter_near(e: Enemy) -> bool:
	if e.flying or not e.data.has("ranged"):
		return false
	var v = e.shooting_at
	if v != null and is_instance_valid(v) and v.position.distance_to(position) < 120.0:
		return true
	return e.position.distance_to(position) < maxf(AGGRO, float(e.data.ranged.range) + 30.0)


func release_target() -> void:
	if target != null and is_instance_valid(target) and target.blocker == self:
		target.blocker = null
	target = null


func take_damage(amount: float) -> void:
	if dead:
		return
	hp -= amount * (1.0 - armor)
	if hp <= 0.0:
		die()


func die() -> void:
	dead = true
	release_target()
	if tower != null and is_instance_valid(tower):
		tower.on_soldier_died(self)
	main.spawn_unit_corpse(self)
	queue_free()


func current_frame() -> Texture2D:
	var anim := "walk"
	if attack_anim > 0.0 and SpriteLib.has(sprite, "attack"):
		anim = "attack"
	elif not moving_anim and SpriteLib.has(sprite, "idle"):
		anim = "idle"
	var fr := SpriteLib.frames(sprite, anim)
	if fr.is_empty():
		return null
	var i := 0
	if anim == "attack":
		i = clampi(int((1.0 - attack_anim) * fr.size()), 0, fr.size() - 1)
	elif anim == "walk" and moving_anim:
		i = int(walk_t * 10.0) % fr.size()
	return fr[i]


# ---------------------------------------------------------------- ОТРИСОВКА
func _draw() -> void:
	_draw_selection()
	Art.shadow(self, Vector2(0, 2), draw_h * 0.3)
	var tex := current_frame()
	if tex != null:
		var mod := Color(1, 1, 1, 0.75) if lifetime > 0.0 and lifetime < 3.0 and int(lifetime * 6.0) % 2 == 0 else Color.WHITE
		SpriteLib.draw_frame(self, tex, sprite_scale, facing < 0, Vector2.ZERO, mod)
	else:
		Art.circle_o(self, Vector2(0, -10), 8, Color(0.3, 0.45, 0.8))
	if hp < max_hp:
		Art.hp_bar(self, Vector2(0, -draw_h - 6), 22, hp / max_hp)


func _draw_selection() -> void:
	pass
