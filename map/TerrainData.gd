class_name TerrainData

enum HarvestType {
	NONE,
	SAND,
	WATER
}

enum SoundType {
	NONE,
	GRASS,
	WATER,
	ROCK
}

var harvest_type: HarvestType
var sound_type: SoundType
var position: Vector2


static func harvest_type_from_string(type: String) -> HarvestType:
	match type:
		"sand": return HarvestType.SAND
		"water": return HarvestType.WATER
		_: return HarvestType.NONE


static func harvest_type_to_string(type: HarvestType) -> String:
	match type:
		HarvestType.SAND: return "sand"
		HarvestType.WATER: return "water"
		_: return "none"
