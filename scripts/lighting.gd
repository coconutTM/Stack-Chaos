class_name Lighting
extends Node3D

# ไฟ SpotLight3D ดวงเดียวส่องกองขยะ (ตามความสูงกอง) + ไฟกะพริบแบบสุ่ม
# ไม่เปิด shadow: shader แบบ vertex snapping จะทำให้เงาเพี้ยน และประหยัดบนเว็บ

const BASE_ENERGY := 6.0
const HEIGHT_ABOVE := 11.0     # ไฟอยู่เหนือยอดกองเท่านี้
const FOLLOW := 3.0
const LIGHT_COLOR := Color(1.0, 0.88, 0.66)

var target_y := 0.0            # main.gd ตั้งเป็น tower_top

var _spot: SpotLight3D
var _y := 0.0
var _clock := 0.0
var _next_burst := 4.0
var _burst_left := 0.0


func _ready() -> void:
	_spot = SpotLight3D.new()
	_spot.light_color = LIGHT_COLOR
	_spot.light_energy = BASE_ENERGY
	_spot.spot_range = 40.0
	_spot.spot_angle = 48.0
	_spot.spot_attenuation = 0.8
	_spot.rotation_degrees = Vector3(-90, 0, 0)   # ชี้ลงตรงๆ
	add_child(_spot)
	_apply_position()


func _process(delta: float) -> void:
	_y = lerpf(_y, target_y, 1.0 - exp(-FOLLOW * delta))
	_apply_position()

	_clock += delta
	# สั่นเบาๆ ตลอด + ไฟกะพริบแรงเป็นช่วงสั้นๆ ทุก 4-10 วินาที
	var energy := BASE_ENERGY * (0.96 + 0.04 * sin(_clock * 37.0))
	_next_burst -= delta
	if _next_burst <= 0.0:
		_burst_left = randf_range(0.15, 0.45)
		_next_burst = randf_range(4.0, 10.0)
	if _burst_left > 0.0:
		_burst_left -= delta
		energy *= 1.0 if randf() < 0.45 else randf_range(0.1, 0.5)
	_spot.light_energy = energy


func _apply_position() -> void:
	_spot.position = Vector3(0.0, _y + HEIGHT_ABOVE, 0.0)
