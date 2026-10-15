class_name BossShop
extends CanvasLayer

# ร้านของ boss: ท้ายวัน (หลังสรุปผลงาน/เลือกรางวัล) ใช้เงินซื้อ item หรือขาย item ในคลังคืน boss / พิกัด 426x240
# main.gd: shop.buy / shop.sell = Callable → await shop.open(stock, cash, boss_line, inventory)
# main เป็นเจ้าของเงินและคลัง: ร้านแค่แสดงผล — กดการ์ด/ช่อง = เรียก callable แล้ววาดตามผลที่ได้กลับมา
#   buy(id)     -> {"ok": bool, "cash": เงินคงเหลือ, "line": บทพูด boss, "inventory": คลังหลังซื้อ}
#   sell(index) -> ผลแบบเดียวกัน (ขายช่องที่ index ของคลัง)

signal closed

const SLOT := 38.0   # ช่องคลังสี่เหลี่ยมพอดีไอคอน (ขนาดเดียวกับ ItemBar)
const SLOT_GAP := 4.0

var _armed_slot := -1   # สัมผัส: ช่องคลังที่แตะไปแล้วครั้งหนึ่ง (แตะซ้ำ = ขาย)
var buy: Callable
var sell: Callable

var _cash: Label
var _boss: Label
var _desc: Label
var _row: HBoxContainer
var _slot_row: HBoxContainer
var _slots: Array[Button] = []
var _inventory: Array = []
var _open := false
var _cards := {}   # id → ปุ่มการ์ด


func _ready() -> void:
	layer = 12   # ระดับเดียวกับ ItemChoice (เหนือ DialogueBox ใต้ PauseMenu และ ScreenFx)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 0.97)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := _label(16, 10.0, 18.0)
	title.text = "BOSS'S STOCK"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_cash = _label(8, 32.0, 10.0)
	_cash.add_theme_color_override("font_color", Color(0.5, 0.85, 0.5))
	_boss = _label(8, 46.0, 10.0)
	_boss.add_theme_color_override("font_color", Color(0.92, 0.9, 0.78))

	_row = HBoxContainer.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("separation", int(ItemChoice.GAP))
	_row.anchor_left = 0.5
	_row.anchor_right = 0.5
	_row.offset_top = 64.0
	_row.offset_bottom = 64.0 + ItemChoice.CARD_H_SMALL
	add_child(_row)

	_desc = _label(8, 146.0, 10.0)   # คำอธิบายของที่ชี้เมาส์อยู่ (การ์ด / ช่องคลัง)
	_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

	var sell_title := _label(8, 164.0, 10.0)
	sell_title.text = Settings.wording("YOUR ITEMS - CLICK ONE TO SELL")
	sell_title.add_theme_color_override("font_color", Color(0.6, 0.5, 0.15))

	var width := ItemData.MAX_SLOTS * SLOT + (ItemData.MAX_SLOTS - 1) * SLOT_GAP
	_slot_row = HBoxContainer.new()
	_slot_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot_row.add_theme_constant_override("separation", int(SLOT_GAP))
	_slot_row.anchor_left = 0.5
	_slot_row.anchor_right = 0.5
	_slot_row.offset_left = -width * 0.5
	_slot_row.offset_right = width * 0.5
	_slot_row.offset_top = 178.0
	_slot_row.offset_bottom = 178.0 + SLOT
	add_child(_slot_row)
	for i in ItemData.MAX_SLOTS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(SLOT, SLOT)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 8)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.expand_icon = false
		b.pressed.connect(_on_slot.bind(i))
		b.mouse_entered.connect(_on_slot_hover.bind(i))
		b.mouse_exited.connect(func() -> void: _desc.text = "")
		_slot_row.add_child(b)
		_slots.append(b)

	var leave := Button.new()
	leave.text = "LEAVE"
	leave.focus_mode = Control.FOCUS_NONE
	leave.anchor_left = 0.5
	leave.anchor_right = 0.5
	leave.offset_left = width * 0.5 + 12.0
	leave.offset_right = width * 0.5 + 76.0
	leave.offset_top = 178.0 + SLOT - 22.0
	leave.offset_bottom = 178.0 + SLOT
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


# เปิดร้าน (stock = id ใน ItemData.ITEMS, inventory = คลังของผู้เล่นตอนนี้) แล้วรอจนผู้เล่นกด LEAVE
func open(stock: Array, cash: int, boss_line: String, inventory: Array) -> void:
	for c in _row.get_children():
		c.queue_free()
	_cards.clear()
	for id in stock:
		var data: Dictionary = ItemData.ITEMS[id]
		var card := ItemChoice.make_card(data.name, data.desc, data.color, "$%d" % data.price, ItemData.icon(id))
		var item_id: String = id
		ItemChoice.bind_hover(card, _desc)
		ItemChoice.bind_confirm(card, _desc, _on_card.bind(item_id))
		_row.add_child(card)
		_cards[item_id] = card
	var width := stock.size() * ItemChoice.CARD_W + (stock.size() - 1) * ItemChoice.GAP
	_row.offset_left = -width * 0.5
	_row.offset_right = width * 0.5
	_set_cash(cash)
	_say(boss_line)
	_desc.text = ""
	_refresh_inventory(inventory)
	_open = true
	visible = true
	await closed
	_open = false
	visible = false


func _on_card(id: String) -> void:
	var result: Dictionary = buy.call(id)
	_apply(result)
	if result.ok:
		var card: Button = _cards[id]
		card.disabled = true
		(card.get_meta("footer") as Label).text = "SOLD"
		_desc.text = ""


func _on_slot(index: int) -> void:
	if index >= _inventory.size():
		return
	if Settings.touch and _armed_slot != index:   # สัมผัส: แตะครั้งแรกโชว์ราคา แตะซ้ำถึงขาย
		_armed_slot = index
		_on_slot_hover(index)
		return
	_armed_slot = -1
	_apply(sell.call(index))
	_desc.text = ""


# ชี้ช่องคลัง = บอกชื่อและราคาที่ boss รับซื้อ
func _on_slot_hover(index: int) -> void:
	if index < _inventory.size():
		var id: String = _inventory[index]
		_desc.text = "%s - SELL FOR $%d" % [ItemData.ITEMS[id].name, ItemData.sell_price(id)]


# วาดผลของการซื้อ/ขาย (เงิน บทพูด คลัง)
func _apply(result: Dictionary) -> void:
	_set_cash(int(result.cash))
	_say(String(result.line))
	_refresh_inventory(result.inventory)


func _refresh_inventory(inventory: Array) -> void:
	_inventory = inventory
	for i in _slots.size():
		var b := _slots[i]
		if i < inventory.size():
			var data: Dictionary = ItemData.ITEMS[inventory[i]]
			var icon := ItemData.icon(inventory[i])
			b.icon = icon
			b.text = "" if icon != null else data.short
			b.modulate = Color.WHITE if icon != null else data.color
			b.disabled = false
		else:
			b.icon = null
			b.text = "-"
			b.modulate = Color(1, 1, 1, 0.45)
			b.disabled = true


func _set_cash(cash: int) -> void:
	_cash.text = "CASH: $%d" % cash


func _say(line: String) -> void:
	_boss.text = '"%s"' % line


# ตัดทิ้งทันที (คำสั่ง /day) ให้ coroutine ที่ await open() ตื่นแล้วเลิกเอง (main เช็ค _flow_id)
func abort() -> void:
	if _open:
		closed.emit()
	visible = false
