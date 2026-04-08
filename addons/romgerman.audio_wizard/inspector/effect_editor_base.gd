extends Control

const ThemeUtils := preload("res://addons/romgerman.audio_wizard/theme_utils.gd")

var audio_bus_index := -1
var audio_eff_index := -1

var eff_ref: AudioEffect

var base_color: Color
var accent_color: Color
var text_color: Color
var is_light_theme: bool

func _ready() -> void:
	if audio_bus_index != -1 and audio_eff_index != -1:
		eff_ref = AudioServer.get_bus_effect(audio_bus_index, audio_eff_index)
	
	base_color = ThemeUtils.get_base_color(self)
	accent_color = ThemeUtils.get_accent_color(self)
	is_light_theme = ThemeUtils.is_light_color(base_color)
	text_color = Color.BLACK if is_light_theme else Color.WHITE
