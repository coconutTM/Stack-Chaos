class_name FpsOverlay
extends CanvasLayer

# ตัวเลข FPS / draw call มุมขวาล่าง กด F3 เปิด-ปิด (ไว้เช็คประสิทธิภาพบนเว็บ build ปิดไว้เป็นค่าเริ่มต้น)
# F3 เป็นปุ่มดีบักเท่านั้น ตัวเกมยังควบคุมด้วยเมาส์อย่างเดียว

var _label: Label


func _ready() -> void:
	layer = 20
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.anchor_left = 1.0
	_label.anchor_right = 1.0
	_label.anchor_top = 1.0
	_label.anchor_bottom = 1.0
	_label.offset_left = -110.0
	_label.offset_top = -14.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)
	visible = false


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		visible = not visible


func _process(_delta: float) -> void:
	if not visible:
		return
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	_label.text = "%d FPS  %d draws" % [Engine.get_frames_per_second(), draws]
