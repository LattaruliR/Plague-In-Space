extends Node2D
const AMBIENT_PANIC = preload("uid://dklfhy3v605a8")
const BLACKOUT = preload("uid://8cajtyxcjxg7")
const CALM_OFFICE = preload("uid://s40st63lm2ws")
const PRELUDE = preload("uid://n3j1nw15qwo1")

func _ready() -> void:
	$Camera.enabled = true
	Global.hasnt_started_night = true
	AudioManager.play_music(PRELUDE, 1.0)
	GameOver.arm()
	Archivist.arm()


func _on_start_night_pressed() -> void:
	_on_crank_button_pressed()
	_on_ghost_button_mouse_entered()
	Global.hasnt_started_night = false
	AudioManager.stop_music(1.0)
	AudioManager.play_music(CALM_OFFICE, 2.0)

func fade_info(sprite: Sprite2D):
	var tween := create_tween()
	tween.tween_property(sprite, "self_modulate", Color(0.0, 0.0, 0.0, 0.0), 3.0)

func _on_ghost_button_mouse_entered() -> void:
	$GhostMouse/GhostButton.hide()
	fade_info($GhostMouse)


func _on_crank_button_pressed() -> void:
	Archivist.winded += 1
	fade_info($GmHold)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("settings"):
		$OptionsUI.visible = !$OptionsUI.visible
