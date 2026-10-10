class_name DropGuide
extends Node3D

# เส้นนำทาง + วงเงาใต้ชิ้นที่ถือ: ยิง ray ลงไปหาจุดที่จะตก ให้เล็งง่ายจากทุกมุมกล้อง
# main.gd ตั้ง target ทุกเฟรม (null = ซ่อนทั้งหมด)

const RAY_LENGTH := 60.0
const MISS_LINE := 4.0   # ไม่เจออะไรข้างล่าง (จะตกเหว) = เส้นแดงสั้นๆ เตือน

var target: Block
var ground_is_fail := false   # true = ตกลงพื้นแล้วนับว่าเสียชิ้น (main.gd ตั้งเมื่อมีกองแล้ว) → วงเป็นสีแดง

var _disc: MeshInstance3D
var _line: MeshInstance3D
var _white := _mat(Color(1, 1, 1, 0.35))
var _red := _mat(Color(1, 0.2, 0.2, 0.6))


func _ready() -> void:
	_disc = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.02
	cyl.radial_segments = 16
	_disc.mesh = cyl
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_disc)

	_line = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.04, 1.0, 0.04)
	_line.mesh = box
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)
	visible = false


func _physics_process(_delta: float) -> void:
	if target == null or not is_instance_valid(target) or target.released:
		visible = false
		return

	var from := target.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * RAY_LENGTH)
	query.exclude = [target.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)

	visible = true
	var bottom_y: float
	if hit.is_empty():
		bottom_y = from.y - MISS_LINE
		_disc.visible = false
		_line.material_override = _red
	else:
		var p: Vector3 = hit.position
		bottom_y = p.y
		var r := target.footprint_radius()
		_disc.visible = true
		_disc.global_position = Vector3(p.x, p.y + 0.03, p.z)
		_disc.scale = Vector3(r, 1.0, r)
		var bad := ground_is_fail and not (hit.collider is Block)
		_disc.material_override = _red if bad else _white
		_line.material_override = _red if bad else _white

	var line_len := maxf(0.01, from.y - bottom_y)
	_line.global_position = Vector3(from.x, bottom_y + line_len * 0.5, from.z)
	_line.scale = Vector3(1, line_len, 1)


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
