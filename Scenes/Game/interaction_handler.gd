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
@onready var computer_button: Button = $"../OfficeRoom/BaseElements/Computer/ComputerButton"

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
	door_handle_button: "Switch",
	computer_button: "Cameras / Oxygen / Heat"
	}
	
	for button in hover_tips:
		button.mouse_entered.connect(_on_button_hover.bind(hover_tips[button]))
		button.mouse_exited.connect(_on_button_unhover)

	# These two are wired up in the scene; the other panel buttons are not, so
	# hook them here rather than leaving them dead.
	comms_reboot.pressed.connect(_on_comms_reboot_pressed)
	reboot_all.pressed.connect(_on_reboot_all_pressed)
	computer_button.pressed.connect(Monitor.toggle)


func _process(_delta: float) -> void:
	mouse_tooltip.text = textTip



func _on_button_hover(tip: String):
	textTip = tip

func _on_button_unhover():
	textTip = ""

# --- OFFICE INTERACTIONS ---

# The hide spots handle their own state; see hide_spot.gd.
func _on_hide_pressed() -> void:
	pass


# The reboot panel is also how a Security Breach gets undone: each button
# clears the sabotage on its room and tops the system back up for a charge.
func _on_o_2_reboot_pressed() -> void:
	CoreResources.reboot_room(Global.Room.OXYGEN_SYS)


func _on_heat_reboot_pressed() -> void:
	CoreResources.reboot_room(Global.Room.HEAT_SYS)


func _on_comms_reboot_pressed() -> void:
	CoreResources.reboot_room(Global.Room.COMMS_SYS)


func _on_reboot_all_pressed() -> void:
	CoreResources.reboot_everything()
