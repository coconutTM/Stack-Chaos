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


# ข้อความลอยขึ้นแล้วจางหายในโลก 3D (หันหน้าหากล้องเสมอ ไม่ถูกกองบัง) เช่น "+0.8 m" / "NEW BEST!"
static func popup(parent: Node, pos: Vector3, text: String, color := Color(1.0, 0.85, 0.2)) -> void:
	var l := Label3D.new()
	l.text = text
	l.font = preload("res://fonts/pixel.ttf")
	l.font_size = 32   # พหุคูณของ 8 ให้ฟอนต์ pixel คม
	l.pixel_size = 0.02
	l.modulate = color
	l.outline_size = 8
	l.outline_modulate = Color(0.02, 0.02, 0.04)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.shaded = false
	l.no_depth_test = true
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	parent.add_child(l)
	l.global_position = pos
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "global_position:y", pos.y + 1.6, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.chain().tween_callback(l.queue_free)
