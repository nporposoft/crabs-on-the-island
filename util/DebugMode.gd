extends Node

signal on_change(enabled: bool)
var enabled: bool

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		enabled = !enabled
		print("Debug mode set to ", enabled)
		on_change.emit(enabled)
