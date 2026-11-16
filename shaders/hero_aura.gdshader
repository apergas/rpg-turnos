// The golden aura of the hero at the game's top level (HeroAura, 3.8.0): a see-through
// envelope added on top of the scene. Brighter at its edges (fresnel) and at the feet, almost
// nothing in its middle, so the face and the gear show through it; value noise that rises
// with the time ripples it like a slow flame, and a slow sine makes it breathe. Works in the
// Compatibility renderer (the web and the phones), like hero_rim.gdshader.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec3 aura_color : source_color = vec3(1.0, 0.85, 0.45);
// The whole glow (HeroAura.flash() raises it for a moment).
uniform float strength = 0.55;
uniform float rim_power = 2.2;
// The envelope's height in its own units (HeroAura: the capsule is centred on its origin).
uniform float height = 1.9;
// Seconds of one breath, and how fine and how fast the ripple rises.
uniform float breath_s = 2.0;
uniform float ripple = 5.0;
uniform float rise_speed = 0.7;

// 0 at the feet, 1 at the top; and a coordinate across the envelope with no seam.
varying float rel_height;
varying float across;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	rel_height = clamp(VERTEX.y / height + 0.5, 0.0, 1.0);
	across = (VERTEX.x - VERTEX.z) * 3.0;
}

void fragment() {
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - facing, rim_power);
	float feet = (1.0 - rel_height) * (1.0 - rel_height);
	float flame = value_noise(vec2(across, rel_height * ripple - TIME * rise_speed));
	float breath = 0.75 + 0.25 * sin(TIME * TAU / breath_s);
	float glow = (rim + feet * 0.4) * (0.5 + 0.7 * flame) * (1.0 - 0.5 * rel_height);
	ALBEDO = aura_color * glow * breath * strength;
}
