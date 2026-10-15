class_name ItemChoice
extends CanvasLayer

# หน้าให้เลือกรางวัลท้ายวัน (เกรด A ขึ้นไป): การ์ด item 3 ใบ เลือกได้ 1 / พิกัด 426x240
# main.gd: var id := await choice.choose(ids, boss_line) → "" ถ้าถูกตัด (abort)
# offer() = การ์ดทั่วไปจำนวนกี่ใบก็ได้ (ใช้กับข้อเสนอสินบน) / make_card() ใช้ร่วมกับร้านของ boss (boss_shop.gd)

signal picked(id: String)

const CARD_W := 118.0
const CARD_H := 98.0
const CARD_H_SMALL := 76.0   # การ์ดไอคอนขนาดจริง (ร้านของ boss)
const GAP := 8.0

var _title: Label
var _boss: Label
var _hint: Label
var _desc: Label
var _row: HBoxContainer
var _open := false
var _ids: Array[String] = []   # id ของการ์ดตามลำดับ (กดเลข 1-9 เลือกได้)


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
	_row.anchor_left = 0.5
	_row.anchor_right = 0.5
	_row.offset_top = 76.0
	_row.offset_bottom = 76.0 + CARD_H
	add_child(_row)

	_desc = _label(8, 186.0, 10.0)   # คำอธิบาย item ใบที่ชี้เมาส์อยู่ (การ์ดไอคอนไม่มีข้อความอธิบายในใบ)
	_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_hint = _label(8, 208.0, 10.0)
	_hint.add_theme_color_override("font_color", Color(0.6, 0.5, 0.15))
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
	var cards: Array = []
	for id in ids:
		var data: Dictionary = ItemData.ITEMS[id]
		cards.append({"id": id, "name": data.name, "desc": data.desc, "color": data.color, "icon": ItemData.icon(id), "icon_scale": 2})
	return await offer("CHOOSE A REWARD", boss_line, cards, Settings.wording("click a card to take it"))


# การ์ดทั่วไป: cards = [{"id", "name", "desc", "color", "footer"(ไม่ใส่ก็ได้)}] / คืน id ของใบที่เลือก ("" = ถูกตัดด้วย abort)
func offer(title: String, boss_line: String, cards: Array, hint: String) -> String:
	for c in _row.get_children():
		c.queue_free()
	_ids.clear()
	for c in cards:
		_ids.append(c.id)
		var b := make_card(c.name, c.desc, c.color, c.get("footer", ""), c.get("icon"), c.get("icon_scale", 1))
		var id: String = c.id
		bind_hover(b, _desc)
		bind_confirm(b, _desc, func() -> void: picked.emit(id))
		_row.add_child(b)
	var width := cards.size() * CARD_W + (cards.size() - 1) * GAP
	_row.offset_left = -width * 0.5
	_row.offset_right = width * 0.5
	_title.text = title
	_boss.text = '"%s"' % boss_line
	_hint.text = "tap a card to read it, tap again to pick" if Settings.touch else "%s  (1-%d)" % [hint, cards.size()]
	_desc.text = ""
	_open = true
	visible = true
	var id: String = await picked
	_open = false
	visible = false
	return id


# การ์ดหนึ่งใบ: ชื่อ (สีของ accent) + คำอธิบาย + footer (เช่นราคา ไม่ใส่ = ไม่โชว์) / footer ที่โชว์ดึงด้วย card.get_meta("footer")
# มี icon = โชว์ไอคอนแทนคำอธิบาย (ขยาย icon_scale เท่า แบบ nearest) คำอธิบายเก็บใน meta "desc" ให้ bind_hover() ไปโชว์ที่บรรทัดล่างจอ
static func make_card(card_name: String, card_desc: String, accent: Color, footer := "", icon: Texture2D = null, icon_scale := 1) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(CARD_W, CARD_H if icon == null or icon_scale > 1 else CARD_H_SMALL)
	b.set_meta("desc", card_desc)
	b.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.07, 0.07, 0.1)
	normal.border_color = accent.darkened(0.4)
	normal.set_border_width_all(2)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.12, 0.12, 0.16)
	hover.border_color = accent
	var off: StyleBoxFlat = normal.duplicate()   # ซื้อแล้ว / กดไม่ได้: ทึบและจาง
	off.bg_color = Color(0.04, 0.04, 0.05)
	off.border_color = Color(0.2, 0.2, 0.22)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", off)

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
	name_label.text = card_name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", accent)
	box.add_child(name_label)
	if icon != null:
		box.add_theme_constant_override("separation", 4)
		var pic := TextureRect.new()
		pic.texture = icon
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(32.0, 32.0) * icon_scale
		pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(pic)
	else:
		var desc := Label.new()
		desc.text = card_desc
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		desc.add_theme_font_size_override("font_size", 8)
		desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		box.add_child(desc)
	var foot := Label.new()
	foot.text = footer
	foot.visible = footer != ""
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 8)
	foot.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	box.add_child(foot)
	b.set_meta("footer", foot)
	return b


# ชี้เมาส์ที่การ์ด = โชว์คำอธิบาย (meta "desc") บน label / เอาเมาส์ออก = ล้าง
static func bind_hover(card: Button, label: Label) -> void:
	card.mouse_entered.connect(func() -> void: label.text = card.get_meta("desc"))
	card.mouse_exited.connect(func() -> void: label.text = "")


# กดการ์ด: บนคอมทำทันที / โหมดสัมผัส (ไม่มี hover) แตะครั้งแรก = โชว์คำอธิบาย, แตะใบเดิมซ้ำ = ยืนยัน (กันนิ้วพลาดเสียเงิน)
static func bind_confirm(card: Button, label: Label, action: Callable) -> void:
	card.pressed.connect(func() -> void:
		if Settings.touch and not card.get_meta("armed", false):
			for c in card.get_parent().get_children():
				c.set_meta("armed", false)
			card.set_meta("armed", true)
			label.text = card.get_meta("desc")
			return
		action.call())


func _unhandled_input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey and event.pressed and not event.echo):
		return
	var i: int = event.physical_keycode - KEY_1
	if i >= 0 and i < _ids.size():
		get_viewport().set_input_as_handled()
		picked.emit(_ids[i])


# ตัดทิ้งทันที (คำสั่ง /day) ให้ coroutine ที่ await choose() ตื่นแล้วเลิกเอง (main เช็ค _flow_id)
func abort() -> void:
	if _open:
		picked.emit("")
	visible = false
