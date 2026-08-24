class_name TerminalStyle
extends RefCounted

const FONT := preload("res://Fonts/home-video/HomeVideo-Regular.ttf")

const GREEN := Color(0.35, 1.0, 0.35)
const DIM_GREEN := Color(0.35, 1.0, 0.35, 0.35)
const RED := Color(1.0, 0.4, 0.35)
const SCREEN_BG := Color(0.02, 0.05, 0.02, 0.92)


static func outline_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(2)
	style.border_color = border
	style.set_content_margin_all(6)
	return style


static func style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", outline_style(SCREEN_BG, GREEN))
	button.add_theme_stylebox_override("hover", outline_style(Color(0.08, 0.18, 0.08, 0.95), GREEN))
	button.add_theme_stylebox_override("pressed", outline_style(Color(0.15, 0.35, 0.15, 0.95), Color.WHITE))
	button.add_theme_stylebox_override("disabled", outline_style(SCREEN_BG, DIM_GREEN))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func text_button(text: String, min_size: Vector2 = Vector2(170, 46), font_size: int = 30) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", GREEN)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", DIM_GREEN)
	style_button(button)
	return button


static func panel() -> PanelContainer:
	var container := PanelContainer.new()
	container.add_theme_stylebox_override("panel", outline_style(SCREEN_BG, GREEN))
	return container


static func label(text: String, font_size: int, color: Color = GREEN) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", FONT)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node


static func wrap_in_margin(container: Control, content: Control, amount: int) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", amount)
	margin.add_theme_constant_override("margin_right", amount)
	margin.add_theme_constant_override("margin_top", amount)
	margin.add_theme_constant_override("margin_bottom", amount)
	container.add_child(margin)
	margin.add_child(content)

static func spaced(text: String) -> String:
	var out := ""
	for i in text.length():
		out += text[i]
		if i < text.length() - 1:
			out += " "
	return out
