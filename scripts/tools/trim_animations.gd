@tool
extends EditorScenePostImport
## Import script for the KayKit character models: each GLB ships about 90 animation clips
## and the game plays only a handful, so every other clip is removed at import time.
## Not part of the exported game (excluded in export_presets.cfg).

## Clips the game plays (BattleActor's CHARACTER_ANIMS, SKELETON_ANIMS and ROGUE_ANIMS)
## plus the rest pose.
const KEEP := [
	"RESET",
	"Idle",
	"Running_A",
	"Walking_D_Skeletons",
	"1H_Melee_Attack_Slice_Diagonal",
	"Dualwield_Melee_Attack_Stab",
	"Spellcast_Shoot",
	"Hit_A",
	"Hit_B",
	"Dodge_Backward",
	"Death_A",
	"Death_C_Skeletons",
	"Cheer",
	"Taunt",
]


func _post_import(scene: Node) -> Object:
	for node in scene.find_children("*", "AnimationPlayer", true, false):
		var player := node as AnimationPlayer
		for library_name in player.get_animation_library_list():
			var library := player.get_animation_library(library_name)
			for anim_name in library.get_animation_list():
				if not KEEP.has(str(anim_name)):
					library.remove_animation(anim_name)
	return scene
