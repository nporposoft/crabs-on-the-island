class_name CrabCollection

extends Object

var _crabs: Array[Crab]


func _init(crabs: Array[Crab]) -> void:
	_crabs = crabs


func to_a() -> Array[Crab]:
	return _crabs


func living() -> CrabCollection:
	var living_crabs: Array[Crab] = (_crabs.filter(func(crab: Crab) -> bool:
		return !crab.is_dead()
	))
	return CrabCollection.new(living_crabs)


func of_family(family: Crab.Family) -> CrabCollection:
	var family_crabs: Array[Crab] = (_crabs.filter(func(crab: Crab) -> bool:
		return crab._family == family
	))
	return CrabCollection.new(family_crabs)


func size() -> int:
	return _crabs.size()
