extends RefCounted

const FONT_SIZE := 12

static func get_base_color(ctrl: Control) -> Color:
	var base_color := ctrl.get_theme_color("base_color", "Editor")
	# editor/themes/theme_modern.cpp
	base_color.s = base_color.s * 0.9
	var contrast: float = EditorInterface.get_editor_settings().get_setting("interface/theme/contrast")
	base_color.v = lerpf(base_color.v, 0.0, 1.7 * contrast)
	return base_color

static func get_accent_color(ctrl: Control) -> Color:
	return ctrl.get_theme_color("accent_color", "Editor")

static func is_light_color(color: Color) -> bool:
	return color.v > 0.5

static func modify_color(color: Color, mod: float) -> Color:
	if is_light_color(color):
		return color.darkened(mod)
	else:
		return color.lightened(mod)

static func get_line_thickness(weight: int) -> float:
	if Engine.get_version_info().hex >= 0x040700:
		if weight == 2:
			return 2.0
		elif weight == 1:
			return 1.0
		elif weight == 0:
			return 1.0
	else:
		if weight == 2:
			return 1.0
		elif weight == 1:
			return 1.0
		elif weight == 0:
			return 0.5
	return 1.0

static func smooth_polyline(points: PackedVector2Array, threshold_angle: float) -> PackedVector2Array:
	if points.size() < 2:
		return points
	
	var out := PackedVector2Array()
	
	out.push_back(points[0])
	for i in range(1, points.size() - 1):
		var prev_point := points[i - 1]
		var curr_point := points[i]
		var next_point := points[i + 1]
		
		var dir_in := prev_point.direction_to(curr_point)
		var dir_out := curr_point.direction_to(next_point)
		
		if abs(dir_in.angle_to(dir_out)) > threshold_angle:
			var q_point := curr_point.lerp(prev_point, 0.25)
			var r_point := curr_point.lerp(next_point, 0.25)
			out.push_back(q_point)
			out.push_back(r_point)
		else:
			out.push_back(next_point)
	
	out.push_back(points[points.size() - 1])
	
	return out
