class_name SettingsPanel
extends CanvasLayer

# หน้า SETTINGS (พิกัด 426x240): ความดัง / ความไวหมุนกล้อง / ความเร็วตัวอักษร / ลุคเรโทร / เต็มจอ (F11 ใช้ได้ทุกหน้า ไม่บันทึกค่า) (dither + vertex snapping) / ใช้ได้ทั้งหน้า title และตอน pause
# ค่าเก็บใน Settings (user://settings.cfg) / ทำงานต่อได้ตอนเกมถูก pause (PROCESS_MODE_ALWAYS)

signal closed
signal changed     # ปล่อยสไลเดอร์/กดปุ่ม (ไว้เล่นเสียงตัวอย่าง)

var _volume: HSlider
var _volume_value: Label
var _sens: HSlider
var _sens_value: Label
var _text: HSlider
var _text_value: Label
var _retro: Button
var _fullscreen: Button
var _loading := false


func _ready() -> void:
	layer = 16   # เหนือ PauseMenu (15) ให้เปิดจากเมนู pause ได้ ใต้จอมืดตอนเปลี่ยนฉาก (ScreenFx 20)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 0.99)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP   # กินคลิกไม่ให้ทะลุไปปุ่มด้านหลัง
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	bg.add_child(box)

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	box.add_child(title)

	_volume = _slider(0.0, 1.0, 0.05)
	_volume_value = Label.new()
	box.add_child(_row("VOLUME", _volume, _volume_value))
	_volume.value_changed.connect(_on_volume)
	_volume.drag_ended.connect(func(_c: bool) -> void: changed.emit())

	_sens = _slider(0.5, 2.0, 0.1)
	_sens_value = Label.new()
	box.add_child(_row("CAMERA SPEED", _sens, _sens_value))
	_sens.value_changed.connect(_on_sens)
	_sens.drag_ended.connect(func(_c: bool) -> void: changed.emit())

	_text = _slider(0.5, 3.0, 0.25)
	_text_value = Label.new()
	box.add_child(_row("TEXT SPEED", _text, _text_value))
	_text.value_changed.connect(_on_text_speed)
	_text.drag_ended.connect(func(_c: bool) -> void: changed.emit())

	_retro = Button.new()
	_retro.toggle_mode = true
	_retro.focus_mode = Control.FOCUS_NONE
	_retro.custom_minimum_size = Vector2(200, 18)
	_retro.add_theme_font_size_override("font_size", 8)
	_retro.toggled.connect(_on_retro)
	_retro.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_retro)

	_fullscreen = Button.new()
	_fullscreen.toggle_mode = true
	_fullscreen.focus_mode = Control.FOCUS_NONE
	_fullscreen.custom_minimum_size = Vector2(200, 18)
	_fullscreen.add_theme_font_size_override("font_size", 8)
	_fullscreen.toggled.connect(_on_fullscreen)
	_fullscreen.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_fullscreen)

	var hint := Label.new()
	hint.text = "Retro look off = sharper and lighter on slow PCs"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 8)
	hint.modulate = Color(1, 1, 1, 0.55)
	box.add_child(hint)

	var back := Button.new()
	back.text = "BACK"
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(136, 18)
	back.add_theme_font_size_override("font_size", 8)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(close)
	box.add_child(back)
	visible = false


func _slider(lo: float, hi: float, step: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.focus_mode = Control.FOCUS_NONE
	s.custom_minimum_size = Vector2(140, 14)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return s


# แถว: ชื่อ (ซ้าย) + สไลเดอร์ + ค่า (ขวา)
func _row(name: String, slider: HSlider, value: Label) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var l := Label.new()
	l.text = name
	l.custom_minimum_size = Vector2(104, 0)
	l.add_theme_font_size_override("font_size", 8)
	row.add_child(l)
	row.add_child(slider)
	value.custom_minimum_size = Vector2(40, 0)
	value.add_theme_font_size_override("font_size", 8)
	row.add_child(value)
	return row


func open() -> void:
	_loading = true   # ตั้งค่าเริ่มต้นของ UI โดยไม่ให้ไปเรียก handler (ไม่งั้นเขียนไฟล์ซ้ำ)
	_volume.value = Settings.volume
	_sens.value = Settings.camera_sens
	_text.value = Settings.text_speed
	_retro.button_pressed = Settings.retro_look
	_fullscreen.button_pressed = _is_fullscreen()
	_loading = false
	_refresh_texts()
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	Settings.save_all()
	closed.emit()


func _refresh_texts() -> void:
	_volume_value.text = "%d%%" % roundi(_volume.value * 100.0)
	_sens_value.text = "x%.1f" % _sens.value
	_text_value.text = "x%.2f" % _text.value
	_retro.text = "RETRO LOOK: %s" % ("ON" if _retro.button_pressed else "OFF")
	_fullscreen.text = "FULLSCREEN: %s (F11)" % ("ON" if _fullscreen.button_pressed else "OFF")


func _on_volume(v: float) -> void:
	if _loading:
		return
	Settings.volume = v
	Settings.apply_audio()
	_refresh_texts()


func _on_sens(v: float) -> void:
	if _loading:
		return
	Settings.camera_sens = v
	_refresh_texts()


func _on_text_speed(v: float) -> void:
	if _loading:
		return
	Settings.text_speed = v
	_refresh_texts()


func _is_fullscreen() -> bool:
	var m := DisplayServer.window_get_mode()
	return m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _on_fullscreen(on: bool) -> void:
	if _loading:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
	_refresh_texts()
	changed.emit()


func _on_retro(on: bool) -> void:
	if _loading:
		return
	Settings.retro_look = on
	Psx.set_snap(on)
	get_tree().call_group("retro_post", "set_enabled", on)
	_refresh_texts()
	changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		# สลับเต็มจอจากทุกหน้า (ผ่านปุ่มเสมอ เพื่อให้ข้อความปุ่มตรงกับสถานะจริง)
		_loading = true
		_fullscreen.button_pressed = not _is_fullscreen()
		_loading = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if _fullscreen.button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)
		_refresh_texts()
		get_viewport().set_input_as_handled()
		return
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
