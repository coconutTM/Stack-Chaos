class_name TitleMenu
extends CanvasLayer

# เมนูหน้าแรก (พิกัด 426x240): ชื่อเกม + ปุ่ม PLAY / OVERTIME / HOW TO PLAY / CREDITS + เกรดดีสุด
# ฉาก 3D ด้านหลัง (กองขยะตัวอย่าง + กล้องหมุนช้าๆ) main.gd เป็นคนจัด / เมนูนี้แค่ส่งสัญญาณกลับ

signal play_pressed
signal overtime_pressed
signal settings_pressed
signal clicked            # กดปุ่มใดก็ตาม (ไว้ผูกเสียงคลิก)

# บรรทัดในหน้า CREDITS (ภาษาอังกฤษ เพราะฟอนต์ไม่มีอักษรไทย) — เพิ่มชื่อทีมที่นี่ได้
const CREDITS_LINES := [
	"A student project",
	"683380290-0 Thakoon Moonwicha",
	"683380294-2 Thanakon Meerit",
	"683380299-2 Thanyaboon Sinthao",
	"683380304-5 Poramet Jantamin",
	"CP352203 Computer Game Development",
	"",
	"3D models: Kenney (CC0)",
	"Cars: Quaternius (CC0)",
	"Font: Press Start 2P (OFL)",
	"Sound: synthesized in code",
	"Made with Godot 4.7",
]
const HOW_TO_LINES := [
	"Mouse: move the piece",
	"Left click: drop it",
	"Right click: spin it 45 degrees",
	"Shift + right click: flip it",
	"Mouse wheel: zoom",
	"Right drag: look around the pile",
	"P / Esc: pause",
	"",
	"Reach the quota height before",
	"you run out of pieces.",
	"Lose 3 pieces and you're fired.",
]

var _root: Control
var _subtitle: Label
var _overtime_button: Button
var _footer: Label
var _panel: Control
var _panel_title: Label
var _panel_body: Label


func _ready() -> void:
	layer = 6   # เหนือ HUD/แถบความสูง ใต้ปุ่มเสียง (12) และจอมืดตอนเปลี่ยนฉาก (ScreenFx 20)
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var title := _label("STACK CHAOS!", 24, 12.0, 28.0)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_subtitle = _label("(night shift)", 8, 44.0, 10.0)
	_subtitle.add_theme_color_override("font_color", Color(0.6, 0.65, 0.9))

	# ปุ่มเรียงเป็นแถวซ้าย ปล่อยกลางจอไว้ให้เห็นกองขยะ
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	box.offset_left = 28.0
	box.offset_top = 98.0
	_root.add_child(box)
	box.add_child(_button("PLAY", func() -> void: play_pressed.emit()))
	_overtime_button = _button("OVERTIME", func() -> void: overtime_pressed.emit())
	box.add_child(_overtime_button)
	box.add_child(_button("HOW TO PLAY", _open_panel.bind("HOW TO PLAY", HOW_TO_LINES)))
	box.add_child(_button("SETTINGS", func() -> void: settings_pressed.emit()))
	box.add_child(_button("CREDITS", _open_panel.bind("CREDITS", CREDITS_LINES)))

	_footer = _label("", 8, 222.0, 10.0)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_footer.offset_left = 28.0

	_build_panel()
	visible = false


func _label(text: String, size: int, y: float, h: float) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.anchor_right = 1.0
	l.offset_top = y
	l.offset_bottom = y + h
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6 if size >= 16 else 4)
	_root.add_child(l)
	return l


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(136, 18)
	b.add_theme_font_size_override("font_size", 8)
	b.pressed.connect(func() -> void:
		clicked.emit()
		action.call())
	return b


# แผงข้อความเต็มจอ (HOW TO PLAY / CREDITS) มีปุ่ม BACK / กินคลิกเองไม่ให้ทะลุไปปุ่มด้านหลัง
func _build_panel() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 0.95)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.visible = false
	_root.add_child(bg)
	_panel = bg

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	bg.add_child(box)

	_panel_title = Label.new()
	_panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_title.add_theme_font_size_override("font_size", 16)
	_panel_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	box.add_child(_panel_title)

	_panel_body = Label.new()
	_panel_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_body.add_theme_font_size_override("font_size", 8)
	_panel_body.add_theme_constant_override("line_spacing", 4)
	box.add_child(_panel_body)

	var back := _button("BACK", func() -> void: _panel.visible = false)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)


func _open_panel(title: String, lines: Array) -> void:
	_panel_title.text = title
	_panel_body.text = "\n".join(lines)
	_panel.visible = true


# แสดงหน้าแรก (อัปเดตข้อความตามความคืบหน้าที่บันทึกไว้)
func open() -> void:
	_panel.visible = false
	_subtitle.visible = Settings.night_shift
	_overtime_button.disabled = not Settings.night_shift
	_overtime_button.text = "OVERTIME" if Settings.night_shift else "OVERTIME [LOCKED]"
	_overtime_button.tooltip_text = "" if Settings.night_shift else "Finish all 5 days to unlock"
	_footer.text = _footer_text()
	visible = true


func close() -> void:
	visible = false


# เกรดดีสุดของแต่ละวัน + จำนวนกะ OVERTIME ที่ไกลสุด (ยังไม่เคยมีอะไร = ไม่โชว์)
func _footer_text() -> String:
	var parts: Array[String] = []
	var any := false
	for g in Settings.best_grades:
		parts.append(String(GameData.GRADES[g].id) if g >= 0 else "-")
		any = any or g >= 0
	var text := ""
	if any:
		text = "BEST GRADES  %s" % " ".join(parts)
	if Settings.best_overtime > 0:
		text += ("   " if text != "" else "") + "OVERTIME BEST  %d" % Settings.best_overtime
	return text
