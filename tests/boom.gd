extends Node
var m
var f := 0
func _ready():
	Shop.unlock_all = true; Levels.current = 2
	m = load("res://scenes/main.tscn").instantiate(); add_child(m)
func _process(_d):
	f += 1
	if f == 5:
		m.meteor_impact(Vector2(400, 420)); m.explode(Vector2(850, 430), 60, 1, 0)
	if f == 5 + 14:
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/boom.png"); get_tree().quit()
