extends "./effect_handle.gd"

var eff: AudioEffect

func _init(_eff: AudioEffect) -> void:
	eff = _eff

func has_effect() -> bool:
	return is_instance_valid(eff)

func get_effect() -> AudioEffect:
	return eff
