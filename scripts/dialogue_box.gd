class_name DialogueBox
extends CanvasLayer

# กล่องข้อความของ boss: เงาร่างมืดๆ + ตาเรืองแสง พูดแบบพิมพ์ทีละตัวอักษร
# - say(lines)    โหมดบล็อก: คลิกซ้ายเพื่อข้ามการพิมพ์ / ไปบรรทัดถัดไป (ใช้ await ได้)
# - comment(text) โหมดคอมเมนต์: ไม่บล็อกเกม โผล่มาแล้วหุบเองใน COMMENT_HOLD วินาที

signal finished   # say() อ่านครบทุกบรรทัดแล้ว
signal blip       # ทุกครั้งที่พิมพ์ตัวอักษรเพิ่ม (Phase 6 เอาไปเล่นเสียงพึมพำ)

const CHARS_PER_SEC := 45.0
const COMMENT_HOLD := 2.5     # คอมเมนต์ค้างหลังพิมพ์ครบกี่วินาที
const PANEL_H := 76.0
const FONT_SIZE := 11
const EYE_COLOR := Color(1.0, 0.85, 0.2)

var _panel: Control
var _label: Label
var _hint: Label
var _eyes: Array[ColorRect] = []
var _glows: Array[ColorRect] = []

var _lines: Array = []
var _idx := 0
var _chars := 0.0
var _typing := false
var _blocking := false
var _comment_left := 0.0
var _blink_in := 3.0
var _blink_left := 0.0
var _clock := 0.0


func _ready() -> void:
	layer = 10
	_panel = Control.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_top = -PANEL_H
	_panel.offset_bottom = 0.0
	add_child(_panel)

	_rect(_panel, Rect2(0, 0, 0, 0), Color(0.02, 0.02, 0.04, 0.93)).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var border := _rect(_panel, Rect2(0, 0, 0, 1), Color(0.55, 0.45, 0.1))
	border.anchor_right = 1.0

	_build_portrait()

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.anchor_right = 1.0
	_label.anchor_bottom = 1.0
	_label.offset_left = 80.0
	_label.offset_top = 6.0
	_label.offset_right = -8.0
	_label.offset_bottom = -6.0
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.78))
	_panel.add_child(_label)

	_hint = Label.new()
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.text = "click >"
	_hint.anchor_left = 1.0
	_hint.anchor_right = 1.0
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = -48.0
	_hint.offset_top = -16.0
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_color_override("font_color", Color(0.6, 0.5, 0.15))
	_panel.add_child(_hint)

	_panel.hide()


# โหมดบล็อก: แสดงทีละบรรทัดจนครบ (เรียกด้วย await dialogue.say([...]))
func say(lines: Array) -> void:
	if lines.is_empty():
		return
	_blocking = true
	_comment_left = 0.0
	_lines = lines
	_idx = 0
	_show_text(_lines[0])
	await finished


# โหมดคอมเมนต์: ไม่บล็อก / ถ้ากำลังอยู่ในโหมดบล็อกจะไม่ทำอะไร
func comment(text: String) -> void:
	if _blocking:
		return
	_comment_left = COMMENT_HOLD
	_show_text(text)


func is_busy() -> bool:
	return _blocking


func _unhandled_input(event: InputEvent) -> void:
	if not _blocking:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()   # ไม่ให้ main.gd เห็นคลิกนี้ซ้ำ
		_advance()


func _process(delta: float) -> void:
	if not _panel.visible:
		return
	_clock += delta
	_animate_eyes(delta)

	if _typing:
		var before := int(_chars)
		_chars += CHARS_PER_SEC * delta
		var shown := mini(int(_chars), _label.text.length())
		_label.visible_characters = shown
		if shown > before:
			blip.emit()
		if shown >= _label.text.length():
			_typing = false
	elif not _blocking:
		_comment_left -= delta
		if _comment_left <= 0.0:
			_panel.hide()

	_hint.visible = _blocking and not _typing and fmod(_clock, 1.0) < 0.6


func _show_text(text: String) -> void:
	_label.text = text
	_label.visible_characters = 0
	_chars = 0.0
	_typing = true
	_panel.show()


func _advance() -> void:
	if _typing:
		# คลิกระหว่างพิมพ์ = โชว์บรรทัดนี้ทั้งหมดทันที
		_typing = false
		_label.visible_characters = -1
		return
	_idx += 1
	if _idx >= _lines.size():
		_blocking = false
		_panel.hide()
		finished.emit()
	else:
		_show_text(_lines[_idx])


# ตากะพริบเป็นครั้งคราว และเรืองแรงขึ้นตอนกำลังพูด
func _animate_eyes(delta: float) -> void:
	_blink_in -= delta
	if _blink_in <= 0.0:
		_blink_left = 0.12
		_blink_in = randf_range(2.0, 5.0)
	_blink_left = maxf(0.0, _blink_left - delta)

	var open := _blink_left <= 0.0
	var energy := 0.75 + 0.25 * sin(_clock * (14.0 if _typing else 3.0))
	for i in _eyes.size():
		_eyes[i].visible = open
		_glows[i].visible = open
		_eyes[i].color = EYE_COLOR * energy
		_eyes[i].color.a = 1.0
		_glows[i].color = Color(EYE_COLOR, 0.25 * energy)


# เงาร่างบอส: หัว + หมวก + ไหล่ สีดำสนิทบนฉากหลังเทาเข้ม มีตาเหลืองสองดวง
func _build_portrait() -> void:
	var p := Control.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.position = Vector2(6, 6)
	p.size = Vector2(68, 64)
	_panel.add_child(p)

	_rect(p, Rect2(0, 0, 68, 64), Color(0.11, 0.11, 0.14))        # ฉากหลัง
	var black := Color(0.0, 0.0, 0.0)
	_rect(p, Rect2(8, 40, 52, 24), black)                          # ไหล่
	_rect(p, Rect2(28, 34, 12, 8), black)                          # คอ
	_rect(p, Rect2(21, 12, 26, 26), black)                         # หัว
	_rect(p, Rect2(17, 8, 34, 8), black)                           # หมวก/ปีกหมวก

	for x in [27.0, 37.0]:
		_glows.append(_rect(p, Rect2(x - 2, 21, 9, 7), Color(EYE_COLOR, 0.25)))
		_eyes.append(_rect(p, Rect2(x, 23, 5, 3), EYE_COLOR))


func _rect(parent: Control, r: Rect2, color: Color) -> ColorRect:
	var c := ColorRect.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = r.position
	c.size = r.size
	c.color = color
	parent.add_child(c)
	return c
