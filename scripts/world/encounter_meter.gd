class_name EncounterMeter extends RefCounted
## Random encounter rule. Only meters walked on grass count. After reset() the first
## grace_m meters are free; after that every full meter has chance_per_m of a battle.
## Each zone sets its own pace (ZoneData.encounter_grace / encounter_chance); the
## meadow and the forest use 9 m and 1 %: a battle every ~110 m, ~22 s walking at 5 m/s.

const GRACE_M := 9.0
const CHANCE_PER_M := 0.01

var grace_m := GRACE_M
var chance_per_m := CHANCE_PER_M

var _rng: RandomNumberGenerator
var _grace := GRACE_M
## Meters walked past the grace that have not been rolled yet (always < 1).
var _walked := 0.0


func _init(rng: RandomNumberGenerator, p_grace_m := GRACE_M, p_chance_per_m := CHANCE_PER_M) -> void:
	_rng = rng
	grace_m = p_grace_m
	chance_per_m = p_chance_per_m
	_grace = grace_m


## Gives the grace distance again (start, back from a battle, respawn).
func reset() -> void:
	_grace = grace_m
	_walked = 0.0


## Adds the meters walked this frame. Returns true when a battle starts.
func advance(meters: float, in_grass: bool) -> bool:
	if not in_grass or meters <= 0.0:
		return false
	if _grace > 0.0:
		var used := minf(_grace, meters)
		_grace -= used
		meters -= used
	_walked += meters
	while _walked >= 1.0:
		_walked -= 1.0
		if _rng.randf() < chance_per_m:
			reset()
			return true
	return false
