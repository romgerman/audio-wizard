@tool
extends "../effect_editor_base.gd"

const DbScale := preload("res://addons/romgerman.audio_wizard/inspector/db_scale.gd")
const FreqScale := preload("res://addons/romgerman.audio_wizard/inspector/freq_scale.gd")
const ThemeUtils := preload("res://addons/romgerman.audio_wizard/theme_utils.gd")

const CONTENT_PADDING := 12.0
const GRAPH_RESOLUTION := 256

var db_scale: DbScale
var freq_scale: FreqScale
var layout_offset_x := 0.0

var base_color: Color
var accent_color: Color
var text_color: Color
var is_light_theme: bool

func _ready() -> void:
	super._ready()
	
	if eff_ref:
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)
	
	db_scale = DbScale.new(self)
	freq_scale = FreqScale.new(self)
	
	base_color = ThemeUtils.get_base_color(self)
	accent_color = ThemeUtils.get_accent_color(self)
	is_light_theme = ThemeUtils.is_light_color(base_color)
	text_color = Color.BLACK if is_light_theme else Color.WHITE

func _draw() -> void:
	draw_layout()
	if eff_ref:
		draw_graph()

func draw_graph() -> void:
	var rect := get_rect()
	var useful_width := rect.size.x - layout_offset_x - CONTENT_PADDING * 2.0
	var useful_height := rect.size.y - CONTENT_PADDING * 2.0
	var eff_filter := eff_ref as AudioEffectFilter
	var points := PackedVector2Array()
	
	for i in GRAPH_RESOLUTION:
		var t := float(i) / float(GRAPH_RESOLUTION - 1)
		var freq := FreqScale.MIN_FREQ * pow(FreqScale.MAX_FREQ / FreqScale.MIN_FREQ, t)
		var mag := get_db_at_freq(
			freq,
			eff_filter.cutoff_hz,
			eff_filter.resonance,
			eff_filter.gain,
			eff_filter.db + 1
		)
		var db := 20.0 * log(mag) / log(10.0)
		
		var x := t * useful_width
		var db_clamped := clampf(db, DbScale.MIN_DB, DbScale.MAX_DB)
		var y := remap(db_clamped, DbScale.MIN_DB, DbScale.MAX_DB, useful_height, 0.0)
		points.push_back(Vector2(x + CONTENT_PADDING, y + CONTENT_PADDING))
	
	draw_polyline(points, accent_color, 1.0, true)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)
	
	# Db scale
	layout_offset_x = db_scale.draw(
		Vector2(rect.size.x - CONTENT_PADDING, CONTENT_PADDING),
		rect.size.y - CONTENT_PADDING * 2.0,
		get_theme_default_font(),
		ThemeUtils.modify_color(text_color, 0.5)
	)
	
	# Freq scale
	var useful_width := rect.size.x - layout_offset_x - CONTENT_PADDING * 2.0
	freq_scale.draw(
		Vector2(CONTENT_PADDING, rect.size.y - CONTENT_PADDING),
		useful_width,
		get_theme_default_font(),
		ThemeUtils.modify_color(text_color, 0.5)
	)

# This method is compiled from: servers/audio/audio_filter_sw.cpp
#/**************************************************************************/
#/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
#/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
#/*                                                                        */
#/* Permission is hereby granted, free of charge, to any person obtaining  */
#/* a copy of this software and associated documentation files (the        */
#/* "Software"), to deal in the Software without restriction, including    */
#/* without limitation the rights to use, copy, modify, merge, publish,    */
#/* distribute, sublicense, and/or sell copies of the Software, and to     */
#/* permit persons to whom the Software is furnished to do so, subject to  */
#/* the following conditions:                                              */
#/*                                                                        */
#/* The above copyright notice and this permission notice shall be         */
#/* included in all copies or substantial portions of the Software.        */
#/*                                                                        */
#/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
#/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
#/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
#/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
#/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
#/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
#/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
#/**************************************************************************/
func get_db_at_freq(p_freq: float, cutoff_hz: float, resonance: float, gain_db: float, stages: int) -> float:
	var sampling_rate := 44100.0
	var sr_limit := (sampling_rate / 2) + 512
	
	var final_cutoff := sr_limit if cutoff_hz > sr_limit else cutoff_hz
	if final_cutoff < 1:
		final_cutoff = 1
	
	var omega := TAU * final_cutoff / sampling_rate

	var sin_v := sin(omega)
	var cos_v := cos(omega)
	
	var Q := resonance
	if Q <= 0.0:
		Q = 0.0001
	
	var tmpgain := gain_db
	if tmpgain < 0.001:
		tmpgain = 0.001
	
	if stages > 1:
		Q = pow(Q, 1.0 / stages) if Q > 1.0 else Q
		tmpgain = pow(tmpgain, 1.0 / (stages + 1))
	
	var alpha := sin_v / (2 * Q)
	var a0 := 1.0 + alpha
	
	var a1 := 0.0
	var a2 := 0.0
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	
	if eff_ref is AudioEffectHighPassFilter:
		b0 = (1.0 + cos_v) / 2.0
		b1 = -(1.0 + cos_v)
		b2 = (1.0 + cos_v) / 2.0
		a1 = -2.0 * cos_v
		a2 = 1.0 - alpha
	elif eff_ref is AudioEffectBandPassFilter:
		b0 = alpha * sqrt(Q + 1)
		b1 = 0.0
		b2 = -alpha * sqrt(Q + 1)
		a1 = -2.0 * cos_v
		a2 = 1.0 - alpha
	elif eff_ref is AudioEffectNotchFilter:
		b0 = 1.0
		b1 = -2.0 * cos_v
		b2 = 1.0
		a1 = -2.0 * cos_v
		a2 = 1.0 - alpha
	#elif eff_ref is PeakFilter
	elif eff_ref is AudioEffectBandLimitFilter:
		var hicutoff := resonance
		var centercutoff := (cutoff_hz + resonance) / 2.0
		var bandwidth := (log(centercutoff) - log(hicutoff)) / log(2.0)
		omega = TAU * centercutoff / sampling_rate
		alpha = sin(omega) * sinh(log(2.0) / 2 * bandwidth * omega / sin(omega))
		a0 = 1 + alpha

		b0 = alpha
		b1 = 0
		b2 = -alpha
		a1 = -2 * cos(omega)
		a2 = 1 - alpha
	elif eff_ref is AudioEffectLowShelfFilter:
		var tmpq := sqrt(Q)
		if tmpq <= 0:
			tmpq = 0.001
		var beta := sqrt(tmpgain) / tmpq

		a0 = (tmpgain + 1.0) + (tmpgain - 1.0) * cos_v + beta * sin_v
		b0 = tmpgain * ((tmpgain + 1.0) - (tmpgain - 1.0) * cos_v + beta * sin_v)
		b1 = 2.0 * tmpgain * ((tmpgain - 1.0) - (tmpgain + 1.0) * cos_v)
		b2 = tmpgain * ((tmpgain + 1.0) - (tmpgain - 1.0) * cos_v - beta * sin_v)
		a1 = -2.0 * ((tmpgain - 1.0) + (tmpgain + 1.0) * cos_v)
		a2 = ((tmpgain + 1.0) + (tmpgain - 1.0) * cos_v - beta * sin_v)
	elif eff_ref is AudioEffectHighShelfFilter:
		var tmpq := sqrt(Q)
		if tmpq <= 0:
			tmpq = 0.001
		var beta := sqrt(tmpgain) / tmpq

		a0 = (tmpgain + 1.0) - (tmpgain - 1.0) * cos_v + beta * sin_v
		b0 = tmpgain * ((tmpgain + 1.0) + (tmpgain - 1.0) * cos_v + beta * sin_v)
		b1 = -2.0 * tmpgain * ((tmpgain - 1.0) + (tmpgain + 1.0) * cos_v)
		b2 = tmpgain * ((tmpgain + 1.0) + (tmpgain - 1.0) * cos_v - beta * sin_v)
		a1 = 2.0 * ((tmpgain - 1.0) - (tmpgain + 1.0) * cos_v)
		a2 = ((tmpgain + 1.0) - (tmpgain - 1.0) * cos_v - beta * sin_v)
	else: # eff_ref is AudioEffectLowPassFilter
		b0 = (1.0 - cos_v) / 2.0
		b1 = 1.0 - cos_v
		b2 = (1.0 - cos_v) / 2.0
		a1 = -2.0 * cos_v
		a2 = 1.0 - alpha
	
	b0 /= a0
	b1 /= a0
	b2 /= a0
	a1 /= 0.0 - a0
	a2 /= 0.0 - a0
	
	# response
	var freq := p_freq / sampling_rate * TAU

	var cx := b0
	var cy := 0.0

	cx += cos(freq) * b1
	cy -= sin(freq) * b1
	cx += cos(2.0 * freq) * b2
	cy -= sin(2.0 * freq) * b2

	var H := cx * cx + cy * cy
	cx = 1.0
	cy = 0.0

	cx -= cos(freq) * a1
	cy += sin(freq) * a1
	cx -= cos(2.0 * freq) * a2
	cy += sin(2.0 * freq) * a2

	H = H / (cx * cx + cy * cy)
	return H
