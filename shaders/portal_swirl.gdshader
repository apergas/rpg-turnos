// The swirling surface of the Ala de viaje's portal (TravelPortal), on a quad: a spiral of
// noise turning with TIME, a bright edge and a darker centre, unshaded and blended over the scene (added light washed out on the bright ground).
// ring_only: only the bright edge (the mark on the ground of the spot it leads back to).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 edge_color : source_color = vec3(0.75, 0.9, 1.0);
uniform vec3 swirl_color : source_color = vec3(0.2, 0.45, 1.0);
uniform vec3 core_color : source_color = vec3(0.1, 0.2, 0.55);
uniform float spin = 0.6;
uniform float pulse_time = 1.2;
uniform bool ring_only = false;
// corona: the quad is bigger than the swirl; the swirl fills the fraction `disc` of it and an
// eclipse's corona (light rays fading out) is drawn in the rest.
uniform bool corona = false;
uniform float disc = 1.0;
uniform vec3 corona_inner : source_color = vec3(0.92, 0.97, 1.0);
uniform vec3 corona_outer : source_color = vec3(0.45, 0.7, 1.0);

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

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	if (corona && !ring_only) {
		r /= disc;
	}
	if (corona && !ring_only && r > 1.0) {
		float t = clamp((r - 1.0) / (1.0 / disc - 1.0), 0.0, 1.0);
		float a = atan(p.y, p.x) / 6.2831;
		float ray = noise(vec2(a * 26.0 + TIME * 0.35, TIME * 0.5));
		float ray2 = noise(vec2(a * 7.0 - TIME * 0.2, 3.0 + TIME * 0.3));
		float reach = 0.15 + 0.85 * smoothstep(0.2, 0.9, ray * 0.75 + ray2 * 0.45);
		float rays = pow(clamp(1.0 - t / reach, 0.0, 1.0), 1.2);
		float glow = pow(1.0 - t, 4.0) * 0.6;
		float pulse_c = 0.9 + 0.1 * sin(TIME * 6.2831 / pulse_time);
		float k = clamp(rays * 1.0 + glow, 0.0, 1.0) * pulse_c;
		ALBEDO = mix(corona_inner, corona_outer, smoothstep(0.0, 0.7, t));
		ALPHA = k * (1.0 - smoothstep(0.9, 1.0, t)) * smoothstep(0.0, 0.03, t + 0.03);
	} else {
	if (r > 1.0) {
		discard;
	}
	float pulse = 0.85 + 0.15 * sin(TIME * 6.2831 / pulse_time);
	float edge = smoothstep(0.78, 0.95, r) * (1.0 - smoothstep(0.95, 1.0, r));
	if (ring_only) {
		ALBEDO = edge_color;
		ALPHA = edge * pulse;
	} else {
		float angle = atan(p.y, p.x) / 6.2831;
		float swirl = noise(vec2(angle * 6.0 + r * 3.0 - TIME * spin, r * 5.0 - TIME * 0.7));
		swirl = smoothstep(0.35, 0.85, swirl);
		vec3 inside = mix(core_color, swirl_color, smoothstep(0.1, 0.8, r));
		vec3 color = mix(inside * (0.6 + 0.9 * swirl), edge_color, edge);
		ALBEDO = color * (0.9 + 0.1 * pulse);
		ALPHA = 0.92 * (1.0 - smoothstep(0.97, 1.0, r));
	}
	}
}
