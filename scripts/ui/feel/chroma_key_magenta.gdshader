shader_type canvas_item;
// SB-VIDEO-001/002: magenta chroma key for the Results Scrubby videos (flat ~#F00DE9 background).
// Magenta-ness m = min(R, B) - G: only pixels whose R AND B both exceed G are touched, so teal /
// cyan / blue (R < G) and the green sprout keep their exact colour (no blue-only despill).
// Despill pulls R and B toward G by m; alpha fades out with a soft edge from key_lo to key_hi.
// tools/build_result_scrubby_videos.py keys the still with the same formula and thresholds.
// SB-VIDEO-007: edge_fade > 0 also fades alpha out over that UV fraction of each side (a fixed
// crop that cuts the star burst); 0 (default) = no fade, the Results / Level Intro behaviour.
uniform float key_lo = 0.15;
uniform float key_hi = 0.45;
uniform float edge_fade = 0.0;

void fragment() {
	vec4 c = COLOR;
	float m = min(c.r, c.b) - c.g;
	float spill = max(m, 0.0);
	c.r -= spill;
	c.b -= spill;
	c.a *= 1.0 - smoothstep(key_lo, key_hi, m);
	if (edge_fade > 0.0) {
		vec2 e = smoothstep(vec2(0.0), vec2(edge_fade), UV) * smoothstep(vec2(0.0), vec2(edge_fade), 1.0 - UV);
		c.a *= e.x * e.y;
	}
	COLOR = c;
}
