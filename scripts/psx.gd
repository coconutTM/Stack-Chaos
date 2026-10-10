class_name Psx
extends RefCounted

# ตัวช่วยสร้าง material สไตล์ PS1 (shaders/psx.gdshader) พร้อม cache ตามสี
# ทุก mesh ในเกมใช้ตัวนี้แทน StandardMaterial3D

const SHADER := preload("res://shaders/psx.gdshader")

static var _cache := {}


# material แชร์ตามสี (อย่าแก้ค่าบนตัวที่ได้จากนี่ ถ้าจะแก้ให้ duplicate() ก่อน)
static func material(color: Color, emission := Color.BLACK, emission_energy := 1.0) -> ShaderMaterial:
	var key := [color, emission, emission_energy]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("emission_color", emission)
	m.set_shader_parameter("emission_energy", emission_energy)
	_cache[key] = m
	return m


# แปลง material ที่ตั้งไว้ใน .tscn (StandardMaterial3D) เป็นสไตล์ PS1 ด้วยสีเดียวกัน
static func from_standard(m: Material) -> Material:
	var std := m as StandardMaterial3D
	if std == null:
		return m
	if std.emission_enabled:
		return material(std.albedo_color, std.emission, std.emission_energy_multiplier)
	return material(std.albedo_color)
