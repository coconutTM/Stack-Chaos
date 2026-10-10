class_name Ps1Look
extends Node3D

# รวมลุค PS1 ไว้ที่เดียว: ฉากโรงขยะ + ไฟกะพริบ + โพสต์โปรเซสลดสี/dithering
# (พื้นหลังดำ / ambient ต่ำ / fog ตั้งใน Environment ของ main.tscn)
# ลบ node นี้ออกจาก main.gd = ได้ฉากเรียบๆ กลับมา

var ground: CSGBox3D        # พื้นแท่นวาง (main.gd ตั้งก่อน add_child)
var target_y := 0.0:        # ความสูงกองที่ไฟควรตาม (main.gd ตั้ง)
	set(v):
		target_y = v
		if _lighting:
			_lighting.target_y = v

var _lighting: Lighting


func _ready() -> void:
	if ground:
		ground.material = Psx.material(Color(0.26, 0.23, 0.2))
	add_child(Junkyard.new())
	_lighting = Lighting.new()
	add_child(_lighting)
	add_child(PostFx.new())
