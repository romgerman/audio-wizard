extends EditorInspectorPlugin

const USE_EDITOR_AUDIO_BUS_FIX := true

func _can_handle(object: Object) -> bool:
	return object is AudioEffect

var is_parsing: bool = false

func _parse_begin(object: Object) -> void:
	_find_editor_buses_ctrl()
	is_parsing = true

func _parse_property(
	object: Object,
	type: Variant.Type,
	name: String,
	hint_type: PropertyHint,
	hint_string: String,
	usage_flags: int,
	wide: bool
) -> bool:
	if is_parsing:
		var fake_ctrl = Control.new()
		fake_ctrl.name = "Fake(Control)"
		fake_ctrl.visible = false
		fake_ctrl.process_mode = Node.PROCESS_MODE_DISABLED
		add_custom_control(fake_ctrl)
		_process_category.call_deferred(fake_ctrl, object)
		is_parsing = false
	return false

func _process_category(ctrl: Control, target: AudioEffect) -> void:
	var p := ctrl.get_parent()
	var category_ctrl: Control = null
	
	while p:
		var cats := p.find_children("*", "EditorInspectorCategory", false, false)
		
		if not cats.is_empty():
			category_ctrl = cats[0]
			break
		
		p = p.get_parent()
	
	if not category_ctrl:
		return
	
	_add_checkbox(category_ctrl, target)

func _add_checkbox(ctrl: Control, target: AudioEffect) -> void:
	var checkbox := CheckButton.new()
	checkbox.anchor_left = 0.0
	checkbox.anchor_top = 0.5
	checkbox.anchor_right = 0.0
	checkbox.anchor_bottom = 0.5
	checkbox.visible = false
	checkbox.button_pressed = _get_effect_enabled(target)
	checkbox.toggled.connect(_set_effect_enabled.bind(target))
	
	var bus_checked_fn := func (bus_index: int, eff_index: int, value: bool):
		if bus_index == -1 or eff_index == -1:
			return
		var eff := AudioServer.get_bus_effect(bus_index, eff_index)
		if eff == target:
			checkbox.set_pressed_no_signal(value)
	
	_editor_bus_eff_checked.connect(bus_checked_fn)
	checkbox.tree_exited.connect(_editor_bus_eff_checked.disconnect.bind(bus_checked_fn))
	
	var ur_history_changed := func ():
		checkbox.set_pressed_no_signal(_get_effect_enabled(target))
	
	var ur := EditorInterface.get_editor_undo_redo()
	ur.version_changed.connect(ur_history_changed)
	checkbox.tree_exited.connect(ur.version_changed.disconnect.bind(ur_history_changed))
	
	ctrl.add_child(checkbox)
	
	checkbox.offset_left = 0.0
	checkbox.offset_top = -checkbox.size.y * 0.5
	checkbox.offset_right = 0.0
	checkbox.offset_bottom = checkbox.size.y * 0.5
	checkbox.visible = true

func _get_effect_enabled(eff: AudioEffect) -> bool:
	var bus_opts := _find_effect_in_bus(eff)
	if bus_opts[0] == -1 or bus_opts[1] == -1:
		return false
	return AudioServer.is_bus_effect_enabled(bus_opts[0], bus_opts[1])

func _set_effect_enabled(value: bool, eff: AudioEffect) -> void:
	var bus_opts := _find_effect_in_bus(eff)
	
	var ur := EditorInterface.get_editor_undo_redo()
	ur.create_action("Toggle Audio Bus Effect")
	ur.add_do_method(self, "_do_undo_action_audio_server_effect_enabled", bus_opts[0], bus_opts[1], value)
	ur.add_undo_method(self, "_do_undo_action_audio_server_effect_enabled", bus_opts[0], bus_opts[1], not value)
	ur.commit_action()

func _do_undo_action_audio_server_effect_enabled(bus_index: int, eff_index: int, enabled: bool) -> void:
	AudioServer.set_bus_effect_enabled(bus_index, eff_index, enabled)
	_update_audio_effect_ui(bus_index, eff_index, enabled)
	_editor_bus_eff_checked.emit(bus_index, eff_index, enabled)

func _find_effect_in_bus(eff: AudioEffect) -> Array:
	var used_bus_index := -1
	var used_eff_index := -1
	for bus_index in AudioServer.bus_count:
		if used_eff_index != -1:
			break
		for eff_index in AudioServer.get_bus_effect_count(bus_index):
			if AudioServer.get_bus_effect(bus_index, eff_index) == eff:
				used_bus_index = bus_index
				used_eff_index = eff_index
				break
	return [used_bus_index, used_eff_index]

# INFO: editor ui update fix below

var editor_buses_ctrl: Control
signal _editor_bus_eff_checked(bus_index: int, eff_index: int, value: bool)

func _find_editor_buses_ctrl() -> void:
	if USE_EDITOR_AUDIO_BUS_FIX and not editor_buses_ctrl:
		var buses_ctrls := EditorInterface.get_base_control().find_children("*", "EditorAudioBuses", true, false)
		if not buses_ctrls.is_empty():
			editor_buses_ctrl = buses_ctrls[0]
			
			# Feedback from the EditorAudioBuses control
			_connect_editor_audio_buses_feedback()
			AudioServer.bus_layout_changed.connect(_connect_editor_audio_buses_feedback)

func _connect_editor_audio_buses_feedback() -> void:
	var bus_ctrls := editor_buses_ctrl.find_children("*", "EditorAudioBus", true, false)
	var idx := 0
	for bus_ctrl: Control in bus_ctrls:
		var eff_tree := bus_ctrl.find_children("*", "Tree", true, false)[0] as Tree
		eff_tree.item_edited.connect(_editor_audio_bus_tree_item_edited.bind(idx, eff_tree), CONNECT_REFERENCE_COUNTED)
		idx += 1

func _editor_audio_bus_tree_item_edited(bus_index: int, eff_tree: Tree) -> void:
	var item := eff_tree.get_edited()
	if item.get_metadata(0) == null:
		return
	var index := item.get_metadata(0)
	_editor_bus_eff_checked.emit(bus_index, index, item.is_checked(0))

func _update_audio_effect_ui(bus_index: int, eff_index: int, checked: bool) -> void:
	if USE_EDITOR_AUDIO_BUS_FIX and editor_buses_ctrl:
		var bus_ctrls := editor_buses_ctrl.find_children("*", "EditorAudioBus", true, false)
		var current_bus := bus_ctrls[bus_index] as Control
		var eff_tree := current_bus.find_children("*", "Tree", true, false)[0] as Tree
		var eff_tree_item := eff_tree.get_root().get_child(eff_index)
		eff_tree_item.set_checked(0, checked)
