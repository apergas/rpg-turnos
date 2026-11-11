// Trees of the map (MultiMesh instances): looks like the model's own material, and thins out
// with a dither pattern along the line from the hero's chest to the camera, so the hero
// never disappears behind a crown. hero_pos below the ground means there is no hero.
shader_type spatial;

global uniform vec3 hero_pos;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float roughness_value = 1.0;
uniform bool use_texture = true;

const float CHEST_HEIGHT = 0.9;
const float HOLE_RADIUS = 1.4;
// Share of the pixels left in the middle of the hole.
const float HOLE_KEEP = 0.2;
const float BAYER[16] = float[16](
	0.03, 0.53, 0.16, 0.66,
	0.78, 0.28, 0.91, 0.41,
	0.22, 0.72, 0.09, 0.59,
	0.97, 0.47, 0.84, 0.34);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (hero_pos.y > -50.0) {
		vec3 chest = hero_pos + vec3(0.0, CHEST_HEIGHT, 0.0);
		vec3 line = CAMERA_POSITION_WORLD - chest;
		float along = clamp(dot(world_pos - chest, line) / dot(line, line), 0.0, 1.0);
		float dist = length(world_pos - (chest + line * along));
		float keep = mix(HOLE_KEEP, 1.0, smoothstep(HOLE_RADIUS * 0.6, HOLE_RADIUS, dist));
		int cell = int(FRAGCOORD.x) % 4 + (int(FRAGCOORD.y) % 4) * 4;
		if (along > 0.0 && BAYER[cell] >= keep) {
			discard;
		}
	}
	vec4 color = (use_texture ? texture(albedo_texture, UV) : vec4(1.0)) * albedo_color;
	ALBEDO = color.rgb;
	ROUGHNESS = roughness_value;
}
