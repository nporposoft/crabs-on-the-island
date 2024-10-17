extends Node

signal on_change
var enabled: bool

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		enabled = !enabled
		on_change.emit(enabled)
