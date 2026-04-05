@tool
extends "../effect_editor_base.gd"

const DbScale := preload("res://addons/romgerman.audio_wizard/inspector/db_scale.gd")
const ThemeUtils := preload("res://addons/romgerman.audio_wizard/theme_utils.gd")

const CONTENT_PADDING := 12.0
const LINE_THICKNESS := 1.0

var db_scale: DbScale
var layout_offset_x := 0.0

var base_color: Color
var accent_color: Color
var text_color: Color
var is_light_theme: bool

func _ready() -> void:
	super._ready()
	
	db_scale = DbScale.new(self)
	
	base_color = ThemeUtils.get_base_color(self)
	accent_color = ThemeUtils.get_accent_color(self)
	is_light_theme = ThemeUtils.is_light_color(base_color)
	text_color = Color.BLACK if is_light_theme else Color.WHITE

func _process(delta: float) -> void:
	if eff_ref:
		queue_redraw()

func _draw() -> void:
	draw_layout()
	if eff_ref:
		draw_meters()

func draw_meters() -> void:
	var rect := get_rect()
	var useful_width := rect.size.x - layout_offset_x - CONTENT_PADDING * 2.0
	var useful_height := rect.size.y - CONTENT_PADDING * 2.0
	
	var eff_amplify := eff_ref as AudioEffectAmplify
	var input_volume := AudioServer.get_bus_volume_db(audio_bus_index)
	var output_volume := input_volume + eff_amplify.volume_db
	
	# Draw input
	var in_vol_y := db_to_y(input_volume, useful_height)
	var in_begin_pos := Vector2(CONTENT_PADDING, CONTENT_PADDING + in_vol_y)
	draw_line(
		in_begin_pos,
		Vector2(CONTENT_PADDING + useful_width * 0.5, CONTENT_PADDING + in_vol_y),
		accent_color,
		LINE_THICKNESS,
		true
	)
	draw_string(
		get_theme_default_font(),
		in_begin_pos + Vector2(0, ThemeUtils.FONT_SIZE + 2),
		"in (bus) %0.1fdB" % input_volume,
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ThemeUtils.FONT_SIZE,
		text_color
	)
	
	# Draw output
	var out_vol_y := db_to_y(output_volume, useful_height)
	var out_being_pos := Vector2(CONTENT_PADDING + useful_width * 0.5, CONTENT_PADDING + out_vol_y)
	draw_line(
		out_being_pos,
		Vector2(CONTENT_PADDING + useful_width, CONTENT_PADDING + out_vol_y),
		Color.RED,
		LINE_THICKNESS,
		true
	)
	draw_string(
		get_theme_default_font(),
		out_being_pos + Vector2(0, ThemeUtils.FONT_SIZE + 2),
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
	
	# Scale
	layout_offset_x = db_scale.draw(
		Vector2(rect.size.x - CONTENT_PADDING, CONTENT_PADDING),
		rect.size.y - CONTENT_PADDING * 2.0,
		get_theme_default_font(),
		ThemeUtils.modify_color(text_color, 0.5)
	)

func db_to_y(db: float, height: float) -> float:
	var t := (db - DbScale.MAX_DB) / (DbScale.MIN_DB - DbScale.MAX_DB)
	return t * height
