class_name ModelLibrary
extends RefCounted

# โหลดโมเดล .glb → รวมทุกชิ้นส่วนเป็น ArrayMesh เดียว (รวม surface ที่ material เดียวกันเป็นก้อนเดียว ลด draw call)
# แปลง material เป็นสไตล์ PS1 (สีเดิม / vertex color / ชื่อมี "light" = เรืองแสง) และ cache ตาม path ของไฟล์
# ใช้ทั้งรถ (CarModels) บล็อกขยะ (BlockModels) และของประดับฉาก (Junkyard)
# texture สี (Kenney ใช้ palette เล็กๆ colormap.png) ส่งต่อให้ shader PS1 / tint = คูณสีทั้งโมเดล (เช่น ถังน้ำมันสีเขียว)

static var _cache := {}


static func mesh(scene: PackedScene, tint := Color.WHITE) -> ArrayMesh:
	var key := [scene.resource_path, tint]
	if not _cache.has(key):
		var parts := {}   # material → {verts, normals, colors, uvs, indices}
		var root := scene.instantiate()
		_collect(root, Transform3D.IDENTITY, parts, tint)
		root.free()
		var out := ArrayMesh.new()
		for mat in parts:
			var p: Dictionary = parts[mat]
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = p.verts
			arrays[Mesh.ARRAY_NORMAL] = p.normals
			arrays[Mesh.ARRAY_COLOR] = p.colors
			arrays[Mesh.ARRAY_TEX_UV] = p.uvs
			arrays[Mesh.ARRAY_INDEX] = p.indices
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			out.surface_set_material(out.get_surface_count() - 1, mat)
		_cache[key] = out
	return _cache[key]


# เดินทุก node ของโมเดล รวม surface ที่ material เดียวกัน (แปลงตำแหน่ง/หมุนของ node เข้าไปใน vertex เลย)
static func _collect(node: Node, parent_xf: Transform3D, parts: Dictionary, tint: Color) -> void:
	var xf := parent_xf
	if node is Node3D:
		xf = parent_xf * (node as Node3D).transform
	var mi := node as MeshInstance3D
	if mi and mi.mesh:
		for s in mi.mesh.get_surface_count():
			var src := mi.get_active_material(s)
			var mat := _psx(src, tint)
			if not parts.has(mat):
				parts[mat] = {"verts": PackedVector3Array(), "normals": PackedVector3Array(),
					"colors": PackedColorArray(), "uvs": PackedVector2Array(), "indices": PackedInt32Array()}
			var p: Dictionary = parts[mat]
			var arrays := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			# ใช้ vertex color เฉพาะเมื่อ material สั่งให้ใช้ ไม่งั้นเติมขาว (shader คูณ COLOR กับสี albedo)
			var colors: PackedColorArray = PackedColorArray()
			if _uses_vertex_color(src) and arrays[Mesh.ARRAY_COLOR] != null:
				colors = arrays[Mesh.ARRAY_COLOR]
			var uvs: PackedVector2Array = PackedVector2Array()
			if arrays[Mesh.ARRAY_TEX_UV] != null:
				uvs = arrays[Mesh.ARRAY_TEX_UV]
			var offset: int = p.verts.size()
			for i in verts.size():
				p.verts.append(xf * verts[i])
				p.normals.append((xf.basis * normals[i]).normalized() if i < normals.size() else Vector3.UP)
				p.colors.append(colors[i] if i < colors.size() else Color.WHITE)
				p.uvs.append(uvs[i] if i < uvs.size() else Vector2.ZERO)
			if indices.is_empty():
				for i in verts.size():   # mesh ที่ไม่มี index = ทุก 3 vertex คือ 1 สามเหลี่ยม
					p.indices.append(i + offset)
			else:
				for idx in indices:
					p.indices.append(idx + offset)
	for child in node.get_children():
		_collect(child, xf, parts, tint)


static func _uses_vertex_color(m: Material) -> bool:
	var std := m as BaseMaterial3D
	return std != null and std.vertex_color_use_as_albedo


# สีเดิมของ material / vertex color = albedo ขาวแล้วให้สีมาจาก vertex แทน
# ถ้าชื่อมีคำว่า "light" (Headlights, TailLights, BlueLights...) ให้เรืองแสงด้วยสีนั้น
static func _psx(m: Material, tint: Color) -> Material:
	var std := m as BaseMaterial3D
	if std == null:
		return Psx.material(Color(0.5, 0.5, 0.5) * tint)
	var color := (Color.WHITE if std.vertex_color_use_as_albedo else std.albedo_color) * tint
	color.a = 1.0
	if std.resource_name.to_lower().contains("light"):
		return Psx.material(color, color, 1.4, std.albedo_texture)
	return Psx.material(color, Color.BLACK, 1.0, std.albedo_texture)
