class_name Settings
extends RefCounted

# ค่าที่จำข้ามการเปิดเกม (user://settings.cfg — บนเว็บเก็บใน storage ของเบราว์เซอร์)

const PATH := "user://settings.cfg"

static var muted := false
static var night_shift := false   # เคยจบเกมครบ 5 วันแล้ว (ตอน title/บทพูดวันแรกเปลี่ยนไปนิดหน่อย)


static func load_all() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	muted = cfg.get_value("audio", "muted", false)
	night_shift = cfg.get_value("progress", "night_shift", false)


static func save_all() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "muted", muted)
	cfg.set_value("progress", "night_shift", night_shift)
	cfg.save(PATH)
