extends Node

const SAVE_PATH := "user://plague_in_space.json"
const VERSION := 1

const MODE_NORMAL := "normal"
const MODE_HARD := "hard"

signal loaded
signal best_time_beaten(mode: String, seconds: float)

var data := {}


func _ready() -> void:
	load_file()


func _defaults() -> Dictionary:
	return {
		"version": VERSION,
		"cure_found": false,
		"best_time": {
			MODE_NORMAL: null,
			MODE_HARD: null,
		},
		"runs": {
			"played": 0,
			"won": 0,
		},
		"achievements": [],
	}

func load_file() -> void:
	data = _defaults()

	if not FileAccess.file_exists(SAVE_PATH):
		loaded.emit()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Save unreadable (%s); starting fresh." % FileAccess.get_open_error())
		loaded.emit()
		return

	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file is not valid JSON; starting fresh.")
		loaded.emit()
		return

	_merge_into_data(parsed)
	loaded.emit()

func _merge_into_data(parsed: Dictionary) -> void:
	if typeof(parsed.get("cure_found")) == TYPE_BOOL:
		data["cure_found"] = parsed["cure_found"]

	var times: Variant = parsed.get("best_time")
	if typeof(times) == TYPE_DICTIONARY:
		for mode in [MODE_NORMAL, MODE_HARD]:
			var value: Variant = times.get(mode)
			if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
				data["best_time"][mode] = float(value)

	var runs: Variant = parsed.get("runs")
	if typeof(runs) == TYPE_DICTIONARY:
		for key in ["played", "won"]:
			if typeof(runs.get(key)) == TYPE_FLOAT or typeof(runs.get(key)) == TYPE_INT:
				data["runs"][key] = int(runs[key])

	var unlocked: Variant = parsed.get("achievements")
	if typeof(unlocked) == TYPE_ARRAY:
		var ids: Array = []
		for id in unlocked:
			if typeof(id) == TYPE_STRING and not ids.has(id):
				ids.append(id)
		data["achievements"] = ids


func save_file() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save (%s)." % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func mode_key(hard: bool) -> String:
	return MODE_HARD if hard else MODE_NORMAL

func best_time(hard: bool) -> float:
	var value: Variant = data["best_time"][mode_key(hard)]
	if value == null:
		return -1.0
	return float(value)


func has_best_time(hard: bool) -> bool:
	return best_time(hard) >= 0.0


func cure_found() -> bool:
	return data["cure_found"]


func runs_played() -> int:
	return data["runs"]["played"]


func runs_won() -> int:
	return data["runs"]["won"]


func unlocked_achievements() -> Array:
	return data["achievements"]

func record_run(won: bool, seconds: float, hard: bool) -> bool:
	data["runs"]["played"] = runs_played() + 1

	var beat_record := false
	if won:
		data["runs"]["won"] = runs_won() + 1
		data["cure_found"] = true

		var mode := mode_key(hard)
		var previous: Variant = data["best_time"][mode]
		if previous == null or seconds < float(previous):
			data["best_time"][mode] = seconds
			beat_record = true
			best_time_beaten.emit(mode, seconds)

	save_file()
	return beat_record


func mark_achievement(id: String) -> bool:
	if data["achievements"].has(id):
		return false
	data["achievements"].append(id)
	save_file()
	return true

func clear_all() -> void:
	data = _defaults()
	save_file()

static func format_time(seconds: float) -> String:
	if seconds < 0.0:
		return "--:--"
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]
