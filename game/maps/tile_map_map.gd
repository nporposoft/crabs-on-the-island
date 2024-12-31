# A Map that encapsulates a TileMapLayer (the name TileMap is taken)
class_name TileMapMap

extends TileMapLayer


@export var background_color: Color = Color.DEEP_PINK

# we're assuming that tiles are all the same size
@onready var cell_size: Vector2 = tile_set.tile_size

@onready var water_collider: PackedScene = preload("res://game/resources/water_collider.tscn")
@onready var sand_collider: PackedScene = preload("res://game/resources/sand_collider.tscn")


const background_size: int = 1000000
const background_rect: Rect2 = Rect2(-background_size / 2.0, -background_size / 2.0, background_size, background_size)


func _ready() -> void:
	_create_resource_colliders()


func _draw() -> void:
	# draw an arbitrarily large rectangle behind the map to hide the edges
	draw_rect(background_rect, background_color)


func _create_resource_colliders() -> void:
	for cell: Vector2i in get_used_cells():
		_create_collider_for_cell(cell)


func _create_collider_for_cell(cell: Vector2i) -> void:
	var tile_data: TileData = get_cell_tile_data(cell)
	var harvest_type: String = tile_data.get_custom_data("harvest_type")
	if harvest_type == "": return
	
	var real_position: Vector2 = map_to_local(cell)
	var collider: Node2D = _create_collider(harvest_type, real_position, cell_size)
	add_child(collider)


func _create_collider(harvest_type: String, collider_position: Vector2, size: Vector2) -> Area2D:
	var scene: PackedScene
	match harvest_type:
		"sand": scene = sand_collider
		"water": scene = water_collider
	
	var collider: MapResource = scene.instantiate()
	collider.position = collider_position
	collider.set_size(size)
	return collider
