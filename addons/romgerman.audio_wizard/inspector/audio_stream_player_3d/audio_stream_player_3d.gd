extends EditorInspectorPlugin

const InspectorEditor := preload("res://addons/romgerman.audio_wizard/inspector/audio_stream_player_3d/audio_stream_player_3d_editor.tscn")

func _can_handle(object: Object) -> bool:
	return object is AudioStreamPlayer3D

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name == "attenuation_model":
		var ie := InspectorEditor.instantiate()
		ie.target = object
		add_custom_control(ie)
	return false
