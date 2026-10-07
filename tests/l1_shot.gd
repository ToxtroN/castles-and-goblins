extends Node
var main
var f := 0
func _ready():
	Shop.unlock_all = true
	Levels.current = 1
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.gold = 2000
	main.build(0, "crossbow"); main.build(2, "barracks"); main.build(3, "mage")
	main.start_next_wave()
	main.summon_hero("gold", main.closest_road_point(Vector2(1000, 470)))
func _process(_d):
	f += 1
	if f == 900:
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/l1.png")
		get_tree().quit()
