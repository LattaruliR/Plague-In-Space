extends Node2D




func _on_button_pressed() -> void:
	CoreResources.reset_systems()
	Global.reset_player_state()
	Blackout.reset()
	get_tree().change_scene_to_file("res://Scenes/Game/game.tscn")


func _on_timer_timeout() -> void:
	Achievements.unlock("lorekeeper")
	print("Unlock!")
