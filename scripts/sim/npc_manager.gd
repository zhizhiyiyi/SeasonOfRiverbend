extends Node2D

const NpcScript = preload("res://scripts/sim/npc.gd")
const ROLE_FARMER := 0
const ROLE_LUMBERJACK := 1
const ACTIVITY_EATING := 4

@export var villager_count := 10

var villagers: Array = []
var food_stock := 80.0
var wood_stock := 20.0
var _ecology_manager: Node2D

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_ecology_manager = get_node_or_null("../NatureLayer")
	_rng.seed = WorldManager.world_seed * 17 + 5
	if WorldManager:
		WorldManager.world_generated.connect(_on_world_generated)
	if SimulationManager:
		SimulationManager.simulation_tick.connect(_on_simulation_tick)
	if TimeManager:
		TimeManager.hour_changed.connect(_on_hour_changed)

	_spawn_villagers()

func get_population() -> int:
	return villagers.size()

func get_status_line() -> String:
	if villagers.is_empty():
		return "Population: 0"

	var working_count := 0
	for villager in villagers:
		if villager.is_working():
			working_count += 1

	var ecology_line := ""
	if _ecology_manager and _ecology_manager.has_method("get_summary_line"):
		ecology_line = "  %s" % _ecology_manager.call("get_summary_line")

	return "Population: %d  Working: %d  Food: %d  Wood: %d%s" % [
		villagers.size(),
		working_count,
		int(round(food_stock)),
		int(round(wood_stock)),
		ecology_line,
	]

func get_save_data() -> Dictionary:
	var villager_data: Array = []
	for villager in villagers:
		if villager.has_method("get_save_data"):
			villager_data.append(villager.get_save_data())

	return {
		"food_stock": food_stock,
		"wood_stock": wood_stock,
		"villagers": villager_data,
	}

func load_from_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return

	_clear_villagers()
	food_stock = float(data.get("food_stock", 80.0))
	wood_stock = float(data.get("wood_stock", 20.0))

	var list: Variant = data.get("villagers", [])
	if list is Array:
		for record in list:
			if not (record is Dictionary):
				continue
			var villager = NpcScript.new()
			villager.load_from_save_data(record)
			add_child(villager)
			villagers.append(villager)

func _on_world_generated(_seed: int) -> void:
	_clear_villagers()
	_spawn_villagers()

func _on_simulation_tick(_tick_count: int, delta_seconds: float) -> void:
	if villagers.is_empty():
		return

	for villager in villagers:
		villager.simulate_tick(delta_seconds)
		if villager.activity == ACTIVITY_EATING:
			food_stock = maxf(food_stock - 0.35, 0.0)

	var consume_rate := float(villagers.size()) * 0.005
	food_stock = maxf(food_stock - consume_rate * delta_seconds, 0.0)

func _on_hour_changed(_hour: int) -> void:
	for villager in villagers:
		villager.update_behavior()

	_resolve_productivity_tick()

func _spawn_villagers() -> void:
	if WorldManager.get_grid_data() == null:
		return

	for i in villager_count:
		var home := WorldManager.get_random_walkable_cell(_rng)
		var work := WorldManager.get_random_walkable_cell(_rng)
		while work == home:
			work = WorldManager.get_random_walkable_cell(_rng)

		var villager = NpcScript.new()
		var role: int = ROLE_FARMER if i % 2 == 0 else ROLE_LUMBERJACK
		villager.configure(i + 1, role, home, home, work)
		add_child(villager)
		villagers.append(villager)

func _clear_villagers() -> void:
	for villager in villagers:
		villager.queue_free()
	villagers.clear()

func _resolve_productivity_tick() -> void:
	for villager in villagers:
		if not villager.is_working():
			continue

		if villager.role == ROLE_FARMER:
			var gathered_food := _harvest_food_at(villager.work_cell, 2.2)
			food_stock += gathered_food * 0.9
		else:
			var gathered_wood := _harvest_wood_at(villager.work_cell, 1.6)
			wood_stock += gathered_wood * 0.9

func _harvest_food_at(cell: Vector2i, amount: float) -> float:
	if _ecology_manager and _ecology_manager.has_method("harvest_food"):
		return float(_ecology_manager.call("harvest_food", cell, amount))
	return amount * 0.5

func _harvest_wood_at(cell: Vector2i, amount: float) -> float:
	if _ecology_manager and _ecology_manager.has_method("harvest_wood"):
		return float(_ecology_manager.call("harvest_wood", cell, amount))
	return amount * 0.5
