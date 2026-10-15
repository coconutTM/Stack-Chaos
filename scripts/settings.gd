class_name Settings
extends RefCounted

# ค่าที่จำข้ามการเปิดเกม (user://settings.cfg — บนเว็บเก็บใน storage ของเบราว์เซอร์)

const PATH := "user://settings.cfg"

static var muted := false
static var volume := 1.0          # ความดังรวม 0-1 (ตั้งในหน้า SETTINGS) / muted คือปุ่ม SND ON/OFF แยกกัน
static var camera_sens := 1.0     # ความไวตอนลากหมุนกล้อง (คูณ OrbitCamera.DRAG_SENS) 0.5-2.0
static var text_speed := 1.0       # ความเร็วพิมพ์ตัวอักษรของ boss (คูณ DialogueBox.CHARS_PER_SEC) 0.5-3.0
static var retro_look := true     # true = dither + vertex snapping แบบ PS1 / false = ปิด (เครื่องช้า/เว็บ) ภาพคมขึ้นและเบาลง
static var night_shift := false   # เคยจบเกมครบ 5 วันแล้ว (ตอน title/บทพูดวันแรกเปลี่ยนไปนิดหน่อย)
static var best_overtime := 0       # กะ OVERTIME ที่ผ่านได้มากสุดในรอบเดียว
static var endings_seen: Array = []   # id ฉากจบที่เคยดู ("boss", "corrupt")
static var best_grades: Array = [-1, -1, -1, -1, -1]   # เกรดดีสุดของแต่ละวัน (index ใน GameData.GRADES, 0 = S, -1 = ยังไม่เคยผ่าน)
static var touch := false         # โหมดสัมผัส (มือถือ/แท็บเล็ต): ลากเล็ง + ปุ่ม DROP + สองนิ้วหมุน/ซูมกล้อง / ไม่บันทึกลง cfg


# ข้อความที่โชว์ผู้เล่น: โหมดสัมผัสเปลี่ยนคำว่า click เป็น tap
static func wording(text: String) -> String:
	return text.replace("click", "tap") if touch else text


# เดาว่าเป็นมือถือจากแพลตฟอร์มของเบราว์เซอร์ (ไม่ชัวร์ก็รอจับการแตะจอครั้งแรกใน main._input)
static func detect_touch() -> void:
	touch = OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android") or OS.has_feature("ios")


static func load_all() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	muted = cfg.get_value("audio", "muted", false)
	volume = clampf(float(cfg.get_value("audio", "volume", 1.0)), 0.0, 1.0)
	camera_sens = clampf(float(cfg.get_value("controls", "camera_sens", 1.0)), 0.5, 2.0)
	text_speed = clampf(float(cfg.get_value("controls", "text_speed", 1.0)), 0.5, 3.0)
	retro_look = bool(cfg.get_value("graphics", "retro_look", true))
	night_shift = cfg.get_value("progress", "night_shift", false)
	best_overtime = cfg.get_value("progress", "best_overtime", 0)
	var seen: Variant = cfg.get_value("progress", "endings_seen", [])
	if seen is Array:
		endings_seen = seen
	if night_shift and not endings_seen.has("boss"):
		endings_seen.append("boss")   # เซฟเก่าก่อนมีรายการฉากจบ: เคยจบแล้ว = ดูฉากหลักแล้ว
	var saved: Variant = cfg.get_value("progress", "best_grades", best_grades)
	if saved is Array and saved.size() == best_grades.size():
		best_grades = saved


static func save_all() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "muted", muted)
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("controls", "camera_sens", camera_sens)
	cfg.set_value("controls", "text_speed", text_speed)
	cfg.set_value("graphics", "retro_look", retro_look)
	cfg.set_value("progress", "night_shift", night_shift)
	cfg.set_value("progress", "best_grades", best_grades)
	cfg.set_value("progress", "best_overtime", best_overtime)
	cfg.set_value("progress", "endings_seen", endings_seen)
	cfg.save(PATH)


# ใช้ค่าความดังกับ bus หลัก (เรียกตอนเปิดเกมและตอนเลื่อนสไลเดอร์) / ปุ่ม mute ใช้ set_bus_mute แยก (ดู SoundToggle)
static func apply_audio() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, muted)


# จดว่าเคยดูฉากจบนี้แล้ว (บันทึกทันที)
static func record_ending(id: String) -> void:
	if not endings_seen.has(id):
		endings_seen.append(id)
	save_all()


# จดเกรดของวันนั้นถ้าดีกว่าที่เคยได้ / คืน true ถ้าเป็นสถิติใหม่
static func record_grade(day: int, grade: int) -> bool:
	var i := day - 1
	if i < 0 or i >= best_grades.size():
		return false
	var old: int = best_grades[i]
	if old != -1 and old <= grade:
		return false
	best_grades[i] = grade
	save_all()
	return true
