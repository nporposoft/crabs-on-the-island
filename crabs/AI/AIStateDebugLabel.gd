extends Label

var _ai: CrabAI

func _ready() -> void:
	_ai = get_parent()

func _process(_delta: float) -> void:
	if !DebugMode.enabled:
		text = ""
		return

	var msg: String = ""
	for state: CrabAI.States in CrabAI.States.values():
		var has_state: bool = _ai._sm.has_state(state)
		if has_state:
			var state_name: String = CrabAI.States.keys()[state]
			msg += state_name + "\n"
	
	text = msg
	var _crab_position: Vector2 = _ai._crab.position
	position = Vector2(_crab_position.x + 43, _crab_position.y + 40)
