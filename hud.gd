extends CanvasLayer


@export var _player : Player
@onready var _crab = _player.get_child(1)
@onready var energyBar = $energy_bar
@onready var waterBar = $water_bar
@onready var siliconBar = $silicon_bar
@onready var ironBar = $iron_bar
@onready var sundial = $sundial
@onready var dayLabel = $day_label


func _new_day():
	dayLabel.text = "Day " + str(WorldClock.day_count)

func _on_crab_battery_charge_changed():
	energyBar.value = 100.0 * _crab._carried_resources.battery_energy / _crab._stats.battery_capacity

# Called when the node enters the scene tree for the first time.
func _ready():
	dayLabel.text = "Day " + str(WorldClock.day_count)
	WorldClock.new_day_rollover.connect(_new_day)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	waterBar.value = 100.0 * _crab._carried_resources.water / 100.0 #TODO: set US water_bar maximum to crab target water maximum
	siliconBar.value = 100.0 * _crab._carried_resources.silicon / 100.0 #TODO: set US silicon_bar maximum to crab target silicon maximum
	ironBar.value = 100.0 * _crab._carried_resources.iron / 100.0 #TODO: set US iron_bar maximum to crab target iron maximum
	sundial.set_rotation(2.0 * PI * WorldClock.time)
