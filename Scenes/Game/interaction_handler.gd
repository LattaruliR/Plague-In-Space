extends Node2D

@onready var mouse_tooltip: Label = $"../Camera/MouseTooltip"
var textTip = " "
@onready var hidemask: Button = $"../OfficeRoom/Interactables/MaskHide/Hide"
@onready var o_2_reboot: Button = $"../OfficeRoom/Interactables/O2RebootBSprite/O2Reboot"
@onready var heat_reboot: Button = $"../OfficeRoom/Interactables/HRebootBSprite/HeatReboot"
@onready var comms_reboot: Button = $"../OfficeRoom/Interactables/CRebootBSprite/CommsReboot"
@onready var reboot_all: Button = $"../OfficeRoom/Interactables/RebootAllBSprite/RebootAll"
@onready var door: Button = $"../OfficeRoom/Interactables/Door"
@onready var door_handle_button: Button = $"../OfficeRoom/Interactables/DoorHandle/DoorHandleButton"

const BAR_TONE = preload("uid://cmabygqmehtnw")




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var hover_tips := {
	hidemask: "hide",
	o_2_reboot: "Reboot oxygen",
	heat_reboot: "Reboot heat",
	comms_reboot: "Reboot Communications",
	reboot_all: "Reboot all",
	door: "Leave",
	door_handle_button: "Switch"
	}
	
	for button in hover_tips:
		button.mouse_entered.connect(_on_button_hover.bind(hover_tips[button]))
		button.mouse_exited.connect(_on_button_unhover)


func _process(_delta: float) -> void:
	mouse_tooltip.text = textTip
	print()
	


func _on_button_hover(tip: String):
	textTip = tip

func _on_button_unhover():
	textTip = ""

# --- OFFICE INTERACTIONS ---

func _on_hide_pressed() -> void:
	pass # Replace with function body.


func _on_o_2_reboot_pressed() -> void:
	pass # Replace with function body.


func _on_heat_reboot_pressed() -> void:
	pass # Replace with function body.
