shader_type canvas_item;
// SB-POLISH-011: draw-only offset for a container-placed character (the layout rect never moves).
uniform vec2 offset = vec2(0.0);

void vertex() {
	VERTEX += offset;
}
