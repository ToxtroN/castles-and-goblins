extends Node
var main
var frame := 0
var leaks := {}
func _ready():
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.gold = 10000
	main.build(12, "barracks"); main.build(4, "archer"); main.build(9, "mage"); main.build(15, "artillery")
	main.start_next_wave()
func _process(_d):
	frame += 1
	if frame % 300 == 0:
		var fighting = 0
		for e in main.enemies: if e.fighting: fighting += 1
		var sol = 0
		for n in main.world.get_children(): if n is Soldier and not n is Hero: sol += 1
		var t = main.slot_towers[12]
		print("f",frame," enemies ",main.enemies.size()," fighting ",fighting," soldiers ",sol," rally ",t.rally, " lives ", main.lives, " kills ", main.kills)
	if frame > 2400: get_tree().quit()
