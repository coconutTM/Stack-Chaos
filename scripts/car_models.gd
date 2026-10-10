class_name CarModels
extends RefCounted

# โมเดลรถจาก assets/cars/*.glb (Cars Bundle) → รวมทุกชิ้นส่วน (ตัวถัง/ล้อ) เป็น ArrayMesh เดียว
# แปลง material เป็นสไตล์ PS1 (สีเดิม / ไฟหน้า-ไฟท้าย-ไซเรนเรืองแสง) และ cache ไว้ ใช้ได้ทั้งตัวบล็อก (Block) และฉากโรงขยะ (MultiMesh)

const SCENES: Array[PackedScene] = [
	preload("res://assets/cars/car_a.glb"),
	preload("res://assets/cars/car_b.glb"),
	preload("res://assets/cars/police.glb"),
	preload("res://assets/cars/sports_a.glb"),
	preload("res://assets/cars/sports_b.glb"),
	preload("res://assets/cars/suv.glb"),
	preload("res://assets/cars/taxi.glb"),
]

static var _cache := {}


static func count() -> int:
	return SCENES.size()


static func mesh(variant: int) -> ArrayMesh:
	if not _cache.has(variant):
		var parts := {}   # material → {verts, normals, indices} รวม surface ที่ material เดียวกันเป็นก้อนเดียว (ลด draw call)
		var root := SCENES[variant].instantiate()
		_collect(root, Transform3D.IDENTITY, parts)
		root.free()
		var out := ArrayMesh.new()
		for mat in parts:
			var p: Dictionary = parts[mat]
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = p.verts
			arrays[Mesh.ARRAY_NORMAL] = p.normals
			arrays[Mesh.ARRAY_INDEX] = p.indices
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			out.surface_set_material(out.get_surface_count() - 1, mat)
		_cache[variant] = out
	return _cache[variant]


# เดินทุก node ของโมเดล รวม surface ที่ material เดียวกัน (แปลงตำแหน่ง/หมุนของ node เข้าไปใน vertex เลย)
static func _collect(node: Node, parent_xf: Transform3D, parts: Dictionary) -> void:
	var xf := parent_xf
	if node is Node3D:
		xf = parent_xf * (node as Node3D).transform
	var mi := node as MeshInstance3D
	if mi and mi.mesh:
		for s in mi.mesh.get_surface_count():
			var mat := _psx(mi.mesh.surface_get_material(s))
			if not parts.has(mat):
				parts[mat] = {"verts": PackedVector3Array(), "normals": PackedVector3Array(), "indices": PackedInt32Array()}
			var p: Dictionary = parts[mat]
			var arrays := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var offset: int = p.verts.size()
			for i in verts.size():
				p.verts.append(xf * verts[i])
				p.normals.append((xf.basis * normals[i]).normalized())
			for idx in indices:
				p.indices.append(idx + offset)
	for child in node.get_children():
		_collect(child, xf, parts)


# สีเดิมของ material / ถ้าชื่อมีคำว่า "light" (Headlights, TailLights, BlueLights...) ให้เรืองแสงด้วยสีนั้น
static func _psx(m: Material) -> Material:
	var std := m as StandardMaterial3D
	if std == null:
		return Psx.material(Color(0.5, 0.5, 0.5))
	if std.resource_name.to_lower().contains("light"):
		return Psx.material(std.albedo_color, std.albedo_color, 1.4)
	return Psx.material(std.albedo_color)
