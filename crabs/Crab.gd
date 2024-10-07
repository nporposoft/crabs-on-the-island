class_name Crab

extends RigidBody2D

@export var move_battery_usage: float = 0.1
@export var dash_battery_usage: float = 0.5
@export var harvest_battery_usage: float = 0.1
@export var dash_cooldown_seconds: float = 1.0
@export var dash_duration: float = 0.4
@export var dash_speed_multiplier: float = 1.0
@export var shutdown_cooldown_seconds: float = 2.0
@export var foot_step_time_delay: float = 0.1

const movementThreshold: float = 20.0
const harvestDrainMult = -0.25
const buildDrainMult = -2.0
const material_size_mult = 10.0

var crab_scene: PackedScene = preload("res://crabs/Crab.tscn")
var crab_ai_scene: PackedScene = preload("res://crabs/AI/CrabAI.tscn")
var morselTemplate: PackedScene = preload("res://resources/Morsel.tscn")
var toastTemplate: PackedScene = preload("res://Toast.tscn")

signal mutations_generated

var isPlayerFamily: bool
var _HP: float
var _direction: Util.Directions = Util.Directions.DOWN
var _velocity: Vector2
@onready var _foot_step_sounds: Array[AudioStreamPlayer2D] = [$FootStepSound1, $FootStepSound2]
var _foot_step_timer: Timer
var _attacks_enabled: bool = false
var _sm: MultiStateMachine = MultiStateMachine.new()
var cobaltTarget: float
var ironTarget: float
var siliconTarget: float
var waterTarget: float
var buildProgress: float = 0.0
@onready var _island: IslandV1 = $"/root/Game/IslandV1"

var batteryEnergyTargetPercentage = 50

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
	"silicon": 0
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
	"solar_charge_rate": 0.2, #0.1, TODO: change back after testing
	"battery_capacity": 10.0,
	"harvest_speed": 10.0, #1.0, TODO: change back after testing
	"build_speed": 0.25 #TODO: added new dictionary element--find out where else I need to reconcile this change
}

func _ready() -> void:
	_foot_step_timer = Timer.new()
	_foot_step_timer.wait_time = foot_step_time_delay
	_foot_step_timer.timeout.connect(_play_random_footstep_sound)
	add_child(_foot_step_timer)
	#TODO: find out whether to keep the following initialization, or somehow make it work in init()
	_body_resources = { "iron": _stats.size * material_size_mult, "cobalt": 0.0, "silicon": _stats.size * material_size_mult }
	_HP = _stats.hit_points
	cobaltTarget = _stats.size * material_size_mult * 0.05
	ironTarget = _stats.size * material_size_mult
	siliconTarget = _stats.size * material_size_mult
	waterTarget = _stats.size * material_size_mult

	$healthBar/healthNum.set_text(str(_HP))
	
	set_size(_stats.size)

	# start powered off
	_start_sleep(false)


func init(body_resources: Dictionary, stats: Dictionary, playerFam: bool) -> void:
	isPlayerFamily = playerFam
	if isPlayerFamily:
		$AnimatedSprite2D.set_self_modulate(Color(1.0, 0.0, 0.0))
	_body_resources = body_resources
	if _body_resources.cobalt == 0.0 and _body_resources.iron == 0.0 and _body_resources.silicon:
		_body_resources = { "iron": _stats.size * material_size_mult, "cobalt": 0.0, "silicon": _stats.size * material_size_mult }
	else:
		_body_resources = body_resources
	_stats = stats
	set_size(_stats.size)
	
	#TODO: test whether the (re?)initialization of the targets below is necessary, esp. for descendants
	#_HP = _stats.hit_points
	#cobaltTarget = _stats.size * material_size_mult * 0.05
	#ironTarget = _stats.size * material_size_mult
	#siliconTarget = _stats.size * material_size_mult
	#waterTarget = _stats.size * material_size_mult


func set_color(color: Color):
	$AnimatedSprite2D.set_self_modulate(color)


func die() -> void:
	generate_chunks(1.0, true)
	queue_free()

func move(movementDirection: Vector2) -> void:
	_velocity = movementDirection.normalized()

	if _sm.has_any_state([States.REPRODUCING, States.OUT_OF_BATTERY, States.DASHING]): return
	if movementDirection.length() == 0: return

	if !_sm.has_state(States.RUNNING):
		_sm.set_state(States.RUNNING)
		_play_random_footstep_sound()
		_foot_step_timer.start()

	_direction = Util.get_direction_from_vector(movementDirection)
	var batteryPercent = _carried_resources.battery_energy / _stats.battery_capacity
	apply_central_force(movementDirection.normalized() * _stats.move_speed * clampf(3 * batteryPercent, 0.0, 1.0)) # linear ramp from 0% speed at empty battery to 100% speed at 1/3 battery


func dash() -> void:
	if _sm.has_any_state([States.DASHING, States.DASH_COOLDOWN, States.OUT_OF_BATTERY, States.REPRODUCING]): return

	_sm.set_state(States.DASHING)
	_sm.set_state(States.DASH_COOLDOWN)
	var direction: Vector2 = Util.get_vector_from_direction(_direction)
	var batteryPercent = min(_carried_resources.battery_energy / dash_battery_usage, 1.0)
	apply_central_impulse(direction * _stats.move_speed * dash_speed_multiplier * batteryPercent)
	_modify_battery_energy(-dash_battery_usage)
	$DashSoundEffect.play()
	Util.one_shot_timer(self, dash_duration, func() -> void:
		_sm.unset_state(States.DASHING)
	)
	Util.one_shot_timer(self, dash_cooldown_seconds, func() -> void:
		_sm.unset_state(States.DASH_COOLDOWN)
	)


func apply_damage(damage: float) -> void:
	if _HP == _stats.hit_points:
		$healthBar.set_visible(true)
	_HP -= damage
	if _HP <= 0.0:
		die()
	else:
		$healthBar.set_value(100.0 * _HP / _stats.hit_points)
		if DebugMode.enabled:
			$healthBar/healthNum.set_visible(true)
			$healthBar/healthNum.set_text(str(_HP))

func generate_chunks(percent: float, include_body: bool) -> void:
	var cobaltMass = _carried_resources.cobalt * percent
	if include_body: cobaltMass += _body_resources.cobalt
	while cobaltMass > 0.0:
		var randMass = min(randf_range(_stats.size() * material_size_mult * 0.2, _stats.size() * material_size_mult * 0.5), cobaltMass)
		cobaltMass -= randMass
		if percent < 1.0 and _carried_resources.cobalt > 0.0:
			_carried_resources.cobalt = max(0.0, _carried_resources.cobalt - randMass)
		#TODO: morsel generation disabled for testing elsewhere: revert later when needed
		var new_morsel = morselTemplate.instantiate()
		$"../..".add_child(new_morsel)
		new_morsel.set_children_scale(sqrt(randMass) / 2.0)
		new_morsel.set_position(Vector2(position.x, position.y))
		new_morsel._set_resource(Morsel.MATERIAL_TYPE.COBALT, randMass, true)
	var ironMass = _carried_resources.iron * percent
	if include_body: ironMass += _body_resources.iron
	while ironMass > 0.0:
		var randMass = min(randf_range(_stats.size() * material_size_mult * 0.2, _stats.size() * material_size_mult * 0.5), ironMass)
		ironMass -= randMass
		if percent < 1.0 and _carried_resources.iron > 0.0:
			_carried_resources.iron = max(0.0, _carried_resources.iron - randMass)
		#TODO: morsel generation disabled for testing elsewhere: revert later when needed
		var new_morsel = morselTemplate.instantiate()
		$"../..".add_child(new_morsel)
		new_morsel.set_children_scale(sqrt(randMass) / 2.0)
		new_morsel._set_resource(Morsel.MATERIAL_TYPE.IRON, randMass, true)
		new_morsel.set_position(Vector2(position.x, position.y))
	var siliconMass = _carried_resources.silicon * percent
	if include_body: siliconMass += _body_resources.silicon
	while siliconMass > 0.0:
		var randMass = min(randf_range(_stats.size() * material_size_mult * 0.2, _stats.size() * material_size_mult * 0.5), siliconMass)
		siliconMass -= randMass
		if percent < 1.0 and _carried_resources.silicon > 0.0:
			_carried_resources.silicon = max(0.0, _carried_resources.silicon - randMass)
		#TODO: morsel generation disabled for testing elsewhere: revert later when needed
		var new_morsel = morselTemplate.instantiate()
		$"../..".add_child(new_morsel)
		new_morsel.set_children_scale(sqrt(randMass) / 2.0)
		new_morsel._set_resource(Morsel.MATERIAL_TYPE.SILICON, randMass, true)
		new_morsel.set_position(Vector2(position.x, position.y))

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

func get_nearby_crabs() -> Array:
	return ($reach_area.get_overlapping_bodies()
		.map(func(body) -> Crab: return body as Crab)
		.filter(func(body) -> bool: return body != null)
	)

func get_nearest_crab() -> RigidBody2D:
	var nearest: Crab
	var nearest_distance: float = 1000.0 # arbitrary max float
	for body: Crab in get_nearby_crabs():
		var distance: float = (body.position - position).length()
		if distance < nearest_distance and body.get_rid() != self.get_rid():
			nearest = body
			nearest_distance = distance
	return nearest

func harvest(delta: float) -> bool:
	if _sm.has_state(States.OUT_OF_BATTERY):
		stop_harvest()
		return false
	if _attacks_enabled:
		var nearestCrab = get_nearest_crab()
		if nearestCrab != null:
			attackCrab(nearestCrab, delta)
			return true
	var nearestMorsel = get_nearest_morsel()
	if nearestMorsel != null:
		return harvest_morsel(delta, nearestMorsel)
	else:
		var sandBodies = _island.SandArea.get_overlapping_bodies()
		if sandBodies.has(self):
			return harvest_sand(delta)
		else:
			var waterBodies = _island.WaterArea.get_overlapping_bodies()
			if waterBodies.has(self):
				return harvest_water(delta)
		return false


func attackCrab(target: Crab, delta: float) -> void:
	var dmg = _stats.harvest_speed * delta
	target.apply_damage(dmg)
	$Sparks.set_emitting(true)
	$Sparks.global_position = target.global_position
	$HarvestSoundEffect.play(randf_range(0, 5.0))


func harvest_sand(delta: float) -> bool:
	if _sm.has_state(States.OUT_OF_BATTERY):
		stop_harvest()
		return false

	var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrainMult))
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

	var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrainMult))
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

	var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrainMult))
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
	$Sparks.global_position = morsel.global_position + (global_position - morsel.global_position) * 0.67
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


func auto_reproduce(delta: float) -> bool:
	if can_reproduce():
		if _sm.has_any_state([States.OUT_OF_BATTERY]):
			return true
		buildProgress += _stats.build_speed * delta
		_modify_battery_energy(_stats.build_speed * delta * buildDrainMult)
		if buildProgress >= 1.0:
			var mutation: Dictionary = MutationEngine.get_mutation_options(_stats)
			reproduce(mutation)
			buildProgress = 0.0
			return false
		return true
	return false


func stop_reproduce() -> void:
	if buildProgress > 0.0:
		generate_chunks(buildProgress, false)
		_carried_resources.water *= 1.0 - buildProgress #TODO: probably should make a remove_resource function so we don't have to write manually
		buildProgress = 0.0


func reproduce(mutation: Dictionary) -> void:
	var new_stats: Dictionary = MutationEngine.apply_mutation(_stats, mutation)
	var new_crab: Crab = crab_scene.instantiate()
	var new_body_resources = { "iron": _carried_resources.iron, "cobalt": _carried_resources.cobalt, "silicon": _carried_resources.silicon }
	_carried_resources = { "iron": 0.0, "cobalt": 0.0, "silicon": 0.0, "water": 0.0, "battery_energy": 0.0 }
	new_crab.init(new_body_resources, new_stats, isPlayerFamily)
	var new_crab_direction: Vector2 = Util.random_direction()
	new_crab.position = position + (new_crab_direction * 20.0)
	var new_crab_ai: CrabAI = crab_ai_scene.instantiate()
	new_crab.add_child(new_crab_ai)
	_island.add_child(new_crab)
	new_crab.stat_toasts(mutation)



func has_reproduction_resources() -> bool:
	if _carried_resources.iron < ironTarget: return false
	if _carried_resources.silicon < siliconTarget: return false
	if _carried_resources.water < waterTarget: return false
	return true


func can_reproduce() -> bool:
	if !has_reproduction_resources(): return false
	return true


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

	var batteryPercent = _carried_resources.battery_energy / _stats.battery_capacity
	var lost_energy: float = min(move_battery_usage * delta * (1.6 * batteryPercent + 0.2), 1.0) # usage scales to match speed ramp at low battery
	_modify_battery_energy(-lost_energy)

func _update_sleep_state() -> void:
	if !_sm.has_state(States.SHUTDOWN_COOLDOWN) && _sm.has_state(States.OUT_OF_BATTERY) && _carried_resources.battery_energy > 0:
		_end_sleep()

func _modify_battery_energy(value: float) -> void:
	_carried_resources.battery_energy = clampf(_carried_resources.battery_energy + value, 0, _stats.battery_capacity)
	if _carried_resources.battery_energy == 0:
		_start_sleep()


func _start_sleep(play_sound: bool = true) -> void:
	if _sm.has_state(States.OUT_OF_BATTERY): return

	_sm.set_states([States.OUT_OF_BATTERY, States.SHUTDOWN_COOLDOWN])
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


func has_cobalt_target() -> bool:
	return _carried_resources.cobalt >= cobaltTarget


func will_drop_iron() -> bool:
	return _carried_resources.iron > 0 || _body_resources.iron > 0


func will_drop_silicon() -> bool:
	return _carried_resources.silicon > 0 || _body_resources.silicon > 0


func _add_cobalt(value: float, delta: float) -> void:
	_carried_resources.cobalt = clampf(_carried_resources.cobalt + value, 0, cobaltTarget)
	_modify_battery_energy(delta * harvestDrainMult)
	if _carried_resources.cobalt >= cobaltTarget:
		_attacks_enabled = true


func _add_iron(value: float, delta: float) -> void:
	_carried_resources.iron = clampf(_carried_resources.iron + value, 0, ironTarget)
	_modify_battery_energy(delta * harvestDrainMult)


func _add_silicon(value: float, delta: float) -> void:
	_carried_resources.silicon = clampf(_carried_resources.silicon + value, 0, siliconTarget)
	_modify_battery_energy(delta * harvestDrainMult)


func _add_water(value: float, delta: float) -> void:
	_carried_resources.water = clampf(_carried_resources.water + value, 0, waterTarget)
	_modify_battery_energy(delta * harvestDrainMult)


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

func stat_toasts(mutation: Dictionary) -> void:
	var newToast = toastTemplate.instantiate()
	add_child(newToast)
	newToast.set_stats(mutation)

func _play_random_footstep_sound() -> void:
	var sound: AudioStreamPlayer2D = _foot_step_sounds[randi_range(0, _foot_step_sounds.size() - 1)]
	sound.pitch_scale = randf_range(0.8, 1.2)
	sound.play()

func set_size(scale: float) -> void:
	for child in find_children("*", "", false):
		var scalable_child: Node2D = child as Node2D
		if scalable_child != null: scalable_child.scale *= scale
