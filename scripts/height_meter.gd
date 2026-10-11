class_name HeightMeter
extends CanvasLayer

# แถบวัดความสูงแนวตั้งที่ขอบขวาจอ (พิกัด 426x240): ระดับกองตอนนี้ (เติมสี) / ขีดสูงสุดของวัน (ขาว) / ขีดโควต้า (เหลือง)
# main.gd เรียก set_values() ทุกเฟรม — ตัวแถบเลื่อนค่าที่โชว์ตามเองให้ไหลลื่น

const BAR_X := 410.0
const BAR_W := 7.0
const TOP_Y := 66.0
const BOT_Y := 186.0
const PAD_Y := 1.2            # ผิวแท่น = ศูนย์ของแถบ (พิกัดโลก เหมือน HEIGHT บน HUD)
const SMOOTH := 8.0           # ความเร็วไหลของระดับที่โชว์ (สูตร exp ไม่ขึ้นกับ framerate)
const COL_BG := Color(0.02, 0.02, 0.04, 0.8)
const COL_FILL := Color(0.85, 0.65, 0.1)
const COL_DONE := Color(0.4, 1.0, 0.45)
const COL_QUOTA := Color(1.0, 0.85, 0.2)

var _canvas: Control
var _top := 0.0               # ค่าจริง
var _best := 0.0
var _quota := 1.0
var _shown := 0.0             # ค่าที่โชว์ (ไหลตาม _top)


func _ready() -> void:
	layer = 4
	_canvas = Control.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_meter)
	add_child(_canvas)
	visible = false


func set_values(top: float, best: float, quota: float) -> void:
	_top = top
	_best = best
	_quota = quota


func _process(delta: float) -> void:
	_shown = lerpf(_shown, maxf(_top, PAD_Y), 1.0 - exp(-SMOOTH * delta))
	_canvas.queue_redraw()


# ความสูง (พิกัดโลก) → พิกัด y บนจอ / แถบสูงถึง 125% ของโควต้า เหลือที่ให้กองเกินได้
func _y_of(height: float) -> float:
	var span := maxf(0.1, _quota * 1.25 - PAD_Y)
	var t := clampf((height - PAD_Y) / span, 0.0, 1.0)
	return lerpf(BOT_Y, TOP_Y, t)


func _draw_meter() -> void:
	var font := _canvas.get_theme_default_font()
	_canvas.draw_rect(Rect2(BAR_X - 1.0, TOP_Y - 1.0, BAR_W + 2.0, BOT_Y - TOP_Y + 2.0), COL_BG)

	# ระดับกองตอนนี้
	var fill_y := _y_of(_shown)
	var reached := _top >= _quota
	_canvas.draw_rect(Rect2(BAR_X, fill_y, BAR_W, BOT_Y - fill_y), COL_DONE if reached else COL_FILL)

	# ขีดสูงสุดของวัน (ขาว)
	if _best > PAD_Y:
		var by := roundf(_y_of(_best))
		_canvas.draw_rect(Rect2(BAR_X - 3.0, by, BAR_W + 6.0, 1.0), Color(1, 1, 1, 0.9))

	# ขีดโควต้า + ตัวเลข
	var qy := roundf(_y_of(_quota))
	_canvas.draw_rect(Rect2(BAR_X - 4.0, qy - 1.0, BAR_W + 8.0, 2.0), COL_QUOTA)
	var text := "%.1f" % maxf(_quota - PAD_Y, 0.0)   # ตัวเลขนับจากผิวแท่น เหมือน HUD
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	_canvas.draw_string_outline(font, Vector2(BAR_X - 7.0 - w, qy + 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 4, Color.BLACK)
	_canvas.draw_string(font, Vector2(BAR_X - 7.0 - w, qy + 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_QUOTA)
	# ฐานแถบ = 0 (ผิวแท่น)
	_canvas.draw_rect(Rect2(BAR_X - 2.0, BOT_Y, BAR_W + 4.0, 1.0), Color(1, 1, 1, 0.5))
