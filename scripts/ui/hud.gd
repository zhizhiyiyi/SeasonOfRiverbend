extends CanvasLayer

@onready var status_label: Label = $StatusLabel
@onready var npc_manager: Node2D = get_node_or_null("../ActorLayer")

func _process(_delta: float) -> void:
	if status_label == null:
		return

	if not TimeManager or not WeatherManager or not WorldManager:
		status_label.text = "Managers are not ready"
		return

	var day := TimeManager.get_day_index() + 1
	var hour := TimeManager.get_hour()
	var minute := TimeManager.get_minute()
	var season := TimeManager.get_season_name()
	var weather := WeatherManager.get_weather_name()
	var seed := WorldManager.world_seed
	var npc_line := "Population: --"
	if npc_manager and npc_manager.has_method("get_status_line"):
		npc_line = npc_manager.call("get_status_line")

	status_label.text = "SeasonOfRiverbend M3  (F5 Save / F9 Load)\nDay %d  %02d:%02d\nSeason: %s\nWeather: %s\nSeed: %d\n%s" % [
		day,
		hour,
		minute,
		season,
		weather,
		seed,
		npc_line,
	]
