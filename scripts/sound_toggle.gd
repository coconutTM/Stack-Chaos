class_name SoundToggle
extends CanvasLayer

# ปุ่มเปิด/ปิดเสียงมุมขวาบน (คลิกด้วยเมาส์) / จำค่าไว้ใน Settings (บนเว็บเบราว์เซอร์มักบล็อกเสียงจนกว่าจะคลิก จึงควรมีปุ่มนี้)

var _button: Button


func _ready() -> void:
	layer = 12   # เหนือกล่อง boss (10) ให้กดได้เสมอ
	_button = Button.new()
	_button.focus_mode = Control.FOCUS_NONE
	_button.anchor_left = 1.0
	_button.anchor_right = 1.0
	_button.offset_left = -66.0
	_button.offset_right = -3.0
	_button.offset_top = 3.0
	_button.offset_bottom = 17.0
	_button.add_theme_font_size_override("font_size", 8)
	_button.pressed.connect(_toggle)
	add_child(_button)
	_apply()


func _toggle() -> void:
	Settings.muted = not Settings.muted
	Settings.save_all()
	_apply()


func _apply() -> void:
	AudioServer.set_bus_mute(0, Settings.muted)
	_button.text = "SND OFF" if Settings.muted else "SND ON"
