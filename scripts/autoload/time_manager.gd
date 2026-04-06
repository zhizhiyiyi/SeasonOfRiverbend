extends Node

signal minute_advanced(total_minutes: int, day_fraction: float)
signal hour_changed(hour: int)
signal day_changed(day_index: int)
signal season_changed(season: int)

enum Season {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER,
}

const MINUTES_PER_DAY := 24 * 60
const DAYS_PER_SEASON := 10
const MINUTES_PER_SEASON := MINUTES_PER_DAY * DAYS_PER_SEASON

@export var seconds_per_game_minute := 0.08
@export var start_hour := 7

var total_minutes_elapsed := 0
var _accumulator := 0.0
var _last_hour := -1
var _last_day := -1
var _last_season := -1

func _ready() -> void:
	total_minutes_elapsed = start_hour * 60
	_emit_time_events()

func _process(delta: float) -> void:
	_accumulator += delta
	if seconds_per_game_minute <= 0.0:
		return

	var step_count := int(floor(_accumulator / seconds_per_game_minute))
	if step_count <= 0:
		return

	_accumulator -= float(step_count) * seconds_per_game_minute
	advance_minutes(step_count)

func advance_minutes(minutes: int) -> void:
	total_minutes_elapsed += minutes
	_emit_time_events()

func get_day_index() -> int:
	return total_minutes_elapsed / MINUTES_PER_DAY

func get_hour() -> int:
	return (total_minutes_elapsed % MINUTES_PER_DAY) / 60

func get_minute() -> int:
	return total_minutes_elapsed % 60

func get_day_fraction() -> float:
	return float(total_minutes_elapsed % MINUTES_PER_DAY) / float(MINUTES_PER_DAY)

func get_season() -> int:
	return int((total_minutes_elapsed / MINUTES_PER_SEASON) % 4)

func get_daylight_factor() -> float:
	var sun_curve := sin((get_day_fraction() - 0.25) * TAU)
	return clamp((sun_curve + 0.2) * 0.9, 0.08, 1.0)

func get_season_name() -> String:
	match get_season():
		Season.SPRING:
			return "Spring"
		Season.SUMMER:
			return "Summer"
		Season.AUTUMN:
			return "Autumn"
		Season.WINTER:
			return "Winter"
		_:
			return "Unknown"

func _emit_time_events() -> void:
	emit_signal("minute_advanced", total_minutes_elapsed, get_day_fraction())

	var hour := get_hour()
	if hour != _last_hour:
		_last_hour = hour
		emit_signal("hour_changed", hour)

	var day := get_day_index()
	if day != _last_day:
		_last_day = day
		emit_signal("day_changed", day)

	var season := get_season()
	if season != _last_season:
		_last_season = season
		emit_signal("season_changed", season)
