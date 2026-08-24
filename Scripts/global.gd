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

var blackout := false # handles blackout state
var panic := false # handles if player is in a panic

# the office (player room) is home base
var player_room: int = Room.PLAYER_ROOM

var hiding := false
var hide_side: int = -1 # -1 not hidden, 0 left spot, 1 right spot

@warning_ignore("unused_signal") # emitted by blackout_manager.gd
signal player_caught

var infection_value: float = 0.0 # max: 100, min: 0
var infection_step: int = 0
var infection_base_rate: float = 0.5 # how much infection increases per second per step
var cure_stage := 0 # the higher the cure stage, the more aggro plague has

func _process(delta: float) -> void:
	if infection_step > 0 and infection_value < 100.0:
		infection_value += infection_base_rate * infection_step * delta
		if infection_value >= 100.0:
			infection_value = 100.0
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

func reset_player_state() -> void:
	blackout = false
	panic = false
	infection_value = 0.0
	infection_step = 0
	cure_stage = 0
	player_room = Room.PLAYER_ROOM
	hiding = false
	hide_side = -1
	hunting = false
