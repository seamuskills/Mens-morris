extends Panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_go_pressed() -> void:
	get_tree().quit()
	

func _on_stay_pressed() -> void:
	queue_free()
