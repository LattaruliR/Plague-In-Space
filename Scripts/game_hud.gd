extends CanvasLayer

var panel: PanelContainer
var vbox: VBoxContainer

var bar_oxygen: ProgressBar
var bar_infection: ProgressBar
var bar_heat: ProgressBar
var power_label: Label

func _ready() -> void:
	layer = 10
	
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.custom_minimum_size = Vector2(250, 0)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new()) # this makes it so no background,
	# remove this line if u want it to have one
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_bottom", 5)
	
	panel.modulate = Color(1, 1, 1, 1)
	
	add_child(margin)
	margin.add_child(panel)
	
	var inner_margin = MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_right", 10)
	inner_margin.add_theme_constant_override("margin_top", 10)
	inner_margin.add_theme_constant_override("margin_left", 10)
	inner_margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(inner_margin)
	
	vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	inner_margin.add_child(vbox)
	
	
	var oxygen_box := VBoxContainer.new()
	oxygen_box.add_theme_constant_override("separation", 2)
	vbox.add_child(oxygen_box)

	var lbl_o2 := Label.new()
	lbl_o2.text = "Oxygen"
	oxygen_box.add_child(lbl_o2)

	bar_oxygen = ProgressBar.new()
	bar_oxygen.min_value = 0.0
	bar_oxygen.max_value = 100.0
	bar_oxygen.step = 0.1
	oxygen_box.add_child(bar_oxygen)


	var infection_box := VBoxContainer.new()
	infection_box.add_theme_constant_override("separation", 2)
	vbox.add_child(infection_box)

	var lbl_inf := Label.new()
	lbl_inf.text = "Infection"
	infection_box.add_child(lbl_inf)

	bar_infection = ProgressBar.new()
	bar_infection.min_value = 0.0
	bar_infection.max_value = 100.0
	bar_infection.step = 0.1
	infection_box.add_child(bar_infection)


	var heat_box := VBoxContainer.new()
	heat_box.add_theme_constant_override("separation", 2)
	vbox.add_child(heat_box)

	var lbl_heat := Label.new()
	lbl_heat.text = "Heat"
	heat_box.add_child(lbl_heat)

	bar_heat = ProgressBar.new()
	bar_heat.min_value = 0.0
	bar_heat.max_value = 100.0
	bar_heat.step = 0.1
	heat_box.add_child(bar_heat)


	power_label = Label.new()
	# power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# uncomment the line above if u want it to be horizontally aligned
	vbox.add_child(power_label)


func _process(_delta: float) -> void:
	if get_tree().current_scene and get_tree().current_scene.name == "Menu":
		visible = false
		return
	else:
		visible = false
		
	# should hide if in menu; for now just always show if coreresources exists
	if not CoreResources or not Global:
		return
		
	bar_oxygen.value = CoreResources.oxygen
	bar_infection.value = Global.infection_value
	bar_heat.value = CoreResources.heat

	var power_text = "Power: "
	for i in range(5):
		if i < CoreResources.power:
			power_text += "[X] "
		else:
			power_text += "[ ] "
	power_label.text = power_text
	
	if CoreResources.current_oxygen_zone == 0:
		bar_oxygen.modulate = Color(0.2, 1, 0.2)
	elif CoreResources.current_oxygen_zone == 1:
		bar_oxygen.modulate = Color(1, 1, 0.2)
	else:
		bar_oxygen.modulate = Color(1, 0.2, 0.2)
		
	match CoreResources.current_heat_zone:
		0: bar_heat.modulate = Color(1, 0.5, 0.2)
		1: bar_heat.modulate = Color(0.2, 1, 0.2)
		2: bar_heat.modulate = Color(0.2, 0.8, 1)
		3: bar_heat.modulate = Color(1, 1, 0.2)
		4: bar_heat.modulate = Color(1, 0.2, 0.2)
		
	# infection bar is always red (ps this whole script is just as an example u can change it if u want toasted)
	bar_infection.modulate = Color(0.8, 0.1, 0.1)
