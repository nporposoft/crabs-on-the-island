class_name HealthBar

extends ProgressBar

@onready var label: Label = $healthNum
@onready var crab: Crab = get_parent()

var _visibility_triggered: bool

func _ready() -> void:
	DebugMode.on_change.connect(set_visible)
	crab.on_damage.connect(func() -> void: _visibility_triggered = true)


func _process(_delta: float) -> void:
	set_visible(DebugMode.enabled or _visibility_triggered)
	if !is_visible():
		return

	var hp: float = crab._HP
	var hp_percent: float = (hp / crab._stats_effective.hit_points) * 100.0
	set_value(hp_percent)
	label.set_text(str(hp))
