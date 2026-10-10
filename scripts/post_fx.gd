class_name PostFx
extends CanvasLayer

# โพสต์โปรเซสลดสี + dithering แบบ PS1 (shaders/psx_post.gdshader)
# layer 0 = วาดทับ 3D แต่ใต้ UI ทุกชั้น (ScoreLabel layer 1, ItemBar 5, DialogueBox 10)

const BASE_HEIGHT := 240.0   # ความสูงอ้างอิงของเกม (project.godot viewport_height) ลาย dither ขยายตามความสูงจริงของจอ

var _material: ShaderMaterial


func _ready() -> void:
	layer = 0
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE   # ห้ามกินคลิกของเกม
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/psx_post.gdshader")
	rect.material = m
	add_child(rect)
	_material = m
	get_window().size_changed.connect(_update_scale)
	_update_scale()


# canvas_items: 3D เรนเดอร์ที่ความละเอียดจริง → ให้ลาย dither หยาบเท่ากับตอน 426x240 (ปัดเป็นจำนวนเต็ม ลายไม่เบลอ)
func _update_scale() -> void:
	var scale_factor := maxf(1.0, floorf(get_window().size.y / BASE_HEIGHT))
	_material.set_shader_parameter("pixel_scale", scale_factor)
