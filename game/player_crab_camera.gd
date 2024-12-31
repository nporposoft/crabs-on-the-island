class_name PlayerCrabCamera

extends Camera


func init() -> void:
	var scenario: Scenario = get_parent()
	var crab_spawner: CrabSpawner = Util.require_child(scenario, CrabSpawner)
	crab_spawner.on_spawn.connect(_on_crab_spawn)


func _on_crab_spawn(crab: Crab) -> void:
	if crab.is_player():
		super.set_target(crab)