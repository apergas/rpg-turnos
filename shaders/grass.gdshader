// Tall grass for Vegetation tufts (MultiMesh instances). UV.y runs from 0 at the blade
// base to 1 at its tip; INSTANCE_CUSTOM.rgb holds the tuft's tip colour. The tips sway
// with the wind and bend away from `pusher` (the player on the world map).
shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform vec3 base_color : source_color = vec3(0.16, 0.32, 0.1);
// Far below the ground by default, so nothing is pushed until set_pusher() is called.
uniform vec3 pusher = vec3(0.0, -100.0, 0.0);
uniform float push_radius = 0.8;
uniform float push_strength = 0.25;
uniform float wind_strength = 0.08;
uniform float wind_speed = 1.6;

varying vec3 tip_color;

void vertex() {
	float bend = UV.y * UV.y;
	vec3 root = MODEL_MATRIX[3].xyz;
	float wave = sin(TIME * wind_speed + root.x * 0.35 + root.z * 0.25);
	vec3 offset = vec3(wave, 0.0, wave * 0.5) * wind_strength * bend;
	vec2 away = root.xz - pusher.xz;
	float dist = length(away);
	if (dist < push_radius && dist > 0.001 && abs(root.y - pusher.y) < 2.0) {
		float k = (1.0 - dist / push_radius) * push_strength * bend;
		offset.xz += normalize(away) * k;
		offset.y -= k * 0.5;
	}
	// The offset is in world space; the vertex is in the instance's (scaled, turned) space.
	VERTEX += (inverse(MODEL_MATRIX) * vec4(offset, 0.0)).xyz;
	tip_color = INSTANCE_CUSTOM.rgb;
}

void fragment() {
	ALBEDO = mix(base_color, tip_color, UV.y);
	ROUGHNESS = 1.0;
	// Lit like the ground under it, so thin blades never flash dark or bright.
	NORMAL = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
}
