class_name Block
extends RigidBody3D

# ชนิดของบล็อก ⇄ ชื่อ scene ใน scenes/blocks/ (ดู Kind.SCENES)
enum Kind { CRATE, PLANK, FRIDGE, BARREL, TIRE, SQUARE, CYLINDER }
const KIND_COUNT := 7

# ความหนืดที่ทำให้บล็อกที่ชิดกัน "ติด" กันเล็กน้อยคล้ายสไลม์ (หน่วง relative velocity
# ของคู่ที่สัมผัสกันอยู่ ไม่ใช่แรงดึงดูดข้ามที่ว่าง) ยิ่งค่าสูง ยิ่งหนืด/กองง่ายขึ้น
const STICK_LINEAR := 3.0   # หน่วงการไถลระหว่างสองชิ้นที่แตะกัน
const STICK_ANGULAR := 0.5  # หน่วงการโยก/หมุนสัมพัทธ์ระหว่างสองชิ้นที่แตะกัน

const SCENES := {
	Kind.CRATE: preload("res://scenes/blocks/block_crate.tscn"),
	Kind.PLANK: preload("res://scenes/blocks/block_plank.tscn"),
	Kind.FRIDGE: preload("res://scenes/blocks/block_fridge.tscn"),
	Kind.BARREL: preload("res://scenes/blocks/block_barrel.tscn"),
	Kind.TIRE: preload("res://scenes/blocks/block_tire.tscn"),
	Kind.SQUARE: preload("res://scenes/blocks/block_square.tscn"),
	Kind.CYLINDER: preload("res://scenes/blocks/block_cylinder.tscn"),
}

var released := false   # ถูกปล่อยลงมาแล้วหรือยัง
var settled := false    # นิ่งแล้วหรือยัง
var _still_time := 0.0
var _mesh: MeshInstance3D


# สร้าง instance ของบล็อกชนิด kind จาก scene ที่สอดคล้องกัน
static func spawn(kind: int) -> Block:
	var blk: Block = SCENES[kind].instantiate()
	return blk


func _ready() -> void:
	_mesh = get_node("MeshInstance3D")

	# ตอนแรกให้ลอยค้างไว้ ให้ผู้เล่นเลื่อนด้วยเมาส์
	continuous_cd = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true

	# เปิดรายงานการสัมผัส ใช้หา neighbor สำหรับความหนืด (ดู _apply_stickiness)
	contact_monitor = true
	max_contacts_reported = 6


func release() -> void:
	released = true
	_still_time = 0.0
	freeze = false  # เริ่มให้ฟิสิกส์ทำงาน


# หยุดฟิสิกส์ของชิ้นนี้ค้างไว้ตรงนั้น (ใช้ตอนจบเกม ไม่ให้กลิ้งต่อ)
func freeze_in_place() -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true


# ความสูงของขอบบนสุดของบล็อกนี้ (คิดตามการหมุนจริง)
func top_y() -> float:
	return (_mesh.global_transform * _mesh.get_aabb()).end.y


# รัศมีรอยเท้าคร่าวๆ บนระนาบ XZ (ใช้ขนาดวงนำทางใต้ชิ้นที่ถือ)
func footprint_radius() -> float:
	var bb := _mesh.global_transform * _mesh.get_aabb()
	return maxf(bb.size.x, bb.size.z) * 0.5


func _physics_process(delta: float) -> void:
	if not released:
		return

	_apply_stickiness()

	if settled:
		return
	if linear_velocity.length() < 0.15 and angular_velocity.length() < 0.2:
		_still_time += delta
		if _still_time > 1.0:
			settled = true
	else:
		_still_time = 0.0


# ให้บล็อกที่สัมผัสกันอยู่ "หนืดติด" กันเล็กน้อย โดยหน่วง linear/angular velocity
# ที่ต่างกันระหว่างคู่ที่แตะกัน (ไม่ดึงข้ามที่ว่าง แตะกันก่อนถึงมีผล)
func _apply_stickiness() -> void:
	for body in get_colliding_bodies():
		var other := body as Block
		if other == null or not other.released:
			continue
		apply_central_force((other.linear_velocity - linear_velocity) * STICK_LINEAR)
		apply_torque((other.angular_velocity - angular_velocity) * STICK_ANGULAR)
