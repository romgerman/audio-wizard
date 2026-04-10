@tool
extends "../effect_editor_base.gd"

const DbScale := preload("res://addons/romgerman.audio_wizard/inspector/db_scale.gd")
const FreqScale := preload("res://addons/romgerman.audio_wizard/inspector/freq_scale.gd")

const EQ_MIN_DB := -60.0
const EQ_MAX_DB := 24.0

const CONTENT_PADDING := 12.0
const GRAPH_RESOLUTION := 128.0
const LINE_THICKNESS := 2.0

var freq_scale: FreqScale
var db_scale: DbScale

var y_offset := 0

var bands := []
var bands_coeff := []

func _ready() -> void:
	super._ready()
	
	if eff_ref:
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)
	
	freq_scale = FreqScale.new(self)
	db_scale = DbScale.new(self)
	
	if eff_ref:
		get_bands()
		recalculate_band_coefficients()

#func _process(delta: float) -> void:
	#if eff_ref:
		#queue_redraw()

func _draw() -> void:
	draw_layout()
	if eff_ref:
		draw_graph()

func draw_graph() -> void:
	var rect := get_rect()
	var useful_width := rect.size.x - CONTENT_PADDING * 2.0
	var useful_height := rect.size.y - CONTENT_PADDING * 2.0 - y_offset
	var eff_eq := eff_ref as AudioEffectEQ
	var points := PackedVector2Array()
	
	for i in GRAPH_RESOLUTION:
		var t := float(i) / float(GRAPH_RESOLUTION - 1)
		var freq := FreqScale.MIN_FREQ * pow(FreqScale.MAX_FREQ / FreqScale.MIN_FREQ, t)
		
		var total := 0.0
		var i_band := 0
		for p_band in bands:
			var mag := get_mag_at_freq(
				freq,
				bands_coeff[i_band]
			)
			var gain_db := eff_eq.get(p_band)
			total += mag * gain_db
			i_band += 1
		
		var db := total
		
		var x := t * useful_width
		var db_clamped := clampf(db, EQ_MIN_DB, EQ_MAX_DB)
		var y := remap(db_clamped, EQ_MIN_DB, EQ_MAX_DB, useful_height, 0.0)
		points.push_back(Vector2(x + CONTENT_PADDING, y + CONTENT_PADDING))

	draw_polyline(points, accent_color, 1.0, true)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)
	
	# Freq scale
	var useful_width := rect.size.x - CONTENT_PADDING * 2.0
	y_offset = freq_scale.draw(
		Vector2(CONTENT_PADDING, rect.size.y - CONTENT_PADDING),
		useful_width,
		get_theme_default_font(),
		ThemeUtils.modify_color(text_color, 0.5)
	)
	
	# Draw 0dB
	var line_y := remap(0.0, EQ_MIN_DB, EQ_MAX_DB, rect.size.y, 0.0)
	draw_line(
		Vector2(CONTENT_PADDING, line_y),
		Vector2(rect.size.x - CONTENT_PADDING, line_y),
		ThemeUtils.modify_color(text_color, 0.85),
		1.0
	)
	
	for p_band in bands:
		var freq := get_band_prop_freq(p_band)
		#var t := log(freq / FreqScale.MIN_FREQ) / log(FreqScale.MAX_FREQ / FreqScale.MIN_FREQ)
		var x := freq_scale.freq_to_x(freq, useful_width) #log(freq - FreqScale.MIN_FREQ) / log(FreqScale.MAX_FREQ - FreqScale.MIN_FREQ)
		
		draw_line(
			Vector2(x + CONTENT_PADDING, CONTENT_PADDING),
			Vector2(x + CONTENT_PADDING, rect.size.y - CONTENT_PADDING - y_offset),
			ThemeUtils.modify_color(text_color, 0.85),
			1.0
		)

func get_bands():
	var eff_eq := eff_ref as AudioEffectEQ
	for p in eff_eq.get_property_list():
		if (p.name as String).begins_with("band_db"):
			bands.push_back(p.name)

func get_band_prop_freq(p_band: String) -> float:
	return (p_band as String).substr("band_db/".length()).trim_suffix("_hz").to_float()

# everything below is compiled from:
# servers/audio/effects/eq_filter.cpp#0aa7242624fcd74eaf13db006274829c284fab3b
# servers/audio/audio_filter_sw.cpp#5dbf1809c6e3e905b94b8764e99491e608122261
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

func get_mag_at_freq(p_freq: float, coeffs: Dictionary) -> float:
	var c1 := coeffs["c1"] as float
	var c2 := coeffs["c2"] as float
	var c3 := coeffs["c3"] as float
	
	# response
	var freq := p_freq / AudioServer.get_mix_rate() * TAU

	var cx := c1 * (1.0 - cos(-2.0 * freq))
	var cy := c1 * (-sin(-2.0 * freq))

	var H := cx * cx + cy * cy
	cx = 1.0 - c3 * cos(-freq) + c2 * cos(-2.0 * freq)
	cy = -c3 * sin(-freq) + c2 * sin(-2.0 * freq)

	H = H / (cx * cx + cy * cy)
	return (H)

const SQRT12 := 0.7071067811865475244008443621048490

func recalculate_band_coefficients() -> void:
	var mix_rate := AudioServer.get_mix_rate()
	var i := 0
	for p_band in bands:
		var octave_size := 0.0
		var frq := get_band_prop_freq(p_band)
		
		if i == 0:
			octave_size = band_log(get_band_prop_freq(bands[1])) - band_log(frq)
		elif i == bands.size() - 1:
			octave_size = band_log(frq) - band_log(get_band_prop_freq(bands[i - 1]))
		else:
			var next := band_log(get_band_prop_freq(bands[i + 1])) - band_log(frq)
			var prev := band_log(frq) - band_log(get_band_prop_freq(bands[i - 1]))
			octave_size = (next + prev) / 2.0
		
		var frq_l := roundf(frq / pow(2.0, octave_size / 2.0))

		var side_gain2 := SQRT12 * SQRT12
		var th := TAU * frq / mix_rate;
		var th_l := TAU * frq_l / mix_rate

		var c2a := side_gain2 * (cos(th) * cos(th)) - 2.0 * side_gain2 * cos(th_l) * cos(th) + side_gain2 - (sin(th_l) * sin(th_l))

		var c2b := 2.0 * side_gain2 * (cos(th_l) * cos(th_l)) + side_gain2 * (cos(th) * cos(th)) - 2.0 * side_gain2 * cos(th_l) * cos(th) - side_gain2 + (sin(th_l) * sin(th_l))

		var c2c := 0.25 * side_gain2 * (cos(th) * cos(th)) - 0.5 * side_gain2 * cos(th_l) * cos(th) + 0.25 * side_gain2 - 0.25 * (sin(th_l) * sin(th_l))
		
		var r_out := {
			"r1" = 0.0,
			"r2" = 0.0
		}
		var roots := solve_quadratic(c2a, c2b, c2c, r_out)
		
		if roots == 0:
			printerr("roots == 0")
		
		var c1 := 2.0 * ((0.5 - (r_out["r1"] as float)) / 2.0)
		var c2 := 2.0 * (r_out["r1"] as float);
		var c3 := 2.0 * (0.5 + (r_out["r1"] as float)) * cos(th)
		
		bands_coeff.push_back({
			"c1" = c1,
			"c2" = c2,
			"c3" = c3
		})
		
		i += 1

func band_log(value: float) -> float:
	return log(value) / log(2.0)

func solve_quadratic(a: float, b: float, c: float, out: Dictionary) -> int:
	var base := 2.0 * a
	if base == 0.0:
		return 0

	var squared := b * b - 4 * a * c
	if squared < 0.0:
		return 0

	squared = sqrt(squared)

	var r1 := (-b + squared) / base
	var r2 := (-b - squared) / base
	
	out["r1"] = r1
	out["r2"] = r2

	if r1 == r2:
		return 1
	else:
		return 2
