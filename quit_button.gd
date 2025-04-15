extends Button

@onready var window = preload("res://quit_window.tscn")

func _on_pressed() -> void:
	var newWindow = window.instantiate()
	get_tree().current_scene.add_child(newWindow)
