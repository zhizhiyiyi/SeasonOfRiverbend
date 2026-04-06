extends Node2D
class_name WorldDebugView

@export var tile_size := 10

const TERRAIN_PLAINS := 0
const TERRAIN_FOREST := 1
const TERRAIN_MOUNTAIN := 2
const TERRAIN_RIVER := 3

var _terrain_colors := {
	TERRAIN_PLAINS: Color("7eb66a"),
	TERRAIN_FOREST: Color("2f7d48"),
	TERRAIN_MOUNTAIN: Color("7f7f86"),
	TERRAIN_RIVER: Color("3d7edb"),
}

func _ready() -> void:
	if WorldManager:
		tile_size = WorldManager.cell_size
	if WorldManager:
		WorldManager.world_generated.connect(_on_world_generated)
	if TimeManager:
		TimeManager.minute_advanced.connect(_on_time_advanced)

	queue_redraw()

func _on_world_generated(_seed: int) -> void:
	queue_redraw()

func _on_time_advanced(_total_minutes: int, _day_fraction: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not WorldManager:
		return

	var grid = WorldManager.get_grid_data()
	if grid == null:
		return

	for y in grid.height:
		for x in grid.width:
			var terrain: int = grid.get_terrain(x, y)
			var color: Color = _terrain_colors.get(terrain, Color.MAGENTA)
			draw_rect(Rect2(x * tile_size, y * tile_size, tile_size, tile_size), color)

	if TimeManager:
		var light: float = TimeManager.get_daylight_factor()
		var dark_alpha: float = clamp(0.7 - light * 0.7, 0.0, 0.65)
		draw_rect(
			Rect2(0, 0, grid.width * tile_size, grid.height * tile_size),
			Color(0.03, 0.05, 0.1, dark_alpha),
			true
		)
