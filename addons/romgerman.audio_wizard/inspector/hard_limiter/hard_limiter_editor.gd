@tool
extends "../effect_editor_base.gd"

const DbScale := preload("res://addons/romgerman.audio_wizard/inspector/db_scale.gd")

const CONTENT_PADDING := 12.0
const LINE_THICKNESS := 1.0

var layout_offset_x := 0.0

var db_scale: DbScale

func _ready() -> void:
	if eff_handle.has_effect():
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)
	
	db_scale = DbScale.new(self)

#func _process(delta: float) -> void:
	#if eff_handle.has_effect():
		#queue_redraw()

#func _process(delta: float) -> void:
	#if eff_handle.has_effect():
		#queue_redraw()

func _draw() -> void:
	draw_layout()
	if eff_handle.has_effect():
		draw_representation()

func draw_representation() -> void:
	var rect := get_rect().grow(-CONTENT_PADDING)
	var points := PackedVector2Array()
	var eff_limiter := eff_handle.get_effect() as AudioEffectHardLimiter
	var in_db := DbScale.MIN_DB
	
	while in_db <= DbScale.MAX_DB:
		var out_lin := get_linear_at(
			in_db,
			eff_limiter.ceiling_db,
			eff_limiter.release,
			eff_limiter.pre_gain_db
		)
		var out_db := linear_to_db(out_lin)
		
		if out_db < DbScale.MIN_DB or out_db > DbScale.MAX_DB:
			in_db += 0.5
			continue
		
		var in_pos := (in_db - DbScale.MIN_DB) / (DbScale.MAX_DB - DbScale.MIN_DB) * (rect.size.x - layout_offset_x)
		var out_pos := rect.size.y - (out_db - DbScale.MIN_DB) / (DbScale.MAX_DB - DbScale.MIN_DB) * rect.size.y
		points.push_back(Vector2(in_pos + rect.position.x, out_pos + rect.position.y))
		
		in_db += 0.5
	
	if points.size() >= 2:
		draw_polyline(points, accent_color, LINE_THICKNESS, true)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)
	
	var useful_rect := rect.grow(-CONTENT_PADDING)
	
	layout_offset_x = db_scale.draw(
		Vector2(useful_rect.position.x + useful_rect.size.x, useful_rect.position.y),
		useful_rect.size.y,
		get_theme_default_font(),
		ThemeUtils.modify_color(text_color, 0.5)
	)
	
	# Draw 0dB
	var line_y := useful_rect.position.y + db_scale.db_to_y(0.0, useful_rect.size.y)
	draw_line(
		Vector2(useful_rect.position.x, line_y),
		Vector2(useful_rect.position.x + rect.size.x - layout_offset_x - CONTENT_PADDING * 2.0, line_y),
		ThemeUtils.modify_color(text_color, 0.85),
		1.0
	)

# servers/audio/effects/audio_effect_hard_limiter.cpp#61a5d523887510a38d99efa782066d75e2e52faf
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
func get_linear_at(in_db: float, ceiling_db: float, release_sec: float, pre_gain_db: float) -> float:
	var sample_rate := AudioServer.get_mix_rate()
	var ceiling := db_to_linear(ceiling_db)
	var release := release_sec
	var attack := 0.002
	var pre_gain := db_to_linear(pre_gain_db)
	
	var in_sample := db_to_linear(in_db)
	
	in_sample *= pre_gain
	
	var attack_factor := 0.0
	var release_factor := 0.0
	var gain_target := 1.0
	var gain := 1.0
	
	release_factor = maxf(0.0, release_factor - 1.0 / sample_rate)
	release_factor = minf(release_factor, release)
	
	if release_factor > 0.0:
		gain = lerp(gain_target, 1.0, 1.0 - release_factor / release)
	
	if in_sample * gain > ceiling:
		gain_target = ceiling / in_sample
		release_factor = release
		attack_factor = attack
	
	attack_factor = maxf(0.0, attack_factor - 1.0 / sample_rate)
	if attack_factor > 0.0:
		gain = lerpf(gain_target, gain, 1.0 - attack_factor / attack)
	
	return in_sample * gain
