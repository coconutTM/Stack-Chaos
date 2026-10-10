class_name Dialogue
extends RefCounted

# บทพูดทั้งหมดของ boss (ภาษาอังกฤษ เพราะฟอนต์ไม่มีอักษรไทย) / แก้บทที่นี่ที่เดียว
# ตัวแปรในข้อความใช้ได้: {day} {days} {quota} {pieces} {height} {fails} {max_fails} {items}

# ตอนต้นวัน (สั่งงาน) — วันที่ 1 เป็น tutorial
const DAY_INTRO := {
	1: [
		"You're the new hire. Good. Sit.",
		"That's your crane. Move the mouse to carry the trash. Left click to drop it.",
		"Right click flips a piece on its side. Scroll the wheel to spin it.",
		"Hold right click and drag to look around the pile.",
		"The white circle shows where it will land. A red circle means it's headed off the platform.",
		"Stack to {quota} meters with {pieces} pieces. Every piece must land on the pile.",
		"Lose {max_fails} pieces, over the edge or left on the floor, and you're done. If the pile falls, every piece that falls counts.",
		"The circle turns red when a piece would hit the floor.",
		"Don't disappoint me.",
	],
	2: [
		"Day {day}. You're still here.",
		"Quota is {quota} meters. {pieces} pieces.",
		"Higher this time.",
	],
	3: [
		"Day {day}. Management is watching.",
		"{quota} meters. {pieces} pieces.",
		"I don't repeat myself.",
	],
	4: [
		"Day {day}. Some of the others didn't make it this far.",
		"{quota} meters. {pieces} pieces. Don't make me look bad.",
	],
	5: [
		"Last day.",
		"{quota} meters. {pieces} pieces.",
		"Do this and you'll see what the job really is.",
	],
}

# ตัวปรับของวัน (ต่อท้าย DAY_INTRO ของวันที่มีตัวปรับนั้น)
const MODIFIER_INTRO := {
	"wind": ["Wind today. It comes in gusts. Watch the warning on the screen."],
	"rain": ["Rain. Everything's slick today. Slower hands."],
	"shake": ["The ground shakes from time to time. Hold your pile together."],
}

# ขยะพิเศษ (ต่อท้าย DAY_INTRO ในวันแรกที่ชนิดนั้นเริ่มมี)
const KIND_INTRO := {
	Block.Kind.OIL_BARREL: ["New arrivals: oil barrels. They're slick. They slide."],
	Block.Kind.STEEL_CRATE: ["Steel crates too. Heavy. Great at the bottom. Terrible if you drop one."],
	Block.Kind.CAR: ["Scrap cars now. Low, wide, heavy. Flat roofs make decent shelves."],
	Block.Kind.TV: ["Some TVs in the mix. Fragile. Lose one and you're fired. No exceptions."],
	Block.Kind.TRASH_BIN: ["Trash bins. Yes, we throw away the trash cans too. Round. They roll."],
	Block.Kind.SOFA: ["Somebody dumped a sofa. Long and flat. Use it as a floor."],
	Block.Kind.BUCKET: ["Buckets. Small, light, round. Annoying. Like you."],
	Block.Kind.TOILET: ["Toilets. Don't ask where they came from. Odd shape, heavy base."],
}

# แจก item ต้นวัน (หลัง DAY_INTRO) — วันที่ 1 มีสอนใช้ / {items} = ชื่อ item ที่ได้
const ITEM_GIVE_FIRST := [
	"Here. Two tools of the trade: {items}.",
	"Click an item on the bar below to use it. Point at it to read what it does.",
	"Use them well. I don't hand out many.",
]
const ITEM_GIVE := [
	"Supplies: {items}.",
]
const ITEM_FULL := [
	"Your bag is full. I'll keep the rest.",
]

# ท้ายวัน — ผ่าน (วันที่ 5 ตามด้วย ENDING)
const DAY_PASS := {
	1: ["{height} meters. Acceptable.", "Come back tomorrow."],
	2: ["{height} meters. Not bad for a rookie.", "Same time tomorrow."],
	3: ["{height} meters. You're getting the hang of it.", "Don't get comfortable."],
	4: ["{height} meters. Impressive.", "One more day."],
	5: ["{height} meters.", "...Well done."],
}

# ท้ายวัน — โดนไล่ออก (แยกสาเหตุ)
const FIRED_FAILS := [
	"You lost {fails} pieces.",
	"Trash belongs on the pile. Not off the platform. Not on the floor.",
	"You're fired.",
]
const FIRED_FRAGILE := [
	"You broke it.",
	"That was company property.",
	"You're fired.",
]
const FIRED_PIECES := [
	"Out of trash. Only {height} meters.",
	"The quota was {quota}.",
	"You're fired.",
]

# ฉากจบหลังผ่านวันสุดท้าย (เฉลย: boss ไม่มีตัวตน เป็นแค่ "งาน" ที่ส่งต่อให้คนถัดไป)
# บรรทัดเป็น String หรือ {"text": ..., "portrait": ...} / portrait: "normal" | "empty" (เงาตัวหายเหลือแต่ตา) | "eyes_turn" (ตาหันมามอง)
const ENDING := [
	"Five days. Not one pile of trash fell on my watch.",
	"You have a talent. I had it once.",
	"I'm retiring. Tonight.",
	{"text": "Look at me. Go on.", "portrait": "empty"},
	"There is no one here. There never was. Only the job.",
	{"text": "Your shadow suits you.", "portrait": "eyes_turn"},
]

# ผ่านเกมแล้วเริ่มรอบใหม่ (Settings.night_shift): แทนบรรทัดแรกของวันที่ 1
const NIGHT_FIRST_LINE := "You're back. Good. Sit. The night shift is yours."


# คอมเมนต์ระหว่างวัน (สุ่มหนึ่งบรรทัดจากแต่ละหมวด)
const COMMENTS := {
	"tutorial_drop": ["Let it settle. Patience.", "Wait for it to stop moving."],
	"tutorial_fail": ["That one's gone. Careful with the edge."],
	"tutorial_off_stack": ["On the floor doesn't count. It has to stay on the pile."],
	"off_stack": ["That's the floor, not the pile.", "Trash on the floor? Really?", "Land it on the stack."],
	"fail": ["There goes another one.", "Watch the edge.", "Was that on purpose?"],
	"collapse": ["The whole pile just moved.", "Hm. It's falling apart.", "Is that what you call stacking?", "Everything that fell counts. Everything."],
	"fragile": ["Careful with that one. Fragile.", "That is a TV. Do not drop it."],
	"insured": ["Covered. This time.", "The company pays for that one. Once."],
	"near": ["Almost there.", "A little more.", "Don't blow it now."],
}


# แทนค่าตัวแปร {name} ในทุกบรรทัด
static func fmt(lines: Array, vars: Dictionary) -> Array:
	var out: Array = []
	for line in lines:
		if line is Dictionary:
			var copy: Dictionary = line.duplicate()
			copy.text = String(line.text).format(vars)
			out.append(copy)
		else:
			out.append(String(line).format(vars))
	return out
