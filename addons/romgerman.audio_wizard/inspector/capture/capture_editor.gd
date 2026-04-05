@tool
extends "../effect_editor_base.gd"

const ThemeUtils := preload("res://addons/romgerman.audio_wizard/theme_utils.gd")

const MAX_BUFFER_SEC := 10.0
const CONTENT_PADDING := 12.0
const LINE_THICKNESS := 1.0

var base_color: Color
var accent_color: Color
var text_color: Color
var is_light_theme: bool

func _ready() -> void:
	super._ready()
	
	if eff_ref:
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)
	
	base_color = ThemeUtils.get_base_color(self)
	accent_color = ThemeUtils.get_accent_color(self)
	is_light_theme = ThemeUtils.is_light_color(base_color)
	text_color = Color.BLACK if is_light_theme else Color.WHITE

func _draw() -> void:
	draw_layout()
	if eff_ref:
		draw_grid()

func draw_grid() -> void:
	var rect := get_rect().grow(-CONTENT_PADDING)
	var grid_scale := MAX_BUFFER_SEC
	var eff_capture := eff_ref as AudioEffectCapture
	
	if eff_capture.buffer_length < 1.0:
		grid_scale = 1.0
	
	for sec in range(int(grid_scale) + 1):
		var x := rect.size.x * (float(sec) / grid_scale) + CONTENT_PADDING
		draw_line(
			Vector2(x, CONTENT_PADDING * 2.0),
			Vector2(x, rect.size.y),
			ThemeUtils.modify_color(text_color, 0.5)
		)
		
		draw_string(
			get_theme_default_font(),
			Vector2(x - ThemeUtils.FONT_SIZE * 0.5, rect.size.y + CONTENT_PADDING + 2.0),
			str(floori(sec)) + "s",
			HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			ThemeUtils.FONT_SIZE,
			ThemeUtils.modify_color(text_color, 0.5)
		)
	
	var repeats_s := MAX_BUFFER_SEC / clampf(eff_capture.buffer_length, 0.08, MAX_BUFFER_SEC)
	var cell_width := rect.size.x / repeats_s
	
	for i in floori(repeats_s):
		draw_set_transform(Vector2(0.0, rect.size.y * 0.5))
		var x := (i + 1) * cell_width + CONTENT_PADDING
		draw_line(
			Vector2(x, -rect.size.y * 0.25),
			Vector2(x, rect.size.y * 0.25),
			accent_color,
			LINE_THICKNESS,
			true
		)
		draw_line(
			Vector2(x - 2.0, -rect.size.y * 0.25),
			Vector2(x + 2.0, -rect.size.y * 0.25),
			accent_color,
			LINE_THICKNESS,
			true
		)
		draw_line(
			Vector2(x - 2.0, rect.size.y * 0.25),
			Vector2(x + 2.0, rect.size.y * 0.25),
			accent_color,
			LINE_THICKNESS,
			true
		)
		draw_set_transform(Vector2.ZERO)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)
