extends Node

signal simulation_tick(tick_count: int, delta_seconds: float)

@export var tick_interval_seconds := 0.2

var _accumulator := 0.0
var _tick_count := 0

func _process(delta: float) -> void:
	if tick_interval_seconds <= 0.0:
		return

	_accumulator += delta
	while _accumulator >= tick_interval_seconds:
		_accumulator -= tick_interval_seconds
		_tick_count += 1
		emit_signal("simulation_tick", _tick_count, tick_interval_seconds)
