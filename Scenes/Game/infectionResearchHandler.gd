extends Control
@onready var infection_bar: ProgressBar = $InfectionBar
@onready var infection_label: Label = $InfectionLabel
@onready var brain_sprite: AnimatedSprite2D = $BrainSprite
@onready var panic: Control = $Panic
@onready var panic_label: Label = $Panic/PanicLabel
@onready var panic_sprites: AnimatedSprite2D = $Panic/PanicSprites
@onready var ambient_panic: AudioStreamPlayer = $"../../../../../AUDIO/AmbientPanic"
@onready var calm_ambient: AudioStreamPlayer = $"../../../../../AUDIO/CalmAmbient"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	infection_bar.value = Global.infection_value
	if (infection_bar.value < 10.0):
		brain_sprite.frame = 0
	elif (infection_bar.value < 30.0):
		brain_sprite.frame = 1
	elif (infection_bar.value < 40.0):
		brain_sprite.frame = 2
	elif (infection_bar.value < 50.0):
		brain_sprite.frame = 3
	elif (infection_bar.value < 60.0):
		brain_sprite.frame = 4
	elif (infection_bar.value < 80.0):
		brain_sprite.frame = 5
	
	
	if Global.panic == true:
		panic.show()
	else:
		panic.hide()
