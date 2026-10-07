extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/en_"
var f := 0
var n
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Loc.set_lang("en")
	Shop.unlock_all = true
	SplashScreen.intro_seen = true
	n = load("res://scenes/splash.tscn").instantiate(); add_child(n)
func shot(name):
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
func _process(_d):
	f += 1
	if f == 40: shot("splash"); n.queue_free(); n = load("res://scenes/level_select.tscn").instantiate(); add_child(n)
	if f == 70: shot("levels"); n.queue_free(); n = load("res://scenes/upgrades.tscn").instantiate(); add_child(n)
	if f == 100: shot("upgrades"); n.queue_free(); Levels.current = 16; n = load("res://scenes/main.tscn").instantiate(); add_child(n)
	if f == 110:
		n.gold = 2000; n.build(0, "crossbow"); n.build(1, "barracks"); n.upgrade(n.slot_towers[0]); n.menu.open_tower(n, n.slot_towers[0])
		n.spawn_enemy("king", 0, 1.0)
	if f == 160: shot("game"); n.menu.close(); n.wave_index = 1; n._offer_buffs()
	if f == 180: shot("buff"); n.pick_buff(n.buff_choice[0]); n.game_state = "win"; n.stars_earned = 2; n.coins_earned = 90
	if f == 300: shot("win"); get_tree().quit()
