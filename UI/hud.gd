class_name Hud

extends CanvasLayer


@export var _player : Player
@onready var energyBar = $topleft/energy_bar
@onready var waterBar = $topleft/water_bar
@onready var waterCloneBar = $topleft/water_bar/water_clone_bar
@onready var siliconBar = $topleft/silicon_bar
@onready var siliconCloneBar = $topleft/silicon_bar/silicon_clone_bar
@onready var ironBar = $topleft/iron_bar
@onready var ironCloneBar = $topleft/iron_bar/iron_clone_bar
@onready var sundial = $topright/sundial
@onready var dayLabel = $topright/day_label

var tutorial_clone = false

const active_color: Color = Color(1.0, 1.0, 1.0)
const inactive_color: Color = Color(0.0625, 0.0625, 0.0625)


func _ready():
	dayLabel.text = "Day " + str(WorldClock.day_count + 1)
	WorldClock.new_day_rollover.connect(_new_day)


func init(player: Player) -> void:
	_player = player
	_player.crab_swapped.connect(_update_statblock)
	_player.disassociation_changed.connect(_set_tab_menu)


func _process(delta):
	_update_sundial()
	if !is_instance_valid(_crab()): return

	_update_battery()
	_update_resources()
	_update_cobalt_light()
	_update_ready_to_clone()
	_update_build_progress()
	_update_statblock()


func _update_sundial() -> void:
	sundial.set_rotation(2.0 * PI * WorldClock.time)


func _update_battery() -> void:
	var batteryPercent = _crab()._carried_resources.battery_energy / _crab()._stats.battery_capacity
	energyBar.value = 100.0 * batteryPercent
	var redVal = max(1.0 - 3.0 * batteryPercent, 0.0)
	var greenVal = min(3 * batteryPercent, 1.0)
	energyBar.get_theme_stylebox("fill").set_bg_color(Color(redVal, greenVal, 0.0))


func _update_resources() -> void:
	_update_water()
	_update_silicon()
	_update_iron()


func _update_cobalt_light() -> void:
	_set_cobalt_light(_cobalt_target_reached())


func _update_ready_to_clone() -> void:
	_set_clone_light(_reproduction_targets_reached())


func _new_day():
	dayLabel.text = "Day " + str(WorldClock.day_count + 1)


func _update_build_progress() -> void:
	var progress = 100.0 * _crab().buildProgress
	waterCloneBar.value = progress
	siliconCloneBar.value = progress
	ironCloneBar.value = progress


func _reproduction_targets_reached() -> bool:
	return _water_target_reached() && _silicon_target_reached() && _iron_target_reached()


func _water_target_reached() -> bool:
	return _crab()._carried_resources.water >= _crab().waterTarget


func _silicon_target_reached() -> bool:
	return _crab()._carried_resources.silicon >= _crab().siliconTarget


func _iron_target_reached() -> bool:
	return _crab()._carried_resources.iron >= _crab().ironTarget


func _cobalt_target_reached() -> bool:
	return _crab()._carried_resources.cobalt >= _crab().cobaltTarget


func _update_water() -> void:
	waterBar.value = 100.0 * _crab()._carried_resources.water / _crab().waterTarget
	_set_water_light(_water_target_reached())


func _update_silicon() -> void:
	siliconBar.value = 100.0 * _crab()._carried_resources.silicon / _crab().siliconTarget
	_set_silicon_light(_silicon_target_reached())


func _update_iron() -> void:
	ironBar.value = 100.0 * _crab()._carried_resources.iron / _crab().ironTarget
	_set_iron_light(_iron_target_reached())


func _set_cobalt_light(activate: bool) -> void:
	var sizeFloat = 2.0 + 0.5 * sin(WorldClock.time * 240.0)
	$topleft/cobalt_light/cobalt_glow.set_scale(Vector2(sizeFloat, sizeFloat))
	$topleft/cobalt_light.set_self_modulate(active_color if activate else inactive_color)
	$topleft/cobalt_light/cobalt_glow.set_visible(activate)


func _set_iron_light(activate: bool) -> void:
	$topleft/clone_light/iron_light.set_self_modulate(active_color if activate else inactive_color)


func _set_silicon_light(activate: bool) -> void:
	$topleft/clone_light/silicon_light.set_self_modulate(active_color if activate else inactive_color)


func _set_water_light(activate: bool) -> void:
	$topleft/clone_light/water_light.set_self_modulate(active_color if activate else inactive_color)


func _set_clone_light(activate: bool) -> void:
	$topleft/clone_light.set_self_modulate(active_color if activate else inactive_color)
	if !tutorial_clone and activate:
		tutorial_clone = true
		$topleft/Q.set_visible(true)
		$topleft/Q.fading = true


func _set_tab_menu() -> void:
	if _player.is_disassociating:
		_update_statblock()
	$center/TAB.set_visible(true if _player.is_disassociating else false)
	$center/statblock.set_visible(true if _player.is_disassociating else false)


func _update_statblock() -> void:
	if !_player.is_disassociating: return
	if !is_instance_valid(_crab()): return

	var lines: Array = []
	for stat in _crab()._stats:
		var value: int = floor(100.0 * _crab()._stats[stat] / _crab()._default_stats[stat])
		var name: String = Translator.g(stat)
		lines.append(name + ":\t\t" + str(value) + "%")
	$center/statblock.set_text("\n".join(lines))


func _trigger_defeat() -> void:
	$center/defeat.set_visible(true)


func _trigger_victory() -> void:
	$center/victory.set_visible(true)


func _crab() -> Crab:
	return _player._crab
