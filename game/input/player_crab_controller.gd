class_name PlayerCrabController

extends InputController

signal on_disassociate

var crab: Crab
var _scenario: Scenario
var _switcher_controller: SwitcherController


func init() -> void:
	_scenario = get_parent()

	var crab_spawner: CrabSpawner = Util.require_child(_scenario, CrabSpawner)
	crab_spawner.on_player_spawn.connect(func(player_crab: Crab) -> void:
		set_crab(player_crab)
	)

	_switcher_controller = Util.require_child(_scenario, SwitcherController)

	if _enabled: PlayerInputManager.set_controller(self)


func process(delta: float) -> void:
	if !is_instance_valid(crab): return

	_process_movement()
	_process_dash()
	_process_harvest(delta)
	_process_pickup()
	_process_reproduction(delta)
	_process_swap()


func _process_movement() -> void:
	crab.move(movement_input())


func movement_input() -> Vector2:
	var input: Vector2
	input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return input.normalized()


func _on_crab_die() -> void:
	_disassociate()


func _disassociate() -> void:
	unset_crab()
	on_disassociate.emit()
	PlayerInputManager.set_controller(_switcher_controller)


func _on_crab_reproduce(_parent: Crab, _child: Crab) -> void:
	pass


func _process_swap() -> void:
	if Input.is_action_just_pressed("swap"):
		_disassociate()


func set_crab(new_crab: Crab) -> void:
	if crab != null: unset_crab()
	crab = new_crab
	_attach_crab_signals(crab)
	crab.ai.enabled = false


func unset_crab() -> void:
	if crab == null: return
	crab.ai.enabled = true
	_detach_crab_signals(crab)


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


func _attach_crab_signals(new_crab: Crab) -> void:
	new_crab.on_death.connect(_on_crab_die)
	new_crab.on_reproduce.connect(_on_crab_reproduce)
	

func _detach_crab_signals(old_crab: Crab) -> void:
	old_crab.on_death.disconnect(_on_crab_die)
	old_crab.on_reproduce.disconnect(_on_crab_reproduce)
	
