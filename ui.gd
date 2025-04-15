extends Control

@onready var quitButton = $QuitButton
@onready var quitWindow = $QuitWindow
var quitting = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("confirm"):
		if quitting:
			_on_go_pressed()
		
	if quitting:
		if Input.is_action_just_pressed("cancel"):
			_on_stay_pressed()
	else:
		if (Input.is_action_just_pressed("quit")):
			_on_quit_button_pressed()

func _on_quit_button_pressed() -> void:
	quitWindow.visible = true
	quitting = true


func _on_go_pressed() -> void:
	get_tree().quit()


func _on_stay_pressed() -> void:
	quitWindow.visible = false
	quitting = false
