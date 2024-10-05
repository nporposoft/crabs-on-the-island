class_name DayNightCycle

extends CanvasModulate

@export var _colorGradient: GradientTexture1D
@export var _clock: WorldClock


func _process(delta: float) -> void:
	var gradientValue: float = 0.5 * sin(2 * PI * _clock.time - (PI / 2)) + 0.5
	color = _colorGradient.gradient.sample(gradientValue)
