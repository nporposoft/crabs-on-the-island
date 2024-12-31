extends Label

var _crab: Crab
var _ai_ref: CrabAI

var _target: Vector2
var _target_line: Line2D


func _ready() -> void:
	_crab = get_parent()
	_target_line = Line2D.new()
	_crab.add_child.call_deferred(_target_line)


func _process(_delta: float) -> void:
	text = ""
	_target_line.visible = false
	if !DebugMode.enabled: return
	
	_print_position()
	_print_states()
	if _ai().enabled:
		text += "AI_ENABLED\n"
		_print_ai_state()
		_draw_ai_target_line()


func _print_position() -> void:
	text += str(_crab.position) + "\n"


func _print_states() -> void:
	for state: Crab.States in Crab.States.values():
		if _crab.state.has(state): text += Crab.States.keys()[state] + "\n"


func _print_ai_state() -> void:
	text += CrabAI.States.keys()[_crab.ai._state] + "\n"


func _draw_ai_target_line() -> void:
	if _target == Vector2.ZERO:
		_target_line.visible = false
		return
	
	_target_line.visible = true
	_target_line.width = 3.0
	_target_line.default_color = Color.RED
	_target_line.clear_points()
	_target_line.add_point(Vector2.ZERO)
	_target_line.add_point(_target - _crab.position)


func _ai() -> CrabAI:
	if _ai_ref != null: return _ai_ref
	
	_ai_ref = _crab.ai
	_ai_ref.on_target.connect(func(target: Vector2) -> void: _target = target)
	return _ai_ref
