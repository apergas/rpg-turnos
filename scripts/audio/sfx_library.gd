class_name SfxLibrary extends RefCounted
## Sound effects in the style of sfxr, synthesized in code. Each effect is a
## Dictionary of parameters: wave ("square", "triangle" or "noise"), "from" and "to"
## (pitch in Hz at the start and at the end, slid linearly; for noise it is how many
## new random values per second), "time" (seconds), "volume", "decay" (power of the
## fade-out: 1 is linear, higher fades sooner) and optional "notes" (pitches in Hz
## played one after the other, each "time" long, instead of the slide). build()
## caches each stream.

const CURSOR := "cursor"
const ACCEPT := "accept"
const CANCEL := "cancel"
const HIT := "hit"
const CRIT := "crit"
const MISS := "miss"
const FIRE := "fire"
const HEAL := "heal"
const LEVEL_UP := "level_up"
const ENCOUNTER := "encounter"
const POTION := "potion"
const STEP := "step"
const DIALOGUE := "dialogue"
const SAVE := "save"
const IDS: Array[String] = [CURSOR, ACCEPT, CANCEL, HIT, CRIT, MISS, FIRE, HEAL, LEVEL_UP,
	ENCOUNTER, POTION, STEP, DIALOGUE, SAVE]

const NOISE_SEED := 4321
## Samples of fade-in at the start of every sound (no click).
const FADE_IN := 40
const SOUNDS := {
	CURSOR: {"wave": "square", "from": 880.0, "to": 880.0, "time": 0.04, "volume": 0.25,
		"decay": 1.0},
	ACCEPT: {"wave": "square", "notes": [660.0, 990.0], "time": 0.06, "volume": 0.3,
		"decay": 1.0},
	CANCEL: {"wave": "square", "from": 440.0, "to": 220.0, "time": 0.09, "volume": 0.3,
		"decay": 1.0},
	HIT: {"wave": "noise", "from": 6000.0, "to": 900.0, "time": 0.16, "volume": 0.6,
		"decay": 2.0},
	CRIT: {"wave": "noise", "from": 9000.0, "to": 400.0, "time": 0.35, "volume": 0.75,
		"decay": 1.5},
	MISS: {"wave": "triangle", "from": 500.0, "to": 1400.0, "time": 0.14, "volume": 0.4,
		"decay": 1.0},
	FIRE: {"wave": "noise", "from": 1200.0, "to": 5000.0, "time": 0.5, "volume": 0.55,
		"decay": 1.2},
	HEAL: {"wave": "triangle", "notes": [523.25, 659.26, 783.99, 1046.5], "time": 0.07,
		"volume": 0.5, "decay": 0.5},
	LEVEL_UP: {"wave": "square", "notes": [523.25, 659.26, 783.99, 1046.5, 783.99, 1046.5],
		"time": 0.09, "volume": 0.3, "decay": 0.3},
	ENCOUNTER: {"wave": "square", "notes": [1046.5, 880.0, 698.46, 1046.5, 880.0, 698.46],
		"time": 0.05, "volume": 0.3, "decay": 0.5},
	POTION: {"wave": "triangle", "from": 300.0, "to": 900.0, "time": 0.22, "volume": 0.5,
		"decay": 1.0},
	STEP: {"wave": "noise", "from": 2500.0, "to": 900.0, "time": 0.05, "volume": 0.12,
		"decay": 2.0},
	DIALOGUE: {"wave": "square", "notes": [1318.5, 1760.0], "time": 0.03, "volume": 0.2,
		"decay": 1.0},
	SAVE: {"wave": "triangle", "notes": [783.99, 987.77, 1174.66, 1567.98], "time": 0.08,
		"volume": 0.5, "decay": 0.5},
}

static var _cache := {}


## Drops the cached streams (see MusicLibrary.clear_cache()).
static func clear_cache() -> void:
	_cache.clear()


static func build(id: String) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	var sound: Dictionary = SOUNDS[id]
	var samples := PackedFloat32Array()
	if sound.has("notes"):
		for pitch: float in sound.notes:
			samples.append_array(_render(sound, pitch, pitch))
	else:
		samples = _render(sound, sound.from, sound.to)
	var stream := MusicLibrary.to_stream(samples)
	_cache[id] = stream
	return stream


## One slide from pitch_from to pitch_to, sound.time long, fading out.
static func _render(sound: Dictionary, pitch_from: float, pitch_to: float) -> PackedFloat32Array:
	var rate := MusicLibrary.RATE
	var count := int(float(sound.time) * rate)
	var volume: float = sound.volume
	var decay: float = sound.decay
	var wave: String = sound.wave
	var rng := RandomNumberGenerator.new()
	rng.seed = NOISE_SEED
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	var held := 0.0
	for i in count:
		var t := float(i) / count
		var pitch := lerpf(pitch_from, pitch_to, t)
		phase += pitch / rate
		var wrapped := phase >= 1.0
		if wrapped:
			phase -= floorf(phase)
		var value: float
		match wave:
			"noise":
				if wrapped:
					held = rng.randf_range(-1.0, 1.0)
				value = held
			"triangle":
				value = 4.0 * absf(phase - 0.5) - 1.0
			_:
				value = 1.0 if phase < 0.5 else -1.0
		var env := pow(1.0 - t, decay)
		if i < FADE_IN:
			env *= float(i) / FADE_IN
		samples[i] = value * volume * env
	return samples
