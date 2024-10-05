class_name Player

extends Node

var _character: RigidBody2D

var dodgeCooldown = 0.0
var dodgeCooldownMax = 1.67
var lateralDodgeMult = 50.0
var canDodge = true


func _tickCooldowns(_delta) -> void:
	if dodgeCooldown > 0.0:
		dodgeCooldown -= _delta
		if dodgeCooldown <= 0.0:
			canDodge = true

func _ready() -> void:
	_character = $Crab

func _process(delta: float) -> void:
	var moveDir = Vector2(0.0, 0.0)
	if Input.is_action_pressed("move_up"):
		moveDir.y = -1.0
		if Input.is_action_pressed("dodge") and canDodge:
			if Input.is_action_pressed("move_left"):
				_character.apply_central_impulse(Vector2(-1.0, -1.0).normalized() * _character._stats.move_speed * lateralDodgeMult)
			elif Input.is_action_pressed("move_right"):
				_character.apply_central_impulse(Vector2(1.0, -1.0).normalized() * _character._stats.move_speed * lateralDodgeMult)
			else:
				_character.apply_central_impulse(Vector2(0.0, -1.0) * _character._stats.move_speed * lateralDodgeMult)
			dodgeCooldown = dodgeCooldownMax
			canDodge = false
	if Input.is_action_pressed("move_down"):
		moveDir.y = 1.0
		if Input.is_action_pressed("dodge") and canDodge:
			if Input.is_action_pressed("move_left"):
				_character.apply_central_impulse(Vector2(-1.0, 1.0).normalized() * _character._stats.move_speed * lateralDodgeMult)
			elif Input.is_action_pressed("move_right"):
				_character.apply_central_impulse(Vector2(1.0, 1.0).normalized() * _character._stats.move_speed * lateralDodgeMult)
			else:
				_character.apply_central_impulse(Vector2(0.0, 1.0) * _character._stats.move_speed * lateralDodgeMult)
			dodgeCooldown = dodgeCooldownMax
			canDodge = false
	if Input.is_action_pressed("move_left"):
		moveDir.x = -1.0
		if Input.is_action_pressed("dodge") and canDodge:
			if Input.is_action_pressed("move_up"):
				_character.apply_central_impulse(Vector2(-1.0, -1.0).normalized() * _character._stats.move_speed * lateralDodgeMult)
			elif Input.is_action_pressed("move_down"):
				_character.apply_central_impulse(Vector2(-1.0, 1.0).normalized() * _character._stats.move_speed * lateralDodgeMult)
			else:
				_character.apply_central_impulse(Vector2(-1.0, 0.0) * _character._stats.move_speed * lateralDodgeMult)
			dodgeCooldown = dodgeCooldownMax
			canDodge = false
	if Input.is_action_pressed("move_right"):
		moveDir.x = 1.0
		if Input.is_action_pressed("dodge") and canDodge:
			if Input.is_action_pressed("move_up"):
				_character.apply_central_impulse(Vector2(1.0, -1.0).normalized() * _character._stats.move_speed * lateralDodgeMult)
			elif Input.is_action_pressed("move_down"):
				_character.apply_central_impulse(Vector2(1.0, 1.0).normalized() * _character._stats.move_speed * lateralDodgeMult)
			else:
				_character.apply_central_impulse(Vector2(1.0, 0.0) * _character._stats.move_speed * lateralDodgeMult)
			dodgeCooldown = dodgeCooldownMax
			canDodge = false
	
	_character.apply_central_impulse(moveDir.normalized() * _character._stats.move_speed)
	
	$Camera2D.position = _character.position
	
	_tickCooldowns(delta)
