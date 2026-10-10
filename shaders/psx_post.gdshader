shader_type canvas_item;

// โพสต์โปรเซสเต็มจอ: ลดสีเหลือ 5 บิตต่อช่อง (15 บิตแบบ PS1) + dithering แบบ Bayer 4x4
// วาดเป็น CanvasLayer ใต้ UI จึงไม่กระทบตัวหนังสือ/แถบ item

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
uniform float levels = 32.0;
uniform float dither_strength = 1.0;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	ivec2 p = ivec2(mod(FRAGCOORD.xy, 4.0));
	float d = (BAYER[p.y * 4 + p.x] / 16.0 - 0.5) * dither_strength / levels;
	c = floor((c + d) * levels + 0.5) / levels;
	COLOR = vec4(c, 1.0);
}
