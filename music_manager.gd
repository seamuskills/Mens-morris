extends Button

var textures = [preload("res://sprites/music_off.png"), preload("res://sprites/music on.png")]
@onready var stream = $AudioStreamPlayer2D

func _on_pressed() -> void:
	stream.playing = not stream.playing
	icon = textures[int(stream.playing)]
