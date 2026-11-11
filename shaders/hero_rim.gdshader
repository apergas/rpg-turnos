// The map hero's soft rim of light (2.4.0), as a material_overlay of each of his meshes:
// added on top of whatever they show, the same in sun and shade. A warm white edge where
// the surface turns away from the camera, and a faint warm light of his own so the dark
// tunic never goes black under a tree's shadow.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec3 rim_color : source_color = vec3(1.0, 0.93, 0.8);
uniform float rim_strength = 0.25;
uniform float rim_power = 3.0;
uniform vec3 self_color : source_color = vec3(1.0, 0.86, 0.7);
// Linear: about 0.03-0.05 (chosen with frames in the sun, the shade, the mine and a phone).
uniform float self_strength = 0.03;

void fragment() {
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - facing, rim_power) * rim_strength;
	ALBEDO = rim_color * rim + self_color * self_strength;
}
