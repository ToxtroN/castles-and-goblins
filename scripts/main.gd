extends Node2D
## Castles and Goblins — главный скрипт: карта, волны, экономика, ввод.
## Управление: ЛКМ по месту — построить; ЛКМ по башне — улучшить/продать;
## H или портрет — выбрать героя, затем ЛКМ — куда идти; 1/2 — способности;
## Пробел — вызвать волну; P — пауза; ПКМ/Esc — отмена.

const GATE := Vector2(640, 40)

var level := 1
var PATHS: Array = []           # дороги текущего уровня (из Levels)
var SLOTS: Array = []           # места под башни
var ENTRY_POINTS: Array = []    # где дорога входит на экран (черепа волн)
var WAVES: Array = []           # 3 волны уровня
var stars_earned := 0
var coins_earned := 0
var art: Dictionary = {}         # готовая картинка карты (если есть)
var art_tex: Texture2D

var curves: Array[Curve2D] = []
var slot_towers := {}
var enemies: Array = []
var gold := 0
var lives := GameData.START_LIVES
var wave_index := 0
var spawn_groups: Array = []
var next_wave_timer := -1.0     # >0 отсчёт; -1 ждём игрока; -2 идёт спавн; -3 волны кончились
var game_state := "play"
var kills := 0
var leaks := {}
var towers_lost := 0
var message := ""
var message_t := 0.0
var damage_flash := 0.0
var targeting := ""
var cooldowns := {"meteor": 0.0, "artillery": 0.0, "gold": 0.0, "cavalry": 0.0}

var world: Node2D
var proj_layer: Node2D
var fx_layer: Node2D
var menu: RadialMenu
var hud: Hud
var heroes := {}                # вид героя -> Hero (только пока он на поле)
var road_graph := AStar2D.new()
var music: AudioStreamPlayer
var sfx: Sfx
var overlay: Node = null      # экран улучшений поверх итогов боя

var trees: Array = []
var decor: Array = []

# бонусы между волнами
var buffs: Array = []            # выбранные бонусы (GameData.BUFFS)
var buff_choice: Array = []      # два варианта на выбор (пока выбор открыт, игра на паузе)
var buff_offered := 0            # перед какой волной уже предлагали
var auto_buffs := false          # автотест: выбирать сразу
# механики карты
var mech: Array = []
var swamps: Array = []           # {p, rx, ry}
var high_slots: Array = []
var shrine := Vector2.INF
var mine := Vector2.INF
var mine_t := 0.0
var mine_flash := 0.0
var max_lives := GameData.START_LIVES
var boss: Enemy = null
var msg_queue: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 1.0
	get_tree().paused = false
	level = Levels.current
	gold = Levels.start_gold(level) + (20 if Kingdom.has("gold") else 0)
	if Kingdom.has("walls"):
		max_lives += 2
	lives = max_lives
	WAVES = Levels.waves(level)
	art = Levels.art_map(level)
	PATHS = Levels.paths(level).duplicate() if not art.is_empty() else _join_paths(Levels.paths(level))
	_build_curves()
	if art.is_empty():
		SLOTS = Levels.make_slots(curves)
	else:
		SLOTS = art.slots.duplicate()
		art_tex = load(art.image)
	for c in curves:
		var pts := c.get_baked_points()
		var e: Vector2 = pts[0]
		for q in pts:
			if q.x > 30 and q.x < 1250 and q.y < 690:
				e = q
				break
		ENTRY_POINTS.append(e)
	_generate_decor()

	world = Node2D.new()
	world.y_sort_enabled = true
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	proj_layer = Node2D.new()
	proj_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(proj_layer)
	fx_layer = Node2D.new()
	fx_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(fx_layer)
	menu = RadialMenu.new()
	menu.visible = false
	add_child(menu)

	_build_road_graph()
	sfx = Sfx.new()
	add_child(sfx)
	music = AudioStreamPlayer.new()
	var stream: AudioStream = load("res://assets/game_music.mp3")
	if stream is AudioStreamMP3:
		stream.loop = true
	music.stream = stream
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music)
	music.play()
	apply_music()

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.main = self
	layer.add_child(hud)

	show_message("Уровень %d — выдержите 3 волны!" % level, 3.5)
	_setup_mechanics()
	for m in mech:
		msg_queue.append(Levels.MECH_INFO[m])
	if Levels.is_boss_level(level):
		msg_queue.append("Финал: в 3-й волне придёт Король гоблинов!")


# ---------------------------------------------------------------- МЕХАНИКИ КАРТЫ
func _setup_mechanics() -> void:
	mech = Levels.mechanics(level)
	var c0: Curve2D = curves[0]
	var L := c0.get_baked_length()
	if mech.has("swamp"):
		# топь — на участке дороги ближе к середине, вне зоны кнопок
		var best := Vector2.INF
		var best_sc := INF
		for ci in curves.size():
			var cl: float = curves[ci].get_baked_length()
			for k in range(20, 75, 3):
				var p: Vector2 = curves[ci].sample_baked(cl * k / 100.0)
				if not _free_spot(p, 20.0) or p.y < 190.0:
					continue
				var sd := INF
				for sl in SLOTS:
					sd = minf(sd, minf(p.distance_to(sl), p.distance_to(sl + Vector2(0, -75))))
				if sd < 110.0:
					continue
				var sc := absf(k - 45.0) + ci * 15.0
				if sc < best_sc:
					best_sc = sc
					best = p
		if best != Vector2.INF:
			swamps.append({"p": best, "rx": 84.0, "ry": 56.0})
	if mech.has("shrine"):
		for f in [0.72, 0.66, 0.78, 0.6, 0.84]:
			var p := c0.sample_baked(L * f)
			if _free_spot(p, 0.0) and (swamps.is_empty() or p.distance_to(swamps[0].p) > 170.0):
				shrine = p
				break
	if mech.has("mine"):
		mine = _find_mine_spot(c0, L)
	if mech.has("high") and SLOTS.size() > 0:
		# возвышенность — места ближе всего к середине главной дороги
		var mid := c0.sample_baked(L * 0.5)
		var idx: Array = range(SLOTS.size())
		idx = idx.filter(func(i): return SLOTS[i].y > 200.0 and SLOTS[i].y < 600.0)
		idx.sort_custom(func(a, b): return SLOTS[a].distance_to(mid) < SLOTS[b].distance_to(mid))
		for i in mini(2 if SLOTS.size() >= 5 else 1, idx.size()):
			high_slots.append(idx[i])


func _free_spot(p: Vector2, margin: float) -> bool:
	if p.x < 60 + margin or p.x > 1220 - margin or p.y < 110 + margin or p.y > 620 - margin:
		return false
	if Rect2(0, 590, 360, 130).has_point(p) or Rect2(1080, 0, 200, 110).has_point(p):
		return false
	return true


## Шахта: место в стороне от дороги, не на башенных площадках.
func _find_mine_spot(c0: Curve2D, L: float) -> Vector2:
	var best := Vector2.INF
	var best_score := INF
	var target := c0.sample_baked(L * 0.35)
	for gx in range(80, 1200, 20):
		for gy in range(130, 600, 20):
			var p := Vector2(gx, gy)
			if not _free_spot(p, 10.0):
				continue
			var rd := road_distance(p)
			if rd < 70.0 or rd > 110.0:
				continue
			var sd := INF
			for s in SLOTS:
				sd = minf(sd, minf(p.distance_to(s), p.distance_to(s + Vector2(0, -75))))
			if sd < 95.0:
				continue
			if shrine != Vector2.INF and p.distance_to(shrine) < 120.0:
				continue
			if not swamps.is_empty() and p.distance_to(swamps[0].p) < 150.0:
				continue
			var score := p.distance_to(target)
			if score < best_score:
				best_score = score
				best = p
	return best


func range_mult(slot_idx: int) -> float:
	return 1.25 if high_slots.has(slot_idx) else 1.0


func zone_speed(p: Vector2) -> float:
	for z in swamps:
		var d: Vector2 = (p - z.p) / Vector2(z.rx, z.ry)
		if d.length() < 1.0:
			return 0.6
	return 1.0


func _mech_tick(delta: float) -> void:
	mine_flash = maxf(0.0, mine_flash - delta)
	if shrine != Vector2.INF:
		for h in heroes.values():
			if not h.dead and h.position.distance_to(shrine) < 95.0:
				h.hp = minf(h.max_hp, h.hp + 18.0 * delta)
	if mine != Vector2.INF and wave_index > 0:
		var safe := true
		for en in enemies:
			if en.position.distance_to(mine) < 170.0:
				safe = false
				break
		if safe:
			mine_t += delta
			if mine_t >= 10.0:
				mine_t = 0.0
				gold += 6
				mine_flash = 1.2
				spawn_text(mine + Vector2(0, -40), "+6", Color(1, 0.85, 0.3))
		else:
			mine_t = maxf(0.0, mine_t - delta)


# ---------------------------------------------------------------- БОНУСЫ
func buff_val(id: String, on, off):
	return on if buffs.has(id) else off


func _offer_buffs() -> void:
	var pool: Array = GameData.BUFFS.keys().filter(func(b): return not buffs.has(b))
	pool.shuffle()
	buff_choice = pool.slice(0, 2)
	buff_offered = wave_index
	menu.close()
	targeting = ""
	if auto_buffs:
		pick_buff(buff_choice[0])
		return
	get_tree().paused = true


func pick_buff(id: String) -> void:
	if not buff_choice.has(id):
		return
	buffs.append(id)
	buff_choice = []
	get_tree().paused = false
	sfx.play("star")
	show_message(GameData.BUFFS[id].name + "!", 2.0)
	if id == "armor":
		for t in slot_towers.values():
			if t.type == "barracks":
				t.refresh_knights()


func hero_cooldown(id: String) -> float:
	if GameData.HEROES.has(id):
		return GameData.HEROES[id].cooldown * buff_val("summon", 0.8, 1.0)
	return GameData.ABILITIES[id].cooldown


# ---------------------------------------------------------------- КОРОЛЬ ГОБЛИНОВ
## Фаза 1: из других входов выбегает подмога.
func king_summon(k: Enemy) -> void:
	var others: Array = []
	for i in curves.size():
		if i != k.path_idx:
			others.append(i)
	if others.is_empty():
		others = [k.path_idx]
	for j in 2:
		var pi: int = others[j % others.size()]
		spawn_groups.append({"type": "spearman", "left": 3, "path": pi, "interval": 0.9, "timer": 0.2 + j * 0.6})
		spawn_groups.append({"type": "grunt", "left": 5, "path": pi, "interval": 0.6, "timer": 1.5 + j * 0.6})
	spawn_groups.append({"type": "mage", "left": 2, "path": others[0], "interval": 1.2, "timer": 3.0})
	show_message("Король зовёт подмогу!", 2.5)


## Фаза 2: удар булавой оглушает ближайшую башню и раскидывает солдат рядом.
func king_smash(k: Enemy) -> void:
	var best: Tower = null
	var bd := INF
	for t in slot_towers.values():
		var d: float = t.position.distance_to(k.position)
		if d < bd:
			bd = d
			best = t
	spawn_explosion("fx_artillery", k.position + Vector2(k.facing * 40, 0), 150)
	for u in get_units():
		if u.position.distance_to(k.position) < 90.0:
			u.take_damage(45.0)
	if best != null:
		best.stun_t = 10.0
		best.take_damage(60.0)
		spawn_fx("ring", best.position).radius = 60
		spawn_text(best.position + Vector2(0, -90), "Башня оглушена!", Color(1, 0.5, 0.3))
	spawn_text(k.position + Vector2(0, -130), "КРАК!", Color(1, 0.6, 0.2))
	sfx.play("artillery")


## Дорога, которая заканчивается не у ворот, продолжается по той дороге, в которую она вливается.
func _join_paths(src: Array) -> Array:
	var res: Array = []
	for pts in src:
		res.append(pts.duplicate())
	for i in res.size():
		var pts: Array = res[i]
		var end: Vector2 = pts[pts.size() - 1]
		if end.distance_to(Vector2(640, 30)) < 5.0:
			continue
		var best_j := -1
		var best_k := -1
		var best_d := INF
		for j in res.size():
			if j == i:
				continue
			var q: Array = res[j]
			if q[q.size() - 1].distance_to(Vector2(640, 30)) > 5.0:
				continue
			for k in q.size() - 1:
				var cp := Geometry2D.get_closest_point_to_segment(end, q[k], q[k + 1])
				if cp.distance_to(end) < best_d:
					best_d = cp.distance_to(end)
					best_j = j
					best_k = k
		if best_j >= 0:
			var q2: Array = res[best_j]
			for k in range(best_k + 1, q2.size()):
				if q2[k].distance_to(pts[pts.size() - 1]) > 3.0:
					pts.append(q2[k])
	return res


func _build_curves() -> void:
	for pts in PATHS:
		var c := Curve2D.new()
		c.bake_interval = 4.0
		for i in pts.size():
			var p: Vector2 = pts[i]
			var handle := Vector2.ZERO
			if i > 0 and i < pts.size() - 1:
				handle = (pts[i + 1] - pts[i - 1]) * 0.22
			c.add_point(p, -handle, handle)
		curves.append(c)


func _generate_decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for gx in range(0, 1300, 34):
		for gy in range(70, 740, 30):
			var p := Vector2(gx + rng.randf_range(-12, 12), gy + rng.randf_range(-10, 10))
			var rd := road_distance(p)
			var sd := INF
			for s in SLOTS:
				sd = minf(sd, p.distance_to(s))
			if sd < 55.0 or rd < 52.0:
				continue
			var hud_zone := Rect2(0, 610, 320, 110).has_point(p)
			var chance := 0.75 if rd > 120.0 else 0.1
			if hud_zone:
				chance = 0.0
			if rng.randf() < chance:
				trees.append({"p": p, "r": rng.randf_range(13, 20), "shade": rng.randf_range(-0.05, 0.05)})
			elif rng.randf() < 0.25:
				decor.append({"p": p, "k": rng.randi() % 3, "r": rng.randf_range(3, 7)})
	trees.sort_custom(func(a, b): return a.p.y < b.p.y)


# ---------------------------------------------------------------- ГЕОМЕТРИЯ
func road_distance(p: Vector2) -> float:
	var best := INF
	for c in curves:
		best = minf(best, c.get_closest_point(p).distance_to(p))
	return best


func closest_road_point(p: Vector2) -> Vector2:
	var best := Vector2.ZERO
	var bd := INF
	for c in curves:
		var q := c.get_closest_point(p)
		if q.distance_to(p) < bd and q.y > 80.0 and q.x > 10 and q.x < 1270 and q.y < 700:
			bd = q.distance_to(p)
			best = q
	return best


func near_road(p: Vector2, r: float = 34.0) -> bool:
	return road_distance(p) < r and p.y > 60.0


## Граф дорог: точки вдоль всех путей + связи на развилках. Юниты ходят только по нему.
func _build_road_graph() -> void:
	var id := 0
	var per_curve: Array = []
	for c in curves:
		var ids: Array = []
		var pts := c.get_baked_points()
		for i in range(0, pts.size(), 4):
			var p: Vector2 = pts[i]
			if p.x < -10 or p.x > 1290 or p.y > 730:
				continue
			road_graph.add_point(id, p)
			if not ids.is_empty():
				road_graph.connect_points(ids[ids.size() - 1], id)
			ids.append(id)
			id += 1
		per_curve.append(ids)
	for a in per_curve.size():
		for b in range(a + 1, per_curve.size()):
			for i in per_curve[a]:
				for j in per_curve[b]:
					if road_graph.get_point_position(i).distance_to(road_graph.get_point_position(j)) < 14.0:
						road_graph.connect_points(i, j)


func road_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := road_graph.get_closest_point(from)
	var b := road_graph.get_closest_point(to)
	var res := road_graph.get_point_path(a, b)
	if res.size() > 0 and res[0].distance_to(from) < 20.0:
		res.remove_at(0)
	res.append(closest_road_point(to))
	return res


# ---------------------------------------------------------------- ЦИКЛ
func _process(delta: float) -> void:
	message_t = maxf(0.0, message_t - delta)
	_update_messages()
	damage_flash = maxf(0.0, damage_flash - delta * 2.0)
	if art_tex != null:
		queue_redraw()
	if get_tree().paused or game_state != "play":
		return
	for k in cooldowns:
		cooldowns[k] = maxf(0.0, cooldowns[k] - delta)
	_update_spawning(delta)
	_mech_tick(delta)
	if boss != null and (not is_instance_valid(boss) or boss.dead):
		boss = null
	if next_wave_timer == -2.0 and spawn_groups.is_empty():
		next_wave_timer = GameData.WAVE_GAP if wave_index < WAVES.size() else -3.0
		if wave_index < WAVES.size() and buff_offered < wave_index:
			_offer_buffs()
	if next_wave_timer > 0.0:
		next_wave_timer -= delta
		if next_wave_timer <= 0.0:
			next_wave_timer = 0.0
			start_next_wave()
	if next_wave_timer == -3.0 and enemies.is_empty() and spawn_groups.is_empty():
		game_state = "win"
		_end_sound("win")
		stars_earned = Levels.stars_for_lives(GameData.START_LIVES - (max_lives - lives))
		Levels.save_stars(level, stars_earned)
		coins_earned = Shop.reward(level, stars_earned, kills)
		Shop.add_coins(coins_earned)
		menu.close()


func _update_spawning(delta: float) -> void:
	var mult := Levels.hp_mult(level, wave_index - 1)
	for g in spawn_groups:
		g.timer -= delta
		if g.timer <= 0.0 and g.left > 0:
			g.timer = g.interval
			g.left -= 1
			spawn_enemy(g.type, g.path, mult)
	spawn_groups = spawn_groups.filter(func(g): return g.left > 0)


func spawn_enemy(type: String, path: int, mult: float) -> void:
	if type == "king":
		path = _king_path()
	var e := Enemy.new()
	e.setup(self, type, curves[path], mult)
	e.path_idx = path
	world.add_child(e)
	if type == "king":
		boss = e
		show_message("КОРОЛЬ ГОБЛИНОВ!", 3.0)
		sfx.play("lose")
	enemies.append(e)


# ---------------------------------------------------------------- ВОЛНЫ
func can_call_wave() -> bool:
	return game_state == "play" and wave_index < WAVES.size() \
		and spawn_groups.is_empty() and (next_wave_timer > 0.0 or next_wave_timer == -1.0)


func early_bonus() -> int:
	if next_wave_timer > 0.0:
		var b := int(next_wave_timer) * GameData.EARLY_BONUS_PER_SEC
		return int(b * 1.25) if Kingdom.has("horn") else b
	return 0


func next_wave_paths() -> Array:
	var res := []
	if wave_index >= WAVES.size():
		return res
	for g in WAVES[wave_index]:
		if not res.has(g[2]):
			res.append(g[2])
	return res


func start_next_wave() -> void:
	if wave_index >= WAVES.size() or not spawn_groups.is_empty():
		return
	var bonus := early_bonus()
	if bonus > 0:
		gold += bonus
		spawn_text(Vector2(450, 70), "+%d золота" % bonus, Color(1, 0.85, 0.3))
	for g in WAVES[wave_index]:
		spawn_groups.append({"type": g[0], "left": g[1], "path": g[2], "interval": g[3], "timer": g[4]})
	wave_index += 1
	next_wave_timer = -2.0
	show_message("Волна %d" % wave_index, 2.0)


## Король идёт по дороге, вдоль которой больше всего мест под башни (самый «честный» бой).
func _king_path() -> int:
	var best := 0
	var best_n := -1.0
	for i in curves.size():
		var n := 0.0
		for s in SLOTS:
			var d: float = curves[i].get_closest_point(s).distance_to(s)
			if d < 200.0:
				n += 1.0
		n += curves[i].get_baked_length() / 2000.0
		if n > best_n:
			best_n = n
			best = i
	return best


func _update_messages() -> void:
	if message_t <= 0.0 and not msg_queue.is_empty():
		show_message(msg_queue.pop_front(), 3.5)


func show_message(m: String, dur: float) -> void:
	message = m
	message_t = dur


# ---------------------------------------------------------------- СОБЫТИЯ
func enemy_killed(e: Enemy) -> void:
	var bounty: int = e.data.gold
	gold += bounty
	kills += 1
	enemies.erase(e)
	_spawn_corpse(e)
	e.queue_free()


func _spawn_corpse(e: Enemy) -> void:
	var fx := spawn_fx("sprite", e.position)
	if SpriteLib.has(e.kind, "death"):
		fx.play(SpriteLib.frames(e.kind, "death"), 10.0, e.sprite_scale, e.facing < 0, false, 0.6)
	else:
		var tex := e.current_frame()
		if tex == null:
			fx.queue_free()
			spawn_fx("puff", e.position)
			return
		fx.play([tex], 10.0, e.sprite_scale, e.facing < 0, false, 0.25)
		spawn_fx("puff", e.position + Vector2(0, -e.fly_offset() - 10))
	if e.flying:
		fx.position.y -= e.fly_offset()


func enemy_reached_castle(e: Enemy) -> void:
	e.dead = true
	leaks[e.kind] = leaks.get(e.kind, 0) + 1
	lives = maxi(0, lives - int(e.data.lives))
	enemies.erase(e)
	e.queue_free()
	damage_flash = 1.0
	if lives <= 0 and game_state == "play":
		game_state = "lose"
		coins_earned = Shop.reward(level, 0, kills)
		Shop.add_coins(coins_earned)
		_end_sound("lose")
		menu.close()


func explode(p: Vector2, radius: float, dmg: float, type: int) -> void:
	spawn_explosion("fx_artillery", p, radius * 2.4)
	if randf() < 0.5:
		spawn_text(p + Vector2(0, -30), ["KBOOM!", "БУМ!", "POW!"].pick_random(), Color(1, 0.6, 0.2))
	for e in enemies.duplicate():
		if e.flying:
			continue
		var d: float = e.position.distance_to(p)
		if d <= radius:
			e.take_damage(dmg * (1.0 - 0.4 * d / radius), type)


## Солдаты и герой, по которым могут бить гоблины.
func get_units() -> Array:
	var res := []
	for n in world.get_children():
		if n is Soldier and not n.dead and n.visible:
			res.append(n)
	return res


func spawn_enemy_projectile(proj: String, from: Vector2, to: Vector2, dmg: float, splash: float) -> void:
	sfx.play("hit")
	spawn_projectile("e_" + proj, from, null, to, dmg, splash)


func enemy_projectile_hit(kind: String, p: Vector2, radius: float, dmg: float) -> void:
	for u in get_units():
		if u.position.distance_to(p) <= radius + 8.0:
			u.take_damage(dmg)
	match kind:
		"e_mage":
			var fx := spawn_fx("sprite", p)
			fx.play(SpriteLib.frames("mage", "splash"), 10.0, 0.45, false, true, 0.3)
		"e_cart":
			spawn_fx("boom", p).radius = radius
			spawn_text(p + Vector2(0, -25), "БУМ!", Color(1, 0.6, 0.2))
		"e_rock":
			spawn_fx("boom", p).radius = radius * 0.7
		_:
			spawn_fx("puff", p)


func destroy_tower(t: Tower) -> void:
	if menu.tower == t:
		menu.close()
	slot_towers.erase(t.slot)
	towers_lost += 1
	var fx := spawn_fx("boom", t.position + Vector2(0, -30))
	fx.radius = 70
	spawn_fx("puff", t.position)
	spawn_text(t.position + Vector2(0, -70), "Башня разрушена!", Color(1, 0.4, 0.3))
	t.remove()
	queue_redraw()


func spawn_unit_corpse(u: Soldier) -> void:
	var fx := spawn_fx("sprite", u.position)
	if SpriteLib.has(u.sprite, "death"):
		fx.play(SpriteLib.frames(u.sprite, "death"), 8.0, u.sprite_scale, u.facing < 0, false, 0.8)
	else:
		var tex := u.current_frame()
		if tex == null:
			fx.queue_free()
		else:
			fx.play([tex], 10.0, u.sprite_scale, u.facing < 0, false, 0.25)
	spawn_fx("puff", u.position + Vector2(0, -10))


## Взрыв из нарисованных кадров (assets/units/<kind>/boom_N.png); width — ширина на экране.
func spawn_explosion(kind: String, p: Vector2, width: float) -> void:
	var fr := SpriteLib.frames(kind, "boom")
	if fr.is_empty():
		spawn_fx("boom", p).radius = width * 0.45
		return
	var fx := spawn_fx("sprite", p + Vector2(0, 14))
	fx.play(fr, 9.0, width / fr[0].get_width(), randf() < 0.5, false, 0.15)


func meteor_impact(p: Vector2) -> void:
	var a: Dictionary = GameData.ABILITIES.meteor
	var r: float = a.radius
	spawn_explosion("fx_meteor", p, r * 2.2)
	for e in enemies.duplicate():
		if e.position.distance_to(p) <= r:
			var d: Vector2 = a.dmg
			e.take_damage(randf_range(d.x, d.y), Enemy.Dmg.TRUE)


func spawn_fx(kind: String, p: Vector2) -> Fx:
	var fx := Fx.new()
	fx.setup(self, kind, p)
	fx_layer.add_child(fx)
	return fx


func spawn_text(p: Vector2, txt: String, col: Color) -> void:
	var fx := spawn_fx("text", p)
	fx.text = txt
	fx.color = col


func spawn_beam(from: Vector2, to: Vector2) -> void:
	var fx := spawn_fx("beam", from)
	fx.a = from
	fx.b = to
	fx.make_bolt()


func spawn_projectile(kind: String, from: Vector2, tgt: Enemy, to: Vector2, dmg: float, splash: float) -> void:
	var p := Projectile.new()
	p.setup(self, kind, from, tgt, to, dmg, splash)
	proj_layer.add_child(p)


# ---------------------------------------------------------------- ДЕЙСТВИЯ ИГРОКА
func build(slot_idx: int, type: String) -> void:
	var cost: int = GameData.TOWERS[type].levels[0].cost
	if gold < cost or slot_towers.has(slot_idx) or not Shop.owned(type):
		return
	gold -= cost
	var t := Tower.new()
	t.setup(self, type, SLOTS[slot_idx], slot_idx)
	world.add_child(t)
	slot_towers[slot_idx] = t
	spawn_fx("ring", t.position).radius = 50
	queue_redraw()


func upgrade(t: Tower, sp: String = "") -> void:
	var cost := t.upgrade_cost()
	if cost < 0 or gold < cost:
		return
	gold -= cost
	t.upgrade(sp)
	if sp != "":
		spawn_text(t.position + Vector2(0, -95), GameData.SPECS[t.type][sp].name + "!", Color(1, 0.9, 0.5))
	spawn_fx("ring", t.position).radius = 50


func sell(t: Tower) -> void:
	gold += t.sell_value()
	if menu.tower == t:
		menu.close()
	spawn_text(t.position + Vector2(0, -40), "+%d" % t.sell_value(), Color(1, 0.85, 0.3))
	spawn_fx("puff", t.position)
	slot_towers.erase(t.slot)
	t.remove()
	queue_redraw()


func selected_hero() -> Hero:
	for h in heroes.values():
		if h.selected:
			return h
	return null


func deselect_heroes() -> void:
	for h in heroes.values():
		h.selected = false


## Кнопка внизу: способность или герой. Если герой уже на поле — выбрать его.
func press_button(id: String) -> void:
	if not Shop.owned(id):
		show_message("Герой не куплен — откройте его в «Улучшениях»", 2.5)
		return
	if heroes.has(id):
		var h: Hero = heroes[id]
		var was: bool = h.selected
		targeting = ""
		menu.close()
		deselect_heroes()
		h.selected = not was
		return
	begin_targeting(id)


func begin_targeting(id: String) -> void:
	if cooldowns[id] > 0.0:
		return
	menu.close()
	deselect_heroes()
	targeting = "" if targeting == id else id


func use_ability(id: String, p: Vector2) -> bool:
	if id == "meteor":
		sfx.play("fireball")
		var n := 3 + int(buffs.has("meteors")) + int(Kingdom.has("fire"))
		for i in n:
			var target := p + Vector2(randf_range(-35, 35), randf_range(-20, 20))
			var fx := spawn_fx("meteor", target)
			fx.a = target + Vector2(-160, -480)
			fx.b = target
			fx.delay = i * 0.22
			if i >= 3:
				fx.a = target + Vector2(160, -480)
		cooldowns[id] = GameData.ABILITIES[id].cooldown
		return true
	if GameData.HEROES.has(id):
		if not near_road(p, 45.0):
			spawn_text(p, "Только на дорогу!", Color(1, 0.5, 0.4))
			return false
		summon_hero(id, closest_road_point(p))
		return true
	return false


func summon_hero(id: String, p: Vector2) -> void:
	var h := Hero.new()
	h.setup_hero(self, id, p)
	world.add_child(h)
	heroes[id] = h
	cooldowns[id] = hero_cooldown(id)
	spawn_fx("ring", p).radius = 40
	spawn_fx("puff", p)
	spawn_text(p + Vector2(0, -60), GameData.HEROES[id].name + "!", Color(1, 0.85, 0.3))


func hero_gone(h: Hero) -> void:
	if heroes.get(h.kind) == h:
		heroes.erase(h.kind)


## Конец боя: музыка игры затихает, играет звук победы / поражения.
func _end_sound(id: String) -> void:
	if SplashScreen.music_on:
		create_tween().tween_property(music, "volume_db", -22.0, 0.6)
	sfx.play(id)


func open_upgrades() -> void:
	if overlay != null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var up = load("res://scenes/upgrades.tscn").instantiate()
	up.as_overlay = true
	layer.add_child(up)
	overlay = layer


func close_upgrades() -> void:
	if overlay != null:
		overlay.queue_free()
		overlay = null


func apply_music() -> void:
	VolumePopup.load_volume()


func toggle_music() -> void:
	VolumePopup.toggle_mute()


func toggle_pause() -> void:
	if game_state != "play" or not buff_choice.is_empty():
		return
	get_tree().paused = not get_tree().paused


func toggle_speed() -> void:
	Engine.time_scale = 2.0 if Engine.time_scale < 1.5 else 1.0


## Между боями — логическая пауза: здесь можно показать полноэкранную рекламу.
func _after_ad(cb: Callable) -> void:
	if game_state != "play":
		Yandex.show_fullscreen_ad(cb)
	else:
		cb.call()


func restart() -> void:
	_after_ad(_restart)


func _restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


func go_menu() -> void:
	_after_ad(_go_menu)


func _go_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func next_level() -> void:
	Levels.current = mini(level + 1, Levels.count())
	_after_ad(_restart)


func _cancel() -> void:
	targeting = ""
	deselect_heroes()
	menu.close()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_P:
				toggle_pause()
			KEY_ESCAPE:
				_cancel()
			KEY_SPACE:
				if can_call_wave() and not get_tree().paused:
					start_next_wave()
			KEY_1, KEY_2, KEY_3, KEY_4:
				press_button(GameData.BUTTONS[event.keycode - KEY_1])
			KEY_M:
				toggle_music()
		return
	if not (event is InputEventMouseButton and event.pressed):
		return
	var p := get_global_mouse_position()
	if event.button_index == MOUSE_BUTTON_RIGHT:
		_cancel()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if hud.click(p):
		return
	if get_tree().paused or game_state != "play":
		return
	_world_click(p)


func _world_click(p: Vector2) -> void:
	# 1) прицеливание способности
	if targeting != "":
		if p.y > 60.0 and use_ability(targeting, p):
			targeting = ""
		return
	# 2) открытое меню
	if menu.is_open():
		var id := menu.hit(p)
		if id != "":
			var it: Dictionary = {}
			for x in menu.items:
				if x.id == id:
					it = x
			if not menu.affordable(it):
				return
			if id == "upgrade":
				upgrade(menu.tower)
			elif id.begins_with("spec_"):
				upgrade(menu.tower, id.substr(5))
			elif id == "sell":
				sell(menu.tower)
			elif id.begins_with("mode_"):
				menu.tower.set_mode(id.substr(5))
			else:
				build(menu.slot, id)
			menu.close()
			return
		menu.close()
	# 3) герои
	for h in heroes.values():
		if not h.dead and p.distance_to(h.position + Vector2(0, -h.draw_h * 0.4)) < 26.0:
			press_button(h.kind)
			return
	var sel := selected_hero()
	if sel != null:
		if near_road(p, 60.0):
			sel.move_to(p)
			spawn_fx("ring", closest_road_point(p)).radius = 22
		else:
			spawn_text(p, "Только по дороге!", Color(1, 0.5, 0.4))
		sel.selected = false
		return
	# 4) башни и пустые места
	for i in SLOTS.size():
		var s: Vector2 = SLOTS[i]
		if p.distance_to(s + Vector2(0, -20)) < 36.0:
			if slot_towers.has(i):
				menu.open_tower(self, slot_towers[i])
			else:
				menu.open_build(self, i, s)
			return


# ---------------------------------------------------------------- КАРТА
func _draw() -> void:
	if art_tex != null:
		_draw_art_map()
		return
	draw_rect(Rect2(-10, -10, 1300, 740), Color(0.45, 0.64, 0.25))
	# пятна травы
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 140:
		var p := Vector2(rng.randf_range(0, 1280), rng.randf_range(60, 720))
		Art.ellipse(self, p, rng.randf_range(20, 60), rng.randf_range(10, 25), Color(0.5, 0.7, 0.28, 0.5))
	for i in 220:
		var p := Vector2(rng.randf_range(0, 1280), rng.randf_range(60, 720))
		draw_line(p, p + Vector2(-2, -5), Color(0.33, 0.5, 0.18), 1.5)
		draw_line(p, p + Vector2(2, -5), Color(0.33, 0.5, 0.18), 1.5)
	# дороги: сначала кромка, потом песок
	for c in curves:
		draw_polyline(c.get_baked_points(), Color(0.55, 0.45, 0.28), 70.0, true)
	for c in curves:
		draw_polyline(c.get_baked_points(), Color(0.86, 0.75, 0.5), 58.0, true)
	for c in curves:
		var pts := c.get_baked_points()
		for i in range(0, pts.size(), 9):
			var off := Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20))
			Art.ellipse(self, pts[i] + off, rng.randf_range(2, 4), 1.6, Color(0.7, 0.6, 0.4))
	# декор
	for d in decor:
		match d.k:
			0: Art.ellipse(self, d.p, d.r + 1, d.r * 0.7 + 1, Art.OUTLINE); Art.ellipse(self, d.p, d.r, d.r * 0.7, Color(0.65, 0.63, 0.6))
			1: draw_circle(d.p, 2.5, Color(1, 0.95, 0.4)); draw_circle(d.p + Vector2(5, 2), 2.5, Color(1, 0.6, 0.8))
			2: Art.circle_o(self, d.p, d.r + 3, Color(0.3, 0.55, 0.2), 1.5)
	# места под башни
	for i in SLOTS.size():
		if not slot_towers.has(i):
			Art.draw_slot(self, SLOTS[i])
	# деревья
	for tr in trees:
		_draw_tree(tr.p, tr.r, tr.shade)
	_draw_wall()


func _draw_tree(p: Vector2, r: float, shade: float) -> void:
	Art.shadow(self, p + Vector2(4, r * 0.4), r * 1.1)
	var dark := Color(0.15 + shade, 0.42 + shade, 0.15)
	var mid := Color(0.25 + shade, 0.58 + shade, 0.2)
	var light := Color(0.42 + shade, 0.72 + shade, 0.28)
	draw_circle(p + Vector2(0, -r * 0.6), r + 2, Art.OUTLINE)
	draw_circle(p + Vector2(0, -r * 0.6), r, dark)
	draw_circle(p + Vector2(-r * 0.15, -r * 0.8), r * 0.75, mid)
	draw_circle(p + Vector2(-r * 0.3, -r * 1.0), r * 0.4, light)


func _draw_art_map() -> void:
	draw_texture_rect(art_tex, Rect2(0, 0, 1280, 720), false)
	_draw_mechanics()
	# пустые места под башни — мягкая подсветка поверх каменных кругов
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 400.0)
	for i in SLOTS.size():
		if not slot_towers.has(i):
			var p: Vector2 = SLOTS[i]
			Art.ellipse_outline(self, p, 40, 26, Color(1, 0.9, 0.5, 0.35 + 0.35 * pulse), 2.5)


func _draw_wall() -> void:
	var stone := Color(0.7, 0.68, 0.64)
	var dark := Color(0.5, 0.48, 0.45)
	draw_rect(Rect2(0, 0, 1280, 62), Art.OUTLINE)
	draw_rect(Rect2(0, 0, 1280, 58), stone)
	for row in 3:
		var y := 6 + row * 17
		draw_line(Vector2(0, y + 16), Vector2(1280, y + 16), dark, 1.5)
		for x in range(-20 + (row % 2) * 22, 1280, 44):
			draw_line(Vector2(x, y), Vector2(x, y + 16), dark, 1.5)
	for x in range(0, 1280, 36):
		Art.rect_o(self, Rect2(x + 4, 52, 22, 12), stone, 2)
	# ворота
	draw_rect(Rect2(600, 0, 80, 60), Color(0.25, 0.18, 0.12))
	for x in range(604, 680, 10):
		draw_line(Vector2(x, 0), Vector2(x, 60), Color(0.15, 0.1, 0.07), 2)
	for gx in [575.0, 705.0]:
		Art.ellipse(self, Vector2(gx, 62), 32, 14, Art.OUTLINE)
		draw_rect(Rect2(gx - 30, -10, 60, 72), Art.OUTLINE)
		draw_rect(Rect2(gx - 28, -10, 56, 72), stone)
		Art.ellipse(self, Vector2(gx, 62), 28, 11, stone)
		for k in 3:
			draw_line(Vector2(gx - 28, 15 + k * 18), Vector2(gx + 28, 15 + k * 18), dark, 1.5)
		draw_rect(Rect2(gx - 4, 22, 8, 16), Color(0.15, 0.12, 0.1))


## Топь, святилище, шахта и флажки возвышенностей поверх карты.
func _draw_mechanics() -> void:
	var tm := Time.get_ticks_msec() / 1000.0
	for z in swamps:
		var c: Vector2 = z.p
		Art.ellipse(self, c, z.rx + 7, z.ry + 6, Color(0.18, 0.2, 0.08, 0.55), 40)
		Art.ellipse(self, c, z.rx, z.ry, Color(0.3, 0.36, 0.13, 0.85), 40)
		Art.ellipse(self, c + Vector2(-12, 6), z.rx * 0.62, z.ry * 0.52, Color(0.22, 0.3, 0.1, 0.8), 32)
		Art.ellipse(self, c + Vector2(20, -10), z.rx * 0.3, z.ry * 0.22, Color(0.45, 0.55, 0.25, 0.6), 24)
		# пузыри
		for i in 6:
			var ph := fmod(tm * 0.6 + i * 0.37, 1.0)
			var bp := c + Vector2(cos(i * 2.4) * z.rx * 0.6, sin(i * 1.7) * z.ry * 0.55)
			draw_arc(bp, 2.0 + ph * 4.0, 0, TAU, 12, Color(0.6, 0.75, 0.4, 0.8 * (1.0 - ph)), 1.5)
		# камыши по краю
		for i in 9:
			var a := i * TAU / 9.0 + 0.3
			var rp := c + Vector2(cos(a) * z.rx * 0.98, sin(a) * z.ry * 0.98)
			var sway := sin(tm * 1.5 + i) * 2.0
			draw_line(rp, rp + Vector2(-2 + sway, -16), Color(0.25, 0.4, 0.12), 2.0)
			draw_line(rp + Vector2(4, 0), rp + Vector2(5 + sway, -12), Color(0.3, 0.45, 0.15), 2.0)
			Art.ellipse(self, rp + Vector2(-2 + sway, -17), 1.8, 4, Color(0.45, 0.28, 0.12))
	if shrine != Vector2.INF:
		var pulse := 0.5 + 0.5 * sin(tm * 2.5)
		Art.ellipse(self, shrine, 95, 66, Color(0.4, 1.0, 0.6, 0.06 + 0.05 * pulse), 40)
		Art.ellipse_outline(self, shrine, 95, 66, Color(0.5, 1.0, 0.7, 0.35 + 0.25 * pulse), 2.0)
		Art.ellipse_outline(self, shrine, 40, 26, Color(0.6, 1.0, 0.8, 0.7), 2.5)
		for i in 6:
			var a := i * TAU / 6.0 + tm * 0.4
			var rp := shrine + Vector2(cos(a) * 40, sin(a) * 26)
			draw_circle(rp, 3.0, Color(0.7, 1.0, 0.85, 0.9))
		# каменные столбы
		for sx in [-58.0, 58.0]:
			var b := shrine + Vector2(sx, -6)
			Art.rect_o(self, Rect2(b + Vector2(-7, -34), Vector2(14, 34)), Color(0.66, 0.64, 0.6), 2)
			draw_rect(Rect2(b + Vector2(-7, -34), Vector2(5, 34)), Color(0.78, 0.76, 0.72))
			Art.rect_o(self, Rect2(b + Vector2(-10, -38), Vector2(20, 6)), Color(0.55, 0.53, 0.5), 2)
			draw_circle(b + Vector2(0, -46), 9 + pulse * 3, Color(0.5, 1.0, 0.7, 0.25))
			Art.poly_o(self, PackedVector2Array([b + Vector2(0, -55), b + Vector2(5, -46), b + Vector2(0, -38), b + Vector2(-5, -46)]),
				Color(0.55, 1.0, 0.75), 1.5)
	if mine != Vector2.INF:
		var m := mine
		Art.shadow(self, m + Vector2(0, 4), 34)
		# вход в шахту: тёмная арка в деревянной раме
		Art.poly_o(self, PackedVector2Array([m + Vector2(-30, 2), m + Vector2(-26, -34), m + Vector2(0, -46),
			m + Vector2(26, -34), m + Vector2(30, 2)]), Color(0.45, 0.4, 0.36), 2)
		draw_colored_polygon(PackedVector2Array([m + Vector2(-17, 2), m + Vector2(-15, -24), m + Vector2(0, -32),
			m + Vector2(15, -24), m + Vector2(17, 2)]), Color(0.08, 0.06, 0.05))
		Art.rect_o(self, Rect2(m + Vector2(-20, -30), Vector2(6, 32)), Color(0.55, 0.36, 0.18), 1.5)
		Art.rect_o(self, Rect2(m + Vector2(14, -30), Vector2(6, 32)), Color(0.55, 0.36, 0.18), 1.5)
		Art.rect_o(self, Rect2(m + Vector2(-23, -34), Vector2(46, 7)), Color(0.6, 0.4, 0.2), 1.5)
		# вагонетка с золотом
		var cp := m + Vector2(34, 2)
		Art.poly_o(self, PackedVector2Array([cp + Vector2(-14, -16), cp + Vector2(14, -16), cp + Vector2(10, -3),
			cp + Vector2(-10, -3)]), Color(0.4, 0.3, 0.25), 1.5)
		for gx in [-7.0, 0.0, 7.0]:
			Art.circle_o(self, cp + Vector2(gx, -18 - absf(gx) * -0.2), 4, Color(1, 0.8, 0.2), 1)
		Art.circle_o(self, cp + Vector2(-8, -1), 3, Color(0.2, 0.2, 0.2), 1)
		Art.circle_o(self, cp + Vector2(8, -1), 3, Color(0.2, 0.2, 0.2), 1)
		# шкала до следующей выплаты
		var k := mine_t / 10.0
		draw_rect(Rect2(m + Vector2(-22, 10), Vector2(44, 5)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(m + Vector2(-22, 10), Vector2(44 * k, 5)), Color(1, 0.8, 0.25))
		if mine_flash > 0.0:
			Art.icon_coin(self, m + Vector2(0, -56 - (1.2 - mine_flash) * 20), 8)
	for i in high_slots:
		var s: Vector2 = SLOTS[i]
		var fp := s + Vector2(-46, -4)
		draw_line(fp, fp + Vector2(0, -50), Art.OUTLINE, 5)
		draw_line(fp, fp + Vector2(0, -50), Color(0.6, 0.42, 0.22), 3)
		var wave := sin(tm * 4.0 + i) * 2.5
		var flag := PackedVector2Array([fp + Vector2(2, -50), fp + Vector2(28, -43 + wave), fp + Vector2(2, -34)])
		draw_colored_polygon(flag, Color(0.95, 0.75, 0.2))
		flag.append(flag[0])
		draw_polyline(flag, Art.OUTLINE, 2)
		draw_circle(fp + Vector2(0, -52), 3.5, Color(1, 0.9, 0.5))
		if not slot_towers.has(i):
			Art.text(self, s + Vector2(0, 48), "+25% дальности", 15, Color(1, 0.92, 0.45), HORIZONTAL_ALIGNMENT_CENTER, -1, 5)
