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

> **(อัปเดต Phase 0 แล้ว: มีบล็อก 7 ชนิด, จบเกมแล้วฟิสิกส์หยุด, มี export preset เว็บ)**
>
> **ตอนนี้ยังเป็น prototype แกนเกมเท่านั้น** — ยังไม่มีระบบวัน/โควต้า, ยังไม่มี boss, ยังไม่มี dialogue,
> ยังไม่ทำ PS1 look, ยังไม่มีเสียง / ดู [Roadmap](#8-roadmap)
>
> **ตอนนี้มี win condition แล้ว** (เวอร์ชันง่าย ยังไม่ใช่ระบบวัน/โควต้าของ boss เต็มรูปแบบ):
> กองให้สูงถึง `WIN_HEIGHT = 7.5m` ให้ได้ก่อนของหมด (`MAX_PIECES = 10` ชิ้น) — ดูหัวข้อ 4
> ระบบวัน/โควต้าของ boss (ข้อ 3 ใน Roadmap) จะมาแทนที่เงื่อนไขชนะแบบตายตัวนี้ในอนาคต

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

คุมเกมทั้งเกมด้วย state machine 3 สถานะ `State { HOLDING, WAITING, GAME_OVER }`:

- **`HOLDING`** — `move_held_block()` ยิง ray จากเมาส์ลงบน `Plane(Vector3.UP, hold_y)` แล้ว clamp
  ตำแหน่งไว้ใน `±BOUND` / ตอนนี้บล็อก `freeze = true` แบบ `FREEZE_MODE_KINEMATIC`
- **`WAITING`** — เข้าเมื่อคลิกซ้าย (`current.release()`) / รอจน `current.settled` หรือเกิน `MAX_WAIT`
  แล้วค่อย `score += 1` → `recalc_tower_top()` → เช็คชนะ → `_advance_or_end()`
- **`GAME_OVER`** — ใช้สถานะเดียวกันทั้งแพ้และชนะ (ดูเงื่อนไขแพ้/ชนะด้านล่าง) ต่างกันแค่ข้อความใน
  `game_over_label` (ดู `won: bool`) / คลิกซ้ายเพื่อ `reload_current_scene()` ทั้งสองกรณี

ฟังก์ชันหลัก: `spawn_block()`, `_advance_or_end()`, `move_held_block()`, `recalc_tower_top()`,
`update_ui()`, `win()`, `game_over()`

ค่าปรับความยาก/ฟีลอยู่เป็น `const` บนสุดของไฟล์ — แก้ที่นี่:

| Const | ค่า | ความหมาย |
| --- | --- | --- |
| `HOLD_GAP` | `1.8` | บล็อกที่ถือลอยเหนือยอดกองกี่เมตร (ลดจาก `3.5` เดิม — ตกจากที่สูงเกินไปทำให้กองยาก) |
| `BOUND` | `3.0` | ขอบเขตที่เลื่อนบล็อกได้ (X / Z) — ตั้งใจให้ใกล้เคียงขนาดพื้น (ดูหัวข้อ Scenes) |
| `KILL_Y` | `-4.0` | ตกต่ำกว่านี้ = ชิ้นนั้น "หลุดกอง" 1 ครั้ง (ไม่ใช่แพ้ทันทีอีกแล้ว ดูด้านล่าง) |
| `MAX_WAIT` | `5.0` | รอบล็อกนิ่งนานสุดกี่วินาที |
| `MAX_FAILS` | `3` | หลุดกองครบกี่ชิ้นแล้วแพ้ |
| `WIN_HEIGHT` | `7.5` | กองสูงถึงเท่านี้ (เมตร) = ชนะ |
| `RESTART_DELAY` | `0.3` | หน่วงหลังจบเกมก่อนรับคลิกเริ่มใหม่ (วินาที) |
| `MAX_PIECES` | `10` | ของให้ใช้ทั้งหมดกี่ชิ้น (นับทุกชิ้นที่ spawn แม้จะหลุด) ใช้ครบแล้วไม่ถึง `WIN_HEIGHT` = แพ้ |

**เงื่อนไขแพ้ (`game_over()`) มี 2 ทาง — อย่างใดอย่างหนึ่งก็พอ:**
1. หลุดกองครบ `MAX_FAILS` (`= 3`) ชิ้น
2. ใช้ของครบ `MAX_PIECES` (`= 10`) ชิ้นแล้ว แต่ `tower_top` ยังไม่ถึง `WIN_HEIGHT`

**เงื่อนไขชนะ (`win()`):** `tower_top >= WIN_HEIGHT` ตอนไหนก็ได้ (เช็คทุกครั้งที่ชิ้นใหม่นิ่ง ก่อนตัดสินใจ
ว่าจะ spawn ชิ้นถัดไปหรือจบเกม) — ชนะได้แม้ใช้ไปไม่ครบ 10 ชิ้น ถ้าถึงความสูงก่อน

`_physics_process` วน `blocks_root.get_children()` ทุกเฟรม ถ้าชิ้นไหน `global_position.y < KILL_Y`
(พื้นอยู่ที่ y ≈ `1.2` กว้าง `9×9` ดูหัวข้อ Scenes — ต้องกลิ้ง/ถูกเหวี่ยงตกขอบพื้นไปก่อนแล้วค่อยร่วง
ต่ำกว่า `-4.0`) จะ `queue_free()` ชิ้นนั้นทิ้งแล้ว `failed_attempts += 1` ทันที **ไม่เว้นฐาน** — ชิ้นแรกที่วาง
(the "base") ก็นับเหมือนชิ้นอื่นทุกประการ ไม่มีการปักหมุดหรือยกเว้นพิเศษ ถ้าถึง `MAX_FAILS` → `game_over()`

`pieces_used` เพิ่มทีละ 1 ใน `spawn_block()` ทุกครั้งที่มีชิ้นใหม่เกิด **รวมถึงชิ้นที่ตกไปโดยไม่ทันนิ่งด้วย**
— เป็น "งบ" ทั้งหมด ไม่ใช่แค่จำนวนที่วางสำเร็จ (`score` ต่างหากคือจำนวนที่นิ่ง/ได้คะแนนจริง) ก่อนจะ
`spawn_block()` ชิ้นใหม่ทุกครั้งต้องผ่าน `_advance_or_end()` ก่อน ซึ่งเช็คว่า `pieces_used >= MAX_PIECES`
หรือยัง ถ้าครบแล้วเรียก `game_over()` แทนการ spawn ต่อ

**กรณีพิเศษ:** ถ้าชิ้นที่หลุดคือ `current` (ชิ้นที่กำลังปล่อย ยังไม่ทันนิ่ง) โค้ดจะเรียก `_advance_or_end()`
ทันทีโดยไม่นับคะแนน/ไม่รอ `MAX_WAIT` — ต้องระวังเรื่องนี้ถ้าจะแก้ loop นี้ต่อ เพราะ `current`
ถูก `queue_free()` ไปแล้ว การแตะ property ของมันต่อในเฟรมเดียวกัน (เช่น `current.settled`) จะพังเพราะ
instance ถูก free แล้ว — โค้ดปัจจุบัน `return` ออกจากฟังก์ชันทันทีหลัง `_advance_or_end()` เพื่อเลี่ยงปัญหานี้

กล้องตามกองขึ้นไปโดย lerp เข้าหา `tower_top + 9.0` ด้วย `1.0 - exp(-3.0 * delta)`
ซึ่งเป็นสูตรที่ไม่ขึ้นกับ framerate — **ถ้าจะเพิ่ม smoothing ที่อื่น ใช้สูตรนี้** อย่าใช้ `lerp(a, b, delta)` ตรงๆ
(ค่าเริ่มต้นกล้องเซ็ตในโค้ด: `position = (0, 9, 8)`, pitch `-45°`)

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

**Stickiness (ติดกันแบบสไลม์):** `_apply_stickiness()` วน `get_colliding_bodies()` ของตัวเอง
ทุกเฟรม (ต้องเปิด `contact_monitor = true` + `max_contacts_reported = 6` ใน `_ready()` ไม่งั้น
list นี้ว่างเปล่าตลอด) แล้วหน่วง **relative velocity** ระหว่างคู่ที่กำลังสัมผัสกันอยู่จริง:
`apply_central_force((other.linear_velocity - linear_velocity) * STICK_LINEAR)` (ไถล) และ
`apply_torque((other.angular_velocity - angular_velocity) * STICK_ANGULAR)` (โยก/หมุน)

นี่คือ **viscous damping ไม่ใช่แรงดึงดูด** — มีผลเฉพาะตอนสองชิ้นแตะกันจริงเท่านั้น ไม่ดึงของที่อยู่ไกล
กันเข้ามาชนกัน และทำงานต่อแม้หลัง `settled = true` แล้ว (ชิ้นที่กองอยู่แล้วก็ควรต้านการถูกเขย่าหลุดได้
เหมือนกัน) ค่าเริ่มต้น `STICK_LINEAR := 3.0`, `STICK_ANGULAR := 0.5` — ปรับได้ตรงนี้ถ้าอยากให้
หนืดขึ้น/ลง (`STICK_LINEAR` สูงขึ้น = กองง่ายขึ้นแต่ของจะดู "เหนียว" มากขึ้นด้วย)

ทั้งสองชิ้นที่แตะกันจะรันลูปนี้แยกกัน (ฝั่งละ script instance) ผลคือแรงกระทำเท่ากันแต่ตรงข้ามกัน
โดยอัตโนมัติ (สมมาตรของ `other.v - self.v` ตรงข้ามกับอีกฝั่ง) ไม่ต้องจัดการคู่ (pairing) เอง

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
| คลิกซ้าย | ปล่อยบล็อก (หรือเริ่มใหม่ตอน game over) |
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
4. [ ] ระบบวัน / โควต้าของ boss
4. [ ] Boss + dialogue box (พิมพ์ทีละตัวอักษร)
5. [ ] PS1 look (แสงมืด, SpotLight, fog, PSX shader)
6. [ ] เสียง, polish UI, ฟอนต์
7. [ ] อัปเดตรายงานออกแบบเกมให้ตรงกับธีมโรงขยะ + README บน GitHub
