class_name SwitcherController

extends InputController

var _scenario: Scenario
var _player_crab_controller: PlayerCrabController
var _hud: HUD
var _camera: PlayerCrabCamera
var _current_crab: Crab

func init() -> void:
	_scenario = get_parent()
	_player_crab_controller = Util.require_child(_scenario, PlayerCrabController)
	_player_crab_controller.new_crab_set.connect(set_crab)

	# TODO: I don't love the SwitcherController knowing so much about the HUD and the camera. Consider using a signal.
	_camera = Util.require_child(_scenario, PlayerCrabCamera)
	_hud = Util.require_child(_scenario, HUD)

	if _enabled: PlayerInputManager.set_controller(self)


func set_crab(crab: Crab) -> void:
	_current_crab = crab
	_hud.set_crab(crab)
	_camera.set_target(crab)


func process(_delta: float) -> void:
	if !is_instance_valid(_current_crab):
		_shift_crab()

	if Input.is_action_just_pressed("swap"):
		_player_crab_controller.set_crab(_current_crab)
		PlayerInputManager.restore()
	elif Input.is_action_just_pressed("move_left"):
		_shift_crab(-1)
	elif Input.is_action_just_pressed("move_right"):
		_shift_crab(1)


func _shift_crab(direction: int = 1) -> void:
	var player_crabs: Array = _scenario.crabs().of_family(Crab.Family.PLAYER).to_a()
	if player_crabs.size() == 0: return

	var current_index: int = player_crabs.find(_current_crab)
	var shift_index: int = (current_index + direction) % player_crabs.size()
	set_crab(player_crabs[shift_index])