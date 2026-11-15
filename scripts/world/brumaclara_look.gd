class_name BrumaclaraLook extends RefCounted
## Brumaclara dressed for the v3's etapa (3.0.0), as CampLook dresses the Caravana for its tramo:
## the same layout (houses, figures, exits, wells, the lighthouse), with what comes back to the
## village with each boss beaten: light in the lighthouse and in the windows (BrumaclaraStage
## draws them), a lighter fog... data/zones/brumaclara.tres is the etapa 1, all dark. Pure:
## dressed() returns a copy of the zone; ZoneTravel builds Brumaclara from it. The figures that
## come back (the Curandera...) are the zone's own, by their needs flags.

const ZONE := "brumaclara"
## etapa -> the fields that change from the .tres: the whole look of that etapa (an etapa with
## no entry looks like the last one before it). 2, the Garza beaten: the lighthouse lit, the
## inn and a few windows with light, a little less fog.
const LOOKS := {
	2: {"lighthouse_lit": true, "fog_density": 0.018,
		"window_lights": [[Vector3(8.95, 1.6, -6.2), -90.0], [Vector3(8.95, 1.6, -3.8), -90.0],
			[Vector3(-9.55, 1.5, -5.6), 90.0], [Vector3(8.6, 1.5, 11.2), 180.0]]},
}


## A copy of Brumaclara dressed for etapa (GameState.etapa()); zone itself up to the etapa 1.
static func dressed(zone: ZoneData, etapa: int) -> ZoneData:
	var step := 0
	for e: int in LOOKS:
		if e <= etapa:
			step = maxi(step, e)
	if step == 0:
		return zone
	var town := zone.duplicate() as ZoneData
	town.look_key = "etapa%d" % step
	var look: Dictionary = LOOKS[step]
	for field: String in look:
		var value: Variant = look[field]
		# A fresh array: duplicate() is shallow, so the cached zone's own would change.
		town.set(field, (value as Array).duplicate(true) if value is Array else value)
	return town
