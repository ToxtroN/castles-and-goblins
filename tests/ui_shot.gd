extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/"
var f := 0
var m
func _ready():
	Shop.unlock_all = true
	Levels.current = 2
	m = load("res://scenes/main.tscn").instantiate(); add_child(m)
	await get_tree().process_frame
	m.gold = 3000
	var types = ["crossbow","mage","barracks","crossbow","mage"]
	for i in m.SLOTS.size(): m.build(i, types[i % 5])
	m.upgrade(m.slot_towers[1])
	m.start_next_wave()
	m.summon_hero("gold", m.closest_road_point(Vector2(700, 520)))
	m.summon_hero("cavalry", m.closest_road_point(Vector2(400, 330)))
func _process(_d):
	f += 1
	if f == 520: get_viewport().get_texture().get_image().save_png(OUT + "ui_game.png")
	if f == 521:
		m.lives = 14; m.stars_earned = 2; m.game_state = "win"
	if f == 521 + 66: get_viewport().get_texture().get_image().save_png(OUT + "ui_win1.png")
	if f == 521 + 150:
		get_viewport().get_texture().get_image().save_png(OUT + "ui_win2.png"); m.game_state = "lose"; m.stars_earned = 0; m.hud.end_t = -1.0
	if f == 521 + 200:
		get_viewport().get_texture().get_image().save_png(OUT + "ui_lose.png"); get_tree().quit()
