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
@onready var arak_energy: Button = $"../OfficeRoom/Interactables/MusicBoxButton"
#@onready var computer_button: Button = $"../OfficeRoom/BaseElements/Computer/ComputerButton"

const BAR_TONE = preload("uid://cmabygqmehtnw")

func _ready() -> void:
	var hover_tips := {
	hidemask: "hide",
	o_2_reboot: "Reboot oxygen",
	heat_reboot: "Reboot heat",
	comms_reboot: "Reboot Communications",
	reboot_all: "Reboot all",
	door: "Leave",
	door_handle_button: "Switch",
	arak_energy: "Monster"
	#computer_button: "Cameras / Oxygen / Heat"
	}
	
	for button in hover_tips:
		button.mouse_entered.connect(_on_button_hover.bind(hover_tips[button]))
		button.mouse_exited.connect(_on_button_unhover)

	comms_reboot.pressed.connect(_on_comms_reboot_pressed)
	reboot_all.pressed.connect(_on_reboot_all_pressed)
	#computer_button.pressed.connect(Monitor.toggle)


func _process(_delta: float) -> void:
	mouse_tooltip.text = textTip



func _on_button_hover(tip: String):
	textTip = tip

func _on_button_unhover():
	textTip = ""

func _on_hide_pressed() -> void:
	pass

func _on_o_2_reboot_pressed() -> void:
	CoreResources.reboot_room(Global.Room.OXYGEN_SYS)


func _on_heat_reboot_pressed() -> void:
	CoreResources.reboot_room(Global.Room.HEAT_SYS)


func _on_comms_reboot_pressed() -> void:
	CoreResources.reboot_room(Global.Room.COMMS_SYS)


func _on_reboot_all_pressed() -> void:
	CoreResources.reboot_everything()
