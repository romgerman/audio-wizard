extends Control

var audio_bus_index := -1
var audio_eff_index := -1

var eff_ref: AudioEffect

func _ready() -> void:
	if audio_bus_index != -1 and audio_eff_index != -1:
		eff_ref = AudioServer.get_bus_effect(audio_bus_index, audio_eff_index)
