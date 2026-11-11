class_name AmbientLibrary extends RefCounted
## The sound of each place (ZoneData.ambient), synthesized in code like MusicLibrary and
## SfxLibrary: no audio files. Each ambient is a bed that loops (bed(): filtered noise, LOOP
## seconds, its end cross-faded into its start so the loop has no seam) and short sounds that
## AudioDirector drops on it every gap() seconds (shot(): a trill in the meadow, a bird in
## the forest, a drop with its echo in the mine, a gust whistling in the castle, a gust of sand
## in the desert, whose bed is a low wind with the hiss of sand). Streams
## are 22050 Hz, 16-bit mono (MusicLibrary.to_stream()) and cached.

const MEADOW := "meadow"
const FOREST := "forest"
const MINE := "mine"
const CASTLE := "castle"
const JUNGLE := "jungle"
const DESERT := "desert"
const IDS: Array[String] = [MEADOW, FOREST, MINE, CASTLE, JUNGLE, DESERT]

## Seconds of each bed, and of the cross-fade that closes its loop.
const LOOP := 8.0
const SEAM := 0.5
## Short sounds of each ambient; AudioDirector picks one at random each time.
const VARIANTS := 4
## Seconds between two short sounds: [least, most].
const GAPS := {MEADOW: [2.0, 6.0], FOREST: [3.0, 7.0], MINE: [1.0, 4.0], CASTLE: [4.0, 9.0],
	JUNGLE: [1.5, 4.0], DESERT: [3.0, 8.0]}
## Peak of each bed and of every short sound (AudioDirector plays them at the effects volume
## × its AMBIENT_SHARE).
const BED_PEAK := {MEADOW: 0.35, FOREST: 0.4, MINE: 0.5, CASTLE: 0.35, JUNGLE: 0.35, DESERT: 0.4}
const SHOT_PEAK := 0.55
## The echoes of a drop in the mine: [delay in seconds, gain].
const ECHOES := [[0.17, 0.45], [0.34, 0.2], [0.51, 0.08]]
## Samples of fade-in of a drop (no click).
const DROP_FADE_IN := 40
const NOISE_SEED := 777

static var _beds := {}
static var _shots := {}


## Drops the cached streams (AudioDirector calls it when it leaves the tree, so no stream
## outlives the game at exit).
static func clear_cache() -> void:
	_beds.clear()
	_shots.clear()


## Seconds until the next short sound of id.
static func gap(id: String, rng: RandomNumberGenerator) -> float:
	var limits: Array = GAPS[id]
	return rng.randf_range(limits[0], limits[1])


## Builds the bed and every short sound of id now (Game calls it under black, so the first
## play never stalls). Nothing for "" or an unknown id.
static func prepare(id: String) -> void:
	if not id in IDS:
		return
	bed(id)
	for variant in VARIANTS:
		shot(id, variant)


## The loop of id, computed on the first call: LOOP seconds, its last SEAM seconds of noise
## faded into its first ones, so the sample after the end is the one that followed it.
static func bed(id: String) -> AudioStreamWAV:
	if _beds.has(id):
		return _beds[id]
	var count := int(LOOP * MusicLibrary.RATE)
	var seam := int(SEAM * MusicLibrary.RATE)
	var rng := RandomNumberGenerator.new()
	rng.seed = NOISE_SEED + IDS.find(id)
	var raw: PackedFloat32Array
	match id:
		MEADOW:
			raw = _breeze(count + seam, rng)
		FOREST:
			raw = _leaves(count + seam, rng)
		MINE:
			raw = _rumble(count + seam, rng)
		JUNGLE:
			raw = _insects(count + seam, rng)
		DESERT:
			raw = _sand_wind(count + seam, rng)
		_:
			raw = _wind(count + seam, rng)
	var samples := raw.slice(0, count)
	for i in seam:
		var t := float(i) / seam
		# Equal power: two unrelated noises add in power, so the bed keeps its level.
		samples[i] = raw[i] * sin(t * PI / 2.0) + raw[count + i] * cos(t * PI / 2.0)
	_normalize(samples, BED_PEAK[id])
	var stream := MusicLibrary.to_stream(samples)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	_beds[id] = stream
	return stream


## Short sound variant (0 .. VARIANTS - 1) of id, computed on the first call.
static func shot(id: String, variant: int) -> AudioStreamWAV:
	var key := "%s_%d" % [id, variant]
	if _shots.has(key):
		return _shots[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = NOISE_SEED * 31 + IDS.find(id) * VARIANTS + variant
	var samples: PackedFloat32Array
	match id:
		MEADOW:
			samples = _trill(rng)
		FOREST:
			samples = _bird(rng)
		MINE:
			samples = _drop(rng)
		JUNGLE:
			samples = _jungle_bird(rng)
		DESERT:
			samples = _sand_gust(rng)
		_:
			samples = _gust(rng)
	_normalize(samples, SHOT_PEAK)
	var stream := MusicLibrary.to_stream(samples)
	_shots[key] = stream
	return stream


## The meadow: a soft breeze, noise low-passed twice at 500 Hz, swelling slowly.
static func _breeze(count: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(count)
	var a := _pole(500.0)
	var y1 := 0.0
	var y2 := 0.0
	for i in count:
		var t := float(i) / MusicLibrary.RATE
		y1 += a * (rng.randf_range(-1.0, 1.0) - y1)
		y2 += a * (y1 - y2)
		var swell := 0.55 + 0.3 * sin(TAU * 0.13 * t) + 0.15 * sin(TAU * 0.37 * t + 1.0)
		out[i] = y2 * swell
	return out


## The forest: a deeper wind (low-passed twice at 220 Hz) and leaves rustling in gusts (the
## band between 1200 and 3000 Hz).
static func _leaves(count: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(count)
	var low_a := _pole(220.0)
	var high_a := _pole(3000.0)
	var mid_a := _pole(1200.0)
	var l1 := 0.0
	var l2 := 0.0
	var high := 0.0
	var mid := 0.0
	for i in count:
		var t := float(i) / MusicLibrary.RATE
		var x := rng.randf_range(-1.0, 1.0)
		l1 += low_a * (x - l1)
		l2 += low_a * (l1 - l2)
		high += high_a * (x - high)
		mid += mid_a * (x - mid)
		var rustle := maxf(0.0, sin(TAU * 0.21 * t) * sin(TAU * 0.09 * t + 2.0))
		out[i] = l2 * (0.7 + 0.2 * sin(TAU * 0.07 * t)) + (high - mid) * rustle * 0.35
	return out


## The jungle: insects, noise high-passed above 3500 Hz and low-passed at 6500 Hz, pulsing
## slowly in volume.
static func _insects(count: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(count)
	var low_a := _pole(6500.0)
	var high_a := _pole(3500.0)
	var low := 0.0
	var high := 0.0
	for i in count:
		var t := float(i) / MusicLibrary.RATE
		var x := rng.randf_range(-1.0, 1.0)
		low += low_a * (x - low)
		high += high_a * (low - high)
		var pulse := 0.55 + 0.3 * sin(TAU * 0.25 * t) + 0.15 * sin(TAU * 0.61 * t + 1.0)
		out[i] = (low - high) * pulse
	return out


## The mine: a deep rumble, noise low-passed three times at 80 Hz, breathing slowly.
static func _rumble(count: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(count)
	var a := _pole(80.0)
	var y1 := 0.0
	var y2 := 0.0
	var y3 := 0.0
	for i in count:
		var t := float(i) / MusicLibrary.RATE
		y1 += a * (rng.randf_range(-1.0, 1.0) - y1)
		y2 += a * (y1 - y2)
		y3 += a * (y2 - y3)
		out[i] = y3 * (0.8 + 0.2 * sin(TAU * 0.06 * t))
	return out


## The desert: a low wind (noise low-passed twice at 350 Hz) swelling slowly, and the hiss
## of the sand it carries (the band between 2500 and 6000 Hz), loudest at the top of each
## swell.
static func _sand_wind(count: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(count)
	var low_a := _pole(350.0)
	var top_a := _pole(6000.0)
	var bottom_a := _pole(2500.0)
	var l1 := 0.0
	var l2 := 0.0
	var top := 0.0
	var bottom := 0.0
	for i in count:
		var t := float(i) / MusicLibrary.RATE
		var x := rng.randf_range(-1.0, 1.0)
		l1 += low_a * (x - l1)
		l2 += low_a * (l1 - l2)
		top += top_a * (x - top)
		bottom += bottom_a * (x - bottom)
		var swell := 0.5 + 0.3 * sin(TAU * 0.09 * t) + 0.2 * sin(TAU * 0.23 * t + 2.0)
		out[i] = 2.0 * l2 * swell + 0.4 * (top - bottom) * pow(swell, 3.0)
	return out


## A gust of sand: 1.5 to 2.5 s of noise through a band-pass that rises from 2500 Hz to its
## top and falls back, swelling and dying away.
static func _sand_gust(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count := int(rng.randf_range(1.5, 2.5) * MusicLibrary.RATE)
	var peak := rng.randf_range(3800.0, 5000.0)
	var out := PackedFloat32Array()
	out.resize(count)
	var band := PackedFloat32Array()
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in count:
		var u := float(i) / count
		if i % 32 == 0:
			band = _band(lerpf(2500.0, peak, sin(PI * u)), 3.0)
		var x := rng.randf_range(-1.0, 1.0)
		var y := band[0] * x + band[1] * x2 - band[2] * y1 - band[3] * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		out[i] = y * pow(sin(PI * u), 1.5)
	return out


## The castle: wind whistling through the walls in gusts (noise through a narrow band-pass
## whose centre wanders around 700 Hz) over a low hiss.
static func _wind(count: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(count)
	var low_a := _pole(300.0)
	var low := 0.0
	var band := PackedFloat32Array()
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in count:
		var t := float(i) / MusicLibrary.RATE
		if i % 32 == 0:
			band = _band(700.0 + 200.0 * sin(TAU * 0.05 * t) + 60.0 * sin(TAU * 0.23 * t), 12.0)
		var x := rng.randf_range(-1.0, 1.0)
		var y := band[0] * x + band[1] * x2 - band[2] * y1 - band[3] * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		low += low_a * (x - low)
		var gust := pow(maxf(0.0, sin(TAU * 0.11 * t)), 2.0)
		out[i] = 3.0 * y * (0.25 + 0.75 * gust) + 0.25 * low
	return out


## A meadow bird: 2 to 4 quick rising chirps, high.
static func _trill(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var base := rng.randf_range(2800.0, 4000.0)
	for n in rng.randi_range(2, 4):
		_chirp(out, base, base * 1.25, rng.randf_range(0.05, 0.08))
		_rest(out, rng.randf_range(0.03, 0.06))
		base *= rng.randf_range(0.92, 1.08)
	return out


## A forest bird: two falling notes, lower and longer ("cu-cú").
static func _bird(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var k := rng.randf_range(0.85, 1.15)
	_chirp(out, 1500.0 * k, 1350.0 * k, 0.16)
	_rest(out, 0.12)
	_chirp(out, 1250.0 * k, 1150.0 * k, 0.22)
	_rest(out, 0.05)
	return out


## A jungle bird: two or three quick notes in a square wave, rising or falling.
static func _jungle_bird(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var base := rng.randf_range(1800.0, 2600.0)
	var up := rng.randf() < 0.5
	for n in rng.randi_range(2, 3):
		var hz := base * (1.0 + (0.18 if up else -0.18) * n)
		var count := int(rng.randf_range(0.06, 0.1) * MusicLibrary.RATE)
		for i in count:
			var u := float(i) / count
			var phase := fmod(hz * float(i) / MusicLibrary.RATE, 1.0)
			out.append((1.0 if phase < 0.5 else -1.0) * 0.5 * sin(PI * u))
		_rest(out, rng.randf_range(0.04, 0.08))
	return out


## A drop in the mine: a short falling "plip" and its ECHOES.
static func _drop(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var rate := MusicLibrary.RATE
	var pitch := rng.randf_range(1400.0, 2200.0)
	var dry := PackedFloat32Array()
	var count := int(0.06 * rate)
	var phase := 0.0
	for i in count:
		var u := float(i) / count
		phase += pitch * pow(0.4, u) / rate
		var env := pow(1.0 - u, 2.0) * minf(1.0, float(i) / DROP_FADE_IN)
		dry.append(sin(TAU * phase) * env)
	var last: Array = ECHOES[ECHOES.size() - 1]
	var out := PackedFloat32Array()
	out.resize(dry.size() + int(float(last[0]) * rate) + 1)
	out.fill(0.0)
	for i in dry.size():
		out[i] += dry[i]
	for echo: Array in ECHOES:
		var start := int(float(echo[0]) * rate)
		for i in dry.size():
			out[start + i] += dry[i] * float(echo[1])
	return out


## A gust in the castle: 1.2 to 2 s of noise through a narrow band-pass that rises from
## 500 Hz to its top and falls back, swelling and dying away.
static func _gust(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count := int(rng.randf_range(1.2, 2.0) * MusicLibrary.RATE)
	var top := rng.randf_range(900.0, 1200.0)
	var out := PackedFloat32Array()
	out.resize(count)
	var band := PackedFloat32Array()
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in count:
		var u := float(i) / count
		if i % 32 == 0:
			band = _band(lerpf(500.0, top, sin(PI * u)), 14.0)
		var x := rng.randf_range(-1.0, 1.0)
		var y := band[0] * x + band[1] * x2 - band[2] * y1 - band[3] * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		out[i] = y * pow(sin(PI * u), 1.5)
	return out


## A sine sliding from hz_from to hz_to over seconds, shaped by sin(π·u) so it starts and
## ends at 0 (no clicks), appended to out.
static func _chirp(out: PackedFloat32Array, hz_from: float, hz_to: float,
		seconds: float) -> void:
	var count := int(seconds * MusicLibrary.RATE)
	var phase := 0.0
	for i in count:
		var u := float(i) / count
		phase += lerpf(hz_from, hz_to, u) / MusicLibrary.RATE
		out.append(sin(TAU * phase) * sin(PI * u))


static func _rest(out: PackedFloat32Array, seconds: float) -> void:
	for i in int(seconds * MusicLibrary.RATE):
		out.append(0.0)


## One-pole low-pass coefficient for a cut-off of hz.
static func _pole(hz: float) -> float:
	return 1.0 - exp(-TAU * hz / MusicLibrary.RATE)


## Band-pass biquad (0 dB at its centre) around hz with quality q, normalized:
## [b0, b2, a1, a2] (b1 is 0): y = b0·x + b2·x[-2] − a1·y[-1] − a2·y[-2].
static func _band(hz: float, q: float) -> PackedFloat32Array:
	var w := TAU * hz / MusicLibrary.RATE
	var alpha := sin(w) / (2.0 * q)
	var a0 := 1.0 + alpha
	return PackedFloat32Array([alpha / a0, -alpha / a0, -2.0 * cos(w) / a0,
		(1.0 - alpha) / a0])


## Scales samples so their loudest one is peak.
static func _normalize(samples: PackedFloat32Array, peak: float) -> void:
	var top := 0.0
	for value in samples:
		top = maxf(top, absf(value))
	if top <= 0.0:
		return
	var k := peak / top
	for i in samples.size():
		samples[i] *= k
