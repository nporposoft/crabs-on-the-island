extends Label

var _ai: CrabAI

func _ready() -> void:
	_ai = get_parent()

func _process(_delta: float) -> void:
	if !Debug.enabled:
		text = ""
		return

	var msg: String
	for state: CrabAI.States in CrabAI.States.values():
		if _ai._sm.has_state(state):
			msg += CrabAI.States.keys()[state] + "\n"
	
	text = msg
