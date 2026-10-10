class_name ItemSystem
extends RefCounted

# คลังไอเท็มของผู้เล่น + ผลของแต่ละ item / ข้อมูล item อยู่ใน data/items.gd
# game = main.gd (ใช้ duck typing: current, last_settled, bag, state, dialogue ฯลฯ)

signal changed
signal used(ok: bool)   # ใช้ item เสร็จ (ok = ใช้สำเร็จ) ไว้เล่นเสียง

var inventory: Array[String] = []
var clipboard := false        # เห็น 3 ชิ้นถัดไป (รีเซ็ตทุกวัน)
var coffee_pending := false   # กาแฟพร้อมใช้กับชิ้นถัดไปที่ปล่อย (รีเซ็ตทุกวัน)
var insurance := 0            # จำนวนครั้งที่ยกเว้นการหลุดขอบ (ค้างข้ามวันจนกว่าจะถูกใช้ รีเซ็ตทุกรอบ)

var game


func _init(main) -> void:
	game = main


func reset_run() -> void:
	inventory.clear()
	insurance = 0
	reset_day()


func reset_day() -> void:
	clipboard = false
	coffee_pending = false
	changed.emit()


# แจก item สุ่มตอนต้นวัน / คืน {"names": [ชื่อที่ได้], "overflow": จำนวนที่ล้นช่อง}
func grant_daily() -> Dictionary:
	var names: Array[String] = []
	var overflow := 0
	for i in ItemData.GIVE_PER_DAY:
		var id := ItemData.roll()
		if inventory.size() >= ItemData.MAX_SLOTS:
			overflow += 1
		else:
			inventory.append(id)
			names.append(ItemData.ITEMS[id].name)
	changed.emit()
	return {"names": names, "overflow": overflow}


# ใช้ item ในช่องที่ index / ผลเป็นเมธอด _use_<id>() (คืน true = ใช้สำเร็จและหมดไป)
func use_slot(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var id := inventory[index]
	var method := "_use_" + id
	if not has_method(method):
		push_warning("Item '%s' has no %s()" % [id, method])
		return
	if call(method):
		inventory.remove_at(index)
		changed.emit()
		used.emit(true)
	else:
		game.dialogue.comment(ItemData.ITEMS[id].fail)
		used.emit(false)


# ถูกเรียกตอนมีชิ้นหลุดขอบ: ถ้ามีประกันก็ใช้ 1 ครั้งแล้วคืน true (ไม่นับว่าหลุด)
func consume_insurance() -> bool:
	if insurance <= 0:
		return false
	insurance -= 1
	changed.emit()
	return true


# ---------- ผลของแต่ละ item ----------

func _use_duct_tape() -> bool:
	var b: Block = game.last_settled
	if b == null or not is_instance_valid(b) or b.taped:
		return false
	b.weld()
	return true


func _use_coffee() -> bool:
	if coffee_pending:
		return false
	coffee_pending = true
	return true


func _use_swap_bag() -> bool:
	return game.swap_current()


func _use_counterweight() -> bool:
	var cur: Block = game.current
	if cur == null or cur.weighted:
		return false
	cur.add_counterweight(3.0)
	return true


func _use_clipboard() -> bool:
	if clipboard:
		return false
	clipboard = true
	return true


func _use_insurance() -> bool:
	if insurance > 0:
		return false
	insurance += 1
	return true
