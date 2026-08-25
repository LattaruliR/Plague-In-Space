extends Node2D

@export var pos_positions: Array[Marker2D] = []

@export var movetimer: Timer
@export var cur_position := 0

@export var move_interval_base: float = 16.0
@export_range(0.0, 0.9, 0.05) var move_interval_jitter: float = 0.3
const MIN_MOVE_INTERVAL := 3.0

const AGGRO_PER_CURE := 0.35 # each dose brewed
const AGGRO_HEAT := 0.5 # heat sitting in the danger/death zone
const AGGRO_PANIC := 0.4 # the player is panicking
const AGGRO_LURE := 1.5 # it has somewhere to be

const NEIGHBOURS := {
	0: [1, 3], # Kitchen      -> Power Grid, Oxygen
	1: [2, 0], # Power Grid   -> Heat, Kitchen
	2: [4, 1], # Heat         -> Comms, Power Grid
	3: [4, 0], # Oxygen       -> Comms, Kitchen
	4: [5, 3, 2], # Comms     -> Player Room, Oxygen, Heat
	5: [4], # Player Room     -> Comms
}

const LURE_DURATION := 14.0
const LURE_COOLDOWN := 7.0

const SABOTAGE_BASE_CHANCE := 0.12
const SABOTAGE_PER_LURE := 0.09
const SABOTAGE_PER_CURE := 0.06
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
	movetimer.start(next_move_interval())
	Blackout.register_plague(self)

func _process(delta: float) -> void:
	position = pos_positions[cur_position].position

	if lure_cooldown_left > 0.0:
		lure_cooldown_left = maxf(lure_cooldown_left - delta, 0.0)

	if lure_target >= 0:
		lure_time_left -= delta
		if lure_time_left <= 0.0:
			_clear_lure()

func aggression() -> float:
	var value := 1.0 + AGGRO_PER_CURE * float(Global.cure_stage)
	if CoreResources.plague_heat_aggro:
		value += AGGRO_HEAT
	if Global.panic:
		value += AGGRO_PANIC
	if lure_target >= 0:
		value += AGGRO_LURE
	return value


## Seconds until its next relocation.
func next_move_interval() -> float:
	var jitter := randf_range(1.0 - move_interval_jitter, 1.0 + move_interval_jitter)
	return maxf(move_interval_base * jitter / aggression(), MIN_MOVE_INTERVAL)


func _on_movechance_timer_timeout() -> void:
	if not Global.blackout:
		move()
		_on_arrived()

	movetimer.start(next_move_interval())

func can_lure() -> bool:
	return lure_cooldown_left <= 0.0 and not Global.blackout

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

func _can_enter(room: int) -> bool:
	if room != Global.Room.PLAYER_ROOM:
		return true
	return not (Global.door_closed and Global.player_room == Global.Room.PLAYER_ROOM)

func _on_arrived() -> void:
	if cur_position == lure_target:
		_clear_lure()

	if cur_position == Global.player_room:
		Global.saw_player()
	else:
		_roll_sabotage()

	if cur_position == Global.Room.COMMS_SYS:
		Blackout.threat_warning.emit(Global.Room.COMMS_SYS)

func _roll_sabotage() -> void:
	if not CoreResources.sabotageable_rooms.has(cur_position):
		return
	if CoreResources.is_sabotaged(cur_position):
		return

	var chance := minf(
		SABOTAGE_BASE_CHANCE
			+ SABOTAGE_PER_LURE * float(Global.lure_streak)
			+ SABOTAGE_PER_CURE * float(Global.cure_stage),
		SABOTAGE_MAX_CHANCE)

	if randf() < chance and CoreResources.apply_sabotage(cur_position):
		Global.lure_streak = 0 # it spent the opportunity
		sabotage_committed.emit(cur_position)

func blackout_step() -> void:
	var options: Array = NEIGHBOURS.get(cur_position, []).duplicate()
	if options.is_empty():
		return

	if lure_target >= 0:
		var step := _step_toward(cur_position, lure_target)
		if step >= 0 and _can_enter(step):
			cur_position = step
			_on_arrived()
			return

	var intrusion_chance := Blackout.INTRUSION_CHANCE
	if Global.panic:
		intrusion_chance = Blackout.INTRUSION_CHANCE_PANIC

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
		var open_options: Array = []
		for room in options:
			if _can_enter(room):
				open_options.append(room)
		if open_options.is_empty():
			return
		cur_position = open_options.pick_random()

	_on_arrived()

func move():
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
