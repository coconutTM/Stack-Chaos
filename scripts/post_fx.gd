class_name PostFx
extends CanvasLayer

# โพสต์โปรเซสลดสี + dithering แบบ PS1 (shaders/psx_post.gdshader)
# layer 0 = วาดทับ 3D แต่ใต้ UI ทุกชั้น (ScoreLabel layer 1, ItemBar 5, DialogueBox 10)


func _ready() -> void:
	layer = 0
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE   # ห้ามกินคลิกของเกม
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/psx_post.gdshader")
	rect.material = m
	add_child(rect)
