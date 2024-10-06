class_name IslandV1

extends Node2D

var SandArea: Area2D
var WaterArea: Area2D


func _ready() -> void:
	SandArea = $sandArea
	WaterArea = $waterArea
