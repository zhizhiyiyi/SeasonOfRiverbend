extends Node2D
class_name Npc

enum Role {
	FARMER,
	LUMBERJACK,
}

enum Activity {
	IDLE,
	WALK_TO_WORK,
	WORKING,
	WALK_TO_HOME,
	EATING,
	RESTING,
}

var npc_id := 0
var role := Role.FARMER
var home_cell := Vector2i.ZERO
var work_cell := Vector2i.ZERO
var current_cell := Vector2i.ZERO

var hunger := 10.0
var energy := 85.0
var mood := 70.0

var activity := Activity.IDLE
var move_speed := 30.0

var _path := PackedVector2Array()
var _path_index := 0
var _role_color := Color("f5d37f")

func configure(
		new_id: int,
		new_role: int,
		spawn_cell: Vector2i,
		home: Vector2i,
		work: Vector2i
	) -> void:
	npc_id = new_id
	role = new_role
	current_cell = spawn_cell
	home_cell = home
	work_cell = work
	position = WorldManager.cell_to_world(spawn_cell)
	_role_color = _color_for_role(role)
	queue_redraw()

func set_target_cell(target_cell: Vector2i) -> void:
	if target_cell == current_cell:
		_path = PackedVector2Array()
		_path_index = 0
		return

	_path = WorldManager.get_world_path(current_cell, target_cell)
	_path_index = 0

func simulate_tick(delta_seconds: float) -> void:
	hunger += delta_seconds * 0.9
	hunger = clampf(hunger, 0.0, 100.0)

	if activity == Activity.RESTING:
		energy += delta_seconds * 3.0
	else:
		energy -= delta_seconds * 1.1
	energy = clampf(energy, 0.0, 100.0)

	if hunger > 70.0:
		mood -= delta_seconds * 2.0
	elif energy < 20.0:
		mood -= delta_seconds * 1.2
	else:
		mood += delta_seconds * 0.35
	mood = clampf(mood, 0.0, 100.0)
	queue_redraw()

func get_save_data() -> Dictionary:
	return {
		"npc_id": npc_id,
		"role": role,
		"home_cell": [home_cell.x, home_cell.y],
		"work_cell": [work_cell.x, work_cell.y],
		"current_cell": [current_cell.x, current_cell.y],
		"hunger": hunger,
		"energy": energy,
		"mood": mood,
		"activity": activity,
	}

func load_from_save_data(data: Dictionary) -> void:
	npc_id = int(data.get("npc_id", 0))
	role = int(data.get("role", Role.FARMER))
	home_cell = _vec2i_from_data(data.get("home_cell", [0, 0]))
	work_cell = _vec2i_from_data(data.get("work_cell", [0, 0]))
	current_cell = _vec2i_from_data(data.get("current_cell", [0, 0]))
	hunger = float(data.get("hunger", 10.0))
	energy = float(data.get("energy", 85.0))
	mood = float(data.get("mood", 70.0))
	activity = int(data.get("activity", Activity.IDLE))
	position = WorldManager.cell_to_world(current_cell)
	_role_color = _color_for_role(role)
	_path = PackedVector2Array()
	_path_index = 0
	queue_redraw()

func update_behavior() -> void:
	if energy < 28.0:
		_handle_need_rest()
		return

	if hunger > 62.0:
		_handle_need_food()
		return

	_handle_work_cycle()

func get_activity_name() -> String:
	match activity:
		Activity.IDLE:
			return "Idle"
		Activity.WALK_TO_WORK:
			return "WalkToWork"
		Activity.WORKING:
			return "Working"
		Activity.WALK_TO_HOME:
			return "WalkToHome"
		Activity.EATING:
			return "Eating"
		Activity.RESTING:
			return "Resting"
		_:
			return "Unknown"

func is_at_cell(cell: Vector2i) -> bool:
	return current_cell == cell

func is_working() -> bool:
	return activity == Activity.WORKING

func get_role_name() -> String:
	if role == Role.FARMER:
		return "Farmer"
	return "Lumberjack"

func _process(delta: float) -> void:
	if _path.is_empty():
		return
	if _path_index >= _path.size():
		_path = PackedVector2Array()
		return

	var target_pos: Vector2 = _path[_path_index]
	var to_target: Vector2 = target_pos - position
	var step_distance: float = move_speed * delta

	if to_target.length() <= step_distance:
		position = target_pos
		_path_index += 1
		current_cell = WorldManager.world_to_cell(position)
		if _path_index >= _path.size():
			_path = PackedVector2Array()
			_on_reach_destination()
	else:
		position += to_target.normalized() * step_distance

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, _role_color)
	var mood_bar_width := 10.0
	var fill_ratio: float = mood / 100.0
	draw_rect(Rect2(-5.0, -10.0, mood_bar_width, 2.0), Color(0.12, 0.12, 0.12), true)
	draw_rect(Rect2(-5.0, -10.0, mood_bar_width * fill_ratio, 2.0), Color("7ee082"), true)

func _handle_need_rest() -> void:
	if is_at_cell(home_cell):
		activity = Activity.RESTING
		return

	if activity != Activity.WALK_TO_HOME:
		activity = Activity.WALK_TO_HOME
		set_target_cell(home_cell)

func _handle_need_food() -> void:
	if is_at_cell(home_cell):
		activity = Activity.EATING
		hunger = maxf(hunger - 18.0, 0.0)
		energy = minf(energy + 4.0, 100.0)
		return

	if activity != Activity.WALK_TO_HOME:
		activity = Activity.WALK_TO_HOME
		set_target_cell(home_cell)

func _handle_work_cycle() -> void:
	if is_at_cell(work_cell):
		activity = Activity.WORKING
		return

	if activity != Activity.WALK_TO_WORK:
		activity = Activity.WALK_TO_WORK
		set_target_cell(work_cell)

func _on_reach_destination() -> void:
	if current_cell == home_cell:
		if hunger > 62.0:
			activity = Activity.EATING
		else:
			activity = Activity.RESTING
		return

	if current_cell == work_cell:
		activity = Activity.WORKING
		return

	activity = Activity.IDLE

func _color_for_role(role_id: int) -> Color:
	if role_id == Role.FARMER:
		return Color("f5d37f")
	return Color("a6d3ff")

func _vec2i_from_data(source: Variant) -> Vector2i:
	if source is Array:
		var arr: Array = source
		if arr.size() >= 2:
			return Vector2i(int(arr[0]), int(arr[1]))
	return Vector2i.ZERO
