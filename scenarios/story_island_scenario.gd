extends Scenario

var _player_controller: PlayerCrabController
var _victory_conditions: VictoryConditions


func _ready() -> void:
	super._ready()

	_player_controller = Util.require_child(self, PlayerCrabController)
	_victory_conditions = Util.require_child(self, VictoryConditions)
	_victory_conditions.victory.connect(_on_victory)


func _on_victory() -> void:
	# disable player controller and let AI take over player crab
	_player_controller.unset_crab()
