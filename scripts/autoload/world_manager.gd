extends Node

const GridDataScript = preload("res://scripts/world/grid_data.gd")
const MapGeneratorScript = preload("res://scripts/world/map_generator.gd")

signal world_generated(seed: int)

@export var world_width := 96
@export var world_height := 96
@export var world_seed := 4601
@export var cell_size := 10

var grid_data
var generator = MapGeneratorScript.new()
var navigation_grid: AStarGrid2D

func _ready() -> void:
	generate_world(world_seed)

func generate_world(seed: int) -> void:
	world_seed = seed
	grid_data = GridDataScript.new(world_width, world_height)
	generator.generate(grid_data, seed)
	_build_navigation_grid()
	emit_signal("world_generated", seed)

func get_grid_data():
	return grid_data

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		(float(cell.x) + 0.5) * float(cell_size),
		(float(cell.y) + 0.5) * float(cell_size)
	)

func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_position.x / float(cell_size))),
		int(floor(world_position.y / float(cell_size)))
	)

func is_cell_walkable(cell: Vector2i) -> bool:
	if grid_data == null:
		return false
	if not grid_data.in_bounds(cell.x, cell.y):
		return false
	return grid_data.get_terrain(cell.x, cell.y) != GridData.TerrainType.RIVER

func get_random_walkable_cell(rng: RandomNumberGenerator) -> Vector2i:
	if grid_data == null:
		return Vector2i.ZERO

	for _attempt in 300:
		var x: int = rng.randi_range(0, world_width - 1)
		var y: int = rng.randi_range(0, world_height - 1)
		var cell := Vector2i(x, y)
		if is_cell_walkable(cell):
			return cell

	return Vector2i(0, 0)

func get_world_path(start_cell: Vector2i, target_cell: Vector2i) -> PackedVector2Array:
	var empty_path := PackedVector2Array()
	if navigation_grid == null:
		return empty_path
	if not is_cell_walkable(start_cell):
		return empty_path
	if not is_cell_walkable(target_cell):
		return empty_path

	var id_path: Array[Vector2i] = navigation_grid.get_id_path(start_cell, target_cell)
	if id_path.is_empty():
		return empty_path

	var world_path := PackedVector2Array()
	for cell in id_path:
		world_path.append(cell_to_world(cell))
	return world_path

func _build_navigation_grid() -> void:
	navigation_grid = AStarGrid2D.new()
	navigation_grid.region = Rect2i(0, 0, world_width, world_height)
	navigation_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	navigation_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	navigation_grid.update()

	for y in world_height:
		for x in world_width:
			var cell := Vector2i(x, y)
			if grid_data.get_terrain(x, y) == GridData.TerrainType.RIVER:
				navigation_grid.set_point_solid(cell, true)
			else:
				navigation_grid.set_point_weight_scale(cell, grid_data.get_movement_cost(x, y))
