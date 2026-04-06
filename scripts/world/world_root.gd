extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var debug_view: Node2D = $WorldDebugView

func _ready() -> void:
	if camera and WorldManager and debug_view:
		var tile_size: int = debug_view.get("tile_size") as int
		var w: int = WorldManager.world_width * tile_size
		var h: int = WorldManager.world_height * tile_size
		camera.position = Vector2(w * 0.5, h * 0.5)
