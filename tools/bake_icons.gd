extends SceneTree

# อบไอคอน item (โมเดล 3D ใน data/item_models.gd) เป็นภาพ pixel assets/icons/<id>.png
# ต้องมีหน้าต่าง (headless ไม่เรนเดอร์): godot --path . -s tools/bake_icons.gd  (บน Wayland/ไม่มีจอ: xvfb-run -a ... --display-driver x11)
# แล้วรัน godot --headless --path . --import เพื่อ import ไฟล์ใหม่
# แก้โมเดล = แก้ ItemModels แล้วรันใหม่ (ไฟล์เดิมถูกเขียนทับ) / เรนเดอร์ใหญ่แล้วย่อลงเหลือ SIZE ให้ขอบเนียนเล็กน้อย

const SIZE := 32          # ขนาดไอคอนที่เกมใช้ (พิกัดอ้างอิง 426x240)
const RENDER := 128       # เรนเดอร์ที่ขนาดนี้ก่อนย่อ
const OUT_DIR := "res://assets/icons/"


func _initialize() -> void:
	_bake.call_deferred()


func _bake() -> void:
	Psx.set_snap(false)   # vertex snapping ของ shader ผูกกับขนาดจอ ปิดตอนอบไม่งั้นรูปทรงสั่น
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var vp := SubViewport.new()
	vp.size = Vector2i(RENDER, RENDER)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.7)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 35, 0)
	light.light_energy = 1.2
	vp.add_child(light)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.9
	vp.add_child(cam)
	cam.position = Vector3(1.3, 1.1, 1.8) * 2.0
	cam.look_at(Vector3.ZERO)

	for id in ItemData.ITEMS:
		var model := ItemModels.build(id)
		vp.add_child(model)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.resize(SIZE, SIZE, Image.INTERPOLATE_TRILINEAR)
		var err := img.save_png(OUT_DIR + id + ".png")
		print("%s -> %s" % [id, "ok" if err == OK else error_string(err)])
		model.queue_free()
		await process_frame
	quit()
