extends Node
var L := 1
var main
var f := 0
func _ready(): _load()
func _load():
	Levels.current = L
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	f = 0
func _process(_d):
	f += 1
	if f == 3:
		var ws = main.WAVES
		var desc = []
		for w in ws:
			var n = 0
			for g in w: n += g[1]
			desc.append(n)
		print("L", L, " ", Levels.def(L).id, " slots ", main.SLOTS.size(), " paths ", main.PATHS.size(), " gold ", main.gold, " wave sizes ", desc, " ", ws[2])
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/map_%d.png" % L)
		main.queue_free()
		L += 1
		if L > Levels.count(): get_tree().quit(); return
		call_deferred("_load")
