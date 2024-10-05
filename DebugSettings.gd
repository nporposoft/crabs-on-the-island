extends Node

var enabled: bool

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		enabled = !enabled
		print("debug mode enabled: ", enabled)
