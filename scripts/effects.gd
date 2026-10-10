class_name Effects
extends RefCounted

# เอฟเฟกต์เล็กๆ แบบยิงแล้วลืม


# ฝุ่นฟุ้งตอนชิ้นขยะกระแทกแรง (CPUParticles3D ครั้งเดียว ลบตัวเองเมื่อจบ)
static func puff(parent: Node, pos: Vector3, color := Color(0.55, 0.5, 0.42)) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 10
	p.lifetime = 0.55
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.6
	p.gravity = Vector3(0, -5.0, 0)
	var chip := BoxMesh.new()
	chip.size = Vector3(0.14, 0.14, 0.14)
	chip.material = Psx.material(color)
	p.mesh = chip
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
