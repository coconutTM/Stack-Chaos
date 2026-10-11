extends SceneTree

# อบเสียงสังเคราะห์ (Sfx._synth ใน scripts/sfx.gd) เป็นไฟล์ res://audio/<id>.wav
# เสียงเหมือนเดิมทุกอย่าง แต่เกมไม่ต้องสร้างใหม่ตอนเปิด (เดิมหน้า title กระตุก ~0.3 วินาที)
# รัน: godot --headless --path . -s tools/bake_sfx.gd  แล้ว  godot --headless --path . --quit  (import)
# แก้เสียง = แก้ _synth() แล้วรันสคริปต์นี้ใหม่ (ไฟล์เดิมถูกเขียนทับ)


func _init() -> void:
	var sfx := Sfx.new()
	for id in Sfx.IDS:
		var stream := sfx._synth(id) as AudioStreamWAV
		if stream == null:
			push_error("no synth for %s" % id)
			continue
		var err := stream.save_to_wav("res://audio/%s.wav" % id)
		print("%s -> %s" % [id, "ok" if err == OK else error_string(err)])
	sfx.free()
	quit()
