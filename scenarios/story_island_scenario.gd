extends Scenario


func _ready() -> void:
	super()
	# attach special handling to parent victory signal
	victory.connect(_on_victory)


func _on_victory() -> void:
	# disable player controller and let AI take over player crab
	player.unset_crab()
