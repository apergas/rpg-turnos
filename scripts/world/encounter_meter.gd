class_name EncounterMeter extends RefCounted
## Random encounter rule. Only meters walked on grass count. After reset() the first
## grace_m meters are free; after that every full meter has chance_per_m of a battle.
## Each zone sets its own pace (ZoneData.encounter_grace / encounter_chance); the
## meadow and the forest use 5 m and 2.5 %: a battle every ~45 m of grass, ~9 s at 5 m/s.
## rate halves them past a zone's exit level (level_rate()).

const GRACE_M := 5.0
const CHANCE_PER_M := 0.025
## Dragon Quest's rule: a hero LEVEL_GAP levels past a zone's exit_level meets its monsters
## at CALM_RATE, the weak ones keep away.
const LEVEL_GAP := 4
const CALM_RATE := 0.5

var grace_m := GRACE_M
var chance_per_m := CHANCE_PER_M
## Multiplies chance_per_m (World.set_encounter_rate()).
var rate := 1.0

var _rng: RandomNumberGenerator
var _grace := GRACE_M
## Meters walked past the grace that have not been rolled yet (always < 1).
var _walked := 0.0


func _init(rng: RandomNumberGenerator, p_grace_m := GRACE_M, p_chance_per_m := CHANCE_PER_M) -> void:
	_rng = rng
	grace_m = p_grace_m
	chance_per_m = p_chance_per_m
	_grace = grace_m


## The encounter rate for a hero of hero_level in a zone with that exit_level.
static func level_rate(hero_level: int, exit_level: int) -> float:
	return CALM_RATE if exit_level > 0 and hero_level >= exit_level + LEVEL_GAP else 1.0


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
		if _rng.randf() < chance_per_m * rate:
			reset()
			return true
	return false
