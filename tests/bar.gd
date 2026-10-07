extends Node
var m
var f := 0
var t
func _ready():
	Shop.unlock_all = true; Levels.current = 1
	m = load("res://scenes/main.tscn").instantiate(); add_child(m)
	await get_tree().process_frame
	m.gold = 2000; m.build(2, "barracks"); t = m.slot_towers[2]; m.upgrade(t)
	for i in 3: t.respawn[i] = 0.0
func _process(_d):
	f += 1
	if f == 60:
		var k = 0; for s in t.soldiers: if s: k += 1
		print("knights ", k)
		t.soldiers[0].hp = 30
	if f == 200: print("knight hp after rest ", t.soldiers[0].hp if t.soldiers[0] else -1)
	if f == 210:
		m.menu.open_tower(m, t)
	if f == 230:
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/bar_menu.png")
		m.menu.close(); t.set_mode("archers")
	if f == 300:
		var a = 0; for s in t.archers: if s: a += 1
		var k2 = 0; for s in t.soldiers: if s: k2 += 1
		print("archers ", a, " knights ", k2)
		# громила рядом с башней, его держат солдаты
		var e = Enemy.new(); e.setup(m, "brute", m.curves[0], 1.0)
		var best = 0; var bd = INF
		for o in range(0, int(e.path_len), 4):
			var d = e.path_pos(o).distance_to(t.position)
			if d < bd: bd = d; best = o
		print("dist ", bd); e.offset = best; e.position = e.path_pos(best); m.world.add_child(e); m.enemies.append(e)
	if f > 300 and f % 50 == 0:
		var e = m.enemies[0] if m.enemies.size() > 0 else null
		print(f, " tower hp ", t.hp, " brute dist ", e.position.distance_to(t.position) if e else -1, " busy ", e.busy if e else null, " fighting ", e.fighting if e else null)
	if f == 520: get_tree().quit()
