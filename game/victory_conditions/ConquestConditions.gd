class_name ConquestConditions

extends VictoryConditions

@export var scenario: Scenario


func evaluate() -> VictoryConditions.Condition:
	var living_crabs: CrabCollection = scenario.crabs().living()
	if living_crabs.of_family(Crab.Family.PLAYER).size() == 0:
		return VictoryConditions.Condition.DEFEAT
	elif living_crabs.of_family(Crab.Family.AI).size() == 0:
		return VictoryConditions.Condition.VICTORY
	return VictoryConditions.Condition.UNRESOLVED
