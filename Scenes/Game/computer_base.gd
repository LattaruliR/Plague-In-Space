extends Control

@onready var resources: Panel = $"../InformationFeed/BasePanel/Resources"
@onready var research: Panel = $"../InformationFeed/BasePanel/Research"
@onready var offline: Panel = $"../InformationFeed/BasePanel/Offline"
@onready var cameras: Panel = $"../InformationFeed/BasePanel/Cameras"
@onready var reboot_time: Timer = $ComputerBase/RebootTime
@onready var booting: ColorRect = $ComputerBase/Booting
@onready var pc_select: AudioStreamPlayer = $"../../AUDIO/PcSelect"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	booting.show()
	reboot_time.start()

func _on_cam_button_pressed() -> void:
	pc_select.play()
	cameras.visible = true
	research.hide()
	resources.hide()


func _on_resources_button_pressed() -> void:
	pc_select.play()
	cameras.hide()
	research.hide()
	resources.show()
var playing := false

func _on_research_button_pressed() -> void:
	if Global.panic == true && playing == false:
		$"../../AUDIO/AmbientPanic".play()
		playing = true
	else:
		$"../../AUDIO/AmbientPanic".stop()
		playing = false
	pc_select.play()
	cameras.hide()
	research.show()
	resources.hide()

func _on_reboot_time_timeout() -> void:
	booting.hide()
