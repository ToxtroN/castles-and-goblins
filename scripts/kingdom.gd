class_name Kingdom
## «Королевство»: постоянные бонусы, открываемые общим числом звёзд.

static var _cache_t := -1
static var _cache_stars := 0


static func stars() -> int:
	# звёзды считаются из сохранения; кэш на кадр, чтобы не читать файл много раз
	var f := Engine.get_process_frames()
	if f != _cache_t:
		_cache_t = f
		_cache_stars = Shop.stars_total()
	return _cache_stars


static func has(id: String) -> bool:
	if Shop.unlock_all:
		return false   # автотесты — без бонусов королевства
	for k in GameData.KINGDOM:
		if k.id == id:
			return stars() >= int(k.stars)
	return false


static func next_goal() -> Dictionary:
	for k in GameData.KINGDOM:
		if stars() < int(k.stars):
			return k
	return {}
