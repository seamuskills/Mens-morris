extends Panel

func _on_dont_pressed() -> void:
	queue_free()


func _on_restart_pressed() -> void:
	var board = get_parent().get_node("GameManager").get_node("Board")
	board.restart()
	queue_free()
