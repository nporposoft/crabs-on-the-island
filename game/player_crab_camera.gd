class_name PlayerCrabCamera

extends Camera

@export var _max_zoom: int = 5
@export var _min_zoom: int = 1
@export var _current_zoom: int = _max_zoom
@export var _zoom_strength: float = 0.5

var _crab: Crab


func init() -> void:
	var scenario: Scenario = get_parent()

	# connect to the crab spawner's on_player_spawn signal to set the initial crab
	# but ignore subsequent signals when other player family crabs spawn
	var crab_spawner: CrabSpawner = Util.require_child(scenario, CrabSpawner)
	crab_spawner.on_spawn.connect(func(crab: Crab) -> void:
		if _crab != null: return
		if crab._family != Crab.Family.PLAYER: return

		_crab = crab
		super.init_target(crab)
	)


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
