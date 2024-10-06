extends CanvasLayer


@export var _player : Player
@onready var _crab = _player.get_child(1)
@onready var energyBar = $energy_bar
@onready var waterBar = $water_bar
@onready var waterCloneBar = $water_bar/water_clone_bar
@onready var siliconBar = $silicon_bar
@onready var siliconCloneBar = $silicon_bar/silicon_clone_bar
@onready var ironBar = $iron_bar
@onready var ironCloneBar = $iron_bar/iron_clone_bar
@onready var sundial = $sundial
@onready var dayLabel = $day_label

var cobalt_is_ready: bool = false
var iron_is_ready: bool = false
var silicon_is_ready: bool = false
var water_is_ready: bool = false
var ready_to_clone: bool = false

func _new_day():
	dayLabel.text = "Day " + str(WorldClock.day_count)

func _update_battery() -> void:
	energyBar.value = 100.0 * _crab._carried_resources.battery_energy / _crab._stats.battery_capacity

func _update_build_prog() -> void:
	var prog = 100.0 * _crab.buildProgress
	waterCloneBar.value = prog
	siliconCloneBar.value = prog
	ironCloneBar.value = prog

func _update_cobalt() -> void:
	if _crab._carried_resources.cobalt >= _crab.cobaltTarget: cobalt_is_ready = _set_cobalt_light(true)
	else: cobalt_is_ready = _set_cobalt_light(false)

func _update_iron() -> void:
	ironBar.value = 100.0 * _crab._carried_resources.iron / _crab.ironTarget
	if _crab._carried_resources.iron >= _crab.ironTarget:
		iron_is_ready = _set_iron_light(true)
		if silicon_is_ready and water_is_ready: ready_to_clone = _set_clone_light(true)
		else: ready_to_clone = _set_clone_light(false)
	else:
		if iron_is_ready: iron_is_ready = _set_iron_light(false)
		if ready_to_clone: ready_to_clone = _set_clone_light(false)

func _update_silicon() -> void:
	siliconBar.value = 100.0 * _crab._carried_resources.silicon / _crab.siliconTarget
	if _crab._carried_resources.silicon >= _crab.siliconTarget:
		silicon_is_ready = _set_silicon_light(true)
		if iron_is_ready and water_is_ready: ready_to_clone = _set_clone_light(true)
		else: ready_to_clone = _set_clone_light(false)
	else:
		if silicon_is_ready: silicon_is_ready = _set_silicon_light(false)
		if ready_to_clone: ready_to_clone = _set_clone_light(false)

func _update_water() -> void:
	waterBar.value = 100.0 * _crab._carried_resources.water / _crab.waterTarget
	if _crab._carried_resources.water >= _crab.waterTarget:
		water_is_ready = _set_water_light(true)
		if silicon_is_ready and iron_is_ready: ready_to_clone = _set_clone_light(true)
		else: ready_to_clone = _set_clone_light(false)
	else:
		if water_is_ready: water_is_ready = _set_water_light(false)
		if ready_to_clone: ready_to_clone = _set_clone_light(false)

func _set_cobalt_light(activate: bool) -> bool:
	if activate:
		$cobalt_light.set_self_modulate(Color(1.0, 1.0, 1.0))
		$cobalt_light/cobalt_glow.set_visible(true)
	else:
		$cobalt_light.set_self_modulate(Color(0.0625, 0.0625, 0.0625))
		$cobalt_light/cobalt_glow.set_visible(false)
	return activate

func _set_iron_light(activate: bool) -> bool:
	if activate:
		$clone_light/iron_light.set_self_modulate(Color(1.0, 1.0, 1.0))
	else:
		$clone_light/iron_light.set_self_modulate(Color(0.0625, 0.0625, 0.0625))
	return activate

func _set_silicon_light(activate: bool) -> bool:
	if activate:
		$clone_light/silicon_light.set_self_modulate(Color(1.0, 1.0, 1.0))
	else:
		$clone_light/silicon_light.set_self_modulate(Color(0.0625, 0.0625, 0.0625))
	return activate

func _set_water_light(activate: bool) -> bool:
	if activate:
		$clone_light/water_light.set_self_modulate(Color(1.0, 1.0, 1.0))
	else:
		$clone_light/water_light.set_self_modulate(Color(0.0625, 0.0625, 0.0625))
	return activate

func _set_clone_light(activate: bool) -> bool:
	if activate:
		$clone_light.set_self_modulate(Color(1.0, 1.0, 1.0))
	else:
		$clone_light.set_self_modulate(Color(0.0625, 0.0625, 0.0625))
	return activate


# Called when the node enters the scene tree for the first time.
func _ready():
	dayLabel.text = "Day " + str(WorldClock.day_count)
	WorldClock.new_day_rollover.connect(_new_day)
	_crab.cobalt_ready.connect(_set_cobalt_light)
	_crab.iron_ready.connect(_set_iron_light)
	_crab.silicon_ready.connect(_set_silicon_light)
	_crab.water_ready.connect(_set_water_light)
	_crab.carried_iron_changed.connect(_update_iron)
	_crab.carried_cobalt_changed.connect(_update_cobalt)
	_crab.carried_silicon_changed.connect(_update_silicon)
	_crab.carried_water_changed.connect(_update_water)
	_crab.battery_charge_changed.connect(_update_battery)
	_crab.build_progress_changed.connect(_update_build_prog)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#waterBar.value = 100.0 * _crab._carried_resources.water / _crab.waterTarget
	#siliconBar.value = 100.0 * _crab._carried_resources.silicon / _crab.siliconTarget
	#ironBar.value = 100.0 * _crab._carried_resources.iron / _crab.ironTarget
	sundial.set_rotation(2.0 * PI * WorldClock.time)
	if cobalt_is_ready:
		var sizeFloat = 2.0 + 0.5 * sin(WorldClock.time * 240.0)
		$cobalt_light/cobalt_glow.set_scale(Vector2(sizeFloat, sizeFloat))
