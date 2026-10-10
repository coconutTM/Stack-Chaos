class_name PauseMenu
extends CanvasLayer

# หยุดเกมชั่วคราวระหว่างเล่น: ปุ่ม PAUSE มุมขวาบน หรือกด Esc / P
# ใช้ get_tree().paused → ฟิสิกส์ / main.gd / เสียง หยุดหมด ส่วนเมนูนี้ทำงานต่อ (PROCESS_MODE_ALWAYS)

signal quit_requested   # กด QUIT TO TITLE (main.gd พากลับหน้าแรก)

var can_pause: Callable   # main ตั้งให้: คืน true เมื่อหยุดได้ (ระหว่างถือ/รอชิ้นนิ่งเท่านั้น)

var _button: Button
var _menu: Control


func _ready() -> void:
	layer = 15   # เหนือกล่อง boss (10) ใต้จอดำตอนเปลี่ยนฉาก (ScreenFx)
	process_mode = Node.PROCESS_MODE_ALWAYS

	_button = Button.new()
	_button.text = "PAUSE"
	_button.focus_mode = Control.FOCUS_NONE
	_button.anchor_left = 1.0
	_button.anchor_right = 1.0
	_button.offset_left = -58.0
	_button.offset_right = -3.0
	_button.offset_top = 3.0
	_button.offset_bottom = 17.0
	_button.add_theme_font_size_override("font_size", 8)
	_button.pressed.connect(set_paused.bind(true))
	_button.visible = false
	add_child(_button)

	# ฉากมืดทับทั้งจอ + เมนูกลางจอ (mouse_filter STOP กินคลิกไม่ให้ไปปล่อยบล็อก)
	_menu = ColorRect.new()
	(_menu as ColorRect).color = Color(0, 0, 0, 0.65)
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu.visible = false
	add_child(_menu)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	_menu.add_child(box)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	box.add_child(title)
	box.add_child(_menu_button("RESUME", set_paused.bind(false)))
	box.add_child(_menu_button("QUIT TO TITLE", _quit))
	var hint := Label.new()
	hint.text = "ESC to resume"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 8)
	hint.modulate = Color(1, 1, 1, 0.6)
	box.add_child(hint)


func _menu_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(136, 18)
	b.add_theme_font_size_override("font_size", 8)
	b.pressed.connect(action)
	return b


func _process(_delta: float) -> void:
	_button.visible = not get_tree().paused and can_pause.is_valid() and can_pause.call()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE or key.keycode == KEY_P:
		if get_tree().paused:
			set_paused(false)
		elif can_pause.is_valid() and can_pause.call():
			set_paused(true)
		get_viewport().set_input_as_handled()


func set_paused(on: bool) -> void:
	get_tree().paused = on
	_menu.visible = on


func _quit() -> void:
	set_paused(false)
	quit_requested.emit()
