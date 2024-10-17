class_name Game

extends Node

enum States {
	RUNNING,
	DEFEAT,
	VICTORY
}
var _state: States = States.RUNNING

func get_map() -> Node:
	return $IslandV1


func get_player_spawn_position() -> Vector2:
	return $IslandV1.get_player_spawn_point().position


func _ready() -> void:	
	_spawn_player_crab()
	$hud.init($Player)
	$Camera.init($Player)
	$IslandV1.victory.connect(func() -> void: _state = States.VICTORY)
	$IslandV1.defeat.connect(func() -> void: _state = States.DEFEAT)


func _spawn_player_crab() -> void:
	var crab: Crab = get_map().create_new_crab()
	crab.init({}, {}, $Player.color, false, Crab.Family.PLAYER)
	crab.position = get_player_spawn_position()
	$Player.set_crab(crab)


func _process(_delta: float) -> void:
	if _state == States.RUNNING: return
	if _state == States.VICTORY: $hud._trigger_victory()
	if _state == States.DEFEAT: $hud._trigger_defeat()
