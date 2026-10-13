extends Node3D

# ตัวคุมเกมหลัก: state machine ของวัน/ชิ้นขยะ
# ค่าโควต้า/จำนวนชิ้น/บทพูดอยู่ใน data/game_data.gd และ data/dialogue.gd

enum State { TITLE, DIALOGUE, HOLDING, WAITING, FIRED, ENDING }

const HOLD_GAP := 1.8     # บล็อกที่ถือลอยเหนือยอดกองกี่เมตร (ยิ่งต่ำ ยิ่งตกแรงน้อย กองง่ายขึ้น)
const BOUND := 3.0        # ขอบเขตที่เลื่อนบล็อกได้ (ตามขนาดพื้น)
const STRAIN_AMP := 0.65  # เมาส์เลยขอบ = เครนตึง ชิ้นแกว่งสูงสุดกี่เมตร (กันเทคนิคตรึงชิ้นที่มุมให้ซ้อนตรงเป๊ะ)
const STRAIN_RATE := 8.0  # ความเร็วที่การแกว่งเริ่ม/หยุด (ใช้ในสูตร 1 - exp(-rate * delta))
const KILL_Y := -4.0      # ตกต่ำกว่านี้ = ถือว่าชิ้นนั้นหลุดจากกอง (สำรอง — ปกติโดนจับที่ _fell_off() ก่อนถึงพื้นลาน)
const MAX_WAIT := 5.0     # รอบล็อกนิ่งนานสุดกี่วินาที
const HARD_IMPACT := 10.0   # impact เกินนี้ = กระแทกหนัก (เสียงหนัก + สั่นจอ + ฝุ่น) ดู Block.hit
const RESTART_DELAY := 0.3  # หน่วงหลังขึ้นหน้าจบก่อนรับคลิก (กันเผลอคลิกข้าม)
const TITLE_SPIN := 0.12    # ความเร็วกล้องหมุนรอบกองตัวอย่างตอนอยู่หน้า title (เรเดียน/วินาที)
const TITLE_PILE_TOP := 3.0 # ความสูงที่กล้อง/ไฟโฟกัสตอน title (กองตัวอย่างสูงราว 4-5 ม.)
# กองตัวอย่างหน้า title: [ชนิด, ตำแหน่ง x, z] ปล่อยทีละชิ้นจากสูง (ไล่ความสูงเอง) แล้วให้ฟิสิกส์จัดกองเอง
const TITLE_PILE := [
	[Block.Kind.STEEL_CRATE, 0.0, 0.0], [Block.Kind.SOFA, 0.1, -0.1], [Block.Kind.CRATE, -0.3, 0.1],
	[Block.Kind.SQUARE, 0.2, 0.0], [Block.Kind.TV, -0.1, 0.1], [Block.Kind.CARDBOARD_BOX, 0.1, 0.0],
]

@onready var camera: OrbitCamera = $Camera3D
@onready var blocks_root: Node3D = $Blocks
@onready var score_label: Label = $UI/ScoreLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var ground: CSGBox3D = $Ground

var crane: Crane
var _strain := 0.0                  # 0 = เมาส์อยู่ในระยะเอื้อมเครน, 1 = เลยขอบเต็มที่ (ชิ้นที่ถือแกว่ง)
var _strain_time := 0.0
var _strain_phase := Vector4.ZERO   # เฟสการแกว่งของแต่ละชิ้น (สุ่มใหม่ใน _make_current)
var _hold_basis := Basis.IDENTITY   # ทิศของชิ้นที่ถือ (main เป็นเจ้าของ: move_held_block() ตั้งทับทุกเฟรม ไม่งั้นการหมุนหาย)
var guide: DropGuide
var quota_marker: QuotaMarker
var dialogue: DialogueBox
var item_bar: ItemBar
var height_meter: HeightMeter
var review: ReviewScreen
var title_menu: TitleMenu
var settings_panel: SettingsPanel
var item_choice: ItemChoice
var shop: BossShop
var look: Ps1Look
var modifiers: DayModifiers
var screen_fx: ScreenFx
var sfx: Sfx
var sound_toggle: SoundToggle
var pause_menu: PauseMenu
var items: ItemSystem
var bag := PieceBag.new(GameData.kinds_for_day(1))

var state := State.TITLE
var current: Block
var last_settled: Block     # ชิ้นล่าสุดที่นิ่ง (เป้าหมายของ Duct Tape)
var stack_base: Block       # ฐานของกอง = ชิ้นเดียวที่อนุญาตให้นอนบนพื้น (ชิ้นแรกที่นิ่งของกอง)
var day := 1                # โหมด OVERTIME: day = DAYS.size() + เลขกะ (นับต่อจากวันที่ 5 เพื่อให้ขยะ/ตัวปรับครบทุกชนิด)
var overtime := false       # true = กำลังเล่นโหมด OVERTIME (ไม่มีวันสุดท้าย โดนไล่ออก = จบรอบ)
var _cur_day: Dictionary = GameData.DAYS[0]   # ข้อมูลของวันที่กำลังเล่น (overtime สุ่มตัวปรับ จึงต้องเก็บไว้ ไม่สร้างซ้ำ)
var quota_height := 0.0
var max_pieces := 0
var score := 0              # ขยะที่วางสำเร็จตลอดการเล่นรอบนี้ (ข้ามวัน)
var money := 0              # เงินในกระเป๋า (ได้จากหน้าสรุปผลงานท้ายวัน / ลดเมื่อซื้อของในร้านหรือจ่ายสินบน)
var earned := 0             # รายได้รวมของรอบนี้ (ไม่ลดเมื่อใช้เงิน ไว้โชว์ TOTAL EARNED ตอนจบ)
var bribes_used := 0        # จ่ายสินบนไปกี่ครั้งในรอบนี้ (ราคาเพิ่มเป็นสองเท่าทุกครั้ง)
var bribe_paid_total := 0   # เงินสินบนรวมของรอบนี้ (ฉากจบพิเศษ)
var suspicion := 0          # ความระแวงของ boss 0-100 (ดู GameData.SUSPICION_*) / ตา boss เปลี่ยนสีตามระดับ
var _bribed_today := false  # จ่ายสินบนในวันนี้แล้ว (วันที่ไม่ติดสินบน ความระแวงลดลง)
var _audit_today := false   # วันนี้โดนตรวจ = boss ไม่รับสินบน
var trophy_bonus := 0       # โบนัสจาก GOLD TROPHY ที่วางนิ่งได้ในวันนี้ (บวกเข้า money ตอนสรุปผลงาน)
var failed_attempts := 0    # หลุดกองในวันนี้
var pieces_used := 0        # ชิ้นที่ spawn ในวันนี้
var tower_top := 0.0
var best_height := 0.0      # ยอดกองสูงสุดของวันนี้ ไว้จับว่ากองล้ม
var wait_time := 0.0
var _near_said := false
var _fragile_said := false
var _first_drop_said := false
var _comment_ready_at := 0   # เวลา (ms) ที่ boss คอมเมนต์ได้อีก
var _screen_at_msec := 0     # เวลา (ms) ที่ขึ้นหน้าจบ ใช้คุม RESTART_DELAY
var _motor := 0.0            # ระดับเสียงมอเตอร์เครน (ตามความเร็วที่ขยับชิ้นที่ถือ)
var _last_hold_pos := Vector3.ZERO
var _flow_id := 0            # เพิ่มทุกครั้งที่ /day ตัดลำดับวันกลางคัน → coroutine เก่า (บทพูด/จอมืด) ที่ยังรออยู่เลิกเอง


func _ready() -> void:
	Settings.load_all()
	Settings.apply_audio()
	Psx.set_snap(Settings.retro_look)
	GameTheme.apply(get_tree().root)
	sfx = Sfx.new()
	add_child(sfx)
	sound_toggle = SoundToggle.new()
	add_child(sound_toggle)
	sfx.set_loop("ambient", true, -10.0)
	sfx.set_loop("motor", true, -80.0)
	look = Ps1Look.new()
	look.ground = ground
	add_child(look)
	modifiers = DayModifiers.new()
	modifiers.blocks_root = blocks_root
	modifiers.camera = camera
	modifiers.environment = $WorldEnvironment.environment
	add_child(modifiers)
	screen_fx = ScreenFx.new()
	add_child(screen_fx)
	crane = Crane.new()
	add_child(crane)
	guide = DropGuide.new()
	guide.pad_top = ground.position.y + ground.size.y * 0.5
	add_child(guide)
	quota_marker = QuotaMarker.new()
	add_child(quota_marker)
	dialogue = DialogueBox.new()
	add_child(dialogue)
	review = ReviewScreen.new()
	add_child(review)
	item_choice = ItemChoice.new()
	add_child(item_choice)
	item_choice.picked.connect(func(id: String) -> void: if id != "": sfx.play("item_get"))
	shop = BossShop.new()
	add_child(shop)
	shop.buy = _shop_buy
	shop.sell = _shop_sell
	title_menu = TitleMenu.new()
	add_child(title_menu)
	title_menu.play_pressed.connect(_start_run)
	title_menu.overtime_pressed.connect(_start_run.bind(true))
	title_menu.clicked.connect(func() -> void: sfx.play("ui_click"))
	title_menu.settings_pressed.connect(func() -> void: settings_panel.open())
	review.tick.connect(func() -> void: sfx.play("ui_click", -6.0))
	review.stamp.connect(func() -> void: sfx.play("item_get"))
	items = ItemSystem.new(self)
	item_bar = ItemBar.new()
	add_child(item_bar)
	item_bar.slot_pressed.connect(_on_item_slot)
	height_meter = HeightMeter.new()
	add_child(height_meter)
	items.used.connect(func(ok: bool) -> void: sfx.play("item_use" if ok else "deny"))
	dialogue.blip.connect(sfx.blip)
	look.flickered.connect(func() -> void: sfx.play("buzz", -6.0))
	modifiers.phase_changed.connect(_on_modifier_phase)
	var console := DevConsole.new()
	console.register("day", "/day N  start a fresh run at day N (1-%d)" % GameData.DAYS.size(), _debug_day)
	console.register("overtime", "/overtime [N]  start overtime at shift N (default 1)", _debug_overtime)
	console.register("give", "/give <item|all>  add items", _debug_give)
	console.register("money", "/money N  set your cash", _debug_money)
	console.register("ending", "/ending corrupt|boss  play an ending now", _debug_ending)
	console.register("suspicion", "/suspicion N  set boss suspicion (0-%d, audit at %d)" % [100, GameData.SUSPICION_AUDIT], _debug_suspicion)
	add_child(console)
	pause_menu = PauseMenu.new()
	pause_menu.can_pause = func() -> bool: return state == State.HOLDING or state == State.WAITING
	pause_menu.quit_requested.connect(_go_title)
	pause_menu.settings_requested.connect(func() -> void: settings_panel.open())
	add_child(pause_menu)
	settings_panel = SettingsPanel.new()   # เพิ่มหลัง PauseMenu → ได้รับ Esc ก่อน (ปิดหน้า SETTINGS ก่อนที่ Esc จะไปปิด pause)
	add_child(settings_panel)
	settings_panel.changed.connect(func() -> void: sfx.play("ui_click"))
	add_child(FpsOverlay.new())
	camera.tapped.connect(_on_camera_tapped)

	score_label.offset_left = 4.0   # เว้นขอบ (ฟอนต์ pixel ล้นขึ้นด้านบนเล็กน้อย)
	score_label.offset_top = 5.0
	score_label.add_theme_font_size_override("font_size", 8)   # Press Start 2P คมสุดที่พหุคูณของ 8
	game_over_label.add_theme_font_size_override("font_size", 16)
	game_over_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# หน้าข้อความเต็มจอ (YOU'RE FIRED! / SHIFT COMPLETE) มีพื้นหลังดำสนิทอยู่หลังตัวหนังสือ โชว์/ซ่อนตามป้ายเสมอ
	var screen_bg := ColorRect.new()
	screen_bg.color = Color.BLACK
	screen_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_bg.visible = false
	$UI.add_child(screen_bg)
	$UI.move_child(screen_bg, game_over_label.get_index())   # อยู่ใต้ป้ายแต่ทับ HUD (ScoreLabel)
	game_over_label.visibility_changed.connect(func() -> void: screen_bg.visible = game_over_label.visible)
	screen_fx.cover_now()   # เปิดเกมจากจอดำแล้วค่อยๆ สว่าง
	_show_title()
	screen_fx.uncover(0.8)


func _process(delta: float) -> void:
	# กล้องโคจร/ตามความสูงกองเอง (orbit_camera.gd) / ที่นี่แค่บอกความสูงเป้าหมาย
	if state == State.TITLE:
		camera.yaw += TITLE_SPIN * delta   # หน้า title: กล้องวนรอบกองตัวอย่างช้าๆ
	camera.target_y = tower_top
	camera.can_zoom = state == State.HOLDING or state == State.WAITING
	look.target_y = tower_top
	modifiers.running = state == State.HOLDING or state == State.WAITING
	modifiers.follow_y = tower_top
	look.power = modifiers.power   # ตัวปรับ BLACKOUT: ไฟดับ/กะพริบ

	var holding := state == State.HOLDING
	# ระหว่างลากหมุนกล้องไม่ต้องให้ชิ้นที่ถือวิ่งตามเมาส์
	if holding and not camera.dragging:
		move_held_block(delta)

	crane.update_crane(current if holding else null, tower_top + HOLD_GAP, delta)
	_update_motor(holding, delta)
	guide.target = current if holding else null
	# มีกองแล้ว (มีชิ้นนิ่ง) → วงนำทางจะเตือนสีแดงถ้าจุดตกคือพื้น
	guide.ground_is_fail = holding and _has_settled_piece(current)
	# เส้นโควต้าโชว์เฉพาะระหว่างวัน (หน้า title / โดนไล่ออก / ฉากจบไม่โชว์)
	quota_marker.visible = quota_height > 0.0 and (state == State.DIALOGUE or state == State.HOLDING or state == State.WAITING)
	quota_marker.update_progress(tower_top)
	height_meter.visible = quota_marker.visible
	height_meter.set_values(tower_top, best_height, quota_height)
	_refresh_items()
	sound_toggle.visible = state == State.TITLE   # ปุ่มเปิด/ปิดเสียงมีเฉพาะหน้าแรก


func _physics_process(delta: float) -> void:
	if state != State.HOLDING and state != State.WAITING:
		return

	# ของชิ้นไหนหล่นตกขอบแท่น = หลุดจากกอง 1 ชิ้น (รวมฐานด้วย ไม่มีการยกเว้น)
	for b in blocks_root.get_children():
		if not _fell_off(b):
			continue
		var was_current := b == current
		var fragile := (b as Block) != null and (b as Block).fragile
		Effects.puff(self, b.global_position)   # ฝุ่นฟุ้งตรงที่ตกลงลาน
		b.queue_free()
		if _register_fail("fail", fragile):
			return
		if was_current:
			_reset_time()
			# ชิ้นที่ปล่อยไปหลุดตอนยังไม่ทันนิ่ง ไม่นับคะแนน ไปต่อชิ้นใหม่เลย (ถ้ายังมีของเหลือ)
			# current ถูก queue_free แล้ว ห้ามแตะต่อในเฟรมนี้ จึง return ทันที
			_advance_or_end()
			return

	if _check_collapse():
		return

	# รอให้บล็อกที่ปล่อยไปนิ่งก่อน แล้วค่อยให้ชิ้นถัดไป
	if state == State.WAITING:
		wait_time += delta
		if current.settled or wait_time > MAX_WAIT:
			# ตกลงพื้นข้างกองแทนที่จะอยู่บนกอง = นับว่าเสียชิ้นนี้ (เอาออกจากฉาก ไม่นับคะแนน)
			if _is_off_stack(current):
				var fragile := current.fragile
				current.queue_free()
				_reset_time()
				if _register_fail("off_stack", fragile):
					return
				_advance_or_end()
				return
			if not _has_settled_piece(current):
				stack_base = current   # ยังไม่มีกอง = ชิ้นนี้คือฐาน (ได้รับการยกเว้นเรื่องนอนบนพื้น)
			current.settled = true
			last_settled = current
			_reset_time()
			score += 1
			if current.kind == Block.Kind.GOLD_TROPHY:   # ถ้วยทองวางนิ่งได้ = โบนัสเงิน
				trophy_bonus += GameData.TROPHY_BONUS
				Effects.popup(self, current.global_position + Vector3(0.0, 1.8, 0.0), "TROPHY +$%d" % GameData.TROPHY_BONUS, Color(1.0, 0.85, 0.2))
				sfx.play("item_get")
			var prev_top := tower_top
			recalc_tower_top()
			_popup_progress(prev_top)
			update_ui()
			if tower_top >= quota_height:
				_end_day(true)
				return
			_comment_on_progress()
			_advance_or_end()


func _unhandled_input(event: InputEvent) -> void:
	# คีย์สำรองหมุน/พลิกชิ้นที่ถือ (physical_keycode ใช้ได้แม้ตั้งคีย์บอร์ดภาษาไทย)
	if event is InputEventKey and event.pressed and not event.echo:
		if state == State.HOLDING:
			match event.physical_keycode:
				KEY_Q:
					_spin_held(-45.0)
				KEY_E:
					_spin_held(45.0)
				KEY_R:
					_flip_held()
		return

	if not (event is InputEventMouseButton and event.pressed):
		return

	match state:
		State.FIRED, State.ENDING:   # กลับไปหน้าแรกก่อน (ไม่เริ่มวันที่ 1 ทันที)
			if event.button_index == MOUSE_BUTTON_LEFT and _screen_ready():
				_go_title()
		State.HOLDING:
			match event.button_index:
				MOUSE_BUTTON_LEFT:        # คลิกซ้าย = ปล่อย
					current.release()
					sfx.play("release")
					items.on_release()
					state = State.WAITING
					wait_time = 0.0
					if items.coffee_pending:
						Engine.time_scale = 0.5   # Coffee: สโลว์ 50% จนชิ้นนี้นิ่ง
					if _is_tutorial() and not _first_drop_said:
						_first_drop_said = true
						_comment("tutorial_drop")
				MOUSE_BUTTON_MIDDLE:      # คลิกกลาง = พลิกตะแคง (ลูกกลิ้งใช้ซูมกล้องใน orbit_camera.gd)
					_flip_held()


# คลิกขวาสั้นๆ (ไม่ลาก) = หมุนชิ้นที่ถือ 45° / Shift + คลิกขวา = พลิกตะแคง / ลากค้าง = หมุนกล้อง (orbit_camera.gd)
func _on_camera_tapped() -> void:
	if state != State.HOLDING:
		return
	if Input.is_key_pressed(KEY_SHIFT):
		_flip_held()
	else:
		_spin_held(45.0)


# หมุนชิ้นที่ถือรอบแกนตั้ง
func _spin_held(deg: float) -> void:
	_hold_basis = Basis(Vector3.UP, deg_to_rad(deg)) * _hold_basis
	sfx.play("ui_click", -10.0, randf_range(0.9, 1.1))


# พลิกชิ้นที่ถือตะแคง 90° รอบแกนแนวราบที่ชี้ออกจากกล้อง (เอียงไปทางขวาของจอเสมอ ไม่ว่ากล้องหมุนไปมุมไหน)
func _flip_held() -> void:
	var away := Vector3(-sin(camera.yaw), 0.0, -cos(camera.yaw))
	_hold_basis = Basis(away, deg_to_rad(90)) * _hold_basis
	sfx.play("ui_click", -10.0, randf_range(0.9, 1.1))


# ---------- วัน / รอบการเล่น ----------

func _start_run(is_overtime := false) -> void:
	title_menu.close()
	overtime = is_overtime
	day = GameData.DAYS.size() + 1 if is_overtime else 1
	score = 0
	money = 0
	earned = 0
	bribes_used = 0
	bribe_paid_total = 0
	_set_suspicion(0)
	items.reset_run()
	_start_day()


func _start_day(retry := false) -> void:
	var flow := _flow_id   # /day ตัดกลางคัน → coroutine นี้เลิกเองหลัง await (ดู _debug_day)
	state = State.DIALOGUE   # กันคลิกระหว่างจอมืด
	await screen_fx.cover()   # เปลี่ยนวัน: จอมืด → ล้างกอง/ตั้งค่าวันใหม่ใต้จอดำ → สว่าง
	if flow != _flow_id:
		return
	game_over_label.hide()
	title_menu.close()   # เผื่อเริ่มวันจาก /day หรือ /overtime ตอนอยู่หน้า title (ไม่ผ่านปุ่ม PLAY)
	# retry (จ่ายสินบน) = วันเดิมทุกอย่าง ใช้ข้อมูลที่เก็บไว้ (ห้ามเรียก overtime_day() ซ้ำ ตัวปรับสุ่มใหม่)
	if not retry:
		_bribed_today = false
		_audit_today = false
	var d: Dictionary = _cur_day if retry else (GameData.overtime_day(_shift()) if overtime else GameData.DAYS[day - 1])
	_cur_day = d
	quota_height = d.height
	max_pieces = d.pieces
	quota_marker.set_quota(quota_height, _shown_height(quota_height))

	for b in blocks_root.get_children():
		b.queue_free()
	current = null
	last_settled = null
	stack_base = null
	_reset_time()
	items.reset_day()
	tower_top = 0.0
	best_height = 0.0
	failed_attempts = 0
	pieces_used = 0
	trophy_bonus = 0
	_near_said = false
	_fragile_said = false
	_first_drop_said = false
	bag = PieceBag.new(GameData.kinds_for_day(day))
	modifiers.start(d.get("modifiers", []))
	sfx.set_loop("rain", d.get("modifiers", []).has("rain"), -16.0)
	_comment_ready_at = 0
	score_label.show()
	update_ui()
	await screen_fx.uncover()
	if flow != _flow_id:
		return

	if retry:   # เล่นซ้ำ: ข้ามบทต้นวันและไม่แจก item ประจำวันซ้ำ
		await dialogue.say(_lines(Dialogue.BRIBE_PAID))
		if flow != _flow_id:
			return
		spawn_block()
		return

	# ความระแวงถึงขีด: boss ตรวจ ยึดเงินครึ่งหนึ่ง และวันนี้ไม่รับสินบน
	if suspicion >= GameData.SUSPICION_AUDIT:
		var kept := int(money * GameData.AUDIT_KEEP)
		var taken := money - kept
		money = kept
		_audit_today = true
		_set_suspicion(GameData.AUDIT_RESET)
		sfx.play("warn")
		await dialogue.say(_lines(Dialogue.AUDIT, {"taken": taken}))
		if flow != _flow_id:
			return

	await dialogue.say(_lines(_intro_lines()))
	if flow != _flow_id:
		return

	# boss แจก item สุ่มตอนต้นวัน
	var given := items.grant_daily()
	if not given.names.is_empty():
		sfx.play("item_get")
	var give_lines: Array = Dialogue.ITEM_GIVE_FIRST if day == 1 else Dialogue.ITEM_GIVE
	if not given.names.is_empty():
		await dialogue.say(_lines(give_lines, {"items": ", ".join(given.names)}))
		if flow != _flow_id:
			return
	if given.overflow > 0:
		await dialogue.say(_lines(Dialogue.ITEM_FULL))
		if flow != _flow_id:
			return
	spawn_block()
	if GameData.suspicion_level(suspicion) == 2:
		_comment("suspicious")


# จบวัน: ผ่าน → boss พูด → วันต่อไป (หรือฉากจบ) / ไม่ผ่าน → โดนไล่ออก
func _end_day(passed: bool, reason := "") -> void:
	var flow := _flow_id   # /day ตัดกลางคัน → coroutine นี้เลิกเองหลัง await (ดู _debug_day)
	state = State.DIALOGUE
	_reset_time()
	modifiers.stop()
	sfx.set_loop("rain", false)
	for b in blocks_root.get_children():
		var blk := b as Block
		if blk:
			blk.freeze_in_place()   # หยุดฟิสิกส์ ไม่ให้กองกลิ้งต่อระหว่าง boss พูด

	if not passed:
		var fired_lines: Array = Dialogue.FIRED_PIECES
		if reason == "fails":
			fired_lines = Dialogue.FIRED_FAILS
		elif reason == "fragile":
			fired_lines = Dialogue.FIRED_FRAGILE
		sfx.play("fired")
		await dialogue.say(_lines(fired_lines))
		if flow != _flow_id:
			return
		# มีเงินพอ → boss เสนอสินบน จ่ายแล้วเล่นวันเดิมใหม่ (ราคาเพิ่มเป็นสองเท่าทุกครั้งในรอบเดียวกัน)
		var cost := GameData.bribe_cost(bribes_used)
		if money >= cost and _audit_today:
			await dialogue.say(_lines(Dialogue.BRIBE_REFUSED))   # โดนตรวจวันนี้ ไม่รับสินบน
			if flow != _flow_id:
				return
		elif money >= cost:
			var paid: bool = await _offer_bribe(cost)
			if flow != _flow_id:
				return
			if paid:
				money -= cost
				bribes_used += 1
				bribe_paid_total += cost
				_bribed_today = true
				_set_suspicion(suspicion + GameData.SUSPICION_PER_BRIBE)
				_start_day(true)
				return
		await screen_fx.cover()
		if flow != _flow_id:
			return
		if overtime:
			var survived := _shift() - 1   # กะที่ผ่านมาแล้ว (กะที่ตกไม่นับ)
			var is_record := survived > Settings.best_overtime
			if is_record:
				Settings.best_overtime = survived
				Settings.save_all()
			_show_screen("YOU'RE FIRED!\nSHIFTS SURVIVED: %d\n%s\nTOTAL EARNED: $%d\n\nclick to return to title" % [
				survived, "NEW RECORD!" if is_record and survived > 0 else "BEST: %d" % Settings.best_overtime, earned
			])
		else:
			_show_screen("YOU'RE FIRED!\nDAY %d\nHEIGHT: %.1f / %.1f m\nLOST: %d PIECES\n\nclick to return to title" % [
				day, _shown_height(tower_top), _shown_height(quota_height), failed_attempts
			])
		state = State.FIRED
		screen_fx.uncover()
		return

	if not _bribed_today:
		_set_suspicion(suspicion - GameData.SUSPICION_DECAY)   # วันที่ไม่ติดสินบน boss คลายระแวง
	sfx.play("pass")
	var pass_lines: Array = Dialogue.OVERTIME_PASS.pick_random() if overtime else Dialogue.DAY_PASS[day]
	await dialogue.say(_lines(pass_lines))
	if flow != _flow_id:
		return
	var grade: int = await _show_review()
	if flow != _flow_id:
		return
	# เกรดดี → boss ให้เลือกรางวัล item 1 ใน 3 (ถ้าคลังยังไม่เต็ม และยังมีวันต่อไป)
	var more_days := overtime or day < GameData.DAYS.size()
	if more_days and grade <= GameData.REWARD_MAX_GRADE and items.inventory.size() < ItemData.MAX_SLOTS:
		var picked: String = await item_choice.choose(ItemData.roll_distinct(3), Dialogue.REWARD_LINES.pick_random())
		if flow != _flow_id:
			return
		if picked != "":
			items.give(picked)
	if more_days:
		await _open_shop()
		if flow != _flow_id:
			return
	if not overtime and day >= GameData.DAYS.size():
		await _play_ending(bribes_used >= GameData.CORRUPT_ENDING_BRIBES, flow)
	else:
		day += 1
		_start_day()


# ร้านของ boss: สุ่มของ SHOP_STOCK ชิ้น เปิดเมื่อเงินพอซื้อชิ้นที่ถูกสุด หรือมี item ในคลังให้ขายคืน (ไม่งั้นข้ามไปเลย)
func _open_shop() -> void:
	var stock := ItemData.roll_distinct(ItemData.SHOP_STOCK)
	var cheapest := 1 << 30
	for id in stock:
		cheapest = mini(cheapest, int(ItemData.ITEMS[id].price))
	var can_buy := money >= cheapest and items.inventory.size() < ItemData.MAX_SLOTS
	if not can_buy and items.inventory.is_empty():
		return
	await shop.open(stock, money, Dialogue.SHOP_OPEN.pick_random(), items.inventory.duplicate())


# ซื้อของในร้าน (BossShop เรียกตอนกดการ์ด) / main เป็นเจ้าของเงินและคลัง ร้านแค่แสดงผลที่ได้กลับไป
func _shop_buy(id: String) -> Dictionary:
	var price := int(ItemData.ITEMS[id].price)
	if items.inventory.size() >= ItemData.MAX_SLOTS:
		sfx.play("deny")
		return _shop_result(false, Dialogue.SHOP_FULL)
	if money < price:
		sfx.play("deny")
		return _shop_result(false, Dialogue.SHOP_BROKE)
	money -= price
	items.give(id)
	sfx.play("item_get")
	return _shop_result(true, Dialogue.SHOP_BUY)


# ขาย item ช่องที่ index คืน boss (BossShop เรียกตอนกดช่องคลัง) ได้เงิน ItemData.sell_price()
func _shop_sell(index: int) -> Dictionary:
	if index < 0 or index >= items.inventory.size():
		return _shop_result(false, Dialogue.SHOP_BROKE)
	money += ItemData.sell_price(items.inventory[index])
	items.inventory.remove_at(index)
	items.changed.emit()
	sfx.play("ui_click")
	return _shop_result(true, Dialogue.SHOP_SELL)


# ผลที่ส่งกลับ BossShop (เงิน + บทพูดสุ่ม + คลังล่าสุด ให้ร้านวาดแถวคลังใหม่)
func _shop_result(ok: bool, lines: Array) -> Dictionary:
	return {"ok": ok, "cash": money, "line": lines.pick_random(), "inventory": items.inventory.duplicate()}


# ข้อเสนอสินบนตอนโดนไล่ออก / คืน true = ผู้เล่นเลือกจ่าย (main หักเงินและเริ่มวันใหม่เอง)
func _offer_bribe(cost: int) -> bool:
	var cards := [
		{"id": "pay", "name": "PAY $%d" % cost, "desc": "Keep your job and replay this day.",
			"color": Color(0.5, 0.85, 0.5), "footer": "CASH: $%d" % money},
		{"id": "leave", "name": "WALK AWAY", "desc": "Take the firing.", "color": Color(0.85, 0.35, 0.3)},
	]
	var level := GameData.suspicion_level(suspicion)
	var pool: Array = [Dialogue.BRIBE_OFFER, Dialogue.BRIBE_OFFER_WARY, Dialogue.BRIBE_OFFER_PARANOID][level]
	var hint: String = ["click a card", "he's getting suspicious", "he's watching you closely"][level]
	var line: String = _lines([pool.pick_random()], {"cost": cost})[0]
	var pick: String = await item_choice.offer("A QUIET WORD", line, cards, hint)
	return pick == "pay"


# หน้าสรุปผลงานท้ายวัน: เกรดจากชิ้นที่เสีย/ที่เหลือ → ค่าแรง (บวกเข้า money) / จดเกรดดีสุดของวัน
func _show_review() -> int:
	var spare := maxi(max_pieces - pieces_used, 0)
	var grade := GameData.grade_for(failed_attempts, spare)
	var info: Dictionary = GameData.GRADES[grade]
	var wage := GameData.wage_for(day, grade, spare)
	money += wage + trophy_bonus
	earned += wage + trophy_bonus
	var rows: Array = [["PIECES LEFT", str(spare)], ["PIECES LOST", str(failed_attempts)]]
	if trophy_bonus > 0:
		rows.append(["TROPHY BONUS", "+$%d" % trophy_bonus])
	rows.append(["WAGE", "$%d" % wage])
	rows.append(["CASH", "$%d" % money])
	var new_best := false
	if not overtime:   # OVERTIME ไม่จดเกรดรายวัน (ใช้สถิติจำนวนกะแทน)
		var had_record: bool = Settings.best_grades[day - 1] != -1
		new_best = Settings.record_grade(day, grade) and had_record
	await review.show_review({
		"title": ("SHIFT %d COMPLETE" % _shift()) if overtime else ("DAY %d COMPLETE" % day),
		"grade": info.id,
		"color": info.color,
		"new_best": new_best,
		"rows": rows,
		"boss": Dialogue.GRADE_LINES[info.id].pick_random(),
	})
	return grade


# ฉากจบหลังผ่านวันสุดท้าย: corrupt = จ่ายสินบนมาก ("The Company Owns You" ตาแดง) / ไม่งั้นฉาก "You Are the Boss Now"
func _play_ending(corrupt: bool, flow: int) -> void:
	var lines: Array = Dialogue.ENDING_CORRUPT if corrupt else Dialogue.ENDING
	await dialogue.say(_lines(lines, {"bribes": bribes_used, "paid": bribe_paid_total}))
	if flow != _flow_id:
		return
	await _ending_cinematic(corrupt)
	if flow != _flow_id:
		return
	Settings.night_shift = true
	Settings.record_ending("corrupt" if corrupt else "boss")   # บันทึกลงไฟล์ด้วย
	var head := "THE COMPANY OWNS YOU" if corrupt else "SHIFT COMPLETE"
	var extra := "BRIBES PAID: %d ($%d)\n" % [bribes_used, bribe_paid_total] if corrupt else ""
	_show_screen("%s\n%sTRASH STACKED: %d\nTOTAL EARNED: $%d\n\nclick to return to title" % [head, extra, score, earned])
	state = State.ENDING


# ฉากจบ: จอมืดสนิท มีแต่ตาของผู้เล่นเรืองขึ้นกลางความมืด (boss หายไปแล้ว)
func _ending_cinematic(corrupt := false) -> void:
	screen_fx.set_eye_color(GameData.SUSPICION_COLORS[2 if corrupt else 0])   # ติดสินบน = ตาแดง
	sfx.play("ending")
	sfx.set_loop("ambient", false)
	await screen_fx.fade_to_black(1.8)
	await screen_fx.show_eyes(true, 1.0)
	await get_tree().create_timer(3.5).timeout
	screen_fx.clear(0.8)
	sfx.set_loop("ambient", true, -10.0)


# กลับหน้าแรกแบบจอมืด (จากหน้าโดนไล่ออก / ฉากจบ / เมนู pause)
func _go_title() -> void:
	var flow := _flow_id   # /day ตัดกลางคัน → coroutine นี้เลิกเองหลัง await (ดู _debug_day)
	state = State.DIALOGUE   # กันคลิกระหว่างจอมืด
	await screen_fx.cover()
	if flow != _flow_id:
		return
	dialogue.hide_comment()
	_show_title()
	await screen_fx.uncover()
	if flow != _flow_id:
		return


func _show_title() -> void:
	state = State.TITLE
	_reset_time()
	modifiers.stop()
	sfx.set_loop("rain", false)
	for b in blocks_root.get_children():
		b.queue_free()
	current = null
	tower_top = TITLE_PILE_TOP
	camera.zoom = 1.0   # หน้า title ใช้มุมกล้องมาตรฐานเสมอ
	score_label.hide()
	game_over_label.hide()
	title_menu.open()
	_spawn_title_pile.call_deferred()   # รอให้ชิ้นเก่าถูกลบเสร็จก่อน ไม่ให้ซ้อนทับกัน


# กองตัวอย่างหน้า title: ปล่อยจากที่สูงทีละชั้น (ไม่มีใครถือ ไม่นับคะแนน) ให้ฟิสิกส์จัดกองเอง
func _spawn_title_pile() -> void:
	if state != State.TITLE:
		return
	var y := guide.pad_top + 1.0
	for e in TITLE_PILE:
		var blk := Block.spawn(e[0])
		blk.position = Vector3(e[1], y, e[2])
		blocks_root.add_child(blk)
		blk.release()
		y += 1.5


func _show_screen(text: String) -> void:
	game_over_label.text = text
	game_over_label.show()
	_screen_at_msec = Time.get_ticks_msec()


func _screen_ready() -> bool:
	return (Time.get_ticks_msec() - _screen_at_msec) / 1000.0 >= RESTART_DELAY


# ---------- คำสั่งนักพัฒนา (DevConsole) ----------

# /day N — เริ่มรอบใหม่ที่วัน N ทันที (ตัดบทพูด/จอมืด/pause ที่ค้างอยู่ทิ้ง)
func _debug_day(args: PackedStringArray) -> String:
	if args.is_empty() or not args[0].is_valid_int():
		return "Usage: /day N"
	var n := args[0].to_int()
	if n < 1 or n > GameData.DAYS.size():
		return "Day must be 1-%d" % GameData.DAYS.size()
	_flow_id += 1
	pause_menu.set_paused(false)
	dialogue.abort()
	review.abort()
	item_choice.abort()
	shop.abort()
	screen_fx.clear(0.01)   # เผื่อกำลังอยู่ในฉากจบ (จอมืด + ตา)
	sfx.set_loop("ambient", true, -10.0)
	_reset_time()
	overtime = false
	day = n
	score = 0
	money = 0
	earned = 0
	bribes_used = 0
	bribe_paid_total = 0
	_set_suspicion(0)
	items.reset_run()
	_start_day()
	return "Starting day %d" % n


# /overtime [N] — เริ่มโหมด OVERTIME ที่กะ N ทันที (ไม่ต้องปลดล็อก)
func _debug_overtime(args: PackedStringArray) -> String:
	var n := args[0].to_int() if not args.is_empty() and args[0].is_valid_int() else 1
	n = maxi(n, 1)
	_flow_id += 1
	pause_menu.set_paused(false)
	dialogue.abort()
	review.abort()
	item_choice.abort()
	shop.abort()
	screen_fx.clear(0.01)
	sfx.set_loop("ambient", true, -10.0)
	_reset_time()
	overtime = true
	day = GameData.DAYS.size() + n
	score = 0
	money = 0
	earned = 0
	bribes_used = 0
	bribe_paid_total = 0
	_set_suspicion(0)
	items.reset_run()
	_start_day()
	return "Starting overtime shift %d" % n


# /ending corrupt|boss — เล่นฉากจบทันที (ไว้ทดสอบบท/สีตา โดยไม่ต้องเล่นครบ 5 วัน)
func _debug_ending(args: PackedStringArray) -> String:
	var corrupt := not args.is_empty() and args[0] == "corrupt"
	_flow_id += 1
	pause_menu.set_paused(false)
	dialogue.abort()
	review.abort()
	item_choice.abort()
	shop.abort()
	screen_fx.clear(0.01)
	_reset_time()
	title_menu.close()
	game_over_label.hide()
	overtime = false
	day = GameData.DAYS.size()
	state = State.DIALOGUE
	if corrupt and bribes_used < GameData.CORRUPT_ENDING_BRIBES:
		bribes_used = 3
		bribe_paid_total = maxi(bribe_paid_total, 1750)
	_play_ending(corrupt, _flow_id)
	return "Playing ending: %s" % ("corrupt" if corrupt else "boss")


# ตั้งความระแวง (0-100) แล้วเปลี่ยนสีตา boss ตามระดับ (บทพูด + ตาในฉากจบ)
func _set_suspicion(value: int) -> void:
	suspicion = clampi(value, 0, 100)
	var color: Color = GameData.SUSPICION_COLORS[GameData.suspicion_level(suspicion)]
	dialogue.set_eye_color(color)
	screen_fx.set_eye_color(color)


# /suspicion N — ตั้งความระแวงของ boss (ไว้ทดสอบตาเปลี่ยนสี / โดนตรวจ)
func _debug_suspicion(args: PackedStringArray) -> String:
	if args.is_empty() or not args[0].is_valid_int():
		return "Usage: /suspicion N"
	_set_suspicion(args[0].to_int())
	return "Suspicion: %d (level %d)" % [suspicion, GameData.suspicion_level(suspicion)]


# /money N — ตั้งเงินในกระเป๋า (ไว้ทดสอบร้านของ boss / สินบน)
func _debug_money(args: PackedStringArray) -> String:
	if args.is_empty() or not args[0].is_valid_int():
		return "Usage: /money N"
	money = maxi(args[0].to_int(), 0)
	return "Cash: $%d" % money


# /give <item|all> — ใส่ item เข้าคลัง (เต็ม MAX_SLOTS แล้วหยุด)
func _debug_give(args: PackedStringArray) -> String:
	if args.is_empty():
		return "Usage: /give <item|all>\nItems: %s" % ", ".join(ItemData.ITEMS.keys())
	var ids: Array = ItemData.ITEMS.keys() if args[0] == "all" else [args[0].to_lower()]
	var added: Array[String] = []
	for id in ids:
		if not ItemData.ITEMS.has(id):
			return "Unknown item: %s" % id
		if items.give(id):
			added.append(id)
	return "Added: %s" % (", ".join(added) if not added.is_empty() else "nothing (slots full)")


# ---------- ชิ้นขยะ ----------

# ชิ้นนี้ตกขอบแท่นแล้วไหม: จุดศูนย์กลางออกนอกแท่น (X/Z) และต่ำกว่าผิวแท่น / ชิ้นที่เกยขอบแต่ยังอยู่เหนือผิวแท่นไม่นับ
func _fell_off(b: Node3D) -> bool:
	var p := b.global_position
	if p.y < KILL_Y:
		return true
	var half := ground.size.x * 0.5
	var outside := absf(p.x) > half or absf(p.z) > half
	return outside and p.y < ground.position.y + ground.size.y * 0.5

# นับชิ้นที่เสีย 1 ชิ้น (หลุดขอบ / ไม่ได้อยู่บนกอง) / Insurance ช่วยได้ทั้งสองแบบ
# คืน true ถ้าจบวันแล้ว (โดนไล่ออก) ผู้เรียกต้อง return ทันที
# fragile = ชิ้นที่เสียเป็นของเปราะ (ทีวี) → โดนไล่ออกทันที (Insurance ช่วยได้เหมือนกัน)
func _register_fail(key: String, fragile := false) -> bool:
	camera.shake(0.45)
	if items.consume_insurance():
		sfx.play("insured")
		_comment("insured")   # ประกันจ่าย: ชิ้นนี้ไม่นับว่าเสีย (ยังนับเป็นชิ้นที่ใช้ไปแล้ว)
		return false
	screen_fx.flash(Color(0.8, 0.05, 0.05), 0.3)
	sfx.play("fail")
	if fragile:
		_end_day(false, "fragile")
		return true
	failed_attempts += 1
	update_ui()
	if failed_attempts >= GameData.MAX_FAILS:
		_end_day(false, "fails")
		return true
	var tutorial_key := "tutorial_" + key
	_comment(tutorial_key if _is_tutorial() and Dialogue.COMMENTS.has(tutorial_key) else key)
	return false


# กองล้ม: ชิ้นเก่าที่เคยนิ่งบนกองแต่ตอนนี้ไปนอนพื้น (ที่ไม่ใช่ฐาน) = เสียชิ้นนั้น นับทีละชิ้น
# (ชิ้นที่ล้มตกขอบไปเลยถูกนับโดยลูป _fell_off() อยู่แล้ว) / คืน true ถ้าจบวันแล้ว
func _check_collapse() -> bool:
	if stack_base != null and not is_instance_valid(stack_base):
		stack_base = null   # ฐานหลุดขอบไปแล้ว
	var ground_top := ground.position.y + ground.size.y * 0.5
	var removed := false
	for b in blocks_root.get_children():
		var blk := b as Block
		if blk == null or blk == current or blk == stack_base or not blk.settled or blk.is_queued_for_deletion():
			continue
		if blk.rests_on_ground(ground_top):
			blk.queue_free()   # ลบออกจากฉากเหมือนชิ้นที่หลุดขอบ
			removed = true
			if _register_fail("collapse", blk.fragile):
				return true
	if removed:
		recalc_tower_top()   # ยอดกองลดลงตามที่ล้ม
		update_ui()
	return false


# ชิ้นที่เพิ่งนิ่งแตะพื้นอยู่ ทั้งที่มีกองอยู่แล้ว (มีชิ้นอื่นนิ่งอยู่) = ไม่ได้วางบนกอง
# ชิ้นแรกของวัน (ฐาน) ได้รับการยกเว้น เพราะยังไม่มีกองให้วาง
func _is_off_stack(blk: Block) -> bool:
	var ground_top := ground.position.y + ground.size.y * 0.5
	if not blk.rests_on_ground(ground_top):
		return false
	return _has_settled_piece(blk)


func _has_settled_piece(except: Block) -> bool:
	for b in blocks_root.get_children():
		var o := b as Block
		if o and o != except and o.released and o.settled and not o.is_queued_for_deletion():
			return true
	return false

# ไปชิ้นถัดไปถ้ายังมีของเหลือ ไม่งั้นใช้ของครบแล้วยังไม่ถึงโควต้า = แพ้
func _advance_or_end() -> void:
	if pieces_used >= max_pieces:
		_end_day(false, "pieces")
	else:
		spawn_block()


func spawn_block() -> void:
	pieces_used += 1
	_make_current(Vector3(0, tower_top + HOLD_GAP, 0))
	state = State.HOLDING
	update_ui()


# สร้างชิ้นที่ถือจากถุง / ตั้งตำแหน่งก่อน add_child ไม่ให้ชิ้นเทเลพอร์ตจาก (0,0,0) ขึ้นมา (blocks_root อยู่ที่จุดกำเนิด)
func _make_current(pos: Vector3) -> void:
	# ยังไม่มีกอง (ชิ้นแรกของวัน หรือฐานหลุดไปแล้ว) = ชิ้นนี้จะเป็นฐาน → ข้ามชนิดที่เป็นฐานไม่ได้ (ถ้วยทอง ถังน้ำ ท่อ)
	var kind := bag.next() if _has_settled_piece(null) else bag.next_excluding(GameData.BAD_BASE_KINDS)
	current = Block.spawn(kind)
	current.position = pos
	blocks_root.add_child(current)
	_hold_basis = Basis.IDENTITY
	_strain = 0.0
	_strain_phase = Vector4(randf(), randf(), randf(), randf()) * TAU
	current.hit.connect(_on_hit.bind(current))
	sfx.play("clunk", -6.0)
	if current.fragile and not _fragile_said:
		_fragile_said = true
		_comment("fragile", true)


# Item: Swap Bag — เปลี่ยนชิ้นที่ถือเป็นชิ้นอื่น (ไม่นับเป็นชิ้นที่ใช้เพิ่ม) / คืนชิ้นเดิมกลับถุง
func swap_current() -> bool:
	if state != State.HOLDING or current == null:
		return false
	var old := current
	bag.give_back(old.kind)
	old.queue_free()
	_make_current(old.position)
	return true


# ชิ้นกระแทก: เสียงตามแรง / ถ้าหนักพอ (HARD_IMPACT) สั่นจอ + ฝุ่นฟุ้งที่จุดชน
func _on_hit(impact: float, blk: Block) -> void:
	if impact >= HARD_IMPACT:
		sfx.play("impact_heavy", linear_to_db(clampf(impact / 20.0, 0.4, 1.0)), randf_range(0.9, 1.1))
		camera.shake(clampf(impact / 40.0, 0.12, 0.5))
		Effects.puff(self, blk.global_position + Vector3(0, -0.3, 0))
	else:
		sfx.play("impact_light", linear_to_db(clampf(impact / 10.0, 0.25, 1.0)), randf_range(0.9, 1.15))


func _on_item_slot(index: int) -> void:
	sfx.play("ui_click")
	items.use_slot(index)


# เสียงตัวปรับของวัน: เตือนก่อน แล้วเสียงลม/ครืนตอนเกิดจริง
func _on_modifier_phase(kind: String, phase: int) -> void:
	if phase == DayModifiers.Phase.WARN:
		sfx.play("warn")
	elif phase == DayModifiers.Phase.ACTIVE:
		sfx.play("buzz" if kind == "blackout" else ("wind" if kind == "wind" else "rumble"))


# มอเตอร์เครนดังตามความเร็วที่ขยับชิ้นที่ถืออยู่ (และตอนลากหมุนกล้อง)
func _update_motor(holding: bool, delta: float) -> void:
	var speed := 0.0
	if holding and current != null:
		speed = current.global_position.distance_to(_last_hold_pos) / maxf(delta, 0.0001)
		_last_hold_pos = current.global_position
	if camera.dragging:
		speed = maxf(speed, 4.0)
	_motor = lerpf(_motor, clampf(speed / 8.0, 0.0, 1.0), 1.0 - exp(-8.0 * delta))
	sfx.set_loop_level("motor", _motor * 0.6 if _motor > 0.03 else 0.0, 0.5)


# คืนเวลาเป็นปกติ + ล้างผลกาแฟ (เรียกเมื่อชิ้นนิ่ง / จบวัน / ชิ้นหลุด)
func _reset_time() -> void:
	Engine.time_scale = 1.0
	items.coffee_pending = false


func move_held_block(delta: float) -> void:
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var dir := camera.project_ray_normal(mouse)
	var hold_y := tower_top + HOLD_GAP
	var hit = Plane(Vector3.UP, hold_y).intersects_ray(origin, dir)
	if hit == null:
		return
	var p: Vector3 = hit
	# เมาส์เลยระยะเอื้อมของเครน → ชิ้นแกว่ง (ขอบ/มุมจะได้ไม่เป็นจุดตรึงที่ซ้อนตรงเป๊ะทุกครั้ง)
	var out := absf(p.x) > BOUND or absf(p.z) > BOUND
	_strain = lerpf(_strain, 1.0 if out else 0.0, 1.0 - exp(-STRAIN_RATE * delta))
	_strain_time += delta
	# sine 2 ความถี่ต่อแกน (ไม่เป็นพหุคูณกัน) → แกว่งแบบเครนตึง จับจังหวะปล่อยให้ตรงเป๊ะไม่ได้
	var sway := Vector2(
		sin(_strain_time * 3.1 + _strain_phase.x) + 0.5 * sin(_strain_time * 7.3 + _strain_phase.y),
		sin(_strain_time * 2.7 + _strain_phase.z) + 0.5 * sin(_strain_time * 6.1 + _strain_phase.w)
	) * (STRAIN_AMP / 1.5 * _strain)
	# ตั้งทั้ง transform (ทิศ + ตำแหน่ง) ไม่ใช่แค่ global_position ไม่งั้นทิศที่หมุนไว้ถูกทับกลับเป็นเดิมทุกเฟรม
	# offset แกว่งบวกหลัง clamp (ไม่ clamp ซ้ำ ไม่งั้นครึ่งหนึ่งของการแกว่งถูกตัดกลับมาที่ขอบพอดี)
	current.global_transform = Transform3D(_hold_basis, Vector3(
		clampf(p.x, -BOUND, BOUND) + sway.x,
		hold_y,
		clampf(p.z, -BOUND, BOUND) + sway.y
	))


func recalc_tower_top() -> void:
	var top := 0.0
	for b in blocks_root.get_children():
		var blk := b as Block
		if blk and blk.released and blk.settled and not blk.is_queued_for_deletion():
			top = maxf(top, blk.top_y())
	tower_top = top


# ---------- boss คอมเมนต์ระหว่างวัน ----------

func _is_tutorial() -> bool:
	return _cur_day.get("tutorial", false)


# เช็คกองล้ม / ใกล้ถึงโควต้า หลังชิ้นล่าสุดนิ่ง
# ข้อความเด้งเหนือชิ้นที่เพิ่งนิ่ง: ความสูงที่เพิ่ม / สถิติใหม่ / ใกล้ถึง / ถึงโควต้า (เรียกก่อน _comment_on_progress ที่อัปเดต best_height)
func _popup_progress(prev_top: float) -> void:
	var at := current.global_position + Vector3(0.0, 1.0, 0.0)
	var reached := tower_top >= quota_height
	var near_line := quota_height - GameData.NEAR_QUOTA
	var gain := tower_top - maxf(prev_top, guide.pad_top)
	if reached:
		Effects.popup(self, at, "QUOTA!", QuotaMarker.GREEN)
	elif tower_top >= near_line and prev_top < near_line:
		Effects.popup(self, at, "ALMOST!", QuotaMarker.YELLOW)
	elif best_height > 0.0 and tower_top > best_height + 0.05:
		Effects.popup(self, at, "NEW BEST!", Color(1.0, 1.0, 1.0))
	elif gain >= 0.2:
		Effects.popup(self, at, "+%.1f m" % gain, Color(0.92, 0.9, 0.78))


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


# force = ข้าม cooldown (ใช้กับคำเตือนสำคัญ เช่นทีวีเปราะ)
func _comment(key: String, force := false) -> void:
	var now := Time.get_ticks_msec()
	if dialogue.is_busy() or (now < _comment_ready_at and not force):
		return
	_comment_ready_at = now + int(GameData.COMMENT_COOLDOWN * 1000.0)
	var pool: Array = Dialogue.COMMENTS[key]
	dialogue.comment(_lines([pool.pick_random()])[0])


# แทนตัวแปร {quota} ฯลฯ ในบทพูด / extra = ตัวแปรเพิ่มเฉพาะที่ (เช่น {items})
func _lines(lines: Array, extra := {}) -> Array:
	var vars := {
		"day": day,
		"shift": _shift(),
		"days": GameData.DAYS.size(),
		"quota": "%.1f" % _shown_height(quota_height),
		"pieces": max_pieces,
		"height": "%.1f" % _shown_height(tower_top),
		"fails": failed_attempts,
		"max_fails": GameData.MAX_FAILS,
	}
	vars.merge(extra)
	return Dialogue.fmt(lines, vars)


# บทพูดต้นวัน: DAY_INTRO + คำอธิบายตัวปรับของวัน + ขยะพิเศษที่เริ่มมีวันนี้
# เลขกะของโหมด OVERTIME (1, 2, 3...) / โหมดปกติคืนเลขวัน
func _shift() -> int:
	return day - GameData.DAYS.size() if overtime else day


func _intro_lines() -> Array:
	var lines: Array
	if overtime:
		lines = Dialogue.OVERTIME_FIRST.duplicate() if _shift() == 1 else Dialogue.OVERTIME_INTRO.pick_random().duplicate()
	else:
		lines = Dialogue.DAY_INTRO[day].duplicate()
		if day == 1 and Settings.night_shift:
			lines[0] = Dialogue.NIGHT_FIRST_LINE
	for m in _cur_day.get("modifiers", []):
		lines.append_array(Dialogue.MODIFIER_INTRO.get(m, []))
	for kind in GameData.KIND_FIRST_DAY:
		if GameData.KIND_FIRST_DAY[kind] == day:
			lines.append_array(Dialogue.KIND_INTRO.get(kind, []))
	return lines


# ส่งสถานะ item ไปแถบ UI (ข้ามเองถ้าไม่มีอะไรเปลี่ยน)
func _refresh_items() -> void:
	var playing := state == State.HOLDING or state == State.WAITING
	item_bar.visible = playing
	if not playing:
		return

	var parts: Array[String] = []
	if items.coffee_pending:
		parts.append("COFFEE: SLOW-MO" if state == State.WAITING else "COFFEE READY")
	if items.insurance > 0:
		parts.append("INSURED x%d" % items.insurance)
	var weather := modifiers.status_text(camera.yaw)
	if weather != "":
		parts.append(weather)
	if state == State.HOLDING and current != null:
		if _strain > 0.5:
			parts.append("OUT OF REACH")
		if current.fragile:
			parts.append("FRAGILE!")
		elif current.slippery:
			parts.append("SLIPPERY")
		elif current.bouncy:
			parts.append("BOUNCY")

	var next_text := ""
	if items.clipboard_left > 0:
		var names: Array[String] = []
		for k in bag.peek(items.clipboard_left):
			names.append(Block.KIND_NAMES[k])
		next_text = "NEXT:\n" + "\n".join(names)

	item_bar.refresh(items.inventory, state == State.HOLDING, "  ".join(parts), next_text)


# ความสูงที่โชว์ผู้เล่น = นับจากผิวแท่น (ค่าภายใน tower_top / quota_height เป็นพิกัดโลก แท่นอยู่ที่ y ≈ 1.2)
func _shown_height(world_y: float) -> float:
	return maxf(world_y - guide.pad_top, 0.0)


func update_ui() -> void:
	var day_text := "SHIFT: %d" % _shift() if overtime else "DAY: %d/%d" % [day, GameData.DAYS.size()]
	score_label.text = "%s\nTRASH: %d\nHEIGHT: %.1f / %.1f m\nFAILS: %d/%d\nPIECES: %d/%d" % [
		day_text, score, _shown_height(tower_top), _shown_height(quota_height),
		failed_attempts, GameData.MAX_FAILS, pieces_used, max_pieces
	]
	var today := modifiers.label_text()
	if today != "":
		score_label.text += "\nTODAY: " + today
