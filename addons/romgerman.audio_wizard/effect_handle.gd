@tool
extends RefCounted

var audio_bus_index := -1
var audio_eff_index := -1

var effect_cached: AudioEffect

func has_effect() -> bool:
	return audio_bus_index != -1 and audio_eff_index != -1

func get_effect() -> AudioEffect:
	if not effect_cached:
		effect_cached = AudioServer.get_bus_effect(audio_bus_index, audio_eff_index)
	return effect_cached

static func create(bus_index: int, eff_index: int):
	var handle := new()
	handle.audio_bus_index = bus_index
	handle.audio_eff_index = eff_index
	return handle
