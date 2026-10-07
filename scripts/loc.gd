class_name Loc
## Локализация RU/EN. Язык определяется через SDK Яндекс Игр (Platform.lang),
## в остальных случаях — по языку системы. Все надписи проходят через Art.text → Loc.t,
## поэтому в коде строки остаются русскими, а перевод берётся из словаря.
## Числа в строке заменяются на «#» при поиске шаблона и подставляются обратно.

static var lang := "ru"
static var _re_num: RegEx
static var _cache := {}


static func set_lang(code: String) -> void:
	code = code.to_lower().substr(0, 2)
	# русский для ru и стран СНГ, где игроки обычно понимают русский; иначе — английский
	lang = "ru" if code in ["ru", "be", "kk", "uk", "uz", "ky", "tg", "hy", "az"] else "en"
	_cache.clear()


static func is_en() -> bool:
	return lang == "en"


static func _has_cyr(s: String) -> bool:
	for i in s.length():
		var c := s.unicode_at(i)
		if c >= 0x400 and c <= 0x4FF:
			return true
	return false


## Перевести строку (готовую, уже с подставленными числами).
static func t(s: String) -> String:
	if lang == "ru" or not _has_cyr(s):
		return s
	if _cache.has(s):
		return _cache[s]
	var res := _translate(s)
	if _cache.size() > 2000:
		_cache.clear()
	_cache[s] = res
	return res


static func _translate(s: String) -> String:
	if EN.has(s):
		return EN[s]
	# шаблон с числами
	if _re_num == null:
		_re_num = RegEx.new()
		_re_num.compile("\\d+(?:\\.\\d+)?")
	var nums: Array = []
	for m in _re_num.search_all(s):
		nums.append(m.get_string())
	if not nums.is_empty():
		var tpl := _re_num.sub(s, "#", true)
		if EN.has(tpl):
			var out: String = EN[tpl]
			for n in nums:
				var i := out.find("#")
				if i >= 0:
					out = out.substr(0, i) + str(n) + out.substr(i + 1)
			return out
	# составные строки: «Имя — куплено!», «Снайпер!», «Всадник уходит»
	if s.contains(" — "):
		var parts := s.split(" — ")
		var outp: Array = []
		for p in parts:
			outp.append(t(p))
		return " — ".join(outp)
	if s.ends_with("!") and EN.has(s.trim_suffix("!")):
		return EN[s.trim_suffix("!")] + "!"
	for suf in SUFFIX:
		if s.ends_with(suf):
			return t(s.trim_suffix(suf)) + SUFFIX[suf]
	return s


const SUFFIX := {" пал!": " has fallen!", " уходит": " leaves", "куплено!": "purchased!"}

const EN := {
	# интерфейс
	"НОВАЯ ИГРА": "NEW GAME", "ВЫХОД": "EXIT", "ВЫБОР УРОВНЯ": "SELECT LEVEL",
	"Нажмите, чтобы продолжить": "Click to continue", "ВЫКЛ": "OFF", "ПАУЗА": "PAUSED",
	"НАЧАТЬ ВОЛНУ": "START WAVE", "ВЫЗВАТЬ ВОЛНУ": "CALL WAVE", "ВОЛНА +#": "WAVE +#",
	"  ВОЛНА #/#": "  WAVE #/#", "Волна #": "Wave #", "УРОВЕНЬ #": "LEVEL #",
	"Уровень # — выдержите 3 волны!": "Level # — survive 3 waves!",
	"Сердец осталось: #   ·   Убито: #": "Hearts left: #   ·   Kills: #",
	"Замок пал на волне #": "The castle fell on wave #", "Убито врагов: #": "Enemies killed: #",
	"+# монет": "+# coins", "# монет": "# coins", "# свободно": "# available", "+# золота": "+# gold",
	"Улучшить": "Upgrade", "Продать": "Sell", "МАКС": "MAX", "МАКС. УРОВЕНЬ": "MAX LEVEL",
	"Только рыцари": "Knights only", "+ Лучники ×2": "+ Archers ×2",
	"Только на дорогу!": "Roads only!", "Только по дороге!": "Roads only!",
	"Герой не куплен — откройте его в «Улучшениях»": "Hero locked — unlock it in Upgrades",
	"куплено!": "purchased!", "БАШНИ": "TOWERS", "ГЕРОИ": "HEROES", "уровень #!": "level #!",
	"Звёзды — покупка новых башен и героев. Монеты за бои — прокачка до 5 уровня.":
		"Stars unlock new towers and heroes. Coins from battles upgrade them up to level 5.",
	"Уровень 1–5 после покупки": "Levels 1–5 after purchase",
	"Урон ×#  Скор. ×#": "Dmg ×#  Speed ×#", "ХП ×#  Урон ×#": "HP ×#  Dmg ×#",
	"Не хватает звёзд: нужно #": "Not enough stars: need #",
	"Не хватает монет: нужно #": "Not enough coins: need #",
	"Выберите бонус перед волной #": "Choose a bonus before wave #",
	"действует до конца боя": "lasts until the end of the battle",
	"КОРОЛЕВСТВО": "KINGDOM", "все бонусы открыты": "all bonuses unlocked", "след.: #★": "next: #★",
	"Собрано звёзд: # из #. Бонусы действуют во всех боях.": "Stars collected: # of #. Bonuses apply in every battle.",
	"ещё #": "# more", "нажмите, чтобы закрыть": "click to close",
	"+25% дальности": "+25% range",
	# башни
	"Арбалет": "Crossbow", "Казарма": "Barracks", "Башня мага": "Mage Tower", "Башня-арбалет": "Crossbow Tower",
	"Мощный выстрел по одной цели": "Powerful single-target shot",
	"Мощный выстрел, бьёт и воронов": "Powerful shot, hits crows too",
	"Рыцари перекрывают дорогу, на 3 ур. + лучники": "Knights block the road, archers at lvl 3",
	"Цепная молния по нескольким врагам": "Chain lightning hits several enemies",
	"Снайпер": "Sniper", "Скорострел": "Rapid Fire", "Буря": "Storm", "Проклятие": "Curse",
	"Стража": "Guards", "Стрелки": "Rangers",
	"Огромная дальность, мощный выстрел": "Huge range, powerful shot",
	"Урон меньше, стреляет втрое чаще": "Less damage, fires 3× faster",
	"Молния прыгает по 8 врагам": "Lightning jumps to 8 enemies",
	"Урон меньше, враги замедлены": "Less damage, slows enemies",
	"3 рыцаря в тяжёлой броне": "3 heavily armored knights",
	"3 рыцаря послабее и 4 лучника": "3 lighter knights and 4 archers",
	"Башня оглушена!": "Tower stunned!", "Башня разрушена!": "Tower destroyed!",
	# герои и способности
	"Золотой рыцарь": "Golden Knight", "Всадник": "Cavalier", "Артиллерист": "Gunner",
	"Огненный шар": "Fireball",
	"Крепкий воин, держит толпу врагов": "Tough warrior, holds back crowds",
	"Быстрый, сильный удар копьём": "Fast, strong lance strike",
	"Пушка бьёт далеко и по площади": "Long-range cannon with splash damage",
	# враги
	"Гоблин": "Goblin", "Копейщик": "Spearman", "Гоблин-алхимик": "Goblin Alchemist", "Камнемёт": "Rock Thrower",
	"Пушечная повозка": "Cannon Cart", "Всадник на вороне": "Crow Rider", "Громила": "Brute",
	"Король гоблинов": "Goblin King", "КОРОЛЬ ГОБЛИНОВ": "GOBLIN KING", "КОРОЛЬ ГОБЛИНОВ!": "THE GOBLIN KING!",
	"Ко мне, гоблины!": "To me, goblins!", "Король зовёт подмогу!": "The King calls for help!",
	"КОРОЛЬ В ЯРОСТИ!": "THE KING IS ENRAGED!", "Финал: в 3-й волне придёт Король гоблинов!":
		"Finale: the Goblin King comes in wave 3!",
	"БАХ!": "BAM!", "БУМ!": "BOOM!", "КРАК!": "CRACK!",
	# бонусы между волнами
	"Острые болты": "Sharp Bolts", "Арбалеты наносят +20% урона": "Crossbows deal +20% damage",
	"Тяжёлые доспехи": "Heavy Armor", "Рыцари получают +30% здоровья": "Knights get +30% health",
	"Перегрузка": "Overload", "Молния мага бьёт на 1 цель больше": "Mage lightning hits 1 more target",
	"Военная экономика": "War Economy", "Продажа башен возвращает 80%": "Selling towers refunds 80%",
	"Метеоритный дождь": "Meteor Shower", "Огненный шар: 4 метеора вместо 3": "Fireball: 4 meteors instead of 3",
	"Быстрый призыв": "Quick Summon", "Откат героев на 20% быстрее": "Hero cooldown 20% faster",
	# королевство
	"Казна": "Treasury", "+20 золота в начале боя": "+20 gold at battle start",
	"Крепкие стены": "Strong Walls", "Замок: +2 сердца": "Castle: +2 hearts",
	"Боевой рог": "War Horn", "+25% золота за ранний вызов": "+25% gold for early waves",
	"Пламя дракона": "Dragon Flame", "Огненный шар: +1 метеор": "Fireball: +1 meteor",
	"Доблесть": "Valor", "Герои остаются на 3 с дольше": "Heroes stay 3 s longer",
	"Испытания": "Challenges", "Режим испытаний (скоро)": "Challenge mode (soon)",
	"Тайный уровень": "Secret Level", "Последняя битва (скоро)": "The final battle (soon)",
	# механики карт (сейчас выключены)
	"Топь: враги и герои идут по ней медленнее": "Swamp: enemies and heroes move slower",
	"Флажок — возвышенность: башня бьёт на 25% дальше": "Flag — high ground: tower range +25%",
	"Святилище: герои рядом с ним лечатся": "Shrine: heroes nearby heal",
	"Шахта: +6 золота каждые 10 с, если рядом нет врагов": "Mine: +6 gold every 10 s if no enemies near",
}
