class_name Detector

extends Area2D


@onready var crab_self: Crab = get_parent()


func morsels() -> Array[Morsel]:
	var morsels: Array[Morsel] = []
	for node: Node2D in get_overlapping_bodies():
		var morsel: Morsel = node as Morsel
		if morsel != null:
			morsels.push_back(morsel)
	return morsels


func nearest_morsel() -> Morsel:
	var morsels: Array[Morsel] = morsels()
	morsels.sort_custom(_sort_distance)
	if morsels.size() == 0: return null
	return morsels[0]


func has_morsel(morsel: Morsel) -> bool:
	return get_overlapping_bodies().has(morsel)


func crabs() -> Array[Crab]:
	var crabs: Array[Crab] = []
	for node: Node2D in get_overlapping_bodies():
		var crab: Crab = node as Crab
		if crab != null && crab != crab_self:
			crabs.push_back(crab)
	
	return crabs


func nearest_crab() -> Crab:
	var crabs: Array[Crab] = crabs()
	crabs.sort_custom(_sort_distance)
	if crabs.size() == 0: return null
	return crabs[0]


func has_crab(crab: Crab) -> bool:
	return get_overlapping_bodies().has(crab)


func water() -> Array[WaterCollider]:
	var waters: Array[WaterCollider] = []
	for area: Area2D in get_overlapping_areas():
		var water: WaterCollider = area as WaterCollider
		if water != null:
			waters.push_back(water)
	
	return waters


func nearest_water() -> WaterCollider:
	var water: Array[WaterCollider] = water()
	water.sort_custom(_sort_distance)
	if water.size() == 0: return null
	return water[0]


func has_water(water: WaterCollider) -> bool:
	return get_overlapping_areas().has(water)


func sand() -> Array[SandCollider]:
	var sands: Array[SandCollider] = []
	for area: Area2D in get_overlapping_areas():
		var sand: SandCollider = area as SandCollider
		if sand != null:
			sands.push_back(sand)
	
	return sands


func nearest_sand() -> SandCollider:
	var sand: Array[SandCollider] = sand()
	sand.sort_custom(_sort_distance)
	if sand.size() == 0: return null
	return sand[0]


func has_sand(sand: SandCollider) -> bool:
	return get_overlapping_areas().has(sand)


func _sort_distance(a: Node2D, b: Node2D) -> bool:
	var distance_to_a: float = position.distance_to(a.position)
	var distance_to_b: float = position.distance_to(b.position)
	return distance_to_a < distance_to_b
