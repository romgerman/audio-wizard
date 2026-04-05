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
		return color.darkened(0.5)
	else:
		return color.lightened(0.5)
