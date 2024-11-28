class_name SpawnPoint

extends Node2D

@export var enabled: bool = true
@export var is_player: bool = false
@export var team_color: Color = Color.WHITE
@export var starting_stats: Dictionary = {
	"size": 1.0,
	"hit_points": 20.0,
	"strength": 10.0,
	"move_power": 2500.0,
	"solar_charge_rate": 0.3,
	"battery_capacity": 10.0,
	"harvest_speed": 2.0,
	"build_speed": 0.2
}
@export var carried_resources: Dictionary = {
	"metal": 0,
	"silicon": 0,
	"water": 0,
	"battery_energy": 0.0,
}
@export var start_with_cobalt: bool = false
@export var family: Crab.Family = Crab.Family.AI
