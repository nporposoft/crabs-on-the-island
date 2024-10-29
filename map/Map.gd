class_name Map

extends Node2D

var _crab_scene = preload("res://crabs/Crab.tscn")

var tutorial_swap: bool = false

const harvestTypeKey = "harvest_type"
const soundTypeKey = "sound_type"

signal victory
signal defeat


func _ready() -> void:
	# init crabs that already exist in scene
	for crab in get_ai_crabs():
		crab.on_death.connect(calculate_win_condition)
		crab.init({}, {}, Color.WHITE, false, self, Crab.Family.AI)


func get_player_spawn_point() -> Node2D:
	return $PlayerSpawnPoint


func create_new_crab() -> Crab:
	var new_crab: Crab = _crab_scene.instantiate()
	new_crab.on_death.connect(calculate_win_condition)
	add_child(new_crab)
	return new_crab


func calculate_win_condition():
	if get_player_crabs().size() == 0:
		defeat.emit()
	elif get_ai_crabs().size() == 0:
		victory.emit()


func get_terrain_at_point(point: Vector2) -> TerrainData:
	push_warning("Map#get_terrain_at_point called -- this method should be overridden")
	return null


func get_terrain_in_radius(point: Vector2, radius: float) -> Array[TerrainData]:
	push_warning("Map#get_terrain_in_radius called -- this method should be overridden")
	return []


func get_all_crabs() -> Array:
	return (get_children().filter(func(child) -> bool:
		var crab: Crab = child as Crab
		return crab != null
	))


func get_player_crabs() -> Array:
	return (
		get_all_crabs()
		.filter(func(crab: Crab) -> bool: return crab._family == Crab.Family.PLAYER && !crab.is_dead())
	)


func get_ai_crabs() -> Array:
	return (
		get_all_crabs()
		.filter(func(crab: Crab) -> bool: return crab._family == Crab.Family.AI && !crab.is_dead())
	)
