@tool
extends "../effect_editor_base.gd"

const CONTENT_PADDING := 12.0
const INDICATOR_RADIUS := 6.0

func _ready() -> void:
	super._ready()
	
	if eff_ref:
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)

#func _process(delta: float) -> void:
	#if eff_ref:
		#queue_redraw()

func _draw() -> void:
	draw_layout()
	if eff_ref:
		draw_representation()

func draw_representation() -> void:
	var content_rect := get_rect().grow(-CONTENT_PADDING)
	var eff_pan := eff_ref as AudioEffectPanner
	var pan := eff_pan.pan
	
	var pan_pos_x := (pan + 1.0) / 2.0 * content_rect.size.x
	var pan_pos_y := content_rect.size.y * 0.5
	
	draw_rect(
		Rect2(content_rect.position, Vector2(content_rect.size.x * 0.5, content_rect.size.y)),
		Color(accent_color, (1.0 - clampf(pan + 1.0, 0.0, 1.0)) * 0.2),
	)
	
	draw_rect(
		Rect2(content_rect.position + Vector2(content_rect.size.x * 0.5, 0.0), Vector2(content_rect.size.x * 0.5, content_rect.size.y)),
		Color(accent_color, clampf(pan, 0.0, 1.0) * 0.2),
	)
	
	#draw_line(
		#Vector2(content_rect.position.x + content_rect.size.x * 0.5, content_rect.position.y + content_rect.size.y * 0.5),
		#Vector2(content_rect.position.x + pan_pos_x, content_rect.position.y + pan_pos_y),
		#ThemeUtils.modify_color(base_color, 0.3),
		#0.5,
		#true
	#)
	
	draw_circle(
		Vector2(content_rect.position.x + pan_pos_x, content_rect.position.y + pan_pos_y),
		INDICATOR_RADIUS,
		accent_color,
		true,
		-1.0,
		true
	)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)
	
	var content_rect := get_rect().grow(-CONTENT_PADDING)
	
	var center_line_x := content_rect.position.x + content_rect.size.x * 0.5
	draw_line(
		Vector2(center_line_x, content_rect.position.y),
		Vector2(center_line_x, content_rect.position.y + content_rect.size.y),
		ThemeUtils.modify_color(base_color, 0.3),
		0.5,
		true
	)
	
	# L
	draw_string(
		get_theme_default_font(),
		Vector2(CONTENT_PADDING, CONTENT_PADDING + ThemeUtils.FONT_SIZE),
		"L",
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		ThemeUtils.FONT_SIZE,
		ThemeUtils.modify_color(text_color, 0.5)
	)
	
	var r_size := get_theme_default_font().get_string_size("R", HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeUtils.FONT_SIZE)
	
	# R
	draw_string(
		get_theme_default_font(),
		Vector2(
			rect.size.x - r_size.x - CONTENT_PADDING,
			CONTENT_PADDING + ThemeUtils.FONT_SIZE
		),
		"R",
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
		r_size.x,
		ThemeUtils.FONT_SIZE,
		ThemeUtils.modify_color(text_color, 0.5)
	)
