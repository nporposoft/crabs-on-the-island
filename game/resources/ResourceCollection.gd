class_name ResourceCollection

extends Object

var _bodies_cache: Array[Node2D]
var _areas_cache: Array[Area2D]

func _init(bodies: Array[Node2D], areas: Array[Area2D]) -> void:
	_bodies_cache = bodies
	_areas_cache = areas


func crabs() -> Array[Crab]:
	var all_crabs: Array[Crab]
	for body in _bodies():
		var crab: Crab = body as Crab
		if crab != null: all_crabs.push_back(crab)
	
	return all_crabs


func nearest_crab() -> Crab:
	var all_crabs: Array[Crab] = crabs()
	if all_crabs.size() == 0: return null
	return all_crabs[0]


func morsels() -> Array[Morsel]:
	var all_morsels: Array[Morsel]
	for body in _bodies():
		var morsel: Morsel = body as Morsel
		if morsel != null: all_morsels.push_back(morsel)
	
	return all_morsels


func nearest_morsel() -> Morsel:
	var all_morsels: Array[Morsel] = morsels()
	if all_morsels.size() == 0: return null
	return all_morsels[0]


func water() -> Array[Water]:
	var all_water: Array[Water]
	for area in _areas_cache:
		var area_as_water: Water = area as Water
		if area_as_water != null: all_water.push_back(area_as_water)
	
	return all_water


func nearest_water() -> Water:
	var all_water: Array[Water] = water()
	if all_water.size() == 0: return null
	return all_water[0]


func sand() -> Array[Sand]:
	var all_sand: Array[Sand]
	for area in _areas_cache:
		var area_as_sand: Sand = area as Sand
		if area_as_sand != null: all_sand.push_back(area_as_sand)
	
	return all_sand


func nearest_sand() -> Sand:
	var all_sand: Array[Sand] = sand()
	if all_sand.size() == 0: return null
	return all_sand[0]


func _bodies() -> Array:
	var all_bodies: Array[Node2D]
	for body in _bodies_cache:
		if is_instance_valid(body): all_bodies.push_back(body)
	_bodies_cache = all_bodies
	return _bodies_cache


func _filter_valid(node: Node) -> bool:
	return is_instance_valid(node)
