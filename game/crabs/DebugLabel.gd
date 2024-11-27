extends Label

var _crab: Crab

func _ready() -> void:
	_crab = get_parent()

func _process(_delta: float) -> void:
	if !DebugMode.enabled:
		text = ""
		return

	var msg: String = ""
	
	msg += str(_crab.position) + "\n"
	
	for state: Crab.States in Crab.States.values():
		if _crab.state.has(state):
			msg += Crab.States.keys()[state] + "\n"
	
	if _crab.ai.enabled:
		msg += "AI_ENABLED\n"
		for state: CrabAI.States in CrabAI.States.values():
			if _crab.ai._state.has(state):
				msg += CrabAI.States.keys()[state] + "\n"
	
	text = msg
