class_name Shop
## Магазин улучшений: за звёзды покупаются новые башни и герои.
## На старте открыта только казарма, героев нет. Огненный шар доступен всегда.
## Покупки хранятся в user://progress.cfg, секция [shop].

static var unlock_all := false   # для автотестов

const ITEMS := [
	{"id": "crossbow", "kind": "tower", "price": 2, "name": "Башня-арбалет",
		"desc": "Мощный выстрел, бьёт и воронов"},
	{"id": "mage", "kind": "tower", "price": 4, "name": "Башня мага",
		"desc": "Цепная молния по нескольким врагам"},
	{"id": "gold", "kind": "hero", "price": 3, "name": "Золотой рыцарь",
		"desc": "Крепкий воин, держит толпу врагов"},
	{"id": "cavalry", "kind": "hero", "price": 5, "name": "Всадник",
		"desc": "Быстрый, сильный удар копьём"},
	{"id": "artillery", "kind": "hero", "price": 6, "name": "Артиллерист",
		"desc": "Пушка бьёт далеко и по площади"},
]
const FREE := ["barracks", "meteor"]


static func _cf() -> ConfigFile:
	var cf := ConfigFile.new()
	cf.load(Levels.SAVE_PATH)
	return cf


static func owned(id: String) -> bool:
	if unlock_all or FREE.has(id):
		return true
	return bool(_cf().get_value("shop", id, false))


static func item(id: String) -> Dictionary:
	for it in ITEMS:
		if it.id == id:
			return it
	return {}


static func stars_total() -> int:
	var n := 0
	for s in Levels.load_stars():
		n += s
	return n


static func stars_spent() -> int:
	var n := 0
	var cf := _cf()
	for it in ITEMS:
		if bool(cf.get_value("shop", it.id, false)):
			n += it.price
	return n


static func stars_free() -> int:
	return stars_total() - stars_spent()


static func buy(id: String) -> bool:
	var it := item(id)
	if it.is_empty() or owned(id) or stars_free() < it.price:
		return false
	var cf := _cf()
	cf.set_value("shop", id, true)
	cf.save(Levels.SAVE_PATH)
	return true


# ---------------------------------------------------------------- МОНЕТЫ И ПРОКАЧКА
## Монеты копятся между уровнями (за победу и за убитых врагов) и тратятся на прокачку.
## Купленные башни и герои прокачиваются с 1 до 5 уровня.
const MAX_LEVEL := 5
const LEVEL_COST := [0, 80, 160, 280, 450]      # цена перехода на уровень 2..5 (индекс = текущий уровень)
const HERO_HP_PER_LVL := 0.20                    # +20% прочности за уровень
const HERO_DMG_PER_LVL := 0.15                   # +15% урона за уровень
const TOWER_DMG_PER_LVL := 0.15                  # башни: +15% урона
const TOWER_RATE_PER_LVL := 0.07                 # и перезарядка быстрее на 7% за уровень


static func coins() -> int:
	return int(_cf().get_value("shop", "coins", 0))


static func add_coins(n: int) -> void:
	var cf := _cf()
	cf.set_value("shop", "coins", int(cf.get_value("shop", "coins", 0)) + n)
	cf.save(Levels.SAVE_PATH)


static func level_of(id: String) -> int:
	if not owned(id):
		return 0
	return int(_cf().get_value("shop", "lvl_" + id, 1))


static func upgrade_cost(id: String) -> int:
	var l := level_of(id)
	if l <= 0 or l >= MAX_LEVEL:
		return -1
	return LEVEL_COST[l]


static func upgrade(id: String) -> bool:
	var c := upgrade_cost(id)
	if c < 0 or coins() < c:
		return false
	var cf := _cf()
	cf.set_value("shop", "coins", int(cf.get_value("shop", "coins", 0)) - c)
	cf.set_value("shop", "lvl_" + id, level_of(id) + 1)
	cf.save(Levels.SAVE_PATH)
	return true


static func hero_hp_mult(id: String) -> float:
	return 1.0 + HERO_HP_PER_LVL * (maxi(1, level_of(id)) - 1)


static func hero_dmg_mult(id: String) -> float:
	return 1.0 + HERO_DMG_PER_LVL * (maxi(1, level_of(id)) - 1)


static func tower_dmg_mult(id: String) -> float:
	if id == "barracks":
		return 1.0
	return 1.0 + TOWER_DMG_PER_LVL * (maxi(1, level_of(id)) - 1)


static func tower_rate_mult(id: String) -> float:
	if id == "barracks":
		return 1.0
	return 1.0 - TOWER_RATE_PER_LVL * (maxi(1, level_of(id)) - 1)


## Награда монетами за бой.
static func reward(level: int, stars: int, kills: int) -> int:
	if stars <= 0:
		return kills / 2
	return 40 + stars * 25 + level * 5 + kills / 3
