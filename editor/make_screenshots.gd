@tool
extends EditorScript

const ScreenshotViewport := preload("res://editor/screenshot_viewport.tscn")

var temp_self
var viewport: SubViewport
var inspector: Control
var inspector_parent: Node
var inspector_index: int

# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	temp_self = self
	viewport = ScreenshotViewport.instantiate()
	
	var root := EditorInterface.get_base_control()
	root.add_child(viewport)
	
	# Right side of the split container
	inspector = EditorInterface.get_inspector().get_parent_control().get_parent_control().get_parent_control().get_parent_control()
	inspector_parent = inspector.get_parent()
	inspector_index = inspector.get_index()
	inspector.reparent(viewport, false)
	
	for bus_index in AudioServer.bus_count:
		for effect_index in AudioServer.get_bus_effect_count(bus_index):
			if AudioServer.is_bus_effect_enabled(bus_index, effect_index):
				var effect_res := AudioServer.get_bus_effect(bus_index, effect_index)
				EditorInterface.get_inspector().edit(effect_res)
				await _render_inspector(effect_res)
	
	inspector.reparent(inspector_parent)
	inspector_parent.move_child(inspector, inspector_index)
	
	viewport.free()
	temp_self = null

func _render_inspector(eff: AudioEffect) -> void:
	var id := eff.resource_name
	
	await RenderingServer.frame_post_draw
	
	var img := viewport.get_texture().get_image()
	img.save_png("user://screenshot_%s.png" % id)
