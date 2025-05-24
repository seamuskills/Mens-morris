extends Sprite2D

var boardPositions = [] #true for white false for black null for netiher
var boardSprites : Array[Sprite2D] = []
var piecehitbox : PackedScene = preload("res://piecehitbox.tscn")
var whiteTexture : Resource = load("res://sprites/stone_white.png")
var blackTexture : Resource = load("res://sprites/stone_black.png")
var winWindow = preload("res://win_window.tscn")
var winBlack = load("res://sprites/win_dialogue/blackWins.png")
var winWhite = load("res://sprites/win_dialogue/whiteWins.png")
var turnIcons = [
	load("res://sprites/sideIcons/place_black.png"),
	load("res://sprites/sideIcons/place_white.png"),
	load("res://sprites/sideIcons/replace_black.png"),
	load("res://sprites/sideIcons/replace_white.png"),
	load("res://sprites/sideIcons/move_black.png"),
	load("res://sprites/sideIcons/move_white.png"),
	load("res://sprites/sideIcons/destroy_black.png"),
	load("res://sprites/sideIcons/destroy_white.png")
]
@onready var soundPlayer = $AudioStreamPlayer2D
var placeSound = load("res://sounds/place.wav")
var breakSound = load("res://sounds/destroy.wav")
var moveSound = load("res://sounds/move.wav")
var winSound = load("res://sounds/win.wav")
var poof = preload("res://poof.tscn")
var dir_poof = preload("res://directional_poof.tscn")
var turn : bool = true #same as boardPositions
var moving = null #position of piece being moved
var removing = false #removing something because the player made a mill?
var millsOnly = [false, false]
var reserve = [9, 9]
var placed = [0, 0]
var stuck = false
var done = false #did someone win the game?

const verticalMills = [
	[0, 9, 21],
	[3, 10, 18],
	[6, 11, 15],
	[1, 4, 7],
	[5, 13, 20],
	[2, 14, 23],
	[8, 12, 17],
	[16, 19, 22]
]

@onready var turnui = get_parent().get_node("turn")

#TODO: Make black use a truthy value so the mill detection works for black too

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boardPositions.resize(24)
	boardSprites.resize(24)
	for i in range(24):
		boardSprites[i] = get_node(str(i))
		boardSprites[i].texture = null
		var hitbox = piecehitbox.instantiate()
		hitbox.connect("pressed", func(): on_piece_select(i))
		boardSprites[i].add_child(hitbox)

func _process(delta: float) -> void:
	turnui.get_child(0).text = "x" + str(reserve[int(turn)])
	turnui.get_child(0).visible = reserve[int(turn)] > 0
	
	if reserve[0] + placed[0] == 0 or reserve[1] + placed[1] == 0:
		var window = winWindow.instantiate()
		if reserve[0] + placed[0] == 0:
			window.get_node("Base").texture = winBlack
		else:
			window.get_node("Base").texture = winWhite
			
	
	turnui.texture = turnIcons[int(turn)]
	if moving:
		turnui.texture = turnIcons[2 + int(turn)]
	elif removing:
		turnui.texture = turnIcons[6 + int(turn)]
	elif reserve[int(turn)] == 0:
		turnui.texture = turnIcons[4 + int(turn)]

func updateSprites() -> void:
	for position in range(24):
		if boardPositions[position] != null:
			boardSprites[position].texture = whiteTexture if boardPositions[position] else blackTexture
			boardSprites[position].modulate.a = 1
		else:
			if position == moving:
				boardSprites[position].modulate.a = 0.5
			else:
				boardSprites[position].texture = null
				boardSprites[position].modulate.a = 1

func isAdjecent(x : int, y : int):
	if int(x / 3) == int(y / 3): #all horizontals
		return abs(x - y) == 1
	else:
		for mill in verticalMills:
			if x in mill and y in mill:
				return abs(x - y) < abs(mill[0] - mill[2])
		return false
		
func getAdjecent(x : int):
	var positions = []
	for mill in verticalMills:
		if x in mill:
			var index = mill.find(x)
			if index > 0: positions.append(mill[index - 1])
			if index < 2: positions.append(mill[index + 1])
			break
	
	if x % 3 > 0: positions.append(x - 1)
	if x % 3 < 2: positions.append(x + 1)
	
	return positions

func restart():
	done = false
	boardPositions.clear()
	boardPositions.resize(24)
	updateSprites()
	turn = true
	moving = null
	removing = false
	stuck = false
	reserve = [9, 9]
	placed = [0, 0]

func checkMillOnPos(position : int):
	if position == null: return false
	var isMill = false
	for mill in verticalMills:
		if position in mill:
			isMill = boardPositions[mill[0]] == boardPositions[mill[1]] && boardPositions[mill[1]] == boardPositions[mill[2]]
	
	if not isMill: #no vertical mill, check for horizontal
		var anchor = position - position % 3
		isMill = boardPositions[anchor] == boardPositions[anchor + 1] && boardPositions[anchor + 1] == boardPositions[anchor + 2]
	
	return isMill

func on_piece_select(position: int) -> void:
	if done: return
	if removing:
		if boardPositions[position] == not turn and (not checkMillOnPos(position) or millsOnly[int(not turn)]):
			print("REMOVE PERMANENT")
			soundPlayer.stream = breakSound
			soundPlayer.play()
			var cloud = poof.instantiate()
			cloud.position = boardSprites[position].position
			cloud.emitting = true
			get_tree().current_scene.add_child(cloud)
			boardPositions[position] = null
			placed[int(not turn)] -= 1
			removing = false
			turn = not turn
	else:
		if boardPositions[position] == turn and reserve[int(turn)] == 0:
			print("REMOVE")
			boardPositions[position] = null
			moving = position
		elif moving != null and boardPositions[position] == null and isAdjecent(position, moving):
			print("MOVE")
			var particle = dir_poof.instantiate()
			particle.direction.x = sign(boardSprites[position].position.x - boardSprites[moving].position.x)
			particle.direction.y = sign(boardSprites[position].position.y - boardSprites[moving].position.y)
			particle.global_position = boardSprites[moving].global_position;
			particle.emitting = true
			get_parent().add_child(particle)
			soundPlayer.stream = moveSound
			soundPlayer.play()
			boardPositions[position] = turn
			moving = null
			if not checkMillOnPos(position):
				turn = not turn
			else:
				print("MILL")
				removing = true
		elif moving == position:
			print("REPLACE")
			boardPositions[position] = turn
			moving = null
		elif reserve[int(turn)] > 0 and boardPositions[position] == null and moving == null:
			print("PLACE")
			soundPlayer.stream = placeSound
			soundPlayer.play()
			boardPositions[position] = turn
			placed[int(turn)] += 1
			reserve[int(turn)] -= 1
			if not checkMillOnPos(position):
				turn = not turn
			else:
				print("MILL")
				removing = true
	updateSprites()
	
	millsOnly = [true, true]
	for pos in range(24):
		if boardPositions[pos] == false and not checkMillOnPos(pos):
			millsOnly[0] = false
		elif boardPositions[pos] == true and not checkMillOnPos(pos):
			millsOnly[1] = false
			

	#check if opponent is now out of options
	if reserve[int(turn)] == 0 and not removing:
		stuck = true
		for pos in range(24):
			if boardPositions[pos] == turn:
				for adjPos in getAdjecent(pos):
					if boardPositions[adjPos] == null:
						stuck = false
						break
	
	if reserve[0] + placed[0] <= 2 or (stuck and turn == false):
		var window = winWindow.instantiate()
		window.get_node("Base").texture = winWhite
		get_tree().current_scene.add_child(window)
		soundPlayer.stream = winSound
		soundPlayer.play()
		print("WIN WHITE")
		done = true
	elif reserve[1] + placed[1] <= 2 or (stuck and turn == true):
		var window = winWindow.instantiate()
		window.get_node("Base").texture = winBlack
		get_tree().current_scene.add_child(window)
		soundPlayer.stream = winSound
		soundPlayer.play()
		print("WIN BLACK")
		done = true


func _on_audio_stream_player_2d_finished() -> void:
	soundPlayer.pitch_scale = 1 * randf_range(0.5, 1.1)
