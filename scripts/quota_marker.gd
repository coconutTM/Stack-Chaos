class_name QuotaMarker
extends Node3D

# เส้นโควต้าในฉาก 3D: กรอบเรืองแสงรอบแท่นที่ความสูงโควต้า + ป้าย QUOTA
# main.gd เรียก set_quota() ต้นวัน และ update_progress() ทุกเฟรม (height / tower_top เป็นพิกัดโลก / ป้ายโชว์ค่าที่นับจากผิวแท่นเหมือน HUD)

const HALF := 4.5            # ครึ่งความกว้างกรอบ (เท่าครึ่งพื้นแท่น 9x9)
const THICK := 0.07
const YELLOW := Color(1.0, 0.85, 0.2, 0.85)
const GREEN := Color(0.4, 1.0, 0.45, 0.9)
const PULSE_SPEED := 9.0     # ความเร็วกะพริบตอนใกล้ถึงโควต้า

var _mat: StandardMaterial3D
var _label: Label3D
var _near := false
var _reached := false
var _quota := 0.0


func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = YELLOW
	for side in 4:
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		var along_x := side < 2
		box.size = Vector3(HALF * 2.0 + THICK, THICK, THICK) if along_x else Vector3(THICK, THICK, HALF * 2.0 + THICK)
		bar.mesh = box
		bar.material_override = _mat
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var s := 1.0 if side % 2 == 0 else -1.0
		bar.position = Vector3(0.0, 0.0, s * HALF) if along_x else Vector3(s * HALF, 0.0, 0.0)
		add_child(bar)

	_label = Label3D.new()
	_label.font = preload("res://fonts/pixel.ttf")
	_label.font_size = 32          # พหุคูณของ 8 ให้ฟอนต์ pixel คม
	_label.pixel_size = 0.02
	_label.outline_size = 8
	_label.outline_modulate = Color(0.02, 0.02, 0.04)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.shaded = false
	_label.no_depth_test = true    # มองเห็นแม้กองขยะบัง
	_label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	add_child(_label)
	visible = false


# ต้นวัน: ตั้งความสูงโควต้า (height = พิกัดโลก วางกรอบ / shown = ตัวเลขบนป้าย นับจากผิวแท่น)
func set_quota(height: float, shown: float) -> void:
	_quota = height
	position.y = height
	_label.text = "QUOTA %.1f m" % shown
	update_progress(0.0)


# ทุกเฟรม: เปลี่ยนสี/กะพริบตามความสูงกองตอนนี้
func update_progress(tower_top: float) -> void:
	_reached = tower_top >= _quota
	_near = not _reached and tower_top >= _quota - GameData.NEAR_QUOTA
	var color := GREEN if _reached else YELLOW
	if _near:
		color.a *= 0.5 + 0.5 * absf(sin(Time.get_ticks_msec() * 0.001 * PULSE_SPEED))
	_mat.albedo_color = color
	_label.modulate = Color(color.r, color.g, color.b, 1.0)
	_place_label()


# ป้ายอยู่ขอบกรอบฝั่งตรงข้ามกล้อง: ระยะจากกล้องคงที่ ตัวหนังสือขนาดเท่าเดิมทุกมุม และไม่ถูกขอบจอตัด
func _place_label() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var away := Vector3(-cam.global_position.x, 0.0, -cam.global_position.z)
	if away.length() < 0.01:
		return
	away = away / maxf(absf(away.x), absf(away.z))   # ฉายลงขอบสี่เหลี่ยม (|x| หรือ |z| = 1)
	_label.position = away * HALF + Vector3(0.0, 0.5, 0.0)
