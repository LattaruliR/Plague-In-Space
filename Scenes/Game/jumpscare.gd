extends Node2D

signal jumpscare_finished


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "zoomin":
		jumpscare_finished.emit()
