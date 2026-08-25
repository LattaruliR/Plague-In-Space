extends Control

# -- Resource Panel

@onready var oxygen_bar: ProgressBar = $BasePanel/Resources/OxygenBar
@onready var heat_bar: ProgressBar = $BasePanel/Resources/HeatBar
@onready var ox_status: Label = $BasePanel/Resources/OxStatus
@onready var heat_status: Label = $BasePanel/Resources/HeatStatus
@onready var power_label: Label = $BasePanel/Resources/PowerLabel
@onready var charges_label: Label = $BasePanel/Resources/ChargesLabel

# -- Research Panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	Monitor._refresh_heat()
	Monitor._refresh_oxygen()
	charges_label.text = str(CoreResources.power) + "/5"
	oxygen_bar.value = Monitor._oxygen_bar.value
	heat_bar.value = Monitor._heat_bar.value
	ox_status.text = Monitor._oxygen_text.text
	heat_status.text = Monitor._heat_text.text
