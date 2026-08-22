extends Node

# -- Oxygen
var oxygen = 100 # minimum: 0%, max: 100%
var o_decay_step = 2 # 2 for normal, 3 for fast, 1 for slow, this gets multiplied when decreasing 
# -- Heat
var heat = 100 # mininum: 0, max: 100
# -- Power
var power = 5 # mininum: 0, max: 5

# -- Comms
var communication_combo: Array[int] = [] # Size 5
var comms_stage = 0 # 0 - No comms uploaded, 1 - One comm uploaded, so on
# -- Kitchen
var kitchen_combo: Array[int] = [] # Size 3 (R, G, B puzzle)
var kitchen_sum: Array[int] = [] # sum of the 3 separate numbers, [].sum method
var num_display := 0

# -- Player revelant variables --
var blackout := false # handles blackout state
var panic := false # handles if player is in a panic
var infection_value = 0 # max: 100, min: 0
var cure_stage := 0 # The higher the cure stage, the more aggro Plague has

# -- Plague relevant variables --
var aggro := 0 # Works similar to fnaf, the higher the value the easier it makes a move (max: 20 = makes a move every time, min: 0 = disabled)
var cur_pos = 0 # 0 -> Hidden
# 1 -> Kitchen,   2 -> PowerGrid, 3 -> HeatSys, 
# 4 -> OxygenSys, 5 -> CommsSys,  6 -> Player Room

var hunting := false
# var thecnology_breached = 0

# -- Menu --
var sfx_volume = 100
var music_volume = 100
var fullscreen := true
