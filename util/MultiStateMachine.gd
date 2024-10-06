class_name MultiStateMachine

extends Object

var _state: int


func has_state(state) -> bool:
	var mask: int = 1 << state
	return _state & mask


func has_any_state(states: Array) -> bool:
	for state in states:
		if has_state(state): return true
	return false


func has_all_states(states: Array) -> bool:
	for state in states:
		if !has_state(state): return false
	return true


func set_state(state) -> void:
	var mask: int = 1 << state
	_state = _state | mask


func set_states(states: Array) -> void:
	for state in states:
		set_state(state)


func unset_state(state) -> void:
	var mask: int = 1 << state
	_state = _state & ~mask


func unset_states(states: Array) -> void:
	for state in states:
		unset_state(state)


func unset_all_states() -> void:
	_state = 0
