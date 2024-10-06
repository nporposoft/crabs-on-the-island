class_name Crab

extends RigidBody2D

@export var move_battery_usage: float = 0.1
@export var dodge_battery_usage: float = 0.5
@export var harvest_battery_usage: float = 0.1
@export var dodge_cooldown_seconds: float = 1.67
@export var dodge_duration: float = 0.5
@export var dodge_speed_multiplier: float = 1.0
@export var shutdown_cooldown_seconds: float = 3.0
@export var foot_step_time_delay: float = 0.1

const movementThreshold: float = 20.0
const harvestDrain = -1.0
const cobaltTarget = 10.0
const ironTarget = 10.0
const siliconTarget = 10.0
const waterTarget = 10.0

signal carried_iron_changed
signal carried_cobalt_changed
signal carried_silicon_changed
signal carried_water_changed
signal battery_charge_changed

var _direction: Util.Directions = Util.Directions.DOWN
var _velocity: Vector2
var _foot_step_sounds: Array[AudioStreamPlayer2D]
var _foot_step_timer: Timer

enum States {
	RUNNING = 0,
	DODGING = 1,
	DODGE_COOLDOWN = 2,
	ATTACKING = 3,
	REPRODUCING = 4,
	OUT_OF_BATTERY = 5,
	SHUTDOWN_COOLDOWN = 6
}
var _state: int

var _current_animation: String
var _current_flip_h: bool

var _body_resources: Dictionary = {
	"iron": 0,
	"cobalt": 0,
	"silicon": 0,
	"water": 0,
}
var _carried_resources: Dictionary = {
	"iron": 0,
	"cobalt": 0,
	"silicon": 0,
	"water": 0,
	"battery_energy": 0.0,
}
var _stats: Dictionary = {
	"size": 1.0,
	"hit_points": 10.0,
	"strength": 10.0,
	"move_speed": 5000.0,
	"solar_charge_rate": 0.2,
	"battery_capacity": 10.0,
	"harvest_speed": 2.0
}

func _ready() -> void:
	_foot_step_sounds = [$FootStepSound1, $FootStepSound2]
	_foot_step_timer = Timer.new()
	_foot_step_timer.wait_time = foot_step_time_delay
	_foot_step_timer.timeout.connect(_play_random_footstep_sound)
	add_child(_foot_step_timer)

func init(body_resources: Dictionary, stats: Dictionary) -> void:
	_body_resources = body_resources
	_stats = stats


func move(movementDirection: Vector2) -> void:
	_velocity = movementDirection
	
	if _has_any_state([States.REPRODUCING, States.OUT_OF_BATTERY, States.DODGING]): return
	if movementDirection.length() == 0: return

	if !_has_state(States.RUNNING):
		_set_state(States.RUNNING)
		_play_random_footstep_sound()
		_foot_step_timer.start()

	_direction = Util.get_direction_from_vector(movementDirection)
	apply_central_force(movementDirection.normalized() * _stats.move_speed)


func dodge() -> void:
	if _has_any_state([States.DODGING, States.DODGE_COOLDOWN, States.OUT_OF_BATTERY, States.REPRODUCING]): return

	_set_state(States.DODGING)
	_set_state(States.DODGE_COOLDOWN)
	var direction: Vector2 = Util.get_vector_from_direction(_direction)
	apply_central_impulse(direction * _stats.move_speed * dodge_speed_multiplier)
	_modify_battery_energy(-dodge_battery_usage)
	$DashSoundEffect.play()
	_one_shot_timer(dodge_duration, func() -> void:
		_unset_state(States.DODGING)
	)
	_one_shot_timer(dodge_cooldown_seconds, func() -> void:
		_unset_state(States.DODGE_COOLDOWN)
	)

func harvest(delta: float) -> bool:
	if _has_state(States.OUT_OF_BATTERY): return false

	var closestDist = 1000.0
	var closestMorsel: Morsel
	var pickups_in_reach = $reach_area.get_overlapping_bodies()
	for item: RigidBody2D in pickups_in_reach:
		var morselItem = item as Morsel
		if morselItem == null: continue
		if (morselItem.position - self.position).length() < closestDist:
			closestDist = (morselItem.position - self.position).length()
			closestMorsel = morselItem
	if closestMorsel != null:
		var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrain))
		match closestMorsel.mat_type:
			Morsel.MATERIAL_TYPE.COBALT:
				if _carried_resources.cobalt < cobaltTarget: _extract_cobalt(partial_harvest * closestMorsel._extract(_stats.harvest_speed * delta), delta)
				else: return false
			Morsel.MATERIAL_TYPE.IRON:
				if _carried_resources.iron < ironTarget: _extract_iron(partial_harvest * closestMorsel._extract(_stats.harvest_speed * delta), delta)
				else: return false
			Morsel.MATERIAL_TYPE.SILICON:
				if _carried_resources.silicon < siliconTarget: _extract_silicon(partial_harvest * closestMorsel._extract(_stats.harvest_speed * delta), delta)
				else: return false
		$Sparks.set_emitting(true)
		$Sparks.global_position = closestMorsel.global_position
		return true
	else:
		return false #TODO: if no morsel in reach, check if on sand or in water

func stop_harvest():
	$Sparks.set_emitting(false)
	$Sparks.position = Vector2(self.position.x, self.position.y - 26.0)


func get_mutations(num_options: int = 1) -> Array:
	var mutations: Array
	for _i in num_options:
		mutations.push_back(MutationEngine.get_mutation_options(_stats))
	return mutations


func _process(delta: float) -> void:
	_update_movement_state()
	_harvest_sunlight(delta)
	_deplete_battery_from_movement(delta)
	_update_animation_from_state()


func _harvest_sunlight(delta: float) -> void:
	var time: float = WorldClock.time
	if time > 0.25 && time < 0.75:
		var gained_energy: float = _stats.solar_charge_rate * delta
		_modify_battery_energy(gained_energy)


func _deplete_battery_from_movement(delta: float) -> void:
	if !_has_state(States.RUNNING): return

	var lost_energy: float = move_battery_usage * delta
	_modify_battery_energy(-lost_energy)


func _modify_battery_energy(value: float) -> void:
	_carried_resources.battery_energy = clampf(_carried_resources.battery_energy + value, 0, _stats.battery_capacity)
	if !_has_state(States.SHUTDOWN_COOLDOWN) && _has_state(States.OUT_OF_BATTERY) && _carried_resources.battery_energy > 0:
		_unset_state(States.OUT_OF_BATTERY)
		$PowerOnSoundEffect.play()
		$Zs.set_emitting(false)
	elif _carried_resources.battery_energy == 0 && !_has_state(States.OUT_OF_BATTERY):
		_set_state(States.OUT_OF_BATTERY)
		_set_state(States.SHUTDOWN_COOLDOWN)
		$PowerOffSoundEffect.play()
		$Zs.set_emitting(true)
		_one_shot_timer(shutdown_cooldown_seconds, func() -> void:
			_unset_state(States.SHUTDOWN_COOLDOWN)
		)
	battery_charge_changed.emit()

func _extract_cobalt(value: float, delta: float) -> void:
	_carried_resources.cobalt = clampf(_carried_resources.cobalt + value, 0, cobaltTarget)
	_modify_battery_energy(delta * harvestDrain)
	carried_cobalt_changed.emit()

func _extract_iron(value: float, delta: float) -> void:
	_carried_resources.iron = clampf(_carried_resources.iron + value, 0, ironTarget)
	_modify_battery_energy(delta * harvestDrain)
	carried_iron_changed.emit()

func _extract_silicon(value: float, delta: float) -> void:
	_carried_resources.silicon = clampf(_carried_resources.silicon + value, 0, siliconTarget)
	_modify_battery_energy(delta * harvestDrain)
	carried_silicon_changed.emit()


func _update_movement_state() -> void:
	if _has_state(States.OUT_OF_BATTERY):
		_foot_step_timer.stop()
		_unset_state(States.RUNNING)
		return

	if _has_state(States.DODGING): return

	if _velocity.length() == 0:
		_foot_step_timer.stop()
		_unset_state(States.RUNNING)


func _update_animation_from_state() -> void:
	var animation: String
	var flip_h: bool

	if _direction in Util.LeftDirections: flip_h = true

	if _has_state(States.OUT_OF_BATTERY):
		animation = "sleep"
	elif _has_state(States.DODGING):
		animation = "dodge"
	elif _has_state(States.RUNNING):
		animation = "move"
	else:
		animation = "idle"

	if animation != _current_animation || flip_h != _current_flip_h:
		_current_animation = animation
		_current_flip_h = flip_h
		$AnimatedSprite2D.play(_current_animation)
		$AnimatedSprite2D.flip_h = _current_flip_h


func _play_random_footstep_sound() -> void:
	var sound: AudioStreamPlayer2D = _foot_step_sounds[randi_range(0, _foot_step_sounds.size() - 1)]
	sound.pitch_scale = randf_range(0.8, 1.2)
	sound.play()


func _one_shot_timer(duration: float, callback: Callable) -> void:
	var timer: Timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func() -> void:
		callback.call()
		remove_child(timer)
		timer.queue_free()
	)
	add_child(timer)
	timer.start()


func _has_state(state: States) -> bool:
	var mask: int = 1 << state
	return _state & mask


func _has_any_state(states: Array[States]) -> bool:
	for state: States in states:
		if _has_state(state): return true
	return false


func _set_state(state: States) -> void:
	var mask: int = 1 << state
	_state = _state | mask


func _unset_state(state: States) -> void:
	var mask: int = 1 << state
	_state = _state & ~mask
