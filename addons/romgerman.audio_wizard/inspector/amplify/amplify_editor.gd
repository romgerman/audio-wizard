@tool
extends "../effect_editor_base.gd"

const DbScale := preload("res://addons/romgerman.audio_wizard/inspector/db_scale.gd")

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
	var input_volume := 0.0
	if eff_handle.audio_eff_index != -1:
		input_volume = AudioServer.get_bus_volume_db(eff_handle.audio_bus_index)
	var output_volume := input_volume + eff_amplify.volume_db
	
	# Draw input
	var in_vol_y := db_scale.db_to_y(input_volume, useful_height)
	var in_begin_pos := Vector2(CONTENT_PADDING, CONTENT_PADDING + in_vol_y)
	draw_line(
		in_begin_pos,
		Vector2(CONTENT_PADDING + useful_width * 0.5, CONTENT_PADDING + in_vol_y),
		accent_color,
		line_thickness_primary,
		true
	)
	var in_text_pos := in_begin_pos + Vector2(0, ThemeUtils.FONT_SIZE + 2)
	if in_text_pos.y > useful_height:
		in_text_pos.y -= ThemeUtils.FONT_SIZE + 2 + line_thickness_primary + 3
	in_text_pos.y = clampf(in_text_pos.y, ThemeUtils.FONT_SIZE, rect.size.y - 2)
	draw_string(
		get_theme_default_font(),
		in_text_pos,
		("in (bus) %0.2fdB" if eff_handle.audio_eff_index == 0 else "in %0.2fdB") % input_volume,
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ThemeUtils.FONT_SIZE,
		ThemeUtils.modify_color(text_color, 0.1)
	)
	
	# Draw output
	var out_vol_y := db_scale.db_to_y(output_volume, useful_height)
	var out_being_pos := Vector2(CONTENT_PADDING + useful_width * 0.5, CONTENT_PADDING + out_vol_y)
	draw_line(
		out_being_pos,
		Vector2(CONTENT_PADDING + useful_width, CONTENT_PADDING + out_vol_y),
		Color.RED,
		line_thickness_primary,
		true
	)
	var out_text_pos := out_being_pos + Vector2(0, ThemeUtils.FONT_SIZE + 2)
	if out_text_pos.y > useful_height:
		out_text_pos.y -= ThemeUtils.FONT_SIZE + 2 + line_thickness_primary + 3
	out_text_pos.y = clampf(out_text_pos.y, ThemeUtils.FONT_SIZE, rect.size.y - 2)
	draw_string(
		get_theme_default_font(),
		out_text_pos,
		"out %0.2fdB" % output_volume,
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ThemeUtils.FONT_SIZE,
		ThemeUtils.modify_color(text_color, 0.1)
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
		ThemeUtils.modify_color(text_color, 0.8),
		line_thickness_secondary
	)
