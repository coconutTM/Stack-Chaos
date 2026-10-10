class_name Block
extends RigidBody3D

# ชนิดของบล็อก ⇄ ชื่อ scene ใน scenes/blocks/ (ดู Kind.SCENES)
enum Kind { CRATE, PLANK, FRIDGE, BARREL, TIRE, SQUARE, CYLINDER, OIL_BARREL, TV, STEEL_CRATE, CAR,
	CARDBOARD_BOX, TRASH_BIN, BUCKET, TOILET, SOFA }
const KIND_COUNT := 16
const KIND_NAMES := ["CRATE", "PLANK", "FRIDGE", "BARREL", "TIRE", "WASHER", "PIPE", "OIL", "TV", "STEEL", "CAR",
	"BOX", "BIN", "BUCKET", "TOILET", "SOFA"]
const CAR_SCALE := 0.4   # รถจริงยาว ~4 ม. ย่อให้เหลือ ~1.6 ม. ให้ขนาดพอดีกับขยะชิ้นอื่น   # เรียงตาม Kind (ใช้โชว์ใน UI)

# ความหนืดที่ทำให้บล็อกที่ชิดกัน "ติด" กันเล็กน้อยคล้ายสไลม์ (หน่วง relative velocity
# ของคู่ที่สัมผัสกันอยู่ ไม่ใช่แรงดึงดูดข้ามที่ว่าง) ยิ่งค่าสูง ยิ่งหนืด/กองง่ายขึ้น
# หน่วย: อัตราต่อวินาที = สัดส่วนของ "ความเร็วสัมพัทธ์" ที่ถูกหน่วงทิ้งต่อวินาที (ยิ่งสูงยิ่งหนืด)
# ใช้ impulse แบบจำกัดสัดส่วนไม่เกิน 1 ต่อเฟรม → นิ่งแม้ชิ้นเบา/มวลต่างกันมาก (แบบแรงตรงๆ เคยระเบิดกอง)
const STICK_LINEAR := 12.0  # หน่วงการไถลระหว่างสองชิ้นที่แตะกัน
const STICK_ANGULAR := 6.0  # หน่วงการโยก/หมุนสัมพัทธ์ระหว่างสองชิ้นที่แตะกัน
const STICK_PULL := 6.0     # ความเร่งดูดเข้าหากัน (เมตร/วินาที²) เฉพาะตอนแตะกัน ช่วยดึงชิ้นที่ไถลกลับ

# พันธะยืดหยุ่นแบบเยลลี่: ชิ้นที่วางนิ่งชิดกันจะ "จำท่าพัก" ไว้ ถ้ากองเอียง/ถูกดันจนคลาดจากท่านั้นจะมีสปริงยืดแล้วดึงกลับแบบเด้งดึ๋ง
# ยืดเกินขีด = พันธะขาด (กองล้มได้จริง) / ทุกค่าเป็นความเร่ง (ม./วินาที²) คูณมวลลดรูปของคู่ → ชิ้นหนักเบาก็เสถียร
const BOND_STIFFNESS := 45.0         # ความแข็งสปริงเชิงเส้น (ต่อเมตรที่ยืด) ยิ่งสูงยิ่งดึงกลับแรง
const BOND_DAMPING := 3.5            # หน่วงความเร็วสัมพัทธ์ (ต่ำ = แกว่งหลายรอบ แบบเยลลี่)
const BOND_ANGULAR_STIFFNESS := 40.0 # ความแข็งสปริงการหมุน (ต่อเรเดียน)
const BOND_ANGULAR_DAMPING := 3.0
const BOND_MAX_ACCEL := 25.0         # เพดานความเร่งเชิงเส้นของสปริง (กันระเบิดตอนยืดมาก)
const BOND_MAX_ANGULAR_ACCEL := 25.0
const BOND_BREAK_DIST := 0.5         # ยืดเกินกี่เมตร = พันธะขาด
const BOND_BREAK_ANGLE := 0.6        # หมุนคลาดเกินกี่เรเดียน (~35°) = พันธะขาด
const BOND_CALM_TIME := 0.08         # สองชิ้นแตะกันและ "เกือบนิ่ง" ต่อเนื่องเท่านี้ (วินาที) ถึงเกิดพันธะ (สั้น = จับท่าตอนเพิ่งลงวาง ก่อนกองเริ่มเอียง)
const BOND_DEADZONE := 0.01          # คลาดน้อยกว่านี้ไม่ออกแรง → ชิ้นได้หลับ/นิ่ง (settled)

const SCENES := {
	Kind.CRATE: preload("res://scenes/blocks/block_crate.tscn"),
	Kind.PLANK: preload("res://scenes/blocks/block_plank.tscn"),
	Kind.FRIDGE: preload("res://scenes/blocks/block_fridge.tscn"),
	Kind.BARREL: preload("res://scenes/blocks/block_barrel.tscn"),
	Kind.TIRE: preload("res://scenes/blocks/block_tire.tscn"),
	Kind.SQUARE: preload("res://scenes/blocks/block_square.tscn"),
	Kind.CYLINDER: preload("res://scenes/blocks/block_cylinder.tscn"),
	Kind.OIL_BARREL: preload("res://scenes/blocks/block_oil_barrel.tscn"),
	Kind.TV: preload("res://scenes/blocks/block_tv.tscn"),
	Kind.STEEL_CRATE: preload("res://scenes/blocks/block_steel_crate.tscn"),
	Kind.CAR: preload("res://scenes/blocks/block_car.tscn"),
	Kind.CARDBOARD_BOX: preload("res://scenes/blocks/block_cardboard_box.tscn"),
	Kind.TRASH_BIN: preload("res://scenes/blocks/block_trash_bin.tscn"),
	Kind.BUCKET: preload("res://scenes/blocks/block_bucket.tscn"),
	Kind.TOILET: preload("res://scenes/blocks/block_toilet.tscn"),
	Kind.SOFA: preload("res://scenes/blocks/block_sofa.tscn"),
}

signal hit(impact: float)   # กระแทก (impact = ความเร็วก่อนชน x รากของมวล) main.gd เอาไปเล่นเสียง/สั่นจอ/ฝุ่น

const HIT_MIN := 2.5       # impact ต่ำกว่านี้ไม่ส่งสัญญาณ (ชิ้นที่วางนิ่งๆ แตะกัน) / ลังไม้ตกปกติ ≈ 7, ตู้เย็น ≈ 13, ลังเหล็ก ≈ 17
const HIT_COOLDOWN := 0.12

@export var fragile := false    # เปราะ: เสียชิ้นนี้ (หลุดขอบ/ตกพื้น/กองล้ม) = โดนไล่ออกทันที (ตั้งใน .tscn)
@export var slippery := false   # ลื่น (ใช้แสดงคำเตือน ค่าความลื่นจริงอยู่ที่ physics material ใน .tscn)
var kind := 0           # ชนิดของบล็อก (Kind) ตั้งโดย spawn()
var taped := false      # โดน Duct Tape ติดตายกับกองแล้ว
var weighted := false   # โดน Counterweight (มวล x3) แล้ว
var released := false   # ถูกปล่อยลงมาแล้วหรือยัง
var settled := false    # นิ่งแล้วหรือยัง
var _still_time := 0.0
var _prev_speed := 0.0
var _hit_cd := 0.0
var _mesh: MeshInstance3D
var _bonds := {}   # Block → {"off": Vector3, "rot": Basis} ท่าพักของอีกชิ้นเทียบกับชิ้นนี้ (พิกัดของชิ้นนี้)
var _calm := {}    # Block → วินาทีที่แตะกันและนิ่ง (ตัวเลือกที่จะเกิดพันธะ)


# สร้าง instance ของบล็อกชนิด which จาก scene ที่สอดคล้องกัน
static func spawn(which: int) -> Block:
	var blk: Block = SCENES[which].instantiate()
	blk.kind = which
	return blk


func _ready() -> void:
	_mesh = get_node("MeshInstance3D")
	if kind == Kind.CAR:
		_setup_car()
	else:
		_setup_model()
	# สีเดิมจาก scene แต่ใช้ shader PS1 (รวมชิ้นส่วนเสริม เช่น จอทีวี)
	for child in get_children():
		var mi := child as MeshInstance3D
		if mi:
			mi.material_override = Psx.from_standard(mi.material_override)

	# ตอนแรกให้ลอยค้างไว้ ให้ผู้เล่นเลื่อนด้วยเมาส์
	continuous_cd = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true

	# เปิดรายงานการสัมผัส ใช้หา neighbor สำหรับความหนืด (ดู _apply_stickiness)
	contact_monitor = true
	max_contacts_reported = 6
	body_entered.connect(_on_body_entered)


func release() -> void:
	released = true
	_still_time = 0.0
	freeze = false  # เริ่มให้ฟิสิกส์ทำงาน
	# ตอนถือ (kinematic) Jolt คำนวณความเร็วจากการขยับตำแหน่งของเฟรมก่อนๆ (เมาส์สะบัดแรง/เทเลพอร์ต = ความเร็วปลอมหลายสิบ-ร้อย m/s)
	# ซึ่งบางครั้งไหลเข้ามาตอนเปลี่ยนเป็น dynamic หลังจากที่เราล้างไปแล้ว จึงล้างซ้ำตามหลังอีก 2 physics frame
	_clear_velocity()
	await get_tree().physics_frame
	_clear_velocity()
	await get_tree().physics_frame
	_clear_velocity()


func _clear_velocity() -> void:
	if is_inside_tree() and not freeze:
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		_prev_speed = 0.0


# หยุดฟิสิกส์ของชิ้นนี้ค้างไว้ตรงนั้น (ใช้ตอนจบเกม ไม่ให้กลิ้งต่อ)
func freeze_in_place() -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true


# ความสูงของขอบบนสุดของบล็อกนี้ (คิดตามการหมุนจริง)
func top_y() -> float:
	return (_mesh.global_transform * _mesh.get_aabb()).end.y


# ชิ้นนี้วางอยู่บนพื้นไหม (ขอบล่างสุดของ mesh ติดระดับผิวพื้น) / ใช้เรขาคณิตแทน get_colliding_bodies()
# เพราะบอดี้ที่นิ่งแล้วจะหลับ (sleep) และ Jolt ไม่รายงาน contact ให้ตอนหลับ
func rests_on_ground(ground_top: float, tolerance := 0.12) -> bool:
	var bb := _mesh.global_transform * _mesh.get_aabb()
	return bb.position.y <= ground_top + tolerance


# Item: Counterweight — ชิ้นนี้หนักขึ้น mult เท่า (inertia คำนวณใหม่เองตามมวล) + เรืองสีส้มให้เห็น
func add_counterweight(mult := 3.0) -> void:
	if weighted:
		return
	weighted = true
	mass *= mult
	_glow(Color(0.85, 0.35, 0.0))


# Item: Duct Tape — เชื่อมชิ้นนี้ติดตายกับทุกชิ้นที่แตะอยู่ (และกับพื้นถ้าแตะพื้น) ด้วย joint ที่ล็อกทุกแกน
func weld() -> void:
	if taped:
		return
	taped = true
	# บอดี้ที่นิ่งแล้วหลับอยู่ ไม่มี contact → ปลุกแล้วรอให้ฟิสิกส์รายงาน contact ก่อน
	sleeping = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return   # ถูกลบระหว่างรอ (เช่นหลุดขอบ)
	var joints := 0
	var touches_world := false
	for body in get_colliding_bodies():
		var other := body as Block
		if other == null:
			touches_world = true   # ไม่ใช่บล็อก = พื้น
		elif other.released:
			_add_weld_joint(other)
			joints += 1
	if touches_world:
		_add_weld_joint(null)
		joints += 1
	if joints == 0:
		freeze_in_place()   # ไม่เจออะไรให้เชื่อมเลย (ไม่น่าเกิด) อย่างน้อยก็ปักไว้กับที่
	_add_tape_band()


# joint ล็อกทุกแกนที่ตำแหน่งชิ้นนี้ / other = null คือยึดกับโลก / ใส่ไว้ที่ parent ไม่ใช่ลูกของ body
# (joint ของ Jolt ไม่ตามตำแหน่ง node ที่ขยับหลังสร้าง)
func _add_weld_joint(other: Block) -> void:
	var j := Generic6DOFJoint3D.new()
	get_parent().add_child(j)
	j.global_position = global_position
	j.node_a = j.get_path_to(self)
	if other != null:
		j.node_b = j.get_path_to(other)
	for axis in ["x", "y", "z"]:
		j.call("set_flag_" + axis, Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		j.call("set_param_" + axis, Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
		j.call("set_param_" + axis, Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
		j.call("set_flag_" + axis, Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
		j.call("set_param_" + axis, Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
		j.call("set_param_" + axis, Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)


# แถบเทปสีเงินรอบกลางชิ้น (ให้เห็นว่าติดเทปแล้ว)
func _add_tape_band() -> void:
	var bb := _mesh.transform * _mesh.get_aabb()   # ขนาดในพิกัดของบล็อก (คิดสเกล/หมุนของโมเดลแล้ว)
	var band := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(bb.size.x + 0.06, maxf(0.1, bb.size.y * 0.14), bb.size.z + 0.06)
	band.mesh = box
	band.material_override = Psx.material(Color(0.78, 0.78, 0.8))
	band.position = bb.get_center()
	add_child(band)


# เปลี่ยนสี emission ของชิ้นนี้ (copy material ก่อน เพราะ material ใน scene แชร์กันทุก instance)
func _glow(color: Color) -> void:
	var m := _mesh.material_override as ShaderMaterial
	if m == null:
		# โมเดลหลาย material (รถ): ใช้ชั้นโปร่งแสงสีนั้นทับแทน
		var overlay := StandardMaterial3D.new()
		overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		overlay.albedo_color = Color(color, 0.28)
		_mesh.material_overlay = overlay
		return
	m = m.duplicate()
	m.set_shader_parameter("emission_color", color)
	m.set_shader_parameter("emission_energy", 0.7)
	_mesh.material_override = m


# รัศมีรอยเท้าคร่าวๆ บนระนาบ XZ (ใช้ขนาดวงนำทางใต้ชิ้นที่ถือ)
func footprint_radius() -> float:
	var bb := _mesh.global_transform * _mesh.get_aabb()
	return maxf(bb.size.x, bb.size.z) * 0.5


# รถ: สุ่มโมเดลจาก CarModels แล้วย่อขนาด / ตั้งกล่องชนให้พอดีโมเดล และย้ายโมเดลให้ศูนย์กลางอยู่ที่ origin ของบล็อก
func _setup_car() -> void:
	_mesh.mesh = CarModels.mesh(randi() % CarModels.count())
	_mesh.scale = Vector3.ONE * CAR_SCALE
	var bb := _mesh.mesh.get_aabb()
	_mesh.position = -bb.get_center() * CAR_SCALE
	var box := BoxShape3D.new()
	box.size = bb.size * CAR_SCALE
	(get_node("CollisionShape3D") as CollisionShape3D).shape = box


# โมเดล .glb ของชนิดนี้ (ถ้ามีไฟล์ ดู BlockModels) แทน primitive เดิม / กล่องชนยังเป็นของเดิมจาก .tscn
# หมุนตาม rot → ย่อขยายให้ AABB พอดีขนาดกล่องชน → ย้ายศูนย์กลางไปที่ origin / ซ่อน mesh อื่นของ scene (เช่น จอทีวี)
func _setup_model() -> void:
	var path := BlockModels.path(kind)
	if path == "":
		return
	var target := _shape_size()
	if target == Vector3.ZERO:
		return
	_mesh.mesh = ModelLibrary.mesh(load(path), BlockModels.tint(kind))
	_mesh.material_override = null   # material PS1 ฝังอยู่ในแต่ละ surface แล้ว
	var rot := BlockModels.rotation(kind)
	var turn := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
	var bb := Transform3D(turn, Vector3.ZERO) * _mesh.mesh.get_aabb()
	var s := target / bb.size.max(Vector3.ONE * 0.001)
	if BlockModels.keep_ratio(kind):
		s = Vector3.ONE * minf(s.x, minf(s.y, s.z))
	_mesh.transform = Transform3D(Basis.from_scale(s) * turn, -bb.get_center() * s)
	for child in get_children():
		if child is MeshInstance3D and child != _mesh:
			(child as MeshInstance3D).visible = false


# ขนาดกล่องชนจาก .tscn (กว้าง x สูง x ลึก)
func _shape_size() -> Vector3:
	var shape := (get_node("CollisionShape3D") as CollisionShape3D).shape
	if shape is BoxShape3D:
		return (shape as BoxShape3D).size
	if shape is CylinderShape3D:
		var c := shape as CylinderShape3D
		return Vector3(c.radius * 2.0, c.height, c.radius * 2.0)
	return Vector3.ZERO


# ชนแรงไหม: ใช้ความเร็ว "ก่อนชน" (เฟรมก่อนหน้า) เพราะตอนสัญญาณมาความเร็วถูกฟิสิกส์ลดไปแล้ว
func _on_body_entered(_body: Node) -> void:
	if not released or _hit_cd > 0.0:
		return
	var impact := _prev_speed * sqrt(mass)
	if impact >= HIT_MIN:
		_hit_cd = HIT_COOLDOWN
		hit.emit(impact)


func _physics_process(delta: float) -> void:
	if not released:
		return

	_hit_cd = maxf(0.0, _hit_cd - delta)
	_apply_stickiness(delta)
	_update_bonds(delta)
	_prev_speed = linear_velocity.length()

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


# ---------- พันธะเยลลี่ ----------

func _is_calm() -> bool:
	return linear_velocity.length() < 0.5 and angular_velocity.length() < 1.0


# 1) ชิ้นที่แตะกันและนิ่งพอ → เกิดพันธะ (สองฝั่งพร้อมกัน) 2) พันธะที่มีอยู่ → สปริงดึงกลับท่าพัก / ยืดเกิน = ขาด
func _update_bonds(delta: float) -> void:
	if taped or freeze:
		return
	if _is_calm():
		for body in get_colliding_bodies():
			var other := body as Block
			if other == null or not other.released or other.taped or other.freeze or _bonds.has(other) or not other._is_calm():
				continue
			_calm[other] = float(_calm.get(other, 0.0)) + delta
			# ฝั่งที่ id ต่ำกว่าเป็นคนสร้าง (กันสร้างซ้ำสองรอบ)
			if _calm[other] >= BOND_CALM_TIME and get_instance_id() < other.get_instance_id():
				_make_bond(other)
	elif not _calm.is_empty():
		_calm.clear()

	for other in _bonds.keys():
		if not is_instance_valid(other) or other.is_queued_for_deletion() or other.taped or other.freeze:
			_bonds.erase(other)
			continue
		_pull_bond(other, _bonds[other])


# จำท่าพักของคู่นี้ (ทั้งสองฝั่ง) ณ ตอนนี้
func _make_bond(other: Block) -> void:
	var inv := global_transform.basis.orthonormalized().inverse()
	var b := other.global_transform.basis.orthonormalized()
	_bonds[other] = {"off": inv * (other.global_position - global_position), "rot": inv * b}
	var other_inv := b.inverse()
	other._bonds[self] = {"off": other_inv * (global_position - other.global_position), "rot": other_inv * global_transform.basis.orthonormalized()}
	_calm.erase(other)
	other._calm.erase(self)


# สปริงของพันธะเดียว (ฝั่งตัวเอง: อีกฝั่งรันของมันเองแล้วได้แรงตรงข้าม → โมเมนตัมรวมคงที่)
func _pull_bond(other: Block, bond: Dictionary) -> void:
	var my_basis := global_transform.basis.orthonormalized()
	var err := (other.global_position - global_position) - my_basis * (bond.off as Vector3)

	# ความคลาดของการหมุน: other ต้องหมุนด้วย R ถึงจะกลับท่าพัก (R = ท่าที่ต้องการ x ท่าจริง⁻¹)
	var want := my_basis * (bond.rot as Basis)
	var q := (want * other.global_transform.basis.orthonormalized().inverse()).get_rotation_quaternion()
	if q.w < 0.0:
		q = -q   # เลือกทางหมุนที่สั้นกว่า
	var angle := 2.0 * acos(clampf(q.w, -1.0, 1.0))
	var axis := Vector3.ZERO
	if angle > 0.0001:
		axis = Vector3(q.x, q.y, q.z).normalized()

	if err.length() > BOND_BREAK_DIST or angle > BOND_BREAK_ANGLE:
		_bonds.erase(other)   # ขาด (อีกฝั่งจะขาดเองเฟรมนี้/เฟรมหน้า เพราะวัดคลาดเท่ากัน)
		other._bonds.erase(self)
		return
	if err.length() < BOND_DEADZONE and angle < 0.02:
		return

	var mu := mass * other.mass / (mass + other.mass)
	var accel := err * BOND_STIFFNESS + (other.linear_velocity - linear_velocity) * BOND_DAMPING
	apply_central_force(mu * accel.limit_length(BOND_MAX_ACCEL))

	# หมุน: ฝั่งตัวเองรับครึ่งหนึ่งของความเร่งสัมพัทธ์ ทิศตรงข้ามกับ other
	var rel_w := other.angular_velocity - angular_velocity
	var alpha := (axis * angle * BOND_ANGULAR_STIFFNESS - rel_w * BOND_ANGULAR_DAMPING).limit_length(BOND_MAX_ANGULAR_ACCEL)
	var inv_i := PhysicsServer3D.body_get_direct_state(get_rid()).inverse_inertia_tensor
	apply_torque(inv_i.inverse() * (-alpha * 0.5))
