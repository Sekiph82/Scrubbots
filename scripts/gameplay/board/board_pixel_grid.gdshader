shader_type canvas_item;
// Dynamic logical-pixel grid + subtle tile bevel for the BoardRenderer texture
// (M28-C002-C003-R01 V02, owner finding 4). PRESENTATION ONLY: the renderer texture is
// one texel per logical cell, and this shader derives the grid from `grid_size` (the real
// LevelData width/height) — there is no fixed mask image. Every fragment samples ITS OWN
// cell's texel centre, so the palette colour / ACTIVE-vs-CLEARED verdict comes from
// exactly the cell it lies in; a CLEARED (alpha 0) cell stays fully transparent, so no
// ghost grid or tile survives a clear. Line / bevel widths are measured in screen pixels
// (fwidth) and clamped, so 20..59-cell boards stay readable without the grid
// overwhelming dense art.

uniform vec2 grid_size = vec2(32.0, 32.0);
uniform float gutter_alpha : hint_range(0.0, 1.0) = 0.55;
uniform float bevel_strength : hint_range(0.0, 0.5) = 0.13;
uniform float corner_radius : hint_range(0.0, 0.5) = 0.10;
uniform vec3 gutter_color : source_color = vec3(0.03, 0.04, 0.07);

void fragment() {
	vec2 g = UV * grid_size;
	vec2 px = fwidth(g);                       // cell-fractions per screen pixel
	float ppc = 1.0 / max(max(px.x, px.y), 0.00001);   // screen pixels per logical cell
	vec2 cell = clamp(floor(g), vec2(0.0), grid_size - vec2(1.0));
	vec2 f = g - cell;                         // 0..1 inside the cell
	vec4 base = texture(TEXTURE, (cell + vec2(0.5)) / grid_size);
	if (base.a < 0.5) {
		COLOR = vec4(0.0);
	} else {
		float aa = 1.0 / ppc;
		float gw = clamp(ppc * 0.07, 0.8, 2.0) * aa;    // gutter band inside the cell edge
		float bw = clamp(ppc * 0.10, 1.0, 3.0) * aa;    // bevel band inside the gutter
		float r = corner_radius;
		vec2 q = abs(f - vec2(0.5)) - vec2(0.5 - r);
		float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;   // <0 inside the tile
		vec3 col = base.rgb;
		// Bevel: light on the top/left edges, dark on the bottom/right edges.
		float t = clamp((-d - gw) / max(bw, 0.00001), 0.0, 1.0);
		float ramp = 1.0 - t;
		float dl = f.x;
		float dr = 1.0 - f.x;
		float dt = f.y;
		float db = 1.0 - f.y;
		float m = min(min(dl, dr), min(dt, db));
		if (m == dl || m == dt) {
			col = mix(col, vec3(1.0), ramp * bevel_strength);
		} else {
			col = mix(col, vec3(0.0), ramp * bevel_strength);
		}
		// Thin dark gutter at the tile boundary (and the rounded corners).
		float gmask = smoothstep(-gw - aa, -gw + aa, d);
		col = mix(col, gutter_color, gmask * gutter_alpha);
		COLOR = vec4(col, 1.0);
	}
}
