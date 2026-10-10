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
		"The white circle shows where it will land. A red line means it's headed for the pit.",
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
	"Trash belongs on the pile. Not in the pit. Not on the floor.",
	"You're fired.",
]
const FIRED_PIECES := [
	"Out of trash. Only {height} meters.",
	"The quota was {quota}.",
	"You're fired.",
]

# ฉากจบหลังผ่านวันสุดท้าย
const ENDING := [
	"Five days. Not one pile of trash fell on my watch.",
	"You see, the pile was never meant to be finished.",
	"Go home. Rest.",
	"Tomorrow, we begin again.",
]

# คอมเมนต์ระหว่างวัน (สุ่มหนึ่งบรรทัดจากแต่ละหมวด)
const COMMENTS := {
	"tutorial_drop": ["Let it settle. Patience.", "Wait for it to stop moving."],
	"tutorial_fail": ["That one's gone. Careful with the edge."],
	"tutorial_off_stack": ["On the floor doesn't count. It has to stay on the pile."],
	"off_stack": ["That's the floor, not the pile.", "Trash on the floor? Really?", "Land it on the stack."],
	"fail": ["There goes another one.", "Watch the edge.", "Was that on purpose?"],
	"collapse": ["The whole pile just moved.", "Hm. It's falling apart.", "Is that what you call stacking?", "Everything that fell counts. Everything."],
	"insured": ["Covered. This time.", "The company pays for that one. Once."],
	"near": ["Almost there.", "A little more.", "Don't blow it now."],
}


# แทนค่าตัวแปร {name} ในทุกบรรทัด
static func fmt(lines: Array, vars: Dictionary) -> Array:
	var out: Array = []
	for line in lines:
		out.append(String(line).format(vars))
	return out
