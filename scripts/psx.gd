class_name Psx
extends RefCounted

# ตัวช่วยสร้าง material สไตล์ PS1 (shaders/psx.gdshader) พร้อม cache ตามสี
# ทุก mesh ในเกมใช้ตัวนี้แทน StandardMaterial3D

const SHADER := preload("res://shaders/psx.gdshader")

static var _cache := {}
static var snap_enabled := true   # false = ปิด vertex snapping (Settings.retro_look) → ตั้ง snap_grid ละเอียดเกินกว่าจอ
const SNAP_OFF := Vector2(8192.0, 4608.0)


# material แชร์ตามสี (อย่าแก้ค่าบนตัวที่ได้จากนี่ ถ้าจะแก้ให้ duplicate() ก่อน)
# tex = texture สี (palette ของโมเดล .glb) คูณกับ color
static func material(color: Color, emission := Color.BLACK, emission_energy := 1.0, tex: Texture2D = null) -> ShaderMaterial:
	var key := [color, emission, emission_energy, tex]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("emission_color", emission)
	m.set_shader_parameter("emission_energy", emission_energy)
	if tex:
		m.set_shader_parameter("albedo_tex", tex)
	if not snap_enabled:
		m.set_shader_parameter("snap_grid", SNAP_OFF)
	_cache[key] = m
	return m


# เปิด/ปิด vertex snapping ของทุก material (ที่สร้างแล้วและที่จะสร้างต่อไป)
static func set_snap(enabled: bool) -> void:
	snap_enabled = enabled
	for m in _cache.values():
		if enabled:
			(m as ShaderMaterial).set_shader_parameter("snap_grid", Vector2(426.0, 240.0))   # ค่าเดียวกับ default ใน shaders/psx.gdshader
		else:
			(m as ShaderMaterial).set_shader_parameter("snap_grid", SNAP_OFF)


# แปลง material ที่ตั้งไว้ใน .tscn (StandardMaterial3D) เป็นสไตล์ PS1 ด้วยสีเดียวกัน
static func from_standard(m: Material) -> Material:
	var std := m as StandardMaterial3D
	if std == null:
		return m
	if std.emission_enabled:
		return material(std.albedo_color, std.emission, std.emission_energy_multiplier)
	return material(std.albedo_color)
