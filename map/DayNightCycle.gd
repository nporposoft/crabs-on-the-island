class_name DayNightCycle

extends CanvasModulate

@export var _colorGradient: GradientTexture1D

func _process(_delta: float) -> void:
	var gradientValue: float = 0.5 * sin(2 * PI * WorldClock.time - (PI / 2)) + 0.5
	color = _colorGradient.gradient.sample(gradientValue)
