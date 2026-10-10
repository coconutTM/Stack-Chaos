class_name SfxSynth
extends RefCounted

# สังเคราะห์เสียงชั่วคราว (placeholder) ด้วยโค้ด — ใช้เมื่อยังไม่มีไฟล์เสียงจริงใน res://audio/
# (ดู scripts/sfx.gd) / mono 16 บิต 22050 Hz

const RATE := 22050


static func _wave(kind: String, phase: float) -> float:
	var p := fposmod(phase, 1.0)
	match kind:
		"square":
			return 1.0 if p < 0.5 else -1.0
		"saw":
			return p * 2.0 - 1.0
		"tri":
			return 4.0 * absf(p - 0.5) - 1.0
	return sin(p * TAU)


# โทนเดี่ยว: sweep = สัดส่วนการเปลี่ยนความถี่ตลอดความยาว (-0.5 = ลดลงครึ่งหนึ่ง) / decay = ความเร็วที่เสียงหาย
static func tone(freq: float, dur: float, kind := "sine", vol := 0.5, decay := 5.0, sweep := 0.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		phase += freq * (1.0 + sweep * t) / RATE
		out[i] = _wave(kind, phase) * vol * exp(-decay * t) * minf(1.0, float(i) / 40.0)
	return out


# นอยส์กรองความถี่สูงออก (lowpass 0-1 ยิ่งน้อยยิ่งทุ้ม) / attack = สัดส่วนช่วงไต่ขึ้นของความดัง
static func noise(dur: float, lowpass := 0.3, vol := 0.5, decay := 5.0, attack := 0.0) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7   # seed คงที่ ให้เสียงเหมือนเดิมทุกครั้ง
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / n
		y += lowpass * (rng.randf_range(-1.0, 1.0) - y)
		var env := exp(-decay * t)
		if attack > 0.0:
			env *= minf(1.0, t / attack)
		out[i] = y * vol * env * minf(1.0, float(i) / 40.0)
	return out


static func mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := maxi(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = (a[i] if i < a.size() else 0.0) + (b[i] if i < b.size() else 0.0)
	return out


static func concat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out


# ทำให้วนต่อเนื่องไม่สะดุด: ครอสเฟดช่วงท้ายเข้าหัว
static func loopable(s: PackedFloat32Array, fade: int) -> PackedFloat32Array:
	var n := s.size() - fade
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = s[i]
	for i in fade:
		var k := float(i) / fade
		out[i] = s[i] * k + s[n + i] * (1.0 - k)
	return out


static func to_stream(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w
