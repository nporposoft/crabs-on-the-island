class_name SwitcherController

extends InputController

signal on_set_crab(crab: Crab)
signal on_select(crab: Crab)

var _scenario: Scenario
var _player_crab_controller: PlayerCrabController


func init() -> void:
	_scenario = get_parent()
	_player_crab_controller = Util.require_child(_scenario, PlayerCrabController)

	if _enabled: PlayerInputManager.set_controller(self)


func set_crab(crab: Crab) -> void:
	_player_crab_controller.set_crab(crab)
	on_set_crab.emit(crab)


func process(_delta: float) -> void:
	if !is_instance_valid(_player_crab_controller.crab):
		_shift_crab()

	if Input.is_action_just_pressed("swap"):
		on_select.emit(_player_crab_controller.crab)
		PlayerInputManager.restore()
	elif Input.is_action_just_pressed("move_left"):
		_shift_crab(-1)
	elif Input.is_action_just_pressed("move_right"):
		_shift_crab(1)


func _shift_crab(direction: int = 1) -> void:
	var player_crabs: Array = _scenario.crabs().of_family(Crab.Family.PLAYER).to_a()
	if player_crabs.size() == 0: return

	var current_index: int = player_crabs.find(_player_crab_controller.crab)
	var shift_index: int
	if current_index == -1:
		shift_index = randi_range(0, player_crabs.size() - 1)
	else:
		shift_index = (current_index + direction) % player_crabs.size()
	set_crab(player_crabs[shift_index])