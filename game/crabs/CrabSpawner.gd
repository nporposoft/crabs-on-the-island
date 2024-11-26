class_name CrabSpawner

extends Node

@export var container: Node
@export var crab_scene: PackedScene


func spawn(spawn_point: SpawnPoint) -> Crab:
	var crab: Crab = crab_scene.instantiate()
	container.add_child(crab)
	crab.init(
		spawn_point.carried_resources,
		spawn_point.starting_stats,
		spawn_point.team_color,
		spawn_point.start_with_cobalt,
		spawn_point.family
	)
	crab.position = spawn_point.position
	return crab
