extends CanvasLayer


@export var _player : Player
@onready var _crab = _player.get_child(1)
@onready var energyBar = $energy_bar
@onready var waterBar = $water_bar
@onready var siliconBar = $silicon_bar
@onready var ironBar = $iron_bar
@onready var sundial = $sundial

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	energyBar.value = 100.0 * _crab._carried_resources.battery_energy / _crab._stats.battery_capacity
	waterBar.value = 100.0 * _crab._carried_resources.water / 100.0
	siliconBar.value = 100.0 * _crab._carried_resources.silicon / 100.0
	ironBar.value = 100.0 * _crab._carried_resources.iron / 100.0
	sundial.set_rotation(2.0 * PI * WorldClock.time)
