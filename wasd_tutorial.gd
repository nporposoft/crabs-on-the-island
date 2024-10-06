extends Node2D

@onready var W: AnimatedSprite2D = $W

var fading = false
var fadeOut = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if fading:
		fadeOut -= delta
		W.set_modulate(Color(1.0, 1.0, 1.0, fadeOut))
	if fadeOut <= 0:
		queue_free()


func _on_timer_timeout():
	if !W.is_visible():
		W.set_visible(true)
	else:
		fading = true
