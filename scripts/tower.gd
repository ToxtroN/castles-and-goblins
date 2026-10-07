class_name Tower
extends Node2D
## Башня. Тип и уровень берутся из GameData.TOWERS.
## crossbow — один мощный болт; mage — цепная молния; barracks — рыцари (+ лучники на 3 ур.).

var main: Node
var type := ""
var level := 0
var slot := -1
var invested := 0
var cd := 0.0
var anim := 0.0
var t := 0.0
var build_t := 0.0
var max_hp := 160.0
var hp := 160.0
var dead := false
var hurt_t := 0.0
# казарма
var rally := Vector2.ZERO
var soldiers: Array = [null, null, null]
var respawn: Array = [0.0, 0.0, 0.0]
var archers: Array = [null, null, null, null]
var archer_respawn: Array = [0.0, 0.0, 0.0, 0.0]
var aim := 1.0          # арбалет: 1 — баллиста смотрит влево, -1 — вправо (плавный поворот)
var aim_target := 1.0
var spec := ""               # специализация III уровня (GameData.SPECS)
var stun_t := 0.0            # оглушена королём гоблинов
var _stats: Dictionary = {}
var unit_mode := "knights"   # со 2 уровня: "knights" — 3 рыцаря, "archers" — 3 рыцаря + 2 лучника
const FORMATION := [Vector2(0, -14), Vector2(-14, 9), Vector2(14, 9)]


func stats() -> Dictionary:
	if _stats.is_empty():
		_stats = GameData.TOWERS[type].levels[level].duplicate()
		if spec != "":
			_stats.merge(GameData.SPECS[type][spec], true)
	return _stats


func spec_data() -> Dictionary:
	return GameData.SPECS[type][spec] if spec != "" else {}


## Дальность с учётом возвышенности.
func get_range() -> float:
	return float(stats().range) * main.range_mult(slot)


## Статы рыцаря с учётом бонуса «Тяжёлые доспехи».
func knight_stats() -> Dictionary:
	var s: Dictionary = stats().duplicate()
	s.hp = float(s.hp) * main.buff_val("armor", 1.3, 1.0)
	return s


func n_archers() -> int:
	if spec != "":
		return int(stats().archers)
	return 2 if unit_mode == "archers" and level >= 1 else 0


func max_level() -> int:
	return GameData.TOWERS[type].levels.size() - 1


func upgrade_cost() -> int:
	if level >= max_level():
		return -1
	return GameData.TOWERS[type].levels[level + 1].cost


func sell_value() -> int:
	return int(invested * main.buff_val("economy", 0.8, 0.6))


## Точка, откуда вылетают снаряды (верх спрайта).
func muzzle() -> Vector2:
	var h := Art.tower_height(type, level)
	if type == "crossbow":
		# наконечник болта — на том краю баллисты, куда она смотрит
		return position + Vector2(-aim * h * 0.3, -h * 0.85)
	return position + Vector2(0, -h * 0.9)


func setup(m: Node, tp: String, pos: Vector2, slot_idx: int) -> void:
	main = m
	type = tp
	slot = slot_idx
	position = pos
	invested = stats().cost
	build_t = 0.35
	max_hp = 160.0
	hp = max_hp
	if type == "barracks":
		rally = main.closest_road_point(pos)
		for i in 3:
			respawn[i] = 0.01 + i * 0.3


func upgrade(sp: String = "") -> void:
	level += 1
	spec = sp
	_stats = {}
	invested += stats().cost
	build_t = 0.3
	max_hp = 160.0 + 80.0 * level
	hp = max_hp
	if type == "barracks":
		for s in soldiers:
			if s != null and is_instance_valid(s):
				s.apply_stats(knight_stats(), true)
		for a in archers:
			if a != null and is_instance_valid(a):
				a.apply_stats(_archer_stats(), true)


func _archer_stats() -> Dictionary:
	return GameData.BARRACKS_ARCHERS[level]


## Бонус «Тяжёлые доспехи» выбран посреди боя — обновляем живых рыцарей.
func refresh_knights() -> void:
	for s in soldiers:
		if s != null and is_instance_valid(s) and not s.dead:
			var old: float = s.max_hp
			s.apply_stats(knight_stats(), false)
			s.hp += s.max_hp - old


## Смена отряда казармы: текущие бойцы уходят, новые выбегают сразу.
func set_mode(m: String) -> void:
	if m == unit_mode or level < 1:
		return
	unit_mode = m
	# рыцари остаются на месте; лучники либо выбегают к ним, либо уходят в казарму
	for s in archers:
		if s != null and is_instance_valid(s) and not s.dead:
			s.tower = null
			s.release_target()
			main.spawn_fx("puff", s.position)
			s.queue_free()
	archers = [null, null, null, null]
	archer_respawn = [0.05, 0.3, 0.55, 0.8]


func remove() -> void:
	for s in soldiers + archers:
		if s != null and is_instance_valid(s) and not s.dead:
			s.tower = null
			s.release_target()
			s.queue_free()
	queue_free()


func _process(delta: float) -> void:
	t += delta
	anim = maxf(0.0, anim - delta * 3.0)
	hurt_t = maxf(0.0, hurt_t - delta)
	if type == "crossbow":
		# поворот баллисты: «сжатие» до 0 и разворот, ~0.18 с
		aim = move_toward(aim, aim_target, delta * 11.0)
	build_t = maxf(0.0, build_t - delta)
	if stun_t > 0.0:
		stun_t -= delta
		queue_redraw()
		if type != "barracks":
			return
	if type == "barracks":
		_barracks_tick(delta)
	else:
		cd -= delta
		if cd <= 0.0:
			var e := _find_target()
			if e != null:
				if _fire(e):
					cd = float(stats().rate) * Shop.tower_rate_mult(type)
	queue_redraw()


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_rem := INF
	var r: float = get_range()
	for e in main.enemies:
		if e.dead:
			continue
		if e.position.distance_to(position) <= r and e.remaining() < best_rem:
			best = e
			best_rem = e.remaining()
	return best


## false — выстрела не было (баллиста ещё разворачивается).
func _fire(e: Enemy) -> bool:
	var s := stats()
	var d: Vector2 = s.dmg
	var dmg := randf_range(d.x, d.y) * Shop.tower_dmg_mult(type)
	if type == "crossbow":
		dmg *= main.buff_val("bolts", 1.2, 1.0)
	anim = 1.0
	match type:
		"crossbow":
			aim_target = 1.0 if e.position.x < position.x else -1.0
			if absf(aim - aim_target) > 0.5:
				anim = 0.0
				cd = 0.05   # сначала развернуться, потом стрелять
				return false
			main.sfx.play("arrow")
			main.spawn_projectile("bolt", muzzle(), e, e.position, dmg, 0.0)
		"mage":
			_chain_lightning(e, dmg, int(s.chain) + int(main.buff_val("overload", 1, 0)))
	return true


func _chain_lightning(first: Enemy, dmg: float, count: int) -> void:
	var hit: Array = []
	var from := muzzle()
	var cur := first
	var sd := spec_data()
	var jump_k: float = sd.get("jump_k", 0.7)
	for i in count:
		hit.append(cur)
		main.spawn_beam(from, cur.hit_point())
		cur.take_damage(dmg, Enemy.Dmg.MAGIC)
		if sd.has("slow"):
			cur.apply_slow(sd.slow, sd.slow_t)
		from = cur.hit_point()
		dmg *= jump_k
		var next: Enemy = null
		var nd := 95.0
		for e in main.enemies:
			if e.dead or hit.has(e):
				continue
			var dd: float = e.hit_point().distance_to(from)
			if dd < nd:
				nd = dd
				next = e
		if next == null:
			break
		cur = next
	if hit.size() > 1 and randf() < 0.4:
		main.spawn_text(first.position + Vector2(0, -30), "ZAP!", Color(0.85, 0.6, 1.0))


func _barracks_tick(delta: float) -> void:
	var n_knights := 3
	for i in n_knights:
		var s = soldiers[i]
		if s != null and is_instance_valid(s) and not s.dead:
			continue
		soldiers[i] = null
		respawn[i] -= delta
		if respawn[i] <= 0.0:
			var sol := Soldier.new()
			sol.setup(main, rally, FORMATION[i], knight_stats(), "knight")
			sol.tower = self
			sol.position = position + Vector2(0, 6)
			main.world.add_child(sol)
			soldiers[i] = sol
	var n_arch := n_archers()
	for i in n_arch:
		var a = archers[i]
		if a != null and is_instance_valid(a) and not a.dead:
			continue
		archers[i] = null
		archer_respawn[i] -= delta
		if archer_respawn[i] <= 0.0:
			var ar := Soldier.new()
			# лучники стоят чуть позади рыцарей, ближе к казарме
			var back := (position - rally).normalized() * 30.0
			var step := 32.0 if n_arch <= 2 else 22.0
			ar.setup(main, rally, back + Vector2((i - (n_arch - 1) * 0.5) * step, 0), _archer_stats(), "archer")
			ar.tower = self
			ar.position = position + Vector2(0, 6)
			main.world.add_child(ar)
			archers[i] = ar


func take_damage(d: float) -> void:
	if dead:
		return
	hp -= d
	hurt_t = 0.15
	if hp <= 0.0:
		dead = true
		main.destroy_tower(self)


func on_soldier_died(s: Soldier) -> void:
	var i := soldiers.find(s)
	if i >= 0:
		soldiers[i] = null
		respawn[i] = stats().respawn
		return
	i = archers.find(s)
	if i >= 0:
		archers[i] = null
		archer_respawn[i] = stats().respawn


func _draw() -> void:
	var sc := 1.0 + build_t * 0.6
	var shake := Vector2(randf_range(-2, 2), 0) if hurt_t > 0.0 else Vector2.ZERO
	Art.draw_tower(self, type, level, t, anim, Transform2D(0, Vector2(sc, 2.0 - sc), 0, shake), aim)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if spec != "":
		_draw_spec_badge(Vector2(22, 26))
	if stun_t > 0.0:
		var h := Art.tower_height(type, level)
		Art.ellipse(self, Vector2(0, -h * 0.45), 34, h * 0.55, Color(0.1, 0.1, 0.15, 0.45))
		for k in 3:
			var a := t * 4.0 + k * TAU / 3.0
			var p := Vector2(cos(a) * 22, -h * 0.95 + sin(a) * 7)
			Art.star_icon(self, p, 14, true)
	if hp < max_hp:
		Art.hp_bar(self, Vector2(0, 16), 40, hp / max_hp)


func _draw_spec_badge(c: Vector2) -> void:
	var col: Color = spec_data().color
	var pts := PackedVector2Array([c + Vector2(0, -11), c + Vector2(10, 0), c + Vector2(0, 11), c + Vector2(-10, 0)])
	Art.poly_o(self, pts, col, 2)
	Art.text(self, c + Vector2(0, 5), Loc.t(spec_data().name).substr(0, 1), 13, Color(0.1, 0.06, 0.03), HORIZONTAL_ALIGNMENT_CENTER, -1, 0)
