extends RefCounted

class FindResult:
	var bus_index := -1
	var eff_index := -1
	
	var is_empty: bool:
		get:
			return bus_index == -1 or eff_index == -1
	
	func _init(used_bus_index: int, used_eff_index: int) -> void:
		bus_index = used_bus_index
		eff_index = used_eff_index

static func find_effect_bus(object: AudioEffect) -> FindResult:
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
	
	return FindResult.new(used_bus_index, used_eff_index)
