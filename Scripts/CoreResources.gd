extends Node

const ALERT_SOUND := preload("res://SOUNDS/barTone.wav")

# Oxygen
var oxygen: float = 100.0 # minimum: 0.0, max: 100.0
var o_decay_step: float = 1.0 # 2 for normal, 3 for fast, 1 for slow; this gets multiplied when decreasing
var oxygen_decay_base_rate: float = 1.0 / 3.0 # % per second (1% every 3 seconds)

var dry_zone_threshold: float = 80.0
var danger_zone_threshold: float = 50.0

var current_oxygen_zone: int = 0 # 0: Safe, 1: Dry, 2: Danger

func _process(delta: float) -> void:
	if oxygen > 0.0:
		oxygen -= oxygen_decay_base_rate * o_decay_step * delta
		if oxygen <= 0.0:
			oxygen = 0.0
			Global.panic = true
			
	_update_oxygen_zone()
	
	if heat > 0.0:
		heat -= heat_decay_base_rate * delta
		if heat < 0.0:
			heat = 0.0
			
	_update_heat_zone()

func _update_oxygen_zone() -> void:
	var new_zone = 0
	if oxygen < danger_zone_threshold:
		new_zone = 2
	elif oxygen < dry_zone_threshold:
		new_zone = 1
	else:
		new_zone = 0
		
	if new_zone != current_oxygen_zone:
		var zone_difference = new_zone - current_oxygen_zone
		Global.infection_step += zone_difference

		if Global.infection_step < 0:
			Global.infection_step = 0

		if new_zone == 2:
			Global.panic = true

		if zone_difference > 0: # got worse
			AudioManager.play_sfx(ALERT_SOUND, 0.0, 0.85 + 0.15 * new_zone)

		current_oxygen_zone = new_zone

# Heat
var heat: float = 100.0 # mininum: 0.0, max: 100.0
var heat_decay_base_rate: float = 0.5 # Losing 1% every 2 seconds
var current_heat_zone: int = 1 # 0: Hot, 1: Perfect, 2: Chilly, 3: Danger, 4: Death
var heat_reboot_cost: int = 1
var plague_heat_aggro: bool = false

# Power
var power: int = 5 # mininum: 0, max: 5

func deplete_charge(charge_cost: int):
	power -= charge_cost
	if power <= 0:
		Global.blackout = true
		AudioManager.play_sfx(ALERT_SOUND, 0.0, 0.6)

func reboot_system(is_heat_system: bool = false) -> void:
	var cost = 1
	if is_heat_system:
		cost = heat_reboot_cost

	if power >= cost:
		power -= cost
		if is_heat_system:
			heat = 85.0 # rebooting sets it to perfect zone
		AudioManager.play_sfx(ALERT_SOUND, 0.0, 1.3)
	else:
		print("not enough power to reboot")
		AudioManager.play_sfx(ALERT_SOUND, -4.0, 0.6)

	if power <= 0:
		Global.blackout = true
		AudioManager.play_sfx(ALERT_SOUND, 0.0, 0.6)

func _update_heat_zone() -> void:
	var new_zone = 1
	if heat >= 90.0:
		new_zone = 0 # Hot Zone
	elif heat >= 80.0:
		new_zone = 1 # Perfect Zone
	elif heat >= 60.0:
		new_zone = 2 # Chilly Zone
	elif heat >= 40.0:
		new_zone = 3 # Danger Zone
	else:
		new_zone = 4 # Death Zone
		
	if new_zone != current_heat_zone:
		# Reset modifiers
		o_decay_step = 1.0
		heat_reboot_cost = 1
		plague_heat_aggro = false
		
		# and apply penalties
		match new_zone:
			0: # Hot
				o_decay_step = 2.0
			1: # Perfect
				o_decay_step = 1.0
			2: # Chilly
				heat_reboot_cost = 2
			3: # Danger
				o_decay_step = 2.0
				plague_heat_aggro = true
			4: # Death
				o_decay_step = 4.0
				plague_heat_aggro = true

		if new_zone == 3 or new_zone == 4:
			AudioManager.play_sfx(ALERT_SOUND, 0.0, 0.85 + 0.15 * new_zone)

		current_heat_zone = new_zone

# Comms
var communication_combo: Array[int] = [] # Size 5
var comms_stage = 0 # 0 - No comms uploaded, 1 - One comm uploaded, so on
# Kitchen
var kitchen_combo: Array[int] = [] # Size 3 (R, G, B puzzle)
var kitchen_sum: Array[int] = [] # sum of the 3 separate numbers, [].sum method
var num_display := 0

func reset_systems() -> void:
	oxygen = 100.0
	current_oxygen_zone = 0
	o_decay_step = 1.0
	
	heat = 100.0
	current_heat_zone = 1
	heat_reboot_cost = 1
	plague_heat_aggro = false
	
	power = 5
