class_name OrbitCamera
extends Camera3D

# กล้องโคจรรอบกองขยะ 360° / คลิกขวาค้าง + ลาก = หมุน, คลิกขวาสั้นๆ = ส่งสัญญาณ tapped
# (main.gd เอาไปใช้พลิกชิ้นที่ถือ) / ติดกับ node Camera3D ใน main.tscn

signal tapped   # คลิกขวาแบบไม่ลาก

const RADIUS := 8.0           # ระยะราบจากแกนกลางกอง
const HEIGHT := 9.0           # สูงเหนือยอดกอง
const DRAG_THRESHOLD := 4.0   # ขยับเมาส์เกินกี่พิกเซลถึงนับว่าเป็นการลาก (ไม่ใช่คลิก)
const DRAG_SENS := 0.012      # เรเดียนต่อพิกเซล
const FOLLOW := 3.0           # ความเร็วตามความสูงกอง (สูตร exp ไม่ขึ้นกับ framerate)

var yaw := 0.0                # มุมกล้องรอบแกน Y (0 = มองจากด้าน +Z เหมือนเดิม)
var target_y := 0.0           # ความสูงที่กล้องควรโฟกัส (main.gd ตั้งเป็น tower_top)
var dragging := false         # กำลังลากหมุนอยู่หรือไม่

var _focus_y := 0.0
var _right_down := false
var _drag_dist := 0.0


func _ready() -> void:
	_update_transform()


func _process(delta: float) -> void:
	_focus_y = lerpf(_focus_y, target_y, 1.0 - exp(-FOLLOW * delta))
	_update_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_right_down = true
			_drag_dist = 0.0
			dragging = false
		else:
			if _right_down and not dragging:
				tapped.emit()
			_right_down = false
			dragging = false
	elif event is InputEventMouseMotion and _right_down:
		_drag_dist += event.relative.length()
		if _drag_dist > DRAG_THRESHOLD:
			dragging = true
		if dragging:
			yaw -= event.relative.x * DRAG_SENS   # ลากขวา = ฉากหมุนตามเมาส์


func _update_transform() -> void:
	position = Vector3(sin(yaw) * RADIUS, _focus_y + HEIGHT, cos(yaw) * RADIUS)
	look_at(Vector3(0.0, _focus_y, 0.0))
