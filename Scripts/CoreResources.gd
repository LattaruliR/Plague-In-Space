extends Node

const ALERT_SOUND := preload("res://SOUNDS/barTone.wav")

# Oxygen
var oxygen: float = 100.0 # minimum: 0.0, max: 100.0
var o_decay_step: float = 1.0 # 2 for normal, 3 for fast, 1 for slow; this gets multiplied when decreasing
var oxygen_decay_base_rate: float = 1.0 / 3.0 # % per second (1% every 3 seconds)

var dry_zone_threshold: float = 80.0
var danger_zone_threshold: float = 50.0

var current_oxygen_zone: int = 0 # 0: Safe, 1: Dry, 2: Danger

#  this is the extra bleeding of every system on top of its normal decay during blackout
const BLACKOUT_OXYGEN_LEAK: float = 1.0 / 1.5 # extra % per second
const BLACKOUT_HEAT_LEAK: float = 1.0 # extra % per second

func _process(delta: float) -> void:
	var leaking := Global.blackout

	if oxygen > 0.0:
		oxygen -= oxygen_decay_base_rate * o_decay_step * delta
		if leaking:
			oxygen -= BLACKOUT_OXYGEN_LEAK * delta
		if oxygen <= 0.0:
			oxygen = 0.0
			Global.panic = true
			
	_update_oxygen_zone()
	
	if heat > 0.0:
		heat -= heat_decay_base_rate * delta
		if leaking:
			heat -= BLACKOUT_HEAT_LEAK * delta
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
const MAX_POWER: int = 5
var power: int = 5 # mininum: 0, max: 5

func deplete_charge(charge_cost: int):
	power -= charge_cost
	if power <= 0:
		power = 0
		Global.blackout = true
		AudioManager.play_sfx(ALERT_SOUND, 0.0, 0.6)

func reboot_system(is_heat_system: bool = false) -> void:
	if Global.blackout:
		AudioManager.play_sfx(ALERT_SOUND, -6.0, 0.4)
		return

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
const MANUAL_COUNT := 3 # how many manuals make a complete cure
const COMMS_SEQUENCE_LENGTH := 5 # symbols in a broadcast
const COMMS_SYMBOL_COUNT := 4 # how many distinct symbols the keypad offers

var communication_combo: Array[int] = [] # Size 5
var comms_stage = 0 # 0 - no comms uploaded, 1 - one comm uploaded, so on

signal manual_downloaded(stage: int)
signal recipe_unlocked(index: int)
signal cure_produced(count: int)

func roll_communication_combo() -> Array[int]:
	communication_combo.clear()
	for i in COMMS_SEQUENCE_LENGTH:
		communication_combo.append(randi() % COMMS_SYMBOL_COUNT)
	return communication_combo

func check_communication_combo(input: Array[int]) -> bool:
	if input.size() != communication_combo.size():
		return false
	for i in input.size():
		if input[i] != communication_combo[i]:
			return false
	return true

func complete_manual_download() -> void:
	if comms_stage >= MANUAL_COUNT:
		return

	var index: int = comms_stage
	comms_stage += 1
	unlocked_recipes.append(index)
	manual_downloaded.emit(comms_stage)
	recipe_unlocked.emit(index)
	AudioManager.play_sfx(ALERT_SOUND, 0.0, 1.6)

# Kitchen
# every manual carries one recipe; three dial values the player has to mix
# the recipes are rolled once per run so a player cannot memorise them
const KITCHEN_DIAL_MAX := 9 # dials run 0..9
const CURE_CHARGE_COST := 1

var kitchen_combo: Array[int] = [] # Size 3 (R, G, B puzzle)
var kitchen_sum: Array[int] = [] # sum of the 3 separate numbers, [].sum method
var num_display := 0

var recipes: Array = [] # one Array[int] of 3 dial values per manual
var unlocked_recipes: Array[int] = [] # indices into recipes the player has read
var produced_recipes: Array[int] = [] # indices the player has already cooked

func roll_recipes() -> void:
	recipes.clear()
	for i in MANUAL_COUNT:
		var recipe: Array[int] = []
		for d in 3:
			recipe.append(randi() % (KITCHEN_DIAL_MAX + 1))
		recipes.append(recipe)

func get_recipe(index: int) -> Array:
	if index < 0 or index >= recipes.size():
		return []
	return recipes[index]

func get_pending_recipes() -> Array[int]:
	var pending: Array[int] = []
	for index in unlocked_recipes:
		if not produced_recipes.has(index):
			pending.append(index)
	return pending

func try_produce_cure(input: Array[int]) -> int:
	if Global.blackout:
		AudioManager.play_sfx(ALERT_SOUND, -6.0, 0.4)
		return -1

	if power < CURE_CHARGE_COST:
		print("not enough power to produce")
		AudioManager.play_sfx(ALERT_SOUND, -4.0, 0.6)
		return -1

	for index in get_pending_recipes():
		if _matches_recipe(input, recipes[index]):
			deplete_charge(CURE_CHARGE_COST)
			produced_recipes.append(index)
			Global.cure_stage += 1
			cure_produced.emit(produced_recipes.size())
			AudioManager.play_sfx(ALERT_SOUND, 0.0, 1.8)
			return index

	AudioManager.play_sfx(ALERT_SOUND, -4.0, 0.5)
	return -1

func _matches_recipe(input: Array, recipe: Array) -> bool:
	if input.size() != recipe.size():
		return false
	for i in input.size():
		if input[i] != recipe[i]:
			return false
	return true

func reset_systems() -> void:
	oxygen = 100.0
	current_oxygen_zone = 0
	o_decay_step = 1.0
	
	heat = 100.0
	current_heat_zone = 1
	heat_reboot_cost = 1
	plague_heat_aggro = false
	
	power = MAX_POWER

	communication_combo.clear()
	comms_stage = 0

	kitchen_combo = [0, 0, 0]
	kitchen_sum.clear()
	num_display = 0
	unlocked_recipes.clear()
	produced_recipes.clear()
	roll_recipes()
