extends Node
var main
var frame := 0
func _ready():
	Shop.unlock_all = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.gold = 5000
	var b = {4:"crossbow",9:"mage",12:"barracks",3:"barracks",8:"crossbow",13:"mage",11:"barracks",10:"crossbow",14:"mage"}
	for k in b: main.build(k, b[k])
	main.wave_index = 1
	main.upgrade(main.slot_towers[12]); main.upgrade(main.slot_towers[12]); main.upgrade(main.slot_towers[9])
	main.summon_hero("cavalry", main.closest_road_point(Vector2(700, 520)))
	main.summon_hero("artillery", main.closest_road_point(Vector2(300, 330)))
	main.cooldowns["gold"] = 23.0
	main.cooldowns["meteor"] = 12.0
	main.heroes["cavalry"].move_to(Vector2(990, 400))
	var kinds = ["grunt","spearman","mage","rock","cart","crow","brute"]
	for i in kinds.size():
		var e = Enemy.new(); e.setup(main, kinds[i], main.curves[i % 3], 1.0)
		e.offset = 250 + i * 35; e.position = e.path_pos(e.offset)
		main.world.add_child(e); main.enemies.append(e)
	for i in 6:
		var e = Enemy.new(); e.setup(main, kinds[i % 3], main.curves[2], 1.0)
		e.offset = 120 + i * 40; e.position = e.path_pos(e.offset)
		main.world.add_child(e); main.enemies.append(e)
func _process(_d):
	frame += 1
	if frame == 200:
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/shot2.png")
		get_tree().quit()
