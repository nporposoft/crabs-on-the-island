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

func _process(_delta: float) -> void:
	if !Debug.enabled:
		text = ""
		return
	
	if Input.is_action_just_pressed("toggle_debug_stat"):
		_current_stat_index = (_current_stat_index + 1) % _available_properties.size()
	
	var stat: Array = _available_properties[_current_stat_index]
	var value: String = str(_crab[stat[0]][stat[1]])
	text = stat[0] + "." + stat[1] + ": " + value
