extends Node

@export var _vision_distance: float = 2500.0

var _sm: MultiStateMachine
var _vision_area: Area2D

enum States {
	HARVESTING = 1,
	WANDERING = 2
}

func _ready() -> void:
	_create_vision_area()

func _process(delta: float) -> void:
	_vision_area.position = $Crab.position
	
	var visibleMorsels: Array = _find_visible_morsels_by_distance()
	for morsel: Morsel in visibleMorsels:
		if !_want_morsel(morsel): continue
		
		if $Crab.can_reach_morsel(morsel):
			$Crab.harvest_morsel(delta, morsel)
		else:
			_move_toward_morsel(morsel)
		return
	
	$Crab.stop_harvest()
	
	# wander


func _move_toward_morsel(morsel: Morsel) -> void:
	var direction: Vector2 = morsel.position - $Crab.position
	$Crab.move(direction)


func _want_morsel(morsel: Morsel) -> bool:
	match morsel.mat_type:
		Morsel.MATERIAL_TYPE.IRON:
			return _want_iron()
		Morsel.MATERIAL_TYPE.COBALT:
			return _want_cobalt()
		Morsel.MATERIAL_TYPE.SILICON:
			return _want_silica()
		_:
			return false


func _want_iron() -> bool:
	return $Crab._carried_resources.iron < $Crab.ironTarget


func _want_cobalt() -> bool:
	return false


func _want_water() -> bool:
	return false


func _want_silica() -> bool:
	return false


func _find_visible_morsels() -> Array:
	return (_vision_area.get_overlapping_bodies()
		.map(func(body) -> Morsel: return body as Morsel)
		.filter(func(body) -> bool: return body != null)
	)


func _find_visible_morsels_by_distance() -> Array:
	var visible_morsels: Array = _find_visible_morsels()
	visible_morsels.sort_custom(func(a, b) -> bool:
		var a_distance: float = (a.position - $Crab.position).length()
		var b_distance: float = (b.position - $Crab.position).length()
		return a_distance < b_distance
	)
	return visible_morsels


func _create_vision_area() -> void:
	var _vision_area_shape: CollisionShape2D = CollisionShape2D.new()
	
	var _vision_area_sphere: CircleShape2D = CircleShape2D.new()
	_vision_area_sphere.radius = _vision_distance
	
	_vision_area_shape.shape = _vision_area_sphere
	
	_vision_area = Area2D.new()
	_vision_area.add_child(_vision_area_shape)
	add_child(_vision_area)
