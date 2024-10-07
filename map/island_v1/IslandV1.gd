class_name IslandV1

extends Node2D

var SandArea: Area2D
var WaterArea: Area2D
var tutorial_swap: bool = false


func _ready() -> void:
	SandArea = $sandArea
	WaterArea = $waterArea
