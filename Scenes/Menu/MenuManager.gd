extends Node2D

@onready var mouse_tooltip: Label = $Camera2D/MouseTooltip
var textTip = " "

func _ready() -> void:
	mouse_tooltip.text = textTip


func _process(_delta: float) -> void:
	mouse_tooltip.text = textTip

func _on_play_button_mouse_entered() -> void:
	textTip = "Play?"

func _on_play_button_mouse_exited() -> void:
	textTip = " "

func _on_play_button_pressed() -> void:
	$Selecting.play()
	CoreResources.reset_systems()
	Global.reset_player_state()
	Blackout.reset()
	Global.hard_mode = false
	get_tree().change_scene_to_file("res://Scenes/cutscene.tscn")


func _on_quit_button_mouse_entered() -> void:
	var easterEgg = randi_range(1, 20)
	if (easterEgg == 20):
		textTip = "Die?"
	else:
		textTip = "Quit?"

func _on_quit_button_mouse_exited() -> void:
	textTip = " "

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_options_button_mouse_entered() -> void:
	textTip = "Options"

func _on_options_button_mouse_exited() -> void:
	textTip = " "


func _on_options_button_pressed() -> void:
	$Selecting.play()
	$OptionsUI.show()


func _on_hard_mode_button_pressed() -> void:
	$Selecting.play()
	CoreResources.reset_systems()
	Global.reset_player_state()
	Blackout.reset()
	Global.hard_mode = true
	get_tree().change_scene_to_file("res://Scenes/cutscene.tscn")
	


func _on_hard_mode_button_mouse_entered() -> void:
	textTip = "Play Hard Mode?\n
				- Frequent Sabotages\n
				- Faster Archive wind down\n
				- Invisible Plague\n
				- Faster Infection spread\n
				+ Faster Reboot Cooldown\n
				+ Additional Power Charge"

func _on_hard_mode_button_mouse_exited() -> void:
	textTip = " "
