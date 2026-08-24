extends Node2D

@export var pos_positions: Array[Marker2D] = []

@export var movetimer: Timer
@export var timer_time_left: int # in seconds pkrl

@export var ai_difficulty: int # 0 = disabled, 20 = always makes a move
@export var cur_position := 0

## Which rooms connect to which, indexed by Global.Room. This is the same graph
## move() walks below, pulled out so the blackout roam can reuse it.
const NEIGHBOURS := {
	0: [1, 3], # Kitchen      -> Power Grid, Oxygen
	1: [2, 0], # Power Grid   -> Heat, Kitchen
	2: [4, 1], # Heat         -> Comms, Power Grid
	3: [4, 0], # Oxygen       -> Comms, Kitchen
	4: [5, 3, 2], # Comms     -> Player Room, Oxygen, Heat
	5: [4], # Player Room     -> Comms
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	print(timer_time_left)
	print(movetimer.wait_time)
	position = pos_positions[0].position
	movetimer.start(timer_time_left)
	Blackout.register_plague(self)

func _process(_delta: float) -> void:
	position = pos_positions[cur_position].position

func _on_movechance_timer_timeout() -> void:
	# While the lights are out the Blackout manager drives the movement instead,
	# on its own faster clock.
	if Global.blackout:
		return

	var randomValue = randi_range(1, 20)

	var effective_difficulty = ai_difficulty
	if CoreResources.plague_heat_aggro:
		effective_difficulty += 5 # Increase move chance significantly

	# Every cure brewed makes it angrier.
	effective_difficulty += Global.cure_stage

	if (randomValue <= effective_difficulty):
		move()
		if cur_position == Global.Room.COMMS_SYS:
			Blackout.threat_warning.emit(Global.Room.COMMS_SYS)
	else:
		return

## One relocation while the ship is dark. It wanders the same graph, but it
## always moves, and it only slips into the player's room on a dice roll that
## panic makes much more generous.
func blackout_step() -> void:
	var options: Array = NEIGHBOURS.get(cur_position, []).duplicate()
	if options.is_empty():
		return

	var intrusion_chance := Blackout.INTRUSION_CHANCE
	if Global.panic:
		intrusion_chance = Blackout.INTRUSION_CHANCE_PANIC

	# Rooms other than the player's are always fair game; the player's room has
	# to win a roll first, otherwise it picks somewhere else.
	var safe_options: Array = []
	for room in options:
		if room != Global.player_room:
			safe_options.append(room)

	var wants_player_room: bool = options.has(Global.player_room) \
			and randf() < intrusion_chance

	if wants_player_room or safe_options.is_empty():
		cur_position = Global.player_room if options.has(Global.player_room) else options.pick_random()
	else:
		cur_position = safe_options.pick_random()

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
