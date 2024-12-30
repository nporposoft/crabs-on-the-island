class_name Detector

extends Area2D


@onready var crab_self: Crab = get_parent()


func get_resources() -> ResourceCollection:
	var bodies: Array[Node2D] = get_overlapping_bodies().filter(_filter_self)
	var areas: Array[Area2D] = get_overlapping_areas()
	return ResourceCollection.new(bodies + areas)


func _filter_self(node: Node2D) -> bool:
	return node != crab_self
	
