// A flame on a quad that always turns to the camera around its own Y axis (Flame): a
// teardrop torn by noise rising with TIME, white-yellow at the base, orange, red at the tip.
// Unshaded and added on top, it costs nothing on the CPU. Each flame differs by its world
// position. Fog does not dim it.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 base_color : source_color = vec3(1.0, 0.95, 0.65);
uniform vec3 mid_color : source_color = vec3(1.0, 0.55, 0.12);
uniform vec3 tip_color : source_color = vec3(0.85, 0.15, 0.05);
uniform float speed = 1.6;
uniform float strength = 1.6;

varying float seed;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	// Billboard around Y, keeping the node's scale (Godot's own Y-billboard).
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], MODEL_MATRIX[1],
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, MODEL_MATRIX[1].xyz)), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	seed = fract(dot(NODE_POSITION_WORLD, vec3(0.731, 0.317, 0.513)));
}

void fragment() {
	vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y);  // x -1..1, y 0 at the base, 1 at the tip
	float t = TIME * speed + seed * 10.0;
	float n = noise(vec2(p.x * 3.0, p.y * 4.0 - t * 2.0)) * 0.6
		+ noise(vec2(p.x * 7.0, p.y * 9.0 - t * 3.5)) * 0.4;
	float x = p.x + (n - 0.5) * 0.5 * p.y;  // the top sways more
	float width = mix(0.8, 0.03, pow(p.y, 1.1)) * (0.85 + 0.3 * n);
	float shape = smoothstep(width, width * 0.4, abs(x)) * smoothstep(0.0, 0.08, p.y)
		* (1.0 - smoothstep(0.75 + 0.2 * n, 1.0, p.y));
	vec3 color = mix(base_color, mid_color, smoothstep(0.1, 0.45, p.y));
	color = mix(color, tip_color, smoothstep(0.45, 0.9, p.y));
	ALBEDO = color * shape * strength;
}
