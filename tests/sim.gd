extends Node
# Автотест: бот строит башни и проходит все волны в ускоренном режиме.
var main
var frame := 0
func _ready():
	Shop.unlock_all = not ("locked" in OS.get_cmdline_user_args())
	var args = OS.get_cmdline_user_args()
	if args.size() > 0: Levels.current = int(args[0])
	main = load("res://scenes/main.tscn").instantiate()
	main.auto_buffs = true
	add_child(main)
	await get_tree().process_frame
	for i in main.SLOTS.size():
		var rd = main.road_distance(main.SLOTS[i])
		if rd < 50: print("SLOT TOO CLOSE ", i, " ", rd)
	print("min slot dists ok; trees=", main.trees.size())
	var plan = ["barracks","archer","mage","artillery"]
	pass
	main.start_next_wave()
func _process(_d):
	frame += 1
	if main.game_state != "play":
		print("RESULT ", main.game_state, " buffs ", main.buffs, " mech ", main.mech, " wave ", main.wave_index, " lives ", main.lives, " gold ", main.gold, " kills ", main.kills, " frame ", frame, " leaks ", main.leaks, " towers lost ", main.towers_lost)
		get_tree().quit()
		return
	if frame % 120 == 0:
		# бот: строит/улучшает
		var order = ["crossbow","mage","barracks"]
		# места раскладываем по дорогам и берём по очереди с каждой (ближе к развилке/середине)
		var groups = {}
		for i in main.SLOTS.size():
			var best = 0; var bd = INF
			for c in main.curves.size():
				var d = main.curves[c].get_closest_point(main.SLOTS[i]).distance_to(main.SLOTS[i])
				if d < bd: bd = d; best = c
			if not groups.has(best): groups[best] = []
			groups[best].append(i)
		for k in groups:
			groups[k].sort_custom(func(a,b): return main.SLOTS[a].distance_to(main.GATE) < main.SLOTS[b].distance_to(main.GATE))
		var idx = []
		var more = true; var r = 0
		while more:
			more = false
			for k in groups:
				if r < groups[k].size(): idx.append(groups[k][r]); more = true
			r += 1
		for i in idx:
			if not main.slot_towers.has(i):
				var t = order[i % 3]
				if main.gold >= GameData.TOWERS[t].levels[0].cost:
					main.build(i, t)
		for t in main.slot_towers.values():
			if t.upgrade_cost() > 0 and main.gold >= t.upgrade_cost() + 50:
				if t.level == t.max_level() - 1:
					var ks = GameData.SPECS[t.type].keys()
					main.upgrade(t, ks[(t.slot + Levels.current) % 2])
				else:
					main.upgrade(t)
		if main.cooldowns.meteor <= 0 and main.enemies.size() > 5:
			main.use_ability("meteor", main.enemies[0].position)
		for h in ["gold", "cavalry", "artillery"]:
			if Shop.owned(h) and main.cooldowns[h] <= 0 and main.enemies.size() > 3:
				main.use_ability(h, main.enemies[0].position)
		if main.enemies.size() > 0 and frame % 600 == 0:
			for h in main.heroes.values():
				h.move_to(main.enemies[0].position)
	if frame % 300 == 0 and main.boss != null and is_instance_valid(main.boss): print("boss phase ", main.boss.phase, " hp ", int(main.boss.hp), " off ", int(main.boss.offset), "/", int(main.boss.path_len))
	if frame % 1800 == 0:
		if main.boss != null and is_instance_valid(main.boss): print("boss phase ", main.boss.phase, " hp ", int(main.boss.hp), "/", int(main.boss.max_hp))
		print("f", frame, " wave ", main.wave_index, " enemies ", main.enemies.size(), " lives ", main.lives, " gold ", main.gold)
	if main.can_call_wave() and main.next_wave_timer < 3 and main.next_wave_timer > 0:
		main.start_next_wave()
