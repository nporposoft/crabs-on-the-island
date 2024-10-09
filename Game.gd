class_name Game

extends Node


func get_map() -> Node:
	return $IslandV1


func get_player_spawn_position() -> Vector2:
	return $IslandV1.get_player_spawn_point().position


func _ready() -> void:	
	_spawn_player_crab()
	$hud.init($Player)
	$Camera.init($Player)


func _spawn_player_crab() -> void:
	var crab: Crab = get_map().create_new_crab()
	crab.init({}, {}, $Player.color, Crab.Family.PLAYER)
	crab.position = get_player_spawn_position()
	$Player.set_crab(crab)
	
