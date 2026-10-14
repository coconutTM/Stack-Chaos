# CLAUDE.md — Stack Chaos!

เกมกองขยะ 3D ฟิสิกส์ ทำด้วย **Godot 4.7** / ผู้เล่นเลื่อนของชิ้นที่ลอยอยู่ด้วยเมาส์ แล้วปล่อยลงไปซ้อนบนกอง
ให้สูงที่สุดโดยไม่ให้อะไรร่วงตกขอบ — HUD เขียนว่า `TRASH:` / `HEIGHT:` / `FAILS:` และตอนแพ้ขึ้นว่า `YOU'RE FIRED!`

---

## 0. About this project

- วิชา **CP352203 Computer Game Development** ภาคต้น ปีการศึกษา 2569
- ผู้พัฒนาเป็น**นักศึกษา** → อธิบายเป็นภาษาไทยแบบเข้าใจง่าย
- เดดไลน์: ให้เสร็จภายใน **1 เดือน** → เน้น "ง่ายที่สุดแต่เล่นได้จริง"
- **อย่าเพิ่มระบบซับซ้อนเกินจำเป็น** ทำทีละ feature ที่ทดสอบได้จริง
- ส่งมอบ: รายงานออกแบบเกม + README บน GitHub + build ขึ้นเว็บ (itch.io)

---

## 1. Concept & design intent

- ชื่อชั่วคราว **"Stack Chaos!"** (อาจเปลี่ยนให้เข้ากับธีมโรงขยะ)
- แนวเกม: Physics stacking / casual
- เนื้อเรื่อง: ผู้เล่นเป็น**พนักงานโรงขยะ** ต้องกองขยะให้สูงที่สุดเพื่อให้ boss พอใจ
- **Boss** (ยังไม่ได้ทำ): ยืนในเงามืด เห็นแค่เงาร่าง + ตาเรืองแสง
  (แรงบันดาลใจจาก Dealer ใน Buckshot Roulette) พูดผ่านกล่องข้อความแบบพิมพ์ทีละตัวอักษร
- โครงสร้างเกมที่วางไว้: แต่ละ **"วัน"** boss ตั้งโควต้าความสูง → ถึงก็ผ่าน / ไม่ถึงหรือกองล้ม = โดนไล่ออก
- เกมอ้างอิง: Super Stacker 2, Tower Bloxx, Stack

> **สถานะ (หลัง Phase 2):** มีเครน + กล้อง 360°, ระบบ 5 วัน/โควต้า, boss พูดแบบพิมพ์ทีละตัว (เงาร่าง + ตาเรืองแสง),
> หน้า title / โดนไล่ออก / จบเกม / tutorial วันที่ 1 / สุ่มขยะแบบ bag / item 6 ชนิดแบบ Buckshot Roulette / ลุค PS1 / ตัวปรับของวัน (ลม ฝน แผ่นดินไหว) / ขยะพิเศษ / สั่นจอ / เสียง / ฟอนต์ pixel / ฉากจบ / ดู [Roadmap](#8-roadmap)

---

## 2. Project settings ที่ต้องรู้ก่อนแก้อะไร

จาก `project.godot` — ทั้งหมดนี้จำกัดงาน rendering / asset:

| Setting | ค่า | ความหมาย |
| --- | --- | --- |
| Renderer | `gl_compatibility` | **เพราะต้องรันบนเว็บได้** → **ไม่มี** SDFGI / Volumetric Fog / SSR / ห้ามใช้ feature ที่มีแต่ใน Forward+ |
| Viewport | ขนาดอ้างอิง `426×240`, หน้าต่างเริ่มต้น `1280×720` (×3), stretch `canvas_items` / `expand` / scale `integer` | UI ทุกชิ้นวางด้วยพิกัด 426×240 (**ห้ามเปลี่ยน `viewport_width/height`** ไม่งั้นตำแหน่ง UI เพี้ยนหมด) แล้วถูกขยายเป็นจำนวนเต็มเท่าแบบคม ส่วน 3D เรนเดอร์ที่ความละเอียดจริงของหน้าต่าง |
| `default_texture_filter` | `0` (nearest) | texture ใหม่ต้องไม่ถูก filter / texture เล็ก 32–64 px |
| 3D physics engine | **Jolt Physics** | เลือกเพราะทำให้การซ้อนของนิ่งกว่า Godot Physics เดิม |

**ความละเอียด:** เปลี่ยนขนาดหน้าต่างเริ่มต้นที่ `window/size/window_width_override` / `window_height_override` / ลาย dither ของ `PostFx`
ขยายตาม (`pixel_scale` = ความสูงจอ ÷ 240 ปัดลง) ให้หยาบเท่าเดิม / vertex snapping (`snap_grid`) เป็นพิกัด NDC ไม่ขึ้นกับความละเอียด
/ **ย้อนกลับเป็นพิกเซลต่ำแบบเดิม:** `stretch/mode = "viewport"` + ลบ override 2 ตัว / ภาพ 3D ใหญ่ขึ้น 4 เท่า → **เช็ค FPS บนเว็บจริง (F3)**
/ Hyprland (tiling) ไม่สนขนาดหน้าต่างที่เกมขอ → ทดสอบขนาดจริงด้วย `xvfb-run -s "-screen 0 1280x720x24" godot --display-driver x11 ...`
/ **ขนาด embed บน itch.io:** `1280×720` (×3) หรือ `960×540` (×2) + เปิดปุ่ม Fullscreen / FPS บนเว็บไม่พอ → ลดเป็น `852×480`
/ **texture `colormap.png` ของ Kenney ต้องเป็น Lossless, ไม่มี mipmap, `detect_3d/compress_to=0`** — ถ้าปล่อยให้ Godot แปลงเป็น VRAM (S3TC)
สี palette จะเพี้ยน และเว็บบนมือถือไม่มี texture (preset Web ใส่แค่ฟอร์แมตเดสก์ท็อป)

**ข้อจำกัดเรื่อง web export** (มี `export_presets.cfg` preset "Web" แล้ว — single-threaded, export ไป `build/web/`, โฟลเดอร์ `build/` ถูก gitignore):
- ต้องเป็น **single-threaded** (ปิด Thread Support) เพื่อลง itch.io ได้ง่าย
- **ลอง export ขึ้นเว็บตั้งแต่เนิ่นๆ** อย่ารอจนจบ
- **ข้อความ UI ทั้งหมดใช้ภาษาอังกฤษ** เพราะ default font ไม่มีอักษรไทย (โดยเฉพาะบนเว็บ)
  → คอมเมนต์ในโค้ดเป็นไทยได้ แต่ string ที่โชว์ผู้เล่นต้องเป็นอังกฤษ

**โมเดล:** เครน รั้ว เสาไฟ เนินขยะ และขยะบางชนิด (ยางรถ ท่อ) เป็น primitive ของ Godot (`BoxMesh`, `CylinderMesh` ที่
`radial_segments = 8`) — **เครนตั้งใจให้เป็น primitive (ผู้พัฒนาชอบแบบนี้) อย่าเปลี่ยนเป็นโมเดล**
ขยะส่วนใหญ่ + ของประดับฉากเป็นโมเดล **Kenney (CC0)** ใน `assets/models/blocks/` และ `assets/models/yard/` (แต่ละโฟลเดอร์มี
`Textures/colormap.png` ของแพ็กตัวเอง ที่ .glb อ้างถึง — **อย่าย้ายโมเดลข้ามโฟลเดอร์** สีจะเพี้ยน) / เครดิต `assets/models/CREDITS.md`
รถ — `assets/cars/*.glb` (ชุด Cars Bundle ที่ผู้พัฒนานำเข้ามา: `car_a`, `car_b`, `police`, `sports_a`,
`sports_b`, `suv`, `taxi` / ไฟล์ต้นฉบับ `assets/Cars Bundle-glb.zip` เก็บไว้ ห้ามลบ) ดู `scripts/car_models.gd`
> **เครดิต:** Cars Bundle โดย **Quaternius** (CC0) จาก https://poly.pizza/bundle/Cars-Bundle-FE5IWe6OMk — ใส่ใน README และ `assets/models/CREDITS.md` แล้ว

---

## 3. Commands

Godot อยู่ใน PATH แล้ว: `/usr/bin/godot` เวอร์ชัน `4.7.2.stable.arch_linux`

```bash
godot --path .                      # รันเกม
godot -e --path .                   # เปิดใน editor
godot --headless --path . --export-release "Web" build/web/index.html   # export เว็บ
godot --headless --path . --quit    # reimport asset / สร้าง .godot ใหม่ (ใช้เช็ค parse error ได้ด้วย)
godot --headless --path . --import  # import ไฟล์ใหม่ (เช่น .wav ที่เพิ่งอบ — --quit อาจออกก่อน import)
godot --headless --path . -s tools/bake_sfx.gd   # อบเสียงสังเคราะห์เป็น audio/*.wav
xvfb-run -a -s "-screen 0 1280x720x24" godot --display-driver x11 --path . -s tools/bake_icons.gd   # อบไอคอน item เป็น assets/icons/*.png (ต้องมีหน้าต่าง) แล้วรัน --import
```

โปรเจกต์นี้**ไม่มี** test, ไม่มี build script, ไม่มี package manager — ไม่ต้องไปหา

---

## 4. Architecture

### `scripts/main.gd` — `Node3D`, ติดอยู่กับ `scenes/main.tscn`

ตัวคุมเกมด้วย state machine `State { TITLE, DIALOGUE, HOLDING, WAITING, FIRED, ENDING }`:

- **`TITLE`** — หน้าแรก: `TitleMenu` (`scripts/title_menu.gd`, CanvasLayer 6) ปุ่ม PLAY / OVERTIME (ล็อกจนกว่า `Settings.night_shift`) / HOW TO PLAY / CREDITS + `BEST GRADES` / ฉาก 3D = กองตัวอย่าง `TITLE_PILE` ที่ `_show_title()` ปล่อยลงแท่น (`_spawn_title_pile`, `call_deferred`) + กล้องหมุนช้าๆ (`TITLE_SPIN` ใน `_process`) / ปุ่ม PLAY → `_start_run()` (วันที่ 1) ปุ่ม OVERTIME → `_start_run(true)` / เพิ่มชื่อทีมในหน้า CREDITS ที่ `TitleMenu.CREDITS_LINES`
- **`DIALOGUE`** — boss กำลังพูดแบบบล็อก (ต้นวัน / ท้ายวัน / ฉากจบ) ฟิสิกส์ใน `_physics_process` หยุดตรวจ
- **`HOLDING`** — `move_held_block()` ยิง ray จากเมาส์ลงบน `Plane(Vector3.UP, hold_y)` แล้ว clamp
  ตำแหน่งไว้ใน `±BOUND` / บล็อก `freeze = true` แบบ `FREEZE_MODE_KINEMATIC`
- **`WAITING`** — เข้าเมื่อคลิกซ้าย (`current.release()`) / รอจน `current.settled` หรือเกิน `MAX_WAIT`
  แล้วค่อย `score += 1` → `recalc_tower_top()` → เช็คถึงโควต้า → `_comment_on_progress()` → `_advance_or_end()`
- **`FIRED`** — โดนไล่ออก (หลุดครบ `GameData.MAX_FAILS` หรือใช้ชิ้นครบแล้วไม่ถึงโควต้า) คลิก → กลับ `TITLE` (ไม่เริ่มวันที่ 1 ทันที)
- **`ENDING`** — ผ่านวันสุดท้ายแล้ว คลิก → กลับ `TITLE`

**เปลี่ยนฉากแบบจอมืด:** `ScreenFx.cover()` / `uncover()` (CanvasLayer layer 20 ทับทุก UI และกินคลิกระหว่างมืด) — ใช้ตอนเปิดเกม,
ต้นทุกวัน (`_start_day()` ล้างกอง/ตั้งค่าใต้จอดำ), ขึ้นหน้าโดนไล่ออก, และ `_go_title()` (กลับหน้าแรกจาก FIRED / ENDING / pause)
ระหว่างจอมืด `state = DIALOGUE` เพื่อกันคลิก / ฉากจบใช้ `fade_to_black()` + ตาเรือง แยกกัน (layer 2)

**Dev console (ลับ):** `scripts/dev_console.gd` (`DevConsole`, layer 30) — กด `/` (ใช้ `physical_keycode` ได้แม้คีย์บอร์ดไทย / **เปิดอย่างเดียว** เพราะตอนเปิดต้องพิมพ์ `/` ได้) หรือ F1
เปิด/ปิด, Esc ปิด / เปิดอยู่ = หยุดเกม / `register(name, usage, callable)` — main ลงทะเบียนคำสั่งใน `_ready()`: **`/day N`** (เริ่มรอบใหม่ที่วัน N
ใช้ได้ทุกหน้า), **`/give <item|all>`** (`ItemSystem.give()`), **`/money N`** (ตั้งเงิน), ในตัว `/help` `/clear` / ไม่มีอะไรบอกผู้เล่นว่ามี (ลับ) / **เพิ่มคำสั่ง = เพิ่ม `register()` + เมธอด**
**`_flow_id`** ใน main: `_start_day()` / `_end_day()` / `_go_title()` จำ id ตอนเริ่มแล้วเช็คหลังทุก `await` (`if flow != _flow_id: return`) —
`/day` เพิ่ม id + `DialogueBox.abort()` เพื่อตัด coroutine เก่าที่ค้างอยู่ (ไม่งั้น `spawn_block()` ซ้ำ) / **เขียน flow ใหม่ที่มี `await` ต้องเช็ค `_flow_id` ด้วย**

**Pause:** `scripts/pause_menu.gd` (`PauseMenu`, layer 15, `PROCESS_MODE_ALWAYS`) — ปุ่ม `PAUSE` มุมขวาบน หรือ Esc / P
หยุดได้เฉพาะ `HOLDING` / `WAITING` (`can_pause`) / **หยุดเองเมื่อเกมเสียโฟกัส** (`_notification` FOCUS_OUT — คลิกออกนอกเกม/สลับแท็บ ไม่ resume เอง) / ใช้ `get_tree().paused` → main, ฟิสิกส์, เสียงหยุดหมด / เมนู RESUME,
QUIT TO TITLE (`quit_requested` → `_go_title()`) / ปุ่มเปิดปิดเสียง (`SoundToggle`) โชว์เฉพาะหน้า `TITLE` (main ตั้ง `visible` ทุกเฟรม)

**วัน/โควต้า:** `_start_day()` อ่านโควต้าจาก `GameData.DAYS[day - 1]` (ล้างกอง, รีเซ็ตตัวนับ, boss พูดต้นวัน
แล้ว `spawn_block()`) / `_end_day(passed, reason)` freeze ทุกบล็อก → boss พูด → วันถัดไป / หน้า FIRED / ฉากจบ
ใช้ `await dialogue.say(...)` — คลิกที่ปิดบทพูดบรรทัดสุดท้ายถูก `set_input_as_handled()` โดย `DialogueBox`
(child ของ Main จึงได้รับก่อน) เพื่อไม่ให้ `main.gd` เห็นซ้ำแล้วปล่อยบล็อกทันที

**boss คอมเมนต์ระหว่างวัน** (ไม่บล็อกเกม): `_comment(key)` — หมวด `fail`, `collapse` (ยอดกองต่ำลงเกิน
`GameData.COLLAPSE_DROP` จาก `best_height`), `near` (ห่างโควต้าไม่เกิน `GameData.NEAR_QUOTA`), และ
`tutorial_*` (เฉพาะวันที่มี `"tutorial": true`) / มี cooldown `GameData.COMMENT_COOLDOWN`

ฟังก์ชันหลัก: `_start_run()`, `_start_day()`, `_end_day()`, `spawn_block()`, `_advance_or_end()`,
`move_held_block()`, `recalc_tower_top()`, `update_ui()`, `_lines()` (แทนตัวแปร `{quota}` ในบทพูด)

ค่าฟีลอยู่เป็น `const` บนสุดของ `main.gd`:

| Const | ค่า | ความหมาย |
| --- | --- | --- |
| `HOLD_GAP` | `1.8` | บล็อกที่ถือลอยเหนือยอดกองกี่เมตร |
| `BOUND` | `3.0` | ขอบเขตที่เลื่อนบล็อกได้ (X / Z) — ต้องคู่กับขนาดพื้น (ดู Gotchas ข้อ 7) |
| `STRAIN_AMP` / `STRAIN_RATE` | `0.65` / `8.0` | เครนส่ายตลอดตาม `sway` ของวัน (`_cur_day`, `GameData.DAYS[i].sway` 0.05 → 0.17 ม., OVERTIME `OVERTIME_SWAY_*` สูงสุด 0.25) / เมาส์เลย `BOUND` = เครนตึง ชิ้นที่ถือแกว่ง ±`STRAIN_AMP` ม. (ใช้ค่าที่มากกว่าของสองอย่าง) + ขึ้น `OUT OF REACH` (กันเทคนิคตรึงชิ้นที่มุมให้ซ้อนตรงเป๊ะ — offset บวกหลัง clamp ห้าม clamp ซ้ำ) |
| `KILL_Y` | `-4.0` | ตกต่ำกว่านี้ = "หลุดกอง" (สำรอง) / ปกติตัดสินที่ `_fell_off()`: ศูนย์กลางออกนอกแท่น (X/Z เกินครึ่งความกว้าง `Ground`) **และ** ต่ำกว่าผิวแท่น — ชิ้นที่เกยขอบแต่ยังเหนือผิวแท่นไม่นับ |
| `MAX_WAIT` | `5.0` | รอบล็อกนิ่งนานสุดกี่วินาที |
| `RESTART_DELAY` | `0.3` | หน่วงหลังขึ้นหน้าจบก่อนรับคลิก (วินาที) |

**ค่าที่จูนเรื่องความยาก/วัน/บท อยู่ในโฟลเดอร์ `data/`** (data-driven ไม่ต้องแตะ `main.gd`):
- `data/game_data.gd` (`GameData`) — `DAYS` (โควต้าความสูง `height` + จำนวนชิ้น `pieces` + `tutorial`
  ต่อวัน), `MAX_FAILS`, `COLLAPSE_DROP`, `NEAR_QUOTA`, `COMMENT_COOLDOWN`
  ความสูงเป็นพิกัดโลก (y) พื้นอยู่ที่ y ≈ `1.2` กองสูง 3 ม. จริง ≈ `4.2` / **ตัวเลขที่โชว์ผู้เล่นทุกที่ลบความสูงแท่นออกแล้ว** (`main._shown_height()` — HUD, หน้า FIRED, ป้าย QUOTA, แถบวัด, บทพูด `{quota}`/`{height}`) เช่น วันที่ 1 `height 4.0` โชว์ `2.8 m`
- `data/dialogue.gd` (`Dialogue`) — บทพูดทั้งหมด (`DAY_INTRO`, `DAY_PASS`, `FIRED_FAILS`, `FIRED_PIECES`,
  `ENDING`, `COMMENTS`) ตัวแปรในบท: `{day} {days} {quota} {pieces} {height} {fails} {max_fails}`

**ชิ้นที่ "เสีย" (fail) มี 3 แบบ** — ทั้งคู่ผ่าน `_register_fail(key)` (นับ `failed_attempts`, Insurance ช่วยได้ทั้งสองแบบ):
1. **หลุดขอบแท่น** — `_fell_off()` (ตกลงลานรอบแท่น ไม่ต้องรอตกถึง `KILL_Y`)
2. **ไม่ได้วางบนกอง** — ชิ้นที่ปล่อยแล้วนิ่ง (หรือเกิน `MAX_WAIT`) แต่ขอบล่างสุดติดระดับผิวพื้น `Block.rests_on_ground()`
   ทั้งที่มีชิ้นอื่นนิ่งอยู่แล้ว (`_is_off_stack()`) → `queue_free()` ไม่นับ `score` / **ชิ้นแรกของวัน (ฐาน) ยกเว้น**
   เพราะยังไม่มีกอง / ข้อ 2 ตรวจเฉพาะชิ้นที่เพิ่งวาง ส่วนชิ้นเก่าที่ถูกชนตกลงพื้นทีหลังถูกตรวจโดยข้อ 3
3. **กองล้ม** — `_check_collapse()` (เรียกทุก physics frame ตอน HOLDING/WAITING) ชิ้นเก่าที่เคย `settled` แล้วตอนนี้ไปนอนพื้น
   และไม่ใช่ `stack_base` (ฐาน = ชิ้นแรกที่นิ่งของกอง ชิ้นเดียวที่นอนพื้นได้ ถ้าฐานหลุดขอบไปจะกลายเป็น null แล้วชิ้นแรกที่นิ่งต่อไปเป็นฐานใหม่)
   → `queue_free()` + `_register_fail("collapse")` **ทีละชิ้น** (ล้ม 3 ชิ้น = fail 3) แล้ว `recalc_tower_top()` / ไม่ลด `score` ที่นับไปแล้ว
   ชิ้นที่ทับกันเป็นกองเศษบนพื้นจะถูกนับตามลำดับที่ตกถึงพื้น (ชิ้นล่างโดนลบก่อน ชิ้นบนร่วงลงมาแล้วค่อยถูกนับ)
`DropGuide.ground_is_fail` (main ตั้งเมื่อมีกองแล้ว) ทำให้วงนำทางเป็นสีแดงถ้าจุดตกคือพื้น

**นับชิ้น/หลุดกอง:** `_physics_process` วน `blocks_root.get_children()` ถ้า `_fell_off(ชิ้นนั้น)`
จะ `queue_free()` แล้ว `failed_attempts += 1` **ไม่เว้นฐาน** / `pieces_used` เพิ่มใน `spawn_block()` รวมชิ้นที่หลุดด้วย
(เป็น "งบ" ไม่ใช่จำนวนที่วางสำเร็จ — `score` ต่างหากคือจำนวนที่นิ่งจริง ตลอดการเล่นรอบนั้นข้ามวัน)

**กรณีพิเศษ:** ถ้าชิ้นที่หลุดคือ `current` โค้ดเรียก `_advance_or_end()` ทันทีแล้ว `return` — `current`
ถูก `queue_free()` แล้ว ห้ามแตะ property ของมัน (เช่น `current.settled`) ต่อในเฟรมเดียวกัน

**สุ่มขยะ:** `scripts/piece_bag.gd` (`PieceBag`) — ถุงที่ใส่ทุก `Block.Kind` อย่างละชิ้น สลับแล้วหยิบ หมดค่อยเติม
(ชิ้นแรกของถุงใหม่ไม่ซ้ำชิ้นสุดท้ายของถุงเก่า) / **ชิ้นที่จะเป็นฐาน** (ยังไม่มีชิ้นนิ่งบนแท่น) ใช้ `next_excluding(GameData.BAD_BASE_KINDS)` ข้ามถ้วยทอง ถังน้ำ ท่อ (ชิ้นที่ข้ามยังอยู่ในถุง) — `main._make_current()`

**โมเดล .glb (`scripts/model_library.gd`, `ModelLibrary.mesh(scene)`):** รวมชิ้นส่วนทั้งไฟล์เป็น `ArrayMesh` เดียว
**รวม surface ที่ material เดียวกัน** (ลด draw call) + แปลงสีเป็น `Psx.material` (ชื่อ material มี "lights" พหูพจน์ = เรืองแสง — `metalLight` ของ Kenney ไม่นับ /
`vertex_color_use_as_albedo` = ใช้ vertex color, shader คูณ `COLOR`) + cache ตาม path / ใช้ทั้งรถและบล็อกขยะ

**โมเดลบล็อกขยะ (ไม่บังคับ):** `data/block_models.gd` (`BlockModels`) — วาง `assets/models/blocks/<file>.glb` (ชื่อตาม `MODELS`
เช่น `crate`, `oil_barrel`) แล้วบล็อกชนิดนั้นใช้โมเดลทันที ไม่มีไฟล์ = primitive เดิม / `Block._setup_model()` **กล่องชนยังเป็นของเดิม
จาก `.tscn`** (ฟิสิกส์ไม่เปลี่ยน) โมเดลถูกหมุนตาม `rot` แล้วยืดให้พอดีกล่องชน (`keep_ratio` = สเกลเท่ากันทุกแกน) และซ่อน mesh
อื่นของ scene (จอทีวี) / เครดิตใส่ `assets/models/CREDITS.md` / รายการไฟล์ที่ต้องหา: `docs/MODELS_TODO.md`

**รถ (`Block.Kind.CAR`):** `scripts/car_models.gd` (`CarModels`) โหลด GLB ทั้ง 7 ผ่าน `ModelLibrary` (~7 draw call ต่อคัน) / `Block._setup_car()` สุ่มโมเดล ย่อ `CAR_SCALE` ตั้งกล่องชนตาม AABB และย้ายโมเดลให้ศูนย์กลาง
อยู่ที่ origin / เริ่มในถุงวันที่ 2 (`GameData.KIND_FIRST_DAY`) / `Junkyard._build_cars()` วางซากรถประดับในหลุม (16 คัน บางคันคว่ำ/ซ้อน
ใช้ 3 โมเดล `YARD_CARS` เป็น `MultiMesh`) / Counterweight บนรถใช้ `material_overlay` แทน emission (โมเดลหลาย material)

**ตัวปรับของวัน + ขยะพิเศษ (Phase 5):**
- `GameData.DAYS[i].modifiers` (วัน 3 = `wind`, 4 = `rain`, 5 = `wind`+`shake`) / ค่าจูนอยู่ใน `GameData.MODIFIERS`
  `scripts/day_modifiers.gd` (`DayModifiers`) — `start(mods)`/`stop()` ตอนต้น/จบวัน, `running` (เปิดเฉพาะ HOLDING/WAITING),
  `status_text(yaw)` ข้อความเตือนโชว์ในแถบสถานะเหนือแถบ item
  - **wind**: IDLE → WARN (เตือนพร้อมนับถอยหลังและลูกศรทิศตามมุมกล้อง) → ACTIVE (ชิ้นที่ยังไม่นิ่งโดน `min(force, มวล x max_accel)` N เต็มๆ / ชิ้นที่นิ่งแล้วโดน `settled_mult` เท่า → กองที่วางแล้วไม่ล้มเพราะลม ลมเป็นเรื่องจังหวะปล่อย)
  - **rain**: ลด `friction` ของ `resources/block_physics.tres` (ใช้ร่วมกันทั้งเกม **ต้องคืนค่าเสมอ** → `stop()` ทำให้) + ฝนเป็น `CPUParticles3D`
  - **shake**: ออกแรงแนวราบแกว่งเร็ว x มวล ทุกชิ้นได้ความเร่งเท่ากัน + จอสั่น (`OrbitCamera.rumble`)
  - **blackout**: ไฟกะพริบ (WARN, `DayModifiers.power` สุ่มกะพริบ) → ดับ (ACTIVE, power → 0) เป็นช่วง / `main._process` ส่ง `modifiers.power` ให้ `look.power` → `Lighting.power` (คูณ SpotLight, ไฟเติมเหลือ `FILL_MIN`) + ลด `environment.ambient_light_energy` ถึง `ambient_min` เท่า (ต้องคืนค่าใน `stop()`) / วงนำทางเป็น unshaded จึงยังเห็นตอนดับ
  - **fog**: `environment.fog_density` x `density_mult` ทั้งวัน (คืนค่าใน `stop()`) / `modifiers.environment` main ตั้งจาก `$WorldEnvironment`
  - blackout/fog ยังไม่ได้ใส่ใน `GameData.DAYS` (เรื่องราว 5 วันไม่เปลี่ยน) ใช้ใน pool สุ่มของโหมด OVERTIME (`OVERTIME_MODIFIERS`) — อยากใส่วันไหน เพิ่มชื่อใน `modifiers` ของวันนั้น (ต้องมีบทใน `Dialogue.MODIFIER_INTRO` แล้ว)
- `GameData.KIND_FIRST_DAY` = วันแรกที่ขยะพิเศษเริ่มอยู่ในถุง (`OIL_BARREL`/`STEEL_CRATE` วัน 2, `TV` วัน 3) / `GameData.kinds_for_day(day)`
  ใช้สร้าง `PieceBag` ใหม่ทุกวัน / `Dialogue.MODIFIER_INTRO` และ `Dialogue.KIND_INTRO` ถูกต่อท้ายบทต้นวันอัตโนมัติ
- **ทีวีเปราะ (`Block.fragile`)**: เสียชิ้นนี้แบบไหนก็ได้ (หลุดขอบ / ตกพื้น / กองล้ม) → `_register_fail(key, true)` →
  `_end_day(false, "fragile")` โดนไล่ออกทันที (Insurance ช่วยได้) / ขึ้น `FRAGILE!` ในแถบสถานะตอนถืออยู่
- **สั่นจอ/เอฟเฟกต์**: `OrbitCamera.shake()/rumble()` (trauma → `h_offset`/`v_offset`), `ScreenFx.flash()` (แฟลชแดงตอนเสียชิ้น),
  `Effects.puff()` (ฝุ่น), `Effects.popup()` (ข้อความ Label3D ลอยขึ้นแล้วจาง — main `_popup_progress()` เด้ง `+x m` / `NEW BEST!` / `ALMOST!` / `QUOTA!` เหนือชิ้นที่เพิ่งนิ่ง) / ชิ้นชนแรง = สัญญาณ `Block.hit(impact)` เมื่อ `ความเร็วก่อนชน x √มวล ≥ HIT_MIN` (หนักพอ ≥ `HARD_IMPACT` ถึงสั่นจอ/ฝุ่น)
  (ลังไม้ ≈ 7 ไม่สั่น, ตู้เย็น ≈ 13, ลังเหล็ก ≈ 17)

**เสียง / ฟอนต์ / ฉากจบ (Phase 6):**
- `scripts/sfx.gd` (`Sfx`, สร้างโดย main) — `play(id, volume_db, pitch)` เสียงสั้น (pool 12 ตัว), `set_loop(id, on, db)` เสียงวน
  (`ambient`, `motor`, `rain`), `set_loop_level()` ปรับมอเตอร์ตามความเร็วที่ขยับชิ้น / รายการ id ทั้งหมดอยู่ใน `Sfx.IDS`
  **เสียงทั้งหมดเป็นเสียงสังเคราะห์ (ผู้พัฒนาชอบแบบนี้ — อย่าเปลี่ยนเป็นไฟล์เสียงจากที่อื่น)** ออกแบบใน `Sfx._synth()` + `scripts/sfx_synth.gd`
  แล้วอบเป็น `audio/<id>.wav` ด้วย `tools/bake_sfx.gd` (เกมโหลดไฟล์ก่อนเสมอ — สังเคราะห์สดตอนเปิดทำหน้า title กระตุก ~0.3 วิ)
  **แก้เสียง = แก้ `_synth()` แล้วรัน bake + `--import` ใหม่** / `.wav.import` ต้องเป็น `compress/mode=0` (ค่าเริ่มต้น QOA) และเสียงวนตั้ง `edit/loop_mode=2`
  / `tools/` ถูกตัดออกจาก export (`exclude_filter`) / รายละเอียด: `audio/README.md`
- ที่ไหนเล่นเสียงอะไร: `main.gd` (ปล่อย/เสีย/ผ่านวัน/ไล่ออก/กระแทก/item/คลิก), `DialogueBox.blip` → `Sfx.blip()`,
  `DayModifiers.phase_changed` → เตือน/ลม/ครืน, `Ps1Look.flickered` → ไฟกะพริบ, `ItemSystem.used`
- **กระแทก:** `Block.hit(impact)` (impact ≥ `HIT_MIN` 2.5) → main เล่นเสียงตามแรง / ถ้า ≥ `HARD_IMPACT` (10) สั่นจอ + ฝุ่นด้วย
- `scripts/sound_toggle.gd` — ปุ่ม SND ON/OFF มุมขวาบน (เฉพาะหน้า title — ตอนเล่นตรงนั้นเป็นปุ่ม PAUSE) / `scripts/settings.gd` (`Settings`) เก็บ `muted` และ `night_shift`
  ใน `user://settings.cfg`
- **ฟอนต์:** `scripts/game_theme.gd` ตั้ง `fonts/pixel.ttf` (Press Start 2P, OFL) เป็นฟอนต์ default ผ่าน `ThemeDB.get_default_theme()`
  (ตั้ง `Window.theme` ไม่ได้ผล เพราะ CanvasLayer ขวาง) / **ขนาดตัวอักษรต้องเป็นพหุคูณของ 8 (8 / 16)** ไม่งั้นตัวอักษรเพี้ยน
  / ทับไฟล์ `pixel.ttf` เพื่อเปลี่ยนฟอนต์
- **ฉากจบวันที่ 5 "You Are the Boss Now":** `Dialogue.ENDING` (บรรทัดเป็น String หรือ `{"text", "portrait"}` โดย portrait =
  `normal` / `empty` เงาตัวหายเหลือแต่ตา / `eyes_turn` ตาเลื่อนลงมามอง) → `main._ending_cinematic()` (`ScreenFx.fade_to_black`
  + `show_eyes`) → `Settings.night_shift = true` → title ขึ้น `(night shift)` และบทวันแรกเปลี่ยนเป็น `Dialogue.NIGHT_FIRST_LINE`

**คำแนะนำปุ่ม:** `ItemBar.set_hints()` โชว์ `Q/E SPIN / R FLIP / C VIEW` มุมซ้ายล่างตอน `HOLDING` จนกว่าจะปล่อยชิ้นครบ `HINT_DROPS` (8) ครั้งตั้งแต่เปิดเกม (`main._drops`)
**เตือนชิ้นใกล้หมด:** แถบสถานะ `2 PIECES LEFT` / `1 PIECE LEFT` / `LAST PIECE!` (`main._refresh_items`), HUD `PIECES` ต่อท้าย ` !` เมื่อเหลือ ≤ 2, ชิ้นสุดท้าย boss พูด `COMMENTS.last_piece`

**Item (Phase 3):** boss แจก `ItemData.GIVE_PER_DAY` (2) ชิ้นหลังบทต้นวัน เก็บได้ `MAX_SLOTS` (6) ช่อง ล้นถูกทิ้ง
(คลังค้างข้ามวัน รีเซ็ตเมื่อเริ่มรอบใหม่) / ใช้ได้เฉพาะตอน `HOLDING`
- `data/items.gd` (`ItemData`) — ข้อมูล item (ชื่อ, ชื่อสั้นบนปุ่ม, `weight` ความน่าจะเป็น, คำอธิบาย, ข้อความตอนใช้ไม่ได้)
- `scripts/item_system.gd` (`ItemSystem`) — คลัง + ผลของ item เป็นเมธอด `_use_<id>()` (คืน `true` = ใช้สำเร็จ/หมดไป)
  **เพิ่ม item ใหม่ = เพิ่ม entry ใน `ItemData.ITEMS` + เขียนเมธอด `_use_<id>()` ไม่ต้องแก้ที่อื่น**
- `scripts/item_bar.gd` (`ItemBar`) — แถบ 6 ช่องด้านล่าง (ชี้เมาส์อ่านคำอธิบาย), บรรทัดสถานะ, รายการ 3 ชิ้นถัดไปมุมขวาบน
  ปุ่มของแถบกินคลิกเอง (`mouse_filter` STOP) จึงไม่ไปปล่อยบล็อก / `main.gd` เรียก `_refresh_items()` ทุกเฟรม
- ผลของแต่ละ item: **Duct Tape** `Block.weld()` สร้าง `Generic6DOFJoint3D` ล็อกทุกแกนกับทุกชิ้นที่แตะ (และโลกถ้าแตะพื้น)
  ใส่ joint ไว้ที่ parent ของบล็อก ไม่ใช่ลูก / **Coffee** `Engine.time_scale = 0.5` ตั้งตอนปล่อยชิ้น คืนเป็น 1.0 ตอนนิ่ง
  (`_reset_time()`) / **Swap Bag** `swap_current()` คืนชิ้นเดิมกลับท้ายคิว `PieceBag.give_back()` ไม่นับเป็นชิ้นที่ใช้เพิ่ม /
  **Counterweight** `Block.add_counterweight()` mass x3 / **Clipboard** `items.clipboard_left` = 3 → ลด 1 ทุกครั้งที่ปล่อย (`ItemSystem.on_release()`) หมดแล้วรายการ NEXT หาย / `PieceBag.peek(n)` / **Insurance**
  `consume_insurance()` ถูกเรียกในลูปหลุดขอบก่อนนับ `failed_attempts` (ชิ้นยังนับเป็นที่ใช้ไปแล้ว)
- คอมเมนต์ของ boss ตอนนี้อยู่ด้านบนจอ (เริ่มหลัง HUD) ส่วนบทพูดบล็อกอยู่ด้านล่าง เพื่อไม่บังแถบ item

**สรุปผลงานท้ายวัน:** ผ่านวัน → boss พูด `DAY_PASS` → `main._show_review()` → `ReviewScreen` (`scripts/review_screen.gd`, CanvasLayer 12) →
เกรด S/A/B/C จาก `GameData.grade_for(failed_attempts, spare)` (spare = `max_pieces - pieces_used`, เกณฑ์อยู่ใน `GameData.GRADES`) + ค่าแรง `GameData.wage_for()` บวกเข้า
`main.money` (รีเซ็ตใน `_start_run()` / `/day`) / แถวผลโผล่ทีละแถว คลิก = ข้ามอนิเมชัน → คลิกอีกที = ปิด (`await review.show_review(data)`,
`review.abort()` ใน `_debug_day` เพื่อตัด coroutine ค้าง) / `Settings.record_grade(day, grade)` จดเกรดดีสุดของแต่ละวัน (`Settings.best_grades` ใน
`user://settings.cfg`) โชว์บนหน้า title (`BEST GRADES` ใน `TitleMenu`) / คำพูด boss ตามเกรด = `Dialogue.GRADE_LINES` / จบเกมโชว์ `TOTAL EARNED`
**ทดสอบด้วยสคริปต์แล้วอย่าลืมคืน `settings.cfg`** (probe ที่เล่นจนผ่านวันจะเขียนเกรดลงไฟล์จริงของผู้เล่น)

**หน้า SETTINGS:** `SettingsPanel` (`scripts/settings_panel.gd`, CanvasLayer 16, `PROCESS_MODE_ALWAYS` ใช้ได้ตอน pause) เปิดจากปุ่ม SETTINGS ที่หน้า title และเมนู pause (main สร้างหลัง `PauseMenu` เพื่อให้ Esc ปิดหน้านี้ก่อน) /
ค่าอยู่ใน `Settings`: `volume` (0-1 → `Settings.apply_audio()` ตั้ง bus 0 เป็น dB + mute แยกกันด้วยปุ่ม SND), `camera_sens` (0.5-2.0 คูณ `OrbitCamera.DRAG_SENS`), `text_speed` (0.5-3.0 คูณ `DialogueBox.CHARS_PER_SEC`), ปุ่ม FULLSCREEN (ไม่บันทึกลง cfg — เว็บเข้าเต็มจอได้เฉพาะตอนผู้เล่นกดเอง),
`retro_look` (false = ปิด `PostFx` (dither + ลดสี) ผ่านกลุ่ม `retro_post` → `set_enabled()` และปิด vertex snapping ผ่าน `Psx.set_snap()` = ตั้ง `snap_grid` ของทุก material ใน cache เป็น `Psx.SNAP_OFF`)
บันทึกเมื่อกด BACK / Esc / ปิด / **material ใหม่ที่สร้างหลังปิด snap ก็ได้ค่าปิดด้วย** (`Psx.snap_enabled`) / ใช้เมื่อ FPS บนเว็บไม่พอ

**เลือกรางวัล item:** หลังหน้าสรุปผลงาน ถ้าเกรด ≤ `GameData.REWARD_MAX_GRADE` (A หรือดีกว่า) และคลังยังไม่เต็ม และยังมีวันต่อไป →
`ItemChoice` (`scripts/item_choice.gd`, CanvasLayer 12) โชว์การ์ด 3 ใบจาก `ItemData.roll_distinct(3)` (ไม่ซ้ำ ตามน้ำหนัก) `await item_choice.choose(ids, boss_line)` คืน id ที่เลือก
(`""` = ถูกตัดโดย `abort()` ใน `/day` / `/overtime`) → `items.give(id)` / แจก item สุ่มตอนต้นวันถัดไปยังเกิดตามเดิม (`GIVE_PER_DAY`) / บท boss = `Dialogue.REWARD_LINES`

**ไอคอน item (โมเดล 3D → pixel):** `ItemModels` (`data/item_models.gd`) ประกอบโมเดล primitive ต่อ item ด้วย `Psx.material()` (วาง `assets/models/items/<id>.glb` = ใช้ไฟล์แทน)
→ `tools/bake_icons.gd` เรนเดอร์ใน `SubViewport` (กล้อง orthogonal, ปิด vertex snapping ด้วย `Psx.set_snap(false)`) แล้วย่อเหลือ 32x32 บันทึก `assets/icons/<id>.png` (เกมไม่เรนเดอร์ 3D ตอนรัน)
→ `ItemData.icon(id)` โหลด+cache (ไม่มีไฟล์ = `null` UI กลับไปใช้ข้อความ) / ใช้ใน `ItemBar` (ช่อง 38x38 `Button.icon`), `ItemChoice.make_card(..., icon, icon_scale)` (การ์ดไอคอนไม่มีคำอธิบายในใบ:
`ItemChoice.bind_hover(card, label)` โชว์ meta `"desc"` ตอนชี้เมาส์), `BossShop` / **เพิ่ม item ใหม่ = เพิ่มเมธอด `_xxx()` ใน `ItemModels.build()` แล้วรัน bake + `--import`**
**ร้านของ boss + สินบน (ใช้เงิน):** `main.money` = เงินในกระเป๋า (ลดได้) / `main.earned` = รายได้รวมของรอบ (ไม่ลด ใช้โชว์ `TOTAL EARNED` ตอนจบ) / หน้าสรุปผลงานแถวสุดท้ายคือ `CASH`
รีเซ็ต `money` / `earned` / `bribes_used` ทุกที่ที่เริ่มรอบ (`_start_run`, `/day`, `/overtime`)
- **ร้าน** `BossShop` (`scripts/boss_shop.gd`, CanvasLayer 12) — เปิดใน `_end_day()` ต่อจากเลือกรางวัล ถ้ายังมีวันต่อไป และ (เงินพอซื้อชิ้นที่ถูกสุดและคลังไม่เต็ม **หรือ** มี item ในคลังให้ขาย) (`main._open_shop()`)
  สุ่มของ `ItemData.SHOP_STOCK` (3) ชิ้นจาก `roll_distinct()` / ราคา = `"price"` ใน `ItemData.ITEMS` / ร้านแค่แสดงผล **main เป็นเจ้าของเงินและคลัง**:
  `shop.buy` = `main._shop_buy(id)`, `shop.sell` = `main._shop_sell(index)` (ขายคืนได้ `ItemData.sell_price()` = `SELL_RATIO` 0.5 ของราคา) ทั้งคู่คืน `{ok, cash, line, inventory}` ให้ร้านวาดเงิน/แถวคลังใหม่
  ซื้อ/ขายได้หลายครั้งจนกด LEAVE / การ์ดใช้ `ItemChoice.make_card()` ร่วมกับหน้าเลือกรางวัล / `shop.abort()` ใน `/day` `/overtime`
- **สินบน** — โดนไล่ออก (ทุกสาเหตุ ทั้งโหมดปกติและ OVERTIME) หลัง boss พูดบทไล่ออก ถ้า `money >= GameData.bribe_cost(bribes_used)` (`BRIBE_BASE` 250 x2 ทุกครั้งในรอบ) →
  `main._offer_bribe(cost)` ใช้ `ItemChoice.offer()` (การ์ด PAY / WALK AWAY) → จ่าย = หักเงิน + `_start_day(true)`
  **`_start_day(retry)`**: ใช้ `_cur_day` เดิม (ห้ามเรียก `overtime_day()` ซ้ำ) ข้ามบทต้นวันและไม่แจก item ประจำวัน (พูด `Dialogue.BRIBE_PAID`) / คลังคงเดิม
- **ความระแวงของ boss** `main.suspicion` 0-100 (รีเซ็ตต้นรอบ) — จ่ายสินบน `+SUSPICION_PER_BRIBE` (35) / ผ่านวันโดยไม่ติดสินบน (`_bribed_today`) `-SUSPICION_DECAY` (10) /
  ระดับ `GameData.suspicion_level()` calm / wary (≥35) / paranoid (≥70) → ตา boss เปลี่ยนสีเหลือง/ส้ม/แดง (`main._set_suspicion()` → `DialogueBox.set_eye_color()` + `ScreenFx.set_eye_color()`),
  บทเสนอสินบนเปลี่ยน (`BRIBE_OFFER_WARY/_PARANOID`), paranoid มีคอมเมนต์ `suspicious` ต้นวัน / ถึง `SUSPICION_AUDIT` (100) → **ต้นวันถัดไป (ไม่ใช่วันเล่นซ้ำ) โดนตรวจ**:
  `Dialogue.AUDIT` ยึดเงิน `1 - AUDIT_KEEP`, ความระแวงเหลือ `AUDIT_RESET`, `_audit_today` = วันนั้นไม่รับสินบน (`BRIBE_REFUSED`)
- **ฉากจบพิเศษ "The Company Owns You"** — ผ่านวันสุดท้ายโดย `bribes_used >= GameData.CORRUPT_ENDING_BRIBES` (2) → `main._play_ending(true, flow)` ใช้ `Dialogue.ENDING_CORRUPT`
  (`{bribes}` `{paid}` = `bribe_paid_total`) ตาแดงในฉากจบ / หน้าจบเขียน `THE COMPANY OWNS YOU` / `Settings.endings_seen` (`"boss"`, `"corrupt"`, บันทึกใน `settings.cfg`) → หน้า title โชว์ `ENDINGS x/2`
  (`GameData.ENDING_COUNT`) / เซฟเก่าที่ `night_shift` = ดูฉาก boss แล้ว
- บท: `Dialogue.SHOP_*`, `BRIBE_*`, `AUDIT` / dev console: `/money N`, `/suspicion N`, `/ending corrupt|boss`
- **ถ้าจะลดของฟรี** เพราะมีร้านแล้วของล้น แก้ `ItemData.GIVE_PER_DAY` (2 → 1)

**โหมด OVERTIME:** ปลดล็อกหลังจบ 5 วัน (`Settings.night_shift`) / ปุ่ม OVERTIME บนหน้า title (`_start_run(true)`) /
`main.overtime = true`, `day = DAYS.size() + เลขกะ` (นับต่อจากวันที่ 5 ให้ `kinds_for_day()` ครบทุกชนิด) / `_shift()` = เลขกะ /
ข้อมูลกะมาจาก `GameData.overtime_day(n)` (โควต้า +`OVERTIME_HEIGHT_STEP` ต่อกะ, ชิ้น +`OVERTIME_PIECE_STEP`, สุ่มตัวปรับ 1 อย่าง (กะ 4+ = 2 อย่าง) จาก `OVERTIME_MODIFIERS`)
เก็บไว้ที่ `main._cur_day` (**อย่าเรียก `overtime_day()` ซ้ำในวันเดียวกัน** ตัวปรับสุ่มใหม่ทุกครั้ง) / บทพูด `Dialogue.OVERTIME_FIRST/_INTRO/_PASS` (ตัวแปรใหม่ `{shift}`) /
ไม่มีฉากจบ ผ่านกะ = `day += 1` ต่อไปเรื่อยๆ / โดนไล่ออก = จบรอบ โชว์ `SHIFTS SURVIVED` + `Settings.best_overtime` (`NEW RECORD!`) / HUD เขียน `SHIFT: n`
dev console: **`/overtime [N]`** เริ่มที่กะ N ทันที (ไม่ต้องปลดล็อก)

**boss UI:** `scripts/dialogue_box.gd` (`DialogueBox`, CanvasLayer) — `say(lines)` โหมดบล็อก (คลิกเพื่อข้ามพิมพ์/ไปต่อ),
`skip()` ข้ามบทชุดที่กำลังพูดทั้งชุด (ปุ่ม `SKIP >>` มุมขวาล่างกล่องบทพูด หรือ Esc — ทีละ `say()` ชุดถัดไปต้องกดใหม่), `comment(text)` โหมดไม่บล็อก, signal `blip` ไว้ผูกเสียงใน Phase 6 / สร้าง UI ด้วยโค้ดทั้งหมด

กล้องตามกองด้วย `1.0 - exp(-3.0 * delta)` ซึ่งไม่ขึ้นกับ framerate — **ถ้าจะเพิ่ม smoothing ที่อื่น ใช้สูตรนี้**
อย่าใช้ `lerp(a, b, delta)` ตรงๆ (ตอนนี้อยู่ใน `orbit_camera.gd`)

### `scripts/block.gd` — `class_name Block`, `RigidBody3D`

แต่ละชนิดบล็อกเป็น **scene แยกไฟล์** ใน `scenes/blocks/` (mesh, collision shape, สี, mass
ถูกเซ็ตไว้ใน scene ไม่ใช่ในโค้ด):

| `Kind` | Scene | รูปร่าง | Mass | linear/angular damp |
| --- | --- | --- | --- | --- |
| `CRATE` | `block_crate.tscn` | Box `1.2×1.0×1.2` | `1.5` | `0.3` / `0.6` |
| `PLANK` | `block_plank.tscn` | Box `2.6×0.35×0.6` | `0.8` | `0.3` / `0.6` |
| `FRIDGE` | `block_fridge.tscn` | Box `1.0×1.8×0.9` | `5.0` | `0.3` / `0.6` |
| `BARREL` | `block_barrel.tscn` | Cylinder r `0.5` h `1.1` | `2.5` | `0.4` / `1.8` |
| `TIRE` | `block_tire.tscn` | Cylinder r `0.7` h `0.35` | `1.0` | `0.4` / `1.8` |
| `SQUARE` | `block_square.tscn` | Box `0.9×0.9×0.9` | `2.0` | `0.3` / `0.6` |
| `CYLINDER` | `block_cylinder.tscn` | Cylinder r `0.45` h `1.6` | `2.0` | `0.4` / `1.8` |
| `OIL_BARREL` | `block_oil_barrel.tscn` | Cylinder r `0.5` h `1.1` (ลื่น: friction `0.1` จาก `block_physics_slippery.tres`, `slippery = true`) | `2.5` | `0.4` / `1.8` |
| `TV` | `block_tv.tscn` | Box `1.1×0.85×0.9` + จอเรืองแสง (**เปราะ** `fragile = true`) | `2.0` | `0.3` / `0.6` |
| `STEEL_CRATE` | `block_steel_crate.tscn` | Box `1.3×1.1×1.3` (หนัก) | `9.0` | `0.3` / `0.6` |
| `CAR` | `block_car.tscn` | โมเดลรถ (สุ่ม 1 ใน 7) ย่อ x`0.4` ≈ `0.7×0.5×1.5` + กล่องชนพอดีโมเดล | `3.5` | `0.3` / `0.8` |
| `CARDBOARD_BOX` | `block_cardboard_box.tscn` | Box `0.8×1.05×0.8` (เบามาก) | `0.6` | `0.3` / `0.6` |
| `TRASH_BIN` | `block_trash_bin.tscn` | Cylinder r `0.42` h `1.2` (วัน 2+) | `1.5` | `0.4` / `1.8` |
| `BUCKET` | `block_bucket.tscn` | Cylinder r `0.35` h `0.5` (วัน 3+) | `0.7` | `0.4` / `1.8` |
| `TOILET` | `block_toilet.tscn` | Box `0.75×0.85×0.6` (วัน 4+) | `3.0` | `0.3` / `0.6` |
| `SOFA` | `block_sofa.tscn` | Box `2.1×0.95×0.9` (แบนกว้าง วัน 2+) | `4.0` | `0.3` / `0.6` |
| `MATTRESS` | `block_mattress.tscn` | Box `2.0×0.3×1.2` (เบา แบนกว้าง **เด้ง** `bounce 0.7` จาก `block_physics_bouncy.tres`, `bouncy = true` วัน 3+) | `0.9` | `0.3` / `0.6` |
| `GOLD_TROPHY` | `block_gold_trophy.tscn` | Cylinder r `0.28` h `0.6` สีทองเรืองแสง (วัน 2+) วางนิ่งบนกอง = โบนัสเงิน `GameData.TROPHY_BONUS` (`main.trophy_bonus` → หน้าสรุป `TROPHY BONUS`) | `1.5` | `0.4` / `1.8` |

โมเดลที่ใช้ต่อชนิด (`data/block_models.gd`): CRATE = ลัง, PLANK = กองไม้, FRIDGE = ตู้เย็น, BARREL = ถัง, SQUARE = เครื่องซักผ้า
(ชื่อบน UI `WASHER`), OIL_BARREL = ถังเดียวกันย้อมเขียว (`tint`), TV = ทีวีจอตู้, STEEL_CRATE = เครื่องอบผ้าย้อมสีเหล็ก,
ชนิดใหม่ 5 ชนิดใช้โมเดลชื่อเดียวกัน / TIRE, CYLINDER, MATTRESS, GOLD_TROPHY = primitive (ยังไม่มีโมเดลที่เข้ากัน)

Cylinder blocks (`BARREL`, `TIRE`) carry a much higher `angular_damp` (`1.8` vs `0.6`) because
they **roll** — without strong damping a tipped barrel/tire keeps rolling almost indefinitely
(friction barely slows rolling motion), which is what made losses feel random before this was
added. Box blocks only need enough damping to kill residual sliding/jitter so `settled` triggers
promptly instead of waiting out `MAX_WAIT`.

`Block.SCENES` (dict `Kind → PackedScene`, preload ไว้) ผูก enum เข้ากับไฟล์ scene แต่ละตัว
`Block.spawn(kind)` เป็น **static factory**: `instantiate()` scene ที่ตรงกัน แล้วคืนเป็น `Block`
→ `main.gd` เรียก `Block.spawn(kind)` แทนที่จะ `Block.new()` + `setup()` แบบเดิม

ทุก scene ใช้ `resources/block_physics.tres` ร่วมกัน (friction `0.9`, bounce `0`)
→ **แก้ friction/bounce ของบล็อกทุกชนิดพร้อมกันได้ที่ไฟล์เดียวนี้**

`_ready()` ของ `block.gd` แค่ cache `_mesh` แล้วตั้ง `continuous_cd` + freeze เริ่มต้น
(`FREEZE_MODE_KINEMATIC`, `freeze = true`) + เปิด `contact_monitor` (ดูหัวข้อ stickiness ด้านล่าง)
— **ไม่มีการสร้าง mesh/shape/material ในโค้ดแล้ว**

**Stickiness (ติดกันแบบสไลม์):** `_apply_stickiness(delta)` วน `get_colliding_bodies()` ของตัวเองทุกเฟรม
(ต้องเปิด `contact_monitor = true` + `max_contacts_reported = 6` ใน `_ready()` ไม่งั้น list ว่างตลอด)
แล้วหน่วง **relative velocity** ระหว่างคู่ที่สัมผัสกันอยู่จริง ด้วย **impulse ที่จำกัดสัดส่วนต่อเฟรม** (ไม่ใช่แรง
`k * dv` ตรงๆ เพราะบล็อกเบา/โมเมนต์ความเฉื่อยต่ำอย่างไม้กระดานทำให้ integration ไม่เสถียรได้):
`f = clamp(STICK_LINEAR * delta, 0, 0.5)` แล้ว `apply_central_impulse((v_other - v_self) * μ * f)` เมื่อ
`μ` = reduced mass ของคู่ → โมเมนตัมรวมคงที่ และความเร็วสัมพัทธ์ลดลงสัดส่วน `f` ต่อเฟรมไม่ว่าหนักหรือเบา
ส่วนหมุนใช้หลักเดียวกันกับ inertia ของตัวเอง และมี `STICK_PULL` ดูดเข้าหาจุดกึ่งกลางของอีกชิ้นเล็กน้อย
(เฉพาะตอนแตะกัน) ทำให้ดูเหนียวแบบการ์ตูน

**พันธะเยลลี่ (`_update_bonds()` / `_pull_bond()`):** ชิ้นที่แตะกันและ "เกือบนิ่ง" (`_is_calm()`) ต่อเนื่อง `BOND_CALM_TIME` จะ **จำท่าพัก** ของกันและกัน
(`_bonds[other] = {off, rot}` ในพิกัดของตัวเอง สร้างพร้อมกันทั้งสองฝั่ง) แล้วทุก physics frame มีสปริงดึงกลับท่าพัก (เชิงเส้น + การหมุน, หน่วงต่ำให้เด้ง,
คูณ reduced mass, จำกัดความเร่ง `BOND_MAX_*`) → กองที่ยื่นเลยขอบเล็กน้อยค้างไว้/ค่อยๆ ยืดแทนที่จะล้มทันที / ยืดเกิน `BOND_BREAK_DIST` / `BOND_BREAK_ANGLE` = พันธะขาด
กองล้มจริง / ไม่ผูกกับพื้น, ข้ามชิ้นที่ติดเทป (`taped`) หรือโดน freeze / ชิ้นที่ถูกลบ = พันธะถูกล้างเองเฟรมถัดไป (`is_instance_valid`)
/ มี deadzone `BOND_DEADZONE` (คลาดน้อยมากไม่ออกแรง ให้ชิ้นหลับและ `settled` ได้) / **จูนความเหนียว:** ค่า `BOND_*` บนสุดของ `block.gd`
(ทดสอบแล้ว: แผ่นไม้ยื่นเลยขอบลังเกือบ 0.65 ม. ค้างอยู่ ~3° แทนที่จะล้มเป็น 48° / 0.8 ม. ค่อยๆ เอียงใน ~2.5 วิ แทน ~1 วิ / ≥ 0.95 ม. ยังล้ม)

**ความนิ่งของกองสูง (`COM_DROP` 0.4 / `MIN_ANGULAR_DAMP` 3.0 ใน `block.gd`):** `_ready()` ย้ายศูนย์ถ่วงลงต่ำกว่ากึ่งกลาง 40% ของความสูงกล่องชน
(`CENTER_OF_MASS_MODE_CUSTOM`) และยก `angular_damp` ของทุกชิ้นให้ไม่ต่ำกว่า 3.0 (**ค่า angular_damp ในตารางด้านบน/ใน `.tscn` จึงไม่มีผลถ้าต่ำกว่านี้**) /
benchmark (กองทรงกล่อง 16 ชิ้น เล็งกลาง ±0.12 ม. 200 รอบ): ชิ้นที่ร่วงต่อรอบ 5.99 → 3.50, รอบที่กองล้ม 68% → 40%, สูงเฉลี่ย 7.6 → 10.3 ม. /
แผ่นไม้ที่กึ่งกลางเลยกลางลัง 0.85 ม. ยังค้าง ~24° / 1.0 ม. ล้ม / **ลองจูนพันธะเยลลี่ (`BOND_DAMPING` ฯลฯ) แล้วไม่ช่วย** (แย่ลงเล็กน้อย) / แรงเสียดทานและความสูงที่ปล่อยแทบไม่มีผล
/ ผลวัดแกว่งมาก (chaotic) ต้องใช้ ≥ 200 รอบหลายชุด seed ถึงเชื่อได้

ค่าเริ่มต้น (หน่วง = อัตราต่อวินาที): `STICK_LINEAR := 12.0`, `STICK_ANGULAR := 6.0`, `STICK_PULL := 6.0` (m/s²)
— ยิ่งสูงยิ่งหนืด/กองง่ายขึ้น ทำงานต่อแม้หลัง `settled = true`

**`release()` ต้องล้าง velocity:** ตอนถือ (kinematic) ความเร็วที่ Jolt เห็นมาจากการขยับ/เทเลพอร์ตตำแหน่ง
ถ้าไม่ล้างตอนปล่อย ชิ้นจะพุ่งทะยาน (เคยเจอ ~380 m/s) / `spawn_block()` จึงตั้งตำแหน่งก่อน `add_child` ด้วย

> **เพิ่มบล็อกชนิดใหม่:** สร้าง `.tscn` ใหม่ใน `scenes/blocks/` (ก๊อปจากอันที่ใกล้เคียงแล้วปรับ
> mesh/shape/สี/mass ในตัว editor) → เพิ่มชื่อใน `Kind` → บวก `KIND_COUNT` → เพิ่ม entry ใน
> `SCENES` + `KIND_NAMES` (≤ 6 ตัวอักษร) ชี้ไปที่ scene ใหม่ / ถ้ามีโมเดล เพิ่มใน `BlockModels.MODELS` / ถ้าไม่ให้มีวันแรก
> เพิ่มใน `GameData.KIND_FIRST_DAY` + บทแนะนำใน `Dialogue.KIND_INTRO` — **ไม่ต้องแก้โค้ดส่วนอื่น**

`settled` บล็อกเช็คตัวเอง: `_physics_process` ต้องได้ `linear_velocity < 0.15` และ
`angular_velocity < 0.2` ติดกันครบ `1.0` วินาที

`top_y()` คืนความสูงขอบบนสุดแบบคิดการหมุนจริงด้วย `(_mesh.global_transform * _mesh.get_aabb()).end.y`

### สคริปต์เสริม (Phase 1) — แยกตามหน้าที่

- `scripts/orbit_camera.gd` (`OrbitCamera`, ติดกับ `Camera3D` ใน `main.tscn`) — กล้องโคจร: `yaw`,
  `target_y` (main ตั้งเป็น `tower_top`), `dragging`, signal `tapped` (คลิกขวาสั้น) / ค่า `RADIUS`,
  `HEIGHT`, `DRAG_THRESHOLD`, `DRAG_SENS` เป็น const บนสุดของไฟล์ / **ซูม:** ลูกกลิ้ง (เฉพาะเมื่อ `can_zoom` = HOLDING/WAITING, main ตั้งทุกเฟรม)
  ปรับ `zoom` (`ZOOM_MIN`–`ZOOM_MAX`) คูณ `RADIUS`/`HEIGHT` แบบลื่น (`_zoom`) / รัศมีถูกจำกัดที่ `MAX_RADIUS` (= `Crane.MAST_DIST` - 1 ไม่ให้ทะลุเสาเครน) ซูมออกเกินนั้นกล้องยกสูงขึ้นแทน / main รีเซ็ต `zoom = 1.0` ใน `_show_title()`
- `scripts/crane.gd` (`Crane`) — เครนทาวเวอร์จาก primitive สร้างด้วยโค้ดใน `_ready()` / **ยืนอยู่กับที่ ไม่หมุนตามกล้อง**
  (`CRANE_YAW` ทิศที่ตั้ง, เสาอยู่ห่างกอง `MAST_DIST` 10.8 นอกวงกล้องโคจร, แขน `JIB_FRONT` 15.5 ยื่นข้ามกอง, `JIB_ABOVE_HOLD` 6.5 สูงกว่ากล้องตอนซูมปกติ แขนจะได้ไม่พาดบังจอ)
  แขนเล็งไปที่ชิ้นที่ถือ trolley/สาย/ตะขอตามตำแหน่ง / main เรียก `update_crane(held, hold_y, delta)` ทุกเฟรม
  **ถ้าแก้ `MAST_DIST` / `RADIUS` ต้องเช็คว่ากล้องไม่ทะลุเสา (`OrbitCamera.MAX_RADIUS`) และเสาไม่ชนของประดับ (`Junkyard.CLEAR_RADIUS` 11)**
- `scripts/drop_guide.gd` (`DropGuide`) — ray ลงใต้ชิ้นที่ถือ วาดวงเงา + เส้นดิ่ง (แดง = ไม่มีอะไรรองรับ
  จะตกลงลานนอกแท่น `pad_top`) / main ตั้ง `guide.target` ทุกเฟรม
- `scripts/quota_marker.gd` (`QuotaMarker`) — กรอบเรืองแสงรอบแท่นที่ความสูงโควต้า + ป้าย `QUOTA x m` (Label3D ฟอนต์ pixel อยู่ขอบฝั่งตรงข้ามกล้อง)
  / เหลือง → กะพริบเมื่อห่างโควต้า ≤ `NEAR_QUOTA` → เขียวเมื่อถึง / main เรียก `set_quota()` ต้นวัน และ `update_progress(tower_top)` ทุกเฟรม (โชว์เฉพาะระหว่างวัน)
- `scripts/height_meter.gd` (`HeightMeter`, CanvasLayer layer 4) — แถบวัดความสูงแนวตั้งขอบขวาจอ (x≈410, y 66–186 พิกัด 426×240): เติมสี = ระดับกอง, ขีดขาว = สูงสุดของวัน (`best_height`), ขีดเหลือง + เลข = โควต้า / main เรียก `set_values(tower_top, best_height, quota_height)` ทุกเฟรม (ซ่อน/โชว์พร้อม QuotaMarker) / วาดด้วย `_draw` ไม่มี node ลูก

main.gd สร้าง `Crane`, `DropGuide`, `QuotaMarker` เองใน `_ready()` (ไม่ได้อยู่ใน `main.tscn`)

### Scenes

```
Main (Node3D)                ← scripts/main.gd
├── WorldEnvironment         (ProceduralSky, ฟ้าสีเทาสว่าง — ยังไม่ใช่ลุค PS1 มืด)
├── Ground (CSGBox3D)        9×1×9, y = 0.7, use_collision = true (sized to match BOUND — see §7)
├── Camera3D                 (ตำแหน่ง/มุมถูก override ในโค้ดตอน _ready)
├── Blocks (Node3D)          ← parent ของบล็อกที่ spawn ทุกชิ้น
└── UI                       ← instance จาก scenes/ui.tscn
    ├── ScoreLabel
    └── GameOverLabel
```

`main.gd` เข้าถึง label ผ่าน `$UI/ScoreLabel` และ `$UI/GameOverLabel`
→ **เปลี่ยนชื่อ node สองตัวนี้ `_ready()` พังทันที**

`ScoreLabel` คือ HUD รวม 4 บรรทัด: `TRASH: %d` (score) / `HEIGHT: %.1f m` (tower_top) /
`FAILS: %d/%d` (failed_attempts / MAX_FAILS) / `PIECES: %d/%d` (pieces_used / MAX_PIECES)
— ตั้งไว้ใน `update_ui()` ถ้าจะเพิ่มสถิติอื่นต่อบรรทัดในฟังก์ชันเดียวกันนี้ได้เลย ยังไม่มี node แยก
สำหรับแต่ละค่า

### Controls — `_unhandled_input()` (ใช้เมาส์อย่างเดียว)

| Input | ผล |
| --- | --- |
| ขยับเมาส์ | เลื่อนตำแหน่งบล็อกที่ถืออยู่ |
| คลิกซ้ายที่ช่องบนแถบ item | ใช้ item นั้น (ตอนถือบล็อกอยู่) |
| คลิกซ้าย | ปล่อยบล็อก / ข้ามการพิมพ์และไปบรรทัดถัดไปตอน boss พูด / กดต่อบนหน้า title, fired, ending |
| คลิกขวา (สั้น ไม่ลาก) | หมุนชิ้นที่ถือ 45° รอบแกน Y (`_spin_held`) |
| Shift + คลิกขวา / คลิกกลาง | พลิกตะแคง 90° รอบแกนแนวราบที่ชี้ออกจากกล้อง (`_flip_held` เอียงไปทางขวาของจอทุกมุมกล้อง) |
| Q / E / R | หมุน -45° / +45° / พลิกตะแคง (คีย์สำรอง ใช้ `physical_keycode`) |
| คลิกขวาค้าง + ลาก | หมุนกล้องรอบกอง 360° (ชิ้นที่ถือจะไม่ตามเมาส์ระหว่างลาก) |
| ลูกกลิ้งขึ้น / ลง | ซูมกล้องเข้า / ออก (`OrbitCamera.zoom`) |
| Esc / P หรือปุ่ม PAUSE มุมขวาบน | หยุดเกม / เล่นต่อ (เฉพาะตอนถือหรือรอชิ้นนิ่ง) |
| Esc หรือปุ่ม SKIP >> ตอน boss พูด | ข้ามบทพูดชุดนั้นทั้งชุด |
| Space / Enter | เหมือนคลิกซ้ายบนบทพูด boss, หน้าสรุปผลงาน, หน้า FIRED / ENDING |
| 1 / 2 / 3 … | เลือกการ์ดบนหน้าเลือกรางวัล / ข้อเสนอสินบน (`ItemChoice`) — ร้านของ boss ไม่รองรับ (กันกดพลาดเสียเงิน) |
| C | คืนมุมกล้องเป็นมุมฉากที่ใกล้สุด + ซูม 1.0 (`OrbitCamera.reset_view()`) |
| F11 | สลับเต็มจอ (`SettingsPanel`, ใช้ได้ทุกหน้า) |

---

## 5. Conventions

- **คอมเมนต์เขียนภาษาไทย** — โค้ดเดิมทั้งสองไฟล์เป็นไทยหมด เขียนต่อให้เป็นไทยด้วย
- **แต่ string ที่โชว์ผู้เล่นต้องเป็นภาษาอังกฤษ** (ดูข้อจำกัดเรื่องฟอนต์ในหัวข้อ 2)
- Typed GDScript ทุกที่: ใช้ `:=` infer, ใส่ `-> void` ที่ return type, `@onready` ระบุ type
- Indent ด้วย **tab** ในไฟล์ `.gd` (มาตรฐาน Godot — `.editorconfig` กำหนดแค่ `charset = utf-8`)
- helper ที่เป็น private นำหน้าด้วย `_` (`_use_box`, `_finish`, `_still_time`, `_mesh`)

---

## 6. Art direction — ลุค PS1 (ทำแล้วใน Phase 4)

สไตล์ PS1 มืดๆ แบบ Buckshot Roulette / ทั้งหมดรันบน `gl_compatibility` และเว็บ:

- `scripts/ps1_look.gd` (`Ps1Look`) — รวมลุคไว้ที่เดียว (main.gd สร้าง): ตั้ง material พื้นแท่น + สร้าง `Junkyard`, `Lighting`, `PostFx`
  ลบ node นี้ออกจาก `main.gd` = ได้ฉากเรียบกลับมา
- `Environment` ใน `main.tscn`: พื้นหลังดำ, ambient ต่ำสีน้ำเงินเทา, fog (`fog_density 0.022`) / **ไม่มี DirectionalLight ใน `main.tscn`** (ไฟเติมสร้างใน `lighting.gd`)
- `scripts/lighting.gd` (`Lighting`) — SpotLight3D เหนือกอง ตามความสูงกอง + กะพริบ (สั่นเบาๆ + ไฟวูบสุ่มทุก 4–10 วิ) + DirectionalLight3D ไฟเติมแสงจันทร์อ่อนๆ (`FILL_*` ไม่กะพริบ) ส่องเฉียงให้หน้าขยะสว่างไม่เท่ากัน อ่านรูปทรงออก
  **ไม่เปิด shadow**: vertex snapping ทำให้เงาเพี้ยน และประหยัดบนเว็บ
- `shaders/psx.gdshader` — spatial shader เขียนเอง: vertex snapping (ปัดตำแหน่งเป็นกริด NDC `snap_grid`) + แสงแบบเป็นขั้น
  (`light_steps`) / สี = `albedo × vertex COLOR × albedo_tex` (texture palette ของโมเดล Kenney, filter nearest)
  / `scripts/psx.gd` (`Psx.material(color, emission, energy, tex)`) สร้าง+cache material ตามสี
  **ทุก mesh ในเกมต้องใช้ `Psx.material()`** (บล็อกแปลงอัตโนมัติจากสีใน `.tscn` ที่ `Block._ready()` ผ่าน `Psx.from_standard()`)
  **ถ้าแก้ `vertex()` ต้องตั้ง `POSITION` ทุกกิ่ง** (รวม vertex หลังกล้อง `clip.w <= 0`) — ไม่งั้นได้ค่าขยะ พื้นลาน 160 ม. เคยยืดมาบังแท่นเป็นเงาดำบางมุมกล้อง
- `shaders/psx_post.gdshader` + `scripts/post_fx.gd` — โพสต์โปรเซสเต็มจอ: ลดสีเหลือ 5 บิต/ช่อง + dithering Bayer 4x4
  ใช้ `hint_screen_texture` / อยู่ `CanvasLayer` layer 0 (ใต้ UI ทุกชั้น จึงไม่ทำให้ตัวหนังสือแตก) และ `mouse_filter = IGNORE`
- `scripts/junkyard.gd` (`Junkyard`) — ลานดินระดับพื้น (`FLOOR_Y` 0.6 มีชนจริง `WorldBoundaryShape3D`; แท่นวางสูงกว่าลาน 0.6 ม.) ของประดับห้ามอยู่ใน `CLEAR_RADIUS` 11 ม. จากแท่น (กล้องโคจร 9.5), กองขยะประดับ, รั้ววงกลม, เนินขยะไกลๆ, เสาไฟ 6 ต้น
  (primitive) + ซากรถ, ขยะโมเดล (`JUNK_PROPS`), ตู้คอนเทนเนอร์ (`_build_props()`), อาคารโรงงาน/ปล่องควันไกลๆ นอกรั้ว
  (`SKYLINE`, `_build_skyline()`) / seed คงที่ / รวมเป็น `MultiMesh` ตามสีหรือตามโมเดล (`_add_model()`) / ไม่มีไฟล์โมเดล = ข้ามไป
  (draw call ตอนหน้า title ≈ 65)
- `scripts/fps_overlay.gd` — กด **F3** เปิดตัวเลข FPS + draw call (ไว้เช็คบนเว็บ build) / เป็นปุ่มดีบักเท่านั้น
- `OrbitCamera.far = 80` (ระยะวาดสั้นแบบ PS1 + fog กลืนอยู่แล้ว)

ข้อควรระวัง: ไม่ใช้ texture (primitive สีเรียบ) จึงไม่ทำ affine texture warping / ถ้าเพิ่ม mesh ใหม่ที่ใช้ `StandardMaterial3D`
จะดูไม่เข้ากับฉาก / จูนความมืดที่ `ambient_light_energy` + `fog_*` ใน `main.tscn` และ `BASE_ENERGY` ใน `lighting.gd`

---

## 7. Gotchas

0b. **ทิศของชิ้นที่ถือต้องเก็บใน `main._hold_basis` แล้วตั้งทั้ง `global_transform` ใน `move_held_block()`** — หมุนชิ้นด้วย `rotate_y()` ตรงๆ
   แล้วตั้งแค่ `global_position` ทุกเฟรม ทิศจะถูกทับกลับเป็นเดิมภายใน 1 เฟรม (Jolt + freeze kinematic) / `_spin_held()` / `_flip_held()` แก้ `_hold_basis`,
   `_make_current()` รีเซ็ต
0a. **ห้ามเชื่อ velocity ของบล็อกที่เพิ่งปล่อยจากการถือ** — ตอนถือ (kinematic) Jolt คำนวณความเร็วจากการขยับตำแหน่ง ถ้าปล่อยทันที
   (เมาส์สะบัดหรือเทเลพอร์ต) ชิ้นจะพุ่ง 70–160 m/s `Block.release()` จึงล้างความเร็วซ้ำ 3 ครั้ง (ทันที + 2 physics frame)
   / ตั้งตำแหน่งชิ้นใหม่ก่อน `add_child` เสมอ
0. **บอดี้ที่นิ่งแล้วจะ "หลับ" (sleep) และ `get_colliding_bodies()` คืนว่าง** — อย่าใช้ contact ตรวจว่าชิ้นที่นิ่งแล้ว
   แตะอะไร ให้ใช้เรขาคณิต (`rests_on_ground()`) หรือปลุก (`sleeping = false`) แล้วรอ physics frame ก่อน (`weld()` ทำแบบนี้)

1. **ปรับ "ฟีล" ของบล็อก (ขนาด/สี/mass) ให้แก้ที่ `.tscn` ใน `scenes/blocks/` ไม่ใช่ใน `scripts/block.gd`**
   — ตั้งแต่เปลี่ยนมาใช้ scene ต่อชนิด โค้ดใน `block.gd` ไม่รู้จัก mesh/shape/mass ของแต่ละ `Kind`
   แล้ว (ดูหัวข้อ 4) ถ้าจะปรับ friction/bounce ของทุกบล็อกพร้อมกัน ไปแก้ `resources/block_physics.tres`
2. **โปรเจกต์นี้อยู่ใน git แล้ว** (git root คือโฟลเดอร์นี้เอง) commit ตามที่ผู้ใช้สั่งได้ตามปกติ
3. `.godot/` เป็น cache ที่ engine สร้างเอง และถูก gitignore — **ห้ามแก้มือ**
4. `scripts/*.gd.uid` ผูกกับสคริปต์ของมัน และถูกอ้างผ่าน `uid://` ใน `.tscn`
   / ย้ายหรือเปลี่ยนชื่อสคริปต์ **ต้องขยับ `.uid` ไปด้วย** ไม่งั้น scene หาไฟล์ไม่เจอ
5. `.tscn` มี attribute `unique_id=` ของ Godot 4.7 ติดมาทุก node / แก้ scene ด้วยมือได้แต่ควรใช้ editor
   ถ้าแก้มือจริงต้องเก็บ field พวกนั้นไว้
6. `recalc_tower_top()` นับแค่บล็อกที่ `released` **และ** `settled` แล้ว
   เพื่อให้บล็อกที่ยังถืออยู่ไม่ไปทำให้ค่า HEIGHT เพี้ยน
7. **`BOUND` และขนาดพื้น (`Ground.size` ใน `main.tscn`) ต้องปรับคู่กันเสมอ** — `BOUND = 3.0` คือ
   ครึ่งความกว้างที่ผู้เล่นเลื่อนบล็อกได้ ส่วนพื้นกว้าง `9×9` (ครึ่งความกว้าง `4.5`) ให้ buffer ไว้
   `~1.5m` รอบๆ สำหรับบล็อกที่ไถล/กลิ้งก่อนนิ่ง ถ้าเพิ่ม `BOUND` โดยไม่ขยายพื้นตาม ขอบจะเข้ามาใกล้
   พื้นที่เล่นมากขึ้น (เกมง่ายเกิน เพราะหลุดขอบยาก) — ถ้าลดพื้นโดยไม่ลด `BOUND` ตาม ผู้เล่นจะเลื่อน
   บล็อกออกนอกพื้นได้ตรงๆ (เกมยากเกิน เพราะหลุดขอบง่ายเกินไป)
8. **`contact_monitor = true` + `max_contacts_reported = 6`** (ใน `block.gd:_ready()`) จำเป็นสำหรับ
   stickiness — ลบ/ลดสองค่านี้โดยไม่ตั้งใจ `get_colliding_bodies()` จะคืน list ว่างเปล่าเงียบๆ (ไม่ error)
   ทำให้ความหนืดหายไปทั้งหมดโดยไม่มี warning ถ้ากองสูงมากจนบล็อกหนึ่งชิ้นสัมผัสมากกว่า 6 ชิ้นพร้อมกัน
   (ไม่น่าเกิดกับขนาดบล็อกปัจจุบัน) ต้องเพิ่มเลขนี้ตาม ไม่งั้น contact เกินจะไม่ถูกรายงาน

### แก้ปัญหาที่เจอบ่อย

- `Block` ไม่ถูกรู้จัก (class_name หาไม่เจอ) → **Project > Reload Current Project**
- เมาส์ map ตำแหน่งไม่ตรง → ปรับค่ากล้องใน `_ready()` (`y 9`, `z 8`, pitch `-45°`)
- บล็อกสั่น / ไถล → เช็คว่าใช้ Jolt อยู่, เพิ่ม `friction` ใน `_finish()`

---

## 8. Roadmap

1. [x] Prototype เล่นได้ (`main.gd` + `block.gd`)
2. [x] Phase 0: แก้ HUD, รวมบล็อก SQUARE/CYLINDER, freeze ตอนจบเกม, export เว็บผ่านแล้ว (ยังต้องทดสอบรันบนเบราว์เซอร์/itch.io จริง)
3. [x] Phase 1: เครน + กล้อง 360° + วงเงานำทาง (รอทดสอบ)
4. [x] Phase 2: ระบบ 5 วัน/โควต้า + boss dialogue + tutorial + title/fired/ending + bag (รอทดสอบ)
5. [x] Phase 3: item 6 ชนิดแบบ Buckshot Roulette (รอทดสอบ)
6. [x] Phase 4: PS1 look (ฉากมืด, SpotLight กะพริบ, fog, PSX shader, โรงขยะ) — รอเช็ค FPS บนเว็บจริง (กด F3)
7. [x] Phase 5: ตัวปรับของวัน (ลม/ฝน/แผ่นดินไหว) + ขยะพิเศษ (น้ำมัน/ทีวีเปราะ/ลังเหล็ก) + สั่นจอ (รอทดสอบ)
8. [x] Phase 6: เสียง (สังเคราะห์ด้วยโค้ด อบเป็น .wav — เป็นเสียงจริงของเกม), ฟอนต์ pixel, ปุ่มปิดเสียง, ฉากจบ
9. [x] โมเดล Kenney (CC0) แทนขยะ 8 ชนิด + ขยะใหม่ 5 ชนิด + ของประดับ/อาคารในฉาก (เครนคง primitive) (รอทดสอบ)
10. [x] Phase 8 (พัฒนาบน branch `test` แล้ว merge): เส้นโควต้า 3D + แถบวัดความสูง + ข้อความเด้ง, เมนู title, ใบเกรด S/A/B/C + เงินเดือน,
    โหมด OVERTIME, เลือกรางวัล item 1 ใน 3, ตัวปรับ BLACKOUT/FOG, ขยะ MATTRESS/GOLD TROPHY, หน้า SETTINGS, ความสูงนับจากผิวแท่น,
    กองสูงนิ่งขึ้น (`COM_DROP`/`MIN_ANGULAR_DAMP`), ฐานกองไม่เป็นชิ้นเล็ก/กลม (รอทดสอบด้วยมือ + เช็ค FPS บนเว็บ)
11. [ ] Phase 7: อัปเดตรายงานออกแบบเกมให้ตรงกับธีมโรงขยะ (Claude Docs) + README บน GitHub (เพิ่มฟีเจอร์ Phase 8)
