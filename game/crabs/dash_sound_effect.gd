extends AudioStreamPlayer2D

var crab: Crab


func _ready() -> void:
	crab = get_parent()
	crab.on_dash.connect(func() -> void: 
		play()
	)
