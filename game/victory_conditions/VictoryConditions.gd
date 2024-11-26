class_name VictoryConditions

extends Node

signal victory
signal defeat

enum Condition {
	UNRESOLVED,
	VICTORY,
	DEFEAT
}


func evaluate() -> Condition:
	push_error("calculate() must be overriden by implementations of VictoryConditions")
	return Condition.UNRESOLVED
