class_name DayModifiers
extends Node

# ตัวปรับของวัน: wind (ลมเป็นระยะ มีสัญญาณเตือน), rain (เสียดทานต่ำ + ฝนตก), shake (พื้นสั่นเป็นช่วง)
# ค่าจูนอยู่ใน GameData.MODIFIERS / วันไหนใช้ตัวไหนอยู่ใน GameData.DAYS[i].modifiers
# main.gd เรียก start()/stop() ตอนต้น/จบวัน และตั้ง running / follow_y ทุกเฟรม

enum Phase { IDLE, WARN, ACTIVE }

var _physics: PhysicsMaterial = load("res://resources/block_physics.tres")   # แชร์กับทุกบล็อก (ResourceLoader cache)

var blocks_root: Node3D
var camera: OrbitCamera
var running := false      # true เฉพาะตอนกำลังเล่น (HOLDING/WAITING) ตอน boss พูดหยุดนับเวลา
var follow_y := 0.0       # ความสูงกอง (ให้ฝนตามขึ้นไป)

var _mods: Array = []
var _original_friction := -1.0
var _rain: CPUParticles3D

# สถานะเป็นรายตัวปรับ: {phase, left}
var _wind := {"phase": Phase.IDLE, "left": 0.0, "dir": Vector3.RIGHT}
var _shake := {"phase": Phase.IDLE, "left": 0.0}
var _clock := 0.0


func start(mods: Array) -> void:
	stop()
	_mods = mods
	if _mods.has("wind"):
		_wind = {"phase": Phase.IDLE, "left": _random_interval("wind"), "dir": Vector3.RIGHT}
	if _mods.has("shake"):
		_shake = {"phase": Phase.IDLE, "left": _random_interval("shake")}
	if _mods.has("rain"):
		_original_friction = _physics.friction
		_physics.friction = float(GameData.MODIFIERS.rain.friction)
		_start_rain()


# ล้างทุกอย่างกลับเป็นปกติ (เรียกตอนจบวัน/กลับ title ด้วย)
func stop() -> void:
	_mods = []
	_wind = {"phase": Phase.IDLE, "left": 0.0, "dir": Vector3.RIGHT}
	_shake = {"phase": Phase.IDLE, "left": 0.0}
	if _original_friction >= 0.0:
		_physics.friction = _original_friction   # คืนค่าเสียดทาน (resource ถูกแชร์ทั้งเกม)
		_original_friction = -1.0
	if _rain:
		_rain.queue_free()
		_rain = null


func _exit_tree() -> void:
	stop()


# ข้อความป้ายวันนี้ เช่น "WIND + RAIN" (ว่าง = ไม่มี)
func label_text() -> String:
	var names: Array[String] = []
	for m in _mods:
		names.append(GameData.MODIFIERS[m].label)
	return " + ".join(names)


# ข้อความเตือนสด (ลม/แผ่นดินไหว) / yaw = มุมกล้อง เพื่อบอกทิศลมตามที่ผู้เล่นเห็นบนจอ
func status_text(yaw: float) -> String:
	var parts: Array[String] = []
	if _wind.phase == Phase.WARN:
		parts.append("WIND IN %d  %s" % [ceili(_wind.left), _wind_arrow(yaw)])
	elif _wind.phase == Phase.ACTIVE:
		parts.append("WIND!  %s" % _wind_arrow(yaw))
	if _shake.phase == Phase.WARN:
		parts.append("RUMBLING...")
	elif _shake.phase == Phase.ACTIVE:
		parts.append("EARTHQUAKE!")
	return "  ".join(parts)


func _process(delta: float) -> void:
	if _rain:
		_rain.global_position = Vector3(0.0, follow_y + 14.0, 0.0)
	if not running:
		return
	_clock += delta
	if _mods.has("wind"):
		_step(_wind, "wind", delta)
	if _mods.has("shake"):
		_step(_shake, "shake", delta)


func _physics_process(_delta: float) -> void:
	if not running or blocks_root == null:
		return
	if _wind.phase == Phase.ACTIVE:
		var force := float(GameData.MODIFIERS.wind.force)
		for b in _loose_blocks():
			b.apply_central_force(_wind.dir * force)
	if _shake.phase == Phase.ACTIVE:
		var accel := float(GameData.MODIFIERS.shake.accel)
		# แกว่งแนวราบเร็วๆ (สองความถี่ต่างกัน ให้ไม่ซ้ำรูปแบบ) คูณมวล = ทุกชิ้นได้ความเร่งเท่ากัน
		var dir := Vector3(sin(_clock * 43.0), 0.0, cos(_clock * 37.0))
		for b in _loose_blocks():
			b.apply_central_force(dir * accel * b.mass)


# เฟสของตัวปรับที่เป็นช่วง: IDLE → WARN → ACTIVE → IDLE
func _step(s: Dictionary, key: String, delta: float) -> void:
	var cfg: Dictionary = GameData.MODIFIERS[key]
	s.left -= delta
	if s.left > 0.0:
		if camera:
			# สั่นจอค้างตลอดช่วง: แผ่นดินไหวครืนเบาๆ ตอนเตือนแล้วแรงตอนเกิดจริง / ลมสั่นนิดๆ ตอนพัด
			if s.phase == Phase.WARN and key == "shake":
				camera.rumble(0.15)
			elif s.phase == Phase.ACTIVE:
				camera.rumble(0.2 if key == "wind" else 0.45)
		return
	match s.phase:
		Phase.IDLE:
			s.phase = Phase.WARN
			s.left = float(cfg.warn)
			if key == "wind":
				s.dir = _random_direction()
		Phase.WARN:
			s.phase = Phase.ACTIVE
			s.left = float(cfg.duration)
		Phase.ACTIVE:
			s.phase = Phase.IDLE
			s.left = _random_interval(key)


# บล็อกที่ปล่อยแล้วและยังไม่ถูก freeze (ชิ้นที่ติดเทปแบบ weld ยังขยับได้ตามกอง แต่ชิ้นที่ถูกปักไว้ไม่ขยับ)
func _loose_blocks() -> Array[Block]:
	var out: Array[Block] = []
	for b in blocks_root.get_children():
		var blk := b as Block
		if blk and blk.released and not blk.freeze and not blk.is_queued_for_deletion():
			out.append(blk)
	return out


func _random_interval(key: String) -> float:
	var r: Vector2 = GameData.MODIFIERS[key].interval
	return randf_range(r.x, r.y)


func _random_direction() -> Vector3:
	var a := randf() * TAU
	return Vector3(cos(a), 0.0, sin(a))


# ลูกศรทิศลมตามมุมกล้อง: ขวาของกล้อง = (cos yaw, 0, -sin yaw) / ไปข้างหน้า (ห่างกล้อง) = (-sin yaw, 0, -cos yaw)
func _wind_arrow(yaw: float) -> String:
	var d: Vector3 = _wind.dir
	var right := d.x * cos(yaw) - d.z * sin(yaw)
	var away := -d.x * sin(yaw) - d.z * cos(yaw)
	if absf(right) >= absf(away):
		return ">>>" if right > 0.0 else "<<<"
	return "^^^" if away > 0.0 else "vvv"


func _start_rain() -> void:
	_rain = CPUParticles3D.new()
	_rain.amount = 260
	_rain.lifetime = 1.1
	_rain.preprocess = 1.1
	_rain.local_coords = false
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(10.0, 0.1, 10.0)
	_rain.direction = Vector3.DOWN
	_rain.spread = 0.0
	_rain.gravity = Vector3.ZERO
	_rain.initial_velocity_min = 18.0
	_rain.initial_velocity_max = 20.0
	var streak := BoxMesh.new()
	streak.size = Vector3(0.025, 0.7, 0.025)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.55, 0.65, 0.85, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak.material = m
	_rain.mesh = streak
	add_child(_rain)
