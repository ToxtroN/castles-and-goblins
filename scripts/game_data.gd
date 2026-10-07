class_name GameData
## Все настройки баланса в одном месте: башни, враги, волны.

const TOWER_ORDER := ["crossbow", "barracks", "mage"]

const TOWERS := {
	"crossbow": {
		"name": "Арбалет", "desc": "Мощный выстрел по одной цели",
		"levels": [
			{"cost": 80, "range": 170.0, "dmg": Vector2(10, 15), "rate": 1.1},
			{"cost": 120, "range": 185.0, "dmg": Vector2(17, 26), "rate": 1.0},
			{"cost": 170, "range": 200.0, "dmg": Vector2(27, 39), "rate": 0.9},
		],
	},
	"barracks": {
		"name": "Казарма", "desc": "Рыцари перекрывают дорогу, на 3 ур. + лучники",
		"levels": [
			{"cost": 70, "range": 170.0, "hp": 55.0, "dmg": Vector2(2, 4), "armor": 0.1, "respawn": 10.0, "archers": 2},
			{"cost": 110, "range": 170.0, "hp": 95.0, "dmg": Vector2(4, 7), "armor": 0.25, "respawn": 9.0, "archers": 2},
			{"cost": 160, "range": 170.0, "hp": 145.0, "dmg": Vector2(7, 12), "armor": 0.35, "respawn": 8.0, "archers": 2},
		],
	},
	"mage": {
		"name": "Башня мага", "desc": "Цепная молния по нескольким врагам",
		"levels": [
			{"cost": 100, "range": 145.0, "dmg": Vector2(8, 15), "rate": 1.6, "chain": 3},
			{"cost": 160, "range": 155.0, "dmg": Vector2(15, 26), "rate": 1.5, "chain": 4},
			{"cost": 230, "range": 170.0, "dmg": Vector2(26, 42), "rate": 1.4, "chain": 5},
		],
	},
}

# Лучник из казармы 3-го уровня
# Лучники казармы по уровню казармы (режим «лучники» доступен со 2 уровня)
const BARRACKS_ARCHERS := [
	{"hp": 45.0, "dmg": Vector2(5, 8), "armor": 0.0,
		"ranged": {"range": 150.0, "rate": 1.0, "dmg": Vector2(5, 8), "splash": 0.0, "proj": "arrow"}},
	{"hp": 60.0, "dmg": Vector2(8, 12), "armor": 0.05,
		"ranged": {"range": 165.0, "rate": 0.9, "dmg": Vector2(8, 12), "splash": 0.0, "proj": "arrow"}},
	{"hp": 80.0, "dmg": Vector2(12, 18), "armor": 0.1,
		"ranged": {"range": 180.0, "rate": 0.8, "dmg": Vector2(12, 18), "splash": 0.0, "proj": "arrow"}},
]

# Герои вызываются кнопками на время (duration), потом уходят; откат (cooldown) идёт с момента вызова.
# sprite — папка в assets/units. ranged — стреляет издалека и не блокирует.
const HEROES := {
	"gold": {"name": "Золотой рыцарь", "sprite": "gold", "hp": 340.0, "dmg": Vector2(12, 18),
		"armor": 0.35, "speed": 100.0, "rate": 0.8, "engage": 80.0, "regen": 10.0, "draw_h": 52.9,
		"duration": 25.0, "cooldown": 45.0},
	"cavalry": {"name": "Всадник", "sprite": "cavalry", "hp": 230.0, "dmg": Vector2(16, 26),
		"armor": 0.2, "speed": 160.0, "rate": 1.0, "engage": 100.0, "regen": 6.0, "draw_h": 59.8,
		"duration": 20.0, "cooldown": 40.0},
	"artillery": {"name": "Артиллерист", "sprite": "artillery", "hp": 160.0, "dmg": Vector2(4, 8),
		"armor": 0.2, "speed": 60.0, "rate": 1.0, "engage": 60.0, "regen": 5.0, "draw_h": 48.3,
		"duration": 22.0, "cooldown": 50.0,
		"ranged": {"range": 290.0, "rate": 2.4, "dmg": Vector2(24, 38), "splash": 60.0, "proj": "bomb"}},
}

# Кнопки внизу экрана (иконки assets/ui/icon_<id>.png), клавиши 1..4
const BUTTONS := ["meteor", "artillery", "gold", "cavalry"]

# Высота спрайтов наших юнитов в игре
const UNIT_DRAW_H := {"knight": 46.0, "archer": 41.0}

# armor режет физический урон, mres — магический (0..1)
# draw_h — высота спрайта в игре (px), size — радиус для попаданий/полоски HP
# ranged — дальняя атака по солдатам/герою: дальность, перезарядка, урон, радиус взрыва, снаряд
# flying — летит, солдаты и герой его не достают; бьют только лучники, маги и метеоры
# tower_dmg — громила останавливается и ломает башни рядом с дорогой
const ENEMIES := {
	"grunt": {"name": "Гоблин", "hp": 18.0, "speed": 55.0, "armor": 0.0, "mres": 0.0,
		"gold": 6, "lives": 1, "size": 10.0, "draw_h": 46.0, "fps": 8.0,
		"dmg": Vector2(1, 3), "rate": 1.0},
	"spearman": {"name": "Копейщик", "hp": 48.0, "speed": 48.0, "armor": 0.2, "mres": 0.0,
		"gold": 9, "lives": 1, "size": 11.0, "draw_h": 50.6, "fps": 4.0,
		"dmg": Vector2(4, 7), "rate": 1.1},
	"mage": {"name": "Гоблин-алхимик", "hp": 36.0, "speed": 46.0, "armor": 0.0, "mres": 0.6,
		"gold": 12, "lives": 1, "size": 10.0, "draw_h": 48.3, "fps": 8.0,
		"dmg": Vector2(1, 3), "rate": 1.0,
		"ranged": {"range": 110.0, "rate": 1.8, "dmg": Vector2(6, 10), "splash": 30.0, "proj": "mage"}},
	"rock": {"name": "Камнемёт", "hp": 85.0, "speed": 38.0, "armor": 0.1, "mres": 0.0,
		"gold": 14, "lives": 1, "size": 13.0, "draw_h": 59.8, "fps": 6.0,
		"dmg": Vector2(3, 6), "rate": 1.2,
		"ranged": {"range": 125.0, "rate": 2.6, "dmg": Vector2(12, 18), "splash": 26.0, "proj": "rock"}},
	"cart": {"name": "Пушечная повозка", "hp": 320.0, "speed": 30.0, "armor": 0.45, "mres": 0.0,
		"gold": 30, "lives": 2, "size": 18.0, "draw_h": 69.0, "fps": 5.0,
		"dmg": Vector2(4, 8), "rate": 1.5,
		"ranged": {"range": 170.0, "rate": 3.5, "dmg": Vector2(18, 28), "splash": 45.0, "proj": "cart"}},
	"crow": {"name": "Всадник на вороне", "hp": 40.0, "speed": 55.0, "armor": 0.0, "mres": 0.0,
		"gold": 12, "lives": 1, "size": 12.0, "draw_h": 62.1, "fps": 7.0, "flying": true,
		"dmg": Vector2(0, 0), "rate": 1.0,
		"ranged": {"range": 85.0, "rate": 2.2, "dmg": Vector2(8, 12), "splash": 22.0, "proj": "crow"}},
	"brute": {"name": "Громила", "hp": 950.0, "speed": 24.0, "armor": 0.25, "mres": 0.1,
		"gold": 80, "lives": 3, "size": 20.0, "draw_h": 87.4, "fps": 7.0,
		"dmg": Vector2(18, 28), "rate": 1.8,
		"tower_dmg": Vector2(35, 50), "tower_range": 115.0},
	# Босс последнего уровня. Фазы: 65% — зовёт подмогу, 35% — оглушает башню, 15% — ярость.
	"king": {"name": "Король гоблинов", "hp": 1400.0, "speed": 20.0, "armor": 0.3, "mres": 0.25,
		"gold": 250, "lives": 10, "size": 22.0, "draw_h": 104.0, "fps": 8.0, "boss": true,
		"dmg": Vector2(30, 45), "rate": 1.6},
}

# Волна = список групп: [тип, количество, путь (0 лево, 1 право, 2 низ), интервал, задержка]
const WAVES := [
	[["grunt", 8, 0, 1.2, 0.0]],
	[["grunt", 8, 0, 1.0, 0.0], ["grunt", 8, 1, 1.0, 3.0]],
	[["grunt", 10, 2, 0.9, 0.0], ["spearman", 4, 0, 1.5, 5.0]],
	[["spearman", 6, 0, 1.4, 0.0], ["mage", 3, 1, 2.0, 4.0], ["grunt", 8, 2, 0.8, 2.0]],
	[["crow", 4, 1, 1.5, 0.0], ["grunt", 12, 0, 0.7, 2.0], ["spearman", 6, 2, 1.3, 4.0]],
	[["rock", 4, 0, 2.2, 0.0], ["mage", 5, 1, 1.8, 0.0], ["grunt", 12, 2, 0.6, 3.0]],
	[["brute", 1, 2, 1.0, 0.0], ["spearman", 8, 0, 1.2, 2.0], ["grunt", 12, 1, 0.6, 2.0]],
	[["cart", 2, 0, 6.0, 0.0], ["crow", 6, 1, 1.2, 0.0], ["mage", 6, 2, 1.5, 3.0], ["grunt", 12, 0, 0.6, 6.0]],
	[["brute", 2, 0, 7.0, 0.0], ["rock", 6, 1, 1.8, 2.0], ["spearman", 10, 2, 1.0, 3.0]],
	[["crow", 6, 0, 1.0, 0.0], ["crow", 6, 1, 1.0, 0.0], ["cart", 2, 2, 6.0, 4.0], ["mage", 8, 0, 1.2, 5.0]],
	[["brute", 3, 2, 6.0, 0.0], ["cart", 3, 0, 5.0, 2.0], ["rock", 8, 1, 1.5, 3.0], ["spearman", 12, 0, 0.9, 4.0]],
	[["brute", 2, 0, 6.0, 0.0], ["brute", 2, 1, 6.0, 0.0], ["cart", 4, 2, 4.0, 2.0],
		["crow", 10, 1, 0.8, 5.0], ["mage", 10, 0, 1.0, 6.0], ["grunt", 20, 2, 0.4, 8.0]],
]

const START_GOLD := 350
const START_LIVES := 20
const WAVE_GAP := 25.0          # секунд между волнами
const EARLY_BONUS_PER_SEC := 2  # золото за досрочный вызов волны

const ABILITIES := {
	"meteor": {"name": "Огненный шар", "cooldown": 35.0, "radius": 65.0, "dmg": Vector2(35, 55)},
}

# ---------------------------------------------------------------- СПЕЦИАЛИЗАЦИИ (III уровень)
# На улучшении II → III игрок выбирает одну из двух веток. Поля перекрывают статы III уровня.
const SPECS := {
	"crossbow": {
		"sniper": {"name": "Снайпер", "desc": "Огромная дальность, мощный выстрел",
			"range": 290.0, "dmg": Vector2(70, 95), "rate": 2.1, "color": Color(0.35, 0.6, 1.0)},
		"rapid": {"name": "Скорострел", "desc": "Урон меньше, стреляет втрое чаще",
			"range": 190.0, "dmg": Vector2(13, 19), "rate": 0.32, "color": Color(1.0, 0.65, 0.2)},
	},
	"mage": {
		"storm": {"name": "Буря", "desc": "Молния прыгает по 8 врагам",
			"chain": 8, "jump_k": 0.82, "color": Color(0.55, 0.75, 1.0)},
		"curse": {"name": "Проклятие", "desc": "Урон меньше, враги замедлены",
			"dmg": Vector2(16, 26), "chain": 5, "slow": 0.45, "slow_t": 2.5, "color": Color(0.7, 0.3, 0.9)},
	},
	"barracks": {
		"guards": {"name": "Стража", "desc": "3 рыцаря в тяжёлой броне",
			"hp": 290.0, "armor": 0.55, "dmg": Vector2(9, 14), "respawn": 9.0, "archers": 0,
			"color": Color(0.75, 0.78, 0.85)},
		"rangers": {"name": "Стрелки", "desc": "3 рыцаря послабее и 4 лучника",
			"hp": 95.0, "armor": 0.25, "dmg": Vector2(5, 8), "respawn": 8.0, "archers": 4,
			"color": Color(0.4, 0.85, 0.4)},
	},
}

# ---------------------------------------------------------------- БОНУСЫ МЕЖДУ ВОЛНАМИ
# Перед 2 и 3 волной игрок выбирает 1 из 2 случайных бонусов — действуют до конца боя.
const BUFFS := {
	"bolts": {"name": "Острые болты", "desc": "Арбалеты наносят +20% урона", "icon": "crossbow"},
	"armor": {"name": "Тяжёлые доспехи", "desc": "Рыцари получают +30% здоровья", "icon": "knight"},
	"overload": {"name": "Перегрузка", "desc": "Молния мага бьёт на 1 цель больше", "icon": "mage"},
	"economy": {"name": "Военная экономика", "desc": "Продажа башен возвращает 80%", "icon": "coin"},
	"meteors": {"name": "Метеоритный дождь", "desc": "Огненный шар: 4 метеора вместо 3", "icon": "meteor"},
	"summon": {"name": "Быстрый призыв", "desc": "Откат героев на 20% быстрее", "icon": "gold"},
}

# ---------------------------------------------------------------- КОРОЛЕВСТВО
# Постоянные бонусы за общее число звёзд.
const KINGDOM := [
	{"stars": 24, "id": "gold", "name": "Казна", "desc": "+20 золота в начале боя"},
	{"stars": 28, "id": "walls", "name": "Крепкие стены", "desc": "Замок: +2 сердца"},
	{"stars": 32, "id": "horn", "name": "Боевой рог", "desc": "+25% золота за ранний вызов"},
	{"stars": 36, "id": "fire", "name": "Пламя дракона", "desc": "Огненный шар: +1 метеор"},
	{"stars": 40, "id": "valor", "name": "Доблесть", "desc": "Герои остаются на 3 с дольше"},
	{"stars": 45, "id": "challenge", "name": "Испытания", "desc": "Режим испытаний (скоро)"},
	{"stars": 48, "id": "secret", "name": "Тайный уровень", "desc": "Последняя битва (скоро)"},
]
