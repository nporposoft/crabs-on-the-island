class_name CrabSpawner

extends Node

@export var container: Node
@export var crab_scene: PackedScene


func spawn_from_point(spawn_point: SpawnPoint) -> Crab:
	return spawn_with_attributes(
		spawn_point.position,
		spawn_point.carried_resources,
		spawn_point.starting_stats,
		spawn_point.team_color,
		spawn_point.start_with_cobalt,
		spawn_point.family
	)


func spawn_with_attributes(
	position: Vector2,
	carried_resources: Dictionary,
	stats: Dictionary,
	color: Color,
	contains_cobalt: bool,
	family: Crab.Family,
) -> Crab:
	var crab: Crab = crab_scene.instantiate()
	container.add_child(crab)
	crab.init(carried_resources, stats, color, contains_cobalt, family)
	crab.position = position
	return crab
