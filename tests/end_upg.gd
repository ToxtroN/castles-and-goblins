extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/"
var m
var f := 0
func _ready():
	Levels.current = 2
	m = load("res://scenes/main.tscn").instantiate(); add_child(m)
	await get_tree().process_frame
	m.lives = 19; m.stars_earned = 3; m.game_state = "win"; m._end_sound("win")
func _process(_d):
	f += 1
	if f == 200:
		get_viewport().get_texture().get_image().save_png(OUT + "end_upg.png")
		print("star sounds ", m.sfx.count)
		m.hud.click(Vector2(640, 620))
	if f == 230:
		get_viewport().get_texture().get_image().save_png(OUT + "overlay.png")
		m.overlay.get_child(0)._back()
	if f == 240:
		print("overlay closed ", m.overlay == null); get_tree().quit()
