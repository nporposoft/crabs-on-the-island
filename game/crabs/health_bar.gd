class_name HealthBar

extends ProgressBar

@onready var label: Label = $healthNum
@onready var crab: Crab = get_parent()

func _ready() -> void:
	crab.on_damage.connect(func() -> void: set_visible(true))


func _process(_delta: float) -> void:
	if !is_visible || !DebugMode.enabled: return

	var hp: float = crab._HP
	var hp_percent: float = (hp / crab._stats_effective.hit_points) * 100.0
	set_value(hp_percent)
	label.set_text(str(hp))
