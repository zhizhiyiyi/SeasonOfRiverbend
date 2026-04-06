extends CanvasLayer

@onready var status_label: Label = $StatusLabel

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

	status_label.text = "SeasonOfRiverbend M1\nDay %d  %02d:%02d\nSeason: %s\nWeather: %s\nSeed: %d" % [
		day,
		hour,
		minute,
		season,
		weather,
		seed,
	]
