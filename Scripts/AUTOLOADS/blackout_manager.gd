extends Node

const ALERT_SOUND := preload("res://SOUNDS/barTone.wav")
const TONE_SOUND := preload("res://SOUNDS/barTone2.wav")
const CLICK_SOUND := preload("res://SOUNDS/shutoutBlackout.wav")
const BLACKOUT = preload("uid://8cajtyxcjxg7")
const CALM_OFFICE = preload("uid://s40st63lm2ws")
const LURE_BROADCAST = preload("uid://cqneqee1ttis6")
const PLAGUE_OXYGEN = preload("uid://dwlthbsebu0cx")
const PLAGUE_WALK = preload("uid://b1d5cfp71sxoa")


## seconds the grid needs in the dark before it can be brought back online
var POWER_REBOOT_TIME := 25.0
## how often the plagues current room announces itself
const CLUE_INTERVAL := 2.6
## how often the plague relocates while the lights are off
const PLAGUE_MOVE_INTERVAL := 3.2
## odds the plague picks the player's room when that room is an option
const INTRUSION_CHANCE := 0.2
const INTRUSION_CHANCE_PANIC := 0.55
## how long the player has to be hidden on the right side once a hunt starts
const HUNT_DURATION := 6.5
const HUNT_CUE_INTERVAL := 1.6

## one sound clue per room, keyed by Global.Room - and toasted dont forget to swap these for dedicated sfx
## when they exist; the pitch shifts are only here to keep the six rooms tellable apart by ear
var room_clues := {}


signal blackout_started
signal blackout_ended
signal power_came_online
signal hunt_started
signal hunt_survived
signal restore_refused(reason: String)
signal threat_warning(room: int) # the plague reached somewhere that matters

## true while the grid has finished rebooting and the switch will actually work
var power_online := false
var reboot_elapsed := 0.0

var hunt_elapsed := 0.0

var _clue_elapsed := 0.0
var _move_elapsed := 0.0
var _hunt_cue_elapsed := 0.0
var _plague: Node = null
var _active := false # mirrors Global.blackout so its possible to catch external flips

var hm_multiplier := 0.0

func _ready() -> void:
	room_clues = {
		Global.Room.KITCHEN: {"stream": PLAGUE_WALK, "db": -8.0, "pitch": 0.55},
		Global.Room.POWER_GRID: {"stream": PLAGUE_WALK, "db": -10.0, "pitch": 0.45},
		Global.Room.HEAT_SYS: {"stream": PLAGUE_WALK, "db": -12.0, "pitch": 1.7},
		Global.Room.OXYGEN_SYS: {"stream": PLAGUE_WALK, "db": -10.0, "pitch": 1.25},
		Global.Room.COMMS_SYS: {"stream": PLAGUE_WALK, "db": -8.0, "pitch": 1.55},
		Global.Room.PLAYER_ROOM: {"stream": PLAGUE_WALK, "db": -6.0, "pitch": 0.35},
	}

func register_plague(plague: Node) -> void:
	_plague = plague

## The Plague node, or null before the Game scene has loaded.
func get_plague() -> Node:
	return _plague


func _process(delta: float) -> void:
	POWER_REBOOT_TIME = 15.0 if Global.hard_mode == true else 25.0
	if Global.blackout != _active:
		if Global.blackout:
			_start_blackout_state()
		else:
			_active = false
			
	if Global.hunting:
		_tick_hunt(delta)

	if not Global.blackout:
		return

	if not power_online:
		reboot_elapsed += delta
		if reboot_elapsed >= POWER_REBOOT_TIME:
			power_online = true
			AudioManager.play_sfx(TONE_SOUND, -4.0, 1.9)
			power_came_online.emit()

	if not Global.hunting:
		_tick_roaming(delta)

	_tick_clues(delta)

func toggle_switch() -> void:
	if Global.blackout:
		try_restore_power()
	else:
		begin_blackout()


func begin_blackout() -> void:
	if Global.blackout:
		return

	Global.blackout = true
	_start_blackout_state()


func _start_blackout_state() -> void:
	AudioManager.stop_music()
	AudioManager.play_music(BLACKOUT, 0.2)
	_active = true
	CoreResources.power = 0
	power_online = false
	reboot_elapsed = 0.0
	_clue_elapsed = 0.0
	_move_elapsed = 0.0

	AudioManager.play_sfx(ALERT_SOUND, 0.0, 0.35)
	blackout_started.emit()

func try_restore_power() -> bool:
	if not Global.blackout:
		return false

	if Global.hunting:
		AudioManager.play_sfx(ALERT_SOUND, -4.0, 0.3)
		#restore_refused.emit("IT IS IN HERE WITH YOU")
		return false

	if not power_online:
		var remaining := int(ceil(POWER_REBOOT_TIME - reboot_elapsed))
		AudioManager.play_sfx(ALERT_SOUND, -6.0, 0.4)
		#restore_refused.emit("GRID REBOOTING - %ds" % remaining)
		return false

	if _plague_room() == Global.player_room:
		AudioManager.play_sfx(ALERT_SOUND, -4.0, 0.3)
		#restore_refused.emit("SOMETHING IS IN THE ROOM")
		return false

	_end_blackout()
	return true


func _end_blackout() -> void:
	AudioManager.stop_music()
	AudioManager.play_music(CALM_OFFICE, 0.8)
	Global.blackout = false
	_active = false
	Global.hunting = false
	hunt_elapsed = 0.0
	power_online = false
	reboot_elapsed = 0.0

	CoreResources.power = CoreResources.max_power()

	if _plague != null:
		_plague.cur_position = Global.Room.KITCHEN

	AudioManager.play_sfx(TONE_SOUND, -2.0, 1.6)
	blackout_ended.emit()


func _tick_roaming(delta: float) -> void:
	if _plague == null:
		return

	_move_elapsed += delta
	if _move_elapsed < PLAGUE_MOVE_INTERVAL:
		return
	_move_elapsed = 0.0

	_plague.blackout_step()

	if _plague_room() == Global.player_room:
		_begin_hunt()


func _tick_clues(delta: float) -> void:
	_clue_elapsed += delta
	if _clue_elapsed < CLUE_INTERVAL:
		return
	_clue_elapsed = 0.0

	if Global.hunting:
		return # the hunt cue takes over

	play_room_clue(_plague_room())

func play_room_clue(room: int) -> void:
	if not room_clues.has(room):
		return
	var clue: Dictionary = room_clues[room]
	AudioManager.play_sfx(clue["stream"], clue["db"], clue["pitch"])

func _begin_hunt() -> void:
	if Global.door_closed and Global.player_room == Global.Room.PLAYER_ROOM:
		return # it cannot get through the blast door

	Global.hunting = true
	hunt_elapsed = 0.0
	_hunt_cue_elapsed = HUNT_CUE_INTERVAL

	AudioManager.play_sfx(ALERT_SOUND, 0.0, 0.25)
	hunt_started.emit()


func _tick_hunt(delta: float) -> void:
	hunt_elapsed += delta

	_hunt_cue_elapsed += delta
	if _hunt_cue_elapsed >= HUNT_CUE_INTERVAL:
		_hunt_cue_elapsed = 0.0
		_play_hunt_cue()

	if hunt_elapsed >= HUNT_DURATION:
		_resolve_hunt()


func _play_hunt_cue() -> void:
	AudioManager.play_sfx(CLICK_SOUND, -2.0, 0.4)


func _resolve_hunt() -> void:
	var safe = Global.hiding and Global.player_room == Global.Room.PLAYER_ROOM

	Global.hunting = false
	hunt_elapsed = 0.0

	if safe:
		if _plague != null:
			var elsewhere: Array[int] = []
			for room in Global.ROOM_NAMES:
				if room != Global.Room.PLAYER_ROOM:
					elsewhere.append(room)
			_plague.cur_position = elsewhere.pick_random()
		AudioManager.play_sfx(TONE_SOUND, -6.0, 0.8)
		hunt_survived.emit()
	else:
		_catch_player()


func _catch_player() -> void:
	Global.hiding = false
	Global.hide_side = -1
	Global.infection_value = 100.0
	Global.panic = true
	AudioManager.play_sfx(ALERT_SOUND, 2.0, 0.2)
	Global.player_caught.emit()

func set_hiding(side: int, is_hiding: bool) -> void:
	Global.hiding = is_hiding
	Global.hide_side = side if is_hiding else -1
	AudioManager.play_sfx(CLICK_SOUND, -10.0, 0.8 if is_hiding else 1.2)

func _plague_room() -> int:
	if _plague == null:
		return -1
	return _plague.cur_position

func reboot_remaining() -> float:
	if power_online:
		return 0.0
	return maxf(POWER_REBOOT_TIME - reboot_elapsed, 0.0)


func reset() -> void:
	Global.blackout = false
	_active = false
	Global.hunting = false
	Global.hiding = false
	Global.hide_side = -1
	power_online = false
	reboot_elapsed = 0.0
	hunt_elapsed = 0.0
	_clue_elapsed = 0.0
	_move_elapsed = 0.0
	_hunt_cue_elapsed = 0.0
