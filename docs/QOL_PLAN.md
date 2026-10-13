# Quality of life ชุด 1 — hints, auto-pause, คีย์ลัด, เตือนชิ้นสุดท้าย, settings เพิ่ม

## Context
ผู้ใช้อยากให้เกมเล่นสบายขึ้น จึงสำรวจโค้ดแล้วพบช่องว่างหลายจุด และผู้ใช้เลือก 5 ข้อด้านล่าง
(ไม่ทำ: fast-forward ตอนรอ, retry day, landing ghost)
- ระหว่างเล่นไม่มีคำแนะนำปุ่มเลย และ HOW TO PLAY ไม่ได้บอก Q/E/R, คลิกกลาง, item, ทีวีเปราะ, วงแดง
- บนเว็บถ้าคลิกออกนอกเกม/สลับแท็บ เกมยังวิ่งต่อ (ไม่มี `_notification` ที่ไหนเลย)
- ทุกหน้าต้องใช้เมาส์อย่างเดียว (ยกเว้น Esc/P/Q/E/R) / กล้องหมุนเพี้ยนแล้วไม่มีปุ่มคืน
- ชิ้นใกล้หมดไม่มีอะไรเตือน (HUD มีแค่ `PIECES: x/y`)
- SETTINGS ไม่มีความเร็วตัวอักษร / ไม่มี fullscreen

ทุกข้อเป็นอิสระกัน ทำ/ทดสอบทีละข้อได้ (ทำตามลำดับด้านล่าง) / string ที่โชว์ผู้เล่นเป็นอังกฤษ คอมเมนต์ไทย ขนาดฟอนต์ 8/16

---

## 1. Control hints ระหว่างเล่น + HOW TO PLAY ครบขึ้น

**`scripts/item_bar.gd`**
- เพิ่ม `var _controls: Label` สร้างใน `_ready()` วางมุม**ซ้ายล่าง**ข้างแถบ item (แถบกว้าง 248 px อยู่กลางจอ 426 → ซ้ายเหลือ ~85 px):
  anchor ซ้ายล่าง, `offset_left 4`, `offset_right 86`, `offset_top -46`, `offset_bottom -4`, `font_size` 8, outline ดำ 4 แบบเดียวกับ `_info`,
  `modulate.a 0.7`, `mouse_filter IGNORE`
- ข้อความ (≤ 10 ตัวอักษรต่อบรรทัด ให้พอดี 85 px): `"Q/E  SPIN\nR    FLIP\nRDRAG LOOK\nC    CAMERA"`
- เมธอด `set_hints(on: bool)` → `_controls.visible = on`

**`scripts/main.gd`**
- const `HINT_DROPS := 8` (โชว์คำแนะนำจนกว่าจะปล่อยชิ้นครบกี่ครั้ง นับตั้งแต่เปิดเกม)
- var `_drops := 0` — เพิ่ม 1 ในกิ่ง `MOUSE_BUTTON_LEFT` ของ `_unhandled_input` (ที่ `current.release()`)
- ใน `_refresh_items()` หลังเช็ค `playing`: `item_bar.set_hints(state == State.HOLDING and _drops < HINT_DROPS)`

**`scripts/title_menu.gd` `HOW_TO_LINES`** — เขียนใหม่ (ระวังความสูงหน้าจอ 240 px ถ้าล้นให้ตัดบรรทัดว่าง):
```
Mouse: move the piece
Left click: drop it
Right click / Q / E: spin 45 degrees
Shift+right click / R: flip it
Right drag: look around / C: reset view
Wheel: zoom   P / Esc: pause
Click an item slot to use it
Red guide = it will land off the pile
TVs are fragile. Break one, you're fired.

Reach the quota height before
you run out of pieces.
Lose 3 pieces and you're fired.
```

## 2. Auto-pause เมื่อเกมเสียโฟกัส

**`scripts/pause_menu.gd`** (เป็น `PROCESS_MODE_ALWAYS` อยู่แล้ว)
```gdscript
func _notification(what: int) -> void:
	# คลิกออกนอกเกม / สลับแท็บ (เว็บ) / สลับหน้าต่าง → หยุดเกมให้เอง (เล่นต่อเองไม่ได้ ต้องกด RESUME)
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if not get_tree().paused and can_pause.is_valid() and can_pause.call():
			set_paused(true)
```
- ไม่ auto-resume ตอนได้โฟกัสคืน (ผู้เล่นต้องกด RESUME / Esc เอง)

## 3. คีย์ลัด

| คีย์ | ที่ไหน | ผล | แก้ที่ |
| --- | --- | --- | --- |
| Space / Enter / KP Enter | boss พูด (บล็อก) | เหมือนคลิกซ้าย (`_advance()`) | `DialogueBox._unhandled_input` เพิ่มกิ่ง key + `set_input_as_handled()` |
| Space / Enter | หน้าสรุปผลงาน | เหมือนคลิกซ้าย | `ReviewScreen._unhandled_input` — แยก logic คลิกเป็น `_confirm()` แล้วเรียกจากทั้งเมาส์และคีย์ |
| Space / Enter | หน้า FIRED / ENDING | กลับหน้าแรก (เช็ค `_screen_ready()`) | `main._unhandled_input` กิ่ง `InputEventKey` (ตอนนี้ `return` ทุกกรณีที่ไม่ใช่ HOLDING) |
| 1 / 2 / 3 … | การ์ดเลือกรางวัล + ข้อเสนอสินบน (PAY / WALK AWAY) | เลือกใบที่ n | `ItemChoice` (ดูด้านล่าง) |
| C | HOLDING / WAITING | คืนมุมกล้อง | `OrbitCamera` (ดูด้านล่าง) |

- ใช้ `physical_keycode` สำหรับตัวอักษร/ตัวเลข (คีย์บอร์ดไทยยังใช้ได้ ตาม convention ใน `main._unhandled_input`) / Space, Enter ใช้ `keycode` ได้
- ทุกจุดเช็ค `pressed and not echo`
- **`scripts/item_choice.gd`**: เก็บ `var _ids: Array = []` ใน `offer()` (ลำดับเดียวกับการ์ด) / `_hint.text = hint + "  (1-%d)" % cards.size()` /
  เพิ่ม `_unhandled_input`: ถ้า `_open` และกด `KEY_1 + i` (`i < _ids.size()`) → `set_input_as_handled()` + `picked.emit(_ids[i])`
  (ร้าน `BossShop` ไม่ทำ — มีซื้อ/ขายหลายครั้ง กดเลขพลาดเสียเงิน)
- **`scripts/orbit_camera.gd`**: var `_resetting := false` / เมธอด `reset_view()` → `zoom = 1.0`, `_reset_yaw = snappedf(yaw, PI / 2.0)` (มุมฉากที่ใกล้สุด
  = มองตรงขอบแท่น ช่วยเล็ง), `_resetting = true` / ใน `_process`: ถ้า `_resetting` → `yaw = lerp_angle(yaw, _reset_yaw, 1.0 - exp(-8.0 * delta))`
  ถ้าห่าง < 0.01 → `yaw = _reset_yaw`, `_resetting = false` / เริ่มลาก (`dragging = true`) → `_resetting = false` /
  `_unhandled_input`: `can_zoom` และกด `physical_keycode == KEY_C` → `reset_view()` (`can_zoom` = HOLDING/WAITING อยู่แล้ว)

## 4. เตือนชิ้นใกล้หมด

**`data/dialogue.gd` `COMMENTS`** เพิ่ม `"last_piece": ["Last one. Make it count.", "That's the last piece.", "No more after this one."]`

**`scripts/main.gd`**
- `spawn_block()`: หลัง `state = State.HOLDING` ถ้า `pieces_used == max_pieces` → `_comment("last_piece", true)`
- `_refresh_items()` ในกิ่ง `state == State.HOLDING and current != null`: `var left := max_pieces - pieces_used` →
  `left == 0` → `parts.append("LAST PIECE!")` / `left <= 2` → `parts.append("%d PIECES LEFT" % left)` (นับไม่รวมชิ้นที่ถือ)
- `update_ui()`: บรรทัด PIECES เติม ` !` ท้ายเมื่อ `max_pieces - pieces_used <= 2` (HUD เป็น Label เดียว เปลี่ยนสีทีละบรรทัดไม่ได้ — ไม่ต้องทำสี)

## 5. SETTINGS: ความเร็วตัวอักษร + fullscreen

**`scripts/settings.gd`**: `static var text_speed := 1.0` (0.5-3.0) / load `cfg.get_value("controls", "text_speed", 1.0)` clamp / save
**`scripts/dialogue_box.gd:184`**: `_chars += CHARS_PER_SEC * Settings.text_speed * delta`
**`scripts/settings_panel.gd`**
- slider `TEXT SPEED` ต่อจาก CAMERA SPEED: `_slider(0.5, 3.0, 0.25)` + label ค่า (`"x%.2f"` หรือรูปแบบเดียวกับ CAMERA SPEED ใน `_refresh_texts()`) — ทำตามแพทเทิร์น `_sens` / `_on_sens` ทุกอย่าง (รวม `_loading`, `drag_ended → changed.emit()`, ตั้งค่าเริ่มใน `open()`)
- ปุ่ม toggle `FULLSCREEN: ON/OFF` ตามแพทเทิร์น `_retro` / `_on_retro`: `DisplayServer.window_set_mode(WINDOW_MODE_FULLSCREEN if on else WINDOW_MODE_WINDOWED)`
  สถานะปุ่มอ่านจาก `DisplayServer.window_get_mode()` ตอนเปิดหน้า (**ไม่เก็บลง settings.cfg** — บนเว็บเข้า fullscreen ได้เฉพาะจากการกดของผู้เล่น ตั้งตอนเปิดเกมไม่ได้)
- **F11** = สลับ fullscreen จากทุกหน้า: ใน `_unhandled_input` ของ SettingsPanel (ก่อนเช็ค `visible`) / ถ้าหน้าเปิดอยู่ อัปเดตข้อความปุ่มด้วย
- กล่องสูงขึ้น 2 แถว: ลด `separation` ของ VBox 12 → 8 แล้วเช็คว่าไม่ล้น 240 px (ถ้าล้น ย้ายปุ่ม RETRO กับ FULLSCREEN ไว้ HBox แถวเดียวกัน กว้างปุ่มละ ~130)

---

## อัปเดตเอกสาร
- `CLAUDE.md`: ตาราง Controls (Space/Enter, 1-3, C, F11), หัวข้อ Pause (auto-pause), หัวข้อ SETTINGS (`text_speed`, fullscreen ไม่บันทึก), ItemBar (`set_hints`, `HINT_DROPS`), คอมเมนต์ `last_piece`
- `README.md` ตาราง controls: Space/Enter, 1/2/3, C, F11

## Verification
1. `godot --headless --path . --quit` หลังแต่ละข้อ — ไม่มี parse error
2. `godot --path .` (หรือ `xvfb-run -a -s "-screen 0 1280x720x24" godot --display-driver x11 --path .` ถ้าต้องการขนาดจริง):
   - ข้อ 1: เริ่มวันที่ 1 → มุมซ้ายล่างมีคำแนะนำ ไม่ทับแถบ item / ปล่อยครบ 8 ชิ้นแล้วหาย / HOW TO PLAY ไม่ล้นจอ
   - ข้อ 2: ระหว่างถือชิ้น คลิกหน้าต่างอื่น → เกม pause / ตอนหน้า title หรือ boss พูดไม่ pause
   - ข้อ 3: Space ผ่านบทพูด / หน้าสรุป / หน้า FIRED / กด 1-3 เลือกรางวัล (`/day 2` แล้วผ่านวันด้วยเกรด ≥ A หรือ `/give`) / สินบน: `/money 999` แล้วทำให้โดนไล่ออก → กด 1 = PAY / หมุนกล้องแล้วกด C → กล้องหมุนลื่นๆ กลับมุมฉาก ซูมกลับ 1.0
   - ข้อ 4: `/day 1` วางจนเหลือ 2 ชิ้น → แถบสถานะขึ้น `2 PIECES LEFT` → ชิ้นสุดท้าย `LAST PIECE!` + boss คอมเมนต์
   - ข้อ 5: SETTINGS → TEXT SPEED x3 แล้วดูบทพูดเร็วขึ้น / ปิดเกมเปิดใหม่ค่ายังอยู่ / ปุ่ม FULLSCREEN และ F11 สลับได้ / หน้าไม่ล้นจอ
3. Export เว็บ (`godot --headless --path . --export-release "Web" build/web/index.html`) แล้วเปิดในเบราว์เซอร์: คลิกนอก canvas → pause, FULLSCREEN ทำงาน
4. ทดสอบเสร็จ **คืน `user://settings.cfg`** ถ้ามีการผ่านวัน (ข้อควรระวังใน CLAUDE.md)
