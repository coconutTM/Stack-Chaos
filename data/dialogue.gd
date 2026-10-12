class_name Dialogue
extends RefCounted

# บทพูดทั้งหมดของ boss (ภาษาอังกฤษ เพราะฟอนต์ไม่มีอักษรไทย) / แก้บทที่นี่ที่เดียว
# ตัวแปรในข้อความใช้ได้: {day} {days} {quota} {pieces} {height} {fails} {max_fails} {items}

# ตอนต้นวัน (สั่งงาน) — วันที่ 1 เป็น tutorial
const DAY_INTRO := {
	1: [
		"You're the new hire. Good. Sit.",
		"That's your crane. Move the mouse to carry the trash. Left click to drop it.",
		"Right click spins a piece. Shift and right click flips it on its side. Scroll the wheel to zoom.",
		"Hold right click and drag to look around the pile.",
		"The white circle shows where it will land. A red circle means it's headed off the platform.",
		"Stack to {quota} meters with {pieces} pieces. Every piece must land on the pile.",
		"Lose {max_fails} pieces, over the edge or left on the floor, and you're done. If the pile falls, every piece that falls counts.",
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
	"blackout": ["The power's unreliable tonight. When the lights die, trust the circle on the floor."],
	"fog": ["Fog tonight. You won't see the top of the pile. Watch the meter."],
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
	Block.Kind.GOLD_TROPHY: ["A gold trophy in the pile! Keep it on the stack and I'll pay a bonus."],
	Block.Kind.MATTRESS: ["Mattresses. Light, flat and bouncy. Don't drop it from too high."],
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

# คำพูดสั้นๆ ของ boss บนหน้าสรุปผลงานท้ายวัน ตามเกรด (สุ่มหนึ่งบรรทัด)
const GRADE_LINES := {
	"S": ["Flawless. I almost smiled.", "Not a single piece wasted. Remarkable.", "Perfect. Don't let it go to your head."],
	"A": ["Good work.", "Solid. Almost perfect.", "I've seen worse. Much worse."],
	"B": ["Acceptable. Barely.", "It stood. That's something.", "You can do better. I know you can."],
	"C": ["That was too close.", "You used every last piece. Careless.", "It counts. Don't make it a habit."],
}

# โหมด OVERTIME: กะแรก (ตัวแปร {shift} = เลขกะ) / กะถัดๆ ไปสุ่มหนึ่งชุด / ท้ายกะสุ่มหนึ่งชุด
const OVERTIME_FIRST := [
	"Five days done. Most people quit by now.",
	"This is overtime. There's no last day. The quota only goes up.",
	"Lose control of the pile and it ends. Let's see how long you last.",
	"{quota} meters. {pieces} pieces.",
]
const OVERTIME_INTRO := [
	["Shift {shift}. Still here.", "{quota} meters. {pieces} pieces."],
	["Shift {shift}. The pile doesn't care how tired you are.", "{quota} meters. {pieces} pieces."],
	["Shift {shift}. Nobody's counting. Except me.", "{quota} meters. {pieces} pieces."],
]
const OVERTIME_PASS := [
	["{height} meters.", "Again."],
	["{height} meters. Don't slow down.", "Next shift."],
	["{height} meters. Barely a scratch.", "Keep going."],
]

# boss ให้เลือกรางวัล item (เกรด A ขึ้นไป) — สุ่มหนึ่งบรรทัด
const REWARD_LINES := ["Take one. You earned it.", "Pick your reward.", "Good work deserves a tool. Choose.", "Don't waste it."]

# ร้านของ boss (หลังสรุปผลงานท้ายวัน ใช้เงินซื้อ item) — สุ่มหนึ่งบรรทัด
const SHOP_OPEN := ["Spend it if you like. Or save it. You may need it.", "My stock. Not cheap.", "Cash only. No refunds."]
const SHOP_BUY := ["Good choice.", "Pleasure.", "That one's useful."]
const SHOP_BROKE := ["You can't afford that.", "Come back with more.", "Not enough."]
const SHOP_FULL := ["Your hands are full.", "No room. Use something first."]

# สินบน: โดนไล่ออกแล้วมีเงินพอ boss เสนอให้เล่นวันนั้นใหม่ (ตัวแปร {cost}) — สุ่มหนึ่งบรรทัด
const BRIBE_OFFER := [
	"I could forget this happened. For ${cost}.",
	"Walls have ears. Mine are for sale. ${cost}.",
	"${cost}, and the day starts over. Between us.",
]
const BRIBE_PAID := ["Pleasure doing business.", "Same day. Same quota. Don't waste it."]

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
