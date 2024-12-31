class_name Scenario

extends Node


var victory_conditions: VictoryConditions
var crab_spawner: CrabSpawner
var camera: Camera
var player: PlayerCrabController
var clock: Clock
var hud: HUD


signal player_init(player: PlayerCrabController)
signal clock_init(clock: Clock)
signal victory
signal defeat


func _ready() -> void:
	victory_conditions = Util.require_child(self, VictoryConditions)
	victory_conditions.defeat.connect(func() -> void: defeat.emit())
	victory_conditions.victory.connect(func() -> void: victory.emit())
	
	crab_spawner = Util.require_child(self, CrabSpawner)
	
	player = Util.require_child(self, PlayerCrabController)
	var player_crab: Crab = _init_player_crab()
	player.set_crab(player_crab)
	player_init.emit(player)
	
	camera = Util.require_child(self, Camera)
	camera.init(player_crab)
	
	clock = Util.require_child(self, Clock)
	clock_init.emit(clock)
	
	_init_morsels()
	_init_ai_crabs()


func _init_morsels() -> void:
	pass


func _init_player_crab() -> Crab:
	var player_spawn: SpawnPoint = _get_player_spawn_point()
	if player_spawn == null:
		push_warning("cannot create player without spawn point")
		return
	var crab: Crab = crab_spawner.spawn_from_point(player_spawn)
	crab.on_death.connect(victory_conditions.on_crab_death)
	return crab


func _init_ai_crabs() -> Array[Crab]:
	var ai_crabs: Array[Crab]
	for spawn_point: SpawnPoint in _get_ai_spawn_points():
		var crab: Crab = crab_spawner.spawn_from_point(spawn_point)
		crab.on_death.connect(victory_conditions.on_crab_death)
		ai_crabs.push_back(crab)
	return ai_crabs


func _get_player_spawn_point() -> SpawnPoint:
	var player_spawn_points: Array = _get_spawn_points().filter(func(spawn_point: SpawnPoint) -> bool: 
		return spawn_point.is_player
	)
	if player_spawn_points.size() > 1:
		push_warning("found multiple player spawn points! please delete extras")
	elif player_spawn_points.size() == 0:
		push_warning("found no player spawn points")
		return null
	
	return player_spawn_points[0]


func _get_ai_spawn_points() -> Array:
	return _get_spawn_points().filter(func(spawn_point: SpawnPoint) -> bool:
		return !spawn_point.is_player
	)


func _get_spawn_points() -> Array:
	return (get_children().filter(func(child: Node) -> bool:
		var spawn_point: SpawnPoint = child as SpawnPoint
		return spawn_point != null && spawn_point.enabled
	))


func crabs() -> CrabCollection:
	var all_crabs: Array[Crab]
	for node: Node in get_children():
		var crab: Crab = node as Crab
		if crab != null:
			all_crabs.push_back(crab)
	return CrabCollection.new(all_crabs)
