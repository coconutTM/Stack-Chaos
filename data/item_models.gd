class_name ItemModels
extends RefCounted

# โมเดล 3D ของ item แต่ละชนิด (primitive ประกอบด้วยโค้ด สไตล์เดียวกับเครน) ใช้ "อบ" เป็นไอคอน pixel ด้วย tools/bake_icons.gd
# เกมไม่ได้เรนเดอร์โมเดลนี้ตอนรัน — โหลดไอคอนจาก assets/icons/<id>.png (ดู ItemData.icon())
# ถ้าวาง assets/models/items/<id>.glb ไว้ จะใช้ไฟล์นั้นแทน primitive (รันอบไอคอนใหม่) / ขนาดโมเดลให้อยู่ในกล่องประมาณ ±0.6 รอบจุดกำเนิด

const GLB_DIR := "res://assets/models/items/"


# สร้างโมเดลของ item id (คืน Node3D ใหม่ทุกครั้ง)
static func build(id: String) -> Node3D:
	var path := GLB_DIR + id + ".glb"
	if ResourceLoader.exists(path):
		var mi := MeshInstance3D.new()
		mi.mesh = ModelLibrary.mesh(load(path) as PackedScene)
		var root := Node3D.new()
		root.add_child(mi)
		return root
	var root := Node3D.new()
	match id:
		"duct_tape": _duct_tape(root)
		"coffee": _coffee(root)
		"swap_bag": _swap_bag(root)
		"counterweight": _counterweight(root)
		"clipboard": _clipboard(root)
		"insurance": _insurance(root)
		_: _box(root, Vector3(0.8, 0.8, 0.8), Vector3.ZERO, Color(0.8, 0.2, 0.8))   # id ไม่รู้จัก = กล่องสีม่วง
	return root


# ม้วนเทป: ม้วนเงิน + แกนกระดาษ + หางเทปห้อย
static func _duct_tape(root: Node3D) -> void:
	var roll := Node3D.new()
	roll.rotation_degrees = Vector3(90, 0, 0)   # แกนม้วนหันเข้าหากล้อง
	root.add_child(roll)
	_cyl(roll, 0.5, 0.5, 0.36, Vector3.ZERO, Color(0.72, 0.73, 0.78))
	_cyl(roll, 0.22, 0.22, 0.4, Vector3.ZERO, Color(0.42, 0.28, 0.14))
	_box(root, Vector3(0.32, 0.03, 0.34), Vector3(0.45, -0.5, 0.05), Color(0.72, 0.73, 0.78), Vector3(0, 0, -20))


# แก้วกาแฟ: ตัวแก้วสอบลง + น้ำกาแฟ + หูจับ + ไอน้ำ
static func _coffee(root: Node3D) -> void:
	_cyl(root, 0.4, 0.3, 0.7, Vector3(0, -0.1, 0), Color(0.9, 0.86, 0.8))
	_cyl(root, 0.35, 0.35, 0.03, Vector3(0, 0.25, 0), Color(0.3, 0.17, 0.08))
	_cyl(root, 0.3, 0.3, 0.12, Vector3(0, -0.08, 0), Color(0.7, 0.45, 0.25))   # แถบสีรอบแก้ว
	var handle := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.24
	torus.rings = 8
	torus.ring_segments = 6
	handle.mesh = torus
	handle.material_override = Psx.material(Color(0.9, 0.86, 0.8))
	handle.rotation_degrees = Vector3(90, 0, 0)
	handle.position = Vector3(0.47, -0.08, 0)
	root.add_child(handle)
	_box(root, Vector3(0.07, 0.25, 0.07), Vector3(-0.1, 0.5, 0), Color(0.9, 0.9, 0.95), Vector3(0, 0, 8))
	_box(root, Vector3(0.07, 0.2, 0.07), Vector3(0.12, 0.55, 0), Color(0.9, 0.9, 0.95), Vector3(0, 0, -8))


# ถุงสลับ: ถุงกลมๆ + คอถุง + ปม
static func _swap_bag(root: Node3D) -> void:
	var blue := Color(0.4, 0.7, 0.9)
	var body := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 0.95
	sphere.radial_segments = 8
	sphere.rings = 5
	body.mesh = sphere
	body.material_override = Psx.material(blue)
	body.position = Vector3(0, -0.12, 0)
	root.add_child(body)
	_cyl(root, 0.1, 0.2, 0.28, Vector3(0, 0.4, 0), blue)
	_box(root, Vector3(0.34, 0.1, 0.1), Vector3(0, 0.6, 0), blue, Vector3(0, 0, 14))
	_box(root, Vector3(0.12, 0.3, 0.1), Vector3(0.1, 0.68, 0), blue, Vector3(0, 0, -25))
	_box(root, Vector3(0.12, 0.3, 0.1), Vector3(-0.1, 0.68, 0), blue, Vector3(0, 0, 25))


# ตุ้มน้ำหนัก: ทรงคางหมู 4 เหลี่ยม + ห่วงด้านบน
static func _counterweight(root: Node3D) -> void:
	var orange := Color(0.9, 0.5, 0.15)
	_cyl(root, 0.32, 0.6, 0.75, Vector3(0, -0.1, 0), orange, Vector3(0, 45, 0), 4)
	_cyl(root, 0.4, 0.4, 0.08, Vector3(0, -0.5, 0), Color(0.25, 0.25, 0.28), Vector3(0, 45, 0), 4)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.2
	torus.rings = 8
	torus.ring_segments = 6
	ring.mesh = torus
	ring.material_override = Psx.material(Color(0.7, 0.7, 0.72))
	ring.position = Vector3(0, 0.38, 0)
	root.add_child(ring)


# คลิปบอร์ด: แผ่นไม้ + กระดาษ + เส้นข้อความ + คลิปเหล็ก
static func _clipboard(root: Node3D) -> void:
	var tilt := Vector3(0, 0, 0)
	_box(root, Vector3(0.8, 1.05, 0.08), Vector3(0, 0, 0), Color(0.55, 0.38, 0.2), tilt)
	_box(root, Vector3(0.64, 0.86, 0.03), Vector3(0, -0.04, 0.05), Color(0.95, 0.93, 0.85), tilt)
	for i in 4:
		_box(root, Vector3(0.46 - 0.08 * (i % 2), 0.04, 0.02), Vector3(-0.02 * (i % 2), 0.14 - i * 0.17, 0.075), Color(0.25, 0.25, 0.3), tilt)
	_box(root, Vector3(0.36, 0.16, 0.1), Vector3(0, 0.5, 0.05), Color(0.7, 0.7, 0.75), tilt)


# ประกัน: แฟ้มเอกสารสีเขียว + แท็บ + ตราประทับแดง
static func _insurance(root: Node3D) -> void:
	var green := Color(0.35, 0.75, 0.4)
	_box(root, Vector3(0.95, 0.72, 0.14), Vector3(0, -0.05, 0), green)
	_box(root, Vector3(0.38, 0.12, 0.14), Vector3(-0.28, 0.37, 0), green)
	_box(root, Vector3(0.8, 0.5, 0.02), Vector3(0, -0.02, 0.08), Color(0.95, 0.93, 0.85))
	_cyl(root, 0.17, 0.17, 0.04, Vector3(0.22, -0.1, 0.12), Color(0.8, 0.15, 0.12), Vector3(90, 0, 0))


# ---------- ตัวช่วยสร้าง primitive (ใช้ Psx.material เหมือนทุก mesh ในเกม) ----------

static func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = Psx.material(color)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


# segments = 0 ใช้ค่าเริ่มต้น 8 (ตามที่เกมใช้กับกระบอกทั้งหมด)
static func _cyl(parent: Node3D, top_r: float, bottom_r: float, height: float, pos: Vector3, color: Color,
		rot_deg := Vector3.ZERO, segments := 8) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = 8 if segments <= 0 else segments
	mesh.rings = 1
	mi.mesh = mesh
	mi.material_override = Psx.material(color)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi
