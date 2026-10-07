extends Node
var f := 0
var ls
func _ready():
	var cf = ConfigFile.new()
	var st = [3,2,1,2,3,2,2,3,2,2,3,2]
	for i in st.size(): cf.set_value("stars", Levels.defs()[i].id, st[i])
	cf.save(Levels.SAVE_PATH)
	ls = load("res://scenes/level_select.tscn").instantiate()
	add_child(ls)
func _process(_d):
	f += 1
	if f == 60:
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/ls.png")
		ls.queue_free()
		Levels.current = 7
		var m = load("res://scenes/main.tscn").instantiate(); add_child(m)
		m.lives = 14; m.kills = 61; m.wave_index = 3; m.game_state = "win"; m.stars_earned = 2
	if f == 80:
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/win.png")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Levels.SAVE_PATH))
		get_tree().quit()
