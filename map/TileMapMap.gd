# A Map that encapsulates a TileMapLayer (the name TileMap is taken)
class_name TileMapMap

extends Map


func get_terrain_at_point(point: Vector2) -> TerrainData:
	var cell: Vector2             = $tileIsland.local_to_map(point)
	var cell_data                 = $tileIsland.get_cell_tile_data(cell)
	var terrain_data: TerrainData = TerrainData.new()
	terrain_data.harvest_type = TerrainData.harvest_type_from_string(cell_data.get_custom_data(harvestTypeKey))
	#terrain_data.sound_type = cell_data.get_custom_data(soundTypeKey)
	return terrain_data


func get_terrain_in_radius(point: Vector2, radius: float) -> Array[TerrainData]:
	var center_on_map: Vector2i = $tileIsland.world_to_map(point)
	var tileset: TileSet = $tileIsland.tile_set
	var tile_size: int = $tileIsland.cell_size
	
	return []
