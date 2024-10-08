class_name Player

extends Node


const player_color = Color(1.0, 0.0, 0.0)

@onready var island = $"../.."
var crab_ai_scene: PackedScene = preload("res://crabs/AI/CrabAI.tscn")

signal disassociation_changed
signal crab_swapped
signal defeat
signal victory

@export var game_running = true
@export var is_disassociating: bool = false
@export var _crab: Crab
var crabFamily: Array = []
var crabIndex: int = 0
var familySize: int = 1
var _inputMovement: Vector2


func _ready():
	_crab = get_parent()
	_crab.isPlayerFamily = true
	_crab.set_color(player_color)


func _process(delta: float) -> void:
	if game_running:
		_process_swap()
		if !is_disassociating:
			_process_movement()
			_process_dash()
			_process_harvest(delta)
			_process_pickup()
			_process_reproduction(delta)
	else:
		pass #TODO: implement maybe a restart button or something to press...


func _process_swap() -> void:
	if is_disassociating or _crab == null:
		_get_new_crab()
	if Input.is_action_just_pressed("swap"):
		if is_disassociating:
			is_disassociating = false
			disassociation_changed.emit()
			#print("No longer disassociating!")
		else:
			is_disassociating = true
			disassociation_changed.emit()
			#print("I'm disassociating!")
			crab_swapped.emit()

func _get_new_crab() -> void:
	_refresh_family()
	if game_running:
		_crab = crabFamily[crabIndex]
		if _crab.get_node("CrabAI") != null:
			_crab.get_node("CrabAI").queue_free()
			_crab.add_child(self)
			crab_swapped.emit()
		var LR = 0
		if Input.is_action_just_pressed("move_left"): LR = -1
		elif Input.is_action_just_pressed("move_right"): LR = 1
		if LR != 0:
			var new_crab_ai: CrabAI = crab_ai_scene.instantiate()
			_crab.add_child(new_crab_ai)
			_crab.remove_child(self)
			crabIndex = ((crabIndex + LR) as int) % crabFamily.size()
			_crab = crabFamily[crabIndex]
			_crab.get_node("CrabAI").queue_free()
			_crab.add_child(self)
			crab_swapped.emit()

func _refresh_family() -> void:
	#print("refreshing family...")
	crabFamily.clear()
	var allCrabs = get_all_crabs()
	for crab: Crab in allCrabs:
		if crab.isPlayerFamily and !crabFamily.has(crab):
			crabFamily.append(crab)
	familySize = crabFamily.size()
	#print(str(familySize) + " crabs in family")
	if familySize == 0:
		_lose_condition()
	elif allCrabs.size() == familySize:
		_win_condition()
	else:
		crabIndex = crabIndex % familySize

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
	return #TODO: implement pickup
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


func _lose_condition() -> void:
		game_running = false
		defeat.emit()
		print("game over! you lose!")


func _win_condition() -> void:
		game_running = false
		victory.emit()
		print("game over! you win!")
