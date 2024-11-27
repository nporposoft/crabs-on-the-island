class_name Util

extends Node


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


static func require_child(parent: Node, type) -> Node:
	var node = (parent.get_children()
	.filter(func(child: Node) -> bool: 
		return is_instance_of(child, type)
	).pop_front())
	if node == null:
		push_error("Required child not found")
	return node
