extends Node2D
const AMBIENT_PANIC = preload("uid://dklfhy3v605a8")
const BLACKOUT = preload("uid://8cajtyxcjxg7")
const CALM_OFFICE = preload("uid://s40st63lm2ws")

func _ready() -> void:
	AudioManager.play_music(CALM_OFFICE)
	GameOver.arm()
