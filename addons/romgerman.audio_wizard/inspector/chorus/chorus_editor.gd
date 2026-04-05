@tool
extends "../effect_editor_base.gd"

const ThemeUtils := preload("res://addons/romgerman.audio_wizard/theme_utils.gd")

const MIN_DELAY_MS := 0.0
const MAX_DELAY_MS := 50.0
const MIN_LEVEL_DB := -60.0
const MAX_LEVEL_DB := 24.0

const CONTENT_PADDING := 12.0
const LINE_THICKNESS := 1.0

var base_color: Color
var accent_color: Color
var text_color: Color
var is_light_theme: bool

func _ready() -> void:
	if audio_bus_index != -1 and audio_eff_index != -1:
		eff_ref = AudioServer.get_bus_effect(audio_bus_index, audio_eff_index)
	
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
		draw_voices()
	draw_overlay()

func draw_voices() -> void:
	var rect := get_rect().grow(-CONTENT_PADDING)
	var useful_width := rect.size.x
	
	var eff_chorus := eff_ref as AudioEffectChorus
	
	for voice_index in eff_chorus.voice_count:
		var voice_pan := eff_chorus.get_voice_pan(voice_index)
		var voice_delay := eff_chorus.get_voice_delay_ms(voice_index)
		var voice_level := eff_chorus.get_voice_level_db(voice_index)
		var base_x := CONTENT_PADDING + useful_width * ((voice_pan + 1.0) / 2.0)
		var level_mod := remap(voice_level, MIN_LEVEL_DB, MAX_LEVEL_DB, 1.0, 0.2)
		
		draw_line(
			Vector2(base_x, CONTENT_PADDING),
			Vector2(base_x, rect.size.y),
			accent_color.lightened(level_mod) if is_light_theme else accent_color.darkened(level_mod),
			voice_delay,
			true
		)
		
		draw_line(
			Vector2(base_x, CONTENT_PADDING),
			Vector2(base_x, rect.size.y),
			accent_color,
			LINE_THICKNESS,
			true
		)
		draw_string(
			get_theme_default_font(),
			Vector2(
				base_x - ThemeUtils.FONT_SIZE * 0.25,
				rect.size.y + ThemeUtils.FONT_SIZE + ThemeUtils.FONT_SIZE * 0.5
			),
			str(voice_index + 1),
			HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			ThemeUtils.FONT_SIZE,
			ThemeUtils.modify_color(text_color, 0.5)
		)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)
	
	# Center line
	draw_line(
		Vector2(rect.size.x * 0.5, CONTENT_PADDING),
		Vector2(rect.size.x * 0.5, rect.size.y - CONTENT_PADDING),
		Color.DIM_GRAY,
	)

func draw_overlay() -> void:
	var rect := get_rect()
	
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
	
	# R
	draw_string(
		get_theme_default_font(),
		Vector2(
			rect.size.x - CONTENT_PADDING - ThemeUtils.FONT_SIZE * 0.5,
			CONTENT_PADDING + ThemeUtils.FONT_SIZE
		),
		"R",
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		ThemeUtils.FONT_SIZE,
		ThemeUtils.modify_color(text_color, 0.5)
	)
