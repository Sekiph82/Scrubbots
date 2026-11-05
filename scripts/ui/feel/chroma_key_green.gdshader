shader_type canvas_item;
// SB-VIDEO-006: green chroma key for the Gift Meter box videos (flat #00FF00 background).
// Green-ness m = G - max(R, B): only pixels whose G exceeds BOTH R and B are touched, so the
// yellow / white light rays, cyan, blue and pink keep their colour. Despill pulls G down to
// max(R, B) by m (the rays over green read yellow, not green); alpha fades out with a soft edge
// from key_lo to key_hi. `edge` fades alpha to 0 over that UV fraction of each side, so sparkles
// cut by the crop never show a hard edge. tools/build_result_scrubby_videos.py keys the still
// with the same formula, thresholds and edge fade.
uniform float key_lo = 0.15;
uniform float key_hi = 0.45;
uniform float edge = 0.06;

void fragment() {
	vec4 c = COLOR;
	float m = c.g - max(c.r, c.b);
	c.g -= max(m, 0.0);
	vec2 e = smoothstep(vec2(0.0), vec2(edge), UV) * smoothstep(vec2(0.0), vec2(edge), 1.0 - UV);
	c.a *= (1.0 - smoothstep(key_lo, key_hi, m)) * e.x * e.y;
	COLOR = c;
}
