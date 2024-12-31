class_name Crab

extends RigidBody2D


@onready var sprite: AnimatedSprite2D = $Sprite
@onready var ai: CrabAI = $AI
@onready var scenario: Scenario = get_parent()
var _clock: Clock
@onready var reach: Detector = $ReachArea
@onready var vision: Detector = $VisionArea

@export var move_battery_usage: float = 0.1
@export var dash_battery_usage: float = 0.5
@export var harvest_battery_usage: float = 0.1
@export var dash_cooldown_seconds: float = 0.6
@export var dash_duration: float = 0.4
@export var dash_speed_multiplier: float = 1.0
@export var shutdown_cooldown_seconds: float = 2.0
@export var foot_step_time_delay: float = 0.1

const movementThreshold: float = 20.0
const harvestDrainMult = -0.25
const buildDrainMult = -2.0


var morsel_template: PackedScene = preload("res://game/resources/morsel.tscn")
var toast_template: PackedScene  = preload("res://game/crabs/toast.tscn")
#@onready var tabForTrigger: AnimatedSprite2D = $"/root/Game/hud/center/TAB"


signal on_death
signal on_damage
signal on_dash
signal on_harvest(type: String)
signal on_sleep
signal on_wakeup
signal on_reproduce(parent: Crab, child: Crab)


var _movement_direction: Vector2 = Vector2.RIGHT
var _velocity: Vector2
@onready var _foot_step_sounds: Array[AudioStreamPlayer2D] = [$FootStepSound1, $FootStepSound2]
var _foot_step_timer: Timer
var _contains_cobalt: bool = false
var state: State = State.new()
var _HP: float
var _mass: float
var metalTarget: float = 1.0
var siliconTarget: float = 1.0
var waterTarget: float = 1.0
var buildProgress: float = 0.0
var default_color: Color = Color(1, 1, 1, 1)
var _color: Color = default_color
var _family: Family

enum States {
	RUNNING,
	DASHING,
	DASH_COOLDOWN,
	ATTACKING,
	REPRODUCING,
	OUT_OF_BATTERY,
	SHUTDOWN_COOLDOWN,
	HARVESTING,
	DEAD
}

enum Family {
	AI,
	PLAYER
}


var _body_metal: float = 0.0
var _carried_resources: Dictionary
var _stats_base: Dictionary = {
	"size": 0,
	"hit_points": 0,
	"strength": 0,
	"move_power": 0,
	"solar_charge_rate": 0,
	"battery_capacity": 0,
	"harvest_speed": 0,
	"build_speed": 0
}
var _stats_effective: Dictionary = _stats_base.duplicate()


func _ready() -> void:
	_foot_step_timer = Timer.new()
	_foot_step_timer.wait_time = foot_step_time_delay
	_foot_step_timer.timeout.connect(_play_random_footstep_sound)
	add_child(_foot_step_timer)


func apply_size_bonuses() -> void:
	_stats_base.size = max(0.05, _stats_base.size)	# ABSOLUTE MINIMUM SIZE (prevents stat weirdness at very small values)
	_stats_effective.size = _stats_base.size
	_stats_effective.hit_points = _stats_base.hit_points * _stats_base.size ** 2
	_stats_effective.strength = _stats_base.strength + (_stats_base.size ** 3) / 4.0
	#_stats_effective.move_power = _stats_base.move_power + _stats_base.size() ** 2
	#_stats_effective.move_power = (_stats_base.move_power * (_stats_base.size ** 2.0) * 0.01 * (_stats_effective.strength + (_stats_base.size ** 3.0) / 4.0) ** 2.0)
	#_stats_effective.move_power = (_stats_base.move_power * (_stats_base.size ** 2.0) * 0.1 * (_stats_effective.strength + (_stats_base.size ** 3.0) / 2.0) * sqrt(_stats_base.size))
	_stats_effective.move_power = (_stats_base.move_power * (_stats_base.size ** 2.0) * 0.1 * (_stats_effective.strength + (_stats_base.size ** 3.0) / 2.0) * log(1.25 + _stats_base.size))
	_stats_effective.solar_charge_rate = _stats_base.solar_charge_rate
	_stats_effective.battery_capacity = _stats_base.battery_capacity
	_stats_effective.harvest_speed = _stats_base.harvest_speed * _stats_base.size
	_stats_effective.build_speed = _stats_base.build_speed
	_HP = _stats_effective.hit_points
	_mass = _stats_base.size ** 3
	metalTarget = _stats_base.size ** 3
	siliconTarget = _stats_base.size ** 3
	waterTarget = _stats_base.size ** 3


func init(
		carried_resources: Dictionary,
		stats: Dictionary,
		color: Color,
		contains_cobalt: bool,
		family: Family,
		start_sleeping: bool = true,
	) -> void:
	
	_carried_resources = carried_resources
	_contains_cobalt = contains_cobalt
	set_color(color)
	_family = family
	_stats_base = stats
	apply_size_bonuses()
	_body_metal = _stats_base.size ** 3
	
	set_size(_stats_effective.size)
	
	if start_sleeping:
		_start_sleep(false)

	_clock = Util.require_child(scenario, Clock)


func set_color(color: Color) -> void:
	_color = color
	$Sprite.set_color(color)


func is_player() -> bool:
	return _family == Family.PLAYER


func die() -> void:
	generate_chunks(1.0, true)
	state.add(States.DEAD)
	queue_free()
	on_death.emit()


func is_dead() -> bool:
	return state.has(States.DEAD)


func move(movementDirection: Vector2) -> void:
	_movement_direction = movementDirection.normalized()
	
	if !can_move(): return
	if is_zero_approx(movementDirection.length()): return

	if !state.has(States.RUNNING):
		state.has(States.RUNNING)
		_play_random_footstep_sound()
		_foot_step_timer.start()

	var batteryPercent = _carried_resources.battery_energy / _stats_effective.battery_capacity
	apply_central_force(movementDirection.normalized() * _stats_effective.move_power * clampf(2.7 * batteryPercent + 0.1, 0.0, 1.0)) # linear ramp from 10% speed at empty battery to 100% speed at 1/3 battery


func can_move() -> bool:
	return !build_in_progress() && !state.has_any([States.REPRODUCING, States.OUT_OF_BATTERY, States.DASHING])


func dash() -> void:
	if !can_dash(): return
	
	if is_zero_approx(_movement_direction.length()): return
	
	state.add(States.DASHING)
	var batteryPercent = min(_carried_resources.battery_energy / dash_battery_usage, 1.0)
	apply_central_impulse(_movement_direction * _stats_effective.move_power * dash_speed_multiplier * batteryPercent)
	_modify_battery_energy(-dash_battery_usage)
	on_dash.emit()
	
	Util.one_shot_timer(self, dash_duration, func() -> void:
		state.remove(States.DASHING)
		state.add(States.DASH_COOLDOWN)
		Util.one_shot_timer(self, dash_cooldown_seconds, func() -> void:
			state.remove(States.DASH_COOLDOWN)
		)
	)


func can_dash() -> bool:
	return !build_in_progress() && !state.has_any([
		States.DASHING, States.DASH_COOLDOWN, States.OUT_OF_BATTERY, States.REPRODUCING
	])


func build_in_progress() -> bool:
	return !is_zero_approx(buildProgress)


func apply_damage(damage: float) -> void:
	on_damage.emit()
	_HP -= damage
	if _HP <= 0.0:
		die()


func generate_chunks(percent: float, include_body: bool) -> void:
	var metalMass = _carried_resources.metal * percent
	if include_body: metalMass += _body_metal
	while metalMass > 0.0:
		var randMass = min(randf_range((_stats_effective.size() ** 3) * 0.2, (_stats_effective.size() ** 3) * 0.5), metalMass)
		metalMass -= randMass
		if percent < 1.0 and _carried_resources.metal > 0.0:
			_carried_resources.metal = max(0.0, _carried_resources.metal - randMass)
		var new_morsel = morsel_template.instantiate()
		scenario.add_child(new_morsel)
		new_morsel._set_resource(randMass, _contains_cobalt, true)
		new_morsel.set_position(Vector2(position.x, position.y))


func pickupables_within_reach() -> Array:
	return ($ReachArea.get_overlapping_bodies()
		.map(func(body) -> RigidBody2D: return body as RigidBody2D)
		.filter(func(body) -> bool: return body != null)
	)


func nearest_pickuppable_within_reach() -> RigidBody2D:
	var nearest: RigidBody2D
	var nearest_distance: float = 1000.0 # arbitrary max float
	for body: RigidBody2D in pickupables_within_reach():
		var distance: float = (body.position - position).length()
		if distance < nearest_distance:
			nearest = body
			nearest_distance = distance
	return nearest


func pickup() -> void:
	if state.has(States.OUT_OF_BATTERY): return

	var nearestPickuppable = nearest_pickuppable_within_reach()
	if nearestPickuppable != null:
		var crabItem: Crab
		crabItem = nearestPickuppable
		if crabItem != null:
			pass #crabItem is a crab; TODO: immobilize crab, tack its position to ours
		else:
			var morselItem: Morsel
			morselItem = nearestPickuppable
			if morselItem != null:
				pass #morselItem is a morsel; TODO: tack its position to ours
	else:
		return


func is_holding() -> bool:
	return false #TODO


func harvest(resource: Node2D, delta: float) -> bool:
	if !can_harvest(): return false

	# TODO: this ideally should only emit when we _start_ harvesting, not
	# every frame we're harvesting
	on_harvest.emit(resource.get_name())

	if resource is Crab:
		return attack(resource as Crab, delta)
	if resource is Morsel:
		return harvest_morsel(delta, resource as Morsel)
	if resource is Sand:
		return harvest_sand(delta)
	if resource is Water:
		return harvest_water(delta)
	return false


func want_resource(resource: Node2D) -> bool:
	if resource is Sand:
		return want_silicon()
	if resource is Water:
		return want_water()
	if resource is Crab:
		return want_metal() && can_attack()
	if resource is Morsel:
		return want_metal()
	return false


func want_metal() -> bool:
	return _carried_resources.metal < metalTarget


func want_silicon() -> bool:
	return _carried_resources.silicon < siliconTarget


func want_water() -> bool:
	return _carried_resources.water < waterTarget


func can_attack() -> bool:
	return can_harvest() and _contains_cobalt


func can_harvest() -> bool:
	return !state.has_any([States.OUT_OF_BATTERY, States.REPRODUCING])


func attack(target: Crab, delta: float) -> bool:
	if !can_attack(): return false

	var relative_strength_mult = _stats_effective.strength / target._stats_effective.strength
	var dmg = _stats_effective.strength * delta * relative_strength_mult
	target.apply_damage(dmg)
	$Sparks.set_emitting(true)
	$Sparks.global_position = target.global_position
	$HarvestSoundEffect.play(randf_range(0, 5.0))
	return true


func harvest_sand(delta: float) -> bool:
	if !can_harvest():
		stop_harvest()
		return false

	var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrainMult))
	if _carried_resources.silicon < siliconTarget:
		_add_silicon(partial_harvest * _stats_effective.harvest_speed * delta, delta)
		$SandVacuum.set_emitting(true)
		return true
	return false


func harvest_water(delta: float) -> bool:
	if !can_harvest():
		stop_harvest()
		return false

	var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrainMult))
	if _carried_resources.water < waterTarget:
		_add_water(partial_harvest * _stats_effective.harvest_speed * delta, delta)
		$WaterVacuum.set_emitting(true)
		return true
	return false


func harvest_morsel(delta: float, morsel: Morsel) -> bool:
	if !can_harvest():
		stop_harvest()
		return false

	var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrainMult))
	if _carried_resources.metal < metalTarget: _add_metal(partial_harvest * morsel._extract(_stats_effective.harvest_speed * delta), delta, morsel.contains_cobalt)
	else: return false

	$Sparks.set_emitting(true)
	$Sparks.global_position = morsel.global_position + (global_position - morsel.global_position) * 0.67
	$HarvestSoundEffect.play(randf_range(0, 5.0))
	return true


func stop_harvest():
	$SandVacuum.set_emitting(false)
	$WaterVacuum.set_emitting(false)
	$Sparks.set_emitting(false)
	$HarvestSoundEffect.stop()


func auto_reproduce(delta: float) -> bool:
	if can_reproduce():
		if state.has(States.OUT_OF_BATTERY):
			return true
		buildProgress += _stats_effective.build_speed * delta
		_modify_battery_energy(_stats_effective.build_speed * delta * buildDrainMult)
		if buildProgress >= 1.0:
			var mutation: Dictionary = MutationEngine.get_mutation_options(_stats_base)
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
	_carried_resources = { "metal": 0.0, "silicon": 0.0, "water": 0.0, "battery_energy": _carried_resources["battery_energy"]}
	var child: Crab = scenario.crab_spawner.spawn_with_attributes(
		position,
		{ "metal": 0.0, "silicon": 0.0, "water": 0.0, "battery_energy": 0.0 },
		MutationEngine.apply_mutation(_stats_base, mutation),
		_color,
		_contains_cobalt,
		_family
	)
	on_reproduce.emit(self, child)
	child.stat_toasts(mutation)
	#if !(_island.tutorial_swap) and new_crab.isPlayerFamily:
		#_island.tutorial_swap = true
		#tabForTrigger.set_visible(true)
		#tabForTrigger.fading = true


func has_reproduction_resources() -> bool:
	if _carried_resources.metal < metalTarget: return false
	if _carried_resources.silicon < siliconTarget: return false
	if _carried_resources.water < waterTarget: return false
	return true


func can_reproduce() -> bool:
	if !has_reproduction_resources(): return false
	return true


func get_mutations(num_options: int = 1) -> Array:
	var mutations: Array
	for _i in num_options:
		mutations.push_back(MutationEngine.get_mutation_options(_stats_base))
	return mutations


func _process(delta: float) -> void:
	_update_movementstate()
	_update_sleepstate()
	_harvest_sunlight(delta)
	_deplete_battery_from_movement(delta)


func _harvest_sunlight(delta: float) -> void:
	if _can_harvest_sunlight():
		var gained_energy: float = _stats_effective.solar_charge_rate * delta
		_modify_battery_energy(gained_energy)


func _can_harvest_sunlight() -> bool:
	var time: float = _clock.time
	return time > 0.25 && time < 0.75


func _deplete_battery_from_movement(delta: float) -> void:
	if !state.has(States.RUNNING): return

	var batteryPercent = _carried_resources.battery_energy / _stats_effective.battery_capacity
	var lost_energy: float = min(move_battery_usage * delta * (1.6 * batteryPercent + 0.2), 1.0) # usage scales to match speed ramp at low battery
	_modify_battery_energy(-lost_energy)

func _update_sleepstate() -> void:
	if !state.has(States.SHUTDOWN_COOLDOWN) && state.has(States.OUT_OF_BATTERY) && _carried_resources.battery_energy > 0:
		_end_sleep()

func _modify_battery_energy(value: float) -> void:
	_carried_resources.battery_energy = clampf(_carried_resources.battery_energy + value, 0, _stats_effective.battery_capacity)
	if is_zero_approx(_carried_resources.battery_energy):
		_start_sleep()


func _start_sleep(play_sound: bool = true) -> void:
	if state.has(States.OUT_OF_BATTERY): return

	on_sleep.emit()

	state.add_all([States.OUT_OF_BATTERY, States.SHUTDOWN_COOLDOWN])
	if play_sound: $PowerOffSoundEffect.play()
	$Zs.set_emitting(true)
	stop_harvest()
	Util.one_shot_timer(self, shutdown_cooldown_seconds, func() -> void:
		state.remove(States.SHUTDOWN_COOLDOWN)
	)


func _end_sleep() -> void:
	state.remove(States.OUT_OF_BATTERY)
	on_wakeup.emit()
	$PowerOnSoundEffect.play()
	$Zs.set_emitting(false)


func will_drop_metal() -> bool:
	return _carried_resources.metal > 0 || _body_metal > 0


func _add_metal(value: float, delta: float, morsel_has_cobalt: bool) -> void:
	_carried_resources.metal = clampf(_carried_resources.metal + value, 0, metalTarget)
	if morsel_has_cobalt: _contains_cobalt = true
	_modify_battery_energy(delta * harvestDrainMult)


func _add_silicon(value: float, delta: float) -> void:
	_carried_resources.silicon = clampf(_carried_resources.silicon + value, 0, siliconTarget)
	_modify_battery_energy(delta * harvestDrainMult)


func _add_water(value: float, delta: float) -> void:
	_carried_resources.water = clampf(_carried_resources.water + value, 0, waterTarget)
	_modify_battery_energy(delta * harvestDrainMult)


func _update_movementstate() -> void:
	if state.has(States.OUT_OF_BATTERY):
		_foot_step_timer.stop()
		state.remove(States.RUNNING)
		return

	if state.has(States.DASHING): return

	if is_zero_approx(_velocity.length()):
		_foot_step_timer.stop()
		state.remove(States.RUNNING)


func stat_toasts(mutation: Dictionary) -> void:
	var newToast = toast_template.instantiate()
	add_child(newToast)
	newToast.set_stats(mutation)

func _play_random_footstep_sound() -> void:
	var sound: AudioStreamPlayer2D = _foot_step_sounds[randi_range(0, _foot_step_sounds.size() - 1)]
	sound.pitch_scale = randf_range(0.8, 1.2)
	sound.play()

func set_size(new_scale: float) -> void:
	for child in find_children("*", "", false):
		var scalable_child: Node2D = child as Node2D
		if scalable_child != null: scalable_child.scale *= new_scale
	set_mass(new_scale ** 3)
