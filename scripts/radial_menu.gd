class_name RadialMenu
extends Node2D
## Круговое меню над местом/башней: постройка, улучшение, продажа.

var main: Node
var items: Array = []        # {id, offset, cost, label}
var slot := -1
var tower: Tower = null
var hovered := ""
var t := 0.0


func open_build(m: Node, slot_idx: int, pos: Vector2) -> void:
	main = m
	slot = slot_idx
	tower = null
	position = pos
	items.clear()
	var ids: Array = GameData.TOWER_ORDER.filter(func(x): return Shop.owned(x))
	var layouts := {1: [Vector2(0, -66)], 2: [Vector2(-52, -36), Vector2(52, -36)],
		3: [Vector2(-52, -36), Vector2(52, -36), Vector2(0, 62)]}
	var offs: Array = layouts[ids.size()]
	for i in ids.size():
		var id: String = ids[i]
		items.append({"id": id, "offset": offs[i], "cost": GameData.TOWERS[id].levels[0].cost,
			"label": GameData.TOWERS[id].name})
	_open()


func open_tower(m: Node, tw: Tower) -> void:
	main = m
	tower = tw
	slot = tw.slot
	position = tw.position + Vector2(0, -30)
	items.clear()
	if tw.level == tw.max_level() - 1 and GameData.SPECS.has(tw.type):
		# II → III: выбор специализации
		var specs: Dictionary = GameData.SPECS[tw.type]
		var ks: Array = specs.keys()
		for i in ks.size():
			items.append({"id": "spec_" + ks[i], "offset": Vector2(-46 + i * 92, -58), "cost": tw.upgrade_cost(),
				"label": specs[ks[i]].name, "desc": specs[ks[i]].desc})
	else:
		items.append({"id": "upgrade", "offset": Vector2(0, -62), "cost": tw.upgrade_cost(), "label": "Улучшить"})
	items.append({"id": "sell", "offset": Vector2(0, 62), "cost": -tw.sell_value(), "label": "Продать"})
	if tw.type == "barracks" and tw.level >= 1 and tw.spec == "":
		items.append({"id": "mode_knights", "offset": Vector2(-64, 0), "cost": 0, "label": "Только рыцари"})
		items.append({"id": "mode_archers", "offset": Vector2(64, 0), "cost": 0, "label": "+ Лучники ×2"})
	_open()


func _open() -> void:
	t = 0.0
	visible = true
	hovered = ""


func close() -> void:
	visible = false
	items.clear()
	tower = null
	slot = -1


func is_open() -> bool:
	return visible and not items.is_empty()


func hit(p: Vector2) -> String:
	for it in items:
		if p.distance_to(position + it.offset) < 24.0:
			return it.id
	return ""


func affordable(it: Dictionary) -> bool:
	if it.id == "sell":
		return true
	return it.cost >= 0 and main.gold >= it.cost


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	hovered = hit(get_global_mouse_position())
	queue_redraw()


func _draw() -> void:
	if items.is_empty():
		return
	var pop := minf(1.0, t * 8.0)
	# радиус: для башни — текущий/следующий, для места — при наведении на тип
	var rng := 0.0
	var center := Vector2.ZERO
	if tower != null:
		center = tower.position - position
		rng = tower.get_range()
		if hovered == "upgrade" and tower.level < tower.max_level():
			rng = GameData.TOWERS[tower.type].levels[tower.level + 1].range * main.range_mult(tower.slot)
		elif hovered.begins_with("spec_"):
			var sd: Dictionary = GameData.SPECS[tower.type][hovered.substr(5)]
			rng = float(sd.get("range", GameData.TOWERS[tower.type].levels[tower.max_level()].range)) * main.range_mult(tower.slot)
	elif hovered in GameData.TOWERS:
		rng = GameData.TOWERS[hovered].levels[0].range
	if rng > 0.0:
		Art.ellipse(self, center, rng, rng * 0.72, Color(1, 1, 1, 0.12), 48)
		Art.ellipse_outline(self, center, rng, rng * 0.72, Color(1, 1, 1, 0.5), 2)
	draw_arc(Vector2.ZERO, 66 * pop, 0, TAU, 40, Color(0.95, 0.85, 0.55, 0.6), 3)
	for it in items:
		var p: Vector2 = it.offset * pop
		var ok := affordable(it)
		var hov: bool = hovered == it.id
		var r := 24.0 if hov else 22.0
		Art.circle_o(self, p, r, Color(0.3, 0.22, 0.14) if ok else Color(0.3, 0.3, 0.3), 3)
		draw_arc(p, r, 0, TAU, 24, Color(0.95, 0.75, 0.3) if ok else Color(0.5, 0.5, 0.5), 2)
		_draw_icon(it.id, p, ok)
		# цена
		var cost: int = it.cost
		if it.id == "upgrade" and cost < 0:
			Art.text(self, p + Vector2(0, 38), "МАКС", 13, Color(0.8, 0.8, 0.8))
		elif cost != 0:
			var txt := ("+%d" % -cost) if cost < 0 else str(cost)
			var col := Color(1, 0.85, 0.3) if ok else Color(0.9, 0.35, 0.3)
			Art.rect_o(self, Rect2(p + Vector2(-20, 18), Vector2(40, 16)), Color(0.15, 0.12, 0.1), 1)
			Art.text(self, p + Vector2(0, 31), txt, 13, col, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
		if it.id.begins_with("spec_") and not hov:
			Art.text(self, p + Vector2(0, -30), it.label, 13, Color(1, 0.95, 0.8), HORIZONTAL_ALIGNMENT_CENTER, -1, 3)
		if hov:
			var desc := ""
			if it.id in GameData.TOWERS:
				desc = GameData.TOWERS[it.id].desc
			elif it.has("desc"):
				desc = it.desc
			Art.text(self, p + Vector2(0, -32), it.label, 15, Color.WHITE)
			if desc != "":
				Art.text(self, p + Vector2(0, -48), desc, 12, Color(0.9, 0.9, 0.8), HORIZONTAL_ALIGNMENT_CENTER, -1, 3)


func _draw_icon(id: String, p: Vector2, ok: bool) -> void:
	var mod := 1.0 if ok else 0.5
	if id in GameData.TOWERS:
		var k := 0.22 if id != "barracks" else 0.30
		Art.draw_tower(self, id, 0, 0.0, 0.0, Transform2D(0, Vector2(k, k), 0, p + Vector2(0, 14)))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		if not ok:
			draw_circle(p, 21, Color(0, 0, 0, 0.35))
	elif id.begins_with("spec_"):
		var tp: String = tower.type
		var k := 0.2 if tp != "barracks" else 0.27
		Art.draw_tower(self, tp, 2, 0.0, 0.0, Transform2D(0, Vector2(k, k), 0, p + Vector2(-2, 15)))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		var sd: Dictionary = GameData.SPECS[tp][id.substr(5)]
		var c: Vector2 = p + Vector2(13, -12)
		Art.poly_o(self, PackedVector2Array([c + Vector2(0, -9), c + Vector2(8, 0), c + Vector2(0, 9), c + Vector2(-8, 0)]), sd.color, 1.5)
		Art.text(self, c + Vector2(0, 4), Loc.t(sd.name).substr(0, 1), 11, Color(0.1, 0.06, 0.03), HORIZONTAL_ALIGNMENT_CENTER, -1, 0)
		if not ok:
			draw_circle(p, 21, Color(0, 0, 0, 0.35))
	elif id == "upgrade":
		var c := Color(0.4, 0.9, 0.3) * mod
		c.a = 1
		Art.poly_o(self, PackedVector2Array([p + Vector2(0, -12), p + Vector2(11, 0), p + Vector2(4, 0),
			p + Vector2(4, 11), p + Vector2(-4, 11), p + Vector2(-4, 0), p + Vector2(-11, 0)]), c)
	elif id.begins_with("mode_"):
		var spr := "knight" if id == "mode_knights" else "archer"
		var fr := SpriteLib.frames(spr, "idle")
		if fr.is_empty():
			fr = SpriteLib.frames(spr, "walk")
		if not fr.is_empty():
			SpriteLib.draw_frame(self, fr[0], 34.0 / fr[0].get_height(), false, p + Vector2(0, 16))
		if tower != null and tower.unit_mode == id.substr(5):
			draw_arc(p, 25, 0, TAU, 28, Color(0.4, 1.0, 0.4), 3.5)
	elif id == "sell":
		Art.icon_coin(self, p, 10)
		Art.text(self, p + Vector2(0, 5), "$", 14, Color(0.5, 0.35, 0.05), HORIZONTAL_ALIGNMENT_CENTER, -1, 0)
