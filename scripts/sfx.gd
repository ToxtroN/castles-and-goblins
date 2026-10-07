class_name Sfx
extends Node
## Звуковые эффекты: assets/sfx/<имя>.ogg
## Ограничение одновременных копий и минимальный интервал, чтобы толпа не превращалась в шум.
## Выключаются вместе с музыкой (мегафон / клавиша M).

const CFG := {
	"hit":       {"vol": -8.0, "max": 4, "gap": 0.06, "pitch": 0.15},   # удары гоблинов
	"sword":     {"vol": -6.0, "max": 4, "gap": 0.07, "pitch": 0.12},   # мечи рыцарей
	"arrow":     {"vol": -9.0, "max": 3, "gap": 0.10, "pitch": 0.10},   # лучники, арбалет
	"artillery": {"vol": -4.0, "max": 2, "gap": 0.30, "pitch": 0.05},   # пушка артиллериста
	"fireball":  {"vol": -2.0, "max": 2, "gap": 0.20, "pitch": 0.0},    # огненный шар
	"win":       {"vol": 0.0, "max": 1, "gap": 1.0, "pitch": 0.0},      # победа
	"lose":      {"vol": 0.0, "max": 1, "gap": 1.0, "pitch": 0.0},      # поражение
	"star":      {"vol": -2.0, "max": 3, "gap": 0.05, "pitch": 0.0},    # звезда легла на силуэт
}

var streams := {}
var players := {}
var last := {}
var count := {}   # сколько раз звук сыграл (для отладки)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in CFG:
		var path := "res://assets/sfx/%s.ogg" % id
		if not ResourceLoader.exists(path):
			continue
		streams[id] = load(path)
		var pool: Array = []
		for i in CFG[id].max:
			var p := AudioStreamPlayer.new()
			p.stream = streams[id]
			p.volume_db = CFG[id].vol
			add_child(p)
			pool.append(p)
		players[id] = pool
		last[id] = -10.0


func play(id: String) -> void:
	if not SplashScreen.music_on or not players.has(id):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - last[id] < CFG[id].gap:
		return
	for p in players[id]:
		if not p.playing:
			last[id] = now
			var pv: float = CFG[id].pitch
			p.pitch_scale = 1.0 + randf_range(-pv, pv)
			p.play()
			count[id] = count.get(id, 0) + 1
			return
