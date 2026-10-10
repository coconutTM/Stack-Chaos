class_name Sfx
extends Node

# ระบบเสียงของเกม: play(id) เสียงสั้น / set_loop(id, on) เสียงวน (ambient, มอเตอร์เครน, ฝน)
#
# เสียงแต่ละตัวมี id (ดู IDS) — ถ้ามีไฟล์ res://audio/<id>.ogg (หรือ .wav / .mp3) จะใช้ไฟล์นั้น
# ถ้าไม่มีจะใช้เสียงสังเคราะห์ชั่วคราวจาก SfxSynth (เพื่อให้เกมมีเสียงไว้ก่อน) → วางไฟล์จริงทับได้เลย ไม่ต้องแก้โค้ด
# เสียงวน (ambient / motor / rain) ถ้าใช้ไฟล์จริง จะถูกตั้งให้วนเองในโค้ด

const POOL_SIZE := 12
const AUDIO_DIR := "res://audio/"
const EXTENSIONS := ["ogg", "wav", "mp3"]

# id → คำอธิบาย (ไว้เป็นรายการไฟล์ที่ต้องหามาใส่ — ดูไฟล์ audio/README.md)
const IDS := {
	"ambient": "เสียงบรรยากาศโรงขยะวนตลอด (ทุ้ม ต่ำ น่ากลัว) [loop]",
	"motor": "มอเตอร์เครนตอนขยับ [loop]",
	"rain": "เสียงฝนตก [loop]",
	"ui_click": "คลิกปุ่ม/ช่อง item",
	"release": "ปล่อยชิ้นขยะ",
	"clunk": "ตะขอเครนคาบชิ้นใหม่",
	"impact_light": "ขยะกระแทกเบา",
	"impact_heavy": "ขยะกระแทกหนัก (ตู้เย็น ลังเหล็ก)",
	"fail": "เสียชิ้นขยะ (หลุดขอบ/ตกพื้น/กองล้ม)",
	"insured": "ประกันจ่ายแทน",
	"item_get": "ได้ item",
	"item_use": "ใช้ item สำเร็จ",
	"deny": "ใช้ item ไม่ได้",
	"blip": "boss พูด (ต่อ 1 ตัวอักษร สั้นมาก)",
	"warn": "เตือนลม/แผ่นดินไหวกำลังมา",
	"wind": "ลมกระโชก",
	"rumble": "แผ่นดินไหว",
	"buzz": "ไฟกะพริบ",
	"pass": "ผ่านวัน",
	"fired": "โดนไล่ออก",
	"ending": "ฉากจบ (หลอน)",
}

var _cache := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _loops := {}       # id → AudioStreamPlayer
var _blip_count := 0


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_warm_up()


# สร้างเสียงสังเคราะห์ทีละตัวทีละเฟรม (ไม่ให้เกมสะดุดตอนเปิด)
func _warm_up() -> void:
	for id in IDS:
		_stream_for(id)
		await get_tree().process_frame


func play(id: String, volume_db := 0.0, pitch := 1.0) -> void:
	var stream := _stream_for(id)
	if stream == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


# เสียงพูดของ boss: ข้ามเป็นช่วงๆ ไม่ให้ถี่เกิน + สุ่มความสูงเล็กน้อย
func blip() -> void:
	_blip_count += 1
	if _blip_count % 2 == 0:
		play("blip", -8.0, randf_range(0.85, 1.3))


func set_loop(id: String, on: bool, volume_db := 0.0) -> void:
	var p: AudioStreamPlayer = _loops.get(id)
	if on:
		if p == null:
			var stream := _stream_for(id)
			if stream == null:
				return
			p = AudioStreamPlayer.new()
			p.stream = stream
			add_child(p)
			_loops[id] = p
		p.volume_db = volume_db
		if not p.playing:
			p.play()
	elif p != null:
		p.stop()


# ปรับความดัง/ระดับเสียงวนระหว่างเล่น (ใช้กับมอเตอร์เครน)
func set_loop_level(id: String, level: float, pitch_range := 0.0) -> void:
	var p: AudioStreamPlayer = _loops.get(id)
	if p == null:
		return
	p.volume_db = linear_to_db(maxf(level, 0.0001)) - 10.0
	p.pitch_scale = 0.85 + pitch_range * level


func _stream_for(id: String) -> AudioStream:
	if _cache.has(id):
		return _cache[id]
	var stream: AudioStream = _load_file(id)
	if stream == null:
		stream = _synth(id)
	if stream != null and id in ["ambient", "motor", "rain"]:
		_enable_loop(stream)
	_cache[id] = stream
	return stream


func _load_file(id: String) -> AudioStream:
	for ext in EXTENSIONS:
		var path := "%s%s.%s" % [AUDIO_DIR, id, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null


func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / 2


# เสียงสังเคราะห์ชั่วคราว (ทุกตัวสั้น/เล็ก)
func _synth(id: String) -> AudioStream:
	match id:
		"ambient":
			# ฮัมต่ำสองความถี่ (จำนวนรอบเต็มใน 2 วินาที จึงวนเนียน) + สั่นช้าๆ
			var n := int(2.0 * SfxSynth.RATE)
			var out := PackedFloat32Array()
			out.resize(n)
			for i in n:
				var t := float(i) / SfxSynth.RATE
				var trem := 0.7 + 0.3 * sin(TAU * t / 2.0)
				out[i] = (sin(TAU * 55.0 * t) * 0.5 + sin(TAU * 82.5 * t) * 0.3 + sin(TAU * 27.5 * t) * 0.4) * 0.22 * trem
			return SfxSynth.to_stream(out, true)
		"motor":
			# ฟันเลื่อย 70 Hz × 0.5 วินาที = 35 รอบเต็ม
			return SfxSynth.to_stream(SfxSynth.mix(SfxSynth.tone(70.0, 0.5, "saw", 0.22, 0.0), SfxSynth.tone(140.0, 0.5, "square", 0.05, 0.0)), true)
		"rain":
			return SfxSynth.to_stream(SfxSynth.loopable(SfxSynth.noise(1.2, 0.45, 0.35, 0.0), 2000), true)
		"ui_click":
			return SfxSynth.to_stream(SfxSynth.tone(900.0, 0.04, "square", 0.25, 8.0))
		"release":
			return SfxSynth.to_stream(SfxSynth.mix(SfxSynth.tone(260.0, 0.09, "sine", 0.4, 6.0, -0.5), SfxSynth.noise(0.05, 0.5, 0.2, 8.0)))
		"clunk":
			return SfxSynth.to_stream(SfxSynth.mix(SfxSynth.noise(0.1, 0.2, 0.5, 6.0), SfxSynth.tone(130.0, 0.1, "sine", 0.4, 6.0)))
		"impact_light":
			return SfxSynth.to_stream(SfxSynth.mix(SfxSynth.noise(0.14, 0.15, 0.6, 6.0), SfxSynth.tone(95.0, 0.14, "sine", 0.45, 6.0, -0.3)))
		"impact_heavy":
			return SfxSynth.to_stream(SfxSynth.mix(SfxSynth.noise(0.35, 0.08, 0.9, 4.0), SfxSynth.tone(55.0, 0.4, "sine", 0.7, 4.0, -0.4)))
		"fail":
			return SfxSynth.to_stream(SfxSynth.tone(240.0, 0.5, "saw", 0.35, 3.0, -0.6))
		"insured":
			return SfxSynth.to_stream(SfxSynth.concat([SfxSynth.tone(660.0, 0.08, "square", 0.2, 3.0), SfxSynth.tone(880.0, 0.14, "square", 0.2, 4.0)]))
		"item_get":
			return SfxSynth.to_stream(SfxSynth.concat([SfxSynth.tone(523.0, 0.07, "square", 0.2, 3.0), SfxSynth.tone(659.0, 0.07, "square", 0.2, 3.0), SfxSynth.tone(784.0, 0.12, "square", 0.2, 4.0)]))
		"item_use":
			return SfxSynth.to_stream(SfxSynth.tone(500.0, 0.14, "square", 0.22, 4.0, 0.6))
		"deny":
			return SfxSynth.to_stream(SfxSynth.tone(140.0, 0.16, "square", 0.25, 4.0))
		"blip":
			return SfxSynth.to_stream(SfxSynth.tone(110.0, 0.035, "square", 0.3, 5.0))
		"warn":
			return SfxSynth.to_stream(SfxSynth.concat([SfxSynth.tone(700.0, 0.1, "square", 0.22, 3.0), SfxSynth.tone(0.0, 0.06, "sine", 0.0, 0.0), SfxSynth.tone(700.0, 0.1, "square", 0.22, 3.0)]))
		"wind":
			return SfxSynth.to_stream(SfxSynth.noise(1.6, 0.06, 0.8, 0.5, 0.3))
		"rumble":
			return SfxSynth.to_stream(SfxSynth.mix(SfxSynth.noise(2.0, 0.02, 1.0, 1.0, 0.1), SfxSynth.tone(38.0, 2.0, "sine", 0.5, 1.0)))
		"buzz":
			return SfxSynth.to_stream(SfxSynth.tone(100.0, 0.12, "saw", 0.22, 3.0))
		"pass":
			return SfxSynth.to_stream(SfxSynth.concat([SfxSynth.tone(523.0, 0.1, "square", 0.2, 2.0), SfxSynth.tone(659.0, 0.1, "square", 0.2, 2.0), SfxSynth.tone(784.0, 0.1, "square", 0.2, 2.0), SfxSynth.tone(1047.0, 0.3, "square", 0.2, 3.0)]))
		"fired":
			return SfxSynth.to_stream(SfxSynth.mix(SfxSynth.tone(330.0, 0.9, "saw", 0.35, 2.5, -0.5), SfxSynth.noise(0.4, 0.1, 0.4, 4.0)))
		"ending":
			return SfxSynth.to_stream(SfxSynth.mix(SfxSynth.tone(55.0, 4.0, "sine", 0.6, 0.6), SfxSynth.tone(58.0, 4.0, "sine", 0.4, 0.6)))
	return null
