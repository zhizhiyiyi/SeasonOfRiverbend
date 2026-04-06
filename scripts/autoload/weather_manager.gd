extends Node

signal weather_changed(new_weather: int)

enum WeatherType {
	CLEAR,
	CLOUDY,
	RAIN,
	SNOW,
}

@export var transition_interval_hours := 3

var current_weather := WeatherType.CLEAR
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 42
	if TimeManager:
		TimeManager.hour_changed.connect(_on_hour_changed)
		TimeManager.day_changed.connect(_on_day_changed)
	_reseed_for_day(TimeManager.get_day_index())

func get_weather_name() -> String:
	match current_weather:
		WeatherType.CLEAR:
			return "Clear"
		WeatherType.CLOUDY:
			return "Cloudy"
		WeatherType.RAIN:
			return "Rain"
		WeatherType.SNOW:
			return "Snow"
		_:
			return "Unknown"

func _on_hour_changed(hour: int) -> void:
	if hour % max(transition_interval_hours, 1) != 0:
		return
	_try_transition()

func _on_day_changed(day_index: int) -> void:
	_reseed_for_day(day_index)

func _reseed_for_day(day_index: int) -> void:
	var season_seed := int(TimeManager.get_season()) * 10_000
	_rng.seed = season_seed + day_index * 97 + 13

func _try_transition() -> void:
	var next := _roll_weather_for_season(TimeManager.get_season())
	if next == current_weather:
		return

	current_weather = next
	emit_signal("weather_changed", int(current_weather))

func _roll_weather_for_season(season: int) -> int:
	var roll := _rng.randf()
	match season:
		TimeManager.Season.SPRING:
			if roll < 0.36:
				return WeatherType.CLEAR
			if roll < 0.66:
				return WeatherType.CLOUDY
			return WeatherType.RAIN
		TimeManager.Season.SUMMER:
			if roll < 0.55:
				return WeatherType.CLEAR
			if roll < 0.8:
				return WeatherType.CLOUDY
			return WeatherType.RAIN
		TimeManager.Season.AUTUMN:
			if roll < 0.3:
				return WeatherType.CLEAR
			if roll < 0.6:
				return WeatherType.CLOUDY
			return WeatherType.RAIN
		TimeManager.Season.WINTER:
			if roll < 0.25:
				return WeatherType.CLEAR
			if roll < 0.55:
				return WeatherType.CLOUDY
			return WeatherType.SNOW
		_:
			return WeatherType.CLEAR
