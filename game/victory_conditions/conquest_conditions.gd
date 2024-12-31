class_name ConquestConditions

extends VictoryConditions

var _scenario: Scenario
var _scenario_started: bool


func init() -> void:
	_scenario = get_parent()
	var crab_spawner: CrabSpawner = Util.require_child(_scenario, CrabSpawner)
	crab_spawner.on_spawn.connect(func(_crab: Crab) -> void: _evaluate())
	crab_spawner.on_death.connect(_evaluate)
	_scenario.on_ready.connect(func() -> void: _scenario_started = true)


func _evaluate() -> void:
	if !_scenario_started: return

	var living_crabs: CrabCollection = _scenario.crabs().living()
	var player_crabs_count: int = living_crabs.of_family(Crab.Family.PLAYER).size()
	var ai_crabs_count: int = living_crabs.of_family(Crab.Family.AI).size()
	if player_crabs_count == 0:
		defeat.emit()
	elif ai_crabs_count == 0:
		victory.emit()
