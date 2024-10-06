class_name Crab

extends RigidBody2D

@export var move_battery_usage: float = 0.1
@export var dash_battery_usage: float = 0.5
@export var harvest_battery_usage: float = 0.1
@export var dash_cooldown_seconds: float = 1.67
@export var dash_duration: float = 0.5
@export var dash_speed_multiplier: float = 1.0
@export var shutdown_cooldown_seconds: float = 2.0
@export var foot_step_time_delay: float = 0.1

const movementThreshold: float = 20.0
const harvestDrain = -0.25
const material_size_mult = 10.0

signal carried_iron_changed
signal carried_cobalt_changed
signal carried_silicon_changed
signal carried_water_changed
signal battery_charge_changed
signal cobalt_ready
signal iron_ready
signal silicon_ready
signal water_ready

var _direction: Util.Directions = Util.Directions.DOWN
var _velocity: Vector2
var _foot_step_sounds: Array[AudioStreamPlayer2D]
var _foot_step_timer: Timer
var _attacks_enabled: bool = false
var _sm: MultiStateMachine = MultiStateMachine.new()

var cobaltTarget = 10.0
var ironTarget = 10.0
var siliconTarget = 10.0
var waterTarget = 10.0

enum States {
	RUNNING,
	DASHING,
	DASH_COOLDOWN,
	ATTACKING,
	REPRODUCING,
	OUT_OF_BATTERY,
	SHUTDOWN_COOLDOWN,
	HARVESTING
}

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
	"harvest_speed": 1.0
}

func _ready() -> void:
	_foot_step_sounds = [$FootStepSound1, $FootStepSound2]
	_foot_step_timer = Timer.new()
	_foot_step_timer.wait_time = foot_step_time_delay
	_foot_step_timer.timeout.connect(_play_random_footstep_sound)
	add_child(_foot_step_timer)
	
	# start powered off
	_start_sleep(false)


func init(body_resources: Dictionary, stats: Dictionary) -> void:
	_body_resources = body_resources
	_stats = stats
	cobaltTarget = _stats.size * material_size_mult * 0.05
	ironTarget = _stats.size * material_size_mult
	siliconTarget = _stats.size * material_size_mult
	waterTarget = _stats.size * material_size_mult


func move(movementDirection: Vector2) -> void:
	_velocity = movementDirection.normalized()
	
	if _sm.has_any_state([States.REPRODUCING, States.OUT_OF_BATTERY, States.DASHING]): return
	if movementDirection.length() == 0: return

	if !_sm.has_state(States.RUNNING):
		_sm.set_state(States.RUNNING)
		_play_random_footstep_sound()
		_foot_step_timer.start()

	_direction = Util.get_direction_from_vector(movementDirection)
	apply_central_force(movementDirection.normalized() * _stats.move_speed)


func dash() -> void:
	if _sm.has_any_state([States.DASHING, States.DASH_COOLDOWN, States.OUT_OF_BATTERY, States.REPRODUCING]): return

	_sm.set_state(States.DASHING)
	_sm.set_state(States.DASH_COOLDOWN)
	var direction: Vector2 = Util.get_vector_from_direction(_direction)
	apply_central_impulse(direction * _stats.move_speed * dash_speed_multiplier)
	_modify_battery_energy(-dash_battery_usage)
	$DashSoundEffect.play()
	Util.one_shot_timer(self, dash_duration, func() -> void:
		_sm.unset_state(States.DASHING)
	)
	Util.one_shot_timer(self, dash_cooldown_seconds, func() -> void:
		_sm.unset_state(States.DASH_COOLDOWN)
	)

#func get_nearby_morsels() -> Array:
	#return ($reach_area.get_overlapping_bodies()
		#.map(func(body) -> Morsel: return body as Morsel)
		#.filter(func(body) -> bool: return body != null)
	#)
#
#func get_nearest_morsel() -> Morsel:
	#var nearest: Morsel
	#var nearest_distance: float = 1000.0 # arbitrary max float
	#for morsel: Morsel in get_nearby_morsels():
		#var distance: float = (morsel.position - position).length()
		#if distance < nearest_distance:
			#nearest = morsel
			#nearest_distance = distance
	#return nearest

func get_nearby_pickuppables() -> Array:
	return ($reach_area.get_overlapping_bodies()
		.map(func(body) -> RigidBody2D: return body as RigidBody2D)
		.filter(func(body) -> bool: return body != null)
	)

func get_nearest_pickuppable() -> RigidBody2D:
	var nearest: RigidBody2D
	var nearest_distance: float = 1000.0 # arbitrary max float
	for body: RigidBody2D in get_nearby_pickuppables():
		var distance: float = (body.position - position).length()
		if distance < nearest_distance:
			nearest = body
			nearest_distance = distance
	return nearest

func pickup() -> void:
	if _sm.has_state(States.OUT_OF_BATTERY): return
	
	var nearestPickuppable = get_nearest_pickuppable()
	if nearestPickuppable != null: 
		var crabItem: Crab
		crabItem = nearestPickuppable
		if crabItem != null:
			pass #crabItem is a crab; TODO: immobilize crab, tack its position to ours
		else:
			var morselItem: Morsel
			morselItem = nearestPickuppable
			if morselItem != null:
				pass #morselItem is a morsel; tack its position to ours
	else:
		return

func is_holding() -> bool:
	return false

func harvest(delta: float) -> bool:
	if _sm.has_state(States.OUT_OF_BATTERY): 
		stop_harvest()
		return false
	
	var nearestMorsel = get_nearest_morsel()
	if nearestMorsel != null: 
		return harvest_morsel(delta, nearestMorsel)
	else:
		var sandBodies = $"../../sandArea".get_overlapping_bodies()
		if sandBodies.has(self):
			return harvest_sand(delta)
		else:
			var waterBodies = $"../../waterArea".get_overlapping_bodies()
			if waterBodies.has(self):
				return harvest_water(delta)
		return false


func harvest_sand(delta: float) -> bool:
	if _sm.has_state(States.OUT_OF_BATTERY): 
		stop_harvest()
		return false
	
	var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrain))
	if _carried_resources.silicon < siliconTarget:
		_add_silicon(partial_harvest * _stats.harvest_speed * delta, delta)
		$Vacuum.set_color(Color(0.75, 0.6, 0.0))
		$Vacuum.set_emitting(true)
		return true
	return false


func harvest_water(delta: float) -> bool:
	if _sm.has_state(States.OUT_OF_BATTERY): 
		stop_harvest()
		return false
	
	var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrain))
	if _carried_resources.water < waterTarget:
		_add_water(partial_harvest * _stats.harvest_speed * delta, delta)
		$Vacuum.set_color(Color(0.0, 1.0, 1.0))
		$Vacuum.set_emitting(true)
		return true
	return false


func harvest_morsel(delta: float, morsel: Morsel) -> bool:
	if _sm.has_state(States.OUT_OF_BATTERY): 
		stop_harvest()
		return false
	
	var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrain))
	match morsel.mat_type:
		Morsel.MATERIAL_TYPE.COBALT:
			if _carried_resources.cobalt < cobaltTarget: _add_cobalt(partial_harvest * morsel._extract(_stats.harvest_speed * delta), delta)
			else: return false
		Morsel.MATERIAL_TYPE.IRON:
			if _carried_resources.iron < ironTarget: _add_iron(partial_harvest * morsel._extract(_stats.harvest_speed * delta), delta)
			else: return false
		Morsel.MATERIAL_TYPE.SILICON:
			if _carried_resources.silicon < siliconTarget: _add_silicon(partial_harvest * morsel._extract(_stats.harvest_speed * delta), delta)
			else: return false
	
	$Sparks.set_emitting(true)
	$Sparks.global_position = morsel.global_position
	$HarvestSoundEffect.play(randf_range(0, 5.0))
	return true


func stop_harvest():
	$Vacuum.set_emitting(false)
	$Sparks.set_emitting(false)
	$HarvestSoundEffect.stop()


func get_nearby_morsels() -> Array:
	return ($reach_area.get_overlapping_bodies()
		.map(func(body) -> Morsel: return body as Morsel)
		.filter(func(body) -> bool: return body != null)
	)


func get_nearest_morsel() -> Morsel:
	var nearest: Morsel
	var nearest_distance: float = 1000.0 # arbitrary max float
	for morsel: Morsel in get_nearby_morsels():
		var distance: float = (morsel.position - position).length()
		if distance < nearest_distance:
			nearest = morsel
			nearest_distance = distance
	return nearest


func can_reach_morsel(morsel: Morsel) -> bool:
	return get_nearby_morsels().has(morsel)


func get_mutations(num_options: int = 1) -> Array:
	var mutations: Array
	for _i in num_options:
		mutations.push_back(MutationEngine.get_mutation_options(_stats))
	return mutations


func _process(delta: float) -> void:
	_update_movement_state()
	_update_sleep_state()
	_harvest_sunlight(delta)
	_deplete_battery_from_movement(delta)
	_update_animation_from_state()


func _harvest_sunlight(delta: float) -> void:
	var time: float = WorldClock.time
	if time > 0.25 && time < 0.75:
		var gained_energy: float = _stats.solar_charge_rate * delta
		_modify_battery_energy(gained_energy)


func _deplete_battery_from_movement(delta: float) -> void:
	if !_sm.has_state(States.RUNNING): return

	var lost_energy: float = move_battery_usage * delta
	_modify_battery_energy(-lost_energy)

func _update_sleep_state() -> void:
	if !_sm.has_state(States.SHUTDOWN_COOLDOWN) && _sm.has_state(States.OUT_OF_BATTERY) && _carried_resources.battery_energy > 0:
		_end_sleep()

func _modify_battery_energy(value: float) -> void:
	_carried_resources.battery_energy = clampf(_carried_resources.battery_energy + value, 0, _stats.battery_capacity)
	battery_charge_changed.emit()
	if _carried_resources.battery_energy == 0 && !_sm.has_state(States.OUT_OF_BATTERY):
		_start_sleep()
	

func _start_sleep(play_sound: bool = true) -> void:
	_sm.set_state(States.OUT_OF_BATTERY)
	_sm.set_state(States.SHUTDOWN_COOLDOWN)
	if play_sound: $PowerOffSoundEffect.play()
	$Zs.set_emitting(true)
	stop_harvest()
	Util.one_shot_timer(self, shutdown_cooldown_seconds, func() -> void:
		_sm.unset_state(States.SHUTDOWN_COOLDOWN)
	)

func _end_sleep() -> void:
	_sm.unset_state(States.OUT_OF_BATTERY)
	$PowerOnSoundEffect.play()
	$Zs.set_emitting(false)

func _add_cobalt(value: float, delta: float) -> void:
	_carried_resources.cobalt = clampf(_carried_resources.cobalt + value, 0, cobaltTarget)
	_modify_battery_energy(delta * harvestDrain)
	carried_cobalt_changed.emit()
	if _carried_resources.cobalt >= cobaltTarget:
		cobalt_ready.emit()
		_attacks_enabled = true

func _add_iron(value: float, delta: float) -> void:
	_carried_resources.iron = clampf(_carried_resources.iron + value, 0, ironTarget)
	_modify_battery_energy(delta * harvestDrain)
	carried_iron_changed.emit()
	if _carried_resources.iron >= ironTarget:
		iron_ready.emit()

func _add_silicon(value: float, delta: float) -> void:
	_carried_resources.silicon = clampf(_carried_resources.silicon + value, 0, siliconTarget)
	_modify_battery_energy(delta * harvestDrain)
	carried_silicon_changed.emit()
	if _carried_resources.silicon >= siliconTarget:
		silicon_ready.emit()

func _add_water(value: float, delta: float) -> void:
	_carried_resources.water = clampf(_carried_resources.water + value, 0, waterTarget)
	_modify_battery_energy(delta * harvestDrain)
	carried_water_changed.emit()
	if _carried_resources.water >= waterTarget:
		water_ready.emit()


func _update_movement_state() -> void:
	if _sm.has_state(States.OUT_OF_BATTERY):
		_foot_step_timer.stop()
		_sm.unset_state(States.RUNNING)
		return

	if _sm.has_state(States.DASHING): return

	if _velocity.length() == 0:
		_foot_step_timer.stop()
		_sm.unset_state(States.RUNNING)


func _update_animation_from_state() -> void:
	var animation: String
	var flip_h: bool

	if _direction in Util.LeftDirections: flip_h = true

	if _sm.has_state(States.OUT_OF_BATTERY):
		animation = "sleep"
	elif _sm.has_state(States.DASHING):
		animation = "dash"
	elif _sm.has_state(States.RUNNING):
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
