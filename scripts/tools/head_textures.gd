extends SceneTree
## Writes the heads of the caravan's people (2.4.0) and of Brumaclara's (3.8.0, the skin
## "bruma"): the Knight's atlas with the hair cell recoloured and the face's skin cell too, to
## assets/characters/head_<hair>_<skin>.png. Prints each hair's mean colour (BattleActor's hair
## pieces use it) and the face's (ActorLooksV3.SKIN_MIST matches the arms to it). Run headless,
## then --import and set mipmaps/generate=true in each new .import (like
## hero_head_texture.png's), and --import again:
## tools/godot.cmd --headless --path . --script res://scripts/tools/head_textures.gd
## Excluded from the exports (scripts/tools/*).

const SOURCE := "res://assets/characters/Knight_knight_texture.png"
const OUT := "res://assets/characters/head_%s.png"
## The hair cell: where hero_head_texture.png differs from the source atlas.
const HAIR_RECT := Rect2i(128, 0, 128, 256)
## The face's skin cell (the atlas is 8 x 4 cells of 128 x 256; only Knight_Head uses cell
## (0, 0), the arms and legs use other cells: the arms of each figure get their skin by tint).
const FACE_RECT := Rect2i(0, 0, 128, 256)
## Each hair's mean colour (sRGB); the cell keeps its own shading.
const HAIRS := {
	"gris": Color(0.62, 0.62, 0.6),
	"negro": Color(0.13, 0.11, 0.1),
	"rubio": Color(0.86, 0.7, 0.38),
	"pelirrojo": Color(0.72, 0.3, 0.13),
	"castano": Color(0.3, 0.19, 0.11),
}
## Each skin over the face cell: [factor, share of its saturation it then loses, tint over
## that]. "clara" is the hero's skin (unchanged); "bruma" (3.8.0) is the lavender blue grey of
## someone who breathes the Niebla: mostly grey, then a touch of blue.
const SKINS := {
	"clara": [Color(1, 1, 1), 0.0, Color(1, 1, 1)],
	"morena": [Color(0.78, 0.62, 0.5), 0.0, Color(1, 1, 1)],
	"palida": [Color(1.0, 0.94, 0.9), 0.15, Color(1, 1, 1)],
	"bruma": [Color(1, 1, 1), 0.7, Color(0.84, 0.86, 1.04)],
}
## Only the heads in use: [hair, skin].
const HEADS := [["gris", "clara"], ["negro", "morena"], ["pelirrojo", "clara"],
	["rubio", "clara"], ["castano", "morena"], ["castano", "palida"],
	["gris", "bruma"], ["rubio", "bruma"], ["pelirrojo", "bruma"], ["castano", "bruma"]]


func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	source.convert(Image.FORMAT_RGBA8)
	var done := {}
	for head: Array in HEADS:
		var image := source.duplicate() as Image
		_recolour_hair(image, HAIRS[head[0]])
		var file_name: String = head[0]
		_recolour_skin(image, FACE_RECT, SKINS[head[1]])
		file_name += "_" + head[1]
		if done.has(file_name):
			continue
		done[file_name] = true
		image.save_png(ProjectSettings.globalize_path(OUT % file_name))
		print("%s: pelo medio %s, cara media %s" % [file_name, _mean(image, HAIR_RECT),
			_mean(image, FACE_RECT)])
	quit()


func _recolour_hair(image: Image, target: Color) -> void:
	var mean := _luma(_mean(image, HAIR_RECT))
	for y in range(HAIR_RECT.position.y, HAIR_RECT.end.y):
		for x in range(HAIR_RECT.position.x, HAIR_RECT.end.x):
			var c := image.get_pixel(x, y)
			var k := _luma(c) / maxf(mean, 0.001)
			image.set_pixel(x, y, Color(clampf(target.r * k, 0, 1), clampf(target.g * k, 0, 1),
				clampf(target.b * k, 0, 1), c.a))


## The face cell times skin[0], losing skin[1] of its saturation, times skin[2] (SKINS).
func _recolour_skin(image: Image, rect: Rect2i, skin: Array) -> void:
	var factor: Color = skin[0]
	var grey: float = skin[1]
	var tint: Color = skin[2]
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c := image.get_pixel(x, y)
			var out := Color(c.r * factor.r, c.g * factor.g, c.b * factor.b, c.a)
			var l := _luma(out)
			out = out.lerp(Color(l, l, l, c.a), grey)
			image.set_pixel(x, y, Color(clampf(out.r * tint.r, 0, 1), clampf(out.g * tint.g, 0, 1),
				clampf(out.b * tint.b, 0, 1), c.a))


static func _mean(image: Image, rect: Rect2i) -> Color:
	var sum := Color(0, 0, 0, 0)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			sum += image.get_pixel(x, y)
	return sum / float(rect.size.x * rect.size.y)


static func _luma(c: Color) -> float:
	return c.r * 0.299 + c.g * 0.587 + c.b * 0.114
