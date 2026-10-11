class_name ReviewScreen
extends CanvasLayer

# หน้าสรุปผลงานท้ายวัน: ตราเกรด + ชิ้นที่เหลือ/เสีย + ค่าแรง + เงินรวม + คำพูดของ boss
# main.gd: await review.show_review(data) / data = {title, grade, color, new_best, rows: [[ชื่อ, ค่า]...], boss, hint}
# แถวโผล่ทีละแถว คลิกระหว่างนั้น = ข้ามไปแสดงครบ / คลิกอีกครั้ง = ปิด

signal tick     # แถวใหม่โผล่ (ไว้ผูกเสียง)
signal stamp    # ตราเกรดโผล่
signal closed

const ROW_DELAY := 0.4
const CLOSE_DELAY := 0.25    # หน่วงหลังแสดงครบก่อนรับคลิกปิด (กันเผลอคลิกข้าม)
const ROW_W := 22            # ความกว้างตัวอักษรของแต่ละแถว (ฟอนต์ pixel เป็น monospace จึงจัดคอลัมน์ด้วยช่องว่างได้)

var _bg: ColorRect
var _title: Label
var _grade: Label
var _best: Label
var _rows: Array[Label] = []
var _boss: Label
var _hint: Label
var _tween: Tween
var _done_at := 0
var _complete := false


func _ready() -> void:
	layer = 12   # เหนือ DialogueBox (10) ใต้ PauseMenu (15) และ ScreenFx (20)
	_bg = ColorRect.new()
	_bg.color = Color(0.02, 0.02, 0.04, 0.97)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_title = _label(16, 20.0, 18.0)
	_grade = _label(48, 44.0, 56.0)
	_grade.pivot_offset = Vector2(213.0, 28.0)
	_best = _label(8, 102.0, 10.0)
	for i in 4:
		_rows.append(_label(8, 120.0 + i * 13.0, 10.0))
	_boss = _label(8, 184.0, 20.0)
	_boss.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boss.offset_left = 40.0
	_boss.offset_right = -40.0
	_hint = _label(8, 222.0, 10.0)
	visible = false


# สร้าง Label กลางจอแนวนอน (พิกัด 426x240) ที่ y กับความสูงที่กำหนด
func _label(size: int, y: float, h: float) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.offset_top = y
	l.offset_bottom = y + h
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	add_child(l)
	return l


# แสดงหน้าสรุปแล้วรอจนผู้เล่นคลิกปิด (หรือ abort())
func show_review(data: Dictionary) -> void:
	_title.text = data.get("title", "")
	_grade.text = data.get("grade", "")
	_grade.add_theme_color_override("font_color", data.get("color", Color.WHITE))
	_best.text = "NEW BEST!" if data.get("new_best", false) else ""
	_best.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	var rows: Array = data.get("rows", [])
	for i in _rows.size():
		_rows[i].text = _format_row(rows[i]) if i < rows.size() else ""
	_boss.text = '"%s"' % data.get("boss", "") if data.get("boss", "") != "" else ""
	_boss.add_theme_color_override("font_color", Color(0.92, 0.9, 0.78))
	_hint.text = data.get("hint", "click to continue")
	_hint.add_theme_color_override("font_color", Color(0.6, 0.5, 0.15))

	_complete = false
	for c in [_title, _grade, _best, _boss, _hint]:
		c.modulate.a = 0.0
	for r in _rows:
		r.modulate.a = 0.0
	visible = true
	_play_reveal(_rows.size())
	await closed


func _format_row(row: Array) -> String:
	var name := String(row[0])
	var value := String(row[1])
	return name + " ".repeat(maxi(1, ROW_W - name.length() - value.length())) + value


func _play_reveal(row_count: int) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_title, "modulate:a", 1.0, 0.25)
	_tween.tween_interval(0.2)
	_tween.tween_callback(_stamp_grade)
	_tween.tween_interval(0.6)
	for i in row_count:
		_tween.tween_callback(_show_row.bind(i))
		_tween.tween_interval(ROW_DELAY)
	_tween.tween_callback(_show_boss)
	_tween.tween_interval(0.3)
	_tween.tween_callback(_finish_reveal)


# ตราเกรดกระแทกลงมา (ใหญ่ → ขนาดจริง)
func _stamp_grade() -> void:
	_grade.modulate.a = 1.0
	_grade.scale = Vector2(2.6, 2.6)
	var tw := create_tween()
	tw.tween_property(_grade, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_best.modulate.a = 1.0
	stamp.emit()


func _show_row(i: int) -> void:
	_rows[i].modulate.a = 1.0
	tick.emit()


func _show_boss() -> void:
	_boss.modulate.a = 1.0


func _finish_reveal() -> void:
	_complete = true
	_done_at = Time.get_ticks_msec()
	_hint.modulate.a = 1.0


# ข้ามอนิเมชันไปแสดงครบทันที
func _reveal_all() -> void:
	if _tween:
		_tween.kill()
	_title.modulate.a = 1.0
	_grade.modulate.a = 1.0
	_grade.scale = Vector2.ONE
	_best.modulate.a = 1.0
	for r in _rows:
		r.modulate.a = 1.0
	_boss.modulate.a = 1.0
	_finish_reveal()


# ตัดทิ้งทันที (คำสั่ง /day) ให้ coroutine ที่ await show_review() ตื่นแล้วเลิกเอง (main เช็ค _flow_id)
func abort() -> void:
	if _tween:
		_tween.kill()
	visible = false
	closed.emit()


func _process(_delta: float) -> void:
	if visible and _complete:
		_hint.modulate.a = 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.004))


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if not _complete:
			_reveal_all()
		elif (Time.get_ticks_msec() - _done_at) / 1000.0 >= CLOSE_DELAY:
			visible = false
			closed.emit()
