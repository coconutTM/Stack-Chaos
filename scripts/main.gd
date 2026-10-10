extends Node3D

enum State { HOLDING, WAITING, GAME_OVER }

const HOLD_GAP := 1.8     # บล็อกที่ถืออยู่ลอยเหนือยอดกองกี่เมตร (ยิ่งต่ำ ยิ่งตกแรงน้อย กองง่ายขึ้น)
const BOUND := 3.0        # ขอบเขตที่เลื่อนบล็อกได้ (ตามขนาดพื้น)
const KILL_Y := -4.0      # ตกต่ำกว่านี้ = ถือว่าชิ้นนั้นหลุดจากกอง
const MAX_WAIT := 5.0     # รอบล็อกนิ่งนานสุดกี่วินาที
const MAX_FAILS := 3      # หลุดกองครบกี่ชิ้น = แพ้ (ไม่เว้นฐาน ชิ้นแรกก็นับเหมือนกัน)
const WIN_HEIGHT := 7.5   # กองสูงถึงเท่านี้ (เมตร) ก่อนของหมด = ชนะ
const MAX_PIECES := 10    # ของให้ใช้แค่นี้ชิ้น (นับทุกชิ้นที่ spawn แม้จะหลุด) ใช้ครบแล้วยังไม่ถึง WIN_HEIGHT = แพ้
const RESTART_DELAY := 0.3  # หน่วงหลังจบเกมกี่วินาทีก่อนรับคลิกเริ่มใหม่ (กันเผลอคลิกข้าม)

@onready var camera: OrbitCamera = $Camera3D
@onready var blocks_root: Node3D = $Blocks
@onready var score_label: Label = $UI/ScoreLabel
@onready var game_over_label: Label = $UI/GameOverLabel

var crane: Crane
var guide: DropGuide

var state := State.HOLDING
var current: Block
var score := 0
var failed_attempts := 0
var pieces_used := 0
var won := false
var tower_top := 0.0
var wait_time := 0.0
var _over_at_msec := 0   # เวลา (ms) ที่เกมจบ ใช้คุม RESTART_DELAY


func _ready() -> void:
	crane = Crane.new()
	add_child(crane)
	guide = DropGuide.new()
	add_child(guide)
	camera.tapped.connect(_on_camera_tapped)
	game_over_label.hide()
	spawn_block()
	update_ui()


func _process(delta: float) -> void:
	# กล้องโคจร/ตามความสูงกองเอง (orbit_camera.gd) / ที่นี่แค่บอกความสูงเป้าหมาย
	camera.target_y = tower_top

	var holding := state == State.HOLDING
	# ระหว่างลากหมุนกล้องไม่ต้องให้ชิ้นที่ถือวิ่งตามเมาส์
	if holding and not camera.dragging:
		move_held_block()

	crane.update_crane(camera.yaw, current if holding else null, tower_top + HOLD_GAP, delta)
	guide.target = current if holding else null


func _physics_process(delta: float) -> void:
	if state == State.GAME_OVER:
		return

	# ของชิ้นไหนหล่นตกขอบพื้น = หลุดจากกอง 1 ชิ้น (รวมฐานด้วย ไม่มีการยกเว้น)
	for b in blocks_root.get_children():
		if b.global_position.y >= KILL_Y:
			continue
		var was_current := b == current
		b.queue_free()
		failed_attempts += 1
		update_ui()
		if failed_attempts >= MAX_FAILS:
			game_over()
			return
		if was_current:
			# ชิ้นที่ถืออยู่หลุดไปตอนยังไม่ทันนิ่ง ไม่นับคะแนน ไปต่อชิ้นใหม่เลย (ถ้ายังมีของเหลือ)
			_advance_or_end()
			return

	# รอให้บล็อกที่ปล่อยไปนิ่งก่อน แล้วค่อยให้ชิ้นถัดไป
	if state == State.WAITING:
		wait_time += delta
		if current.settled or wait_time > MAX_WAIT:
			current.settled = true
			score += 1
			recalc_tower_top()
			update_ui()
			if tower_top >= WIN_HEIGHT:
				win()
				return
			_advance_or_end()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return

	if state == State.GAME_OVER:
		var elapsed := (Time.get_ticks_msec() - _over_at_msec) / 1000.0
		if event.button_index == MOUSE_BUTTON_LEFT and elapsed >= RESTART_DELAY:
			get_tree().reload_current_scene()
		return

	if state != State.HOLDING:
		return

	match event.button_index:
		MOUSE_BUTTON_LEFT:        # คลิกซ้าย = ปล่อย
			current.release()
			state = State.WAITING
			wait_time = 0.0
		MOUSE_BUTTON_WHEEL_UP:    # ลูกกลิ้ง = หมุน 45°
			current.rotate_y(deg_to_rad(45))
		MOUSE_BUTTON_WHEEL_DOWN:
			current.rotate_y(deg_to_rad(-45))


# คลิกขวาสั้นๆ (ไม่ลาก) = พลิกชิ้นที่ถือตะแคง 90° / ลากค้าง = หมุนกล้อง (orbit_camera.gd)
func _on_camera_tapped() -> void:
	if state == State.HOLDING:
		current.rotate_z(deg_to_rad(90))


# ไปชิ้นถัดไปถ้ายังมีของเหลือ ไม่งั้นใช้ของครบ MAX_PIECES แล้วยังไม่ถึง WIN_HEIGHT = แพ้
func _advance_or_end() -> void:
	if pieces_used >= MAX_PIECES:
		game_over()
	else:
		spawn_block()


func spawn_block() -> void:
	pieces_used += 1
	current = Block.spawn(randi() % Block.KIND_COUNT)
	blocks_root.add_child(current)
	current.global_position = Vector3(0, tower_top + HOLD_GAP, 0)
	state = State.HOLDING
	update_ui()


func move_held_block() -> void:
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var dir := camera.project_ray_normal(mouse)
	var hold_y := tower_top + HOLD_GAP
	var hit = Plane(Vector3.UP, hold_y).intersects_ray(origin, dir)
	if hit == null:
		return
	var p: Vector3 = hit
	current.global_position = Vector3(
		clampf(p.x, -BOUND, BOUND),
		hold_y,
		clampf(p.z, -BOUND, BOUND)
	)


func recalc_tower_top() -> void:
	var top := 0.0
	for b in blocks_root.get_children():
		var blk := b as Block
		if blk and blk.released and blk.settled:
			top = maxf(top, blk.top_y())
	tower_top = top


func update_ui() -> void:
	score_label.text = "TRASH: %d\nHEIGHT: %.1f m\nFAILS: %d/%d\nPIECES: %d/%d" % [
		score, tower_top, failed_attempts, MAX_FAILS, pieces_used, MAX_PIECES
	]


# ใช้ร่วมกันทั้งชนะ/แพ้: เปลี่ยนสถานะ จับเวลา และหยุดฟิสิกส์ของทุกชิ้น
func _end_game() -> void:
	state = State.GAME_OVER
	_over_at_msec = Time.get_ticks_msec()
	for b in blocks_root.get_children():
		var blk := b as Block
		if blk:
			blk.freeze_in_place()


func win() -> void:
	won = true
	_end_game()
	game_over_label.text = "QUOTA MET!\nHEIGHT: %.1f m\nPIECES USED: %d/%d\n\nclick to play again" % [
		tower_top, pieces_used, MAX_PIECES
	]
	game_over_label.show()


func game_over() -> void:
	_end_game()
	game_over_label.text = "YOU'RE FIRED!\nHEIGHT: %.1f m\nDROPPED: %d PIECES\nUSED: %d/%d\n\nclick to retry" % [
		tower_top, failed_attempts, pieces_used, MAX_PIECES
	]
	game_over_label.show()
