extends EditorInspectorPlugin

const EffectHandle := preload("res://addons/romgerman.audio_wizard/effect_handle.gd")
const ResEffectHandle := preload("res://addons/romgerman.audio_wizard/res_effect_handle.gd")
const Utils := preload("res://addons/romgerman.audio_wizard/utils.gd")
const InspectorEditor := preload("res://addons/romgerman.audio_wizard/inspector/filter/filter_editor.tscn")

func _can_handle(object: Object) -> bool:
	return object is AudioEffectFilter

func _parse_begin(object: Object) -> void:
	var result := Utils.find_effect_bus(object)
	var ie := InspectorEditor.instantiate()
	
	if result.is_empty:
		ie.eff_handle = ResEffectHandle.new(object)
	else:
		ie.eff_handle = EffectHandle.create(result.bus_index, result.eff_index)
	add_custom_control(ie)
