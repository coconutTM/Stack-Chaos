class_name OrbitCamera
extends Camera3D

# กล้องโคจรรอบกองขยะ 360° / คลิกขวาค้าง + ลาก = หมุน, คลิกขวาสั้นๆ = ส่งสัญญาณ tapped
# (main.gd เอาไปใช้หมุนชิ้นที่ถือ) / ลูกกลิ้ง = ซูม / ติดกับ node Camera3D ใน main.tscn

signal tapped   # คลิกขวาแบบไม่ลาก

const RADIUS := 9.5           # ระยะราบจากแกนกลางกอง
const HEIGHT := 5.5           # สูงเหนือยอดกอง
const DRAG_THRESHOLD := 4.0   # ขยับเมาส์เกินกี่พิกเซลถึงนับว่าเป็นการลาก (ไม่ใช่คลิก)
const DRAG_SENS := 0.012      # เรเดียนต่อพิกเซล
const SHAKE_MAX := 0.45       # ระยะเลื่อนภาพสูงสุดตอนสั่นเต็มที่ (เมตรที่ระนาบภาพ)
const SHAKE_DECAY := 1.8      # trauma ลดลงต่อวินาที
const FOLLOW := 3.0           # ความเร็วตามความสูงกอง (สูตร exp ไม่ขึ้นกับ framerate)
const ZOOM_MIN := 0.6         # ซูมเข้าสุด (คูณ RADIUS / HEIGHT)
const ZOOM_MAX := 1.5         # ซูมออกสุด
const ZOOM_STEP := 1.12       # คูณ/หารต่อลูกกลิ้ง 1 คลิก
const ZOOM_FOLLOW := 8.0      # ความเร็วซูมตามเป้า (สูตร exp)
const MAX_RADIUS := Crane.MAST_DIST - 1.0   # ถอยหลังได้ไม่เกินนี้ (ไม่ทะลุเสาเครน) เกินแล้วยกกล้องสูงขึ้นแทน

var yaw := 0.0                # มุมกล้องรอบแกน Y (0 = มองจากด้าน +Z เหมือนเดิม)
var target_y := 0.0           # ความสูงที่กล้องควรโฟกัส (main.gd ตั้งเป็น tower_top)
var dragging := false         # กำลังลากหมุนอยู่หรือไม่
var zoom := 1.0               # ระดับซูมเป้าหมาย (ZOOM_MIN-ZOOM_MAX, น้อย = ใกล้) / main รีเซ็ตเป็น 1.0 ที่หน้า title
var can_zoom := false         # main ตั้งทุกเฟรม: ซูมได้เฉพาะตอนเล่น (ลูกกลิ้งหน้าอื่นไม่ทำอะไร)

var _trauma := 0.0            # ความแรงสั่นจอ 0-1 (สั่นจริง = trauma²)

var _focus_y := 0.0
var _zoom := 1.0              # ค่าซูมที่ลื่นแล้ว (ตามเป้า zoom)
var _right_down := false
var _drag_dist := 0.0


func _ready() -> void:
	far = 80.0   # ระยะวาดสั้นแบบ PS1 (ไกลกว่านี้ถูก fog กลืนอยู่แล้ว)
	_update_transform()


func _process(delta: float) -> void:
	_focus_y = lerpf(_focus_y, target_y, 1.0 - exp(-FOLLOW * delta))
	_zoom = lerpf(_zoom, zoom, 1.0 - exp(-ZOOM_FOLLOW * delta))
	_update_transform()

	# สั่นจอด้วย h_offset/v_offset (ไม่ยุ่งกับ look_at)
	_trauma = maxf(0.0, _trauma - SHAKE_DECAY * delta)
	var power := _trauma * _trauma * SHAKE_MAX
	h_offset = randf_range(-1.0, 1.0) * power
	v_offset = randf_range(-1.0, 1.0) * power


# สั่นจอค้างอย่างน้อยที่ระดับ level (ใช้กับเอฟเฟกต์ต่อเนื่อง เรียกซ้ำทุกเฟรมระหว่างที่ยังสั่น)
func rumble(level: float) -> void:
	_trauma = maxf(_trauma, level)


# สั่นจอเพิ่ม amount (0-1 สะสมได้ สูงสุด 1)
func shake(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)


func _unhandled_input(event: InputEvent) -> void:
	if can_zoom and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom / ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom * ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)

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
			yaw -= event.relative.x * DRAG_SENS * Settings.camera_sens   # ลากขวา = ฉากหมุนตามเมาส์


func _update_transform() -> void:
	var radius := minf(RADIUS * _zoom, MAX_RADIUS)
	position = Vector3(sin(yaw) * radius, _focus_y + HEIGHT * _zoom, cos(yaw) * radius)
	look_at(Vector3(0.0, _focus_y, 0.0))
