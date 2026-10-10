class_name Junkyard
extends Node3D

# ฉากโรงขยะรอบแท่นวาง: พื้นหลุมขยะลึกลงไป, กองขยะประดับ, รั้ว, เนินขยะไกลๆ, เสาไฟ
# ทั้งหมดจาก primitive (กล่อง/ทรงกระบอก 8 เหลี่ยม) ใช้ material PS1 / สุ่มด้วย seed คงที่ ให้หน้าตาเหมือนเดิมทุกครั้ง
# รวมชิ้นที่สีเดียวกันเป็น MultiMesh เดียว → draw call น้อย (สำคัญบนเว็บ)

const FLOOR_Y := -7.0         # พื้นหลุม (ต่ำกว่า KILL_Y ของเกม)
const SEED := 20260
const PALETTE: Array[Color] = [
	Color(0.34, 0.25, 0.18), Color(0.45, 0.36, 0.24), Color(0.26, 0.28, 0.30), Color(0.50, 0.28, 0.18),
	Color(0.20, 0.24, 0.22), Color(0.40, 0.41, 0.36), Color(0.26, 0.32, 0.42), Color(0.52, 0.47, 0.34),
]
const LAMP_COLOR := Color(1.0, 0.8, 0.5)
const FENCE_RADIUS := 21.0
const YARD_CARS := [0, 2, 6]   # โมเดลรถที่ใช้ประดับฉาก (car_a, police, taxi) — จำกัดไว้ลด draw call (แต่ละโมเดล ≈ 7 draw)

enum Shape { BOX, CYLINDER }

var _rng := RandomNumberGenerator.new()
var _groups := {}   # key → {shape, material, xforms}
var _car_groups := {}   # โมเดลรถ (variant) → รายการ transform (รวมเป็น MultiMesh ต่อโมเดล)
var _meshes := {}


func _ready() -> void:
	_rng.seed = SEED
	_build_floor()
	_build_rubble()
	_build_fence()
	_build_mounds()
	_build_lamps()
	_build_cars()
	_flush()


func _build_floor() -> void:
	_add(Shape.BOX, Psx.material(Color(0.3, 0.25, 0.21)), Transform3D(Basis.from_scale(Vector3(160, 0.5, 160)), Vector3(0, FLOOR_Y - 0.25, 0)))


# ขยะกระจายในหลุม (ในรั้ว) มีซ้อนกันบ้าง
func _build_rubble() -> void:
	for i in 130:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(6.5, FENCE_RADIUS - 1.5)
		var pos := Vector3(cos(a) * r, 0.0, sin(a) * r)
		if absf(pos.x) < 5.5 and absf(pos.z) < 5.5:
			continue   # ใต้แท่นวาง
		var size := Vector3(_rng.randf_range(0.5, 2.2), _rng.randf_range(0.4, 2.0), _rng.randf_range(0.5, 2.2))
		var shape := Shape.CYLINDER if _rng.randf() < 0.3 else Shape.BOX
		_add_piece(shape, pos, size, FLOOR_Y)
		if _rng.randf() < 0.35:
			var top := Vector3(pos.x + _rng.randf_range(-0.4, 0.4), 0.0, pos.z + _rng.randf_range(-0.4, 0.4))
			var s2 := size * _rng.randf_range(0.5, 0.9)
			_add_piece(Shape.BOX, top, s2, FLOOR_Y + size.y)


func _add_piece(shape: int, pos: Vector3, size: Vector3, base_y: float) -> void:
	var tilt := Vector3(_rng.randf_range(-0.15, 0.15), _rng.randf() * TAU, _rng.randf_range(-0.15, 0.15))
	var basis := Basis.from_euler(tilt) * Basis.from_scale(size)
	var color: Color = PALETTE[_rng.randi() % PALETTE.size()]
	_add(shape, Psx.material(color), Transform3D(basis, Vector3(pos.x, base_y + size.y * 0.5, pos.z)))


# รั้วเป็นวงรอบหลุม: แผ่นรั้ว + เสา / ขาดหายไปบางช่วง เอียงบ้าง ให้ดูทรุดโทรม
func _build_fence() -> void:
	var mat := Psx.material(Color(0.24, 0.24, 0.26))
	var sections := 36
	for i in sections:
		var a := TAU * i / sections
		var dir := Vector3(cos(a), 0.0, sin(a))
		var yaw := -a - PI * 0.5   # ให้แกน x ของกล่องขนานเส้นสัมผัสวง
		# เสา
		_add(Shape.BOX, mat, Transform3D(Basis.from_scale(Vector3(0.28, 5.0, 0.28)), dir * FENCE_RADIUS + Vector3(0, FLOOR_Y + 2.5, 0)))
		if _rng.randf() < 0.22:
			continue   # แผ่นรั้วหายไป
		var mid_a := a + TAU / sections * 0.5
		var mid := Vector3(cos(mid_a), 0.0, sin(mid_a)) * FENCE_RADIUS
		var lean := _rng.randf_range(-0.12, 0.12)
		var basis := Basis.from_euler(Vector3(0, yaw - TAU / sections * 0.5, lean)) * Basis.from_scale(Vector3(3.7, 3.4, 0.12))
		_add(Shape.BOX, mat, Transform3D(basis, mid + Vector3(0, FLOOR_Y + 2.0, 0)))


# เนินขยะใหญ่ๆ ไกลๆ นอกรั้ว เป็นเงามืดๆ ตรงขอบฉาก
func _build_mounds() -> void:
	for i in 18:
		var a := TAU * i / 18.0 + _rng.randf_range(-0.12, 0.12)
		var r := _rng.randf_range(27.0, 40.0)
		var center := Vector3(cos(a) * r, 0.0, sin(a) * r)
		for j in 9:
			var size := Vector3(_rng.randf_range(3.0, 7.0), _rng.randf_range(2.5, 6.0), _rng.randf_range(3.0, 7.0))
			var off := Vector3(_rng.randf_range(-4.0, 4.0), 0.0, _rng.randf_range(-4.0, 4.0))
			_add_piece(Shape.BOX, center + off, size, FLOOR_Y + _rng.randf_range(0.0, 4.0))


# เสาไฟสูง หัวโคมเรืองแสงสีส้ม (แค่ emissive ไม่ใช่ไฟจริง)
func _build_lamps() -> void:
	var pole_mat := Psx.material(Color(0.10, 0.10, 0.11))
	var lamp_mat := Psx.material(Color(0.2, 0.17, 0.1), LAMP_COLOR, 1.6)
	var count := 6
	for i in count:
		var a := TAU * i / count + 0.3
		var dir := Vector3(cos(a), 0.0, sin(a))
		var base := dir * 15.5
		var height := 16.0
		_add(Shape.CYLINDER, pole_mat, Transform3D(Basis.from_scale(Vector3(0.3, height, 0.3)), base + Vector3(0, FLOOR_Y + height * 0.5, 0)))
		var top_y := FLOOR_Y + height
		var inward := -dir
		var arm_basis := Basis.from_euler(Vector3(0, PI - a, 0)) * Basis.from_scale(Vector3(2.2, 0.2, 0.2))
		_add(Shape.BOX, pole_mat, Transform3D(arm_basis, base + inward * 1.1 + Vector3(0, top_y, 0)))
		_add(Shape.BOX, lamp_mat, Transform3D(Basis.from_scale(Vector3(0.8, 0.25, 0.8)), base + inward * 2.2 + Vector3(0, top_y - 0.2, 0)))


# ซากรถในหลุม: บางคันพลิกคว่ำ/เอียง บางคันซ้อนทับกัน (ไฟหน้า-ไฟท้ายเรืองแสงในความมืด)
func _build_cars() -> void:
	for i in 16:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(8.0, FENCE_RADIUS - 2.5)
		var pos := Vector3(cos(a) * r, FLOOR_Y, sin(a) * r)
		if absf(pos.x) < 6.5 and absf(pos.z) < 6.5:
			continue   # ใต้แท่นวาง
		var tilt := Vector3(_rng.randf_range(-0.12, 0.12), 0.0, _rng.randf_range(-0.12, 0.12))
		if _rng.randf() < 0.25:
			tilt.z = PI   # คว่ำหลังคา
			pos.y += 1.2
		var s := _rng.randf_range(0.9, 1.2)
		var basis := Basis.from_euler(Vector3(tilt.x, _rng.randf() * TAU, tilt.z)) * Basis.from_scale(Vector3(s, s, s))
		_add_car(YARD_CARS[_rng.randi() % YARD_CARS.size()], Transform3D(basis, pos))
		if _rng.randf() < 0.3:
			# ซ้อนอีกคันทับ
			var top := Basis.from_euler(Vector3(0.0, _rng.randf() * TAU, _rng.randf_range(-0.15, 0.15))) * Basis.from_scale(Vector3(s, s, s))
			_add_car(YARD_CARS[_rng.randi() % YARD_CARS.size()], Transform3D(top, pos + Vector3(_rng.randf_range(-0.5, 0.5), 1.15 * s, _rng.randf_range(-0.5, 0.5))))


func _add_car(variant: int, xform: Transform3D) -> void:
	if not _car_groups.has(variant):
		_car_groups[variant] = []
	_car_groups[variant].append(xform)


func _add(shape: int, material: Material, xform: Transform3D) -> void:
	var key := "%d:%d" % [shape, material.get_instance_id()]
	if not _groups.has(key):
		_groups[key] = {"shape": shape, "material": material, "xforms": []}
	_groups[key].xforms.append(xform)


func _flush() -> void:
	for key in _groups:
		var g: Dictionary = _groups[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _mesh_for(g.shape)
		mm.instance_count = g.xforms.size()
		for i in g.xforms.size():
			mm.set_instance_transform(i, g.xforms[i])
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = g.material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	_groups.clear()

	for variant in _car_groups:
		var xforms: Array = _car_groups[variant]
		var cars := MultiMesh.new()
		cars.transform_format = MultiMesh.TRANSFORM_3D
		cars.mesh = CarModels.mesh(variant)   # material PS1 ฝังอยู่ในแต่ละ surface แล้ว
		cars.instance_count = xforms.size()
		for i in xforms.size():
			cars.set_instance_transform(i, xforms[i])
		var cars_mi := MultiMeshInstance3D.new()
		cars_mi.multimesh = cars
		cars_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(cars_mi)
	_car_groups.clear()


func _mesh_for(shape: int) -> Mesh:
	if not _meshes.has(shape):
		if shape == Shape.BOX:
			var box := BoxMesh.new()
			box.size = Vector3.ONE
			_meshes[shape] = box
		else:
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.5
			cyl.bottom_radius = 0.5
			cyl.height = 1.0
			cyl.radial_segments = 8
			cyl.rings = 1
			_meshes[shape] = cyl
	return _meshes[shape]
