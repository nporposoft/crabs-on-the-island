class_name Util

extends Node

enum Directions { UP, UP_LEFT, LEFT, DOWN_LEFT, DOWN, DOWN_RIGHT, RIGHT, UP_RIGHT }
const LeftDirections = [Directions.LEFT, Directions.UP_LEFT, Directions.DOWN_LEFT]
const RightDirections = [Directions.RIGHT, Directions.UP_RIGHT, Directions.DOWN_RIGHT]

static func one_shot_timer(object: Node, duration: float, callback: Callable) -> void:
	var timer: Timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func() -> void:
		callback.call()
		object.remove_child(timer)
		timer.queue_free()
	)
	object.add_child(timer)
	timer.start()


static func random_direction() -> Vector2:
	return Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()


static func get_direction_from_vector(vector: Vector2) -> Directions:
	if vector.x > 0 && vector.y < 0:
		return Directions.UP_RIGHT
	if vector.x > 0 && vector.y > 0:
		return Directions.DOWN_RIGHT
	if vector.x < 0 && vector.y < 0:
		return Directions.UP_LEFT
	if vector.x < 0 && vector.y > 0:
		return Directions.DOWN_LEFT
	if vector.y < 0:
		return Directions.UP
	if vector.y > 0:
		return Directions.DOWN
	if vector.x < 0:
		return Directions.LEFT
	# default to right
	return Directions.RIGHT


static func get_vector_from_direction(direction: Directions) -> Vector2:
	# default to right
	var vector: Vector2 = Vector2.RIGHT
	match direction:
		Directions.UP:
			vector = Vector2.UP
		Directions.UP_LEFT:
			vector = Vector2.UP + Vector2.LEFT
		Directions.LEFT:
			vector = Vector2.LEFT
		Directions.DOWN_LEFT:
			vector = Vector2.DOWN + Vector2.LEFT
		Directions.DOWN:
			vector = Vector2.DOWN
		Directions.DOWN_RIGHT:
			vector = Vector2.DOWN + Vector2.RIGHT
		Directions.UP_RIGHT:
			vector = Vector2.UP + Vector2.RIGHT
	return vector.normalized()


static func require_child(parent: Node, type) -> Node:
	var node = (parent.get_children()
	.filter(func(child: Node) -> bool: 
		return is_instance_of(child, type)
	).pop_front())
	if node == null:
		push_error("Required child not found")
	return node
