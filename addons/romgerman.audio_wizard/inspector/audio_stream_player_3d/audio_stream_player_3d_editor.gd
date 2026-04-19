@tool
extends Control

const ThemeUtils := preload("res://addons/romgerman.audio_wizard/theme_utils.gd")

const MIN_DB := -80.0
const MAX_DB := 0.0

const CONTENT_PADDING := 12.0
const LINE_THICKNESS := 0.5
const LINE_RESOLUTION := 96
const FONT_SIZE := 10

var base_color: Color
var accent_color: Color
var text_color: Color
var is_light_theme: bool

var target: AudioStreamPlayer3D

func _ready() -> void:
	if target:
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)
	
	_get_theme_colors()

#func _process(delta: float) -> void:
	#queue_redraw()

func _draw() -> void:
	if not target:
		return
	
	# Usually the "stream" property
	var prev_control := get_parent_control().get_child(get_index() - 1) as Control
	var rect := get_rect()
	# Move to fix the separation
	var margin_y := position.y - (prev_control.position.y + prev_control.size.y)
	# Move up by the height of the editor property control
	# (Godot reserves space for a property of am I high?)
	rect.position.y -= prev_control.get_rect().size.y + margin_y
	
	# Background
	draw_rect(rect, base_color, true)
	
	var content_rect := rect.grow(-CONTENT_PADDING)
	var max_distance := maxf(target.max_distance, 200.0)
	var text_y := rect.size.y - CONTENT_PADDING
	
	for i in range(0.0, max_distance, snappedf(max_distance / 10.0, 10.0)):
		var t := float(i) / max_distance
		draw_string(
			get_theme_default_font(),
			Vector2(t * content_rect.size.x + CONTENT_PADDING, text_y),
			"%0.0f" % i,
			HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			FONT_SIZE,
			ThemeUtils.modify_color(text_color, 0.5)
		)
	
	var points := PackedVector2Array()
	for i in LINE_RESOLUTION:
		var t := float(i) / float(LINE_RESOLUTION - 1)
		var out_db := get_attenuation_db(t * max_distance)
		var mult := db_to_linear(out_db)
		var db_att := (1.0 - minf(1.0, mult)) * target.attenuation_filter_db

		var in_pos := t * content_rect.size.x
		var out_pos := clampf(1.0 - db_to_linear(db_att), 0.0, 1.0) * (content_rect.size.y - FONT_SIZE * 1.5)
		points.push_back(Vector2(in_pos + content_rect.position.x, out_pos + content_rect.position.y))
	
	draw_polyline(
		points,
		accent_color,
		LINE_THICKNESS,
		true
	)

func _get_theme_colors() -> void:
	base_color = ThemeUtils.get_base_color(self)
	accent_color = ThemeUtils.get_accent_color(self)
	is_light_theme = ThemeUtils.is_light_color(base_color)
	text_color = Color.BLACK if is_light_theme else Color.WHITE

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_get_theme_colors()
		queue_redraw()

# scene/3d/audio_stream_player_3d.cpp#2e73be99d8d86d9dad7bcb99518a4d3cbb5c373c
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
func get_attenuation_db(p_distance: float) -> float:
	var attenuation_model := target.attenuation_model
	var unit_size := target.unit_size
	
	if attenuation_model == AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE:
		return linear_to_db(1.0 / ((p_distance / unit_size) + 0.00001))
	elif attenuation_model == AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE:
		var d = (p_distance / unit_size)
		d *= d
		return linear_to_db(1.0 / (d + 0.00001))
	elif attenuation_model == AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC:
		return -20 * log(p_distance / unit_size + 0.00001)
	else:
		return 1.0
