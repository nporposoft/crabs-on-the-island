class_name State

extends Object

var _state: int


func has(state) -> bool:
	var mask: int = 1 << state
	return _state & mask


func has_any(states: Array) -> bool:
	for state in states:
		if has(state): return true
	return false


func has_all(states: Array) -> bool:
	for state in states:
		if !has(state): return false
	return true


func add(state) -> void:
	var mask: int = 1 << state
	_state = _state | mask


func add_all(states: Array) -> void:
	for state in states:
		add(state)


func remove(state) -> void:
	var mask: int = 1 << state
	_state = _state & ~mask


func remove_all(states: Array) -> void:
	for state in states:
		remove(state)


func clear() -> void:
	_state = 0
