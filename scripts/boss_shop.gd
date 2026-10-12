class_name BossShop
extends CanvasLayer

# ร้านของ boss: ท้ายวัน (หลังสรุปผลงาน/เลือกรางวัล) ใช้เงินซื้อ item / พิกัด 426x240
# main.gd: shop.buy = Callable → await shop.open(stock, cash, boss_line)
# main เป็นเจ้าของเงินและคลัง: ร้านแค่แสดงผล — กดการ์ด = เรียก buy.call(id) แล้วโชว์ตามผลที่ได้กลับมา
#   buy(id) -> {"ok": bool, "cash": เงินคงเหลือ, "line": บทพูด boss}

signal closed

var buy: Callable

var _cash: Label
var _boss: Label
var _row: HBoxContainer
var _open := false
var _cards := {}   # id → ปุ่มการ์ด


func _ready() -> void:
	layer = 12   # ระดับเดียวกับ ItemChoice (เหนือ DialogueBox ใต้ PauseMenu และ ScreenFx)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 0.97)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := _label(16, 14.0, 18.0)
	title.text = "BOSS'S STOCK"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_cash = _label(8, 38.0, 10.0)
	_cash.add_theme_color_override("font_color", Color(0.5, 0.85, 0.5))
	_boss = _label(8, 54.0, 10.0)
	_boss.add_theme_color_override("font_color", Color(0.92, 0.9, 0.78))

	_row = HBoxContainer.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("separation", int(ItemChoice.GAP))
	_row.anchor_left = 0.5
	_row.anchor_right = 0.5
	_row.offset_top = 76.0
	_row.offset_bottom = 76.0 + ItemChoice.CARD_H
	add_child(_row)

	var leave := Button.new()
	leave.text = "LEAVE"
	leave.focus_mode = Control.FOCUS_NONE
	leave.anchor_left = 0.5
	leave.anchor_right = 0.5
	leave.offset_left = -40.0
	leave.offset_right = 40.0
	leave.offset_top = 196.0
	leave.offset_bottom = 216.0
	leave.add_theme_font_size_override("font_size", 8)
	leave.pressed.connect(func() -> void: closed.emit())
	add_child(leave)
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


# เปิดร้าน (stock = id ใน ItemData.ITEMS) แล้วรอจนผู้เล่นกด LEAVE
func open(stock: Array, cash: int, boss_line: String) -> void:
	for c in _row.get_children():
		c.queue_free()
	_cards.clear()
	for id in stock:
		var data: Dictionary = ItemData.ITEMS[id]
		var card := ItemChoice.make_card(data.name, data.desc, data.color, "$%d" % data.price)
		var item_id: String = id
		card.pressed.connect(_on_card.bind(item_id))
		_row.add_child(card)
		_cards[item_id] = card
	var width := stock.size() * ItemChoice.CARD_W + (stock.size() - 1) * ItemChoice.GAP
	_row.offset_left = -width * 0.5
	_row.offset_right = width * 0.5
	_set_cash(cash)
	_say(boss_line)
	_open = true
	visible = true
	await closed
	_open = false
	visible = false


func _on_card(id: String) -> void:
	var result: Dictionary = buy.call(id)
	_set_cash(int(result.cash))
	_say(String(result.line))
	if result.ok:
		var card: Button = _cards[id]
		card.disabled = true
		(card.get_meta("footer") as Label).text = "SOLD"


func _set_cash(cash: int) -> void:
	_cash.text = "CASH: $%d" % cash


func _say(line: String) -> void:
	_boss.text = '"%s"' % line


# ตัดทิ้งทันที (คำสั่ง /day) ให้ coroutine ที่ await open() ตื่นแล้วเลิกเอง (main เช็ค _flow_id)
func abort() -> void:
	if _open:
		closed.emit()
	visible = false
