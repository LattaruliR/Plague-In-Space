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
