extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/"
var m
var f := 0
func _ready():
	var cf = ConfigFile.new()
	for i in 6: cf.set_value("stars", Levels.defs()[i].id, 3)
	for k in ["crossbow", "gold", "mage"]: cf.set_value("shop", k, true)
	cf.set_value("shop", "coins", 900)
	cf.save(Levels.SAVE_PATH)
	print("gold lvl ", Shop.level_of("gold"), " up ", Shop.upgrade("gold"), Shop.upgrade("gold"), " lvl ", Shop.level_of("gold"), " coins ", Shop.coins(), " hp x", Shop.hero_hp_mult("gold"))
	print("crossbow up ", Shop.upgrade("crossbow"), " dmg x", Shop.tower_dmg_mult("crossbow"), " rate x", Shop.tower_rate_mult("crossbow"))
	Levels.current = 3
	m = load("res://scenes/main.tscn").instantiate(); add_child(m)
	await get_tree().process_frame
	m.summon_hero("gold", m.closest_road_point(Vector2(640, 400)))
	print("hero hp ", m.heroes["gold"].max_hp, " dmg ", m.heroes["gold"].dmg)
	m.gold = 999; m.build(0, "barracks"); var t = m.slot_towers[0]; m.upgrade(t); for i in 3: t.respawn[i] = 0.0
	await get_tree().create_timer(0.6).timeout
	t.set_mode("archers")
	await get_tree().create_timer(1.5).timeout
	var k = 0; for s in t.soldiers: if s and is_instance_valid(s): k += 1
	var a = 0; for s in t.archers: if s and is_instance_valid(s): a += 1
	print("knights ", k, " archers ", a)
	m.lives = 18; m.kills = 40; m.game_state = "win"; m.stars_earned = 3; m.coins_earned = Shop.reward(3, 3, 40)
func _process(_d):
	f += 1
	if f == 300:
		get_viewport().get_texture().get_image().save_png(OUT + "meta_end.png")
		m.open_upgrades()
	if f == 320:
		get_viewport().get_texture().get_image().save_png(OUT + "meta_shop.png")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Levels.SAVE_PATH))
		get_tree().quit()
