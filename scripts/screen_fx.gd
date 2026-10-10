class_name ScreenFx
extends CanvasLayer

# เอฟเฟกต์เต็มจอ: แฟลชสี (เช่นแดงตอนเสียชิ้น) / flash(color, alpha, seconds)

const EYE_COLOR := Color(1.0, 0.85, 0.2)

var _rect: ColorRect
var _black: ColorRect
var _eyes: Control
var _tween: Tween
var _fade_tween: Tween


func _ready() -> void:
	layer = 2   # เหนือ HUD (layer 1) ใต้แถบ item (5) และกล่อง boss (10)
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE   # ห้ามกินคลิก
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.color = Color(1, 1, 1, 0)
	add_child(_rect)

	# ฉากมืดสนิทสำหรับฉากจบ (ทับ HUD ที่ layer 1 ทั้งหมด)
	_black = ColorRect.new()
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.color = Color(0, 0, 0, 0)
	add_child(_black)

	# ตาเรืองสองดวงกลางจอ (ตาของผู้เล่นในฉากจบ) กว้างเริ่มปิด
	_eyes = Control.new()
	_eyes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eyes.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_eyes.visible = false
	add_child(_eyes)
	for x in [-24.0, 12.0]:
		var glow := ColorRect.new()
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.color = Color(EYE_COLOR, 0.25)
		glow.position = Vector2(x - 4, -8)
		glow.size = Vector2(20, 16)
		_eyes.add_child(glow)
		var eye := ColorRect.new()
		eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
		eye.color = EYE_COLOR
		eye.position = Vector2(x, -4)
		eye.size = Vector2(12, 8)
		_eyes.add_child(eye)


# จอค่อยๆ มืดสนิท (ใช้ await ได้)
func fade_to_black(seconds := 1.5) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_black, "color:a", 1.0, seconds)
	await _fade_tween.finished


# ตาเรืองกลางจอลืมขึ้นช้าๆ (scale แกน y จาก 0 → 1) / on = false ซ่อน
func show_eyes(on: bool, open_seconds := 0.8) -> void:
	_eyes.visible = on
	if not on:
		return
	_eyes.scale = Vector2(1, 0.05)
	_eyes.pivot_offset = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(_eyes, "scale:y", 1.0, open_seconds)
	await tw.finished


# ล้างทุกอย่างกลับปกติ (ค่อยๆ สว่างขึ้น)
func clear(seconds := 0.6) -> void:
	_eyes.visible = false
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_black, "color:a", 0.0, seconds)
	await _fade_tween.finished


func flash(color: Color, alpha := 0.3, seconds := 0.35) -> void:
	if _tween:
		_tween.kill()
	_rect.color = Color(color, alpha)
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", 0.0, seconds)
