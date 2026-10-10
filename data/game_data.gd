class_name GameData
extends RefCounted

# ค่าที่ต้องจูนของระบบวัน/โควต้า รวมไว้ที่เดียว (แก้ที่นี่ ไม่ต้องไปแก้ main.gd)
# ความสูงเป็นพิกัดโลก (y) ไม่ใช่ความสูงเหนือพื้น: พื้นอยู่ที่ y ≈ 1.2 ดังนั้นกองสูง 3 เมตรจริงๆ ≈ 4.2

const MAX_FAILS := 3          # หลุดกองครบกี่ชิ้นในวันเดียว = โดนไล่ออก
const COLLAPSE_DROP := 1.0    # ยอดกองต่ำลงเกินนี้ (เมตร) จากสูงสุดของวัน = ถือว่ากองล้ม boss คอมเมนต์
const NEAR_QUOTA := 1.0       # ห่างโควต้าไม่เกินนี้ (เมตร) = boss คอมเมนต์ว่าใกล้แล้ว
const COMMENT_COOLDOWN := 6.0 # boss คอมเมนต์ระหว่างวันถี่สุดทุกกี่วินาที

# height = โควต้าความสูง, pieces = จำนวนชิ้นที่ให้ใช้ (นับทุกชิ้นที่ spawn แม้จะหลุด)
# tutorial = true เปิดคอมเมนต์สอนเล่นระหว่างวัน (วันที่ 1)
# modifiers = ตัวปรับของวัน (ดู MODIFIERS ด้านล่าง) ใส่ได้หลายอัน
const DAYS := [
	{"height": 4.0, "pieces": 8, "tutorial": true},
	{"height": 5.5, "pieces": 9},
	{"height": 7.0, "pieces": 10, "modifiers": ["wind"]},
	{"height": 8.5, "pieces": 11, "modifiers": ["rain"]},
	{"height": 10.0, "pieces": 12, "modifiers": ["wind", "shake"]},
]

# ตัวปรับของวัน (ค่าจูน) — interval = ช่วงเวลาสุ่มระหว่างครั้ง (วินาที) / warn = เตือนก่อนกี่วินาที
# wind: force = แรงผลัก (นิวตัน คงที่ ไม่คูณมวล ชิ้นเบาจึงโดนหนัก; ไม้กระดานบนพื้นเริ่มไถลที่ราว 7 N: 6.0 = ไม่ขยับ, 7.5 = ขยับ ~0.5 ม., 9.0 = ไถล ~2.7 ม.) / rain: friction = ค่าเสียดทานของบล็อกทั่วไปตอนฝนตก
# shake: accel = ความเร่งสั่นแนวราบ (คูณมวล ทุกชิ้นสั่นเท่ากัน)
const MODIFIERS := {
	"wind": {"label": "WIND", "interval": Vector2(7.0, 12.0), "warn": 2.0, "duration": 1.5, "force": 7.5},
	"rain": {"label": "RAIN", "friction": 0.35},
	"shake": {"label": "QUAKE", "interval": Vector2(8.0, 14.0), "warn": 1.5, "duration": 2.0, "accel": 3.5},
}

# ขยะพิเศษ: วันแรกที่เริ่มมีในถุง (ชนิดที่ไม่ได้ระบุ = มีตั้งแต่วันที่ 1)
const KIND_FIRST_DAY := {
	Block.Kind.OIL_BARREL: 2,
	Block.Kind.STEEL_CRATE: 2,
	Block.Kind.TV: 3,
}


# ชนิดขยะที่อยู่ในถุงของวันนี้
static func kinds_for_day(day: int) -> Array[int]:
	var out: Array[int] = []
	for kind in Block.KIND_COUNT:
		if int(KIND_FIRST_DAY.get(kind, 1)) <= day:
			out.append(kind)
	return out
