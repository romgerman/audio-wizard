@tool
extends "../effect_editor_base.gd"

const TAP_MIN_DELAY_MS := 0.0
const TAP_MAX_DELAY_MS := 1500.0
const TAP_MIN_LEVEL_DB := -60.0
const TAP_MAX_LEVEL_DB := 0.0
const FEEDBACK_LOWPASS_MIN_HZ := 1.0
const FEEDBACK_LOWPASS_MAX_HZ := 16000.0

const CONTENT_PADDING := 12.0
const RESOLUTION := 128
const FEEDBACK_RESOLUTION := 48
const LINE_THICKNESS := 3.0

func _ready() -> void:
	if eff_handle.has_effect():
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)

#func _process(delta: float) -> void:
	#if eff_ref:
		#queue_redraw()

func _draw() -> void:
	draw_layout()
	if eff_handle.has_effect():
		draw_representation()
	draw_overlay()

func draw_representation() -> void:
	var rect := get_rect().grow(-CONTENT_PADDING)
	var eff_delay := eff_handle.get_effect() as AudioEffectDelay
	
	var tap_origin := rect.get_center() - Vector2(0, -rect.size.y * 0.5)
	if eff_delay.feedback_active:
		draw_feedback(tap_origin, rect)
	if eff_delay.tap1_active:
		draw_tap(1, tap_origin, rect)
	if eff_delay.tap2_active:
		draw_tap(2, tap_origin, rect)

func draw_tap(num: int, pos: Vector2, rect: Rect2) -> void:
	var eff_delay := eff_handle.get_effect() as AudioEffectDelay
	var tap_delay: float = eff_delay.get("tap%s_delay_ms" % num)
	var radius := lerpf(10.0, rect.size.y, tap_delay / (TAP_MAX_DELAY_MS - TAP_MIN_DELAY_MS))

	var points := PackedVector2Array()
	for i in RESOLUTION:
		var t := float(i) / float(RESOLUTION - 1)
		var rad := t * PI + PI * 0.5
		var x := sin(rad) * radius
		var y := cos(rad) * radius
		
		points.push_back(pos + Vector2(x, y))
	
	var tap_level: float = eff_delay.get("tap%s_level_db" % num)
	var brightness := lerpf(0.05, 1.0, -(tap_level / (TAP_MAX_LEVEL_DB - TAP_MIN_LEVEL_DB)))
	
	draw_polyline(points, ThemeUtils.modify_color(accent_color, brightness), LINE_THICKNESS, true)
	
	var tap_pan: float = eff_delay.get("tap%s_pan" % num)
	var t := (tap_pan + 1.0) / 2.0
	var rad := t * PI + PI * 0.5
	var pan_pos := Vector2(
		sin(-rad) * radius,
		cos(-rad) * radius
	)
	
	draw_circle(pos + pan_pos, LINE_THICKNESS * 2.0, accent_color, true, -1, true)

func draw_feedback(pos: Vector2, rect: Rect2) -> void:
	var eff_delay := eff_handle.get_effect() as AudioEffectDelay
	var feedback_delay := eff_delay.feedback_delay_ms
	var feedback_level := eff_delay.feedback_level_db
	var lowpass := eff_delay.feedback_lowpass
	
	var radius := lerpf(5.0, rect.size.y, (feedback_delay - TAP_MIN_DELAY_MS) / (TAP_MAX_DELAY_MS - TAP_MIN_DELAY_MS))
	var brightness := (feedback_level - TAP_MAX_LEVEL_DB) / (TAP_MIN_LEVEL_DB - TAP_MAX_LEVEL_DB)
	var saturation := (lowpass - FEEDBACK_LOWPASS_MIN_HZ) / (FEEDBACK_LOWPASS_MAX_HZ - FEEDBACK_LOWPASS_MIN_HZ)
	
	var feedback_arc_distance := remap(
		feedback_delay,
		TAP_MIN_DELAY_MS,
		TAP_MAX_DELAY_MS,
		3.0,
		rect.size.y
	)
	var feedback_arc_amount : = ceil(rect.size.y / feedback_arc_distance)
	for ai in feedback_arc_amount:
		var arc_t := float(ai) / float(feedback_arc_amount)
		var falloff := -log(1.0 - arc_t) / log(10.0)
		var color := Color(accent_color.lerp(Color.RED, 0.6 - sqrt(brightness)), 1.0 - lerpf(1.0, falloff * brightness, 1.0 - brightness))
		color.s = lerpf(1.0, falloff * saturation, 1.0 - saturation)
		
		draw_arc(
			pos,
			radius + ai * feedback_arc_distance,
			PI,
			PI * 2.0,
			FEEDBACK_RESOLUTION,
			color,
			0.5,
			true
		)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)

func draw_overlay() -> void:
	var rect := get_rect().grow(-CONTENT_PADDING)
	
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
			rect.size.x + r_size.x * 0.5,
			CONTENT_PADDING + ThemeUtils.FONT_SIZE
		),
		"R",
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
		r_size.x,
		ThemeUtils.FONT_SIZE,
		ThemeUtils.modify_color(text_color, 0.5)
	)
