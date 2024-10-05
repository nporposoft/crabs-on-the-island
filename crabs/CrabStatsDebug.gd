extends Label

var _crab: Crab

var _available_properties: Array
var _current_stat_index: int

func _ready() -> void:
	_crab = get_parent()
	for property in _crab._carried_resources.keys():
		_available_properties.push_back(["_carried_resources",property])
	for property in _crab._stats.keys():
		_available_properties.push_back(["_stats",property])
	_available_properties.push_back(["_state"])
	_available_properties.push_back(["_direction"])

func _process(_delta: float) -> void:
	if !Debug.enabled:
		text = ""
		return
	
	if Input.is_action_just_pressed("toggle_debug_stat"):
		_current_stat_index = (_current_stat_index + 1) % _available_properties.size()
	
	var stat: Array = _available_properties[_current_stat_index]
	var value = _get_stat(stat)
	text = value[0] + ": " + value[1]

# Returns array of [name, value]
func _get_stat(path: Array) -> Array:
	var stat_value: String
	var stat_name: String
	
	if path.size() == 1:
		stat_name = path[0]
		stat_value = str(_crab[path[0]])
	else:
		stat_name = path[0] + "." + path[1]
		stat_value = str(_crab[path[0]][path[1]])
		
	return [stat_name, stat_value]
