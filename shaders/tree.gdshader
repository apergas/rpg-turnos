// Trees, bushes and the Kenney decoration of the map (MultiMesh instances and merged
// chunks): looks like the model's own material, or its vertex colours. Nothing is cut
// away: a crown may hide the hero (the user's choice, 2.4.0), and its shadow stays whole.
shader_type spatial;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float roughness_value = 1.0;
uniform bool use_texture = true;
// The mesh's vertex colours (sRGB) are the albedo (the Kenney decoration, one surface).
uniform bool use_vertex_color = false;

void fragment() {
	vec4 color = (use_texture ? texture(albedo_texture, UV) : vec4(1.0)) * albedo_color;
	if (use_vertex_color) {
		vec3 srgb = COLOR.rgb;
		color.rgb = mix(srgb / 12.92, pow((srgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, srgb));
	}
	ALBEDO = color.rgb;
	ROUGHNESS = roughness_value;
}
