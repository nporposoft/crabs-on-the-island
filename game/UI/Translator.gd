class_name Translator

extends Node

const _stat_to_human_readable: Dictionary = {
	"size": "Size",
	"hit_points": "Hit points",
	"strength": "Strength",
	"move_power": "Movement power",
	"solar_charge_rate": "Solar charge rate",
	"battery_capacity": "Battery",
	"harvest_speed": "Harvest speed",
	"build_speed": "Build speed"
}

static func g(stat_key: String) -> String:
	return _stat_to_human_readable[stat_key]
