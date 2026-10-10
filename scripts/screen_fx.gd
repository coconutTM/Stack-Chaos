class_name ScreenFx
extends CanvasLayer

# เอฟเฟกต์เต็มจอ: แฟลชสี (เช่นแดงตอนเสียชิ้น) / flash(color, alpha, seconds)

var _rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 2   # เหนือ HUD (layer 1) ใต้แถบ item (5) และกล่อง boss (10)
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE   # ห้ามกินคลิก
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.color = Color(1, 1, 1, 0)
	add_child(_rect)


func flash(color: Color, alpha := 0.3, seconds := 0.35) -> void:
	if _tween:
		_tween.kill()
	_rect.color = Color(color, alpha)
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", 0.0, seconds)
