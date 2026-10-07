extends Node
# Скриншоты новых фич: args = уровень, режим (boss|buff|menu|mech)
var main
var frame := 0
var mode := "mech"
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/"
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Shop.unlock_all = true
	var args = OS.get_cmdline_user_args()
	Levels.current = int(args[0])
	mode = args[1]
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.gold = 9000
	main.wave_index = 1
	var specs = ["sniper", "storm", "guards", "rapid", "curse", "rangers"]
	for i in main.SLOTS.size():
		var tp = GameData.TOWER_ORDER[i % 3]
		main.build(i, tp)
		var t = main.slot_towers[i]
		if mode != "menu" or i > 0:
			main.upgrade(t)
			main.upgrade(t, GameData.SPECS[tp].keys()[(i / 3) % 2])
	if mode == "boss":
		main.spawn_enemy("king", 0, 1.0); main.boss.offset = 0
		main.boss.offset = main.boss.path_len * 0.4
		main.boss.position = main.boss.path_pos(main.boss.offset)
		main.boss.hp = main.boss.max_hp * 0.5
		main.boss.phase = 1
		for i in 8:
			main.spawn_enemy(["grunt","spearman"][i % 2], i % main.curves.size(), 1.0)
			var e = main.enemies[-1]
			e.offset = 200 + i * 40
			e.position = e.path_pos(e.offset)
	if mode == "buff":
		main.buffs = ["bolts"]
		main._offer_buffs()
	if mode == "mech":
		for i in main.high_slots: main.slot_towers[i].remove(); main.slot_towers.erase(i)
		main.summon_hero("gold", main.shrine if main.shrine != Vector2.INF else main.closest_road_point(Vector2(600, 400)))
		for i in 6:
			main.spawn_enemy("grunt", 0, 1.0)
			var e = main.enemies[-1]
			e.offset = main.curves[0].get_baked_length() * 0.38 + i * 18
			e.position = e.path_pos(e.offset)
func _process(_d):
	frame += 1
	if mode == "menu" and frame == 5:
		main.menu.open_tower(main, main.slot_towers[0])
		main.slot_towers[0].upgrade()
		main.menu.open_tower(main, main.slot_towers[0])
	if mode == "boss" and frame == 60:
		main.boss.hp = main.boss.max_hp * 0.34
	if frame == 110:
		get_viewport().get_texture().get_image().save_png(OUT + "feat_%s_%d.png" % [mode, Levels.current])
		get_tree().quit()
