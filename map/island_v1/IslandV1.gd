class_name IslandV1

extends Node2D

@onready var SandArea: Area2D = $sandArea
@onready var WaterArea: Area2D = $waterArea
var _crab_scene = preload("res://crabs/Crab.tscn")

var tutorial_swap: bool = false


func get_player_spawn_point() -> Node2D:
	return $PlayerSpawnPoint


func create_new_crab() -> Crab:
	var new_crab: Crab = _crab_scene.instantiate()
	add_child(new_crab)
	return new_crab
