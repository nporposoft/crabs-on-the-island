extends Label

var _crab: Crab
@export var _enabled: bool

func _ready() -> void:
	_crab = get_parent()
	
func _process(_delta: float) -> void:
	if !_enabled:
		return
	
	text = str(_crab._carried_resources.battery_energy)
