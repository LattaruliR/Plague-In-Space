class_name JumpscareHolder
extends Node2D

signal jumpscare_finished
const PLAGUE_ALTERNATE = preload("uid://cqneqee1ttis6")
const PLAGUE_LAUGH_1 = preload("uid://b2l86sbpurpo3")
@onready var jumpscare_audio: AudioStreamPlayer = $JumpscareAudio
@onready var jumpscare_sprite: AnimatedSprite2D = $JumpscareSprite


func jumpscare_params(request: String):
	match request:
		"plague":
			jumpscare_sprite.play("Plague1")
			jumpscare_audio.stream = PLAGUE_LAUGH_1
		_:
			jumpscare_sprite.play("Plague2")
			jumpscare_audio.stream = PLAGUE_ALTERNATE
	jumpscare_audio.play()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "zoomin":
		jumpscare_finished.emit()
