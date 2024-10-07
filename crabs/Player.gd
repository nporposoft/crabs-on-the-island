class_name Player

extends Node

const player_color = Color(1.0, 0.0, 0.0)

@onready var island = $"../.."

var disassociated: bool = false
var familyCrabs: Array = []
var crabIndex: int = 0
var _crab: Crab
var _inputMovement: Vector2


func _ready():
	_crab = get_parent()
	_crab.isPlayerFamily = true
	_crab.set_color(player_color)


func _process(delta: float) -> void:
	if disassociated:
		_process_swap()
	_process_movement()
	_process_dash()
	_process_harvest(delta)
	_process_pickup()
	_process_reproduction(delta)


func _process_swap() -> void:
	if Input.is_action_just_pressed("swap"):
		print("unswapping!")
		disassociated = false
		return
	for crab: Crab in get_all_crabs():
		if crab.isPlayerFamily and !familyCrabs.has(crab):
			familyCrabs.append(crab)
	_crab = familyCrabs[crabIndex]
	
		#var distance: float = (morsel.position - position).length()
		#if distance < nearest_distance:
			#nearest = morsel
			#nearest_distance = distance
	#return nearest


func get_all_crabs() -> Array:
	return (island.get_children()
		.map(func(child) -> Crab: return child as Crab)
		.filter(func(child) -> bool: return child != null)
	)


func _process_dash() -> void:
	if Input.is_action_just_pressed("dash"):
		_crab.dash()


func _process_movement() -> void:
	_inputMovement.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	_inputMovement.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	

func _physics_process(delta: float) -> void:
	_crab.move(_inputMovement)


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
