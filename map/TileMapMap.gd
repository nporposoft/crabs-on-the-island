# A Map that encapsulates a TileMapLayer (the name TileMap is taken)
class_name TileMapMap

extends Map

@onready var tilemap: TileMapLayer = $tileIsland2

func get_terrain_at_point(point: Vector2) -> TerrainData:
	var terrain_data: TerrainData = TerrainData.new()
	
	var cell: Vector2 = tilemap.local_to_map(to_local(point))
	var cell_data: TileData = tilemap.get_cell_tile_data(cell)
	if cell_data == null:
		push_warning("attempt to get cell data at ", cell, " for point ", point, " is out of map bounds")
		return terrain_data
	
	terrain_data.harvest_type = TerrainData.harvest_type_from_string(cell_data.get_custom_data(harvestTypeKey))
	terrain_data.position = tilemap.map_to_local(cell)
	return terrain_data


func get_terrain_in_radius(point: Vector2, radius: float) -> Array[TerrainData]:
	var center_on_map: Vector2i = tilemap.local_to_map(point)
	var tileset: TileSet = tilemap.tile_set
	var tile_size: int = tileset.tile_size.x
	
	return []
