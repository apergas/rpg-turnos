class_name EncounterMeter extends RefCounted
## Random encounter rule. Only meters walked on grass count. After reset() the first
## GRACE_M meters are free; after that every full meter has CHANCE_PER_M of a battle.

const GRACE_M := 15.0
const CHANCE_PER_M := 0.006

var _rng: RandomNumberGenerator
var _grace := GRACE_M
## Meters walked past the grace that have not been rolled yet (always < 1).
var _walked := 0.0


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


## Gives the grace distance again (start, back from a battle, respawn).
func reset() -> void:
	_grace = GRACE_M
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
		if _rng.randf() < CHANCE_PER_M:
			reset()
			return true
	return false
