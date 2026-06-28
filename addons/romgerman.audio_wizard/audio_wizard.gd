@tool
extends EditorPlugin

const AmplifyInspector := preload("res://addons/romgerman.audio_wizard/inspector/amplify/amplify.gd")
const FilterInspector := preload("res://addons/romgerman.audio_wizard/inspector/filter/filter.gd")
const CaptureInspector := preload("res://addons/romgerman.audio_wizard/inspector/capture/capture.gd")
const ChorusInspector := preload("res://addons/romgerman.audio_wizard/inspector/chorus/chorus.gd")
const CompressorInspector := preload("res://addons/romgerman.audio_wizard/inspector/compressor/compressor.gd")
const DelayInspector := preload("res://addons/romgerman.audio_wizard/inspector/delay/delay.gd")
const DistortionInspector := preload("res://addons/romgerman.audio_wizard/inspector/distortion/distortion.gd")
const EQInspector := preload("res://addons/romgerman.audio_wizard/inspector/eq/eq.gd")
const HardLimiterInspector := preload("res://addons/romgerman.audio_wizard/inspector/hard_limiter/hard_limiter.gd")
const PannerInspector := preload("res://addons/romgerman.audio_wizard/inspector/panner/panner.gd")
const StereoEnhanceInspector := preload("res://addons/romgerman.audio_wizard/inspector/stereo_enhance/stereo_enhance.gd")
const PhaserInspector := preload("res://addons/romgerman.audio_wizard/inspector/phaser/phaser.gd")

const AudioStreamPlayer3DInspector := preload("res://addons/romgerman.audio_wizard/inspector/audio_stream_player_3d/audio_stream_player_3d.gd")
const AudioEffectToggleInspector := preload("res://addons/romgerman.audio_wizard/inspector/effect_toggle.gd")

var eff_amplify: AmplifyInspector
var eff_filter: FilterInspector
var eff_capture: CaptureInspector
var eff_chorus: ChorusInspector
var eff_compressor: CompressorInspector
var eff_delay: DelayInspector
var eff_distortion: DistortionInspector
var eff_eq: EQInspector
var eff_hard_limiter: HardLimiterInspector
var eff_panner: PannerInspector
var eff_stereo_enhance: StereoEnhanceInspector
var eff_phaser: PhaserInspector

var audio_stream_player_3d: AudioStreamPlayer3DInspector
var audio_effect_toggle: AudioEffectToggleInspector

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
	eff_eq = EQInspector.new()
	add_inspector_plugin(eff_eq)
	eff_hard_limiter = HardLimiterInspector.new()
	add_inspector_plugin(eff_hard_limiter)
	eff_panner = PannerInspector.new()
	add_inspector_plugin(eff_panner)
	eff_stereo_enhance = StereoEnhanceInspector.new()
	add_inspector_plugin(eff_stereo_enhance)
	eff_phaser = PhaserInspector.new()
	add_inspector_plugin(eff_phaser)
	
	audio_stream_player_3d = AudioStreamPlayer3DInspector.new()
	add_inspector_plugin(audio_stream_player_3d)
	audio_effect_toggle = AudioEffectToggleInspector.new()
	add_inspector_plugin(audio_effect_toggle)

func _exit_tree() -> void:
	remove_inspector_plugin(eff_amplify)
	remove_inspector_plugin(eff_filter)
	remove_inspector_plugin(eff_capture)
	remove_inspector_plugin(eff_chorus)
	remove_inspector_plugin(eff_compressor)
	remove_inspector_plugin(eff_delay)
	remove_inspector_plugin(eff_distortion)
	remove_inspector_plugin(eff_eq)
	remove_inspector_plugin(eff_hard_limiter)
	remove_inspector_plugin(eff_panner)
	remove_inspector_plugin(eff_stereo_enhance)
	remove_inspector_plugin(eff_phaser)
	
	remove_inspector_plugin(audio_stream_player_3d)
	remove_inspector_plugin(audio_effect_toggle)
