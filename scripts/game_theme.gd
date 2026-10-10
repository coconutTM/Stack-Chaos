class_name GameTheme
extends RefCounted

# ใส่ฟอนต์ pixel ให้ UI ทั้งเกม: ถ้ามี res://fonts/pixel.ttf (หรือ .otf) จะใช้เป็นฟอนต์เริ่มต้นของทุก Control (ผ่าน default theme)
# ตอนนี้ใช้ Press Start 2P (SIL OFL — ดู fonts/OFL.txt) / เปลี่ยนฟอนต์ = ทับไฟล์ pixel.ttf
# ฟอนต์ pixel คมสุดเมื่อขนาดเป็นพหุคูณของขนาดต้นแบบ (Press Start 2P = 8: ใช้ 8 / 16 / 24) — ขนาดอื่นตัวอักษรจะเพี้ยน

const CANDIDATES := ["res://fonts/pixel.ttf", "res://fonts/pixel.otf"]


static func apply(_window: Window = null) -> void:
	for path in CANDIDATES:
		if not ResourceLoader.exists(path):
			continue
		var font := load(path) as FontFile
		if font == null:
			continue
		font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		font.hinting = TextServer.HINTING_NONE
		font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		# ตั้งที่ default theme ของโปรเจกต์ (Window.theme ไม่ส่งผ่าน CanvasLayer ลงไปถึง Control ใน UI ของเรา)
		ThemeDB.get_default_theme().default_font = font
		return
