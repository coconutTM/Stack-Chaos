class_name CarModels
extends RefCounted

# โมเดลรถจาก assets/cars/*.glb (Cars Bundle) → ArrayMesh เดียวต่อคันผ่าน ModelLibrary
# (ไฟหน้า-ไฟท้าย-ไซเรนเรืองแสง) ใช้ได้ทั้งตัวบล็อก (Block) และฉากโรงขยะ (MultiMesh)

const SCENES: Array[PackedScene] = [
	preload("res://assets/cars/car_a.glb"),
	preload("res://assets/cars/car_b.glb"),
	preload("res://assets/cars/police.glb"),
	preload("res://assets/cars/sports_a.glb"),
	preload("res://assets/cars/sports_b.glb"),
	preload("res://assets/cars/suv.glb"),
	preload("res://assets/cars/taxi.glb"),
]


static func count() -> int:
	return SCENES.size()


# รวมชิ้นส่วน + แปลง material + cache ทำใน ModelLibrary (ใช้ร่วมกับบล็อกขยะ)
static func mesh(variant: int) -> ArrayMesh:
	return ModelLibrary.mesh(SCENES[variant])
