class_name ItemChoice
extends CanvasLayer

# หน้าให้เลือกรางวัลท้ายวัน (เกรด A ขึ้นไป): การ์ด item 3 ใบ เลือกได้ 1 / พิกัด 426x240
# main.gd: var id := await choice.choose(ids, boss_line) → "" ถ้าถูกตัด (abort)

signal picked(id: String)

const CARD_W := 118.0
const CARD_H := 98.0
const GAP := 8.0

var _title: Label
var _boss: Label
var _row: HBoxContainer
var _open := false


func _ready() -> void:
	layer = 12   # เหนือ DialogueBox (10) ใต้ PauseMenu (15) และ ScreenFx (20)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 0.97)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_title = _label(16, 22.0, 18.0)
	_title.text = "CHOOSE A REWARD"
	_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_boss = _label(8, 46.0, 10.0)
	_boss.add_theme_color_override("font_color", Color(0.92, 0.9, 0.78))

	_row = HBoxContainer.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("separation", int(GAP))
	var width := 3.0 * CARD_W + 2.0 * GAP
	_row.anchor_left = 0.5
	_row.anchor_right = 0.5
	_row.offset_left = -width * 0.5
	_row.offset_right = width * 0.5
	_row.offset_top = 76.0
	_row.offset_bottom = 76.0 + CARD_H
	add_child(_row)

	var hint := _label(8, 200.0, 10.0)
	hint.text = "click a card to take it"
	hint.add_theme_color_override("font_color", Color(0.6, 0.5, 0.15))
	visible = false


func _label(size: int, y: float, h: float) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.anchor_right = 1.0
	l.offset_top = y
	l.offset_bottom = y + h
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	add_child(l)
	return l


# แสดงการ์ดของ item ที่ให้เลือก (ids = id ใน ItemData.ITEMS) แล้วรอจนผู้เล่นเลือก / คืน id ที่เลือก
func choose(ids: Array, boss_line: String) -> String:
	for c in _row.get_children():
		c.queue_free()
	for id in ids:
		_row.add_child(_card(id))
	_boss.text = '"%s"' % boss_line
	_open = true
	visible = true
	var id: String = await picked
	_open = false
	visible = false
	return id


func _card(id: String) -> Button:
	var data: Dictionary = ItemData.ITEMS[id]
	var accent: Color = data.color
	var b := Button.new()
	b.custom_minimum_size = Vector2(CARD_W, CARD_H)
	b.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.07, 0.07, 0.1)
	normal.border_color = accent.darkened(0.4)
	normal.set_border_width_all(2)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.12, 0.12, 0.16)
	hover.border_color = accent
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.pressed.connect(func() -> void: picked.emit(id))

	# ชื่อ (สีของ item) + คำอธิบาย แยก Label กันเพื่อให้มีช่องว่างระหว่างกัน
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 6.0
	box.offset_right = -6.0
	box.offset_top = 8.0
	box.offset_bottom = -6.0
	box.add_theme_constant_override("separation", 8)
	b.add_child(box)
	var name_label := Label.new()
	name_label.text = data.name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", accent)
	box.add_child(name_label)
	var desc := Label.new()
	desc.text = data.desc
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override("font_size", 8)
	desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	box.add_child(desc)
	return b


# ตัดทิ้งทันที (คำสั่ง /day) ให้ coroutine ที่ await choose() ตื่นแล้วเลิกเอง (main เช็ค _flow_id)
func abort() -> void:
	if _open:
		picked.emit("")
	visible = false
