class_name BlackSun extends RefCounted
## Constructor: the black sun of the v3's sky (ZoneData.black_sun; 3.0.0): a black disc with a
## light-blue corona, the same drawing as the Ala de viaje's portal (portal_swirl.gdshader with
## its corona) but dark and slow, hung low over the north, left of where the enemies stand in
## battle. BattleStage.build_environment() adds it to the map and to the battles; only the
## battle camera sees that much sky. Static only, keeps no state.

const SWIRL_SHADER := preload("res://shaders/portal_swirl.gdshader")
## Where it hangs and how big its quad is; the disc fills 1 / CORONA_SCALE of the quad, the
## corona the rest (TravelPortal's proportion).
const POSITION := Vector3(-24, 9, -95)
const SIZE := 38.0
const CORONA_SCALE := 2.1
## The swirl's colours, near black, and its edge, the corona's light blue.
const CORE := Color(0.01, 0.01, 0.03)
const SWIRL := Color(0.05, 0.04, 0.1)
const EDGE := Color(0.55, 0.75, 1.0)
const SPIN := 0.08


static func add(root: Node3D) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * SIZE
	var material := ShaderMaterial.new()
	material.shader = SWIRL_SHADER
	material.set_shader_parameter("corona", true)
	material.set_shader_parameter("disc", 1.0 / CORONA_SCALE)
	material.set_shader_parameter("core_color", CORE)
	material.set_shader_parameter("swirl_color", SWIRL)
	material.set_shader_parameter("edge_color", EDGE)
	material.set_shader_parameter("spin", SPIN)
	var sun := MeshInstance3D.new()
	sun.name = "BlackSun"
	sun.mesh = quad
	sun.material_override = material
	sun.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sun.position = POSITION
	root.add_child(sun)
