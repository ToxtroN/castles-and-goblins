extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/"
var m
var f := 0
func _ready():
	Shop.unlock_all = true; Levels.current = 2
	m = load("res://scenes/main.tscn").instantiate(); add_child(m)
func _process(_d):
	f += 1
	if f == 5:
		m.hud.click(Vector2(1148, 30))
		# имитируем перетаскивание
		var pr = m.hud.vol_popup.panel_rect()
		m.hud.vol_popup._set_from(pr.position.y + 22 + (168 - 22) * 0.4)
		print("open ", m.hud.vol_popup.open, " vol ", VolumePopup.volume, " db ", AudioServer.get_bus_volume_db(0))
	if f == 10:
		get_viewport().get_texture().get_image().save_png(OUT + "vol.png")
		m.hud.vol_popup._set_from(9999)
		print("muted ", AudioServer.is_bus_mute(0), " music_on ", SplashScreen.music_on)
	if f == 15:
		get_viewport().get_texture().get_image().save_png(OUT + "vol0.png")
		VolumePopup.set_volume(0.8); get_tree().quit()
