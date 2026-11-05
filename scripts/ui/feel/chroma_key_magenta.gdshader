shader_type canvas_item;
// SB-VIDEO-001/002: magenta chroma key for the Results Scrubby videos (flat ~#F00DE9 background).
// Magenta-ness m = min(R, B) - G: only pixels whose R AND B both exceed G are touched, so teal /
// cyan / blue (R < G) and the green sprout keep their exact colour (no blue-only despill).
// Despill pulls R and B toward G by m; alpha fades out with a soft edge from key_lo to key_hi.
// tools/build_result_scrubby_videos.py keys the still with the same formula and thresholds.
uniform float key_lo = 0.15;
uniform float key_hi = 0.45;

void fragment() {
	vec4 c = COLOR;
	float m = min(c.r, c.b) - c.g;
	float spill = max(m, 0.0);
	c.r -= spill;
	c.b -= spill;
	c.a *= 1.0 - smoothstep(key_lo, key_hi, m);
	COLOR = c;
}
