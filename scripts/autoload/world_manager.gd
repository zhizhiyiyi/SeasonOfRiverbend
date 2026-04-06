extends Node

const GridDataScript = preload("res://scripts/world/grid_data.gd")
const MapGeneratorScript = preload("res://scripts/world/map_generator.gd")

signal world_generated(seed: int)

@export var world_width := 96
@export var world_height := 96
@export var world_seed := 4601

var grid_data
var generator = MapGeneratorScript.new()

func _ready() -> void:
	generate_world(world_seed)

func generate_world(seed: int) -> void:
	world_seed = seed
	grid_data = GridDataScript.new(world_width, world_height)
	generator.generate(grid_data, seed)
	emit_signal("world_generated", seed)

func get_grid_data():
	return grid_data
