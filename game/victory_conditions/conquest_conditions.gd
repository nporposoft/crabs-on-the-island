class_name ConquestConditions

extends VictoryConditions

@export var scenario: Scenario


func _ready() -> void:
	_on_crab_death.connect(_evaluate)


func _evaluate() -> void:
	var living_crabs: CrabCollection = scenario.crabs().living()
	var player_crabs_count: int = living_crabs.of_family(Crab.Family.PLAYER).size()
	var ai_crabs_count: int = living_crabs.of_family(Crab.Family.AI).size()
	if player_crabs_count == 0:
		defeat.emit()
	elif ai_crabs_count == 0:
		victory.emit()
