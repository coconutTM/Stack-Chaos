class_name ItemData
extends RefCounted

# ข้อมูล item ทั้งหมด (แก้ความน่าจะเป็น/ข้อความที่นี่) / ผล (effect) เขียนเป็นเมธอด _use_<id>() ใน scripts/item_system.gd
# เพิ่ม item ใหม่ = เพิ่ม entry ตรงนี้ + เพิ่มเมธอด _use_<id>() (คืน true ถ้าใช้สำเร็จ) ไม่ต้องแก้ที่อื่น

const MAX_SLOTS := 6        # เก็บได้สูงสุดกี่ช่อง
const GIVE_PER_DAY := 2     # boss แจกกี่ชิ้นตอนเริ่มวัน

# name = ชื่อเต็ม, short = ชื่อบนปุ่ม, weight = น้ำหนักความน่าจะเป็น (สัมพัทธ์), fail = ข้อความตอนใช้ไม่ได้
const ITEMS := {
	"duct_tape": {
		"name": "DUCT TAPE", "short": "TAPE", "weight": 3, "color": Color(0.8, 0.8, 0.85),
		"desc": "Glue the last settled piece to the pile for good.",
		"fail": "Nothing to tape yet.",
	},
	"coffee": {
		"name": "COFFEE", "short": "COFFEE", "weight": 3, "color": Color(0.7, 0.45, 0.25),
		"desc": "Time runs at half speed while the next piece falls.",
		"fail": "You're already wired.",
	},
	"swap_bag": {
		"name": "SWAP BAG", "short": "SWAP", "weight": 3, "color": Color(0.4, 0.7, 0.9),
		"desc": "Swap the piece you're holding for a different one.",
		"fail": "Can't swap right now.",
	},
	"counterweight": {
		"name": "COUNTERWEIGHT", "short": "WEIGHT", "weight": 2, "color": Color(0.9, 0.5, 0.15),
		"desc": "The piece you're holding gets 3x heavier.",
		"fail": "Already heavy.",
	},
	"clipboard": {
		"name": "CLIPBOARD", "short": "CLIP", "weight": 2, "color": Color(0.9, 0.85, 0.5),
		"desc": "See the next 3 pieces for the rest of the day.",
		"fail": "You already have the list.",
	},
	"insurance": {
		"name": "INSURANCE", "short": "INSURE", "weight": 2, "color": Color(0.5, 0.85, 0.5),
		"desc": "Forgives one piece lost over the edge.",
		"fail": "You're already covered.",
	},
}


# สุ่ม id ของ item ตามน้ำหนัก
static func roll() -> String:
	var total := 0.0
	for id in ITEMS:
		total += float(ITEMS[id].weight)
	var r := randf() * total
	for id in ITEMS:
		r -= float(ITEMS[id].weight)
		if r <= 0.0:
			return id
	return ITEMS.keys()[0]
