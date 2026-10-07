extends Node
var main
var f := 0
var t
func _ready():
	Shop.unlock_all = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.gold = 5000
	main.build(12, "barracks")
	t = main.slot_towers[12]
	for i in 3: t.respawn[i] = 0.0
func _process(_d):
	f += 1
	if f == 60:
		# алхимики в стороне от точки сбора, но в радиусе броска
		for i in 3:
			var e = Enemy.new(); e.setup(main, "mage", main.curves[2], 1.0)
			e.speed = 0.0
			e.offset = 30; e.position = e.path_pos(e.offset)
			var best = 0.0
			for o in range(0, int(e.path_len), 5):
				var d = e.path_pos(o).distance_to(t.rally)
				if d > 150 and d < 165 and e.path_pos(o).y > t.rally.y: best = o; break
			e.offset = best + i * 6; e.position = e.path_pos(e.offset)
			main.world.add_child(e); main.enemies.append(e)
		print("rally ", t.rally, " mage at ", main.enemies[0].position, " dist ", main.enemies[0].position.distance_to(t.rally))
	if f == 200:
		for e in main.enemies: print("busy ", e.busy, " shoot ", e.shooting_at, " cd ", e.ranged_cd, " blocker ", e.blocker)
		for s in t.soldiers: print("sol ", s, " target ", s.target if s else null, " pos ", s.position if s else null, " hp ", s.hp if s else 0)
	if f == 400:
		var fighting = 0
		for e in main.enemies: if e.fighting: fighting += 1
		print("after 5.6s: enemies left ", main.enemies.size(), " fighting ", fighting, " kills ", main.kills)
		main.explode(Vector2(640, 420), 60, 1, 0)
		var m = main.spawn_fx("meteor", Vector2(420, 430)); m.a = Vector2(260, -50); m.b = Vector2(420, 430)
		var p = Projectile.new(); p.setup(main, "bomb", Vector2(300, 600), null, Vector2(700, 600), 1, 50); main.proj_layer.add_child(p)
	if f == 408:
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/fx.png")
		get_tree().quit()
