class_name AchievementCard
extends RefCounted

const ICON_SIZE := Vector2(84, 84)
const CARD_MIN_WIDTH := 470.0

const ACCENT := Color(0.61, 0, 0.0824)
const CARD_BG := Color(0, 0, 0, 0.92)


static func build(font: FontFile) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_MIN_WIDTH, 0)
	card.add_theme_stylebox_override("panel", _outline(3))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var icon := Panel.new()
	icon.name = "Icon"
	icon.custom_minimum_size = ICON_SIZE
	icon.add_theme_stylebox_override("panel", _outline(2))
	row.add_child(icon)

	var text := VBoxContainer.new()
	text.name = "Text"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 2)
	row.add_child(text)

	var title := Label.new()
	title.name = "Name"
	title.text = "???"
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", ACCENT)
	text.add_child(title)

	var desc := Label.new()
	desc.name = "Description"
	desc.text = "???"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_override("font", font)
	desc.add_theme_font_size_override("font_size", 19)
	desc.add_theme_color_override("font_color", ACCENT)
	text.add_child(desc)

	return card

static func apply(card: PanelContainer, def: Dictionary, is_unlocked: bool) -> void:
	var secret: bool = def.get("secret", false)
	var title := name_of(card)
	var desc := desc_of(card)

	if is_unlocked:
		title.text = str(def.get("name", "???"))
		desc.text = str(def.get("description", ""))
	elif secret:
		title.text = "???"
		desc.text = "Secret"
	else:
		title.text = "???"
		desc.text = "???"

	var alpha := 1.0 if is_unlocked else 0.55
	card.modulate = Color(1, 1, 1, alpha)


static func icon_of(card: PanelContainer) -> Panel:
	return card.find_child("Icon", true, false) as Panel


static func name_of(card: PanelContainer) -> Label:
	return card.find_child("Name", true, false) as Label


static func desc_of(card: PanelContainer) -> Label:
	return card.find_child("Description", true, false) as Label


static func _outline(width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.set_border_width_all(width)
	style.border_color = ACCENT
	style.set_content_margin_all(4)
	return style
