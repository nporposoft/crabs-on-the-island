class_name Player

extends Node

const player_color = Color(1.0, 0.0, 0.0)

var zoom_level: int = 5
var _crab: Crab

func _ready():
	_crab = get_parent()
	_crab.isPlayerFamily = true
	_crab.set_color(player_color)

func _process(delta: float) -> void:
	if DebugMode.enabled:
		_process_camera()
	_process_movement()
	_process_dash()
	_process_harvest(delta)
	_process_pickup()
	_process_reproduction(delta)
	_update_camera_position()


func _process_camera() -> void:
	if Input.is_action_just_pressed("zoom_in"):
		zoom_level = min(zoom_level + 1, 5)
	elif Input.is_action_just_pressed("zoom_out"):
		zoom_level = max(zoom_level - 1, 1)
	$Camera2D.set_zoom(Vector2(zoom_level / 5.0, zoom_level / 5.0))


func _process_dash() -> void:
	if Input.is_action_just_pressed("dash"):
		_crab.dash()


func _process_movement() -> void:
	var moveInput: Vector2
	moveInput.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	moveInput.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	_crab.move(moveInput)


func _process_harvest(delta) -> void:
	if Input.is_action_pressed("harvest"):
		if !_crab.harvest(delta):
			_crab.stop_harvest()
	if Input.is_action_just_released("harvest"):
		_crab.stop_harvest()


func _process_pickup() -> void:
	if Input.is_action_pressed("pickup"):
		if _crab.is_holding():
			_crab.pickup()
		else:
			_crab.drop_held()


func _process_reproduction(delta) -> void:
	if Input.is_action_pressed("reproduce"):
		if !_crab.auto_reproduce(delta):
			_crab.stop_reproduce()
	if Input.is_action_just_released("reproduce"):
		_crab.stop_reproduce()

func _update_camera_position() -> void:
	$Camera2D.position = _crab.position
	$Camera2D.transform = _crab.transform
