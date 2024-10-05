extends Node

@onready var sprite = $Sprite2D
var chunkTXR := preload("res://assets/chunk.png")
var ingotTXR := preload("res://assets/ingot.png")

enum MATERIAL_TYPE {COBALT, IRON, SILICON}

@export var material = MATERIAL_TYPE.SILICON
@export var amount = 1000.0
@export var is_chunk = false


func _set_resource (_mat, _amount, _isChunk):
	material = _mat
	amount = _amount
	is_chunk = _isChunk
	
	if is_chunk:
		sprite.set_texture(chunkTXR)
	else:
		sprite.set_texture(ingotTXR)

func _extract (extractAmount) -> float:
	if extractAmount >= amount:
		queue_free()
		return amount
	else:
		amount -= extractAmount
		return extractAmount

# Called when the node enters the scene tree for the first time.
func _ready():
	_set_resource(material, amount, is_chunk)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
