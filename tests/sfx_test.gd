extends Node
var main
var n := {}
func _ready():
	Shop.unlock_all = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	print("streams ", main.sfx.streams.keys())
	main.gold = 5000
	main.build(12, "barracks"); main.upgrade(main.slot_towers[12]); main.upgrade(main.slot_towers[12])
	main.build(4, "crossbow"); main.build(15, "crossbow")
	var t = main.slot_towers[12]
	for k in ["grunt","spearman","rock","mage"]:
		var e = Enemy.new(); e.setup(main, k, main.curves[2], 1.0)
		for o in range(0, int(e.path_len), 5):
			if e.path_pos(o).distance_to(t.rally) < 60: e.offset = o; break
		e.position = e.path_pos(e.offset); main.world.add_child(e); main.enemies.append(e)
	main.summon_hero("artillery", main.closest_road_point(Vector2(640, 300)))
	main.use_ability("meteor", Vector2(640, 400))
	var orig = main.sfx
	for id in orig.players: n[id] = 0
func _process(_d):
	for id in main.sfx.players:
		for p in main.sfx.players[id]:
			if p.playing and p.get_playback_position() < 0.02: n[id] += 1
	if Engine.get_process_frames() > 900:
		print("played ", main.sfx.count); get_tree().quit()
