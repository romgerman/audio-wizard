extends Control

const EffectHandle := preload("res://addons/romgerman.audio_wizard/effect_handle.gd")
const ThemeUtils := preload("res://addons/romgerman.audio_wizard/theme_utils.gd")

const CONTENT_PADDING := 12.0

var eff_handle: EffectHandle = EffectHandle.new()

var base_color: Color
var accent_color: Color
var text_color: Color
var is_light_theme: bool
var line_thickness_primary: float
var line_thickness_secondary: float
var line_thickness_thin: float

func _get_theme_colors() -> void:
	base_color = ThemeUtils.get_base_color(self)
	accent_color = ThemeUtils.get_accent_color(self)
	is_light_theme = ThemeUtils.is_light_color(base_color)
	text_color = Color.BLACK if is_light_theme else Color.WHITE
	line_thickness_primary = ThemeUtils.get_line_thickness(2)
	line_thickness_secondary = ThemeUtils.get_line_thickness(1)
	line_thickness_thin = ThemeUtils.get_line_thickness(0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		_get_theme_colors()
	if what == NOTIFICATION_THEME_CHANGED:
		_get_theme_colors()
		queue_redraw()
