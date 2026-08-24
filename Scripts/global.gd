extends Node


# -- Player revelant variables --
var blackout := false # handles blackout state
var panic := false # handles if player is in a panic

# -- Infection relevant variables
var infection_value: float = 0.0 # max: 100, min: 0
var infection_step: int = 0 # Increases when player makes mistakes (e.g. low oxygen)
var infection_base_rate: float = 0.5 # How much infection increases per second per step
var cure_stage := 0 # The higher the cure stage, the more aggro Plague has

func _process(delta: float) -> void:
	if infection_step > 0 and infection_value < 100.0:
		infection_value += infection_base_rate * infection_step * delta
		if infection_value >= 100.0:
			infection_value = 100.0
			panic = true

# -- ENEMY relevant variables --
var cur_pos = 0 # 0 -> Hidden
				# 1 -> Kitchen,   2 -> PowerGrid, 3 -> HeatSys, 
				# 4 -> OxygenSys, 5 -> CommsSys,  6 -> Player Room

var hunting := false
# var thecnology_breached = 0

# -- Menu --
var sfx_volume = 100
var music_volume = 100
var fullscreen := true
var scanlines := true

func reset_player_state() -> void:
	blackout = false
	panic = false
	infection_value = 0.0
	infection_step = 0
