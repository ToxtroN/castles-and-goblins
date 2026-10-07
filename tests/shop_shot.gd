extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/"
var f := 0
var n
func _ready():
	var cf = ConfigFile.new()
	for i in 4: cf.set_value("stars", Levels.defs()[i].id, 3)
	cf.set_value("shop", "crossbow", true)
	cf.save(Levels.SAVE_PATH)
	n = load("res://scenes/upgrades.tscn").instantiate(); add_child(n)
func _process(_d):
	f += 1
	if f == 20:
		print("free ", Shop.stars_free(), " buy gold ", Shop.buy("gold"), " buy artillery ", Shop.buy("artillery"), " free ", Shop.stars_free())
	if f == 40:
		get_viewport().get_texture().get_image().save_png(OUT + "shop.png")
		n.queue_free(); n = load("res://scenes/level_select.tscn").instantiate(); add_child(n)
	if f == 90:
		get_viewport().get_texture().get_image().save_png(OUT + "ls2.png")
		n.queue_free(); Levels.current = 1
		n = load("res://scenes/main.tscn").instantiate(); add_child(n)
	if f == 100:
		n.gold = 999; n.build(0, "barracks"); n.build(1, "crossbow"); n.upgrade(n.slot_towers[1]); n.menu.open_build(n, 2, n.SLOTS[2])
	if f == 140:
		get_viewport().get_texture().get_image().save_png(OUT + "game_lock.png")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Levels.SAVE_PATH))
		get_tree().quit()
