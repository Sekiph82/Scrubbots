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

// M50-BOARD colour symbols (owner 2026-10-15): every ACTIVE cell carries its canonical C-ID
// shape, the same 16 shapes as Supply/Slots. `cid_map` is one texel per cell (R = C-ID 1..16,
// 0 = none; G = 1 when the cell takes the dark ink), `glyph_atlas` the 16 shapes built once by
// ColorSymbols.build_atlas_image() (R = shape, G = halo). Still one pass, no per-cell nodes;
// a CLEARED cell exits above before any glyph is drawn. Owner 2026-10-22: opt-in (Settings,
// default OFF), small subtle glyph of floor(ppc * glyph_span) whole screen pixels (owner rework:
// half the old 0.8 glyph, rounded down), not drawn when that is under `min_glyph_px`.
uniform bool symbols_on = false;
uniform sampler2D cid_map : filter_nearest, repeat_disable;
uniform sampler2D glyph_atlas : filter_linear_mipmap, repeat_disable;
uniform float glyph_span = 0.4;          // glyph side as a fraction of the cell, floored to whole px
uniform float ink_alpha = 0.85;
uniform float halo_alpha = 0.35;
uniform float min_glyph_px = 5.0;        // smaller glyphs are hidden; the magnifier is the inspect path
uniform vec3 ink_dark : source_color = vec3(0.03, 0.04, 0.09);
uniform vec3 ink_light : source_color = vec3(1.0);

void fragment() {
	vec2 g = UV * grid_size;
	vec2 px = fwidth(g);                       // cell-fractions per screen pixel
	vec2 dgx = dFdx(g);                        // glyph gradients: uniform control flow only
	vec2 dgy = dFdy(g);
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
		float gpx = floor(ppc * glyph_span + 0.001);   // glyph side in whole screen pixels
		if (symbols_on && gpx >= min_glyph_px) {
			float gs = gpx / ppc;                       // that side as a fraction of the cell
			vec2 id = texelFetch(cid_map, ivec2(cell), 0).rg;
			float cid = floor(id.r * 255.0 + 0.5);
			vec2 gp = (f - vec2(0.5)) / gs + vec2(0.5);
			// Quarter-pixel bias: when the square edge falls on pixel centres, exactly gpx px are inside.
			vec2 gq = gp + vec2(0.25 / gpx);
			if (cid > 0.5 && gq.x >= 0.0 && gq.x < 1.0 && gq.y >= 0.0 && gq.y < 1.0) {
				// Explicit gradients from the continuous grid coordinate (f wraps per cell).
				vec2 k = vec2(1.0 / 16.0, 1.0) / gs;
				vec2 gl = textureGrad(glyph_atlas, vec2((cid - 1.0 + gp.x) / 16.0, gp.y), dgx * k, dgy * k).rg;
				bool dark = id.g > 0.5;
				col = mix(col, dark ? ink_light : ink_dark, gl.g * halo_alpha);
				col = mix(col, dark ? ink_dark : ink_light, gl.r * ink_alpha);
			}
		}
		// Thin dark gutter at the tile boundary (and the rounded corners).
		float gmask = smoothstep(-gw - aa, -gw + aa, d);
		col = mix(col, gutter_color, gmask * gutter_alpha);
		COLOR = vec4(col, 1.0);
	}
}
