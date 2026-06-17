@tool
extends "../effect_editor_base.gd"

const LINE_THICKNESS := 1.0
const RESOLUTION := 48

const MAX_PAN_PULLOUT := 4.0
const MAX_TIME_PULLOUT_MS := 50.0

func _ready() -> void:
	if eff_handle.has_effect():
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)

# func _process(delta: float) -> void:
# 	if eff_handle.has_effect():
# 		queue_redraw()

func _draw() -> void:
	draw_layout()
	if eff_handle.has_effect():
		draw_representation()

func draw_representation() -> void:
	var content_rect := get_rect().grow(-CONTENT_PADDING)
	
	var eff_stereo := eff_handle.get_effect() as AudioEffectStereoEnhance
	var side_pan_angle := remap(eff_stereo.pan_pullout, 0.0, MAX_PAN_PULLOUT, 0.0, PI * 0.5)
	var is_surround := eff_stereo.surround > 0.0
	
	var radius := content_rect.size.y
	var center := Vector2(content_rect.get_center().x, content_rect.size.y + CONTENT_PADDING)
	
	if is_surround:
		var points := PackedVector2Array()
		for i in RESOLUTION:
			var t := float(i) / float(RESOLUTION - 1)
			var rad := t * PI + PI * 0.5
			var x := sin(rad) * radius
			var y := cos(rad) * radius
			
			points.push_back(center + Vector2(x, y))
		draw_colored_polygon(points, Color(ThemeUtils.modify_color(accent_color, 0.7), 0.5 * eff_stereo.surround))
	
	if side_pan_angle > 0.005:
		var points := PackedVector2Array()
		for i in RESOLUTION:
			var t := float(i) / float(RESOLUTION - 1)
			var rad := t * side_pan_angle * 2.0 - side_pan_angle - PI
			var x := sin(rad) * radius
			var y := cos(rad) * radius
			
			points.push_back(center + Vector2(x, y))
		points.push_back(center)
		draw_colored_polygon(points, Color(ThemeUtils.modify_color(accent_color, 0.7), 0.4))
	
	var center_line_x := content_rect.position.x + content_rect.size.x * 0.5
	var center_line_start := Vector2(center_line_x, content_rect.position.y)
	var center_line_end := Vector2(center_line_x, content_rect.position.y + content_rect.size.y)
	
	# L
	draw_line(
		(center_line_start - center_line_end).rotated(-side_pan_angle) + center_line_end,
		center_line_end,
		accent_color,
		LINE_THICKNESS,
		true
	)
	
	# R
	draw_line(
		(center_line_start - center_line_end).rotated(side_pan_angle) + center_line_end,
		center_line_end,
		accent_color,
		LINE_THICKNESS,
		true
	)
	
	if side_pan_angle > 0.005:
		draw_arc(
			center,
			radius,
			-side_pan_angle - PI * 0.5,
			side_pan_angle - PI * 0.5,
			48,
			accent_color,
			LINE_THICKNESS,
			true
		)
	
	var mode_string := "MONO" if eff_stereo.pan_pullout == 0.0 else ("SR" if is_surround else "")
	var mode_string_size := get_theme_default_font().get_string_size(mode_string, HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeUtils.FONT_SIZE)
	
	if mode_string:
		draw_rect(
			Rect2(CONTENT_PADDING, CONTENT_PADDING + mode_string_size.y * 2.0, mode_string_size.x + 1.0, ThemeUtils.FONT_SIZE).grow(2.0),
			accent_color,
			false,
			1.0,
			false
		)
	
	draw_string(
		get_theme_default_font(),
		Vector2(CONTENT_PADDING, (CONTENT_PADDING + ThemeUtils.FONT_SIZE) * 2.0),
		mode_string,
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		ThemeUtils.FONT_SIZE,
		accent_color
	)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)
	
	var content_rect := get_rect().grow(-CONTENT_PADDING)
	
	var center_line_x := content_rect.position.x + content_rect.size.x * 0.5
	var center_line_start := Vector2(center_line_x, content_rect.position.y)
	var center_line_end := Vector2(center_line_x, content_rect.position.y + content_rect.size.y)
	draw_line(
		center_line_start,
		center_line_end,
		ThemeUtils.modify_color(base_color, 0.1),
		0.5,
		true
	)
	
	draw_line(
		(center_line_start - center_line_end).rotated(PI * 0.25) + center_line_end,
		center_line_end,
		ThemeUtils.modify_color(base_color, 0.1),
		0.5,
		true
	)
	
	draw_line(
		(center_line_start - center_line_end).rotated(-PI * 0.25) + center_line_end,
		center_line_end,
		ThemeUtils.modify_color(base_color, 0.1),
		0.5,
		true
	)
	
	var radius := content_rect.size.y
	
	draw_line(
		Vector2(content_rect.get_center().x - radius, content_rect.size.y + CONTENT_PADDING),
		Vector2(content_rect.get_center().x + radius, content_rect.size.y + CONTENT_PADDING),
		ThemeUtils.modify_color(base_color, 0.1),
		0.5,
		true
	)
	
	# L
	draw_arc(
		Vector2(content_rect.get_center().x, content_rect.size.y + CONTENT_PADDING),
		radius,
		PI,
		PI * 2.0,
		48,
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
