# รายการโมเดลที่ต้องโหลด (แทน primitive ทั้งเกม)

สถานะ: **รอผู้พัฒนาโหลดและวางไฟล์** — ยังไม่ได้แก้โค้ดส่วนนำเข้า (Phase 7 README/รายงาน พักไว้ก่อน)

## เงื่อนไขที่เลือกไว้
- ใช้ **สีเรียบ / vertex color เท่านั้น** (ไม่ใช้ texture)
- เปลี่ยน **ทุกอย่างที่มีอยู่ + เพิ่มชนิดขยะใหม่**
- ห้ามติดตั้ง addon / ห้ามลบไฟล์โดยไม่ถามก่อน

## เงื่อนไขของไฟล์
- ฟอร์แมต **.glb** เป็นหลัก
- ไลเซนส์ **CC0** (ถ้า CC-BY ต้องใส่เครดิต)
- low poly ไม่เกิน ~1,500 สามเหลี่ยมต่อชิ้น
- ไฟล์ละ 1 ของ (ไม่ใช่ทั้งฉากรวมกัน) / pivot กลางหรือก้นของ / สเกลใกล้เมตรจริง (ปรับสเกลในโค้ดได้)
- สีเรียบหรือ vertex color

> ⚠️ แพ็ก PSX หลายตัวมี texture ติดมา (เช่น PSX Derelict Furniture มี 6 ไฟล์) ถ้าเลือกสีเรียบเท่านั้นจะใช้ได้เฉพาะชิ้นที่ไม่มี texture
> ถ้าเปลี่ยนใจให้ใช้ texture ได้ เพิ่มใน `shaders/psx.gdshader` ประมาณ 15 บรรทัด

## A. ขยะที่ซ้อนได้ (แทนของเดิม 10 ชนิด — ต้องมีครบ ทำก่อน)
| ไฟล์ที่ตั้งชื่อ | Block.Kind | ของที่ต้องหา | คีย์เวิร์ด |
| --- | --- | --- | --- |
| `crate.glb` | CRATE | ลังไม้ | wooden crate |
| `plank.glb` | PLANK | ไม้กระดานยาว | wood plank / board |
| `fridge.glb` | FRIDGE | ตู้เย็นเก่า | fridge / refrigerator |
| `barrel.glb` | BARREL | ถังเหล็ก | barrel / steel drum |
| `tire.glb` | TIRE | ยางรถ | tire / car tire |
| `square.glb` | SQUARE | กล่องเหล็กเล็ก / ไมโครเวฟ | metal box / microwave |
| `cylinder.glb` | CYLINDER | ท่อกลมยาว | pipe / metal pipe |
| `oil_barrel.glb` | OIL_BARREL | ถังน้ำมัน (สีต่างจาก barrel) | oil drum / toxic barrel |
| `tv.glb` | TV | ทีวีจอตู้ CRT | CRT TV / old television |
| `steel_crate.glb` | STEEL_CRATE | ลังเหล็ก | metal crate / ammo box |

## B. ขยะชนิดใหม่ (เลือกเอาที่เจอ ~5 อย่าง)
`trash_bag.glb` ถุงขยะ · `cardboard_box.glb` กล่องกระดาษ · `bucket.glb` ถังสี/ถังน้ำ · `mattress.glb` ที่นอนเก่า · `pallet.glb` พาเลทไม้
สำรอง: เก้าอี้ออฟฟิศ, กรวยจราจร (traffic cone), ถังขยะล้อเลื่อน (wheelie bin)

## C. เครน
- ทาวเวอร์เครน 1 ไฟล์ `crane.glb` **หรือ** แยกส่วน (`mast.glb` เสา, `jib.glb` แขน+counterweight, `cab.glb` ห้องคนขับ, `hook.glb` ตะขอ)
- สายเคเบิลกับ trolley ยังสร้างด้วยโค้ด (ต้องยืดหดตามระยะ)
- คีย์เวิร์ด: low poly tower crane / construction crane

## D. ฉากโรงขยะ (ประดับ)
`junk_pile.glb` กองขยะ · `fence.glb` รั้วตาข่าย/สังกะสี · `lamp.glb` เสาไฟถนน · `dumpster.glb` ถังขยะใหญ่
(พาเลท ถังเหล็ก ท่อ ยาง ใช้ซ้ำจากหมวด A ได้ / ซากรถมีแล้วจาก Cars Bundle)

## แหล่งโหลด (ยังไม่ได้เปิดดูไฟล์ ต้องเช็ค texture + ไลเซนส์เอง)
- PSX Waste (CC0) — ถังเหล็ก กล่องกระดาษ ถุงขยะ dumpster: https://daniel-jurys.itch.io/psx-waste
- PSX Derelict Furniture (CC0, มี texture) — ตู้เย็นสนิม ที่นอน เก้าอี้พัง: https://daniel-jurys.itch.io/psx-derelict-furniture
- PSX Inspired Clutter — ยางรถ: https://jamzuz.itch.io/psx-inspired-clutter-objects
- PSX CRT TV — ทีวีจอตู้: https://itsjustjord.itch.io/psx-crt-tv-itsjustjord
- LoFi3D Cargo (CC0) — ถัง กล่อง ลัง: https://philip-erd.itch.io/lofi3d-cargo
- Kenney Survival Kit (CC0, GLB): https://kenney-assets.itch.io/survival-kit
- Kenney City Kit Industrial (CC0): https://opengameart.org/content/city-kit-industrial
- Kenney Furniture Kit (CC0): https://opengameart.org/node/80260
  (ชุดของ Kenney มักมี palette texture เล็กๆ)
- Quaternius (CC0, สีเรียบ แนวเดียวกับ Cars Bundle): https://quaternius.com
- Poly Pizza — ค้นด้วยคีย์เวิร์ด กรอง License = CC0: https://poly.pizza
- เครน: https://free3d.com/3d-model/tower-crane-3d-model-5989.html และ https://majadroid.itch.io/3d-house-construction-site

## วิธีวางไฟล์
```
assets/models/blocks/  crate.glb plank.glb fridge.glb barrel.glb tire.glb square.glb
                       cylinder.glb oil_barrel.glb tv.glb steel_crate.glb
assets/models/new/     trash_bag.glb cardboard_box.glb bucket.glb mattress.glb pallet.glb
assets/models/crane/   crane.glb
assets/models/yard/    fence.glb lamp.glb dumpster.glb junk_pile.glb
assets/models/CREDITS.md   ชื่อโมเดล | ผู้สร้าง | ลิงก์ | ไลเซนส์
```
ไม่ต้องครบ — ไฟล์ไหนไม่มี เกมใช้ primitive เดิมต่อ ทยอยใส่ได้ **แนะนำเริ่มจากหมวด A**

## แผนนำเข้า (ทำหลังวางไฟล์แล้ว)
1. ทำ `CarModels` ให้เป็น `ModelLibrary` ทั่วไป (รวม surface ตาม material, `Psx.material`, cache) + รองรับ vertex color (`COLOR`) ใน `psx.gdshader`
2. `data/block_models.gd` ข้อมูลต่อชนิด: `Kind → {file, scale, collision, offset}` (ไม่มีไฟล์ = ใช้ primitive เดิมใน `.tscn`)
3. `Block._setup_model()` ต่อยอด `_setup_car()` (ตั้ง mesh, กล่องชนพอดี, ย้ายศูนย์กลางไป origin)
4. ชนิดขยะใหม่: `Block.Kind` + `KIND_NAMES` + `SCENES` + `GameData.KIND_FIRST_DAY` + `Dialogue.KIND_INTRO`
5. `crane.gd`: เปลี่ยน `_box()` เป็นโมเดล คงตรรกะหมุน/trolley/สาย
6. `junkyard.gd`: MultiMesh ต่อโมเดล คุม draw call ≲ 150
7. อัปเดต CLAUDE.md + CREDITS + สคริปต์ตรวจ AABB/สเกล

## ตรวจหลังนำเข้า
- สคริปต์ตรวจขนาด AABB / จำนวน vertex ของทุกไฟล์
- `godot --headless --path . --quit` ไม่มี error, export เว็บผ่าน, รันจาก `.pck` ได้
- ชุดทดสอบฟิสิกส์เดิมผ่านโดยไม่ระเบิด (รวมวางซ้อนทุกชนิดใหม่)
- เรนเดอร์ภาพจริง + กด F3 เช็ค FPS / draw call

## ยังค้างอยู่
- ตรวจที่มา/ไลเซนส์ของ Cars Bundle แล้วใส่เครดิตใน README (ในไฟล์ .glb ไม่ระบุผู้สร้าง)
- Phase 7: README + สรุปรายงานออกแบบเกม (พักไว้ตามที่ผู้ใช้สั่ง)
- ไฟล์เสียงจริงใน `audio/` (ไม่บังคับ — ตอนนี้ใช้เสียงสังเคราะห์)
