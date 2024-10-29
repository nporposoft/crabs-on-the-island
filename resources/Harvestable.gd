class_name Harvestable

extends Object

enum HarvestableType {
	SAND,
	WATER,
	MORSEL
}

var position: Vector2
var type: HarvestableType

# only used when the Harvestable is a Morsel, otherwise null
var morsel: Morsel


static func from_morsel(morsel: Morsel) -> Harvestable:
	var harvestable: Harvestable
	harvestable.type = Harvestable.HarvestableType.MORSEL
	harvestable.position = morsel.position
	harvestable.morsel = morsel
	return harvestable


static func from_terrain(terrain_data: TerrainData) -> Harvestable:
	var harvestable: Harvestable
	harvestable.position = terrain_data.position
	match terrain_data.HarvestType:
		TerrainData.HarvestType.SAND:
			harvestable.type = HarvestableType.SAND
		TerrainData.HarvestType.WATER:
			harvestable.type = HarvestableType.WATER
	return harvestable
