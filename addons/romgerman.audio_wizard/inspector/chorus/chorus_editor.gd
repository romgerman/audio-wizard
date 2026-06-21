@tool
extends "../effect_editor_base.gd"

const MIN_DELAY_MS := 0.0
const MAX_DELAY_MS := 50.0
const MIN_LEVEL_DB := -60.0
const MAX_LEVEL_DB := 24.0
const MAX_RATE_HZ := 20.0
const MIN_DEPTH_MS := 0.0
const MAX_DEPTH_MS := 20.0

const MIN_RESOLUTION := 32
const MAX_RESOLUTION := 512
const MARKER_SIZE := 8.0

const VOICE_COLOR := [
	Color.BLUE,
	Color.GREEN,
	Color.YELLOW,
	Color.RED
]

func _ready() -> void:
	if eff_handle.has_effect():
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)

#func _process(_delta: float) -> void:
	#if eff_handle.has_effect():
		#queue_redraw()

func _draw() -> void:
	draw_layout()
	if eff_handle.has_effect():
		draw_voices()
	draw_overlay()

func draw_voices() -> void:
	var rect := get_rect().grow(-CONTENT_PADDING)
	var useful_width := rect.size.x
	
	var eff_chorus := eff_handle.get_effect() as AudioEffectChorus
	
	for voice_index in eff_chorus.voice_count:
		var voice_pan := eff_chorus.get_voice_pan(voice_index)
		var voice_delay := eff_chorus.get_voice_delay_ms(voice_index)
		var voice_level := eff_chorus.get_voice_level_db(voice_index)
		var voice_rate_hz := eff_chorus.get_voice_rate_hz(voice_index)
		var voice_depth_ms := eff_chorus.get_voice_depth_ms(voice_index)
		
		var level_mod := remap(voice_level, MIN_LEVEL_DB, MAX_LEVEL_DB, 0.1, 1.0)
		var freq := voice_rate_hz
		var amplitude := remap(voice_depth_ms, MIN_DEPTH_MS, MAX_DEPTH_MS, 0.0, rect.size.y * 0.25)
		var max_depth_frames := (voice_depth_ms / 1000.0) * AudioServer.get_mix_rate()
		var offset_ms := MIN_DELAY_MS + voice_delay * MAX_DELAY_MS
		var pan_mod_y := remap(voice_pan, -1.0, 1.0, CONTENT_PADDING * 2.0 + ThemeUtils.FONT_SIZE + amplitude * 0.5, rect.size.y + ThemeUtils.FONT_SIZE * 0.5 - amplitude * 0.5)
		
		var points := PackedVector2Array()
		var resolution := remap(freq, 0.0, MAX_RATE_HZ, MIN_RESOLUTION, MAX_RESOLUTION)
		for i in resolution:
			var t := float(i) / float(resolution)
			var x := t * (useful_width - ThemeUtils.FONT_SIZE * 0.5)
			var y := amplitude * sin(PI * 2.0 * freq * t + offset_ms / 1000.0)
			points.push_back(Vector2(x + CONTENT_PADDING, pan_mod_y + y - MARKER_SIZE))
		var color := VOICE_COLOR[voice_index] as Color
		color.s = 0.50
		color.a = level_mod
		draw_polyline(points, ThemeUtils.modify_color(color, 0.25), line_thickness_primary, true)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)

func draw_overlay() -> void:
	var rect := get_rect()
	var content_rect := rect.grow(-CONTENT_PADDING)
	
	var offset := 0.0
	for i in VOICE_COLOR.size():
		var color := VOICE_COLOR[i] as Color
		color.s = 0.50
		draw_line(
			Vector2(CONTENT_PADDING + offset, content_rect.size.y + CONTENT_PADDING - MARKER_SIZE * 0.5),
			Vector2(CONTENT_PADDING + offset + MARKER_SIZE, content_rect.size.y + CONTENT_PADDING - MARKER_SIZE * 0.5),
			ThemeUtils.modify_color(color, 0.25),
			MARKER_SIZE,
			false
		)
		draw_string(
			get_theme_default_font(),
			Vector2(
				CONTENT_PADDING + offset + MARKER_SIZE + ThemeUtils.FONT_SIZE * 0.5,
				content_rect.size.y + CONTENT_PADDING
			),
			str(i + 1),
			HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			ThemeUtils.FONT_SIZE,
			ThemeUtils.modify_color(text_color, 0.3)
		)
		
		offset += CONTENT_PADDING + MARKER_SIZE + ThemeUtils.FONT_SIZE #content_rect.size.x / VOICE_COLOR.size()
	
	# L
	draw_string(
		get_theme_default_font(),
		Vector2(content_rect.size.x + CONTENT_PADDING - ThemeUtils.FONT_SIZE * 0.5, CONTENT_PADDING + ThemeUtils.FONT_SIZE),
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
			content_rect.size.x + CONTENT_PADDING - ThemeUtils.FONT_SIZE * 0.5,
			content_rect.size.y + ThemeUtils.FONT_SIZE
		),
		"R",
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		ThemeUtils.FONT_SIZE,
		ThemeUtils.modify_color(text_color, 0.5)
	)
