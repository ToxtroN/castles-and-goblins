extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/"
var f := 0
var n
func _ready():
	var cf = ConfigFile.new()
	for i in 11: cf.set_value("stars", Levels.defs()[i].id, 3)
	cf.save(Levels.SAVE_PATH)
	n = load("res://scenes/upgrades.tscn").instantiate(); add_child(n)
func _process(_d):
	f += 1
	if f == 20:
		get_viewport().get_texture().get_image().save_png(OUT + "upg_main.png")
		n.kingdom_open = true
	if f == 40:
		get_viewport().get_texture().get_image().save_png(OUT + "kingdom.png")
		n.queue_free(); Levels.current = 2
		n = load("res://scenes/main.tscn").instantiate(); add_child(n)
	if f == 50:
		print("lives ", n.lives, " gold ", n.gold, " kingdom fire ", Kingdom.has("fire"))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Levels.SAVE_PATH))
		get_tree().quit()
