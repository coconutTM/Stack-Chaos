class_name PieceBag
extends RefCounted

# สุ่มชนิดขยะแบบ "ถุง": ใส่ครบทุกชนิดอย่างละชิ้น สลับแล้วหยิบทีละชิ้น หมดค่อยเติมใหม่
# → ไม่ซ้ำเกินไป และได้ครบทุกชนิดสม่ำเสมอ

var _bag: Array[int] = []
var _last := -1


func next() -> int:
	if _bag.is_empty():
		_refill()
	_last = _bag.pop_back()
	return _last


func _refill() -> void:
	for kind in Block.KIND_COUNT:
		_bag.append(kind)
	_bag.shuffle()
	# ชิ้นแรกของถุงใหม่ (หยิบจากท้าย) ต้องไม่ซ้ำกับชิ้นสุดท้ายที่เพิ่งหยิบ
	if _bag.size() > 1 and _bag.back() == _last:
		var tmp: int = _bag[0]
		_bag[0] = _bag.back()
		_bag[_bag.size() - 1] = tmp
