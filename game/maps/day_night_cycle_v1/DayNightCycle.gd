class_name DayNightCycle

extends CanvasModulate

@export var _colorGradient: GradientTexture1D
@onready var scenario: Scenario = get_parent()
var _clock: Clock


func _ready() -> void:
	scenario.clock_init.connect(_init_clock)


func _init_clock(clock: Clock) -> void:
	_clock = clock


func _process(_delta: float) -> void:
	var gradientValue: float = 0.5 * sin(2 * PI * _clock.time - (PI / 2)) + 0.5
	color = _colorGradient.gradient.sample(gradientValue)
