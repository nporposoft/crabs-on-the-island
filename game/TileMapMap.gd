# A Map that encapsulates a TileMapLayer (the name TileMap is taken)
class_name TileMapMap

extends Map

@export var tilemap: TileMapLayer


func _ready() -> void:
	_create_resource_colliders()


func _create_resource_colliders() -> void:
	for cell: Vector2i in tilemap.get_used_cells():
		#_create_collider_for_cell(cell)
		#print(cell)
		pass


func _create_collider_for_cell(cell: Vector2i) -> void:
	var tile_data: TileData = tilemap.get_cell_tile_data(cell)
	var harvest_type: String = tile_data.get_custom_data("harvest_type")
	if harvest_type == "": return
