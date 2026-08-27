extends Node2D

const INFECTION_PER_SECOND := 0.5

const SHUT_SOUND := preload("res://SOUNDS/barTone2.wav")
const OPEN_SOUND := preload("res://SOUNDS/selecting.wav")

@export var door_sprite: AnimatedSprite2D
@export var handle_sprite: AnimatedSprite2D
@export var handle_button: Button
@export var leave_button: Button

func _ready() -> void:
	if handle_button != null and not handle_button.pressed.is_connected(toggle):
		handle_button.pressed.connect(toggle)
	if leave_button != null and not leave_button.pressed.is_connected(_on_leave_pressed):
		leave_button.pressed.connect(_on_leave_pressed)

	Global.door_closed = false
	_apply_visuals(false)


func _process(delta: float) -> void:
	if not Global.door_closed:
		return

	Global.infection_value = minf(
		Global.infection_value + INFECTION_PER_SECOND * Global.infection_multiplier() * delta,
		100.0)
	if Global.infection_value >= 100.0:
		Global.panic = true


func toggle() -> void:
	if Global.hunting:
		AudioManager.play_sfx(OPEN_SOUND, -8.0, 0.4)
		return

	set_closed(not Global.door_closed)


func set_closed(closed: bool) -> void:
	if Global.door_closed == closed:
		return

	Global.door_closed = closed
	_apply_visuals(true)
	AudioManager.play_sfx(SHUT_SOUND if closed else OPEN_SOUND, -4.0, 0.6 if closed else 1.0)


func _on_leave_pressed() -> void:
	Rooms.open_travel_menu()


func _apply_visuals(animate: bool) -> void:
	if door_sprite != null and door_sprite.sprite_frames != null:
		var anim := ""
		if animate:
			anim = "closing" if Global.door_closed else "opening"
		else:
			anim = "idleClosed" if Global.door_closed else "idleOpen"
		if door_sprite.sprite_frames.has_animation(anim):
			door_sprite.play(anim)

	if handle_sprite != null and handle_sprite.sprite_frames != null:
		var handle_anim := "pressingDown" if Global.door_closed else "goingUp"
		if handle_sprite.sprite_frames.has_animation(handle_anim):
			handle_sprite.play(handle_anim)
