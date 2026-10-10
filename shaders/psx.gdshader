shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// สไตล์ PS1: vertex snapping + แสงแบบเป็นขั้นบันได (เขียนเองทั้งหมด ไม่ได้อ้างอิง shader ภายนอก)
// ใช้ได้กับ gl_compatibility / เว็บ (ไม่ใช้ฟีเจอร์ของ Forward+)
// ไม่มี texture: โมเดลทั้งเกมเป็น primitive สีเรียบ จึงไม่ต้องทำ affine texture warping

uniform vec4 albedo : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 1.0;
// ตาราง snap ในจอ (NDC) ยิ่งน้อยยิ่งสั่นหยาบ / ค่าเริ่มต้นเป็นครึ่งหนึ่งของ viewport 426x240
uniform vec2 snap_grid = vec2(213.0, 120.0);
uniform float light_steps = 4.0;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (clip.w > 0.0) {
		vec2 ndc = clip.xy / clip.w;
		vec2 half_grid = snap_grid * 0.5;
		ndc = floor(ndc * half_grid + 0.5) / half_grid;
		POSITION = vec4(ndc * clip.w, clip.z, clip.w);
	}
}

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 1.0;
	EMISSION = emission_color.rgb * emission_energy;
}

// แสงเป็นขั้นๆ (แทนไล่เฉดเนียน) ให้ลุคเก่าๆ
void light() {
	float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float banded = floor(ndl * light_steps + 0.5) / light_steps;
	DIFFUSE_LIGHT += banded * ATTENUATION * LIGHT_COLOR / PI;
}
