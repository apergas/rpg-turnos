// The bestiary portrait of an enemy seen but not beaten (2.7.0): desaturated and blended
// toward a light wash colour, so dark sprites get lighter, never darker. One material shared
// by every such card; BestiaryPage sets the uniforms from UiTokens (portrait-seen and
// opacity-portrait-desaturate).
shader_type canvas_item;

// rgb: the wash colour; a: how much of it is blended in.
uniform vec4 wash : source_color = vec4(0.72, 0.72, 0.8, 0.45);
uniform float desaturate = 0.8;

void fragment() {
	vec4 tex = COLOR; // the texture, already sampled
	float grey = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 rgb = mix(tex.rgb, vec3(grey), desaturate);
	rgb = mix(rgb, wash.rgb, wash.a);
	COLOR = vec4(rgb, tex.a);
}
