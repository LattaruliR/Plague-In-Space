extends Control
const LURE_BROADCAST = preload("uid://cqneqee1ttis6")
@onready var recharging_label: Label = $RechargingLabel


func _process(delta: float) -> void:
	if CoreResources.is_sabotaged(Global.Room.OXYGEN_SYS):
		$SabotageWarnings/SabotageTexture4.show()
	else: $SabotageWarnings/SabotageTexture4.hide()
	if CoreResources.is_sabotaged(Global.Room.KITCHEN):
		$SabotageWarnings/SabotageTexture.show()
	else: $SabotageWarnings/SabotageTexture.hide()
	if CoreResources.is_sabotaged(Global.Room.POWER_GRID):
		$SabotageWarnings/SabotageTexture2.show()
	else: $SabotageWarnings/SabotageTexture2.hide()
	if CoreResources.is_sabotaged(Global.Room.HEAT_SYS):
		$SabotageWarnings/SabotageTexture3.show()
	else: $SabotageWarnings/SabotageTexture3.hide()
	if CoreResources.is_sabotaged(Global.Room.COMMS_SYS):
		$SabotageWarnings/SabotageTexture5.show()
	else: $SabotageWarnings/SabotageTexture5.hide()
	



	recharging_label.text = "SPEAKERS RECHARGING - %ds" % int(ceil(Blackout.get_plague().lure_cooldown_left))
	recharging_label.text = "SPEAKERS READY   -   LURES UNSEEN: %d" % Global.lure_streak


func _on_lure_k_pressed() -> void:
	AudioManager.play_sfx(LURE_BROADCAST)
	Monitor._on_lure_pressed(0)

func _on_lure_p_pressed() -> void:
	AudioManager.play_sfx(LURE_BROADCAST)
	Monitor._on_lure_pressed(1)

func _on_lure_h_pressed() -> void:
	AudioManager.play_sfx(LURE_BROADCAST)
	Monitor._on_lure_pressed(2)


func _on_lure_o_pressed() -> void:
	AudioManager.play_sfx(LURE_BROADCAST)
	Monitor._on_lure_pressed(3)

func _on_lure_c_pressed() -> void:
	AudioManager.play_sfx(LURE_BROADCAST)
	Monitor._on_lure_pressed(4)
