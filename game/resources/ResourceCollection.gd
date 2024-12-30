class_name ResourceCollection
extends Object

var _resources: Array
var _resource_by_distance_cache: Array
var _resource_by_distance_cached: bool

func _init(resources: Array) -> void:
	_resources = resources


func all() -> Array:
	return _resources


func by_distance(position: Vector2) -> Array:
	if not _resource_by_distance_cached:
		_resource_by_distance_cache = _sort_by_distance(all(), position)
		_resource_by_distance_cached = true
	return _resource_by_distance_cache


func nearest_resource(position: Vector2) -> Node2D:
	var resources: Array = by_distance(position)
	if resources.size() == 0: return null
	return resources[0]


func crabs() -> Array:
	return all().filter(func(resource: Node2D) -> bool:
		return is_instance_valid(resource) and resource is Crab
	)


# E 0:01:39:0923   ResourceCollection.gd:36 @ crabs_by_distance(): Error calling method from 'filter': 'GDScript::<anonymous lambda>': Cannot convert argument 1 from Object to Object
#  <C++ Error>    Method/function failed. Returning: Array()
#  <C++ Source>   core/variant/array.cpp:514 @ filter()
#  <Stack Trace>  ResourceCollection.gd:36 @ crabs_by_distance()
#                 CrabAI.gd:131 @ _harvest_crab_routine()
#                 CrabAI.gd:51 @ _process()
func crabs_by_distance(position: Vector2) -> Array:
	return by_distance(position).filter(func(resource: Node2D) -> bool:
		return is_instance_valid(resource) and resource is Crab
	)


func nearest_crab(position: Vector2) -> Crab:
	var all_crabs: Array = crabs_by_distance(position)
	if all_crabs.size() == 0: return null
	return all_crabs[0]


func morsels() -> Array:
	return all().filter(func(resource: Node2D) -> bool:
		return is_instance_valid(resource) and resource is Morsel
	)


func morsels_by_distance(position: Vector2) -> Array:
	return by_distance(position).filter(func(resource: Node2D) -> bool:
		return is_instance_valid(resource) and resource is Morsel
	)


func nearest_morsel(position: Vector2) -> Morsel:
	var all_morsels: Array = morsels_by_distance(position)
	if all_morsels.size() == 0: return null
	return all_morsels[0]


func water() -> Array:
	return all().filter(func(resource: Node2D) -> bool:
		return is_instance_valid(resource) and resource is Water
	)


func water_by_distance(position: Vector2) -> Array:
	return by_distance(position).filter(func(resource: Node2D) -> bool:
		return is_instance_valid(resource) and resource is Water
	)


func nearest_water(position: Vector2) -> Water:
	var all_water: Array = water_by_distance(position)
	if all_water.size() == 0: return null
	return all_water[0]


func sand() -> Array:
	return all().filter(func(resource: Node2D) -> bool:
		return is_instance_valid(resource) and resource is Sand
	)


func sand_by_distance(position: Vector2) -> Array:
	return by_distance(position).filter(func(resource: Node2D) -> bool:
		return is_instance_valid(resource) and resource is Sand
	)


func nearest_sand(position: Vector2) -> Sand:
	var all_sand: Array = sand_by_distance(position)
	if all_sand.size() == 0: return null
	return all_sand[0]


func _sort_by_distance(objects: Array, position: Vector2) -> Array:
	var valid_objects: Array = objects.filter(is_instance_valid)
	valid_objects.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		var distance_to_a: float = position.distance_to(a.position)
		var distance_to_b: float = position.distance_to(b.position)
		return distance_to_a < distance_to_b
	)
	return valid_objects