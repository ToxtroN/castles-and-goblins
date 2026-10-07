class_name Enemy
extends Node2D
## Гоблин: идёт по пути к замку. Ближний бой с блокирующим солдатом, дальняя атака
## (алхимик, камнемёт, повозка, ворон), полёт (ворон), ломание башен (громила).

enum Dmg { PHYSICAL, MAGIC, TRUE }

const FLY_HEIGHT := 42.0

var main: Node
var kind := ""
var data: Dictionary
var curve: Curve2D
var path_len := 0.0
var offset := 0.0
var lateral := 0.0
var max_hp := 10.0
var hp := 10.0
var speed := 40.0
var armor := 0.0
var mres := 0.0
var size := 10.0
var flying := false
var blocker: Soldier = null
var attack_cd := 0.0
var ranged_cd := 0.0
var dead := false
var walk_t := 0.0
var facing := 1.0
var hit_flash := 0.0
var fighting := false
var busy := false            # стоит и стреляет / ломает башню
var attack_anim := 0.0       # 1 → 0 во время проигрывания атаки
var tower_target: Tower = null
var shooting_at: Soldier = null   # кого обстреливает (чтобы тот пошёл в ответ)
var sprite_scale := 1.0
var path_idx := 0
var slow_k := 1.0            # замедление от проклятия мага
var slow_t := 0.0
# босс
var phase := 0
var roar_t := 0.0
var enraged := false


func setup(m: Node, k: String, c: Curve2D, hp_mult: float) -> void:
	main = m
	kind = k
	data = GameData.ENEMIES[k]
	curve = c
	path_len = c.get_baked_length()
	max_hp = float(data.hp) * hp_mult
	hp = max_hp
	speed = float(data.speed) * randf_range(0.93, 1.07)
	armor = data.armor
	mres = data.mres
	size = data.size
	flying = data.get("flying", false)
	lateral = randf_range(-14.0, 14.0)
	walk_t = randf() * 10.0
	ranged_cd = randf_range(0.3, 1.0)
	var walk := SpriteLib.frames(kind, "walk")
	if not walk.is_empty():
		sprite_scale = float(data.draw_h) / walk[0].get_height()
	position = path_pos(0.0)


func path_pos(o: float) -> Vector2:
	o = clampf(o, 0.0, path_len)
	var p := curve.sample_baked(o)
	var p2 := curve.sample_baked(minf(o + 6.0, path_len))
	var dir := p2 - p
	if dir.length() < 0.01:
		return p
	dir = dir.normalized()
	return p + Vector2(-dir.y, dir.x) * lateral


func remaining() -> float:
	return path_len - offset


func fly_offset() -> float:
	return FLY_HEIGHT + sin(walk_t * 3.0) * 4.0 if flying else 0.0


## Куда целиться снарядами (у летающих — в воздух).
func hit_point() -> Vector2:
	return position + Vector2(0, -fly_offset() - float(data.draw_h) * 0.5)


func predict(dt: float) -> Vector2:
	if fighting or busy:
		return position
	return path_pos(offset + cur_speed() * dt)


func cur_speed() -> float:
	var s := speed
	if slow_t > 0.0:
		s *= slow_k
	if not flying:
		s *= main.zone_speed(position)
	return s


func apply_slow(k: float, t: float) -> void:
	if data.has("boss"):
		k = lerpf(k, 1.0, 0.5)   # король замедляется вдвое слабее
	slow_k = minf(k, slow_k) if slow_t > 0.0 else k
	slow_t = maxf(slow_t, t)


func _process(delta: float) -> void:
	if dead:
		return
	walk_t += delta
	hit_flash = maxf(0.0, hit_flash - delta)
	attack_anim = maxf(0.0, attack_anim - delta * 2.0)
	attack_cd -= delta
	ranged_cd -= delta
	slow_t = maxf(0.0, slow_t - delta)
	if blocker != null and (not is_instance_valid(blocker) or blocker.dead):
		blocker = null
	if data.has("boss"):
		_boss_tick(delta)
		if roar_t > 0.0:
			busy = true
			fighting = false
			queue_redraw()
			return
		if enraged and blocker != null:
			blocker.release_target()
			blocker = null
	fighting = not flying and blocker != null and blocker.position.distance_to(position) < 30.0
	busy = false
	shooting_at = null
	# громила в первую очередь ломает башни — даже если его держат солдаты
	if data.has("tower_dmg"):
		_tower_attack()
		if busy:
			queue_redraw()
			return
	if fighting:
		_face(blocker.position)
		if attack_cd <= 0.0:
			attack_cd = data.rate
			attack_anim = 1.0
			var d: Vector2 = data.dmg
			blocker.take_damage(randf_range(d.x, d.y))
			main.sfx.play("hit")
	else:
		if not busy and data.has("ranged"):
			_ranged_attack()
		if not busy or flying:
			var old := position
			offset += cur_speed() * delta
			if offset >= path_len:
				main.enemy_reached_castle(self)
				return
			position = path_pos(offset)
			if absf(position.x - old.x) > 0.05:
				facing = signf(position.x - old.x)
	queue_redraw()


func _face(p: Vector2) -> void:
	if absf(p.x - position.x) > 1.0:
		facing = signf(p.x - position.x)


func _ranged_attack() -> void:
	var r: Dictionary = data.ranged
	var best: Soldier = null
	var best_d: float = r.range
	for u in main.get_units():
		var d: float = u.position.distance_to(position)
		if d < best_d:
			best_d = d
			best = u
	if best == null:
		return
	busy = true
	shooting_at = best
	_face(best.position)
	if ranged_cd <= 0.0:
		ranged_cd = r.rate
		attack_anim = 1.0
		var dmg: Vector2 = r.dmg
		var from := position + Vector2(facing * float(data.draw_h) * 0.3, -fly_offset() - float(data.draw_h) * 0.6)
		main.spawn_enemy_projectile(r.proj, from, best.position, randf_range(dmg.x, dmg.y), r.splash)


func _tower_attack() -> void:
	if tower_target != null and (not is_instance_valid(tower_target) or tower_target.dead):
		tower_target = null
	if tower_target == null:
		var rng: float = data.tower_range
		for t in main.slot_towers.values():
			if t.position.distance_to(position) < rng:
				tower_target = t
				break
	if tower_target == null:
		return
	busy = true
	_face(tower_target.position)
	if attack_cd <= 0.0:
		attack_cd = data.rate
		attack_anim = 1.0
		var d: Vector2 = data.tower_dmg
		tower_target.take_damage(randf_range(d.x, d.y))
		main.sfx.play("hit")
		main.spawn_text(tower_target.position + Vector2(0, -60), "БАХ!", Color(1, 0.6, 0.3))


## Король гоблинов: на 65% зовёт подмогу, на 35% оглушает башню, на 15% впадает в ярость.
func _boss_tick(delta: float) -> void:
	if roar_t > 0.0:
		roar_t -= delta
		if attack_anim <= 0.05:
			attack_anim = 1.0
		return
	var k := hp / max_hp
	if phase == 0 and k <= 0.65:
		phase = 1
		roar_t = 1.8
		attack_anim = 1.0
		main.king_summon(self)
		main.spawn_text(position + Vector2(0, -130), "Ко мне, гоблины!", Color(1, 0.55, 0.3))
		main.sfx.play("lose")
	elif phase == 1 and k <= 0.35:
		phase = 2
		roar_t = 1.6
		attack_anim = 1.0
		main.king_smash(self)
	elif phase == 2 and k <= 0.15:
		phase = 3
		enraged = true
		speed *= 2.1
		armor = minf(0.6, armor + 0.15)
		roar_t = 0.9
		attack_anim = 1.0
		main.spawn_text(position + Vector2(0, -130), "КОРОЛЬ В ЯРОСТИ!", Color(1, 0.3, 0.2))
		main.spawn_fx("ring", position).radius = 70


func take_damage(amount: float, type: int = Dmg.PHYSICAL) -> void:
	if dead:
		return
	if type == Dmg.PHYSICAL:
		amount *= 1.0 - armor
	elif type == Dmg.MAGIC:
		amount *= 1.0 - mres
	hp -= amount
	hit_flash = 0.1
	if hp <= 0.0:
		dead = true
		blocker = null
		main.enemy_killed(self)


func current_frame() -> Texture2D:
	var anim := "walk"
	if attack_anim > 0.0 and SpriteLib.has(kind, "attack"):
		anim = "attack"
	var fr := SpriteLib.frames(kind, anim)
	if fr.is_empty():
		return null
	var i := 0
	if anim == "attack":
		i = clampi(int((1.0 - attack_anim) * fr.size()), 0, fr.size() - 1)
	elif not (fighting or busy) or flying:
		i = int(walk_t * float(data.fps)) % fr.size()
	return fr[i]


# ---------------------------------------------------------------- ОТРИСОВКА
func _draw() -> void:
	var h: float = data.draw_h
	var fo := fly_offset()
	Art.shadow(self, Vector2(0, 2), size * (0.8 if flying else 1.1))
	var tex := current_frame()
	if tex != null:
		var boss := data.has("boss")
		var mod := Color.WHITE
		if hit_flash > 0.0:
			mod = Color(1, 0.85, 0.85) if boss else Color(1, 0.55, 0.55)
		if slow_t > 0.0:
			mod = mod * (Color(0.95, 0.9, 1.0) if boss else Color(0.85, 0.7, 1.0))
		if enraged:
			mod = mod * Color(1.0, 0.72 + 0.15 * sin(walk_t * 12.0), 0.68)
		SpriteLib.draw_frame(self, tex, sprite_scale, facing < 0, Vector2(0, -fo), mod)
	else:
		Art.circle_o(self, Vector2(0, -fo - h * 0.4), size, Color(0.4, 0.6, 0.3))
	if slow_t > 0.0:
		Art.ellipse_outline(self, Vector2(0, 1), size * 1.2, size * 0.45, Color(0.75, 0.35, 1.0, 0.8), 2.0)
	if hp < max_hp and not data.has("boss"):
		Art.hp_bar(self, Vector2(0, -fo - h - 6), maxf(20.0, size * 2.0), hp / max_hp)
