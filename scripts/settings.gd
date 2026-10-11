class_name Settings
extends RefCounted

# ค่าที่จำข้ามการเปิดเกม (user://settings.cfg — บนเว็บเก็บใน storage ของเบราว์เซอร์)

const PATH := "user://settings.cfg"

static var muted := false
static var night_shift := false   # เคยจบเกมครบ 5 วันแล้ว (ตอน title/บทพูดวันแรกเปลี่ยนไปนิดหน่อย)
static var best_overtime := 0       # กะ OVERTIME ที่ผ่านได้มากสุดในรอบเดียว
static var best_grades: Array = [-1, -1, -1, -1, -1]   # เกรดดีสุดของแต่ละวัน (index ใน GameData.GRADES, 0 = S, -1 = ยังไม่เคยผ่าน)


static func load_all() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	muted = cfg.get_value("audio", "muted", false)
	night_shift = cfg.get_value("progress", "night_shift", false)
	best_overtime = cfg.get_value("progress", "best_overtime", 0)
	var saved: Variant = cfg.get_value("progress", "best_grades", best_grades)
	if saved is Array and saved.size() == best_grades.size():
		best_grades = saved


static func save_all() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "muted", muted)
	cfg.set_value("progress", "night_shift", night_shift)
	cfg.set_value("progress", "best_grades", best_grades)
	cfg.set_value("progress", "best_overtime", best_overtime)
	cfg.save(PATH)


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
