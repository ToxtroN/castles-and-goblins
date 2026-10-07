extends "res://tests/sim.gd"
# Скриншоты для каталога: бот играет уровень, кадры снимаются во время боя.
# args: уровень, язык, кадр1, кадр2...
const OUT := "/home/claude/castle-defense/store/"
var shots: Array = []
var lang := "ru"
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var a = OS.get_cmdline_user_args()
	lang = a[1]
	Loc.set_lang(lang)
	for i in range(2, a.size()): shots.append(int(a[i]))
	super._ready()
	main.message_t = 0.0
func _process(d):
	super._process(d)
	if frame in shots:
		main.message_t = 0.0
		get_viewport().get_texture().get_image().save_png(OUT + "screenshot_%s_L%d_%d.png" % [lang, Levels.current, frame])
		if frame == shots[-1]: get_tree().quit()
