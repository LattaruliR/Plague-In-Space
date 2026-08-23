extends CanvasLayer

var panel: PanelContainer
var oxygen_label: Label
var oxygen_bar: ProgressBar
var infection_label: Label
var infection_bar: ProgressBar
var panic_label: Label
var heat_label: Label

var debug_open := false


func _ready() -> void:
	layer = 128
	_build_debug_panel()
	_update_visibility()


func _build_debug_panel() -> void:
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.custom_minimum_size = Vector2(250, 150)
	panel.modulate.a = 1
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.98)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 1)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var title := Label.new()
	title.text = "debug info"
	box.add_child(title)

	oxygen_label = Label.new()
	box.add_child(oxygen_label)

	oxygen_bar = _create_bar()
	box.add_child(oxygen_bar)

	infection_label = Label.new()
	box.add_child(infection_label)

	infection_bar = _create_bar()
	box.add_child(infection_bar)

	panic_label = Label.new()
	box.add_child(panic_label)

	heat_label = Label.new()
	box.add_child(heat_label)

	var controls := Label.new()
	controls.text = """
controls:
1 -10% O2
2 +10% O2
3 reset infection
4 reset panic
5 reboot heat (-power)
6 refill power
"""
	controls.modulate = Color(0.7, 0.7, 0.7)
	box.add_child(controls)


func _create_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.step = 0.1
	return bar


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	match event.keycode:
		KEY_F3:
			debug_open = !debug_open
			_update_visibility()

		KEY_1 when debug_open:
			CoreResources.oxygen = max(CoreResources.oxygen - 10.0, 0.0)

		KEY_2 when debug_open:
			CoreResources.oxygen = min(CoreResources.oxygen + 10.0, 100.0)

		KEY_3 when debug_open:
			Global.infection_value = 0.0
			Global.infection_step = 0

		KEY_4 when debug_open:
			Global.panic = false

		KEY_5 when debug_open:
			CoreResources.reboot_system(true) # Reboot Heat
			
		KEY_6 when debug_open:
			CoreResources.power = 5
			Global.blackout = false


func _update_visibility() -> void:
	if panel:
		panel.visible = debug_open


func _process(_delta: float) -> void:
	if not debug_open:
		return

	_update_debug_info()


func _update_debug_info() -> void:
	oxygen_label.text = "oxygen: [%s]" % _get_oxygen_zone_name()
	oxygen_bar.value = CoreResources.oxygen

	infection_label.text = "infection: (step: %d)" % Global.infection_step
	infection_bar.value = Global.infection_value

	panic_label.text = "Panic State: %s" % str(Global.panic)
	
	var heat_zone_name = "PERFECT"
	match CoreResources.current_heat_zone:
		0: heat_zone_name = "HOT"
		1: heat_zone_name = "PERFECT"
		2: heat_zone_name = "CHILLY"
		3: heat_zone_name = "DANGER"
		4: heat_zone_name = "DEATH"
		
	heat_label.text = "Heat: %.1f [%s]" % [CoreResources.heat, heat_zone_name]
	
	# If we want to show power, we can append it or create a new label.
	# Let's just append it to heat for now to save space, or use the panel.
	heat_label.text += "\nPower: %d/5  Blackout: %s" % [CoreResources.power, Global.blackout]


func _get_oxygen_zone_name() -> String:
	match CoreResources.current_oxygen_zone:
		0:
			return "SAFE"
		1:
			return "DRY"
		2:
			return "DANGER"
		_:
			return "UNKNOWN"
