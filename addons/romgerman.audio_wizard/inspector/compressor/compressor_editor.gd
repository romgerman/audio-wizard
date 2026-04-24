@tool
extends "../effect_editor_base.gd"

const DbScale := preload("res://addons/romgerman.audio_wizard/inspector/db_scale.gd")

const MIN_THRESHOLD := -80.0
const MAX_THRESHOLD := 0.0

const LINE_THICKNESS := 1.0

var db_scale: DbScale
var layout_offset_x := 0.0

func _ready() -> void:
	if eff_handle.has_effect():
		EditorInterface.get_inspector().property_edited.connect(func (_prop: String):
			queue_redraw()
		)
	
	db_scale = DbScale.new(self)

func _draw() -> void:
	draw_layout()
	if eff_handle.has_effect():
		draw_representation()

func draw_representation() -> void:
	var rect := get_rect().grow(-CONTENT_PADDING)
	
	# Threshold jar
	draw_rect(
		Rect2(Vector2(CONTENT_PADDING, CONTENT_PADDING), Vector2(24.0, rect.size.y)),
		ThemeUtils.modify_color(base_color, 0.5),
		false,
		LINE_THICKNESS
	)
	
	var eff_compressor := eff_handle.get_effect() as AudioEffectCompressor
	var threshold_height := remap(eff_compressor.threshold, DbScale.MIN_DB, DbScale.MAX_DB, rect.size.y, 0.0)
	draw_rect(
		Rect2(
			Vector2(CONTENT_PADDING, CONTENT_PADDING + rect.size.y),
			Vector2(24.0, threshold_height - rect.size.y)
		),
		accent_color,
		true
	)
	
	# Db line
	draw_line(
		Vector2(CONTENT_PADDING, threshold_height + CONTENT_PADDING),
		Vector2(CONTENT_PADDING + 24.0 + 12.0, threshold_height + CONTENT_PADDING),
		ThemeUtils.modify_color(base_color, 0.5),
		LINE_THICKNESS,
	)
	
	draw_string(
		get_theme_default_font(),
		Vector2(
			CONTENT_PADDING + 24.0 + 12.0 + 2.0,
			threshold_height + CONTENT_PADDING + ThemeUtils.FONT_SIZE * 0.5 - 1.0
		),
		"%0.1f dB" % eff_compressor.threshold,
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ThemeUtils.FONT_SIZE,
		text_color.lightened(0.5)
	)
	
	var uncomp_points := PackedVector2Array()
	var comp_points := PackedVector2Array()
	var in_db := MIN_THRESHOLD
	var graph_rect := Rect2(
		Vector2(CONTENT_PADDING * 2.0 + 24.0 + 2.0, rect.position.y),
		Vector2(rect.size.x - 24.0 - 2.0 - layout_offset_x, rect.size.y)
	)
	
	while in_db <= MAX_THRESHOLD:
		var out_db := get_compression_at_db(in_db, eff_compressor.threshold, eff_compressor.ratio)
		
		var in_pos := (in_db - DbScale.MIN_DB) / (DbScale.MAX_DB - DbScale.MIN_DB) * graph_rect.size.x
		var out_pos := graph_rect.size.y - (out_db - DbScale.MIN_DB) / (DbScale.MAX_DB - DbScale.MIN_DB) * graph_rect.size.y
		comp_points.push_back(Vector2(in_pos + graph_rect.position.x, out_pos + graph_rect.position.y))
		var uncomp_out_pos := graph_rect.size.y - (in_db - DbScale.MIN_DB) / (DbScale.MAX_DB - DbScale.MIN_DB) * graph_rect.size.y
		uncomp_points.push_back(Vector2(in_pos + graph_rect.position.x, uncomp_out_pos + graph_rect.position.y))
		
		in_db += 0.5
	
	draw_polyline(
		uncomp_points,
		ThemeUtils.modify_color(base_color, 0.2),
		LINE_THICKNESS * 0.5,
		true
	)
	
	draw_polyline(
		comp_points,
		accent_color,
		LINE_THICKNESS,
		true
	)

func draw_layout() -> void:
	var rect := get_rect()
	
	# Background
	draw_rect(rect, base_color, true)
	
	var content_rect := rect.grow(-CONTENT_PADDING)
	
	layout_offset_x = db_scale.draw(
		Vector2(content_rect.size.x + CONTENT_PADDING, content_rect.position.y),
		content_rect.size.y,
		get_theme_default_font(),
		ThemeUtils.modify_color(text_color, 0.5)
	)

# servers/audio/effects/audio_effect_compressor.cpp#e1c1d7d1d7d9b3f3f64c9887107f55a22f5d0a31
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
func get_compression_at_db(in_db: float, threshold_db: float, ratio: float) -> float:
	var out_db := in_db
		
	if out_db > threshold_db:
		var threshold := db_to_linear(threshold_db)
		var overdb := 2.08136898 * linear_to_db(db_to_linear(in_db) / threshold)
		if overdb < 0.0:
			overdb = 0.0
		var gr := -overdb * (ratio - 1.0) / ratio
		out_db = in_db + gr
		
	return clampf(out_db, MIN_THRESHOLD, MAX_THRESHOLD)
