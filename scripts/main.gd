extends Node3D

# ตัวคุมเกมหลัก: state machine ของวัน/ชิ้นขยะ
# ค่าโควต้า/จำนวนชิ้น/บทพูดอยู่ใน data/game_data.gd และ data/dialogue.gd

enum State { TITLE, DIALOGUE, HOLDING, WAITING, FIRED, ENDING }

const HOLD_GAP := 1.8     # บล็อกที่ถือลอยเหนือยอดกองกี่เมตร (ยิ่งต่ำ ยิ่งตกแรงน้อย กองง่ายขึ้น)
const BOUND := 3.0        # ขอบเขตที่เลื่อนบล็อกได้ (ตามขนาดพื้น)
const KILL_Y := -4.0      # ตกต่ำกว่านี้ = ถือว่าชิ้นนั้นหลุดจากกอง
const MAX_WAIT := 5.0     # รอบล็อกนิ่งนานสุดกี่วินาที
const RESTART_DELAY := 0.3  # หน่วงหลังขึ้นหน้าจบก่อนรับคลิก (กันเผลอคลิกข้าม)

@onready var camera: OrbitCamera = $Camera3D
@onready var blocks_root: Node3D = $Blocks
@onready var score_label: Label = $UI/ScoreLabel
@onready var game_over_label: Label = $UI/GameOverLabel

var crane: Crane
var guide: DropGuide
var dialogue: DialogueBox
var bag := PieceBag.new()

var state := State.TITLE
var current: Block
var day := 1
var quota_height := 0.0
var max_pieces := 0
var score := 0              # ขยะที่วางสำเร็จตลอดการเล่นรอบนี้ (ข้ามวัน)
var failed_attempts := 0    # หลุดกองในวันนี้
var pieces_used := 0        # ชิ้นที่ spawn ในวันนี้
var tower_top := 0.0
var best_height := 0.0      # ยอดกองสูงสุดของวันนี้ ไว้จับว่ากองล้ม
var wait_time := 0.0
var _near_said := false
var _first_drop_said := false
var _comment_ready_at := 0   # เวลา (ms) ที่ boss คอมเมนต์ได้อีก
var _screen_at_msec := 0     # เวลา (ms) ที่ขึ้นหน้าจบ ใช้คุม RESTART_DELAY


func _ready() -> void:
	crane = Crane.new()
	add_child(crane)
	guide = DropGuide.new()
	add_child(guide)
	dialogue = DialogueBox.new()
	add_child(dialogue)
	camera.tapped.connect(_on_camera_tapped)

	score_label.add_theme_font_size_override("font_size", 11)
	game_over_label.add_theme_font_size_override("font_size", 14)
	game_over_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_show_title()


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
	if state != State.HOLDING and state != State.WAITING:
		return

	# ของชิ้นไหนหล่นตกขอบพื้น = หลุดจากกอง 1 ชิ้น (รวมฐานด้วย ไม่มีการยกเว้น)
	for b in blocks_root.get_children():
		if b.global_position.y >= KILL_Y:
			continue
		var was_current := b == current
		b.queue_free()
		failed_attempts += 1
		update_ui()
		if failed_attempts >= GameData.MAX_FAILS:
			_end_day(false, "fails")
			return
		_comment("tutorial_fail" if _is_tutorial() else "fail")
		if was_current:
			# ชิ้นที่ปล่อยไปหลุดตอนยังไม่ทันนิ่ง ไม่นับคะแนน ไปต่อชิ้นใหม่เลย (ถ้ายังมีของเหลือ)
			# current ถูก queue_free แล้ว ห้ามแตะต่อในเฟรมนี้ จึง return ทันที
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
			if tower_top >= quota_height:
				_end_day(true)
				return
			_comment_on_progress()
			_advance_or_end()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return

	match state:
		State.TITLE:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_start_run()
		State.FIRED:
			if event.button_index == MOUSE_BUTTON_LEFT and _screen_ready():
				_start_run()
		State.ENDING:
			if event.button_index == MOUSE_BUTTON_LEFT and _screen_ready():
				_show_title()
		State.HOLDING:
			match event.button_index:
				MOUSE_BUTTON_LEFT:        # คลิกซ้าย = ปล่อย
					current.release()
					state = State.WAITING
					wait_time = 0.0
					if _is_tutorial() and not _first_drop_said:
						_first_drop_said = true
						_comment("tutorial_drop")
				MOUSE_BUTTON_WHEEL_UP:    # ลูกกลิ้ง = หมุน 45°
					current.rotate_y(deg_to_rad(45))
				MOUSE_BUTTON_WHEEL_DOWN:
					current.rotate_y(deg_to_rad(-45))


# คลิกขวาสั้นๆ (ไม่ลาก) = พลิกชิ้นที่ถือตะแคง 90° / ลากค้าง = หมุนกล้อง (orbit_camera.gd)
func _on_camera_tapped() -> void:
	if state == State.HOLDING:
		current.rotate_z(deg_to_rad(90))


# ---------- วัน / รอบการเล่น ----------

func _start_run() -> void:
	day = 1
	score = 0
	game_over_label.hide()
	_start_day()


func _start_day() -> void:
	var d: Dictionary = GameData.DAYS[day - 1]
	quota_height = d.height
	max_pieces = d.pieces

	for b in blocks_root.get_children():
		b.queue_free()
	current = null
	tower_top = 0.0
	best_height = 0.0
	failed_attempts = 0
	pieces_used = 0
	_near_said = false
	_first_drop_said = false
	_comment_ready_at = 0
	score_label.show()
	update_ui()

	state = State.DIALOGUE
	await dialogue.say(_lines(Dialogue.DAY_INTRO[day]))
	spawn_block()


# จบวัน: ผ่าน → boss พูด → วันต่อไป (หรือฉากจบ) / ไม่ผ่าน → โดนไล่ออก
func _end_day(passed: bool, reason := "") -> void:
	state = State.DIALOGUE
	for b in blocks_root.get_children():
		var blk := b as Block
		if blk:
			blk.freeze_in_place()   # หยุดฟิสิกส์ ไม่ให้กองกลิ้งต่อระหว่าง boss พูด

	if not passed:
		await dialogue.say(_lines(Dialogue.FIRED_FAILS if reason == "fails" else Dialogue.FIRED_PIECES))
		_show_screen("YOU'RE FIRED!\nDAY %d\nHEIGHT: %.1f / %.1f m\nDROPPED: %d PIECES\n\nclick to start over" % [
			day, tower_top, quota_height, failed_attempts
		])
		state = State.FIRED
		return

	await dialogue.say(_lines(Dialogue.DAY_PASS[day]))
	if day >= GameData.DAYS.size():
		await dialogue.say(_lines(Dialogue.ENDING))
		_show_screen("SHIFT COMPLETE\nTRASH STACKED: %d\n\nclick to return to title" % score)
		state = State.ENDING
	else:
		day += 1
		_start_day()


func _show_title() -> void:
	state = State.TITLE
	for b in blocks_root.get_children():
		b.queue_free()
	current = null
	tower_top = 0.0
	score_label.hide()
	_show_screen("STACK CHAOS!\n\nclick to start")


func _show_screen(text: String) -> void:
	game_over_label.text = text
	game_over_label.show()
	_screen_at_msec = Time.get_ticks_msec()


func _screen_ready() -> bool:
	return (Time.get_ticks_msec() - _screen_at_msec) / 1000.0 >= RESTART_DELAY


# ---------- ชิ้นขยะ ----------

# ไปชิ้นถัดไปถ้ายังมีของเหลือ ไม่งั้นใช้ของครบแล้วยังไม่ถึงโควต้า = แพ้
func _advance_or_end() -> void:
	if pieces_used >= max_pieces:
		_end_day(false, "pieces")
	else:
		spawn_block()


func spawn_block() -> void:
	pieces_used += 1
	current = Block.spawn(bag.next())
	# ตั้งตำแหน่งก่อน add_child ไม่ให้ชิ้นเทเลพอร์ตจาก (0,0,0) ขึ้นมา (blocks_root อยู่ที่จุดกำเนิด)
	current.position = Vector3(0, tower_top + HOLD_GAP, 0)
	blocks_root.add_child(current)
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


# ---------- boss คอมเมนต์ระหว่างวัน ----------

func _is_tutorial() -> bool:
	return GameData.DAYS[day - 1].get("tutorial", false)


# เช็คกองล้ม / ใกล้ถึงโควต้า หลังชิ้นล่าสุดนิ่ง
func _comment_on_progress() -> void:
	if tower_top > best_height:
		best_height = tower_top
	elif tower_top < best_height - GameData.COLLAPSE_DROP:
		best_height = tower_top
		_comment("collapse")
		return
	if not _near_said and tower_top >= quota_height - GameData.NEAR_QUOTA:
		_near_said = true
		_comment("near")


func _comment(key: String) -> void:
	var now := Time.get_ticks_msec()
	if now < _comment_ready_at or dialogue.is_busy():
		return
	_comment_ready_at = now + int(GameData.COMMENT_COOLDOWN * 1000.0)
	var pool: Array = Dialogue.COMMENTS[key]
	dialogue.comment(_lines([pool.pick_random()])[0])


# แทนตัวแปร {quota} ฯลฯ ในบทพูด
func _lines(lines: Array) -> Array:
	return Dialogue.fmt(lines, {
		"day": day,
		"days": GameData.DAYS.size(),
		"quota": "%.1f" % quota_height,
		"pieces": max_pieces,
		"height": "%.1f" % tower_top,
		"fails": failed_attempts,
		"max_fails": GameData.MAX_FAILS,
	})


func update_ui() -> void:
	score_label.text = "DAY: %d/%d\nTRASH: %d\nHEIGHT: %.1f / %.1f m\nFAILS: %d/%d\nPIECES: %d/%d" % [
		day, GameData.DAYS.size(), score, tower_top, quota_height,
		failed_attempts, GameData.MAX_FAILS, pieces_used, max_pieces
	]
