extends Label

var _crab: Crab

func _ready() -> void:
	_crab = get_parent()

func _process(_delta: float) -> void:
	if !DebugMode.enabled:
		text = ""
		return

	var msg: String = ""
	for state: Crab.States in Crab.States.values():
		if _crab._sm.has_state(state):
			msg += Crab.States.keys()[state] + "\n"
	
	text = msg
