extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/"
var s
var f := 0
func _ready():
	s = load("res://scenes/splash.tscn").instantiate()
	add_child(s)
func _process(_d):
	f += 1
	if f == 90: _shot("intro.png"); s._to_menu()
	if f == 150: _shot("menu.png"); s._toggle_sound()
	if f == 160:
		_shot("muted.png")
		print("music playing=", s.music.playing, " paused=", s.music.stream_paused, " stream=", s.music.stream)
		s._start_game()
	if f == 260:
		print("scene now: ", get_tree().current_scene, " children ", get_children())
		get_tree().quit()
func _shot(n): get_viewport().get_texture().get_image().save_png(OUT + n)
