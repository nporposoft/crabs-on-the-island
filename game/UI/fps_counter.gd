extends Label


func _ready() -> void:
	DebugMode.on_change.connect(set_visible)


func _process(_delta: float) -> void:
	set_text(str(Engine.get_frames_per_second()) + " fps")
