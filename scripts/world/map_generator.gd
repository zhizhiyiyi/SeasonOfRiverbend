extends RefCounted
class_name MapGenerator

const TERRAIN_PLAINS := 0
const TERRAIN_FOREST := 1
const TERRAIN_MOUNTAIN := 2
const TERRAIN_RIVER := 3

const CARDINAL_DIRECTIONS := [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

func generate(grid, seed: int) -> void:
	var elevation_noise := FastNoiseLite.new()
	elevation_noise.seed = seed
	elevation_noise.frequency = 0.035
	elevation_noise.fractal_octaves = 5
	elevation_noise.fractal_gain = 0.55

	var humidity_noise := FastNoiseLite.new()
	humidity_noise.seed = seed + 837
	humidity_noise.frequency = 0.05
	humidity_noise.fractal_octaves = 4
	humidity_noise.fractal_gain = 0.6

	for y in grid.height:
		for x in grid.width:
			var elevation := _sample01(elevation_noise, x, y)
			var humidity := _sample01(humidity_noise, x, y)

			grid.set_height(x, y, elevation)
			grid.set_humidity(x, y, humidity)
			grid.set_terrain(x, y, _pick_base_terrain(elevation, humidity))

	_carve_rivers(grid, seed)

func _sample01(noise: FastNoiseLite, x: int, y: int) -> float:
	return (noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5

func _pick_base_terrain(elevation: float, humidity: float) -> int:
	if elevation > 0.72:
		return TERRAIN_MOUNTAIN
	if humidity > 0.58:
		return TERRAIN_FOREST
	return TERRAIN_PLAINS

func _carve_rivers(grid, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7919 + 101

	var sources := _river_sources(grid, 6)
	if sources.is_empty():
		return

	for i in mini(4, sources.size()):
		var source := sources[rng.randi_range(0, sources.size() - 1)]
		_flow_river(grid, source, rng)

func _river_sources(grid, target_count: int) -> Array[Vector2i]:
	var sources: Array[Vector2i] = []
	for y in grid.height:
		for x in grid.width:
			if grid.get_height(x, y) > 0.76:
				sources.append(Vector2i(x, y))

	sources.shuffle()
	if sources.size() <= target_count:
		return sources
	return sources.slice(0, target_count)

func _flow_river(grid, source: Vector2i, rng: RandomNumberGenerator) -> void:
	var current := source
	var visited := {}
	var max_steps := int(grid.width * 1.5)

	for _step in max_steps:
		if not grid.in_bounds(current.x, current.y):
			break

		grid.set_terrain(current.x, current.y, TERRAIN_RIVER)
		visited[current] = true

		var next := _choose_downstream(grid, current, visited, rng)
		if next == current:
			break

		current = next
		if current.x <= 1 or current.y <= 1 or current.x >= grid.width - 2 or current.y >= grid.height - 2:
			grid.set_terrain(current.x, current.y, TERRAIN_RIVER)
			break

func _choose_downstream(
		grid,
		from: Vector2i,
		visited: Dictionary,
		rng: RandomNumberGenerator
	) -> Vector2i:
	var best := from
	var best_score := 9_999.0

	for dir in CARDINAL_DIRECTIONS:
		var candidate: Vector2i = from + dir
		if not grid.in_bounds(candidate.x, candidate.y):
			continue
		if visited.has(candidate):
			continue

		var score: float = grid.get_height(candidate.x, candidate.y)
		score += rng.randf_range(0.0, 0.05)
		if score < best_score:
			best = candidate
			best_score = score

	return best
