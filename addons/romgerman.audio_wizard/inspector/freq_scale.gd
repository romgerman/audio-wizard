extends RefCounted

const FONT_SIZE := 12
const TICK_HEIGHT := 6
const TICK_THICKNESS := 1.0
const MIN_FREQ := 10.0
const MAX_FREQ := 21000.0

var tick_marks := [20.0, 100.0, 1000.0, 5000.0, 10000.0, 20000.0]

var owner_ctrl: Control

func _init(ctrl: Control) -> void:
	owner_ctrl = ctrl

## Returns height of the drawn scale
func draw(pos: Vector2, max_width: float, font: Font, color: Color = Color.GRAY) -> float:
	var tick_text_sizes := []
	
	for tick_freq in tick_marks:
		var tick_string := format_freq(tick_freq)
		var tick_string_size := font.get_string_size(
			tick_string,
			HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			FONT_SIZE,
			TextServer.JUSTIFICATION_NONE,
			TextServer.DIRECTION_LTR,
			TextServer.ORIENTATION_HORIZONTAL
		)
		tick_text_sizes.push_back(tick_string_size)
	
	var idx := 0
	for tick_freq in tick_marks:
		var x := freq_to_x(tick_freq, max_width)
		
		owner_ctrl.draw_line(
			Vector2(pos.x + x, pos.y - TICK_HEIGHT * 2.0),
			Vector2(pos.x + x, pos.y - TICK_HEIGHT),
			color,
			TICK_THICKNESS
		)
		
		owner_ctrl.draw_string(
			font,
			Vector2(
				pos.x + x - tick_text_sizes[idx].x * 0.5,
				pos.y + TICK_HEIGHT * 1.5
			),
			format_freq(tick_freq),
			HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			FONT_SIZE,
			color,
			TextServer.JUSTIFICATION_NONE
		)
		
		idx += 1
	
	return TICK_HEIGHT + FONT_SIZE

func freq_to_x(freq: float, width: float) -> float:
	var t := log(freq / MIN_FREQ) / log(MAX_FREQ / MIN_FREQ)
	return t * width

func format_freq(freq: float) -> String:
	if freq > 1000.0:
		return str(floori(freq / 1000.0)) + "k"
	else:
		return str(floori(freq))
