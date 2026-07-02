@tool
extends "../effect_editor_base.gd"

const MAX_BUFFER_SEC := 10.0

func _ready() -> void:
	if eff_handle.has_effect():
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)

#func _process(delta: float) -> void:
	#if eff_handle.has_effect():
		#queue_redraw()

func _draw() -> void:
	draw_layout()
	if eff_handle.has_effect():
		draw_grid()

func draw_grid() -> void:
	var rect := get_rect().grow(-CONTENT_PADDING)
	var grid_scale := MAX_BUFFER_SEC
	var eff_capture := eff_handle.get_effect() as AudioEffectCapture
	
	if eff_capture.buffer_length < 1.0:
		grid_scale = 1.0
	
	for sec in range(int(grid_scale) + 1):
		var x := rect.size.x * (float(sec) / grid_scale) + CONTENT_PADDING
		draw_line(
			Vector2(x, CONTENT_PADDING + ThemeUtils.FONT_SIZE),
			Vector2(x, rect.size.y),
			ThemeUtils.modify_color(text_color, 0.5),
			line_thickness_secondary
		)
		
		var mark_text := str(floori(sec)) + "s"
		var mark_text_size := get_theme_default_font().get_string_size(mark_text, HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeUtils.FONT_SIZE)
		
		draw_string(
			get_theme_default_font(),
			Vector2(x - mark_text_size.x * 0.5, rect.size.y + CONTENT_PADDING + 2.0),
			mark_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			ThemeUtils.FONT_SIZE,
			ThemeUtils.modify_color(text_color, 0.5)
		)
	
	var repeats_s := MAX_BUFFER_SEC / clampf(eff_capture.buffer_length, 0.08, MAX_BUFFER_SEC)
	var cell_width := rect.size.x / repeats_s
	
	for i in floori(repeats_s):
		draw_set_transform(Vector2(0.0, rect.get_center().y))
		var x := (i + 1) * cell_width + CONTENT_PADDING
		draw_line(
			Vector2(x, -rect.size.y * 0.25),
			Vector2(x, rect.size.y * 0.25),
			accent_color,
			line_thickness_secondary,
			true
		)
		draw_line(
			Vector2(x - 2.0, -rect.size.y * 0.25),
			Vector2(x + 2.0, -rect.size.y * 0.25),
			accent_color,
			line_thickness_secondary,
			true
		)
		draw_line(
			Vector2(x - 2.0, rect.size.y * 0.25),
			Vector2(x + 2.0, rect.size.y * 0.25),
			accent_color,
			line_thickness_secondary,
			true
		)
		draw_set_transform(Vector2.ZERO)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)
