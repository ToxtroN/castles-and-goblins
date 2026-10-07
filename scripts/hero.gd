class_name Hero
extends Soldier
## Герой, вызванный кнопкой: появляется на дороге и сражается ограниченное время.
## Ходит только по дорогам (путь строится по графу дорог в main.road_path).
## Выбрать кликом → кликнуть по дороге, куда идти.

var kind := "gold"
var hdata: Dictionary
var duration := 20.0
var path: PackedVector2Array = PackedVector2Array()
var selected := false


func setup_hero(m: Node, k: String, pos: Vector2) -> void:
	main = m
	kind = k
	hdata = GameData.HEROES[k]
	position = pos
	rally = pos
	set_sprite(hdata.sprite, hdata.draw_h)
	max_hp = hdata.hp * Shop.hero_hp_mult(k)
	hp = max_hp
	dmg = hdata.dmg * Shop.hero_dmg_mult(k)
	armor = hdata.armor
	attack_rate = hdata.rate
	speed = hdata.speed
	engage_radius = hdata.engage
	regen = hdata.regen
	ranged = hdata.get("ranged", {}).duplicate(true)
	if not ranged.is_empty():
		ranged.dmg = ranged.dmg * Shop.hero_dmg_mult(k)
	duration = hdata.duration + (3.0 if Kingdom.has("valor") else 0.0)
	lifetime = duration


func display_name() -> String:
	return hdata.name


func move_to(p: Vector2) -> void:
	if dead:
		return
	release_target()
	path = main.road_path(position, p)
	if path.is_empty():
		return
	rally = path[path.size() - 1]
	formation = Vector2.ZERO


func is_moving() -> bool:
	return not path.is_empty()


func _process(delta: float) -> void:
	if dead:
		return
	if not path.is_empty():
		lifetime -= delta
		if lifetime <= 0.0:
			die()
			return
		walk_t += delta
		attack_anim = maxf(0.0, attack_anim - delta * 2.2)
		_move_to(path[0], delta)
		if position.distance_to(path[0]) < 3.0:
			path.remove_at(0)
		queue_redraw()
		return
	tick(delta)


## Конец времени или гибель: герой уходит с поля, кнопка продолжает откат.
func die() -> void:
	if dead:
		return
	dead = true
	release_target()
	if hp <= 0.0:
		main.spawn_unit_corpse(self)
		main.spawn_text(position + Vector2(0, -50), "%s пал!" % hdata.name, Color(1, 0.4, 0.3))
	else:
		main.spawn_fx("puff", position)
		main.spawn_fx("puff", position + Vector2(8, -14))
		main.spawn_text(position + Vector2(0, -50), "%s уходит" % hdata.name, Color(1, 0.9, 0.6))
	main.hero_gone(self)
	queue_free()


func _draw_selection() -> void:
	if selected:
		Art.ellipse_outline(self, Vector2(0, 2), draw_h * 0.55, draw_h * 0.22, Color(0.4, 1.0, 0.4), 2.5)
	else:
		Art.ellipse_outline(self, Vector2(0, 2), draw_h * 0.45, draw_h * 0.18, Color(1, 0.85, 0.3, 0.6), 1.5)
	# полоска оставшегося времени
	var k := clampf(lifetime / duration, 0.0, 1.0)
	draw_rect(Rect2(-14, 8, 28, 3), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(-14, 8, 28 * k, 3), Color(1, 0.85, 0.3))
