class_name SceneManager

extends Node


@export var starting_scene: PackedScene


var current_scene: Node

func _ready() -> void:
	_init_scene(starting_scene)


func _init_scene(scene: PackedScene) -> void:
	var instance: Node = scene.instantiate()
	current_scene = instance
	add_child(instance)
