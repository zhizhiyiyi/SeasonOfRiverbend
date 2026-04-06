extends RefCounted
class_name GridData

enum TerrainType {
	PLAINS,
	FOREST,
	MOUNTAIN,
	RIVER,
}

var width: int
var height: int
var terrain: PackedInt32Array
var height_map: PackedFloat32Array
var humidity_map: PackedFloat32Array
var movement_cost: PackedFloat32Array

func _init(new_width: int, new_height: int) -> void:
	width = new_width
	height = new_height
	var size := width * height
	terrain.resize(size)
	height_map.resize(size)
	humidity_map.resize(size)
	movement_cost.resize(size)

	for i in size:
		terrain[i] = TerrainType.PLAINS
		height_map[i] = 0.0
		humidity_map[i] = 0.0
		movement_cost[i] = 1.0

func index(x: int, y: int) -> int:
	return y * width + x

func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

func set_height(x: int, y: int, value: float) -> void:
	height_map[index(x, y)] = value

func get_height(x: int, y: int) -> float:
	return height_map[index(x, y)]

func set_humidity(x: int, y: int, value: float) -> void:
	humidity_map[index(x, y)] = value

func get_humidity(x: int, y: int) -> float:
	return humidity_map[index(x, y)]

func set_terrain(x: int, y: int, terrain_type: int) -> void:
	terrain[index(x, y)] = terrain_type
	movement_cost[index(x, y)] = _terrain_movement_cost(terrain_type)

func get_terrain(x: int, y: int) -> int:
	return terrain[index(x, y)]

func get_movement_cost(x: int, y: int) -> float:
	return movement_cost[index(x, y)]

func _terrain_movement_cost(terrain_type: int) -> float:
	match terrain_type:
		TerrainType.PLAINS:
			return 1.0
		TerrainType.FOREST:
			return 1.4
		TerrainType.MOUNTAIN:
			return 2.2
		TerrainType.RIVER:
			return 10.0
		_:
			return 1.0
