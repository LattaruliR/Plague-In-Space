extends Node2D

@export var pos_positions: Array[Marker2D] = []

@export var movetimer: Timer
@export var timer_time_left: int # in seconds pkrl

@export var ai_difficulty: int # 0 = disabled, 20 = always makes a move
@export var cur_position := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	print(timer_time_left)
	print(movetimer.wait_time)
	position = pos_positions[0].position
	movetimer.start(timer_time_left)

func _process(_delta: float) -> void:
	position = pos_positions[cur_position].position

func _on_movechance_timer_timeout() -> void:
	var randomValue = randi_range(1, 20)
	
	var effective_difficulty = ai_difficulty
	if CoreResources.plague_heat_aggro:
		effective_difficulty += 5 # Increase move chance significantly
	
	if (randomValue <= effective_difficulty):
		move()
	else:
		return

func move():
	var coin_flip = randi_range(1, 2)
	var triple_check = randi_range(1, 3)
	match cur_position:
		0: # Kitchen
			if (coin_flip == 1 || Global.panic == true):
				cur_position = 1
			else:	cur_position = 3

		1: # Power Grid
			if (coin_flip == 1 || Global.panic == true):
				cur_position = 2
			else:	cur_position = 0

		2: # Heat System
			if (coin_flip == 1 || Global.panic == true):
				cur_position = 4
			else:	cur_position = 1

		3: # Oxygen System
			if (coin_flip == 1 || Global.panic == true):
				cur_position = 4
			else:	cur_position = 0

		4: # Communication System
			if (triple_check == 1 || Global.panic == true):
				cur_position = 5
			elif (triple_check == 2):
				cur_position = 3
			else:
				cur_position = 2

		5: # Player Room
			if (coin_flip == 1 && Global.panic == true):
				return
			else:
				cur_position = 4


				# 1 -> Kitchen,   2 -> PowerGrid, 3 -> HeatSys, 
				# 4 -> OxygenSys, 5 -> CommsSys,  6 -> Player Room
