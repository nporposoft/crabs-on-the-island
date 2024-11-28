class_name Detector

extends Area2D


@onready var crab_self: Crab = get_parent()


func get_resources() -> ResourceCollection:
	var bodies: Array[Node2D] = get_overlapping_bodies().filter(_filter_self)
	bodies.sort_custom(_sort_distance)
	var areas: Array[Area2D] = get_overlapping_areas()
	areas.sort_custom(_sort_distance)
	return ResourceCollection.new(bodies, areas)


func _sort_distance(a: Node2D, b: Node2D) -> bool:
	var distance_to_a: float = position.distance_to(a.position)
	var distance_to_b: float = position.distance_to(b.position)
	return distance_to_a < distance_to_b


func _filter_self(node: Node2D) -> bool:
	return node != crab_self
	
