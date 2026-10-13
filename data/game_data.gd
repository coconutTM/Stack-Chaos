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
# sway = เครนส่ายตลอดทั้งวัน (เมตร, แอมพลิจูดของชิ้นที่ถือ) / เมาส์เลยขอบจะแกว่งแรงกว่านี้ (STRAIN_AMP ใน main.gd) ใช้ค่าที่มากกว่า
const DAYS := [
	{"height": 4.0, "pieces": 8, "sway": 0.05, "tutorial": true},
	{"height": 5.5, "pieces": 9, "sway": 0.08},
	{"height": 7.0, "pieces": 10, "sway": 0.12, "modifiers": ["wind"]},
	{"height": 8.5, "pieces": 11, "sway": 0.14, "modifiers": ["rain"]},
	{"height": 10.0, "pieces": 12, "sway": 0.17, "modifiers": ["wind", "shake"]},
]

# ตัวปรับของวัน (ค่าจูน) — interval = ช่วงเวลาสุ่มระหว่างครั้ง (วินาที) / warn = เตือนก่อนกี่วินาที
# wind: force = แรงผลัก (นิวตัน) ชิ้นที่ยังไม่นิ่ง (กำลังตก) โดนเต็มแรง / ชิ้นที่นิ่งแล้วโดนแค่ settled_mult เท่า (กองไม่ล้มเพราะลมเอง)
#       max_accel = ความเร่งสูงสุด (ม./วินาที²) แรงจริง = min(force, มวล x max_accel) กันชิ้นเบาปลิว
#       (ไม้กระดานบนพื้นเริ่มไถลที่ราว 7 N) / rain: friction = ค่าเสียดทานของบล็อกทั่วไปตอนฝนตก
# shake: accel = ความเร่งสั่นแนวราบ (คูณมวล ทุกชิ้นสั่นเท่ากัน)
const MODIFIERS := {
	"wind": {"label": "WIND", "interval": Vector2(10.0, 16.0), "warn": 3.0, "duration": 1.0, "force": 6.0,
		"settled_mult": 0.3, "max_accel": 4.0},
	"rain": {"label": "RAIN", "friction": 0.35},
	"shake": {"label": "QUAKE", "interval": Vector2(8.0, 14.0), "warn": 1.5, "duration": 2.0, "accel": 3.5},
	# blackout: ไฟกะพริบ (warn) แล้วดับ (duration) เป็นระยะ เหลือแต่ไฟเติมจางๆ + ambient จางลงเป็น ambient_min เท่า
	"blackout": {"label": "BLACKOUT", "interval": Vector2(12.0, 18.0), "warn": 1.5, "duration": 2.5, "ambient_min": 0.35},
	# fog: หมอกหนาทั้งวัน (fog_density x density_mult) มองยอดกองไม่ชัด ดูจากแถบความสูงแทน
	"fog": {"label": "FOG", "density_mult": 2.5},
}

# เกรดท้ายวัน (เฉพาะวันที่ผ่าน) ตัดสินจากชิ้นที่เสีย (fails) และชิ้นที่เหลือไม่ได้ใช้ (spare = pieces - ชิ้นที่ใช้ไป)
# เรียงจากดีสุด ตัวแรกที่เข้าเงื่อนไขชนะ (ตัวสุดท้ายต้องรับทุกกรณี) / bonus = โบนัสเงินของเกรดนั้น
const GRADES := [
	{"id": "S", "max_fails": 0, "min_spare": 3, "bonus": 60, "color": Color(1.0, 0.85, 0.2)},
	{"id": "A", "max_fails": 1, "min_spare": 1, "bonus": 30, "color": Color(0.4, 1.0, 0.45)},
	{"id": "B", "max_fails": 2, "min_spare": 1, "bonus": 10, "color": Color(0.55, 0.75, 1.0)},
	{"id": "C", "max_fails": 99, "min_spare": 0, "bonus": 0, "color": Color(0.75, 0.75, 0.75)},
]
const REWARD_MAX_GRADE := 1   # ได้เกรด A (index 1) หรือดีกว่า → boss ให้เลือกรางวัล item 1 ใน 3 ก่อนขึ้นวันใหม่
const TROPHY_BONUS := 40      # โบนัสเงินเมื่อ GOLD TROPHY วางนิ่งบนกองได้ (ต่อชิ้น)
const WAGE_BASE := 60        # ค่าแรงวันที่ 1
const WAGE_PER_DAY := 15      # ค่าแรงเพิ่มต่อวัน
const WAGE_PER_SPARE := 10    # เงินพิเศษต่อชิ้นที่เหลือ
const BRIBE_BASE := 250        # สินบนครั้งแรกของรอบ (โดนไล่ออกแล้วจ่ายเพื่อเล่นวันนั้นใหม่) / ครั้งต่อไปคูณสอง


# คืน index ใน GRADES (0 = ดีสุด)
static func grade_for(fails: int, spare: int) -> int:
	for i in GRADES.size():
		var g: Dictionary = GRADES[i]
		if fails <= int(g.max_fails) and spare >= int(g.min_spare):
			return i
	return GRADES.size() - 1


# ฉากจบพิเศษ "The Company Owns You": ผ่านวันสุดท้ายโดยจ่ายสินบนในรอบนั้นอย่างน้อยเท่านี้ครั้ง
const CORRUPT_ENDING_BRIBES := 2
const ENDING_COUNT := 2           # จำนวนฉากจบทั้งหมด (boss, corrupt) ไว้โชว์ ENDINGS x/2 บนหน้า title

# ความระแวงของ boss (0-100): จ่ายสินบนเพิ่ม / ผ่านวันโดยไม่ติดสินบนลด / ถึง SUSPICION_AUDIT = ต้นวันถัดไปโดนตรวจ (ยึดเงิน + วันนั้นไม่รับสินบน)
const SUSPICION_PER_BRIBE := 35
const SUSPICION_DECAY := 10
const SUSPICION_WARY := 35        # ระดับ 1 (ตาส้ม บทพูดเปลี่ยน)
const SUSPICION_PARANOID := 70    # ระดับ 2 (ตาแดง)
const SUSPICION_AUDIT := 100
const SUSPICION_COLORS := [Color(1.0, 0.85, 0.2), Color(1.0, 0.55, 0.15), Color(1.0, 0.2, 0.15)]   # สีตา boss ตามระดับ
const AUDIT_KEEP := 0.5           # โดนตรวจแล้วเหลือเงินกี่เท่า
const AUDIT_RESET := 50           # หลังโดนตรวจ ความระแวงเหลือเท่านี้


# ระดับความระแวง: 0 = calm, 1 = wary, 2 = paranoid
static func suspicion_level(s: int) -> int:
	if s >= SUSPICION_PARANOID:
		return 2
	if s >= SUSPICION_WARY:
		return 1
	return 0


# ราคาสินบนครั้งที่ used + 1 ของรอบ (250 → 500 → 1000 ...)
static func bribe_cost(used: int) -> int:
	return BRIBE_BASE * (1 << used)


# เงินเดือนของวันนั้น = ค่าแรงตามวัน + ชิ้นที่เหลือ + โบนัสเกรด
static func wage_for(day: int, grade: int, spare: int) -> int:
	return WAGE_BASE + WAGE_PER_DAY * (day - 1) + WAGE_PER_SPARE * maxi(spare, 0) + int(GRADES[grade].bonus)


# โหมด OVERTIME (ไม่มีที่สิ้นสุด ปลดล็อกหลังจบ 5 วัน): กะที่ n (1, 2, 3...) สร้างข้อมูลวันแบบเดียวกับ DAYS
# โควต้าเพิ่ม OVERTIME_HEIGHT_STEP ต่อกะ + ชิ้นเพิ่ม OVERTIME_PIECE_STEP (สัดส่วนเดียวกับวันที่ 5) / ตัวปรับสุ่มจาก OVERTIME_MODIFIERS
const OVERTIME_HEIGHT_BASE := 10.0
const OVERTIME_HEIGHT_STEP := 1.5
const OVERTIME_PIECES_BASE := 12
const OVERTIME_PIECE_STEP := 2
const OVERTIME_SWAY_BASE := 0.17   # เครนส่ายของกะแรก = วันที่ 5 / เพิ่มต่อกะ / เพดาน
const OVERTIME_SWAY_STEP := 0.015
const OVERTIME_SWAY_MAX := 0.25
const OVERTIME_MODIFIERS := ["wind", "rain", "shake", "blackout", "fog"]


static func overtime_day(n: int) -> Dictionary:
	var pool := OVERTIME_MODIFIERS.duplicate()
	pool.shuffle()
	var count := mini(1 if n < 4 else 2, pool.size())   # กะ 1-3 ตัวปรับ 1 อย่าง / กะ 4+ สองอย่าง
	return {
		"height": OVERTIME_HEIGHT_BASE + OVERTIME_HEIGHT_STEP * n,
		"pieces": OVERTIME_PIECES_BASE + OVERTIME_PIECE_STEP * n,
		"sway": minf(OVERTIME_SWAY_BASE + OVERTIME_SWAY_STEP * n, OVERTIME_SWAY_MAX),
		"modifiers": pool.slice(0, count),
	}


# ชนิดที่ห้ามเป็นฐานกอง (ชิ้นแรกตอนยังไม่มีกอง): เล็ก/กลม ชิ้นต่อไปไถลตกหมดจนวันนั้นแทบเล่นไม่ได้
const BAD_BASE_KINDS := [Block.Kind.GOLD_TROPHY, Block.Kind.BUCKET, Block.Kind.CYLINDER]


# ขยะพิเศษ: วันแรกที่เริ่มมีในถุง (ชนิดที่ไม่ได้ระบุ = มีตั้งแต่วันที่ 1)
const KIND_FIRST_DAY := {
	Block.Kind.OIL_BARREL: 2,
	Block.Kind.STEEL_CRATE: 2,
	Block.Kind.CAR: 2,
	Block.Kind.TV: 3,
	Block.Kind.TRASH_BIN: 2,
	Block.Kind.SOFA: 2,
	Block.Kind.BUCKET: 3,
	Block.Kind.TOILET: 4,
	Block.Kind.GOLD_TROPHY: 2,
	Block.Kind.MATTRESS: 3,
}


# ชนิดขยะที่อยู่ในถุงของวันนี้
static func kinds_for_day(day: int) -> Array[int]:
	var out: Array[int] = []
	for kind in Block.KIND_COUNT:
		if int(KIND_FIRST_DAY.get(kind, 1)) <= day:
			out.append(kind)
	return out
