extends Node


enum Room {
	KITCHEN,
	POWER_GRID,
	HEAT_SYS,
	OXYGEN_SYS,
	COMMS_SYS,
	PLAYER_ROOM,
}

const ROOM_NAMES := {
	Room.KITCHEN: "KITCHEN",
	Room.POWER_GRID: "POWER GRID",
	Room.HEAT_SYS: "HEAT SYSTEM",
	Room.OXYGEN_SYS: "OXYGEN SYSTEM",
	Room.COMMS_SYS: "COMMUNICATION ROOM",
	Room.PLAYER_ROOM: "OFFICE",
}

var hard_mode := false
var cure_found := false

var blackout := false # handles blackout state
var panic := false # handles if player is in a panic

# the office (player room) is home base
var player_room: int = Room.PLAYER_ROOM

var hiding := false
var hide_side: int = -1 # -1 not hidden, 0 left spot, 1 right spot

# the office blast door. shut it and nothing gets in, but the air goes stale
var door_closed := false

# lures played since the Plague last laid eyes on the player. the longer the
# player goes unseen while pulling it around the ship, the bolder it gets about
# sabotaging something on the way
var lure_streak := 0

@warning_ignore("unused_signal") # emitted by blackout_manager.gd
signal player_caught

var infection_value: float = 0.0 # max: 100, min: 0

const INF_OXYGEN_DRY := 0.4
const INF_OXYGEN_DANGER := 0.9
const INF_HEAT_CHILLY := 0.1
const INF_HEAT_DANGER := 0.4
const INF_HEAT_DEATH := 0.8
const INF_PER_SABOTAGE := 0.25
const INF_DOOR_SEALED := 0.5
const INF_RECOVERY := -0.2

const HARD_INFECTION_MULT := 1.5

func infection_multiplier() -> float:
	return HARD_INFECTION_MULT if hard_mode else 1.0
var cure_stage := 0 # the higher the cure stage, the more aggro plague has
						
func infection_contributions() -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	match CoreResources.current_oxygen_zone:
		1: out.append({"label": "OXYGEN DRY", "rate": INF_OXYGEN_DRY})
		2: out.append({"label": "OXYGEN DANGER", "rate": INF_OXYGEN_DANGER})

	match CoreResources.current_heat_zone:
		2: out.append({"label": "HEAT CHILLY", "rate": INF_HEAT_CHILLY})
		3: out.append({"label": "HEAT DANGER", "rate": INF_HEAT_DANGER})
		4: out.append({"label": "HEAT DEATH", "rate": INF_HEAT_DEATH})

	for room in CoreResources.sabotaged:
		out.append({
			"label": "%s SABOTAGED" % ROOM_NAMES.get(room, "SYSTEM"),
			"rate": INF_PER_SABOTAGE,
		})

	if door_closed:
		out.append({"label": "DOOR SEALED", "rate": INF_DOOR_SEALED})

	if out.is_empty() and CoreResources.current_heat_zone == 1:
		# Nominal: oxygen SAFE, heat PERFECT, nothing broken, door open.
		out.append({"label": "ALL NOMINAL", "rate": INF_RECOVERY})

	return out

func infection_rate() -> float:
	var harm := 0.0
	var relief := 0.0
	for c in infection_contributions():
		if c["rate"] > 0.0:
			harm += c["rate"]
		else:
			relief += c["rate"]
	return harm * infection_multiplier() + relief


func _process(delta: float) -> void:
	if infection_value >= 100.0:
		return

	infection_value = clampf(infection_value + infection_rate() * delta, 0.0, 100.0)
	if infection_value >= 100.0:
		panic = true
			

var cur_pos = 0 # 0 -> Hidden
				# 1 -> Kitchen,   2 -> PowerGrid, 3 -> HeatSys, 
				# 4 -> OxygenSys, 5 -> CommsSys,  6 -> Player Room

var hunting := false
# var thecnology_breached = 0

var sfx_volume = 100
var music_volume = 100
var fullscreen := true
var scanlines := true

## the plague has eyes on the player: it stops trusting the lures
func saw_player() -> void:
	lure_streak = 0


func reset_player_state() -> void:
	blackout = false
	panic = false
	infection_value = 0.0
	cure_stage = 0
	player_room = Room.PLAYER_ROOM
	hiding = false
	hide_side = -1
	hunting = false
	door_closed = false
	lure_streak = 0
