extends Node
var m
var f := 0
var t
func _ready():
	Shop.unlock_all = true
	Levels.current = 1
	m = load("res://scenes/main.tscn").instantiate(); add_child(m)
	await get_tree().process_frame
	m.gold = 999; m.build(2, "barracks"); t = m.slot_towers[2]
	for i in 3: t.respawn[i] = 0.0
	m.summon_hero("gold", m.closest_road_point(Vector2(1000, 470)))
func _process(_d):
	f += 1
	if f == 90:
		for k in ["mage", "rock", "mage"]:
			var e = Enemy.new(); e.setup(m, k, m.curves[0], 1.0); e.speed = 0
			for o in range(0, int(e.path_len), 4):
				var d = e.path_pos(o).distance_to(t.rally)
				if d > 150 and d < 160 and o > 0: e.offset = o + randi() % 10
			e.position = e.path_pos(e.offset); m.world.add_child(e); m.enemies.append(e)
			print(k, " dist to rally ", e.position.distance_to(t.rally))
		# стрелок у героя
		var e2 = Enemy.new(); e2.setup(m, "rock", m.curves[0], 1.0); e2.speed = 0
		var hp = m.heroes["gold"].position
		for o in range(0, int(e2.path_len), 4):
			if e2.path_pos(o).distance_to(hp) > 170 and e2.path_pos(o).distance_to(hp) < 180: e2.offset = o
		e2.position = e2.path_pos(e2.offset); m.world.add_child(e2); m.enemies.append(e2)
	if f == 90 + 300:
		var fighting = 0
		for e in m.enemies: if e.fighting: fighting += 1
		print("after 5s: enemies ", m.enemies.size(), " fighting ", fighting, " kills ", m.kills)
		get_tree().quit()
