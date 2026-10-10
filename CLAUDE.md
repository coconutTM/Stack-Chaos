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
> หน้า title / โดนไล่ออก / จบเกม / tutorial วันที่ 1 / สุ่มขยะแบบ bag / item 6 ชนิดแบบ Buckshot Roulette — **ยังไม่มี** PS1 look, เสียง / ดู [Roadmap](#8-roadmap)

---

## 2. Project settings ที่ต้องรู้ก่อนแก้อะไร

จาก `project.godot` — ทั้งหมดนี้จำกัดงาน rendering / asset:

| Setting | ค่า | ความหมาย |
| --- | --- | --- |
| Renderer | `gl_compatibility` | **เพราะต้องรันบนเว็บได้** → **ไม่มี** SDFGI / Volumetric Fog / SSR / ห้ามใช้ feature ที่มีแต่ใน Forward+ |
| Viewport | `426×240`, stretch `viewport` / `expand` | ตั้งใจให้ความละเอียดต่ำแบบ PS1/pixel-art **อย่าเพิ่มขนาด** |
| `default_texture_filter` | `0` (nearest) | texture ใหม่ต้องไม่ถูก filter / texture เล็ก 32–64 px |
| 3D physics engine | **Jolt Physics** | เลือกเพราะทำให้การซ้อนของนิ่งกว่า Godot Physics เดิม |

**ข้อจำกัดเรื่อง web export** (มี `export_presets.cfg` preset "Web" แล้ว — single-threaded, export ไป `build/web/`, โฟลเดอร์ `build/` ถูก gitignore):
- ต้องเป็น **single-threaded** (ปิด Thread Support) เพื่อลง itch.io ได้ง่าย
- **ลอง export ขึ้นเว็บตั้งแต่เนิ่นๆ** อย่ารอจนจบ
- **ข้อความ UI ทั้งหมดใช้ภาษาอังกฤษ** เพราะ default font ไม่มีอักษรไทย (โดยเฉพาะบนเว็บ)
  → คอมเมนต์ในโค้ดเป็นไทยได้ แต่ string ที่โชว์ผู้เล่นต้องเป็นอังกฤษ

**โมเดลทั้งหมดเป็น primitive mesh ของ Godot** (`BoxMesh`, `CylinderMesh` ที่ `radial_segments = 8`)
สร้างด้วยโค้ด ไม่ import asset ภายนอก

---

## 3. Commands

Godot อยู่ใน PATH แล้ว: `/usr/bin/godot` เวอร์ชัน `4.7.2.stable.arch_linux`

```bash
godot --path .                      # รันเกม
godot -e --path .                   # เปิดใน editor
godot --headless --path . --export-release "Web" build/web/index.html   # export เว็บ
godot --headless --path . --quit    # reimport asset / สร้าง .godot ใหม่ (ใช้เช็ค parse error ได้ด้วย)
```

โปรเจกต์นี้**ไม่มี** test, ไม่มี build script, ไม่มี package manager — ไม่ต้องไปหา

---

## 4. Architecture

### `scripts/main.gd` — `Node3D`, ติดอยู่กับ `scenes/main.tscn`

ตัวคุมเกมด้วย state machine `State { TITLE, DIALOGUE, HOLDING, WAITING, FIRED, ENDING }`:

- **`TITLE`** — หน้าแรก (ใช้ `game_over_label` โชว์ข้อความ) / คลิกซ้าย → `_start_run()` (วันที่ 1)
- **`DIALOGUE`** — boss กำลังพูดแบบบล็อก (ต้นวัน / ท้ายวัน / ฉากจบ) ฟิสิกส์ใน `_physics_process` หยุดตรวจ
- **`HOLDING`** — `move_held_block()` ยิง ray จากเมาส์ลงบน `Plane(Vector3.UP, hold_y)` แล้ว clamp
  ตำแหน่งไว้ใน `±BOUND` / บล็อก `freeze = true` แบบ `FREEZE_MODE_KINEMATIC`
- **`WAITING`** — เข้าเมื่อคลิกซ้าย (`current.release()`) / รอจน `current.settled` หรือเกิน `MAX_WAIT`
  แล้วค่อย `score += 1` → `recalc_tower_top()` → เช็คถึงโควต้า → `_comment_on_progress()` → `_advance_or_end()`
- **`FIRED`** — โดนไล่ออก (หลุดครบ `GameData.MAX_FAILS` หรือใช้ชิ้นครบแล้วไม่ถึงโควต้า) คลิก → กลับวันที่ 1
- **`ENDING`** — ผ่านวันสุดท้ายแล้ว คลิก → กลับ `TITLE`

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
| `KILL_Y` | `-4.0` | ตกต่ำกว่านี้ = ชิ้นนั้น "หลุดกอง" 1 ครั้ง |
| `MAX_WAIT` | `5.0` | รอบล็อกนิ่งนานสุดกี่วินาที |
| `RESTART_DELAY` | `0.3` | หน่วงหลังขึ้นหน้าจบก่อนรับคลิก (วินาที) |

**ค่าที่จูนเรื่องความยาก/วัน/บท อยู่ในโฟลเดอร์ `data/`** (data-driven ไม่ต้องแตะ `main.gd`):
- `data/game_data.gd` (`GameData`) — `DAYS` (โควต้าความสูง `height` + จำนวนชิ้น `pieces` + `tutorial`
  ต่อวัน), `MAX_FAILS`, `COLLAPSE_DROP`, `NEAR_QUOTA`, `COMMENT_COOLDOWN`
  ความสูงเป็นพิกัดโลก (y) พื้นอยู่ที่ y ≈ `1.2` กองสูง 3 ม. จริง ≈ `4.2`
- `data/dialogue.gd` (`Dialogue`) — บทพูดทั้งหมด (`DAY_INTRO`, `DAY_PASS`, `FIRED_FAILS`, `FIRED_PIECES`,
  `ENDING`, `COMMENTS`) ตัวแปรในบท: `{day} {days} {quota} {pieces} {height} {fails} {max_fails}`

**นับชิ้น/หลุดกอง:** `_physics_process` วน `blocks_root.get_children()` ถ้าชิ้นไหน `global_position.y < KILL_Y`
จะ `queue_free()` แล้ว `failed_attempts += 1` **ไม่เว้นฐาน** / `pieces_used` เพิ่มใน `spawn_block()` รวมชิ้นที่หลุดด้วย
(เป็น "งบ" ไม่ใช่จำนวนที่วางสำเร็จ — `score` ต่างหากคือจำนวนที่นิ่งจริง ตลอดการเล่นรอบนั้นข้ามวัน)

**กรณีพิเศษ:** ถ้าชิ้นที่หลุดคือ `current` โค้ดเรียก `_advance_or_end()` ทันทีแล้ว `return` — `current`
ถูก `queue_free()` แล้ว ห้ามแตะ property ของมัน (เช่น `current.settled`) ต่อในเฟรมเดียวกัน

**สุ่มขยะ:** `scripts/piece_bag.gd` (`PieceBag`) — ถุงที่ใส่ทุก `Block.Kind` อย่างละชิ้น สลับแล้วหยิบ หมดค่อยเติม
(ชิ้นแรกของถุงใหม่ไม่ซ้ำชิ้นสุดท้ายของถุงเก่า)

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
  **Counterweight** `Block.add_counterweight()` mass x3 / **Clipboard** `PieceBag.peek(3)` / **Insurance**
  `consume_insurance()` ถูกเรียกในลูปหลุดขอบก่อนนับ `failed_attempts` (ชิ้นยังนับเป็นที่ใช้ไปแล้ว)
- คอมเมนต์ของ boss ตอนนี้อยู่ด้านบนจอ (เริ่มหลัง HUD) ส่วนบทพูดบล็อกอยู่ด้านล่าง เพื่อไม่บังแถบ item

**boss UI:** `scripts/dialogue_box.gd` (`DialogueBox`, CanvasLayer) — `say(lines)` โหมดบล็อก (คลิกเพื่อข้ามพิมพ์/ไปต่อ),
`comment(text)` โหมดไม่บล็อก, signal `blip` ไว้ผูกเสียงใน Phase 6 / สร้าง UI ด้วยโค้ดทั้งหมด

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

ค่าเริ่มต้น (หน่วง = อัตราต่อวินาที): `STICK_LINEAR := 12.0`, `STICK_ANGULAR := 6.0`, `STICK_PULL := 6.0` (m/s²)
— ยิ่งสูงยิ่งหนืด/กองง่ายขึ้น ทำงานต่อแม้หลัง `settled = true`

**`release()` ต้องล้าง velocity:** ตอนถือ (kinematic) ความเร็วที่ Jolt เห็นมาจากการขยับ/เทเลพอร์ตตำแหน่ง
ถ้าไม่ล้างตอนปล่อย ชิ้นจะพุ่งทะยาน (เคยเจอ ~380 m/s) / `spawn_block()` จึงตั้งตำแหน่งก่อน `add_child` ด้วย

> **เพิ่มบล็อกชนิดใหม่:** สร้าง `.tscn` ใหม่ใน `scenes/blocks/` (ก๊อปจากอันที่ใกล้เคียงแล้วปรับ
> mesh/shape/สี/mass ในตัว editor) → เพิ่มชื่อใน `Kind` → บวก `KIND_COUNT` → เพิ่ม entry ใน
> `SCENES` ชี้ไปที่ scene ใหม่ — **ไม่ต้องแก้โค้ดส่วนอื่น**

`settled` บล็อกเช็คตัวเอง: `_physics_process` ต้องได้ `linear_velocity < 0.15` และ
`angular_velocity < 0.2` ติดกันครบ `1.0` วินาที

`top_y()` คืนความสูงขอบบนสุดแบบคิดการหมุนจริงด้วย `(_mesh.global_transform * _mesh.get_aabb()).end.y`

### สคริปต์เสริม (Phase 1) — แยกตามหน้าที่

- `scripts/orbit_camera.gd` (`OrbitCamera`, ติดกับ `Camera3D` ใน `main.tscn`) — กล้องโคจร: `yaw`,
  `target_y` (main ตั้งเป็น `tower_top`), `dragging`, signal `tapped` (คลิกขวาสั้น) / ค่า `RADIUS`,
  `HEIGHT`, `DRAG_THRESHOLD`, `DRAG_SENS` เป็น const บนสุดของไฟล์
- `scripts/crane.gd` (`Crane`) — เครนทาวเวอร์จาก primitive สร้างด้วยโค้ดใน `_ready()` / หมุนตาม
  `camera.yaw` (เสาอยู่ฝั่งตรงข้ามกล้อง) แขนเล็งไปที่ชิ้นที่ถือ trolley/สาย/ตะขอตามตำแหน่ง / main เรียก
  `update_crane(yaw, held, hold_y, delta)` ทุกเฟรม
- `scripts/drop_guide.gd` (`DropGuide`) — ray ลงใต้ชิ้นที่ถือ วาดวงเงา + เส้นดิ่ง (แดง = ไม่มีอะไรรองรับ
  จะตกเหว) / main ตั้ง `guide.target` ทุกเฟรม

main.gd สร้าง `Crane` และ `DropGuide` เองใน `_ready()` (ไม่ได้อยู่ใน `main.tscn`)

### Scenes

```
Main (Node3D)                ← scripts/main.gd
├── WorldEnvironment         (ProceduralSky, ฟ้าสีเทาสว่าง — ยังไม่ใช่ลุค PS1 มืด)
├── DirectionalLight3D       (shadow_enabled)
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
| คลิกขวา (สั้น ไม่ลาก) | พลิกตะแคง 90° รอบแกน Z |
| คลิกขวาค้าง + ลาก | หมุนกล้องรอบกอง 360° (ชิ้นที่ถือจะไม่ตามเมาส์ระหว่างลาก) |
| ลูกกลิ้งขึ้น / ลง | หมุน ±45° รอบแกน Y |

---

## 5. Conventions

- **คอมเมนต์เขียนภาษาไทย** — โค้ดเดิมทั้งสองไฟล์เป็นไทยหมด เขียนต่อให้เป็นไทยด้วย
- **แต่ string ที่โชว์ผู้เล่นต้องเป็นภาษาอังกฤษ** (ดูข้อจำกัดเรื่องฟอนต์ในหัวข้อ 2)
- Typed GDScript ทุกที่: ใช้ `:=` infer, ใส่ `-> void` ที่ return type, `@onready` ระบุ type
- Indent ด้วย **tab** ในไฟล์ `.gd` (มาตรฐาน Godot — `.editorconfig` กำหนดแค่ `charset = utf-8`)
- helper ที่เป็น private นำหน้าด้วย `_` (`_use_box`, `_finish`, `_still_time`, `_mesh`)

---

## 6. Art direction (ทำหลัง prototype เล่นได้แล้ว — ยังไม่เริ่ม)

เป้าหมาย: **สไตล์ PS1 มืดๆ แบบ Buckshot Roulette**

- ฉากมืด พื้นหลังดำ ambient ต่ำ มี `SpotLight3D` ดวงเดียวส่องกองขยะ
- fog + ไฟกะพริบ (สุ่ม `light_energy`)
- PSX shader (vertex jitter, dithering, ลดสี) จาก godotshaders.com
  → **ต้องเช็คว่ารองรับ Compatibility renderer** ก่อนเอามาใช้
- Viewport ความละเอียดต่ำ + nearest filter มีอยู่แล้ว (ดูหัวข้อ 2)

ตอนนี้ `WorldEnvironment` ยังเป็น ProceduralSky สีเทาสว่าง และใช้ `DirectionalLight3D`
→ ต้องเปลี่ยนทั้งสองอย่างเมื่อเริ่มทำลุคนี้

---

## 7. Gotchas

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
6. [ ] Phase 4: PS1 look (แสงมืด, SpotLight, fog, PSX shader)
7. [ ] Phase 5: day modifier + ขยะพิเศษ / Phase 6: เสียง, polish UI, ฟอนต์
8. [ ] Phase 7: อัปเดตรายงานออกแบบเกมให้ตรงกับธีมโรงขยะ + README บน GitHub
