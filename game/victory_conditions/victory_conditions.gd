class_name VictoryConditions

extends Node

# These public signals and methods are defining an API that Scenarios use to communicate
# back and forth with child implementations of VictoryConditions
@warning_ignore("unused_signal")
signal victory
@warning_ignore("unused_signal")
signal defeat


func on_crab_death() -> void:
	_on_crab_death.emit()

func on_crab_spawn() -> void:
	_on_crab_spawn.emit()


# These private signals can be hooked into by child implemenations of VictoryConditions
# to respond appropriately to events as desired
signal _on_crab_death
signal _on_crab_spawn
