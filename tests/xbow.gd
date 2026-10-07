extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/"
var m
var f := 0
var t
func _ready():
	Shop.unlock_all = true; Levels.current = 2
	m = load("res://scenes/main.tscn").instantiate(); add_child(m)
	await get_tree().process_frame
	m.gold = 999
	for i in m.SLOTS.size():
		m.build(i, "crossbow")
func _spawn(off):
	var e = Enemy.new(); e.setup(m, "brute", m.curves[0], 1.0); e.speed = 0
	e.offset = off; e.position = e.path_pos(off); m.world.add_child(e); m.enemies.append(e)
func _process(_d):
	f += 1
	if f == 5:
		var e = Enemy.new(); e.setup(m, "brute", m.curves[0], 1.0)
		for o in range(0, int(e.path_len), 5):
			var q = e.path_pos(o)
			if q.x > 700 and q.x < 760 and q.y > 350: _spawn(o); break
	if f == 60:
		var a = []
		for t in m.slot_towers.values(): a.append([int(t.position.x), t.aim])
		print("aims ", a, " enemy x ", int(m.enemies[0].position.x))
		get_viewport().get_texture().get_image().save_png(OUT + "xbow.png"); get_tree().quit()
