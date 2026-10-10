class_name PieceBag
extends RefCounted

# สุ่มชนิดขยะแบบ "ถุง": ใส่ครบทุกชนิดอย่างละชิ้น สลับแล้วหยิบทีละชิ้น หมดค่อยเติมใหม่
# → ไม่ซ้ำเกินไป และได้ครบทุกชนิดสม่ำเสมอ

var _kinds: Array[int] = []   # ชนิดที่อยู่ในถุง (เปลี่ยนตามวัน ดู GameData.kinds_for_day)
var _bag: Array[int] = []
var _last := -1


func _init(kinds: Array[int] = []) -> void:
	_kinds = kinds


func next() -> int:
	if _bag.is_empty():
		_refill()
	_last = _bag.pop_back()
	return _last


# ดูล่วงหน้า n ชิ้นถัดไป (ตามลำดับที่จะหยิบ) โดยไม่หยิบออก / ถุงสั้นไปก็เติมชุดใหม่ต่อท้ายคิว
func peek(n: int) -> Array[int]:
	while _bag.size() < n:
		_refill()
	var out: Array[int] = []
	for i in n:
		out.append(_bag[_bag.size() - 1 - i])
	return out


# คืนชิ้นที่ถืออยู่กลับถุง (ไปอยู่ปลายคิว จะถูกหยิบเป็นชิ้นสุดท้าย) — ใช้กับ Swap Bag
func give_back(kind: int) -> void:
	_bag.insert(0, kind)


# เติมชุดใหม่ (ทุกชนิดอย่างละชิ้น สลับ) ไว้ "หลัง" คิวเดิม คือใส่ที่ต้นอาร์เรย์ (หยิบจากท้าย)
func _refill() -> void:
	var fresh: Array[int] = []
	fresh.append_array(_kinds)
	fresh.shuffle()
	# ชิ้นแรกของชุดใหม่ (ท้ายอาร์เรย์) ต้องไม่ซ้ำกับชิ้นสุดท้ายของคิวเดิม
	var prev: int = _bag[0] if not _bag.is_empty() else _last
	if fresh.size() > 1 and fresh.back() == prev:
		var tmp: int = fresh[0]
		fresh[0] = fresh.back()
		fresh[fresh.size() - 1] = tmp
	fresh.append_array(_bag)
	_bag = fresh
