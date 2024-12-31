class_name Scenario

extends Node

signal on_ready

var crab_spawner: CrabSpawner


func _ready() -> void:
	crab_spawner = Util.require_child(self, CrabSpawner)

	for child: Node in get_children():
		if child.has_method("init"):
			child.init()

	_spawn_resources()
	_spawn_crabs()

	on_ready.emit()


func _spawn_resources() -> void:
	pass


func _spawn_crabs() -> void:
	for spawn_point: SpawnPoint in _get_spawn_points():
		crab_spawner.spawn_from_point(spawn_point)


func _get_spawn_points() -> Array:
	return (get_children().filter(func(child: Node) -> bool:
		var spawn_point: SpawnPoint = child as SpawnPoint
		return spawn_point != null && spawn_point.enabled
	))


func crabs() -> CrabCollection:
	var all_crabs: Array[Crab]
	for node: Node in get_children():
		var crab: Crab = node as Crab
		if crab != null:
			all_crabs.push_back(crab)
	return CrabCollection.new(all_crabs)
