class_name MusicLibrary extends RefCounted
## Original chiptune tracks, written as note tables and synthesized in code into
## AudioStreamWAV (22050 Hz, 16-bit mono): lead in a square wave, bass in a triangle
## and noise drums. build() caches each stream, so a track is only computed once.
##
## Note tables: each voice is a list of bars; a bar is a string of tokens separated by
## spaces. A token is a note with its octave ("C5", "F#4", sharps only) or "r" (rest),
## then "/" and its length in sixteenth notes ("A5/4" is a quarter note). Drum tokens
## are "k" (kick), "s" (snare), "h" (hi-hat) or "r". The lead sets the track's length;
## the bass and the drums repeat from the start until they fill it.

const RATE := 22050
const TITLE := "title"
const MAP := "map"
const VILLAGE := "village"
const FOREST := "forest"
const MINE := "mine"
const CASTLE := "castle"
const BATTLE := "battle"
const BOSS := "boss"
const VICTORY := "victory"
const DEFEAT := "defeat"
const CARAVAN := "caravan"
const IDS: Array[String] = [TITLE, MAP, VILLAGE, FOREST, MINE, CASTLE, BATTLE, BOSS, VICTORY,
	DEFEAT, CARAVAN]

const LEAD_VOLUME := 0.2
const BASS_VOLUME := 0.3
const DRUM_VOLUME := 0.18
## Seconds of fade-in and fade-out of every note (no clicks between notes).
const ATTACK := 0.004
const RELEASE := 0.02
## The lead loses this share of its volume over each note, for a plucked sound.
const LEAD_DECAY := 0.45
## Silence added after a track that does not loop, so its last note can fade.
const TAIL := 0.4
const NOISE_SEED := 1234
const SEMITONES := {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7,
	"G#": 8, "A": 9, "A#": 10, "B": 11}

## bpm, loop, duty of the lead's square wave and the three voices of each track.
const TRACKS := {
	TITLE: {
		"bpm": 96, "loop": true, "duty": 0.5,
		"lead": [
			"C5/4 F5/4 A5/6 G5/2", "F5/4 D5/4 A4/8", "A#4/4 D5/4 F5/6 E5/2", "E5/4 G5/4 C5/8",
			"C5/4 F5/4 A5/4 C6/4", "C6/4 A5/2 G5/2 E5/8", "D5/4 F5/4 A#5/4 G5/4", "F5/12 r/4",
		],
		"bass": [
			"F2/4 C3/4 F3/4 C3/4", "D2/4 A2/4 D3/4 A2/4", "A#1/4 F2/4 A#2/4 F2/4",
			"C2/4 G2/4 C3/4 G2/4", "F2/4 C3/4 F3/4 C3/4", "A1/4 E2/4 A2/4 E2/4",
			"A#1/4 F2/4 C2/4 G2/4", "F2/8 C2/4 F2/4",
		],
		"drums": ["k/4 h/4 s/4 h/4"],
	},
	MAP: {
		"bpm": 132, "loop": true, "duty": 0.5,
		"lead": [
			"G4/2 B4/2 D5/4 B4/2 D5/2 G5/4", "F#5/4 E5/2 D5/2 A4/8",
			"E5/2 G5/2 B5/4 A5/2 G5/2 E5/4", "C5/4 E5/4 G5/4 E5/4",
			"D5/2 G5/2 B5/4 A5/2 G5/2 D5/4", "E5/4 G5/2 E5/2 C5/8",
			"D5/2 F#5/2 A5/4 F#5/2 A5/2 D6/4", "C6/4 A5/4 F#5/8",
			"B5/4 G5/2 E5/2 B4/4 E5/4", "C5/2 E5/2 G5/4 C6/6 B5/2",
			"B5/4 G5/4 D5/4 G5/4", "A5/6 F#5/2 E5/4 D5/4",
			"E5/4 G5/4 C6/4 B5/2 A5/2", "A5/4 F#5/4 D5/4 E5/2 F#5/2",
			"G5/8 D5/4 B4/4", "G4/8 r/8",
		],
		"bass": [
			"G2/4 D3/4 G2/4 D3/4", "D2/4 A2/4 D2/4 A2/4", "E2/4 B2/4 E2/4 B2/4",
			"C2/4 G2/4 C2/4 G2/4", "G2/4 D3/4 G2/4 D3/4", "C2/4 G2/4 C2/4 G2/4",
			"D2/4 A2/4 D2/4 A2/4", "D2/4 A2/4 D2/4 A2/4", "E2/4 B2/4 E2/4 B2/4",
			"C2/4 G2/4 C2/4 G2/4", "G2/4 D3/4 G2/4 D3/4", "D2/4 A2/4 D2/4 A2/4",
			"C2/4 G2/4 C2/4 G2/4", "D2/4 A2/4 D2/4 A2/4", "G2/4 D3/4 G2/4 D3/4",
			"G2/4 D3/4 G2/8",
		],
		"drums": ["k/4 h/2 h/2 s/4 h/2 h/2"],
	},
	# A waltz: 12 sixteenths per bar.
	VILLAGE: {
		"bpm": 120, "loop": true, "duty": 0.25,
		"lead": [
			"F#5/6 A5/4 F#5/2", "E5/8 C#5/4", "D5/4 F#5/4 B5/4", "A5/6 G5/6",
			"F#5/4 E5/4 D5/4", "B4/4 D5/4 G5/4", "E5/6 C#5/2 E5/4", "A4/12",
			"B5/6 A5/2 G5/4", "A5/6 F#5/2 D5/4", "G5/4 E5/4 B4/4", "C#5/6 E5/6",
			"D5/4 F#5/4 A5/4", "B5/4 A5/4 G5/4", "F#5/4 E5/4 C#5/4", "D5/8 r/4",
		],
		"bass": [
			"D2/4 A2/4 A2/4", "A1/4 E2/4 E2/4", "B1/4 F#2/4 F#2/4", "G1/4 D2/4 D2/4",
			"D2/4 A2/4 A2/4", "G1/4 D2/4 D2/4", "A1/4 E2/4 E2/4", "A1/4 E2/4 E2/4",
			"G1/4 D2/4 D2/4", "D2/4 A2/4 A2/4", "E2/4 B2/4 B2/4", "A1/4 E2/4 E2/4",
			"D2/4 A2/4 A2/4", "G1/4 D2/4 D2/4", "A1/4 E2/4 E2/4", "D2/4 A2/4 A2/4",
		],
		"drums": ["k/4 h/4 h/4"],
	},
	# The forest map: slower, in E minor, with a thin lead.
	FOREST: {
		"bpm": 112, "loop": true, "duty": 0.25,
		"lead": [
			"E5/4 G5/4 B5/6 A5/2", "G5/4 F#5/4 E5/8", "D5/4 F#5/4 A5/6 G5/2", "F#5/4 D5/4 B4/8",
			"C5/4 E5/4 G5/4 C6/4", "B5/6 A5/2 G5/4 E5/4", "F#5/4 A5/4 G5/4 F#5/4", "E5/12 r/4",
		],
		"bass": [
			"E2/4 B2/4 E3/4 B2/4", "E2/4 B2/4 E3/4 B2/4", "D2/4 A2/4 D3/4 A2/4",
			"B1/4 F#2/4 B2/4 F#2/4", "C2/4 G2/4 C3/4 G2/4", "G1/4 D2/4 G2/4 D2/4",
			"D2/4 A2/4 B1/4 F#2/4", "E2/8 B1/4 E2/4",
		],
		"drums": ["k/4 h/4 h/2 h/2 s/4"],
	},
	# Slow and in D minor, with sparse drums like dripping water.
	MINE: {
		"bpm": 88, "loop": true, "duty": 0.25,
		"lead": [
			"D5/6 F5/2 A5/8", "G5/4 F5/4 E5/8", "D5/4 E5/4 F5/6 E5/2", "C#5/12 r/4",
			"A4/6 D5/2 F5/8", "E5/4 G5/4 A#5/8", "A5/4 G5/4 F5/4 E5/4", "D5/12 r/4",
		],
		"bass": [
			"D2/4 A2/4 D2/4 A2/4", "C2/4 G2/4 C2/4 G2/4", "A#1/4 F2/4 A#1/4 F2/4",
			"A1/4 E2/4 A1/4 E2/4", "D2/4 A2/4 D2/4 A2/4", "G1/4 D2/4 G1/4 D2/4",
			"A1/4 E2/4 A1/4 C#2/4", "D2/8 A1/8",
		],
		"drums": ["k/4 r/4 h/4 r/2 h/2"],
	},
	# The castle: a slow march in E minor.
	CASTLE: {
		"bpm": 76, "loop": true, "duty": 0.5,
		"lead": [
			"E5/6 G5/2 B5/8", "A5/4 G5/4 F#5/8", "E5/4 F#5/4 G5/4 A5/4", "B5/12 r/4",
			"C6/6 B5/2 A5/8", "G5/4 F#5/4 E5/8", "F#5/4 G5/4 A5/4 D#5/4", "E5/12 r/4",
		],
		"bass": [
			"E2/4 B2/4 E2/4 B2/4", "D2/4 A2/4 D2/4 A2/4", "C2/4 G2/4 C2/4 G2/4",
			"B1/4 F#2/4 B1/4 F#2/4", "A1/4 E2/4 A1/4 E2/4", "E2/4 B2/4 E2/4 B2/4",
			"B1/4 F#2/4 B1/4 D#2/4", "E2/8 B1/8",
		],
		"drums": ["k/4 s/4 k/4 s/2 h/2"],
	},
	BATTLE: {
		"bpm": 150, "loop": true, "duty": 0.5,
		"lead": [
			"A4/2 C5/2 E5/2 A5/2 G5/2 E5/2 C5/2 E5/2", "A5/6 G5/2 E5/4 D5/4",
			"C5/2 F5/2 A5/2 C6/2 A5/4 F5/4", "G5/6 F5/2 D5/4 B4/4",
			"A4/2 C5/2 E5/2 A5/2 B5/2 A5/2 G5/2 E5/2", "C6/6 B5/2 A5/4 E5/4",
			"F5/4 A5/4 C6/4 A5/4", "G#5/8 B5/4 E5/4",
			"D5/4 F5/2 A5/2 D6/6 C6/2", "C6/4 A5/2 E5/2 A5/8",
			"F5/4 A5/2 D6/2 F6/6 E6/2", "E6/4 D6/2 B5/2 G#5/8",
			"A5/2 C6/2 A5/2 F5/2 A5/2 C6/2 F6/4", "D6/2 B5/2 G5/2 D5/2 G5/2 B5/2 D6/4",
			"C6/4 E6/4 A5/4 C6/4", "B5/4 G#5/4 E5/4 B4/4",
		],
		"bass": [
			"A1/2 A2/2 A1/2 A2/2 A1/2 A2/2 A1/2 A2/2", "A1/2 A2/2 A1/2 A2/2 A1/2 A2/2 A1/2 A2/2",
			"F1/2 F2/2 F1/2 F2/2 F1/2 F2/2 F1/2 F2/2", "G1/2 G2/2 G1/2 G2/2 G1/2 G2/2 G1/2 G2/2",
			"A1/2 A2/2 A1/2 A2/2 A1/2 A2/2 A1/2 A2/2", "A1/2 A2/2 A1/2 A2/2 A1/2 A2/2 A1/2 A2/2",
			"F1/2 F2/2 F1/2 F2/2 F1/2 F2/2 F1/2 F2/2", "E1/2 E2/2 E1/2 E2/2 E1/2 E2/2 E1/2 E2/2",
			"D2/2 D3/2 D2/2 D3/2 D2/2 D3/2 D2/2 D3/2", "A1/2 A2/2 A1/2 A2/2 A1/2 A2/2 A1/2 A2/2",
			"D2/2 D3/2 D2/2 D3/2 D2/2 D3/2 D2/2 D3/2", "E1/2 E2/2 E1/2 E2/2 E1/2 E2/2 E1/2 E2/2",
			"F1/2 F2/2 F1/2 F2/2 F1/2 F2/2 F1/2 F2/2", "G1/2 G2/2 G1/2 G2/2 G1/2 G2/2 G1/2 G2/2",
			"A1/2 A2/2 A1/2 A2/2 A1/2 A2/2 A1/2 A2/2", "E1/2 E2/2 E1/2 E2/2 E1/2 E2/2 E1/2 E2/2",
		],
		"drums": ["k/2 h/2 s/2 h/2 k/2 k/2 s/2 h/2"],
	},
	BOSS: {
		"bpm": 168, "loop": true, "duty": 0.25,
		"lead": [
			"E5/2 E5/2 G5/2 E5/2 A#5/4 B5/4", "E5/2 D5/2 E5/2 G5/2 F#5/8",
			"G5/2 G5/2 C6/2 G5/2 E5/4 C5/4", "D#5/6 F#5/2 B5/8",
			"E6/2 B5/2 G5/2 E5/2 E6/2 B5/2 G5/2 E5/2", "F#5/2 G5/2 A5/2 B5/2 C6/4 B5/4",
			"C6/2 G5/2 E5/2 C6/2 D6/4 C6/4", "B5/8 A5/4 F#5/4",
			"A5/4 C6/4 E6/4 C6/4", "D#6/4 B5/4 F#5/4 D#5/4",
			"E5/2 G5/2 B5/2 E6/2 D6/2 B5/2 G5/2 B5/2", "C6/6 B5/2 G5/4 E5/4",
			"A5/2 B5/2 C6/2 E6/2 D6/4 C6/4", "B5/4 A5/4 G5/4 F#5/4",
			"E5/4 G5/4 B5/4 E6/4", "D#6/8 B5/8",
		],
		"bass": [
			"E1/2 E2/2 E1/2 E2/2 E1/2 E2/2 E1/2 E2/2", "E1/2 E2/2 E1/2 E2/2 E1/2 E2/2 E1/2 E2/2",
			"C2/2 C3/2 C2/2 C3/2 C2/2 C3/2 C2/2 C3/2", "B1/2 B2/2 B1/2 B2/2 B1/2 B2/2 B1/2 B2/2",
			"E1/2 E2/2 E1/2 E2/2 E1/2 E2/2 E1/2 E2/2", "E1/2 E2/2 E1/2 E2/2 E1/2 E2/2 E1/2 E2/2",
			"C2/2 C3/2 C2/2 C3/2 C2/2 C3/2 C2/2 C3/2", "B1/2 B2/2 B1/2 B2/2 B1/2 B2/2 B1/2 B2/2",
			"A1/2 A2/2 A1/2 A2/2 A1/2 A2/2 A1/2 A2/2", "B1/2 B2/2 B1/2 B2/2 B1/2 B2/2 B1/2 B2/2",
			"E1/2 E2/2 E1/2 E2/2 E1/2 E2/2 E1/2 E2/2", "C2/2 C3/2 C2/2 C3/2 C2/2 C3/2 C2/2 C3/2",
			"A1/2 A2/2 A1/2 A2/2 A1/2 A2/2 A1/2 A2/2", "B1/2 B2/2 B1/2 B2/2 B1/2 B2/2 B1/2 B2/2",
			"E1/2 E2/2 E1/2 E2/2 E1/2 E2/2 E1/2 E2/2", "B1/2 B2/2 B1/2 B2/2 B1/2 B2/2 B1/2 B2/2",
		],
		"drums": ["k/2 h/2 s/2 k/2 k/2 h/2 s/2 s/2"],
	},
	VICTORY: {
		"bpm": 140, "loop": false, "duty": 0.5,
		"lead": ["C5/2 E5/2 G5/2 C6/2 r/2 G5/2 C6/4", "A#5/4 D6/4 C6/8", "C6/12 r/4"],
		"bass": ["C2/8 G2/8", "A#1/8 C2/8", "C2/12 r/4"],
		"drums": ["k/2 k/2 k/2 k/2 r/8", "s/4 s/4 k/8", "k/4 r/12"],
	},
	DEFEAT: {
		"bpm": 76, "loop": false, "duty": 0.5,
		"lead": ["E5/4 D5/4 C5/4 B4/4", "C5/4 B4/4 A4/8", "A4/12 r/4"],
		"bass": ["A2/8 G2/8", "F2/8 E2/8", "A1/12 r/4"],
		"drums": ["r/48"],
	},
	# The Caravana's camp: a travelling tune in G major.
	CARAVAN: {
		"bpm": 100, "loop": true, "duty": 0.5,
		"lead": [
			"G4/4 B4/4 D5/6 B4/2", "C5/4 E5/4 D5/8", "B4/4 D5/4 G5/6 F#5/2", "E5/4 D5/4 B4/8",
			"C5/4 E5/4 A5/6 G5/2", "F#5/4 D5/4 E5/8", "D5/4 B4/4 A4/4 F#4/4", "G4/12 r/4",
		],
		"bass": [
			"G2/8 D3/8", "C3/8 G2/8", "G2/8 B2/8", "E2/8 B2/8",
			"A2/8 E3/8", "D3/8 A2/8", "D3/8 D2/8", "G2/12 r/4",
		],
		"drums": ["k/4 h/4 s/4 h/4"],
	},
}

static var _cache := {}
static var _drums := {}


## The track as a stream, computed on the first call and cached after it. Looping
## tracks loop over their whole length.
static func build(id: String) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	var track: Dictionary = TRACKS[id]
	var step_frames: float = 60.0 / float(track.bpm) / 4.0 * RATE
	var lead := _parse(track.lead)
	var total_steps := 0
	for note in lead:
		total_steps += note[1]
	var frames := int(total_steps * step_frames)
	if not track.loop:
		frames += int(TAIL * RATE)
	var mix := PackedFloat32Array()
	mix.resize(frames)
	mix.fill(0.0)
	_add_voice(mix, lead, total_steps, step_frames, track.duty, LEAD_VOLUME, LEAD_DECAY)
	_add_voice(mix, _parse(track.bass), total_steps, step_frames, -1.0, BASS_VOLUME, 0.0)
	_add_drums(mix, _parse(track.drums), total_steps, step_frames)
	var stream := to_stream(mix)
	if track.loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = frames
	_cache[id] = stream
	return stream


## Drops the cached streams (AudioDirector calls it when it leaves the tree, so no
## stream outlives the game at exit).
static func clear_cache() -> void:
	_cache.clear()
	_drums.clear()


## 16-bit mono stream at RATE from samples in -1..1 (clipped).
static func to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream


## Largest absolute sample of a 16-bit stream, 0..1 (1 means it clips).
static func peak(stream: AudioStreamWAV) -> float:
	var data := stream.data
	var top := 0
	for i in range(0, data.size(), 2):
		top = maxi(top, absi(data.decode_s16(i)))
	return top / 32767.0


## Bars of tokens -> [[pitch or drum, length in sixteenths], ...]. A pitch is a
## frequency in Hz; a rest is 0.0; a drum is its letter.
static func _parse(bars: Array) -> Array:
	var notes := []
	for bar: String in bars:
		for token in bar.split(" ", false):
			var parts := token.split("/")
			var length := int(parts[1]) if parts.size() > 1 else 2
			var name := parts[0]
			if name == "r":
				notes.append([0.0, length])
			elif name in ["k", "s", "h"]:
				notes.append([name, length])
			else:
				var octave := int(name.right(1))
				var midi := 12 * (octave + 1) + int(SEMITONES[name.left(-1)])
				notes.append([440.0 * pow(2.0, (midi - 69) / 12.0), length])
	return notes


## Plays notes from the start, repeating them until total_steps. duty < 0 is a
## triangle wave, otherwise a square wave with that duty cycle.
static func _add_voice(mix: PackedFloat32Array, notes: Array, total_steps: int, \
		step_frames: float, duty: float, volume: float, decay: float) -> void:
	if notes.is_empty():
		return
	var step := 0
	var index := 0
	while step < total_steps:
		var note: Array = notes[index % notes.size()]
		var length: int = mini(note[1], total_steps - step)
		var freq: float = note[0]
		if freq > 0.0:
			var start := int(step * step_frames)
			var count := int(length * step_frames)
			_add_tone(mix, start, count, freq, duty, volume, decay)
		step += length
		index += 1


static func _add_tone(mix: PackedFloat32Array, start: int, count: int, freq: float, \
		duty: float, volume: float, decay: float) -> void:
	var attack := int(ATTACK * RATE)
	var release := int(RELEASE * RATE)
	var inc := freq / RATE
	var phase := 0.0
	count = mini(count, mix.size() - start)
	for i in count:
		var env := 1.0 - decay * i / count
		if i < attack:
			env *= float(i) / attack
		elif i > count - release:
			env *= float(count - i) / release
		var wave: float
		if duty < 0.0:
			wave = 4.0 * absf(phase - 0.5) - 1.0
		else:
			wave = 1.0 if phase < duty else -1.0
		mix[start + i] += wave * volume * env
		phase += inc
		if phase >= 1.0:
			phase -= 1.0


static func _add_drums(mix: PackedFloat32Array, hits: Array, total_steps: int, \
		step_frames: float) -> void:
	if hits.is_empty():
		return
	var step := 0
	var index := 0
	while step < total_steps:
		var hit: Array = hits[index % hits.size()]
		if hit[0] is String:
			var sound := _drum(hit[0])
			var start := int(step * step_frames)
			for i in mini(sound.size(), mix.size() - start):
				mix[start + i] += sound[i]
		step += hit[1]
		index += 1


## One drum hit, computed once: the kick is a falling triangle, the snare and the
## hi-hat are noise held for a few samples (lower or higher pitched) that fades out.
static func _drum(kind: String) -> PackedFloat32Array:
	if _drums.has(kind):
		return _drums[kind]
	var rng := RandomNumberGenerator.new()
	rng.seed = NOISE_SEED
	var seconds: float = {"k": 0.12, "s": 0.14, "h": 0.04}[kind]
	var count := int(seconds * RATE)
	var sound := PackedFloat32Array()
	sound.resize(count)
	var phase := 0.0
	var held := 0.0
	var hold: int = {"k": 1, "s": 2, "h": 1}[kind]
	for i in count:
		var t := float(i) / count
		var env := (1.0 - t) * (1.0 - t)
		var value: float
		if kind == "k":
			phase = fmod(phase + lerpf(150.0, 40.0, t) / RATE, 1.0)
			value = 4.0 * absf(phase - 0.5) - 1.0
		else:
			if i % hold == 0:
				held = rng.randf_range(-1.0, 1.0)
			value = held * (0.6 if kind == "h" else 1.0)
		sound[i] = value * env * DRUM_VOLUME
	_drums[kind] = sound
	return sound
