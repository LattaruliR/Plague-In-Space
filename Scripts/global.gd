extends Node


# -- Player revelant variables --
var blackout := false # handles blackout state
var panic := false # handles if player is in a panic

# -- Infection relevant variables
var infection_value = 0 # max: 100, min: 0
var cure_stage := 0 # The higher the cure stage, the more aggro Plague has

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
