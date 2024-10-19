extends Label

var _crab: Crab


func _ready() -> void:
	_crab = get_parent()


func _process(_delta: float) -> void:
	if !DebugMode.enabled:
		text = ""
		return

	var terrain_data: TerrainData = _crab._island.get_terrain_at_point(_crab.position)
	text = TerrainData.HarvestType.keys()[terrain_data.harvest_type]
