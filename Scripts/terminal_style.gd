class_name TerminalStyle
extends RefCounted

const FONT := preload("res://Fonts/home-video/HomeVideo-Regular.ttf")

const GREEN := Color(0.35, 1.0, 0.35)
const DIM_GREEN := Color(0.35, 1.0, 0.35, 0.35)
## AMBER = needs attention (offline grid, sabotage, a refused action).
## RED is reserved for immediate danger: the Plague in your room, or caught.
const AMBER := Color(1.0, 0.85, 0.3)
const RED := Color(1.0, 0.4, 0.35)
const SCREEN_BG := Color(0.02, 0.05, 0.02, 0.92)


static func outline_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(2)
	style.border_color = border
	style.set_content_margin_all(6)
	return style

static func screen_bg(accent: Color = GREEN) -> Color:
	return Color(accent.r * 0.06, accent.g * 0.06, accent.b * 0.06, 0.92)


static func style_button(button: Button, accent: Color = GREEN) -> void:
	var dim := Color(accent.r, accent.g, accent.b, 0.35)
	var hover_bg := Color(accent.r * 0.18, accent.g * 0.18, accent.b * 0.18, 0.95)
	var pressed_bg := Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35, 0.95)
	var bg := screen_bg(accent)

	button.add_theme_stylebox_override("normal", outline_style(bg, accent))
	button.add_theme_stylebox_override("hover", outline_style(hover_bg, accent))
	button.add_theme_stylebox_override("pressed", outline_style(pressed_bg, Color.WHITE))
	button.add_theme_stylebox_override("disabled", outline_style(bg, dim))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func text_button(text: String, min_size: Vector2 = Vector2(170, 46), font_size: int = 30,
		accent: Color = GREEN) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", accent)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(accent.r, accent.g, accent.b, 0.35))
	style_button(button, accent)
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
