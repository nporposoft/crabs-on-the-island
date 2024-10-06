extends CanvasLayer


@export var _player : Player
@onready var _crab = _player.get_child(1)
@onready var energyBar = $energy_bar
@onready var waterBar = $water_bar
@onready var siliconBar = $silicon_bar
@onready var ironBar = $iron_bar
@onready var sundial = $sundial
@onready var dayLabel = $day_label

var cobalt_is_ready: bool = false
var iron_is_ready: bool = false
var silicon_is_ready: bool = false
var water_is_ready: bool = false
var ready_to_clone: bool = false


func _new_day():
	dayLabel.text = "Day " + str(WorldClock.day_count)

func _cobalt_light():
	cobalt_is_ready = true
	$cobalt_light.set_self_modulate(Color(1.0, 1.0, 1.0))
	$cobalt_light/cobalt_glow.set_visible(true)
	$cobalt_light/cobalt_glow.set_self_modulate(Color(0.0, 1.0, 1.0))

func _iron_light():
	iron_is_ready = true
	$clone_light/iron_light.set_self_modulate(Color(1.0, 1.0, 1.0))
	if silicon_is_ready and water_is_ready:
		_clone_light()

func _silicon_light():
	silicon_is_ready = true
	$clone_light/silicon_light.set_self_modulate(Color(1.0, 1.0, 1.0))
	if iron_is_ready and water_is_ready:
		_clone_light()

func _water_light():
	water_is_ready = true
	$clone_light/water_light.set_self_modulate(Color(1.0, 1.0, 1.0))
	if silicon_is_ready and iron_is_ready:
		_clone_light()

func _clone_light():
	ready_to_clone = true
	$clone_light.set_self_modulate(Color(1.0, 1.0, 1.0))

func _on_crab_battery_charge_changed():
	energyBar.value = 100.0 * _crab._carried_resources.battery_energy / _crab._stats.battery_capacity



# Called when the node enters the scene tree for the first time.
func _ready():
	dayLabel.text = "Day " + str(WorldClock.day_count)
	WorldClock.new_day_rollover.connect(_new_day)
	_crab.cobalt_ready.connect(_cobalt_light)
	_crab.iron_ready.connect(_iron_light)
	_crab.silicon_ready.connect(_silicon_light)
	_crab.water_ready.connect(_water_light)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	waterBar.value = 100.0 * _crab._carried_resources.water / _crab.waterTarget
	siliconBar.value = 100.0 * _crab._carried_resources.silicon / _crab.siliconTarget
	ironBar.value = 100.0 * _crab._carried_resources.iron / _crab.ironTarget
	sundial.set_rotation(2.0 * PI * WorldClock.time)
	if cobalt_is_ready:
		var sizeFloat = 2.0 + 0.5 * sin(WorldClock.time * 240.0)
		$cobalt_light/cobalt_glow.set_scale(Vector2(sizeFloat, sizeFloat))
