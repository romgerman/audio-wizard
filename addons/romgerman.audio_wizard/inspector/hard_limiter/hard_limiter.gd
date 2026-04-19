extends EditorInspectorPlugin

const InspectorEditor := preload("res://addons/romgerman.audio_wizard/inspector/hard_limiter/hard_limiter_editor.tscn")

func _can_handle(object: Object) -> bool:
	return object is AudioEffectHardLimiter

func _parse_begin(object: Object) -> void:
	var used_bus_index := -1
	var used_eff_index := -1
	for bus_index in AudioServer.bus_count:
		if used_eff_index != -1:
			break
		for eff_index in AudioServer.get_bus_effect_count(bus_index):
			if AudioServer.get_bus_effect(bus_index, eff_index) == object:
				used_bus_index = bus_index
				used_eff_index = eff_index
				break
	
	var ie := InspectorEditor.instantiate()
	ie.audio_bus_index = used_bus_index
	ie.audio_eff_index = used_eff_index
	add_custom_control(ie)
