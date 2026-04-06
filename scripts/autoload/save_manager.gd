extends Node

const SAVE_PATH := "user://save_slot_1.json"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			save_game()
		elif event.keycode == KEY_F9:
			load_game()

func save_game() -> bool:
	var payload: Dictionary = {
		"version": 1,
		"world_seed": WorldManager.world_seed,
		"time_total_minutes": TimeManager.total_minutes_elapsed,
		"weather": WeatherManager.current_weather,
	}

	var scene := get_tree().current_scene
	if scene:
		var actor_layer := scene.get_node_or_null("ActorLayer")
		if actor_layer and actor_layer.has_method("get_save_data"):
			payload["npc"] = actor_layer.call("get_save_data")

		var nature_layer := scene.get_node_or_null("NatureLayer")
		if nature_layer and nature_layer.has_method("get_save_data"):
			payload["ecology"] = nature_layer.call("get_save_data")

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager failed to open save file")
		return false

	file.store_string(JSON.stringify(payload))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("SaveManager: save file not found")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager failed to open save file for read")
		return false

	var raw_text: String = file.get_as_text()
	var parse_result: Variant = JSON.parse_string(raw_text)
	if not (parse_result is Dictionary):
		push_error("SaveManager: invalid save format")
		return false

	var data: Dictionary = parse_result
	WorldManager.generate_world(int(data.get("world_seed", WorldManager.world_seed)))
	TimeManager.set_total_minutes(int(data.get("time_total_minutes", TimeManager.total_minutes_elapsed)))
	WeatherManager.set_current_weather(int(data.get("weather", WeatherManager.current_weather)), true)
	call_deferred("_apply_scene_data", data)
	return true

func _apply_scene_data(data: Dictionary) -> void:
	var scene := get_tree().current_scene
	if not scene:
		return

	var nature_layer := scene.get_node_or_null("NatureLayer")
	if nature_layer and nature_layer.has_method("load_from_save_data"):
		var ecology_data: Variant = data.get("ecology", {})
		if ecology_data is Dictionary:
			nature_layer.call("load_from_save_data", ecology_data)

	var actor_layer := scene.get_node_or_null("ActorLayer")
	if actor_layer and actor_layer.has_method("load_from_save_data"):
		var npc_data: Variant = data.get("npc", {})
		if npc_data is Dictionary:
			actor_layer.call("load_from_save_data", npc_data)
