class_name PlayerCrabCamera

extends Camera

@export var _max_zoom: int = 5
@export var _min_zoom: int = 1
@export var _current_zoom: int = _max_zoom
@export var _zoom_strength: float = 0.5


func init() -> void:
	var scenario: Scenario = get_parent()

	var crab_spawner: CrabSpawner = Util.require_child(scenario, CrabSpawner)
	crab_spawner.on_player_spawn.connect(func(crab: Crab) -> void:
		super.init_target(crab)
	)

	var switcher_controller: SwitcherController = Util.require_child(scenario, SwitcherController)
	switcher_controller.on_set_crab.connect(set_target)


func _process(delta: float) -> void:
	super._process(delta)
	_update_zoom_level()


func _update_zoom_level() -> void:
	if Input.is_action_just_pressed("zoom_in"):
		_current_zoom = min(_current_zoom + 1, _max_zoom)
	elif Input.is_action_just_pressed("zoom_out"):
		_current_zoom = max(_current_zoom - 1, _min_zoom)
	var desired_zoom: float = _current_zoom / 5.0
	zoom = zoom.lerp(Vector2(desired_zoom, desired_zoom), _zoom_strength)
