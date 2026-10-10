class_name BlockModels
extends RefCounted

# โมเดล .glb ของบล็อกขยะแต่ละชนิด (ไม่บังคับ) — วางไฟล์ที่ assets/models/blocks/<file>.glb แล้วบล็อกชนิดนั้นใช้โมเดลทันที
# ไม่มีไฟล์ = ใช้ primitive เดิมใน .tscn / กล่องชนยังเป็นรูปเดิมจาก .tscn เสมอ (ฟิสิกส์ไม่เปลี่ยน) โมเดลถูกย่อ/ขยายให้พอดีกล่องชน
#   file       = ชื่อไฟล์ใน DIR (ไม่ต้องใส่ .glb) หรือ path เต็ม "res://..." (โมเดลที่ใช้ palette ของแพ็กอื่น เช่น assets/models/yard/)
#   rot        = หมุนโมเดลก่อนวัดขนาด (องศา x/y/z) ใช้แก้โมเดลที่หันผิดแกน เช่น ท่อที่นอนอยู่ → Vector3(0, 0, 90)
#   keep_ratio = true: ย่อขยายเท่ากันทุกแกน (ไม่บิดสัดส่วน อาจเล็กกว่ากล่องชนบางด้าน) / false: ยืดให้พอดีกล่องชนทุกแกน
#   tint       = คูณสีทั้งโมเดล ใช้โมเดลเดียวกันได้หลายชนิด (ถังน้ำมัน = ถังสีเขียว, ลังเหล็ก = เครื่องอบผ้าสีเหล็ก)
# โมเดลปัจจุบันเป็นของ Kenney (CC0) ดู assets/models/CREDITS.md / tire, cylinder ยังไม่มีโมเดลที่เข้ากัน → primitive

const DIR := "res://assets/models/blocks/"

const MODELS := {
	Block.Kind.CRATE: {"file": "crate"},
	Block.Kind.PLANK: {"file": "plank"},
	Block.Kind.FRIDGE: {"file": "fridge"},
	Block.Kind.BARREL: {"file": "barrel"},
	Block.Kind.TIRE: {"file": "tire"},
	Block.Kind.SQUARE: {"file": "square"},
	Block.Kind.CYLINDER: {"file": "cylinder"},
	Block.Kind.OIL_BARREL: {"file": "barrel", "tint": Color(0.45, 0.85, 0.4)},
	Block.Kind.TV: {"file": "tv"},
	Block.Kind.STEEL_CRATE: {"file": "steel_crate", "tint": Color(0.36, 0.4, 0.46)},   # เครื่องอบผ้าทาสีเหล็ก
	Block.Kind.CARDBOARD_BOX: {"file": "cardboard_box"},
	Block.Kind.TRASH_BIN: {"file": "trash_bin"},
	Block.Kind.BUCKET: {"file": "bucket"},
	Block.Kind.TOILET: {"file": "toilet"},
	Block.Kind.SOFA: {"file": "sofa"},
}


# path ของไฟล์โมเดลของชนิดนี้ / "" ถ้าไม่ได้กำหนดหรือยังไม่มีไฟล์
static func path(kind: int) -> String:
	if not MODELS.has(kind):
		return ""
	var file: String = MODELS[kind].file
	var p := (file if file.begins_with("res://") else DIR + file) + ".glb"
	return p if ResourceLoader.exists(p) else ""


static func rotation(kind: int) -> Vector3:
	return MODELS.get(kind, {}).get("rot", Vector3.ZERO)


static func keep_ratio(kind: int) -> bool:
	return MODELS.get(kind, {}).get("keep_ratio", false)


static func tint(kind: int) -> Color:
	return MODELS.get(kind, {}).get("tint", Color.WHITE)
