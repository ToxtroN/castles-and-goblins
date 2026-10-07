extends Node
var s
var f := 0
func _ev(pos: Vector2, pressed: bool):
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT; e.pressed = pressed; e.position = pos + Vector2(0, -40)
	s.vol_popup._input(e)
func _ready():
	s = load("res://scenes/level_select.tscn").instantiate(); add_child(s)
func _process(_d):
	f += 1
	var p = s.vol_popup.panel_rect().get_center()
	if f == 10: s.vol_popup.toggle(); print("open ", s.vol_popup.open)
	if f == 20: _ev(p, true)
	if f == 25: _ev(p, false)
	if f == 30: print("after release open ", s.vol_popup.open, " vol ", VolumePopup.volume)
	if f == 80: print("after 1s open ", s.vol_popup.open)
	if f == 90: s.vol_popup.toggle()
	if f == 400: print("idle 5s open ", s.vol_popup.open); get_tree().quit()
