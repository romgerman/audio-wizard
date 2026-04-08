@tool
extends EditorPlugin

const AmplifyInspector := preload("res://addons/romgerman.audio_wizard/inspector/amplify/amplify.gd")
const FilterInspector := preload("res://addons/romgerman.audio_wizard/inspector/filter/filter.gd")
const CaptureInspector := preload("res://addons/romgerman.audio_wizard/inspector/capture/capture.gd")
const ChorusInspector := preload("res://addons/romgerman.audio_wizard/inspector/chorus/chorus.gd")
const CompressorInspector := preload("res://addons/romgerman.audio_wizard/inspector/compressor/compressor.gd")
const DelayInspector := preload("res://addons/romgerman.audio_wizard/inspector/delay/delay.gd")
const DistortionInspector := preload("res://addons/romgerman.audio_wizard/inspector/distortion/distortion.gd")

var eff_amplify: AmplifyInspector
var eff_filter: FilterInspector
var eff_capture: CaptureInspector
var eff_chorus: ChorusInspector
var eff_compressor: CompressorInspector
var eff_delay: DelayInspector
var eff_distortion: DistortionInspector

func _enable_plugin() -> void:
	# Add autoloads here.
	pass

func _disable_plugin() -> void:
	# Remove autoloads here.
	pass

func _enter_tree() -> void:
	eff_amplify = AmplifyInspector.new()
	add_inspector_plugin(eff_amplify)
	eff_filter = FilterInspector.new()
	add_inspector_plugin(eff_filter)
	eff_capture = CaptureInspector.new()
	add_inspector_plugin(eff_capture)
	eff_chorus = ChorusInspector.new()
	add_inspector_plugin(eff_chorus)
	eff_compressor = CompressorInspector.new()
	add_inspector_plugin(eff_compressor)
	eff_delay = DelayInspector.new()
	add_inspector_plugin(eff_delay)
	eff_distortion = DistortionInspector.new()
	add_inspector_plugin(eff_distortion)

func _exit_tree() -> void:
	remove_inspector_plugin(eff_amplify)
	remove_inspector_plugin(eff_filter)
	remove_inspector_plugin(eff_capture)
	remove_inspector_plugin(eff_chorus)
	remove_inspector_plugin(eff_compressor)
	remove_inspector_plugin(eff_delay)
	remove_inspector_plugin(eff_distortion)
