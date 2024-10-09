class_name Camera

extends Camera2D

@export var _player: Player
@export var _pan_strength: float = 0.5
@export var _zoom_strength: float = 0.5

var zoom_level: int = 5


func init(player: Player) -> void:
	_player = player
	position = _player._crab.position


func _process(delta: float) -> void:
	_update_zoom_level()
	_update_position()


func _update_zoom_level() -> void:
	if Input.is_action_just_pressed("zoom_in"):
		zoom_level = min(zoom_level + 1, 5)
	elif Input.is_action_just_pressed("zoom_out"):
		zoom_level = max(zoom_level - 1, 1)
	var desired_zoom: float = zoom_level / 5.0
	zoom = zoom.lerp(Vector2(desired_zoom, desired_zoom), _zoom_strength)


func _update_position() -> void:
	if is_instance_valid(_player._crab):
		position = position.lerp(_player._crab.position, _pan_strength)
