extends Node2D

const TERRAIN_PLAINS := 0
const TERRAIN_FOREST := 1

var _food_biomass: PackedFloat32Array
var _wood_biomass: PackedFloat32Array
var _food_capacity: PackedFloat32Array
var _wood_capacity: PackedFloat32Array
var _initialized := false

func _ready() -> void:
	if WorldManager:
		WorldManager.world_generated.connect(_on_world_generated)
	if SimulationManager:
		SimulationManager.simulation_tick.connect(_on_simulation_tick)

	if WorldManager and WorldManager.get_grid_data() != null:
		_build_from_world()

func harvest_food(cell: Vector2i, requested_amount: float) -> float:
	if not _initialized:
		return 0.0
	if not _in_bounds(cell):
		return 0.0

	var idx: int = _index(cell)
	var available: float = _food_biomass[idx]
	var harvested: float = minf(available, maxf(requested_amount, 0.0))
	_food_biomass[idx] = available - harvested
	return harvested

func harvest_wood(cell: Vector2i, requested_amount: float) -> float:
	if not _initialized:
		return 0.0
	if not _in_bounds(cell):
		return 0.0

	var idx: int = _index(cell)
	var available: float = _wood_biomass[idx]
	var harvested: float = minf(available, maxf(requested_amount, 0.0))
	_wood_biomass[idx] = available - harvested
	return harvested

func get_summary_line() -> String:
	if not _initialized:
		return "WildFood: --  WildWood: --"
	return "WildFood: %d  WildWood: %d" % [
		int(round(_sum(_food_biomass))),
		int(round(_sum(_wood_biomass))),
	]

func get_save_data() -> Dictionary:
	if not _initialized:
		return {}

	return {
		"food": _packed_to_array(_food_biomass),
		"wood": _packed_to_array(_wood_biomass),
	}

func load_from_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	if not _initialized:
		return

	if data.has("food"):
		_apply_array_to_packed(data["food"], _food_biomass)
	if data.has("wood"):
		_apply_array_to_packed(data["wood"], _wood_biomass)

func _on_world_generated(_seed: int) -> void:
	_build_from_world()

func _on_simulation_tick(_tick_count: int, delta_seconds: float) -> void:
	if not _initialized:
		return

	var season: int = TimeManager.get_season()
	var weather: int = WeatherManager.current_weather
	var weather_multiplier: float = _weather_growth_multiplier(weather)

	for i in _food_biomass.size():
		var food_rate: float = _season_food_growth_rate(season) * weather_multiplier
		var wood_rate: float = _season_wood_growth_rate(season) * weather_multiplier

		var food_cap: float = _food_capacity[i]
		var wood_cap: float = _wood_capacity[i]

		if food_cap > 0.0:
			_food_biomass[i] = minf(food_cap, _food_biomass[i] + food_rate * delta_seconds)
		if wood_cap > 0.0:
			_wood_biomass[i] = minf(wood_cap, _wood_biomass[i] + wood_rate * delta_seconds)

func _build_from_world() -> void:
	var grid = WorldManager.get_grid_data()
	if grid == null:
		return

	var size: int = grid.width * grid.height
	_food_biomass.resize(size)
	_wood_biomass.resize(size)
	_food_capacity.resize(size)
	_wood_capacity.resize(size)

	for y in grid.height:
		for x in grid.width:
			var idx: int = y * grid.width + x
			var terrain: int = grid.get_terrain(x, y)
			if terrain == TERRAIN_FOREST:
				_food_capacity[idx] = 8.0
				_wood_capacity[idx] = 18.0
				_food_biomass[idx] = 4.5
				_wood_biomass[idx] = 10.0
			elif terrain == TERRAIN_PLAINS:
				_food_capacity[idx] = 10.0
				_wood_capacity[idx] = 3.5
				_food_biomass[idx] = 5.5
				_wood_biomass[idx] = 1.5
			else:
				_food_capacity[idx] = 0.0
				_wood_capacity[idx] = 0.0
				_food_biomass[idx] = 0.0
				_wood_biomass[idx] = 0.0

	_initialized = true

func _index(cell: Vector2i) -> int:
	return cell.y * WorldManager.world_width + cell.x

func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < WorldManager.world_width and cell.y >= 0 and cell.y < WorldManager.world_height

func _season_food_growth_rate(season: int) -> float:
	match season:
		TimeManager.Season.SPRING:
			return 0.8
		TimeManager.Season.SUMMER:
			return 1.0
		TimeManager.Season.AUTUMN:
			return 0.6
		TimeManager.Season.WINTER:
			return 0.25
		_:
			return 0.5

func _season_wood_growth_rate(season: int) -> float:
	match season:
		TimeManager.Season.SPRING:
			return 0.3
		TimeManager.Season.SUMMER:
			return 0.38
		TimeManager.Season.AUTUMN:
			return 0.28
		TimeManager.Season.WINTER:
			return 0.1
		_:
			return 0.2

func _weather_growth_multiplier(weather: int) -> float:
	match weather:
		WeatherManager.WeatherType.CLEAR:
			return 1.0
		WeatherManager.WeatherType.CLOUDY:
			return 0.9
		WeatherManager.WeatherType.RAIN:
			return 1.2
		WeatherManager.WeatherType.SNOW:
			return 0.6
		_:
			return 1.0

func _sum(values: PackedFloat32Array) -> float:
	var total := 0.0
	for value in values:
		total += value
	return total

func _packed_to_array(values: PackedFloat32Array) -> Array:
	var out: Array = []
	out.resize(values.size())
	for i in values.size():
		out[i] = values[i]
	return out

func _apply_array_to_packed(source: Variant, target: PackedFloat32Array) -> void:
	if not (source is Array):
		return
	var source_array: Array = source
	var count: int = mini(source_array.size(), target.size())
	for i in count:
		target[i] = float(source_array[i])
