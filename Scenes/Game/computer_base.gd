extends Control

@onready var resources: Panel = $"../InformationFeed/BasePanel/Resources"
@onready var research: Panel = $"../InformationFeed/BasePanel/Research"
@onready var offline: Panel = $"../InformationFeed/BasePanel/Offline"
@onready var cameras: Panel = $"../InformationFeed/BasePanel/Cameras"
@onready var reboot_time: Timer = $ComputerBase/RebootTime
@onready var booting: ColorRect = $ComputerBase/Booting
@onready var pc_select: AudioStreamPlayer = $"../../AUDIO/PcSelect"
var playing := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	booting.show()
	reboot_time.start()

func _on_cam_button_pressed() -> void:
	var tween = create_tween()
	tween.tween_property($ComputerBase/Options/Cameras, "scale", Vector2(1.01, 1.01), 0.2)
	pc_select.play()
	cameras.visible = true
	research.hide()
	resources.hide()
	tween.tween_interval(0.5)
	tween.tween_property($ComputerBase/Options/Cameras, "scale", Vector2(1, 1), 0.2)



func _on_resources_button_pressed() -> void:
	var tween = create_tween()
	tween.tween_property($ComputerBase/Options/Resources, "scale", Vector2(1.01, 1.01), 0.2)
	pc_select.play()
	cameras.hide()
	research.hide()
	resources.show()
	tween.tween_interval(0.5)
	tween.tween_property($ComputerBase/Options/Resources, "scale", Vector2(1, 1), 0.2)



func _on_research_button_pressed() -> void:
	var tween = create_tween()
	tween.tween_property($ComputerBase/Options/Research, "scale", Vector2(1.01, 1.01), 0.2)
	pc_select.play()
	cameras.hide()
	research.show()
	resources.hide()
	tween.tween_interval(0.5)
	tween.tween_property($ComputerBase/Options/Research, "scale", Vector2(1, 1), 0.2)


func _on_reboot_time_timeout() -> void:
	booting.hide()

func _process(_delta: float) -> void:
	if Global.panic == true && playing == false:
		$"../../AUDIO/AmbientPanic".play()
		playing = true
	else:
		$"../../AUDIO/AmbientPanic".stop()
		playing = false
