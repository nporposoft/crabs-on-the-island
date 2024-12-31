class_name PlayerController

extends Node

signal disassociation_changed
signal crab_swapped


var crab: Crab
var is_disassociating: bool = false


func _process(delta: float) -> void:
	if !is_instance_valid(crab): return

	_process_movement()
	_process_dash()
	_process_harvest(delta)
	_process_pickup()
	_process_reproduction(delta)


func _process_movement() -> void:
	crab.move(movement_input())


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


func _on_crab_reproduce(parent: Crab, child: Crab) -> void:
	pass


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
	var prev_crab: Crab = crab
	var familyCrabs: Array = get_family_crabs()
	if familyCrabs.size() == 0: return
	
	var currentIndex: int = familyCrabs.find(crab)
	var newIndex: int = ((currentIndex + indexShift) as int) % familyCrabs.size()
	var next_crab: Crab = familyCrabs[newIndex]
	
	#var replacement_ai: CrabAI = crab_ai_scene.instantiate()
	#prev_crab.add_child(replacement_ai)
	
	var existing_ai: CrabAI = next_crab.get_node("CrabAI")
	if existing_ai != null: existing_ai.queue_free()
	
	set_crab(next_crab)
	
	crab_swapped.emit()


func set_crab(new_crab: Crab) -> void:
	if crab != null: unset_crab()
	crab = new_crab
	crab.ai.enabled = false
	_attach_crab_signals(crab)


func unset_crab() -> void:
	if crab == null: return
	crab.ai.enabled = true
	_detach_crab_signals(crab)


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
		crab.dash()


func _process_harvest(delta) -> void:
	if Input.is_action_pressed("harvest"):
		if !_harvest(delta):
			crab.stop_harvest()
	if Input.is_action_just_released("harvest"):
		crab.stop_harvest()


func _harvest(delta: float) -> bool:
	if !crab.can_harvest(): return false

	var resources_in_reach: ResourceCollection = crab.reach.get_resources()

	if crab.can_attack():
		var nearest_crab: Crab = resources_in_reach.nearest_crab(crab.position)
		if nearest_crab != null:
			return crab.attack(nearest_crab, delta)

	var nearest_resources: Array = resources_in_reach.by_distance(crab.position)
	for nearest_resource: Node2D in nearest_resources:
		if crab.want_resource(nearest_resource):
			return crab.harvest(nearest_resource, delta)
	return false


func _process_pickup() -> void:
	return #TODO: implement pickup
	#if Input.is_action_pressed("pickup"):
		#if _crab.is_holding():
			#_crab.pickup()
		#else:
			#_crab.drop_held()


func _process_reproduction(delta) -> void:
	if Input.is_action_pressed("reproduce"):
		if !crab.auto_reproduce(delta):
			crab.stop_reproduce()
	if Input.is_action_just_released("reproduce"):
		crab.stop_reproduce()


func _attach_crab_signals(crab: Crab) -> void:
	crab.on_death.connect(_on_crab_die)
	crab.on_reproduce.connect(_on_crab_reproduce)
	

func _detach_crab_signals(crab: Crab) -> void:
	crab.on_death.disconnect(_on_crab_die)
	crab.on_reproduce.disconnect(_on_crab_reproduce)
	
