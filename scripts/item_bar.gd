class_name ItemBar
extends CanvasLayer

# แถบ item ด้านล่างจอ: ช่องละ 1 item คลิกเพื่อใช้ / เอาเมาส์ชี้เพื่ออ่านคำอธิบาย
# + บรรทัดสถานะ (กาแฟ/ประกัน) เหนือแถบ + รายการ 3 ชิ้นถัดไปมุมขวาบน (เมื่อมี Clipboard)
# main.gd เรียก refresh() ทุกเฟรม (ข้ามเองถ้าไม่มีอะไรเปลี่ยน)

signal slot_pressed(index: int)

const SLOT_W := 56.0
const SLOT_H := 26.0
const GAP := 3.0

var _buttons: Array[Button] = []
var _info: Label
var _next: Label
var _root: Control
var _inventory: Array = []
var _status := ""
var _hover := -1
var _signature := ""


func _ready() -> void:
	layer = 5
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var width := ItemData.MAX_SLOTS * SLOT_W + (ItemData.MAX_SLOTS - 1) * GAP
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", int(GAP))
	row.anchor_left = 0.5
	row.anchor_right = 0.5
	row.anchor_top = 1.0
	row.anchor_bottom = 1.0
	row.offset_left = -width * 0.5
	row.offset_right = width * 0.5
	row.offset_top = -(SLOT_H + 4.0)
	row.offset_bottom = -4.0
	_root.add_child(row)

	for i in ItemData.MAX_SLOTS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 8)
		b.pressed.connect(slot_pressed.emit.bind(i))
		b.mouse_entered.connect(_on_hover.bind(i))
		b.mouse_exited.connect(_on_hover.bind(-1))
		row.add_child(b)
		_buttons.append(b)

	_info = Label.new()
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.anchor_left = 0.0
	_info.anchor_right = 1.0
	_info.anchor_top = 1.0
	_info.anchor_bottom = 1.0
	_info.offset_top = -(SLOT_H + 20.0)
	_info.offset_bottom = -(SLOT_H + 6.0)
	_info.add_theme_font_size_override("font_size", 8)
	_info.add_theme_color_override("font_outline_color", Color.BLACK)
	_info.add_theme_constant_override("outline_size", 4)
	_root.add_child(_info)

	_next = Label.new()
	_next.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_next.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_next.anchor_left = 1.0
	_next.anchor_right = 1.0
	_next.offset_left = -120.0
	_next.offset_right = -4.0
	_next.offset_top = 22.0
	_next.add_theme_font_size_override("font_size", 8)
	_next.add_theme_color_override("font_outline_color", Color.BLACK)
	_next.add_theme_constant_override("outline_size", 4)
	_root.add_child(_next)

	visible = false


# inventory = id ของ item / usable = กดใช้ได้ไหม / status = ข้อความสถานะ / next_text = รายการชิ้นถัดไป ("" = ซ่อน)
func refresh(inventory: Array, usable: bool, status: String, next_text: String) -> void:
	var sig := "%s|%s|%s|%s" % [inventory, usable, status, next_text]
	if sig == _signature:
		return
	_signature = sig
	_inventory = inventory
	_status = status

	for i in _buttons.size():
		var b := _buttons[i]
		if i < inventory.size():
			var data: Dictionary = ItemData.ITEMS[inventory[i]]
			b.text = data.short
			b.modulate = data.color
			b.disabled = not usable
		else:
			b.text = "-"
			b.modulate = Color(1, 1, 1, 0.45)
			b.disabled = true
	_next.text = next_text
	_next.visible = next_text != ""
	_update_info()


func _on_hover(index: int) -> void:
	_hover = index
	_update_info()


func _update_info() -> void:
	if _hover >= 0 and _hover < _inventory.size():
		var data: Dictionary = ItemData.ITEMS[_inventory[_hover]]
		_info.text = "%s: %s" % [data.name, data.desc]
	else:
		_info.text = _status
