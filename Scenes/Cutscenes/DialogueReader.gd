class_name DialogueReader
extends Node

@export_file("*.json") var dialogue_file: String

signal dialogue_ended

@export_category("UI")
@export var dialogue_label: Label
@export var speaker_label: Label
@export var next_button: Control

@export_category("Achievements")
@export var achiev_name: String
@export var achiev_id: String

@export_category("Typing")
@export var characters_per_second: float = 12.0

var dialogue_data: Array = []
var current_line: int = 0
var current_line_id: String = ""

const PLAYER_MOVES_1 = preload("uid://bvmqsc8abimy3")


var is_typing: bool = false
var typing_tween: Tween


func _ready() -> void:
	load_dialogue()

	if next_button:
		next_button.gui_input.connect(_on_next_button_input)


func load_dialogue() -> void:
	if dialogue_file.is_empty():
		push_error("No dialogue file assigned.")
		return

	if not FileAccess.file_exists(dialogue_file):
		push_error("Dialogue file not found: " + dialogue_file)
		return

	var file := FileAccess.open(dialogue_file, FileAccess.READ)

	if file == null:
		push_error("Could not open dialogue file.")
		return

	var text := file.get_as_text()
	file.close()

	var parsed_data = JSON.parse_string(text)

	if parsed_data == null:
		push_error("Could not parse dialogue JSON.")
		return

	if typeof(parsed_data) != TYPE_ARRAY:
		push_error("Dialogue JSON must contain an array.")
		return

	dialogue_data = parsed_data

	if dialogue_data.is_empty():
		push_warning("Dialogue file is empty.")
		return

	current_line = 0
	show_line()


func show_line() -> void:
	if current_line >= dialogue_data.size():
		end_dialogue()
		return

	var line: Dictionary = dialogue_data[current_line]

	var speaker: String = line.get("speaker", "")
	var text: String = line.get("text", "")
	current_line_id = line.get("id", "")

	if speaker_label:
		speaker_label.text = speaker

	if dialogue_label:
		dialogue_label.text = ""
		type_text(text)


func type_text(text: String) -> void:
	is_typing = true

	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()

	dialogue_label.text = text
	dialogue_label.visible_ratio = 0.0

	var duration := text.length() / characters_per_second

	typing_tween = create_tween()
	typing_tween.tween_property(
		dialogue_label,
		"visible_ratio",
		1.0,
		duration
	)

	typing_tween.finished.connect(_on_typing_finished)


func _on_typing_finished() -> void:
	is_typing = false


func advance_dialogue() -> void:
	AudioManager.play_sfx(PLAYER_MOVES_1)
	if is_typing:
		if typing_tween and typing_tween.is_valid():
			typing_tween.kill()

		dialogue_label.visible_ratio = 1.0
		is_typing = false
		return

	current_line += 1
	show_line()


func _on_next_button_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			advance_dialogue()
			check_achievements()

func check_achievements():
	if achiev_id.is_empty():
		return

	if current_line_id == achiev_name:
		Achievements.unlock(achiev_id)


func end_dialogue() -> void:
	dialogue_ended.emit()
	is_typing = false

	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()

	if dialogue_label:
		dialogue_label.text = ""

	if speaker_label:
		speaker_label.text = ""
