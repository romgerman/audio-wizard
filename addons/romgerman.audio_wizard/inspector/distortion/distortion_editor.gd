@tool
extends "../effect_editor_base.gd"

const GRAPH_STEP := 0.02
const MIN_GRAPH := -1.0
const MAX_GRAPH := 1.0
const MIN_HF_HZ := 1.0
const MAX_HF_HZ := 20500.0

const CONTENT_PADDING := 12.0
const LINE_THICKNESS := 2.0

func _ready() -> void:
	super._ready()
	
	if eff_ref:
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)

#func _process(delta: float) -> void:
	#if eff_ref:
		#queue_redraw()

func _draw() -> void:
	draw_layout()
	if eff_ref:
		draw_representation()

func draw_representation() -> void:
	var rect := get_rect().grow(-CONTENT_PADDING)
	var eff_dist := eff_ref as AudioEffectDistortion
	
	var points := PackedVector2Array()
	var input := MIN_GRAPH
	
	while input <= (MAX_GRAPH + GRAPH_STEP):
		var out := get_abs_at_db(
			input,
			eff_dist.drive,
			eff_dist.pre_gain,
			eff_dist.post_gain,
			eff_dist.mode
		)
		
		var in_pos := (input + 1.0) / 2.0 * rect.size.x
		var out_pos := clampf(rect.size.y - (out + 1.0) / 2.0 * rect.size.y, 0.0, rect.size.y)
		points.push_back(Vector2(in_pos + rect.position.x, out_pos + rect.position.y))
		
		input += GRAPH_STEP
	
	var brightness := (eff_dist.keep_hf_hz - MIN_HF_HZ) / (MAX_HF_HZ - MIN_HF_HZ)
	
	draw_polyline(
		points,
		accent_color,
		LINE_THICKNESS * clampf(brightness, 0.1, 1.0),
		true
	)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)
	
	var center := rect.get_center()
	var content_rect := rect.grow(-CONTENT_PADDING)
	
	# Vertical line
	draw_line(
		Vector2(center.x, CONTENT_PADDING),
		Vector2(center.x, content_rect.size.y + CONTENT_PADDING),
		ThemeUtils.modify_color(base_color, 0.1),
		1.0
	)
	# Horizontal line
	draw_line(
		Vector2(CONTENT_PADDING, center.y),
		Vector2(content_rect.size.x + CONTENT_PADDING, center.y),
		ThemeUtils.modify_color(base_color, 0.1),
		1.0
	)

# servers/audio/effects/audio_effect_distortion.cpp#63fa5486a4038498dec5d58f1dec41fd282c4645
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
func get_abs_at_db(input: float, drive: float, pre_gain: float, post_gain: float, mode: AudioEffectDistortion.Mode) -> float:
	var drive_f := drive
	var pregain_f := db_to_linear(pre_gain)
	var postgain_f := db_to_linear(post_gain)

	var atan_mult := pow(10, drive_f * drive_f * 3.0) - 1.0 + 0.001
	var atan_div := 1.0 / (atan(atan_mult) * (1.0 + drive_f * 8))

	var lofi_mult := pow(2.0, 2.0 + (1.0 - drive_f) * 14)
	
	# loop
	
	var out := input
	var a := out
	a *= pregain_f;
	
	if mode == AudioEffectDistortion.Mode.MODE_CLIP:
		var a_sign := -1.0 if a < 0 else 1.0
		a = pow(abs(a), 1.0001 - drive_f) * a_sign;
		if a > 1.0:
			a = 1.0
		elif a < (-1.0):
			a = -1.0
	elif mode == AudioEffectDistortion.Mode.MODE_ATAN:
		a = atan(a * atan_mult) * atan_div
	elif mode == AudioEffectDistortion.Mode.MODE_LOFI:
		a = floor(a * lofi_mult + 0.5) / lofi_mult
	elif mode == AudioEffectDistortion.Mode.MODE_OVERDRIVE:
		var x := a * 0.686306
		var z := 1 + exp(sqrt(abs(x)) * -0.75)
		a = (exp(x) - exp(-x * z)) / (exp(x) + exp(-x))
	elif mode == AudioEffectDistortion.Mode.MODE_WAVESHAPE:
		var x := a
		var k := 2 * drive_f / (1.00001 - drive_f)

		a = (1.0 + k) * x / (1.0 + k * abs(x))
	
	return a * postgain_f
