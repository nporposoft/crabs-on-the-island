class_name CrabAI

extends Node

@export var _vision_distance: float = 2500.0

var _sm: MultiStateMachine = MultiStateMachine.new()
var _vision_area: Area2D

var _wander_timer: Timer

enum States {
	IDLING,
	WANDERING,
	MOVING_TO_RESOURCE,
	HARVESTING
}

var _wander_direction: Vector2

func _ready() -> void:
	_create_vision_area()
	_create_wander_timer()

func _process(delta: float) -> void:
	_vision_area.position = $Crab.position
	
	var visibleMorsels: Array = _find_visible_morsels_by_distance()
	for morsel: Morsel in visibleMorsels:
		if !_want_morsel(morsel): continue
		
		_sm.unset_all_states()
		
		if $Crab.can_reach_morsel(morsel):
			_sm.set_state(States.HARVESTING)
			$Crab.harvest_morsel(delta, morsel)
		else:
			_sm.set_state(States.MOVING_TO_RESOURCE)
			_move_toward_morsel(morsel)
		return
	
	$Crab.stop_harvest()
	
	if _sm.has_state(States.WANDERING):
		if _time_to_idle():
			_start_idling()
		else: 
			_keep_wandering()
	else:
		if _time_to_wander(): 
			_start_wandering()


func _start_wandering() -> void:
	_wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_sm.set_state(States.WANDERING)
	_sm.unset_state(States.IDLING)
	_start_wander_timer()


func _start_idling() -> void:
	_sm.unset_state(States.WANDERING)
	_sm.set_state(States.IDLING)
	_start_idle_timer()


func _time_to_idle() -> bool:
	return _wander_timer.is_stopped()


func _time_to_wander() -> bool:
	return _wander_timer.is_stopped()


func _start_wander_timer() -> void:
	_wander_timer.wait_time = randf_range(3.0, 6.0)
	_wander_timer.start()


func _start_idle_timer() -> void:
	_wander_timer.wait_time = randf_range(1.0, 3.0)
	_wander_timer.start()

func _keep_wandering() -> void:
	$Crab.move(_wander_direction)


func _move_toward_morsel(morsel: Morsel) -> void:
	var direction: Vector2 = morsel.position - $Crab.position
	$Crab.move(direction)


func _want_morsel(morsel: Morsel) -> bool:
	match morsel.mat_type:
		Morsel.MATERIAL_TYPE.IRON:
			return _want_iron()
		Morsel.MATERIAL_TYPE.COBALT:
			return _want_cobalt()
		Morsel.MATERIAL_TYPE.SILICON:
			return _want_silica()
		_:
			return false


func _want_iron() -> bool:
	return $Crab._carried_resources.iron < $Crab.ironTarget


func _want_cobalt() -> bool:
	return false


func _want_water() -> bool:
	return false


func _want_silica() -> bool:
	return false


func _find_visible_morsels() -> Array:
	return (_vision_area.get_overlapping_bodies()
		.map(func(body) -> Morsel: return body as Morsel)
		.filter(func(body) -> bool: return body != null)
	)


func _find_visible_morsels_by_distance() -> Array:
	var visible_morsels: Array = _find_visible_morsels()
	visible_morsels.sort_custom(func(a, b) -> bool:
		var a_distance: float = (a.position - $Crab.position).length()
		var b_distance: float = (b.position - $Crab.position).length()
		return a_distance < b_distance
	)
	return visible_morsels


func _create_wander_timer() -> void:
	_wander_timer = Timer.new()
	_wander_timer.one_shot = true
	add_child(_wander_timer)

func _create_vision_area() -> void:
	var _vision_area_shape: CollisionShape2D = CollisionShape2D.new()
	
	var _vision_area_sphere: CircleShape2D = CircleShape2D.new()
	_vision_area_sphere.radius = _vision_distance
	
	_vision_area_shape.shape = _vision_area_sphere
	
	_vision_area = Area2D.new()
	_vision_area.add_child(_vision_area_shape)
	add_child(_vision_area)
