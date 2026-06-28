@tool
extends "../effect_editor_base.gd"

const DbScale := preload("res://addons/romgerman.audio_wizard/inspector/db_scale.gd")
const FreqScale := preload("res://addons/romgerman.audio_wizard/inspector/freq_scale.gd")

const GRAPH_RESOLUTION := 256

var freq_scale: FreqScale
var layout_offset_x := 0.0
var layout_offset_y := 0.0

func _ready() -> void:
	if eff_handle.has_effect():
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)
	
	freq_scale = FreqScale.new(self)

func _process(delta: float) -> void:
	if eff_handle.has_effect():
		queue_redraw()
		pass

func _draw() -> void:
	draw_layout()
	if eff_handle.has_effect():
		draw_representation()
	draw_overlay()

func draw_representation() -> void:
	var content_rect := get_rect().grow(-CONTENT_PADDING)
	
	var eff_phaser := eff_handle.get_effect() as AudioEffectPhaser
	var sampling_rate := AudioServer.get_mix_rate()
	
	var min_x := freq_scale.freq_to_x(eff_phaser.range_min_hz, content_rect.size.x)
	draw_rect(
		Rect2(
			Vector2(
				min_x + CONTENT_PADDING,
				CONTENT_PADDING
			),
			Vector2(
				freq_scale.freq_to_x(eff_phaser.range_max_hz, content_rect.size.x) - min_x,
				content_rect.size.y - layout_offset_y
			)
		),
		Color(ThemeUtils.modify_color(accent_color, 0.7), 0.3),
	)
	
	var dmin := eff_phaser.range_min_hz / (sampling_rate / 2.0)
	var dmax := eff_phaser.range_max_hz / (sampling_rate / 2.0)
	
	var points := PackedVector2Array()
	var phase := -0.25
	var avg_freq := dmin + (dmax - dmin) * 0.5
	var d := avg_freq #dmin + (dmax - dmin) * ((sin(phase) + 1.0) / 2.0)
	var a := (1.0 - d) / (1.0 + d)
	for i in GRAPH_RESOLUTION:
		var t := float(i) / float(GRAPH_RESOLUTION - 1)
		var freq := FreqScale.MIN_FREQ * pow(FreqScale.MAX_FREQ / FreqScale.MIN_FREQ, t)
		
		var omega := freq / sampling_rate * TAU
		var r := get_phase_response(omega, a) * 6.0
		
		var x := t * content_rect.size.x
		var r_wrapped := fmod(fmod(r + PI, TAU) + TAU, TAU) - PI

		var y := remap(r_wrapped, -PI, PI, 0.0, content_rect.size.y - layout_offset_y)
		points.push_back(Vector2(x + CONTENT_PADDING, y + CONTENT_PADDING))
	
	if points.size() > 2:
		var smooth_points := ThemeUtils.smooth_polyline(points, PI * 0.5)
		draw_polyline(smooth_points, accent_color, line_thickness_primary, true)

func draw_layout() -> void:
	var rect := get_rect()
	var content_rect := get_rect().grow(-CONTENT_PADDING)
	
	# Background
	draw_rect(rect, base_color, true)
	
	# Freq scale
	var useful_width := rect.size.x - layout_offset_x - CONTENT_PADDING * 2.0
	layout_offset_y = freq_scale.draw(
		Vector2(CONTENT_PADDING, rect.size.y - CONTENT_PADDING),
		useful_width,
		get_theme_default_font(),
		ThemeUtils.modify_color(text_color, 0.5)
	)
	
	draw_line(
		Vector2(CONTENT_PADDING, content_rect.get_center().y + CONTENT_PADDING - layout_offset_y),
		Vector2(CONTENT_PADDING + content_rect.size.x, content_rect.get_center().y + CONTENT_PADDING - layout_offset_y),
		ThemeUtils.modify_color(base_color, 0.2)
	)

func draw_overlay() -> void:
	var content_rect := get_rect().grow(-CONTENT_PADDING)
	
	# -180deg
	draw_string(
		get_theme_default_font(),
		Vector2(CONTENT_PADDING - ThemeUtils.FONT_SIZE * 0.5, CONTENT_PADDING + ThemeUtils.FONT_SIZE),
		"-180.0°",
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		ThemeUtils.FONT_SIZE,
		ThemeUtils.modify_color(text_color, 0.5)
	)
	
	# 180deg
	draw_string(
		get_theme_default_font(),
		Vector2(
			CONTENT_PADDING - ThemeUtils.FONT_SIZE * 0.5,
			content_rect.size.y + ThemeUtils.FONT_SIZE - layout_offset_y
		),
		" 180.0°",
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		ThemeUtils.FONT_SIZE,
		ThemeUtils.modify_color(text_color, 0.5)
	)

func get_phase_response(omega: float, a: float) -> float:
	return -omega - 2.0 * atan2((a * sin(omega)), (1.0 - a * cos(omega)))
