class_name TouchControls
extends CanvasLayer

# ปุ่มบนจอสำหรับมือถือ (โหมดสัมผัส): DROP / SPIN / FLIP มุมขวาล่าง, VIEW มุมซ้ายล่าง
# โชว์เฉพาะตอน Settings.touch และกำลังถือชิ้นอยู่ (main ตั้ง visible ทุกเฟรม) / ปุ่มกินคลิกเอง จึงไม่ไปรบกวนการลากเล็ง

signal drop_pressed
signal spin_pressed
signal flip_pressed
signal view_pressed

const DROP_SIZE := Vector2(58.0, 40.0)
const SMALL_SIZE := Vector2(58.0, 26.0)
const MARGIN := 6.0
const RIGHT_MARGIN := 20.0   # เว้นขวาให้แถบวัดความสูง (HeightMeter อยู่ที่ x≈410)
const HINT_HEIGHT := 40.0    # ข้อความแนะนำปุ่มมุมซ้ายล่าง (ItemBar) — ปุ่ม VIEW วางเหนือขึ้นไป


func _ready() -> void:
	layer = 5
	visible = false

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# ขวาล่าง: DROP ใหญ่ที่สุดอยู่ล่างสุด (นิ้วโป้งถึงง่าย) + FLIP / SPIN วางซ้อนขึ้นไป (แถบ item อยู่กลางจอ จึงไม่ชน)
	var x := -RIGHT_MARGIN - DROP_SIZE.x
	var y := -MARGIN - DROP_SIZE.y
	_add_button(root, "DROP", DROP_SIZE, Vector2(1.0, 1.0), Vector2(x, y), drop_pressed)
	y -= 4.0 + SMALL_SIZE.y
	_add_button(root, "FLIP", SMALL_SIZE, Vector2(1.0, 1.0), Vector2(x, y), flip_pressed)
	y -= 4.0 + SMALL_SIZE.y
	_add_button(root, "SPIN", SMALL_SIZE, Vector2(1.0, 1.0), Vector2(x, y), spin_pressed)
	# ซ้ายล่าง: คืนมุมกล้อง (เหนือข้อความแนะนำปุ่ม)
	_add_button(root, "VIEW", SMALL_SIZE, Vector2(0.0, 1.0), Vector2(MARGIN, -MARGIN - HINT_HEIGHT - SMALL_SIZE.y), view_pressed)


# anchor = มุมที่ยึด (0/1) / pos = ตำแหน่งมุมบนซ้ายของปุ่มเทียบกับมุมนั้น
func _add_button(parent: Control, text: String, size: Vector2, anchor: Vector2, pos: Vector2, sig: Signal) -> void:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.anchor_left = anchor.x
	b.anchor_right = anchor.x
	b.anchor_top = anchor.y
	b.anchor_bottom = anchor.y
	b.offset_left = pos.x
	b.offset_top = pos.y
	b.offset_right = pos.x + size.x
	b.offset_bottom = pos.y + size.y
	b.add_theme_font_size_override("font_size", 8)
	b.pressed.connect(sig.emit)
	parent.add_child(b)
