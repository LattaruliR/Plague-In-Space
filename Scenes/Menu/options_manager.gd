extends Control

@onready var sfx_slider: HSlider = $BasePanel/HBoxContainer/SFX/SfxSlider
@onready var volume_slider: HSlider = $BasePanel/HBoxContainer/MUSIC/VolumeSlider
@onready var percentage_label_volume: Label = $BasePanel/HBoxContainer/MUSIC/percentageLabelVolume
@onready var percentage_label_sfx: Label = $BasePanel/HBoxContainer/SFX/percentageLabelSfx


func _process(delta: float) -> void:
	percentage_label_sfx.text = str(sfx_slider.value) + "%"
	percentage_label_volume.text = str(volume_slider.value) + "%"
	
	Global.sfx_volume = sfx_slider.value
	Global.music_volume = volume_slider.value
	
	var musicBus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(musicBus, Global.music_volume - 63)

	var sfxBus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfxBus, Global.sfx_volume - 63)
	



func _on_exit_button_pressed() -> void:
	$"../Selecting".play()
	hide()


func _on_check_button_toggled(toggled_on: bool) -> void:
	$"../Selecting".play()
	if toggled_on == false:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _on_sfx_slider_value_changed(value: float) -> void:
	$"../BarTone".play()


func _on_volume_slider_value_changed(value: float) -> void:
	$"../BarTone".play()
