@tool
extends "../effect_editor_base.gd"

const DbScale := preload("res://addons/romgerman.audio_wizard/inspector/db_scale.gd")

const CONTENT_PADDING := 12.0
const LINE_THICKNESS := 1.0

var db_scale: DbScale
var layout_offset_x := 0.0

func _ready() -> void:
	db_scale = DbScale.new(self)

func _process(delta: float) -> void:
	if eff_handle.has_effect():
		queue_redraw()

func _draw() -> void:
	draw_layout()
	if eff_handle.has_effect():
		draw_meters()

func draw_meters() -> void:
	var rect := get_rect()
	var useful_width := rect.size.x - layout_offset_x - CONTENT_PADDING * 2.0
	var useful_height := rect.size.y - CONTENT_PADDING * 2.0
	
	var eff_amplify := eff_handle.get_effect() as AudioEffectAmplify
	var input_volume := AudioServer.get_bus_volume_db(eff_handle.audio_bus_index)
	var output_volume := input_volume + eff_amplify.volume_db
	
	# Draw input
	var in_vol_y := db_scale.db_to_y(input_volume, useful_height)
	var in_begin_pos := Vector2(CONTENT_PADDING, CONTENT_PADDING + in_vol_y)
	draw_line(
		in_begin_pos,
		Vector2(CONTENT_PADDING + useful_width * 0.5, CONTENT_PADDING + in_vol_y),
		accent_color,
		LINE_THICKNESS,
		true
	)
	var in_text_pos := in_begin_pos + Vector2(0, ThemeUtils.FONT_SIZE + 2)
	if in_text_pos.y > useful_height:
		in_text_pos.y -= ThemeUtils.FONT_SIZE + 2 + LINE_THICKNESS + 3
	in_text_pos.y = clampf(in_text_pos.y, ThemeUtils.FONT_SIZE, rect.size.y - 2)
	draw_string(
		get_theme_default_font(),
		in_text_pos,
		"in (bus) %0.2fdB" % input_volume,
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ThemeUtils.FONT_SIZE,
		text_color
	)
	
	# Draw output
	var out_vol_y := db_scale.db_to_y(output_volume, useful_height)
	var out_being_pos := Vector2(CONTENT_PADDING + useful_width * 0.5, CONTENT_PADDING + out_vol_y)
	draw_line(
		out_being_pos,
		Vector2(CONTENT_PADDING + useful_width, CONTENT_PADDING + out_vol_y),
		Color.RED,
		LINE_THICKNESS,
		true
	)
	var out_text_pos := out_being_pos + Vector2(0, ThemeUtils.FONT_SIZE + 2)
	if out_text_pos.y > useful_height:
		out_text_pos.y -= ThemeUtils.FONT_SIZE + 2 + LINE_THICKNESS + 3
	out_text_pos.y = clampf(out_text_pos.y, ThemeUtils.FONT_SIZE, rect.size.y - 2)
	draw_string(
		get_theme_default_font(),
		out_text_pos,
		"out %0.2fdB" % output_volume,
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ThemeUtils.FONT_SIZE,
		text_color
	)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)
	
	var content_rect := rect.grow(-CONTENT_PADDING)
	
	# Db scale
	layout_offset_x = db_scale.draw(
		Vector2(rect.size.x - CONTENT_PADDING, CONTENT_PADDING),
		content_rect.size.y,
		get_theme_default_font(),
		ThemeUtils.modify_color(text_color, 0.5)
	)
	
	# Draw 0dB
	var line_y := remap(0.0, DbScale.MIN_DB, DbScale.MAX_DB, content_rect.size.y, 0.0)
	draw_line(
		Vector2(CONTENT_PADDING, line_y + CONTENT_PADDING),
		Vector2(rect.size.x - CONTENT_PADDING - layout_offset_x, line_y + CONTENT_PADDING),
		ThemeUtils.modify_color(text_color, 0.85),
		1.0
	)
