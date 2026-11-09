shader_type canvas_item;
// SB-VIDEO-010: blue chroma key for the Clippy robot unlock video (background drifts from ~#0003F8
// to ~#0F1FAB). Blue-ness m = B - max(R, G): only pixels whose B exceeds BOTH R and G are touched.
// Clippy's purple armour stays below m 0.3, so despill only clamps the excess over key_lo
// (B <= max(R, G) + key_lo: purple stays purple, the blue fringe goes); alpha fades out with a soft
// edge from key_lo to key_hi. edge_fade > 0 also fades alpha out over that UV fraction of each side
// (bursts the crop cuts). tools/build_result_scrubby_videos.py keys the still with the same formula.
uniform float key_lo = 0.30;
uniform float key_hi = 0.45;
uniform float edge_fade = 0.0;

void fragment() {
	vec4 c = COLOR;
	float m = c.b - max(c.r, c.g);
	c.b -= max(m - key_lo, 0.0);
	c.a *= 1.0 - smoothstep(key_lo, key_hi, m);
	if (edge_fade > 0.0) {
		vec2 e = smoothstep(vec2(0.0), vec2(edge_fade), UV) * smoothstep(vec2(0.0), vec2(edge_fade), 1.0 - UV);
		c.a *= e.x * e.y;
	}
	COLOR = c;
}
