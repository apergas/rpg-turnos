// The golden aura of the hero at the game's top level (HeroAura, 3.8.0): a see-through,
// flame-like envelope added on top of the scene. Wide round the body and the feet, narrower and
// taller than the hero, whose top breaks up into soft tongues: scrolling value noise rises along
// the height and cuts the glow more and more towards the top, so there is no smooth dome and no
// hard outline. A slow sine makes it breathe. The glow shows from above too (the map's camera).
// No screen texture: works in the Compatibility renderer (the web and the phones).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec3 aura_color : source_color = vec3(1.0, 0.6, 0.2);
// The whole glow (HeroAura.flash() raises it for a moment).
uniform float strength = 1.0;
// The envelope's height in metres (HeroAura: the capsule is centred on its origin).
uniform float height = 2.7;
// Seconds of one breath, noise cells per metre and metres per second the noise rises.
uniform float breath_s = 2.0;
uniform float ripple = 2.6;
uniform float rise_speed = 1.3;

varying vec3 opos;
varying float rel_height;

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
	// Wide at the feet, narrow at the top.
	VERTEX.xz *= mix(1.3, 0.65, rel_height);
	opos = VERTEX;
}

void fragment() {
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float edge = 1.0;
	// Soft outside, strongest just inside the silhouette, thin in the middle (the face).
	float soft = smoothstep(0.0, 0.75, facing) * (1.0 - 0.45 * smoothstep(0.5, 1.0, facing));
	float t = TIME * rise_speed;
	float y = opos.y * ripple;
	float n1 = value_noise(vec2(opos.x * 2.5 + opos.z * 1.7, y - t * ripple));
	float n2 = value_noise(vec2(opos.x * 5.0 - opos.z * 4.1 + 7.0, y * 2.0 - t * 2.0 * ripple));
	float flame = 0.6 * n1 + 0.4 * n2;
	float cut = clamp(flame * 1.4 + 0.75 - rel_height * 1.3, 0.0, 1.0);
	float tongues = smoothstep(0.0, 0.5, cut);
	float low = (1.0 - 0.5 * rel_height) * (1.0 - smoothstep(0.85, 1.0, rel_height));
	float breath = 0.8 + 0.2 * sin(TIME * TAU / breath_s);
	float glow = edge * soft * tongues * low * (0.2 + 1.4 * flame);
	ALBEDO = aura_color * glow * breath * strength;
}
