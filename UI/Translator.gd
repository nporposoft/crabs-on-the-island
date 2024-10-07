class_name Translator

extends Node

const _stat_to_human_readable: Dictionary = {
	"size": "Size",
	"hit_points": "Hit points",
	"strength": "Strength",
	"move_speed": "Move",
	"solar_charge_rate": "Solar charging",
	"battery_capacity": "Battery",
	"harvest_speed": "Harvest",
	"build_speed": "Build speed"
}

static func g(stat_key: String) -> String:
	return _stat_to_human_readable[stat_key]
