class_name ResourceCollection
extends Object

var _resources: Array
var _resource_by_distance_cache: Array
var _resource_by_distance_cached: bool

func _init(resources: Array) -> void:
	_resources = resources


func all() -> Array:
	return _resources

## Sorting by distance is really expensive and should be done only if absolutely necessary
## @deprecated
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
	return all().filter(func(resource) -> bool:
		return is_instance_valid(resource) and resource is Crab
	)

## Sorting by distance is really expensive and should be done only if absolutely necessary
## @deprecated
func crabs_by_distance(position: Vector2) -> Array:
	return by_distance(position).filter(func(resource) -> bool:
		return is_instance_valid(resource) and resource is Crab
	)


func nearest_crab(position: Vector2) -> Crab:
	return _get_nearest(crabs(), position) as Crab


func morsels() -> Array:
	return all().filter(func(resource) -> bool:
		return is_instance_valid(resource) and resource is Morsel
	)

## Sorting by distance is really expensive and should be done only if absolutely necessary
## @deprecated
func morsels_by_distance(position: Vector2) -> Array:
	return by_distance(position).filter(func(resource) -> bool:
		return is_instance_valid(resource) and resource is Morsel
	)


func nearest_morsel(position: Vector2) -> Morsel:
	return _get_nearest(morsels(), position) as Morsel


func water() -> Array:
	return all().filter(func(resource) -> bool:
		return is_instance_valid(resource) and resource is Water
	)

## Sorting by distance is really expensive and should be done only if absolutely necessary
## @deprecated
func water_by_distance(position: Vector2) -> Array:
	return by_distance(position).filter(func(resource) -> bool:
		return is_instance_valid(resource) and resource is Water
	)


func nearest_water(position: Vector2) -> Water:
	return _get_nearest(water(), position) as Water


func sand() -> Array:
	return all().filter(func(resource) -> bool:
		return is_instance_valid(resource) and resource is Sand
	)

## Sorting by distance is really expensive and should be done only if absolutely necessary
## @deprecated
func sand_by_distance(position: Vector2) -> Array:
	return by_distance(position).filter(func(resource) -> bool:
		return is_instance_valid(resource) and resource is Sand
	)


func nearest_sand(position: Vector2) -> Sand:
	return _get_nearest(sand(), position) as Sand


func _sort_by_distance(objects: Array, position: Vector2) -> Array:
	var valid_objects: Array = objects.filter(is_instance_valid)

	# Pre-calculate distances to all objects ( O(n) ) instead of doing it for each sort
	# comparison ( O(n log n) )
	# TODO: we're looping through the objects like 3 additional times here, that can be optimized
	var objects_with_distances: Array = valid_objects.map(func(object) -> Dictionary:
		var distance: float = position.distance_to(object.position)
		return {
			"object": object,
			"distance": distance
		}
	)
	objects_with_distances.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["distance"] < b["distance"]
	)

	# map the sorted object/distance pairs back to just the objects
	var sorted_objects: Array = objects_with_distances.map(func(object) -> Node2D:
		return object["object"]
	)

	return sorted_objects


func _get_nearest(objects: Array, position: Vector2) -> Node2D:
	var nearest_object: Node2D
	var nearest_distance: float = float(INF)
	for object in objects:
		var distance: float = position.distance_to(object.position)
		if distance < nearest_distance:
			nearest_object = object
			nearest_distance = distance
	return nearest_object
