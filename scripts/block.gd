class_name Block
extends RigidBody3D

# ชนิดของบล็อก ⇄ ชื่อ scene ใน scenes/blocks/ (ดู Kind.SCENES)
enum Kind { CRATE, PLANK, FRIDGE, BARREL, TIRE, SQUARE, CYLINDER }
const KIND_COUNT := 7

# ความหนืดที่ทำให้บล็อกที่ชิดกัน "ติด" กันเล็กน้อยคล้ายสไลม์ (หน่วง relative velocity
# ของคู่ที่สัมผัสกันอยู่ ไม่ใช่แรงดึงดูดข้ามที่ว่าง) ยิ่งค่าสูง ยิ่งหนืด/กองง่ายขึ้น
# หน่วย: อัตราต่อวินาที = สัดส่วนของ "ความเร็วสัมพัทธ์" ที่ถูกหน่วงทิ้งต่อวินาที (ยิ่งสูงยิ่งหนืด)
# ใช้ impulse แบบจำกัดสัดส่วนไม่เกิน 1 ต่อเฟรม → นิ่งแม้ชิ้นเบา/มวลต่างกันมาก (แบบแรงตรงๆ เคยระเบิดกอง)
const STICK_LINEAR := 12.0  # หน่วงการไถลระหว่างสองชิ้นที่แตะกัน
const STICK_ANGULAR := 6.0  # หน่วงการโยก/หมุนสัมพัทธ์ระหว่างสองชิ้นที่แตะกัน
const STICK_PULL := 6.0     # ความเร่งดูดเข้าหากัน (เมตร/วินาที²) เฉพาะตอนแตะกัน ช่วยดึงชิ้นที่ไถลกลับ

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
	# ตอนถูก freeze (kinematic) ความเร็วที่ค้างอยู่มาจากการขยับ/เทเลพอร์ตตำแหน่ง ไม่ใช่ความเร็วจริง
	# ถ้าไม่ล้างตอนปล่อย ชิ้นจะพุ่งทะยานเหมือนถูกยิง (เคยเจอตอนปล่อยทันทีหลัง spawn)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
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

	_apply_stickiness(delta)

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
func _apply_stickiness(delta: float) -> void:
	var f := clampf(STICK_LINEAR * delta, 0.0, 0.5)
	var fa := clampf(STICK_ANGULAR * delta, 0.0, 0.5)
	for body in get_colliding_bodies():
		var other := body as Block
		if other == null or not other.released:
			continue
		# สองฝั่งรันแยกกัน แต่ละฝั่งใช้ impulse ตามมวลลดรูป (reduced mass) ผลคือโมเมนตัมรวมคงที่
		# และความเร็วสัมพัทธ์ลดลงสัดส่วน f ต่อเฟรม โดยไม่ขึ้นกับว่าชิ้นหนักหรือเบา
		var mu := mass * other.mass / (mass + other.mass)
		apply_central_impulse((other.linear_velocity - linear_velocity) * mu * f)

		# หมุน: ใช้ inertia ของตัวเองครึ่งหนึ่งต่อฝั่ง (คร่าวๆ แต่จำกัดสัดส่วนจึงไม่เสถียรไม่ได้)
		var inv_i := PhysicsServer3D.body_get_direct_state(get_rid()).inverse_inertia_tensor
		apply_torque_impulse(inv_i.inverse() * ((other.angular_velocity - angular_velocity) * fa * 0.5))

		# ดูดเข้าหาจุดกึ่งกลางของอีกชิ้นด้วยความเร็วเล็กน้อย (equal & opposite ตามมวลลดรูป)
		var to_other := other.global_position - global_position
		if to_other.length_squared() > 0.0001:
			apply_central_impulse(to_other.normalized() * mu * STICK_PULL * delta)
