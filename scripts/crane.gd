class_name Crane
extends Node3D

# เครนทาวเวอร์ประกอบจาก primitive ล้วน (สร้างด้วยโค้ด)
# - ทั้งเครนหมุนตามมุมกล้อง: เสาอยู่ฝั่งตรงข้ามกล้องเสมอ แขนยื่นข้ามกองมาทางกล้อง
# - แขนเล็งไปทางชิ้นที่ถือ, trolley เลื่อนตามระยะ, สายเคเบิลยืดหดตามความสูง

const MAST_DIST := 5.4        # เสาห่างศูนย์กลางกองเท่านี้ (ฝั่งตรงข้ามกล้อง)
const MAST_BOTTOM := Junkyard.FLOOR_Y   # เสายืนบนพื้นลาน (นอกแท่นวาง)
const JIB_ABOVE_HOLD := 3.0   # แขนเครนอยู่เหนือชิ้นที่ถือเท่านี้
const JIB_BACK := 2.5         # แขนยื่นไปด้านหลังเสา (ฝั่ง counterweight)
const JIB_FRONT := 11.5       # แขนยื่นไปด้านหน้า
const IDLE_HOOK_LEN := 1.0    # ความยาวสายตอนไม่ได้ถืออะไร
const FOLLOW := 3.0           # ความเร็วยกแขนตามกอง
const HOOK_FOLLOW := 10.0     # ความเร็วหย่อน/ดึงตะขอ

var _jib_y := 0.0
var _jib_angle := 0.0
var _trolley_r := 6.0
var _hook_len := IDLE_HOOK_LEN
var _inited := false

var _mast: MeshInstance3D
var _pivot: Node3D       # หมุนเล็งไปหาชิ้นที่ถือ
var _trolley: Node3D
var _cable: MeshInstance3D
var _hook: Node3D


func _ready() -> void:
	var yellow := _mat(Color(0.85, 0.65, 0.1))
	var dark := _mat(Color(0.2, 0.22, 0.26))
	var glass := _mat(Color(0.5, 0.8, 0.9))
	var black := _mat(Color(0.08, 0.08, 0.08))
	var steel := _mat(Color(0.7, 0.7, 0.72))

	_mast = _box(self, Vector3(0.7, 1.0, 0.7), Vector3.ZERO, yellow)

	_pivot = Node3D.new()
	add_child(_pivot)
	_box(_pivot, Vector3(0.3, 0.3, JIB_FRONT + JIB_BACK), Vector3(0, 0, (JIB_FRONT - JIB_BACK) * 0.5), yellow)
	_box(_pivot, Vector3(0.9, 0.5, 0.9), Vector3(0, 0.3, 0), yellow)            # หัวหมุน
	_box(_pivot, Vector3(1.2, 0.7, 0.8), Vector3(0, -0.1, -JIB_BACK + 0.4), dark)  # counterweight
	_box(_pivot, Vector3(1.0, 0.9, 1.2), Vector3(0.95, -0.6, 0.3), dark)         # ห้องคนขับ
	_box(_pivot, Vector3(0.7, 0.45, 0.05), Vector3(0.95, -0.5, 0.93), glass)     # กระจกหน้า

	_trolley = Node3D.new()
	_pivot.add_child(_trolley)
	_box(_trolley, Vector3(0.5, 0.3, 0.7), Vector3.ZERO, dark)
	_cable = _box(_trolley, Vector3(0.06, 1.0, 0.06), Vector3.ZERO, black)

	_hook = Node3D.new()
	_trolley.add_child(_hook)
	_box(_hook, Vector3(0.3, 0.25, 0.3), Vector3.ZERO, steel)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.22
	torus.rings = 8
	torus.ring_segments = 6
	ring.mesh = torus
	ring.material_override = steel
	ring.rotation_degrees = Vector3(90, 0, 0)
	ring.position = Vector3(0, -0.25, 0)
	_hook.add_child(ring)


# เรียกทุกเฟรมจาก main.gd / held = ชิ้นที่ถืออยู่ (null = ไม่ได้ถือ ตะขอจะยกขึ้นและ trolley อยู่ที่เดิม)
func update_crane(yaw: float, held: Block, hold_y: float, delta: float) -> void:
	rotation.y = yaw

	var target_jib := hold_y + JIB_ABOVE_HOLD
	_jib_y = target_jib if not _inited else lerpf(_jib_y, target_jib, 1.0 - exp(-FOLLOW * delta))

	var target_len := IDLE_HOOK_LEN
	if held != null:
		# หาตำแหน่งชิ้นที่ถือในกรอบของเครน แล้วเล็งแขน + เลื่อน trolley ไปเหนือมัน
		var p := to_local(held.global_position)
		var v := Vector2(p.x, p.z + MAST_DIST)
		_jib_angle = atan2(v.x, v.y)
		_trolley_r = clampf(v.length(), 1.5, JIB_FRONT - 0.5)
		target_len = maxf(0.4, (_jib_y - 0.3) - (held.top_y() + 0.45))

	_hook_len = target_len if not _inited else lerpf(_hook_len, target_len, 1.0 - exp(-HOOK_FOLLOW * delta))
	_inited = true

	# เสา: กล่อง 1 หน่วยยืดตามความสูง
	var mast_top := _jib_y - 0.3
	_mast.position = Vector3(0, (mast_top + MAST_BOTTOM) * 0.5, -MAST_DIST)
	_mast.scale = Vector3(1, mast_top - MAST_BOTTOM, 1)

	_pivot.position = Vector3(0, _jib_y, -MAST_DIST)
	_pivot.rotation.y = _jib_angle
	_trolley.position = Vector3(0, -0.3, _trolley_r)
	_cable.position = Vector3(0, -_hook_len * 0.5, 0)
	_cable.scale = Vector3(1, _hook_len, 1)
	_hook.position = Vector3(0, -_hook_len, 0)


func _mat(color: Color) -> Material:
	return Psx.material(color)


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi
