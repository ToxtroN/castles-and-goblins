extends Node
var s
var f := 0
func _ready():
	s = load("res://scenes/level_select.tscn").instantiate(); add_child(s)
func _process(_d):
	f += 1
	if f == 30: s.vol_popup.toggle()
	if f == 40:
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/vol_ls.png")
		s.queue_free(); s = load("res://scenes/splash.tscn").instantiate(); add_child(s)
	if f == 60: s._toggle_sound()
	if f == 70:
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/vol_sp.png"); get_tree().quit()
