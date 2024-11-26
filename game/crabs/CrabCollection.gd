class_name CrabCollection

extends Object

var crabs: Array[Crab]


func _init(crabs: Array[Crab]) -> void:
	self.crabs = crabs


func living() -> CrabCollection:
	var living_crabs: Array[Crab] = (crabs.filter(func(crab: Crab) -> bool:
		return !crab.is_dead()
	))
	return CrabCollection.new(living_crabs)


func of_family(family: Crab.Family) -> CrabCollection:
	var family_crabs: Array[Crab] = (crabs.filter(func(crab: Crab) -> bool:
		return crab.family == family
	))
	return CrabCollection.new(family_crabs)


func size() -> int:
	return crabs.size()
