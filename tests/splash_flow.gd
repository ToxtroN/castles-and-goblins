extends Node
var s
var f := 0
func _ready():
	s = load("res://scenes/splash.tscn").instantiate()
	add_child(s)
func _process(_d):
	f += 1
	if f == 30:
		print("music playing=", s.music.playing, " loop=", s.music.stream.loop, " len=", s.music.stream.get_length())
		s._toggle_sound(); print("after toggle paused=", s.music.stream_paused); s._toggle_sound()
		s._to_menu(); s._start_game()
		var tree := get_tree()
		tree.create_timer(3.0).timeout.connect(func():
			print("current scene: ", tree.current_scene.name, " enemies? ", tree.current_scene.get("enemies") != null)
			tree.quit())
