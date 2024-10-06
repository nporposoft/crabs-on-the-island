extends Node

@export var _vision_distance: float = 500.0

var _sm: MultiStateMachine
var _vision_area: Area2D


func _ready() -> void:
	var _vision_area_shape: CollisionShape2D = CollisionShape2D.new()
	var _vision_area_sphere: CircleShape2D = CircleShape2D.new()
	_vision_area_sphere.radius = _vision_distance
	_vision_area_shape.shape = _vision_area_sphere


func _process(_delta: float) -> void:
	var nearbyResources: Array
	# for each resource
		# if resource is needed
			# if within reach
				# harvest and end
			# else
				# move toward and end
	
	# wander
