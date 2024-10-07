extends Camera2D

@export var _player: Player
@export var _pan_strength: float = 0.5
@export var _zoom_strength: float = 0.5

var zoom_level: int = 5

func _ready() -> void:
	position = _player._crab.position


func _process(delta: float) -> void:
	#if DebugMode.enabled:
		#_debug_zoom_override()
	#else:
		#_update_zoom()
	#_update_position()
	_debug_zoom_override()
	_update_position()


func _debug_zoom_override() -> void:
	if Input.is_action_just_pressed("zoom_in"):
		zoom_level = min(zoom_level + 1, 5)
	elif Input.is_action_just_pressed("zoom_out"):
		zoom_level = max(zoom_level - 1, 1)
	set_zoom(Vector2(zoom_level / 5.0, zoom_level / 5.0))


func _update_zoom() -> void:
	var crab_size: float = _player._crab._stats.size
	var desired_zoom: float = 1 / crab_size
	zoom = zoom.lerp(Vector2(desired_zoom, desired_zoom), _zoom_strength)


func _update_position() -> void:
	position = position.lerp(_player._crab.position, _pan_strength)
