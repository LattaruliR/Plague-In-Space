class_name Glyph
extends Control

## toasted nao esqueça de mudar esses shapes por sprites reais depois

const SHAPES: Array[Dictionary] = [
	{ # 0 - delta
		"lines": [
			[Vector2(0.5, 0.08), Vector2(0.93, 0.86), Vector2(0.07, 0.86), Vector2(0.5, 0.08)],
			[Vector2(0.28, 0.52), Vector2(0.5, 0.74), Vector2(0.72, 0.52)],
			[Vector2(0.37, 0.37), Vector2(0.63, 0.37)],
		],
		"circles": [],
	},
	{ # 1 - star
		"lines": [
			[Vector2(0.5, 0.05), Vector2(0.61, 0.37), Vector2(0.95, 0.5), Vector2(0.61, 0.63),
			 Vector2(0.5, 0.95), Vector2(0.39, 0.63), Vector2(0.05, 0.5), Vector2(0.39, 0.37),
			 Vector2(0.5, 0.05)],
		],
		"circles": [],
	},
	{ # 2 - hourglass
		"lines": [
			[Vector2(0.16, 0.10), Vector2(0.84, 0.10), Vector2(0.84, 0.90), Vector2(0.16, 0.90),
			 Vector2(0.16, 0.10)],
			[Vector2(0.32, 0.24), Vector2(0.68, 0.24), Vector2(0.40, 0.50), Vector2(0.68, 0.76),
			 Vector2(0.32, 0.76), Vector2(0.60, 0.50), Vector2(0.32, 0.24)],
		],
		"circles": [],
	},
	{ # 3 - token
		"lines": [
			[Vector2(0.31, 0.09), Vector2(0.69, 0.09), Vector2(0.78, 0.30), Vector2(0.69, 0.92),
			 Vector2(0.31, 0.92), Vector2(0.22, 0.30), Vector2(0.31, 0.09)],
			[Vector2(0.5, 0.46), Vector2(0.5, 0.80)],
		],
		"circles": [{"c": Vector2(0.5, 0.33), "r": 0.12}],
	},
	{ # 4 - lens (spare)
		"lines": [
			[Vector2(0.06, 0.5), Vector2(0.5, 0.16), Vector2(0.94, 0.5), Vector2(0.5, 0.84),
			 Vector2(0.06, 0.5)],
		],
		"circles": [{"c": Vector2(0.5, 0.5), "r": 0.14}],
	},
	{ # 5 - bolt (spare)
		"lines": [
			[Vector2(0.60, 0.05), Vector2(0.27, 0.53), Vector2(0.48, 0.53), Vector2(0.38, 0.95),
			 Vector2(0.72, 0.45), Vector2(0.51, 0.45), Vector2(0.60, 0.05)],
		],
		"circles": [],
	},
]

const CIRCLE_SEGMENTS := 18

@export var glyph_index: int = -1: # -1 draws nothing (empty slot)
	set(value):
		glyph_index = value
		queue_redraw()

@export var line_color: Color = Color(0.35, 1.0, 0.35):
	set(value):
		line_color = value
		queue_redraw()

@export var line_width: float = 2.0:
	set(value):
		line_width = value
		queue_redraw()

@export var show_empty_slot: bool = false

func _draw() -> void:
	if glyph_index < 0 or glyph_index >= SHAPES.size():
		if show_empty_slot:
			var faint := Color(line_color.r, line_color.g, line_color.b, 0.25)
			draw_rect(Rect2(Vector2(size.x * 0.2, size.y * 0.45),
					Vector2(size.x * 0.6, max(1.0, line_width))), faint)
		return

	var shape: Dictionary = SHAPES[glyph_index]

	for line: Array in shape["lines"]:
		var points := PackedVector2Array()
		for point: Vector2 in line:
			points.append(point * size)
		if points.size() >= 2:
			draw_polyline(points, line_color, line_width, true)

	for circle: Dictionary in shape["circles"]:
		var center: Vector2 = circle["c"] * size
		var radius: float = circle["r"] * minf(size.x, size.y)
		_draw_circle_outline(center, radius)

func _draw_circle_outline(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for i in CIRCLE_SEGMENTS + 1:
		var angle := TAU * float(i) / float(CIRCLE_SEGMENTS)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_polyline(points, line_color, line_width, true)

static func create(index: int, box_size: Vector2, width: float = 2.0) -> Glyph:
	var glyph := Glyph.new()
	glyph.custom_minimum_size = box_size
	glyph.glyph_index = index
	glyph.line_width = width
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return glyph
