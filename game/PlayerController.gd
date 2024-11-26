class_name PlayerController

extends Node

signal disassociation_changed
signal crab_swapped


var _crab: Crab
var _inputMovement: Vector2
var is_disassociating: bool = false


func _process(delta: float) -> void:
	_process_movement()
	_process_dash()
	_process_harvest(delta)
	_process_pickup()
	_process_reproduction(delta)


func _process_movement() -> void:
	_crab.move(movement_input())


func movement_input() -> Vector2:
	var input: Vector2
	input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return input.normalized()


func _on_crab_die() -> void:
	var new_crab: Crab = find_living_family_member()
	if new_crab == null: return
	
	_shift_crab()
	_disassociate()


func _disassociate() -> void:
	is_disassociating = true
	disassociation_changed.emit()


func _process_swap() -> void:
	if is_disassociating:
		if Input.is_action_just_pressed("swap"):
			is_disassociating = false
			disassociation_changed.emit()
		elif Input.is_action_just_pressed("move_left"):
			_shift_crab(-1)
		elif Input.is_action_just_pressed("move_right"):
			_shift_crab(+1)
			
	else:
		if Input.is_action_just_pressed("swap"):
			_disassociate()
			crab_swapped.emit()


func _shift_crab(indexShift: int = 1) -> void:
	var prev_crab: Crab = _crab
	var familyCrabs: Array = get_family_crabs()
	if familyCrabs.size() == 0: return
	
	var currentIndex: int = familyCrabs.find(_crab)
	var newIndex: int = ((currentIndex + indexShift) as int) % familyCrabs.size()
	var next_crab: Crab = familyCrabs[newIndex]
	
	#var replacement_ai: CrabAI = crab_ai_scene.instantiate()
	#prev_crab.add_child(replacement_ai)
	
	var existing_ai: CrabAI = next_crab.get_node("CrabAI")
	if existing_ai != null: existing_ai.queue_free()
	
	set_crab(next_crab)
	
	crab_swapped.emit()


func set_crab(crab: Crab) -> void:
	if _crab != null: _unset_crab()
	_crab = crab
	_crab.ai.enabled = false
	_crab.on_death.connect(_on_crab_die)


func _unset_crab() -> void:
	if _crab == null: return
	_crab.ai.enabled = true
	_crab.on_death.disconnect(_on_crab_die)


func find_living_family_member() -> Crab:
	var living_family_members: Array = get_family_crabs()
	if living_family_members.size() == 0: return null
	
	return get_family_crabs().front()


func get_family_crabs() -> Array:
	#return (_map.get_all_crabs()
		#.filter(func(crab: Crab) -> bool:
		#return (is_instance_valid(crab) && 
		#crab._family == Crab.Family.PLAYER && 
		#!crab.is_dead())
		#)
	#)
	return []


func _process_dash() -> void:
	if Input.is_action_just_pressed("dash"):
		_crab.dash()


func _process_harvest(delta) -> void:
	if Input.is_action_pressed("harvest"):
		if !_crab.harvest(delta):
			_crab.stop_harvest()
	if Input.is_action_just_released("harvest"):
		_crab.stop_harvest()


func _process_pickup() -> void:
	return #TODO: implement pickup
	#if Input.is_action_pressed("pickup"):
		#if _crab.is_holding():
			#_crab.pickup()
		#else:
			#_crab.drop_held()


func _process_reproduction(delta) -> void:
	if Input.is_action_pressed("reproduce"):
		if !_crab.auto_reproduce(delta):
			_crab.stop_reproduce()
	if Input.is_action_just_released("reproduce"):
		_crab.stop_reproduce()
