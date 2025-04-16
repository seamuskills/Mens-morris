extends Sprite2D

var boardPositions = [] #true for white false for black null for netiher
var boardSprites : Array[Sprite2D] = []
var piecehitbox : PackedScene = preload("res://piecehitbox.tscn")
var whiteTexture : Resource = load("res://sprites/stone_white.png")
var blackTexture : Resource = load("res://sprites/stone_black.png")
var winWindow = preload("res://win_window.tscn")
var winBlack = load("res://sprites/win_dialogue/blackWins.png")
var winWhite = load("res://sprites/win_dialogue/whiteWins.png")
var poof = preload("res://poof.tscn")
var turn : bool = true #same as boardPositions
var moving = null #position of piece being moved
var removing = false #removing something because the player made a mill?
var millsOnly = [false, false]
var reserve = [9, 9]
var placed = [0, 0]

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
	turnui.texture = whiteTexture if turn else blackTexture
	turnui.get_child(0).text = "x" + str(reserve[int(turn)])
	
	if reserve[0] + placed[0] == 0 or reserve[1] + placed[1] == 0:
		var window = winWindow.instantiate()
		if reserve[0] + placed[0] == 0:
			window.get_node("Base").texture = winBlack
		else:
			window.get_node("Base").texture = winWhite

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

func isAdjecent(x, y):
	if int(x / 3) == int(y / 3): #all horizontals
		return abs(x - y) == 1
	else:
		for mill in verticalMills:
			if x in mill and y in mill:
				return abs(x - y) < abs(mill[0] - mill[2])
		return false

func restart():
	boardPositions.clear()
	boardPositions.resize(24)
	updateSprites()
	turn = true
	moving = null
	removing = false
	reserve = [9, 9]
	placed = [0, 0]

func checkMillOnPos(position):
	if position == null: return false
	var isMill = false
	print(verticalMills)
	print(boardPositions)
	for mill in verticalMills:
		if position in mill:
			isMill = boardPositions[mill[0]] == boardPositions[mill[1]] && boardPositions[mill[1]] == boardPositions[mill[2]]
			if isMill: print(mill)
	
	if not isMill: #no vertical mill, check for horizontal
		var anchor = position - position % 3
		isMill = boardPositions[anchor] == boardPositions[anchor + 1] && boardPositions[anchor + 1] == boardPositions[anchor + 2]
		if isMill: print(str(anchor))
	
	return isMill

func on_piece_select(position: int) -> void:
	if removing:
		if boardPositions[position] == not turn and (not checkMillOnPos(position) or millsOnly[int(not turn)]):
			print("REMOVE PERMANENT")
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
			
	
	if reserve[0] + placed[0] <= 2:
		var window = winWindow.instantiate()
		window.get_node("Base").texture = winWhite
		get_tree().current_scene.add_child(window)
		print("WIN WHITE")
	elif reserve[1] + placed[1] <= 2:
		var window = winWindow.instantiate()
		window.get_node("Base").texture = winBlack
		get_tree().current_scene.add_child(window)
		print("WIN BLACK")
