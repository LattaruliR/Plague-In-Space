extends Node2D

@export var pos_positions: Array[Marker2D] = []

@export var movetimer: Timer
@export var timer_time_left: int # in seconds pkrl

@export var ai_difficulty: int # 0 = disabled, 20 = always makes a move
@export var cur_position := 0

## Which rooms connect to which, indexed by Global.Room. This is the same graph
## move() walks below, pulled out so the blackout roam and the lure pathing can
## reuse it.
const NEIGHBOURS := {
	0: [1, 3], # Kitchen      -> Power Grid, Oxygen
	1: [2, 0], # Power Grid   -> Heat, Kitchen
	2: [4, 1], # Heat         -> Comms, Power Grid
	3: [4, 0], # Oxygen       -> Comms, Kitchen
	4: [5, 3, 2], # Comms     -> Player Room, Oxygen, Heat
	5: [4], # Player Room     -> Comms
}

# -- Lures --
## How long a played lure keeps pulling it, in seconds.
const LURE_DURATION := 14.0
## The player cannot spam the speaker.
const LURE_COOLDOWN := 7.0

# -- Security Breach --
## Odds it wrecks the room it just walked into, before lures are counted.
const SABOTAGE_BASE_CHANCE := 0.06
## Every lure played since it last saw the player makes it bolder.
const SABOTAGE_PER_LURE := 0.09
const SABOTAGE_MAX_CHANCE := 0.75

var lure_target: int = -1
var lure_time_left := 0.0
var lure_cooldown_left := 0.0

signal lure_played(room: int)
signal lure_expired
signal sabotage_committed(room: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = pos_positions[0].position
	movetimer.start(timer_time_left)
	Blackout.register_plague(self)

func _process(delta: float) -> void:
	position = pos_positions[cur_position].position

	if lure_cooldown_left > 0.0:
		lure_cooldown_left = maxf(lure_cooldown_left - delta, 0.0)

	if lure_target >= 0:
		lure_time_left -= delta
		if lure_time_left <= 0.0:
			_clear_lure()

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

	# A lure gives it somewhere to be, so it stops dithering.
	if lure_target >= 0:
		effective_difficulty += 6

	if (randomValue <= effective_difficulty):
		move()
		_on_arrived()

# -- Lures (FNAF-style: pull it somewhere and hope it takes the bait) --

func can_lure() -> bool:
	return lure_cooldown_left <= 0.0 and not Global.blackout

## Plays a noise in `room` and points the Plague at it. Each lure the player
## gets away with makes the next sabotage roll more dangerous.
func play_lure(room: int) -> bool:
	if not can_lure():
		return false
	if room == cur_position:
		return false

	lure_target = room
	lure_time_left = LURE_DURATION
	lure_cooldown_left = LURE_COOLDOWN
	Global.lure_streak += 1

	Blackout.play_room_clue(room)
	lure_played.emit(room)
	return true

func _clear_lure() -> void:
	if lure_target < 0:
		return
	lure_target = -1
	lure_time_left = 0.0
	lure_expired.emit()

## First hop along the shortest path from `from` to `to`, or -1 if unreachable.
func _step_toward(from: int, to: int) -> int:
	if from == to:
		return -1

	var came_from := {from: -1}
	var queue: Array[int] = [from]
	while not queue.is_empty():
		var node: int = queue.pop_front()
		if node == to:
			break
		for next in NEIGHBOURS.get(node, []):
			if not came_from.has(next):
				came_from[next] = node
				queue.append(next)

	if not came_from.has(to):
		return -1

	var step: int = to
	while came_from[step] != from:
		step = came_from[step]
		if step == -1:
			return -1
	return step

## The office door being shut is a hard wall: it simply cannot come in.
func _can_enter(room: int) -> bool:
	if room != Global.Room.PLAYER_ROOM:
		return true
	return not (Global.door_closed and Global.player_room == Global.Room.PLAYER_ROOM)

## Called after any relocation, blackout or not.
func _on_arrived() -> void:
	if cur_position == lure_target:
		_clear_lure()

	if cur_position == Global.player_room:
		# It has eyes on the player, so the lure streak is spent.
		Global.saw_player()
	else:
		_roll_sabotage()

	if cur_position == Global.Room.COMMS_SYS:
		Blackout.threat_warning.emit(Global.Room.COMMS_SYS)

## Security Breach: the more lures the player has pulled off unseen, the more
## likely it is to break whatever is in the room it just reached.
func _roll_sabotage() -> void:
	if not CoreResources.sabotageable_rooms.has(cur_position):
		return
	if CoreResources.is_sabotaged(cur_position):
		return

	var chance := minf(
		SABOTAGE_BASE_CHANCE + SABOTAGE_PER_LURE * float(Global.lure_streak),
		SABOTAGE_MAX_CHANCE)

	if randf() < chance and CoreResources.apply_sabotage(cur_position):
		Global.lure_streak = 0 # it spent the opportunity
		sabotage_committed.emit(cur_position)

## One relocation while the ship is dark. It wanders the same graph, but it
## always moves, and it only slips into the player's room on a dice roll that
## panic makes much more generous.
func blackout_step() -> void:
	var options: Array = NEIGHBOURS.get(cur_position, []).duplicate()
	if options.is_empty():
		return

	# A lure still works in the dark, and it is the whole point of the mechanic.
	if lure_target >= 0:
		var step := _step_toward(cur_position, lure_target)
		if step >= 0 and _can_enter(step):
			cur_position = step
			_on_arrived()
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
			and _can_enter(Global.player_room) \
			and randf() < intrusion_chance

	if wants_player_room:
		cur_position = Global.player_room
	elif not safe_options.is_empty():
		cur_position = safe_options.pick_random()
	else:
		# Nowhere else to go; stay put rather than walk through a shut door.
		var open_options: Array = []
		for room in options:
			if _can_enter(room):
				open_options.append(room)
		if open_options.is_empty():
			return
		cur_position = open_options.pick_random()

	_on_arrived()

func move():
	# Being lured overrides the wander graph.
	if lure_target >= 0:
		var step := _step_toward(cur_position, lure_target)
		if step >= 0 and _can_enter(step):
			cur_position = step
			return

	var coin_flip = randi_range(1, 2)
	var triple_check = randi_range(1, 3)
	var wanted := cur_position

	match cur_position:
		0: # Kitchen
			if (coin_flip == 1 || Global.panic == true):
				wanted = 1
			else:	wanted = 3

		1: # Power Grid
			if (coin_flip == 1 || Global.panic == true):
				wanted = 2
			else:	wanted = 0

		2: # Heat System
			if (coin_flip == 1 || Global.panic == true):
				wanted = 4
			else:	wanted = 1

		3: # Oxygen System
			if (coin_flip == 1 || Global.panic == true):
				wanted = 4
			else:	wanted = 0

		4: # Communication System
			if (triple_check == 1 || Global.panic == true):
				wanted = 5
			elif (triple_check == 2):
				wanted = 3
			else:
				wanted = 2

		5: # Player Room
			if (coin_flip == 1 && Global.panic == true):
				return
			else:
				wanted = 4

	if _can_enter(wanted):
		cur_position = wanted
