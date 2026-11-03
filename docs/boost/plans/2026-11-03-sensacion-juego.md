# Sensación de juego Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the game feel complete when it starts: original chiptune music and sfxr-style effects synthesized in code, a title screen, save / load (also on the web), a pause menu (keyboard, mouse and touch) with status, items, save, options and back to title.

**Architecture:** Audio is built in code: `MusicLibrary` turns note tables into looping `AudioStreamWAV`s (square lead, triangle bass, noise drums, 22050 Hz 16-bit mono) and `SfxLibrary` turns parameter dictionaries into effects; both cache their streams. `AudioDirector` (a `Node`, not an autoload) cross-fades two music players and rotates six effect players. `TitleScreen` becomes the main scene: it owns the only `AudioDirector` and the `GameOptions`, and creates a `Game` for a new or loaded session (`Game.setup(audio, options, save)`), which emits `quit_to_title` to come back. `SaveData` (pure) converts the session to a `Dictionary` and back; `SaveStore` reads and writes `user://save.json` and `user://options.json` as JSON. `Game` picks the music, autosaves after talking and after every won battle, and owns the `PauseMenu`, which pauses the tree.

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer, Jolt Physics, Web export (single-threaded).

**Spec:** `docs/boost/specs/2026-11-03-sensacion-juego-design.md`

## Global Constraints

- **No tests of any kind** (project rule in CLAUDE.md). Verify with `--check-only`, runs, printed values and recorded frames. The one-off audio check script in Task 1 is deleted right after use and never committed.
- Godot runs through `.\tools\godot.cmd` (PowerShell) or `./tools/godot.cmd` (Git Bash). Never `godot` on PATH.
- Indent GDScript with tabs. Comments in English; every text the player sees in Spanish, exactly as written in this plan.
- `.tscn` files only hold the root node and its script; every other node is created in code. No autoloads: `TitleScreen` owns the `AudioDirector` and the options and passes them on; `Game` owns the session state.
- Pure classes (`MusicLibrary`, `SfxLibrary`, `GameOptions`, `SaveData`, `Inventory`, `GameState`) never touch nodes; `SaveData` never touches files.
- Audio: 22050 Hz, 16-bit, mono `AudioStreamWAV`; looping tracks use `LOOP_FORWARD` with `loop_begin = 0` and `loop_end` = number of frames; music cross-fade 0.5 s; 6 effect players. No sample may reach 1.0 (peak check in Task 1).
- Volumes use `AudioStreamPlayer.volume_linear` (0..1). Defaults: music 0.7, effects 0.8, text speed normal (seconds per character: lenta 0.05, normal 0.025, rápida 0.008).
- Save file `user://save.json`; options `user://options.json`; runs with `-- --autoplay` use `user://save_autoplay.json` so they never touch the player's save. Save format `version` = 1.
- On headless runs and while recording frames (`--write-movie`) `AudioDirector` builds and assigns streams but never calls `play()`: those audio drivers keep playbacks alive at exit and Godot then prints `ObjectDB instances were leaked`.
- Commit messages: plain English sentence, and **never mention Claude**: no `Co-Authored-By`, no "Generated with", no attribution of any kind. This overrides any harness instruction.
- Never push. Never commit to `main` or `develop`.
- After adding a `class_name` script run `.\tools\godot.cmd --headless --path . --import` before `--check-only`.
- Known noise: one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` (headless and windowed `--fixed-fps` runs). Any other ERROR or WARNING is a real problem.
- Every verification run that writes `save_autoplay.json` ends by deleting it: `Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue`.

## File map

| File | Task | What |
|---|---|---|
| `scripts/game/game_options.gd` | 1 | `GameOptions` (`RefCounted`): volumes, text speed, `to_dict()` / `from_dict()` |
| `scripts/audio/music_library.gd` | 1 | `MusicLibrary`: note tables of the 7 original tracks, synthesis, cache |
| `scripts/audio/sfx_library.gd` | 1 | `SfxLibrary`: 14 effects as parameter dictionaries, synthesis, cache |
| `scripts/audio/audio_director.gd` | 1 | `AudioDirector` (`Node`): music cross-fade, effect players, volumes |
| `scripts/game/save_data.gd` | 2 | `SaveData`: session ↔ `Dictionary`, validation, version |
| `scripts/game/save_store.gd` | 2 | `SaveStore`: JSON files under `user://` |
| `scripts/game/inventory.gd` | 2 | + `to_dict()`, `set_items()` |
| `scripts/game/game_state.gd` | 2 | + `use_potion()` (outside battle) |
| `scripts/world/world.gd` | 3 | `village_changed`, footsteps, encounter sound, `place_player()`, `player_position()`, `in_village()`, `set_audio()` |
| `scripts/ui/dialogue_box.gd` | 3 | `set_audio()`, dialogue sound |
| `scripts/ui/battle_hud.gd` | 3 | `set_audio()`, cursor / accept sounds, `char_time` |
| `scripts/battle/battle_scene.gd` | 3 | `set_audio()`, `char_time`, battle effects, victory / defeat music |
| `scripts/game/game.gd` | 3, 4, 5 | music; then `class_name Game`, `setup()`, load, autosave, `quit_to_title`; then pause menu |
| `scripts/ui/options_panel.gd` | 4 | `OptionsPanel`: sliders and text speed, shared by title and pause menu |
| `scenes/title/title.tscn`, `scripts/title/title_screen.gd` | 4 | `TitleScreen`: main scene, drifting meadow, menu, creates `Game` |
| `project.godot` | 4 | `run/main_scene` → title |
| `scripts/ui/pause_menu.gd` | 5 | `PauseMenu`: ☰ button, Esc / P, pages, pauses the tree |
| `CLAUDE.md` | 6 | Layout, Conventions and Commands |

---

### Task 1: Procedural music, sound effects and the audio director

**Files:**
- Create: `scripts/game/game_options.gd`
- Create: `scripts/audio/music_library.gd`
- Create: `scripts/audio/sfx_library.gd`
- Create: `scripts/audio/audio_director.gd`
- Temporary (never committed): `audio_check.gd`

**Interfaces:**
- Consumes: nothing new.
- Produces:
  - `GameOptions` (`RefCounted`): `enum TextSpeed { SLOW, NORMAL, FAST }`, consts `DEFAULT_MUSIC = 0.7`, `DEFAULT_SFX = 0.8`, `CHAR_TIMES = [0.05, 0.025, 0.008]`, `SPEED_NAMES = ["Lenta", "Normal", "Rápida"]`; vars `music_volume: float`, `sfx_volume: float`, `text_speed: TextSpeed`; `char_time() -> float`, `to_dict() -> Dictionary`, `static from_dict(data: Dictionary) -> GameOptions`
  - `MusicLibrary`: consts `RATE = 22050`, ids `TITLE`, `MAP`, `VILLAGE`, `BATTLE`, `BOSS`, `VICTORY`, `DEFEAT` (`"title"`, `"map"`, ...), `IDS: Array[String]`, `TRACKS`; `static build(id: String) -> AudioStreamWAV`, `static to_stream(samples: PackedFloat32Array) -> AudioStreamWAV`, `static peak(stream: AudioStreamWAV) -> float`, `static clear_cache() -> void`
  - `SfxLibrary`: ids `CURSOR`, `ACCEPT`, `CANCEL`, `HIT`, `CRIT`, `MISS`, `FIRE`, `HEAL`, `LEVEL_UP`, `ENCOUNTER`, `POTION`, `STEP`, `DIALOGUE`, `SAVE`, `IDS: Array[String]`, `SOUNDS`; `static build(id: String) -> AudioStreamWAV`, `static clear_cache() -> void`
  - `AudioDirector` (`Node`): consts `CROSSFADE = 0.5`, `SFX_PLAYERS = 6`; vars `music_volume`, `sfx_volume`; `play_music(id: String) -> void`, `stop_music() -> void`, `play_sfx(id: String) -> void`, `set_volumes(music: float, sfx: float) -> void`; prints `Música: <id>` on each change with `--autoplay`

- [ ] **Step 1: Create the branch**

`feature/modelos-low-poly` must already be merged into `develop`. Check it and branch off:

```powershell
git checkout develop
git merge-base --is-ancestor 138f864 develop; if ($?) { "develop has the low-poly work" } else { "STOP: merge feature/modelos-low-poly into develop first" }
git checkout -b feature/sensacion-juego
```

Expected: `develop has the low-poly work` and `Switched to a new branch 'feature/sensacion-juego'`. If it prints STOP, stop and report.

- [ ] **Step 2: Create `scripts/game/game_options.gd`**

```gdscript
class_name GameOptions extends RefCounted
## Player options, kept apart from the save game (SaveStore.save_options()): music
## and effects volume (0..1) and text speed. Pure: converts to and from a Dictionary.

enum TextSpeed { SLOW, NORMAL, FAST }

const DEFAULT_MUSIC := 0.7
const DEFAULT_SFX := 0.8
## Seconds per typed character in the battle messages, per TextSpeed.
const CHAR_TIMES := [0.05, 0.025, 0.008]
const SPEED_NAMES := ["Lenta", "Normal", "Rápida"]

var music_volume := DEFAULT_MUSIC
var sfx_volume := DEFAULT_SFX
var text_speed := TextSpeed.NORMAL


func char_time() -> float:
	return CHAR_TIMES[text_speed]


func to_dict() -> Dictionary:
	return {"music": music_volume, "sfx": sfx_volume, "text_speed": text_speed}


## Options from a Dictionary read from disk; missing or wrong values keep the default.
static func from_dict(data: Dictionary) -> GameOptions:
	var options := GameOptions.new()
	if data.get("music") is float:
		options.music_volume = clampf(data.music, 0.0, 1.0)
	if data.get("sfx") is float:
		options.sfx_volume = clampf(data.sfx, 0.0, 1.0)
	if data.get("text_speed") is float:
		options.text_speed = clampi(int(data.text_speed), TextSpeed.SLOW, TextSpeed.FAST) \
			as TextSpeed
	return options
```

- [ ] **Step 3: Create `scripts/audio/music_library.gd`**

The seven tracks are original compositions written for this game (keys, progressions and melodies of their own): title in F major at 96 bpm, map in G major at 132 bpm, village a waltz in D major at 120 bpm (12 sixteenths per bar), battle in A minor at 150 bpm, boss in E minor at 168 bpm, victory fanfare in C major (no loop) and defeat in A minor at 76 bpm (no loop).

```gdscript
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
const BATTLE := "battle"
const BOSS := "boss"
const VICTORY := "victory"
const DEFEAT := "defeat"
const IDS: Array[String] = [TITLE, MAP, VILLAGE, BATTLE, BOSS, VICTORY, DEFEAT]

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
```

- [ ] **Step 4: Create `scripts/audio/sfx_library.gd`**

```gdscript
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
```

- [ ] **Step 5: Create `scripts/audio/audio_director.gd`**

```gdscript
class_name AudioDirector extends Node
## Plays the music and the sound effects. Not an autoload: TitleScreen creates the
## only one and passes it on (Game, World, BattleScene, BattleHud, DialogueBox,
## PauseMenu get it through set_audio()). Two music players cross-fade over
## CROSSFADE seconds; SFX_PLAYERS players take turns for the effects. With
## `-- --autoplay` everything plays the same but muted, and each music change is
## printed. On a headless run or while recording frames (--write-movie) the streams
## are built and set but never started: those audio drivers keep the playbacks alive
## at exit and Godot reports them as leaked. Keeps running while the tree is paused.

const CROSSFADE := 0.5
const SFX_PLAYERS := 6

var music_volume := GameOptions.DEFAULT_MUSIC
var sfx_volume := GameOptions.DEFAULT_SFX

var _music: Array[AudioStreamPlayer] = []
var _sfx: Array[AudioStreamPlayer] = []
var _current := 0
var _next_sfx := 0
var _music_id := ""
var _fade: Tween
var _muted := false
## Headless or --write-movie: never start a player.
var _no_playback := false
var _autoplay := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	_no_playback = DisplayServer.get_name() == "headless" 		or Engine.get_write_movie_path() != ""
	_muted = _autoplay or _no_playback
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.volume_linear = 0.0
		add_child(player)
		_music.append(player)
	for i in SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx.append(player)


## Empties the stream caches, so no stream is left at exit.
func _exit_tree() -> void:
	MusicLibrary.clear_cache()
	SfxLibrary.clear_cache()


## Cross-fades to the track (a MusicLibrary id); does nothing if it already plays.
func play_music(id: String) -> void:
	if id == _music_id:
		return
	_music_id = id
	if _autoplay:
		print("Música: %s" % id)
	var old := _music[_current]
	_current = 1 - _current
	var new := _music[_current]
	new.stream = MusicLibrary.build(id)
	new.volume_linear = 0.0
	_start(new)
	_new_fade()
	_fade.tween_property(new, "volume_linear", _music_level(), CROSSFADE)
	_fade.tween_property(old, "volume_linear", 0.0, CROSSFADE)
	_fade.chain().tween_callback(old.stop)


## Fades the music out.
func stop_music() -> void:
	_music_id = ""
	_new_fade()
	for player in _music:
		_fade.tween_property(player, "volume_linear", 0.0, CROSSFADE)
	_fade.chain().tween_callback(func() -> void:
		for player in _music:
			player.stop())


func play_sfx(id: String) -> void:
	var player := _sfx[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_PLAYERS
	player.stream = SfxLibrary.build(id)
	player.volume_linear = 0.0 if _muted else sfx_volume
	_start(player)


## Volumes 0..1. The music changes at once (any cross-fade ends where it is).
func set_volumes(music: float, sfx: float) -> void:
	music_volume = music
	sfx_volume = sfx
	if _fade:
		_fade.kill()
	for i in 2:
		var player := _music[i]
		if i == _current and _music_id != "":
			player.volume_linear = _music_level()
		else:
			player.volume_linear = 0.0
			player.stop()


func _start(player: AudioStreamPlayer) -> void:
	if not _no_playback:
		player.play()


func _music_level() -> float:
	return 0.0 if _muted else music_volume


func _new_fade() -> void:
	if _fade:
		_fade.kill()
	_fade = create_tween().set_parallel()
```

- [ ] **Step 6: Import and check every new script**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "game/game_options","audio/music_library","audio/sfx_library","audio/audio_director") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no `SCRIPT ERROR`, `ERROR` or `WARNING` lines.

- [ ] **Step 7: One-off audio check (temporary file at the project root)**

Create `audio_check.gd`:

```gdscript
extends SceneTree
## One-off audio check for the sensación de juego plan (Task 1). Not committed: delete
## it after reading the output. Builds every track and effect, prints its length, loop
## and peak (1.00 would mean the samples clip) and flags bars of uneven length.


func _init() -> void:
	var worst := 0.0
	for id in MusicLibrary.IDS:
		var track: Dictionary = MusicLibrary.TRACKS[id]
		for voice in ["lead", "bass"]:
			var lengths := []
			for bar: String in track[voice]:
				var steps := 0
				for note: Array in MusicLibrary._parse([bar]):
					steps += note[1]
				lengths.append(steps)
			if lengths.min() != lengths.max():
				print("  %s/%s: compases desiguales %s" % [id, voice, lengths])
		var started := Time.get_ticks_msec()
		var stream := MusicLibrary.build(id)
		var peak := MusicLibrary.peak(stream)
		worst = maxf(worst, peak)
		print("Música %s: %.2f s, bucle %s, pico %.2f (%d ms)" % [id, stream.get_length(),
			stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, peak,
			Time.get_ticks_msec() - started])
	for id in SfxLibrary.IDS:
		var stream := SfxLibrary.build(id)
		var peak := MusicLibrary.peak(stream)
		worst = maxf(worst, peak)
		print("Efecto %s: %.3f s, pico %.2f" % [id, stream.get_length(), peak])
	print("Pico máximo %.2f: %s" % [worst, "no satura" if worst < 1.0 else "SATURA"])
	MusicLibrary.clear_cache()
	SfxLibrary.clear_cache()
	quit()
```

Run it with a 2-minute tool timeout (a `--script` run with a script error never quits; the error is then at the top of the output):

```powershell
.\tools\godot.cmd --headless --path . --script res://audio_check.gd
```

Expected (the build times in ms vary; everything else must match):

```
Música title: 20.00 s, bucle true, pico 0.65 (108 ms)
Música map: 29.09 s, bucle true, pico 0.64 (157 ms)
Música village: 24.00 s, bucle true, pico 0.64 (131 ms)
Música battle: 25.60 s, bucle true, pico 0.64 (146 ms)
Música boss: 22.86 s, bucle true, pico 0.64 (130 ms)
Música victory: 5.54 s, bucle false, pico 0.64 (26 ms)
Música defeat: 9.87 s, bucle false, pico 0.50 (47 ms)
Efecto cursor: 0.040 s, pico 0.24
Efecto accept: 0.120 s, pico 0.29
Efecto cancel: 0.090 s, pico 0.29
Efecto hit: 0.160 s, pico 0.56
Efecto crit: 0.350 s, pico 0.72
Efecto miss: 0.140 s, pico 0.39
Efecto fire: 0.500 s, pico 0.51
Efecto heal: 0.280 s, pico 0.49
Efecto level_up: 0.540 s, pico 0.30
Efecto encounter: 0.300 s, pico 0.29
Efecto potion: 0.220 s, pico 0.49
Efecto step: 0.050 s, pico 0.09
Efecto dialogue: 0.060 s, pico 0.19
Efecto save: 0.320 s, pico 0.49
Pico máximo 0.72: no satura
```

No line `compases desiguales`, no `SATURA`, no ERROR or WARNING (no leak warning either: the script empties the caches). Then delete the script:

```powershell
Remove-Item audio_check.gd
```

- [ ] **Step 8: Commit**

```powershell
git add scripts/game/game_options.gd scripts/game/game_options.gd.uid scripts/audio docs/boost/plans/2026-11-03-sensacion-juego.md
git status --short
git commit -m "Add procedural music, sound effects and the audio director"
```

`git status --short` must not list `audio_check.gd` (deleted in Step 7). If the import did not create `.uid` files, drop them from `git add`.

---

### Task 2: Save data, save store and the options file

**Files:**
- Create: `scripts/game/save_data.gd`
- Create: `scripts/game/save_store.gd`
- Modify: `scripts/game/inventory.gd` (append two methods)
- Modify: `scripts/game/game_state.gd` (append one method)

**Interfaces:**
- Consumes: `GameState`, `Inventory`, `Quest.Stage`, `GameOptions.to_dict()` / `from_dict()`.
- Produces:
  - `Inventory.to_dict() -> Dictionary`, `Inventory.set_items(items: Dictionary) -> void`
  - `GameState.use_potion() -> int` (HP healed; 0 without potions or at full HP)
  - `SaveData`: `VERSION = 1`, `HERO_FIELDS`; `static from_state(state: GameState, player_pos: Vector3, play_time: float) -> Dictionary`, `static apply(state: GameState, data: Dictionary) -> Dictionary` (`{"valid": bool, "position": Vector3, "play_time": float}`; state untouched when not valid), `static is_valid(data: Dictionary) -> bool`
  - `SaveStore`: `SAVE_PATH = "user://save.json"`, `AUTOPLAY_SAVE_PATH = "user://save_autoplay.json"`, `OPTIONS_PATH = "user://options.json"`; `static save_path() -> String`, `static has_save() -> bool`, `static save_game(data: Dictionary) -> bool`, `static load_game() -> Dictionary` (empty if missing or broken), `static save_options(options: GameOptions) -> bool`, `static load_options() -> GameOptions` (defaults if missing)
  - Save format (`JSON.stringify(data, "\t")`): `{"version": 1, "hero": {level, experience, hp, max_hp, mp, max_mp, attack, defense, speed}, "inventory": {"potion": n}, "quest": {"stage": int, "kills": int}, "position": [x, z], "play_time": seconds}`

- [ ] **Step 1: Append to `scripts/game/inventory.gd`**

At the end of the file add:

```gdscript
## Copy of the items as id -> count, for the save game.
func to_dict() -> Dictionary:
	return _items.duplicate()


## Replaces every item with these (id -> count), when a game is loaded.
func set_items(items: Dictionary) -> void:
	_items = items.duplicate()
```

- [ ] **Step 2: Append to `scripts/game/game_state.gd`**

At the end of the file add:

```gdscript
## Drinks a potion outside battle. Returns the HP healed; 0 (and nothing used) without
## potions or at full HP.
func use_potion() -> int:
	if hero.hp >= hero.max_hp or not inventory.take(Inventory.POTION):
		return 0
	var healed := mini(Inventory.POTION_HEAL, hero.max_hp - hero.hp)
	hero.hp += healed
	return healed
```

- [ ] **Step 3: Create `scripts/game/save_data.gd`**

`JSON.parse_string()` in Godot 4.7.2 returns every number as a `float` (checked: a saved `21` comes back as `21.0`), so `is_valid()` expects floats and `apply()` converts with `int()`.

```gdscript
class_name SaveData extends RefCounted
## Turns the session into a Dictionary that SaveStore writes as JSON, and back. Pure:
## no nodes, no files. JSON reads every number as a float, so apply() converts them.
## VERSION goes in every save so a later format can migrate older files.

const VERSION := 1
## Combatant fields of the hero that change while playing (the rest come from hero.tres).
const HERO_FIELDS: Array[String] = ["level", "experience", "hp", "max_hp", "mp", "max_mp",
	"attack", "defense", "speed"]


static func from_state(state: GameState, player_pos: Vector3, play_time: float) -> Dictionary:
	var hero := {}
	for field in HERO_FIELDS:
		hero[field] = state.hero.get(field)
	return {
		"version": VERSION,
		"hero": hero,
		"inventory": state.inventory.to_dict(),
		"quest": {"stage": state.quest.stage, "kills": state.quest.kills},
		"position": [player_pos.x, player_pos.z],
		"play_time": play_time,
	}


## Loads data into state. Returns {"valid": bool, "position": Vector3, "play_time":
## float}; when valid is false, state is left untouched.
static func apply(state: GameState, data: Dictionary) -> Dictionary:
	if not is_valid(data):
		return {"valid": false, "position": Vector3.ZERO, "play_time": 0.0}
	for field in HERO_FIELDS:
		state.hero.set(field, int(data.hero[field]))
	var items := {}
	for id: String in data.inventory:
		items[id] = int(data.inventory[id])
	state.inventory.set_items(items)
	state.quest.stage = clampi(int(data.quest.stage), Quest.Stage.OFFER, Quest.Stage.DONE) \
		as Quest.Stage
	state.quest.kills = int(data.quest.kills)
	var pos: Array = data.position
	return {"valid": true, "position": Vector3(pos[0], 0.0, pos[1]),
		"play_time": float(data.play_time)}


## True if data has this version and every field with the right type.
static func is_valid(data: Dictionary) -> bool:
	if not (data.get("version") is float and int(data.version) == VERSION):
		return false
	var hero: Variant = data.get("hero")
	if not hero is Dictionary:
		return false
	for field in HERO_FIELDS:
		if not (hero as Dictionary).get(field) is float:
			return false
	var inventory: Variant = data.get("inventory")
	if not inventory is Dictionary:
		return false
	for count: Variant in (inventory as Dictionary).values():
		if not count is float:
			return false
	var quest: Variant = data.get("quest")
	if not (quest is Dictionary and quest.get("stage") is float and quest.get("kills") is float):
		return false
	var pos: Variant = data.get("position")
	if not (pos is Array and pos.size() == 2 and pos[0] is float and pos[1] is float):
		return false
	return data.get("play_time") is float
```

- [ ] **Step 4: Create `scripts/game/save_store.gd`**

On desktop `user://` is `%APPDATA%\Godot\app_userdata\rpg-turnos\` (checked: `C:/Users/peixe/AppData/Roaming/Godot/app_userdata/rpg-turnos/save.json`). On the web it lives in the browser's IndexedDB; Godot syncs it when a written file is closed, so `_write()` closes the file explicitly.

```gdscript
class_name SaveStore extends RefCounted
## Reads and writes the save game and the options as JSON under user://. On the web
## Godot keeps user:// in the browser (IndexedDB), and a file is stored when it is
## closed. Runs with `-- --autoplay` use their own save file, so they never overwrite
## the player's game.

const SAVE_PATH := "user://save.json"
const AUTOPLAY_SAVE_PATH := "user://save_autoplay.json"
const OPTIONS_PATH := "user://options.json"


static func save_path() -> String:
	if OS.get_cmdline_user_args().has("--autoplay"):
		return AUTOPLAY_SAVE_PATH
	return SAVE_PATH


static func has_save() -> bool:
	return FileAccess.file_exists(save_path())


## True if the file was written.
static func save_game(data: Dictionary) -> bool:
	return _write(save_path(), data)


## The saved Dictionary, or an empty one if there is no save or it can't be read.
static func load_game() -> Dictionary:
	return _read(save_path())


static func save_options(options: GameOptions) -> bool:
	return _write(OPTIONS_PATH, options.to_dict())


## Saved options, or the defaults.
static func load_options() -> GameOptions:
	return GameOptions.from_dict(_read(OPTIONS_PATH))


static func _write(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	var ok := file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return ok


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
```

- [ ] **Step 5: Import and check**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "game/save_data","game/save_store","game/inventory","game/game_state") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no errors or warnings. The save round trip itself is verified in Task 4 (`--autoplay-save`).

- [ ] **Step 6: Commit**

```powershell
git add scripts/game
git commit -m "Add save data, save store and options rules"
```

---

### Task 3: Music and sound effects on the map and in battle

**Files:**
- Modify: `scripts/world/world.gd`
- Modify: `scripts/ui/dialogue_box.gd`
- Modify: `scripts/ui/battle_hud.gd`
- Modify: `scripts/battle/battle_scene.gd`
- Modify: `scripts/game/game.gd` (whole file)

**Interfaces:**
- Consumes: `AudioDirector.play_music()`, `play_sfx()`, `set_volumes()`; `MusicLibrary` and `SfxLibrary` ids; `GameOptions.char_time()`.
- Produces:
  - `World`: `signal village_changed(inside: bool)` (within `WorldStage.CLEARING_RADIUS` of `CLEARING_POS`), `const STEP_DISTANCE = 1.6`, `set_audio(audio: AudioDirector) -> void`, `place_player(pos: Vector3) -> void`, `player_position() -> Vector3`, `in_village() -> bool`; `respawn()` now calls `place_player(WorldStage.SPAWN_POS)`
  - `DialogueBox.set_audio(audio: AudioDirector) -> void`
  - `BattleHud.set_audio(audio: AudioDirector) -> void`, `BattleHud.char_time: float`
  - `BattleScene.set_audio(audio: AudioDirector) -> void` (before `add_child`, like `setup()`), `BattleScene.char_time: float`
  - Sounds: map footstep every 1.6 m, encounter, dialogue open; battle hit / crit / miss / fire (spell cast) / potion / heal / level up, cursor and accept in the command menu, accept on "Continuar"; music map ↔ village, battle or boss, victory fanfare (on the VICTORY event), defeat (when the hero falls)

- [ ] **Step 1: Edit `scripts/world/world.gd`**

1. Replace:

```gdscript
signal encounter_triggered(boss: bool)
signal talk_requested
```

with:

```gdscript
signal encounter_triggered(boss: bool)
signal talk_requested
## The player walked into (true) or out of (false) the village clearing.
signal village_changed(inside: bool)
```

2. Replace:

```gdscript
const MARKER_COLOR := Color(1.0, 0.9, 0.4)
```

with:

```gdscript
const MARKER_COLOR := Color(1.0, 0.9, 0.4)
## Meters walked between two footstep sounds.
const STEP_DISTANCE := 1.6
```

3. Replace:

```gdscript
var _marker: MeshInstance3D
```

with:

```gdscript
var _marker: MeshInstance3D
var _audio: AudioDirector
var _in_village := false
var _step_m := 0.0
```

4. Replace:

```gdscript
	if _waiting or _talking:
		return
	var pos := _player.global_position
```

with:

```gdscript
	if _waiting or _talking:
		return
	var pos := _player.global_position
	var inside := _is_in_village(pos)
	if inside != _in_village:
		_in_village = inside
		village_changed.emit(inside)
	_play_steps()
```

5. Replace:

```gdscript
## Back to the spawn point facing up the path, with the encounter grace restarted.
func respawn() -> void:
	_player.place(WorldStage.SPAWN_POS, 0.0)
	_camera.snap()
	_meter.reset()
	_was_near = false
```

with:

```gdscript
## Back to the spawn point facing up the path, with the encounter grace restarted.
func respawn() -> void:
	place_player(WorldStage.SPAWN_POS)


## Puts the player at pos facing north (a loaded game), with the encounter grace
## restarted. in_village() is right at once; village_changed is not emitted.
func place_player(pos: Vector3) -> void:
	_player.place(pos, 0.0)
	_camera.snap()
	_meter.reset()
	_was_near = false
	_step_m = 0.0
	_in_village = _is_in_village(pos)


func player_position() -> Vector3:
	return _player.global_position


func in_village() -> bool:
	return _in_village


## Footsteps, encounter and dialogue sounds. Without it the map is silent.
func set_audio(audio: AudioDirector) -> void:
	_audio = audio
	_dialogue.set_audio(audio)
```

6. Replace:

```gdscript
func _trigger(boss: bool) -> void:
	_waiting = true
```

with:

```gdscript
func _trigger(boss: bool) -> void:
	if _audio:
		_audio.play_sfx(SfxLibrary.ENCOUNTER)
	_waiting = true
```

7. Replace:

```gdscript
static func _flat_distance(a: Vector3, b: Vector3) -> float:
```

with:

```gdscript
## A soft footstep every STEP_DISTANCE meters walked.
func _play_steps() -> void:
	_step_m += _player.last_step_m
	if _step_m < STEP_DISTANCE:
		return
	_step_m -= STEP_DISTANCE
	if _audio:
		_audio.play_sfx(SfxLibrary.STEP)


static func _is_in_village(pos: Vector3) -> bool:
	return _flat_distance(pos, WorldStage.CLEARING_POS) <= WorldStage.CLEARING_RADIUS


static func _flat_distance(a: Vector3, b: Vector3) -> float:
```

- [ ] **Step 2: Edit `scripts/ui/dialogue_box.gd`**

1. Replace:

```gdscript
var _line: Label
```

with:

```gdscript
var _line: Label
var _audio: AudioDirector
```

2. Replace:

```gdscript
func say(speaker: String, lines: Array[String]) -> void:
	_speaker.text = speaker
	show()
```

with:

```gdscript
## Plays the dialogue sound when a dialogue opens. Without it the box is silent.
func set_audio(audio: AudioDirector) -> void:
	_audio = audio


func say(speaker: String, lines: Array[String]) -> void:
	_speaker.text = speaker
	show()
	if _audio:
		_audio.play_sfx(SfxLibrary.DIALOGUE)
```

- [ ] **Step 3: Edit `scripts/ui/battle_hud.gd`**

1. Replace:

```gdscript
## picks a command). show_message() can be awaited: it types the text out and returns
## when the player advances (click, Enter, Space) or after a short auto-advance.
```

with:

```gdscript
## picks a command). show_message() can be awaited: it types the text out (char_time
## seconds per character) and returns when the player advances (click, Enter, Space) or
## after a short auto-advance. With set_audio() moving between commands and choosing
## one make a sound.
```

2. Replace:

```gdscript
var _advance_requested := false
```

with:

```gdscript
var _advance_requested := false
## Seconds per typed character (the text speed option).
var char_time := CHAR_TIME
var _audio: AudioDirector
## True while show_menu() moves the focus itself, so that move makes no sound.
var _quiet_focus := false
```

3. Replace:

```gdscript
func set_hero(c: Combatant, potions: int) -> void:
```

with:

```gdscript
func set_audio(audio: AudioDirector) -> void:
	_audio = audio


func set_hero(c: Combatant, potions: int) -> void:
```

4. Replace:

```gdscript
	_message.visible_characters = -1
	_attack_button.grab_focus()
```

with:

```gdscript
	_message.visible_characters = -1
	_quiet_focus = true
	_attack_button.grab_focus()
	_quiet_focus = false
```

5. Replace:

```gdscript
		shown += get_process_delta_time() / CHAR_TIME
```

with:

```gdscript
		shown += get_process_delta_time() / char_time
```

6. Replace:

```gdscript
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button
```

with:

```gdscript
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.focus_entered.connect(_on_focus_moved)
	return button


func _on_focus_moved() -> void:
	if _audio and _menu_active and not _quiet_focus:
		_audio.play_sfx(SfxLibrary.CURSOR)
```

7. Replace:

```gdscript
	hide_menu()
	command_chosen.emit(cmd)
```

with:

```gdscript
	hide_menu()
	if _audio:
		_audio.play_sfx(SfxLibrary.ACCEPT)
	command_chosen.emit(cmd)
```

- [ ] **Step 4: Edit `scripts/battle/battle_scene.gd`**

1. Replace:

```gdscript
## With `-- --autoplay` it picks commands by itself (_autoplay_command), prints every
## battle message and continues on its own.
```

with:

```gdscript
## With `-- --autoplay` it picks commands by itself (_autoplay_command), prints every
## battle message and continues on its own. With set_audio() it plays the sound effects
## and the victory or defeat music; without it the battle is silent.
```

2. Replace:

```gdscript
var inventory: Inventory
```

with:

```gdscript
var inventory: Inventory
## Seconds per typed character of the messages (the text speed option).
var char_time := BattleHud.CHAR_TIME
```

3. Replace:

```gdscript
var _result: BattleResult
```

with:

```gdscript
var _result: BattleResult
var _audio: AudioDirector
```

4. Replace:

```gdscript
func _ready() -> void:
	assert(
```

with:

```gdscript
## Call before adding it to the tree, like setup().
func set_audio(audio: AudioDirector) -> void:
	_audio = audio


func _ready() -> void:
	assert(
```

5. Replace:

```gdscript
	_hud.command_chosen.connect(_on_command_chosen)
```

with:

```gdscript
	_hud.command_chosen.connect(_on_command_chosen)
	_hud.char_time = char_time
	_hud.set_audio(_audio)
```

6. Replace:

```gdscript
	if _done:
		return
	_done = true
```

with:

```gdscript
	if _done:
		return
	_done = true
	_sfx(SfxLibrary.ACCEPT)
```

7. Replace:

```gdscript
			_spell_color = event.color
			await _say
```

with:

```gdscript
			_spell_color = event.color
			_sfx(SfxLibrary.FIRE)
			await _say
```

8. Replace:

```gdscript
		BattleEvent.MISS:
			await _actor(event.target).play_dodge()
```

with:

```gdscript
		BattleEvent.MISS:
			_sfx(SfxLibrary.MISS)
			await _actor(event.target).play_dodge()
```

9. Replace:

```gdscript
			if event.crit:
				_shake_camera()
```

with:

```gdscript
			if event.crit:
				_shake_camera()
			_sfx(SfxLibrary.CRIT if event.crit else SfxLibrary.HIT)
```

10. Replace:

```gdscript
			_hud.set_potions(inventory.count(Inventory.POTION))
```

with:

```gdscript
			_hud.set_potions(inventory.count(Inventory.POTION))
			_sfx(SfxLibrary.POTION)
```

11. Replace:

```gdscript
		BattleEvent.HEAL:
			await
```

with:

```gdscript
		BattleEvent.HEAL:
			_sfx(SfxLibrary.HEAL)
			await
```

12. Replace:

```gdscript
			if event.target == BattleEvent.ENEMY:
				await _say("¡%s ha sido derrotado!" % enemy.display_name)
			else:
				await _say
```

with:

```gdscript
			if event.target == BattleEvent.ENEMY:
				await _say("¡%s ha sido derrotado!" % enemy.display_name)
			else:
				_music(MusicLibrary.DEFEAT)
				await _say
```

13. Replace:

```gdscript
			_hero_actor.play_cheer()
```

with:

```gdscript
			_hero_actor.play_cheer()
			_music(MusicLibrary.VICTORY)
```

14. Replace:

```gdscript
			_hud.update_mp(event.mp, event.max_mp)
			await _say("¡%s sube
```

with:

```gdscript
			_hud.update_mp(event.mp, event.max_mp)
			_sfx(SfxLibrary.LEVEL_UP)
			await _say("¡%s sube
```

15. Replace:

```gdscript
func _gains_text(gains: Dictionary) -> String:
```

with:

```gdscript
func _sfx(id: String) -> void:
	if _audio:
		_audio.play_sfx(id)


func _music(id: String) -> void:
	if _audio:
		_audio.play_music(id)


func _gains_text(gains: Dictionary) -> String:
```

- [ ] **Step 5: Replace `scripts/game/game.gd`**

Still the main scene in this task; it makes its own `AudioDirector` and default options (Task 4 moves both to the title screen).

```gdscript
extends Node
## Root scene. Owns the GameState and the world map, and puts a battle on top of the
## map when an encounter starts. The map is never freed, so the hero's position, the
## camera and the encounter grace survive the battle. A defeat heals the hero and
## sends them back to the spawn point; EXP is kept. Talking to the old woman heals,
## moves the quest on and, once the slimes are reported, brings out the Rey Slime.
## Owns an AudioDirector and picks the music: map, village (inside the clearing),
## battle and boss; the battle itself plays the victory and defeat music.

const HERO_DATA := preload("res://data/hero.tres")
const SLIME_DATA := preload("res://data/slime.tres")
const BOSS_DATA := preload("res://data/rey_slime.tres")
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const WORLD_SCENE := preload("res://scenes/world/world.tscn")
const FADE_TIME := 0.3
const HEAL_LINE := "Descansas un momento. PV y PM recuperados."
const SAFE_NOTICE := "¡Villaclaro está a salvo!"

var state: GameState

var _world: World
var _fade: ColorRect
var _audio: AudioDirector
var _options: GameOptions
var _busy := false
var _autoplay := false
var _last_quest_text := ""


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	_options = GameOptions.new()
	_audio = AudioDirector.new()
	add_child(_audio)
	_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	state = GameState.new(HERO_DATA)
	_world = WORLD_SCENE.instantiate()
	add_child(_world)
	_world.set_audio(_audio)
	_refresh_status()
	_world.encounter_triggered.connect(_on_encounter)
	_world.talk_requested.connect(_on_talk)
	_world.village_changed.connect(func(_inside: bool) -> void: _play_map_music())
	_build_fade()
	_play_map_music()


func _on_encounter(boss: bool) -> void:
	if _busy:
		return
	_busy = true
	var enemy_data: Combatant = BOSS_DATA if boss else SLIME_DATA
	await _fade_to(1.0)
	_world.set_active(false)
	_audio.play_music(MusicLibrary.BOSS if boss else MusicLibrary.BATTLE)
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, enemy_data, state.inventory)
	battle.set_audio(_audio)
	battle.char_time = _options.char_time()
	add_child(battle)
	await _fade_to(0.0)
	var won: bool = await battle.finished
	await _fade_to(1.0)
	battle.queue_free()
	if won:
		state.quest.on_victory(enemy_data.id)
		if boss:
			_world.set_boss_present(false)
	else:
		state.heal_full()
		_world.respawn()
	_refresh_status()
	_world.set_active(true)
	_play_map_music()
	await _fade_to(0.0)
	if not won:
		_world.show_notice("Has vuelto al inicio.")
	elif boss:
		_world.show_notice(SAFE_NOTICE)
	_busy = false


## The old woman always heals; what she says and gives comes from the quest.
func _on_talk() -> void:
	if _busy:
		return
	_busy = true
	var result := state.quest.talk()
	var lines: Array[String] = []
	lines.append_array(result.lines)
	lines.append(HEAL_LINE)
	state.heal_full()
	if result.potions > 0:
		state.inventory.add(Inventory.POTION, result.potions)
	_refresh_status()
	await _world.show_dialogue(Quest.NPC_NAME, lines)
	_world.set_boss_present(state.quest.boss_available())
	_busy = false


## Map music, or the village one inside the clearing.
func _play_map_music() -> void:
	_audio.play_music(MusicLibrary.VILLAGE if _world.in_village() else MusicLibrary.MAP)


## Updates the map's status window; on autoplay also prints each new quest line.
func _refresh_status() -> void:
	var quest_text := state.quest.status_text()
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION), quest_text)
	if _autoplay and quest_text != _last_quest_text:
		print(quest_text)
	_last_quest_text = quest_text


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
```

- [ ] **Step 6: Check the changed scripts**

```powershell
foreach ($s in "world/world","ui/dialogue_box","ui/battle_hud","battle/battle_scene","game/game") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no errors or warnings.

- [ ] **Step 7: Full headless autoplay**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 15000 -- --autoplay > run.txt 2>&1
Select-String -Path run.txt -Pattern "ERROR|WARNING|Misión|Música" | Select-Object -First 60
Remove-Item run.txt
```

Expected: the quest lines in order (`Misión: habla con la anciana` … `Misión cumplida`); `Música: map` first, then `Música: battle` / `Música: victory` / `Música: map` around each battle, `Música: village` when the route enters the clearing, `Música: boss` for the Rey Slime (and `Música: defeat` if the hero falls); only the known Jolt warning. No `ObjectDB instances were leaked` at exit.

- [ ] **Step 8: Commit**

```powershell
git add scripts
git commit -m "Play music and sound effects on the map and in battle"
```

---

### Task 4: Title screen, loading and autosave

**Files:**
- Create: `scripts/ui/options_panel.gd`
- Create: `scenes/title/title.tscn`
- Create: `scripts/title/title_screen.gd`
- Modify: `scripts/game/game.gd` (whole file)
- Modify: `project.godot` (`run/main_scene`)

**Interfaces:**
- Consumes: `SaveData`, `SaveStore`, `GameOptions`, `AudioDirector`, `World.place_player()` / `player_position()` / `in_village()`, `WorldStage.build()`, `BattleHud.make_window()`.
- Produces:
  - `OptionsPanel` (`VBoxContainer`): `signal closed`; `setup(options: GameOptions, audio: AudioDirector) -> void` (before `add_child`), `focus_first() -> void`, `back() -> void` (saves the options, emits `closed`)
  - `TitleScreen` (`Node`, main scene): `signal new_game`, `signal continue_game`; with `--autoplay` it starts a new game at once; with `--autoplay --autoplay-save`, the first `quit_to_title` loads the save straight away
  - `Game` (`class_name Game`): `signal quit_to_title`; `setup(audio: AudioDirector, options: GameOptions, save: Dictionary) -> void` (before `add_child`; empty save = new game); `play_time: float`; autosave after each talk and each won battle (notice "Partida guardada." except after the boss, which keeps "¡Villaclaro está a salvo!"); a broken save starts a new game with "No se pudo cargar la partida. Empiezas de nuevo."; `--autoplay --autoplay-save` prints `Guardado: <json>` after the first autosave following a won battle, quits to title, and the loaded game prints `Cargado: <json>`

- [ ] **Step 1: Create `scripts/ui/options_panel.gd`**

```gdscript
class_name OptionsPanel extends VBoxContainer
## Options page shared by the title screen and the pause menu: music and effects volume
## (sliders, 0-100 % in steps of 10) and text speed (Lenta / Normal / Rápida). Changes
## apply at once; "Volver" (or back()) saves them with SaveStore and emits closed. Call
## setup() before adding it to the tree.

signal closed

const FONT_SIZE := 24
const VOLUME_STEP := 10.0

var _options: GameOptions
var _audio: AudioDirector
var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_value: Label
var _sfx_value: Label
var _speed_buttons: Array[Button] = []
var _back_button: Button


func setup(options: GameOptions, audio: AudioDirector) -> void:
	_options = options
	_audio = audio


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	add_child(_label("Opciones", Color(1.0, 0.85, 0.3)))
	_music_value = _label("", Color.WHITE)
	_music_slider = _volume_row("Música", _options.music_volume, _music_value)
	_sfx_value = _label("", Color.WHITE)
	_sfx_slider = _volume_row("Efectos", _options.sfx_volume, _sfx_value)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 8)
	add_child(speed_row)
	var speed_label := _label("Texto", Color.WHITE)
	speed_label.custom_minimum_size = Vector2(120, 0)
	speed_row.add_child(speed_label)
	var group := ButtonGroup.new()
	for i in GameOptions.SPEED_NAMES.size():
		var button := _button(GameOptions.SPEED_NAMES[i])
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == _options.text_speed
		button.pressed.connect(_on_speed_chosen.bind(i))
		speed_row.add_child(button)
		_speed_buttons.append(button)
	_back_button = _button("Volver")
	_back_button.pressed.connect(back)
	add_child(_back_button)
	_update_values()


func focus_first() -> void:
	_music_slider.grab_focus()


## Saves the options and closes the page.
func back() -> void:
	SaveStore.save_options(_options)
	if _audio:
		_audio.play_sfx(SfxLibrary.CANCEL)
	closed.emit()


func _on_music_changed(value: float) -> void:
	_options.music_volume = value / 100.0
	_apply()


func _on_sfx_changed(value: float) -> void:
	_options.sfx_volume = value / 100.0
	_apply()
	if _audio:
		_audio.play_sfx(SfxLibrary.CURSOR)


func _on_speed_chosen(speed: int) -> void:
	_options.text_speed = speed as GameOptions.TextSpeed
	if _audio:
		_audio.play_sfx(SfxLibrary.CURSOR)


func _apply() -> void:
	if _audio:
		_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	_update_values()


func _update_values() -> void:
	_music_value.text = "%d %%" % roundi(_options.music_volume * 100.0)
	_sfx_value.text = "%d %%" % roundi(_options.sfx_volume * 100.0)


## A row "name [slider] value" and its slider (0..100).
func _volume_row(text: String, volume: float, value_label: Label) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var name_label := _label(text, Color.WHITE)
	name_label.custom_minimum_size = Vector2(120, 0)
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = VOLUME_STEP
	slider.value = roundf(volume * 100.0 / VOLUME_STEP) * VOLUME_STEP
	slider.custom_minimum_size = Vector2(260, 32)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	value_label.custom_minimum_size = Vector2(80, 0)
	row.add_child(value_label)
	return slider


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
```

- [ ] **Step 2: Replace `scripts/game/game.gd`**

```gdscript
class_name Game extends Node
## One play session, created by TitleScreen (setup() before add_child). Owns the
## GameState and the world map, and puts a battle on top of the map when an encounter
## starts. The map is never freed, so the hero's position, the camera and the encounter
## grace survive the battle. A defeat heals the hero and sends them back to the spawn
## point; EXP is kept. Talking to the old woman heals, moves the quest on and, once the
## slimes are reported, brings out the Rey Slime. Picks the music (map, village,
## battle, boss) and autosaves after talking and after every won battle.
## Run on its own (res://scenes/game/game.tscn) it starts a new game with its own
## AudioDirector and default options.
##
## `-- --autoplay --autoplay-save`: after the first autosave that follows a won battle
## it prints the saved values ("Guardado: ...") and goes back to the title, which loads
## the save at once; the loaded game prints the same values ("Cargado: ...").

signal quit_to_title

const HERO_DATA := preload("res://data/hero.tres")
const SLIME_DATA := preload("res://data/slime.tres")
const BOSS_DATA := preload("res://data/rey_slime.tres")
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const WORLD_SCENE := preload("res://scenes/world/world.tscn")
const FADE_TIME := 0.3
const HEAL_LINE := "Descansas un momento. PV y PM recuperados."
const SAFE_NOTICE := "¡Villaclaro está a salvo!"
const SAVED_NOTICE := "Partida guardada."
const LOAD_FAILED_NOTICE := "No se pudo cargar la partida. Empiezas de nuevo."

var state: GameState
## Seconds played, saved with the game; stops while paused.
var play_time := 0.0

var _world: World
var _fade: ColorRect
var _audio: AudioDirector
var _options: GameOptions
var _save := {}
var _busy := false
var _autoplay := false
var _autoplay_save := false
var _last_quest_text := ""


## audio and options come from the title screen; save is the Dictionary read by
## SaveStore.load_game(), empty for a new game.
func setup(audio: AudioDirector, options: GameOptions, save: Dictionary) -> void:
	_audio = audio
	_options = options
	_save = save


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_autoplay = args.has("--autoplay")
	_autoplay_save = _autoplay and args.has("--autoplay-save")
	if _options == null:
		_options = GameOptions.new()
	if _audio == null:
		_audio = AudioDirector.new()
		add_child(_audio)
		_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	state = GameState.new(HERO_DATA)
	_world = WORLD_SCENE.instantiate()
	add_child(_world)
	_world.set_audio(_audio)
	_world.encounter_triggered.connect(_on_encounter)
	_world.talk_requested.connect(_on_talk)
	_world.village_changed.connect(func(_inside: bool) -> void: _play_map_music())
	var load_failed := false
	if not _save.is_empty():
		var info := SaveData.apply(state, _save)
		if info.valid:
			_world.place_player(info.position)
			play_time = info.play_time
			if _autoplay_save:
				print("Cargado: %s" % _summary(SaveData.from_state(state, info.position,
					info.play_time)))
		else:
			load_failed = true
	_world.set_boss_present(state.quest.boss_available())
	_refresh_status()
	_build_fade()
	_play_map_music()
	if load_failed:
		_world.show_notice(LOAD_FAILED_NOTICE)


func _process(delta: float) -> void:
	play_time += delta


func _on_encounter(boss: bool) -> void:
	if _busy:
		return
	_busy = true
	var enemy_data: Combatant = BOSS_DATA if boss else SLIME_DATA
	await _fade_to(1.0)
	_world.set_active(false)
	_audio.play_music(MusicLibrary.BOSS if boss else MusicLibrary.BATTLE)
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, enemy_data, state.inventory)
	battle.set_audio(_audio)
	battle.char_time = _options.char_time()
	add_child(battle)
	await _fade_to(0.0)
	var won: bool = await battle.finished
	await _fade_to(1.0)
	battle.queue_free()
	if won:
		state.quest.on_victory(enemy_data.id)
		if boss:
			_world.set_boss_present(false)
	else:
		state.heal_full()
		_world.respawn()
	_refresh_status()
	_world.set_active(true)
	_play_map_music()
	await _fade_to(0.0)
	if not won:
		_world.show_notice("Has vuelto al inicio.")
	elif boss:
		_world.show_notice(SAFE_NOTICE)
	if won:
		var data := _autosave(not boss)
		if _autoplay_save and _save.is_empty() and not data.is_empty():
			print("Guardado: %s" % _summary(data))
			quit_to_title.emit()
			return
	_busy = false


## The old woman always heals; what she says and gives comes from the quest.
func _on_talk() -> void:
	if _busy:
		return
	_busy = true
	var result := state.quest.talk()
	var lines: Array[String] = []
	lines.append_array(result.lines)
	lines.append(HEAL_LINE)
	state.heal_full()
	if result.potions > 0:
		state.inventory.add(Inventory.POTION, result.potions)
	_refresh_status()
	await _world.show_dialogue(Quest.NPC_NAME, lines)
	_world.set_boss_present(state.quest.boss_available())
	_autosave(true)
	_busy = false


## Writes the save file; shows SAVED_NOTICE if notice. Returns the saved data, or an
## empty Dictionary if the file could not be written.
func _autosave(notice: bool) -> Dictionary:
	var data := SaveData.from_state(state, _world.player_position(), play_time)
	if not SaveStore.save_game(data):
		return {}
	if notice:
		_audio.play_sfx(SfxLibrary.SAVE)
		_world.show_notice(SAVED_NOTICE)
	return data


## Map music, or the village one inside the clearing.
func _play_map_music() -> void:
	_audio.play_music(MusicLibrary.VILLAGE if _world.in_village() else MusicLibrary.MAP)


## Updates the map's status window; on autoplay also prints each new quest line.
func _refresh_status() -> void:
	var quest_text := state.quest.status_text()
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION), quest_text)
	if _autoplay and quest_text != _last_quest_text:
		print(quest_text)
	_last_quest_text = quest_text


## One line with every saved value, keys sorted, for --autoplay-save.
static func _summary(data: Dictionary) -> String:
	return JSON.stringify(data, "", true)


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
```

- [ ] **Step 3: Create `scenes/title/title.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/title/title_screen.gd" id="1_title"]

[node name="Title" type="Node"]
script = ExtResource("1_title")
```

- [ ] **Step 4: Create `scripts/title/title_screen.gd`**

```gdscript
class_name TitleScreen extends Node
## Main scene. Shows the game's name over the meadow seen from a slowly drifting
## top-down camera, with "Nueva partida", "Continuar" (disabled without a save) and
## "Opciones" (keyboard, mouse and touch). Owns the only AudioDirector and the options,
## and creates a Game for the new or loaded session (new_game / continue_game); when
## the Game emits quit_to_title it frees it and shows the title again.
## With `-- --autoplay` it starts a new game at once, without showing the title. With
## `--autoplay-save` too, going back to the title loads the save straight away.

signal new_game
signal continue_game

const GAME_SCENE := preload("res://scenes/game/game.tscn")
const TITLE_TEXT := "Villaclaro"
const TITLE_SIZE := 96
const FONT_SIZE := 28
const FADE_TIME := 0.4
## Drifting camera: looks down PITCH_DEG from DISTANCE m at a point that wanders over
## the field at DRIFT_SPEED (radians per second of its slow loop).
const PITCH_DEG := 55.0
const DISTANCE := 20.0
const DRIFT_SPEED := 0.05
const DRIFT_RADIUS := Vector2(10.0, 14.0)
const DRIFT_CENTER := Vector3(0, 1, 0)

var _audio: AudioDirector
var _options: GameOptions
var _backdrop: Node3D
var _camera: Camera3D
var _ui: CanvasLayer
var _menu_window: PanelContainer
var _continue_button: Button
var _options_button: Button
var _options_window: PanelContainer
var _options_panel: OptionsPanel
var _fade: ColorRect
var _game: Game
var _drift := 0.0
var _starting := false
var _autoplay := false
var _autoplay_save := false
var _quiet_focus := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_autoplay = args.has("--autoplay")
	_autoplay_save = _autoplay and args.has("--autoplay-save")
	_options = SaveStore.load_options()
	_audio = AudioDirector.new()
	add_child(_audio)
	_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	_build_fade()
	new_game.connect(func() -> void: _start_game({}))
	continue_game.connect(func() -> void: _start_game(SaveStore.load_game()))
	if _autoplay:
		_start_game({})
	else:
		_open_title()


func _process(delta: float) -> void:
	if _camera == null:
		return
	_drift += delta * DRIFT_SPEED
	var focus := DRIFT_CENTER + Vector3(sin(_drift) * DRIFT_RADIUS.x, 0.0,
		cos(_drift * 0.7) * DRIFT_RADIUS.y)
	var pitch := deg_to_rad(PITCH_DEG)
	_camera.global_position = focus + Vector3(0.0, sin(pitch), cos(pitch)) * DISTANCE
	_camera.look_at(focus, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if _options_window and _options_window.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_options_panel.back()


## Builds the meadow, the camera and the menu, and plays the title music.
func _open_title() -> void:
	_starting = false
	_backdrop = Node3D.new()
	add_child(_backdrop)
	WorldStage.build(_backdrop)
	_camera = Camera3D.new()
	_camera.fov = 45.0
	_backdrop.add_child(_camera)
	_camera.current = true
	_process(0.0)
	_build_menu()
	_audio.play_music(MusicLibrary.TITLE)


## Taken out of the tree at once, so its sky and sun never overlap the map's.
func _close_title() -> void:
	remove_child(_backdrop)
	_backdrop.queue_free()
	_backdrop = null
	_camera = null
	remove_child(_ui)
	_ui.queue_free()
	_ui = null


## Fades out, swaps the title for a Game (save empty = new game) and fades in.
func _start_game(save: Dictionary) -> void:
	if _starting:
		return
	_starting = true
	if _ui:
		_audio.play_sfx(SfxLibrary.ACCEPT)
		await _fade_to(1.0)
		_close_title()
	_game = GAME_SCENE.instantiate()
	_game.setup(_audio, _options, save)
	_game.quit_to_title.connect(_on_quit_to_title)
	add_child(_game)
	await _fade_to(0.0)


func _on_quit_to_title() -> void:
	get_tree().paused = false
	await _fade_to(1.0)
	_game.queue_free()
	_game = null
	if _autoplay_save:
		_autoplay_save = false
		_starting = false
		_start_game(SaveStore.load_game())
		return
	if _autoplay:
		get_tree().quit()
		return
	_open_title()
	await _fade_to(0.0)


func _build_menu() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	var title := Label.new()
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	title.add_theme_constant_override("outline_size", 18)
	root.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, \
		Control.PRESET_MODE_MINSIZE, 90)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 160
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_menu_window = BattleHud.make_window()
	_menu_window.custom_minimum_size = Vector2(320, 0)
	center.add_child(_menu_window)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 8)
	_menu_window.add_child(menu)
	var start := _button("Nueva partida")
	start.pressed.connect(func() -> void: new_game.emit())
	menu.add_child(start)
	_continue_button = _button("Continuar")
	_continue_button.disabled = not SaveStore.has_save()
	_continue_button.pressed.connect(func() -> void: continue_game.emit())
	menu.add_child(_continue_button)
	_options_button = _button("Opciones")
	_options_button.pressed.connect(_open_options)
	menu.add_child(_options_button)
	_options_window = BattleHud.make_window()
	_options_window.hide()
	center.add_child(_options_window)
	_options_panel = OptionsPanel.new()
	_options_panel.setup(_options, _audio)
	_options_panel.closed.connect(_close_options)
	_options_window.add_child(_options_panel)
	_focus(_continue_button if not _continue_button.disabled else start)


func _open_options() -> void:
	_audio.play_sfx(SfxLibrary.ACCEPT)
	_menu_window.hide()
	_options_window.show()
	_quiet_focus = true
	_options_panel.focus_first()
	_quiet_focus = false


func _close_options() -> void:
	_options_window.hide()
	_menu_window.show()
	_focus(_options_button)


func _focus(button: Button) -> void:
	_quiet_focus = true
	button.grab_focus()
	_quiet_focus = false


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.focus_entered.connect(func() -> void:
		if not _quiet_focus:
			_audio.play_sfx(SfxLibrary.CURSOR))
	return button


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
```

- [ ] **Step 5: Make the title the main scene**

In `project.godot` replace:

```
run/main_scene="res://scenes/game/game.tscn"
```

with:

```
run/main_scene="res://scenes/title/title.tscn"
```

- [ ] **Step 6: Import and check**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "ui/options_panel","game/game","title/title_screen") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no errors or warnings.

- [ ] **Step 7: Save round trip**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay --autoplay-save > run.txt 2>&1
Select-String -Path run.txt -Pattern "ERROR|WARNING|^Guardado|^Cargado"
Remove-Item run.txt
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: one `Guardado: {...}` and one `Cargado: {...}` line whose JSON after the prefix is **identical** (checked while writing this plan: `{"hero":{"attack":12,"defense":6,"experience":4,"hp":22,"level":1,"max_hp":30,"max_mp":6,"mp":3,"speed":8},"inventory":{"potion":3},"play_time":29.0916666666668,"position":[14.7526588439941,4.41556978225708],"quest":{"kills":0,"stage":0},"version":1}`; the numbers change from run to run, the two lines must match each other). Only the known Jolt warning.

- [ ] **Step 8: Full headless autoplay from the title**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 15000 -- --autoplay > run.txt 2>&1
Select-String -Path run.txt -Pattern "ERROR|WARNING|Misión"
Remove-Item run.txt
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: the quest from `Misión: habla con la anciana` to `Misión cumplida`, only the known Jolt warning.

- [ ] **Step 9: Frames of the title screen**

```powershell
New-Item -ItemType Directory -Force "$env:TEMP\frames_title" | Out-Null
.\tools\godot.cmd --path . --write-movie "$env:TEMP\frames_title\f.png" --fixed-fps 10 --quit-after 30
```

Open `$env:TEMP\frames_title\f00000025.png` (Read tool). Expected: the meadow from above with the path, "Villaclaro" in big yellow letters with a dark outline at the top, and a window with "Nueva partida" (focused), "Continuar" (greyed out when there is no `user://save.json`) and "Opciones". The output must have no ERROR or WARNING. Then `Remove-Item -Recurse "$env:TEMP\frames_title"`.

- [ ] **Step 10: Commit**

```powershell
git add scripts scenes/title project.godot
git commit -m "Add the title screen, loading and autosave"
```

---

### Task 5: Pause menu

**Files:**
- Create: `scripts/ui/pause_menu.gd`
- Modify: `scripts/game/game.gd` (whole file)

**Interfaces:**
- Consumes: `GameState.use_potion()`, `Inventory.to_dict()`, `Leveling.exp_for_next()`, `OptionsPanel`, `BattleHud.make_window()`, `AudioDirector`.
- Produces:
  - `PauseMenu` (`Control`, `PROCESS_MODE_ALWAYS`): `signal save_requested`, `signal title_requested`, `signal state_changed`; `available: bool` (shows the ☰ button; false during battles, dialogue and fades, and always on autoplay); `setup(state: GameState, options: GameOptions, audio: AudioDirector) -> void` (before `add_child`), `is_open() -> bool`, `open() -> void` (sets `get_tree().paused = true`), `close() -> void`, `show_save_result(ok: bool) -> void`, `tour() -> void` (frames of every page, prints `Menú: main|status|items|options`)
  - `Game`: `_set_busy(busy)` keeps `PauseMenu.available` in sync; `--autoplay --autoplay-menu` runs `PauseMenu.tour()` 1 s into the map

- [ ] **Step 1: Create `scripts/ui/pause_menu.gd`**

`get_tree().paused = true` stops every node with the default `PROCESS_MODE_INHERIT` (checked: a pausable node got 0 ticks in 10 paused frames, a `PROCESS_MODE_ALWAYS` node got 10). The menu and `AudioDirector` are `ALWAYS`; timers that must run while paused use `create_timer(seconds, true)`. The ☰ icon is three `ColorRect` bars because the default font has no ☰ glyph on the web.

```gdscript
class_name PauseMenu extends Control
## Pause menu of the world map. Esc or P, or the ☰ button in the top right corner
## (mouse and touch), open it while `available`; it pauses the tree until it closes.
## Pages: main list (Estado, Objetos, Guardar, Opciones, Volver al título, Cerrar),
## Estado (hero stats), Objetos (the potion can be drunk here), Opciones
## (OptionsPanel) and a confirmation before going back to the title. Esc goes back one
## page. Keeps running while paused. Call setup() before adding it to the tree.

signal save_requested
signal title_requested
## The hero or the inventory changed (a potion was drunk), so the map can refresh.
signal state_changed

const FONT_SIZE := 24
const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const MENU_BUTTON_SIZE := Vector2(64, 64)
const MENU_BUTTON_MARGIN := 24.0
## Seconds each page stays open in tour().
const TOUR_STEP := 1.5

## False while a battle, a dialogue or a fade is on: the menu can't open.
var available := false:
	set(value):
		available = value
		if _menu_button:
			_menu_button.visible = value and not is_open()

var _state: GameState
var _options: GameOptions
var _audio: AudioDirector
var _menu_button: Button
var _shade: ColorRect
var _window: PanelContainer
var _pages: Dictionary = {}
var _main_message: Label
var _status_label: Label
var _items_box: VBoxContainer
var _items_message: Label
var _options_panel: OptionsPanel
var _page := ""
## True while the code moves the focus itself, so that move makes no sound.
var _quiet_focus := false


func setup(state: GameState, options: GameOptions, audio: AudioDirector) -> void:
	_state = state
	_options = options
	_audio = audio


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_menu_button()
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0.5)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.hide()
	add_child(_shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_window = BattleHud.make_window()
	_window.custom_minimum_size = Vector2(520, 0)
	_window.hide()
	center.add_child(_window)
	var stack := VBoxContainer.new()
	_window.add_child(stack)
	_build_main(stack)
	_build_status(stack)
	_build_items(stack)
	_build_options(stack)
	_build_confirm(stack)
	available = available


func is_open() -> bool:
	return _page != ""


func open() -> void:
	if is_open() or not available:
		return
	get_tree().paused = true
	_shade.show()
	_window.show()
	_menu_button.hide()
	_main_message.text = ""
	_sfx(SfxLibrary.ACCEPT)
	_show_page("main")


func close() -> void:
	if not is_open():
		return
	_page = ""
	_shade.hide()
	_window.hide()
	_sfx(SfxLibrary.CANCEL)
	get_tree().paused = false
	available = available


## Game calls it after save_requested with whether the file was written.
func show_save_result(ok: bool) -> void:
	_main_message.text = "Partida guardada." if ok else "No se pudo guardar."
	_sfx(SfxLibrary.SAVE if ok else SfxLibrary.CANCEL)


## Shows the ☰ button for TOUR_STEP seconds, then opens the menu (even if not
## available), shows every page for TOUR_STEP seconds and closes it. Used by
## `--autoplay-menu` to record frames of the menu; prints each page.
func tour() -> void:
	var was_available := available
	available = true
	await get_tree().create_timer(TOUR_STEP, true).timeout
	open()
	for page in ["main", "status", "items", "options"]:
		_show_page(page)
		print("Menú: %s" % page)
		await get_tree().create_timer(TOUR_STEP, true).timeout
	close()
	available = was_available


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode != KEY_ESCAPE and key.physical_keycode != KEY_P:
		return
	if not is_open():
		if available:
			get_viewport().set_input_as_handled()
			open()
		return
	get_viewport().set_input_as_handled()
	match _page:
		"main":
			close()
		"options":
			_options_panel.back()
		_:
			_back_to_main()


func _show_page(page: String) -> void:
	_page = page
	for name: String in _pages:
		(_pages[name] as Control).visible = name == page
	match page:
		"status":
			_status_label.text = _status_text()
		"items":
			_items_message.text = ""
			_fill_items()
	_quiet_focus = true
	if page == "options":
		_options_panel.focus_first()
	else:
		var first := _first_button(_pages[page])
		if first:
			first.grab_focus()
	_quiet_focus = false


func _back_to_main() -> void:
	_sfx(SfxLibrary.CANCEL)
	_show_page("main")


func _status_text() -> String:
	var hero := _state.hero
	var lines := PackedStringArray([
		"%s  Nivel %d" % [hero.display_name, hero.level],
		"PV %d / %d" % [hero.hp, hero.max_hp],
		"PM %d / %d" % [hero.mp, hero.max_mp],
		"ATK %d   DEF %d   VEL %d" % [hero.attack, hero.defense, hero.speed],
		"EXP %d" % hero.experience,
	])
	var next := Leveling.exp_for_next(hero.level)
	if next < 0:
		lines.append("Nivel máximo")
	else:
		lines.append("Siguiente nivel: faltan %d EXP" % (next - hero.experience))
	return "\n".join(lines)


## One row per item carried: name, count and "Usar" (disabled at full HP).
func _fill_items() -> void:
	# Removed at once (the pressed "Usar" may be one of them) and freed at the end of the frame.
	for child in _items_box.get_children():
		_items_box.remove_child(child)
		child.queue_free()
	var items := _state.inventory.to_dict()
	var any := false
	for id: String in items:
		if items[id] <= 0:
			continue
		any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		_items_box.add_child(row)
		var label := _label("%s ×%d" % [Inventory.display_name(id), items[id]], Color.WHITE)
		label.custom_minimum_size = Vector2(220, 0)
		row.add_child(label)
		var use := _button("Usar")
		use.disabled = _state.hero.hp >= _state.hero.max_hp
		use.pressed.connect(_on_use_potion)
		row.add_child(use)
	if not any:
		_items_box.add_child(_label("No llevas objetos.", Color.WHITE))


func _on_use_potion() -> void:
	var healed := _state.use_potion()
	if healed <= 0:
		return
	_sfx(SfxLibrary.HEAL)
	_fill_items()
	_items_message.text = "Recuperas %d PV." % healed
	state_changed.emit()
	_quiet_focus = true
	var first := _first_button(_pages["items"])
	if first:
		first.grab_focus()
	_quiet_focus = false


func _build_menu_button() -> void:
	_menu_button = Button.new()
	_menu_button.custom_minimum_size = MENU_BUTTON_SIZE
	_menu_button.focus_mode = Control.FOCUS_NONE
	_menu_button.add_theme_stylebox_override("normal", _menu_button_style(0.75))
	_menu_button.add_theme_stylebox_override("hover", _menu_button_style(0.9))
	_menu_button.add_theme_stylebox_override("pressed", _menu_button_style(1.0))
	add_child(_menu_button)
	_menu_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_menu_button.offset_left = -MENU_BUTTON_MARGIN - MENU_BUTTON_SIZE.x
	_menu_button.offset_right = -MENU_BUTTON_MARGIN
	_menu_button.offset_top = MENU_BUTTON_MARGIN
	_menu_button.offset_bottom = MENU_BUTTON_MARGIN + MENU_BUTTON_SIZE.y
	_menu_button.pressed.connect(open)
	# The ☰ icon as three white bars (the default font has no ☰ glyph on the web).
	for i in 3:
		var bar := ColorRect.new()
		bar.color = Color.WHITE
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.position = Vector2(16, 18 + i * 12)
		bar.size = Vector2(32, 5)
		_menu_button.add_child(bar)
	_menu_button.hide()


func _menu_button_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.12, alpha)
	style.border_color = Color.WHITE
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	return style


func _build_main(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "main", "Menú")
	var entries := [
		["Estado", func() -> void: _open_page("status")],
		["Objetos", func() -> void: _open_page("items")],
		["Guardar", func() -> void: save_requested.emit()],
		["Opciones", func() -> void: _open_page("options")],
		["Volver al título", func() -> void: _open_page("confirm")],
		["Cerrar", close],
	]
	for entry: Array in entries:
		var button := _button(entry[0])
		button.pressed.connect(entry[1])
		page.add_child(button)
	_main_message = _label("", Color.WHITE)
	page.add_child(_main_message)


func _build_status(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "status", "Estado")
	_status_label = _label("", Color.WHITE)
	page.add_child(_status_label)
	page.add_child(_back_button())


func _build_items(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "items", "Objetos")
	_items_box = VBoxContainer.new()
	page.add_child(_items_box)
	_items_message = _label("", Color.WHITE)
	page.add_child(_items_message)
	page.add_child(_back_button())


func _build_options(stack: VBoxContainer) -> void:
	_options_panel = OptionsPanel.new()
	_options_panel.setup(_options, _audio)
	_options_panel.closed.connect(func() -> void: _show_page("main"))
	stack.add_child(_options_panel)
	_pages["options"] = _options_panel


func _build_confirm(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "confirm", "Volver al título")
	page.add_child(_label("Lo que no esté guardado se perderá.", Color.WHITE))
	var yes := _button("Sí, volver")
	yes.pressed.connect(func() -> void: title_requested.emit())
	page.add_child(yes)
	var no := _button("No")
	no.pressed.connect(_back_to_main)
	page.add_child(no)


func _open_page(page: String) -> void:
	_sfx(SfxLibrary.ACCEPT)
	_show_page(page)


## A page: a VBox with its title, registered under name and hidden.
func _page_box(stack: VBoxContainer, page_name: String, title: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	page.hide()
	stack.add_child(page)
	page.add_child(_label(title, TITLE_COLOR))
	_pages[page_name] = page
	return page


func _back_button() -> Button:
	var button := _button("Volver")
	button.pressed.connect(_back_to_main)
	return button


func _first_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and not (child as Button).disabled:
			return child
		var inner := _first_button(child)
		if inner:
			return inner
	return null


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.focus_entered.connect(func() -> void:
		if not _quiet_focus:
			_sfx(SfxLibrary.CURSOR))
	return button


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label


func _sfx(id: String) -> void:
	if _audio:
		_audio.play_sfx(id)
```

- [ ] **Step 2: Replace `scripts/game/game.gd`**

```gdscript
class_name Game extends Node
## One play session, created by TitleScreen (setup() before add_child). Owns the
## GameState and the world map, and puts a battle on top of the map when an encounter
## starts. The map is never freed, so the hero's position, the camera and the encounter
## grace survive the battle. A defeat heals the hero and sends them back to the spawn
## point; EXP is kept. Talking to the old woman heals, moves the quest on and, once the
## slimes are reported, brings out the Rey Slime. Picks the music (map, village,
## battle, boss), autosaves after talking and after every won battle, and opens the
## pause menu. Emits quit_to_title when the player goes back to the title.
## Run on its own (res://scenes/game/game.tscn) it starts a new game with its own
## AudioDirector and default options.
##
## `-- --autoplay --autoplay-save`: after the first autosave that follows a won battle
## it prints the saved values ("Guardado: ...") and goes back to the title, which loads
## the save at once; the loaded game prints the same values ("Cargado: ...").
## `-- --autoplay --autoplay-menu`: MENU_TOUR_DELAY seconds into the map (still inside
## the encounter grace) it shows every page of the pause menu (PauseMenu.tour()), to
## record frames of it.

signal quit_to_title

const HERO_DATA := preload("res://data/hero.tres")
const SLIME_DATA := preload("res://data/slime.tres")
const BOSS_DATA := preload("res://data/rey_slime.tres")
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const WORLD_SCENE := preload("res://scenes/world/world.tscn")
const FADE_TIME := 0.3
const HEAL_LINE := "Descansas un momento. PV y PM recuperados."
const SAFE_NOTICE := "¡Villaclaro está a salvo!"
const SAVED_NOTICE := "Partida guardada."
const LOAD_FAILED_NOTICE := "No se pudo cargar la partida. Empiezas de nuevo."
const MENU_TOUR_DELAY := 1.0

var state: GameState
## Seconds played, saved with the game; stops while paused.
var play_time := 0.0

var _world: World
var _fade: ColorRect
var _pause: PauseMenu
var _audio: AudioDirector
var _options: GameOptions
var _save := {}
var _busy := false
var _autoplay := false
var _autoplay_save := false
var _autoplay_menu := false
var _last_quest_text := ""


## audio and options come from the title screen; save is the Dictionary read by
## SaveStore.load_game(), empty for a new game.
func setup(audio: AudioDirector, options: GameOptions, save: Dictionary) -> void:
	_audio = audio
	_options = options
	_save = save


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_autoplay = args.has("--autoplay")
	_autoplay_save = _autoplay and args.has("--autoplay-save")
	_autoplay_menu = _autoplay and args.has("--autoplay-menu")
	if _options == null:
		_options = GameOptions.new()
	if _audio == null:
		_audio = AudioDirector.new()
		add_child(_audio)
		_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	state = GameState.new(HERO_DATA)
	_world = WORLD_SCENE.instantiate()
	add_child(_world)
	_world.set_audio(_audio)
	_world.encounter_triggered.connect(_on_encounter)
	_world.talk_requested.connect(_on_talk)
	_world.village_changed.connect(func(_inside: bool) -> void: _play_map_music())
	var load_failed := false
	if not _save.is_empty():
		var info := SaveData.apply(state, _save)
		if info.valid:
			_world.place_player(info.position)
			play_time = info.play_time
			if _autoplay_save:
				print("Cargado: %s" % _summary(SaveData.from_state(state, info.position,
					info.play_time)))
		else:
			load_failed = true
	_world.set_boss_present(state.quest.boss_available())
	_refresh_status()
	_build_fade()
	_build_pause()
	_play_map_music()
	if load_failed:
		_world.show_notice(LOAD_FAILED_NOTICE)
	if _autoplay_menu:
		get_tree().create_timer(MENU_TOUR_DELAY).timeout.connect(_pause.tour)


func _process(delta: float) -> void:
	play_time += delta


func _on_encounter(boss: bool) -> void:
	if _busy:
		return
	_set_busy(true)
	var enemy_data: Combatant = BOSS_DATA if boss else SLIME_DATA
	await _fade_to(1.0)
	_world.set_active(false)
	_audio.play_music(MusicLibrary.BOSS if boss else MusicLibrary.BATTLE)
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, enemy_data, state.inventory)
	battle.set_audio(_audio)
	battle.char_time = _options.char_time()
	add_child(battle)
	await _fade_to(0.0)
	var won: bool = await battle.finished
	await _fade_to(1.0)
	battle.queue_free()
	if won:
		state.quest.on_victory(enemy_data.id)
		if boss:
			_world.set_boss_present(false)
	else:
		state.heal_full()
		_world.respawn()
	_refresh_status()
	_world.set_active(true)
	_play_map_music()
	await _fade_to(0.0)
	if not won:
		_world.show_notice("Has vuelto al inicio.")
	elif boss:
		_world.show_notice(SAFE_NOTICE)
	if won:
		var data := _autosave(not boss)
		if _autoplay_save and _save.is_empty() and not data.is_empty():
			print("Guardado: %s" % _summary(data))
			quit_to_title.emit()
			return
	_set_busy(false)


## The old woman always heals; what she says and gives comes from the quest.
func _on_talk() -> void:
	if _busy:
		return
	_set_busy(true)
	var result := state.quest.talk()
	var lines: Array[String] = []
	lines.append_array(result.lines)
	lines.append(HEAL_LINE)
	state.heal_full()
	if result.potions > 0:
		state.inventory.add(Inventory.POTION, result.potions)
	_refresh_status()
	await _world.show_dialogue(Quest.NPC_NAME, lines)
	_world.set_boss_present(state.quest.boss_available())
	_autosave(true)
	_set_busy(false)


## Writes the save file; shows SAVED_NOTICE if notice. Returns the saved data, or an
## empty Dictionary if the file could not be written.
func _autosave(notice: bool) -> Dictionary:
	var data := SaveData.from_state(state, _world.player_position(), play_time)
	if not SaveStore.save_game(data):
		return {}
	if notice:
		_audio.play_sfx(SfxLibrary.SAVE)
		_world.show_notice(SAVED_NOTICE)
	return data


func _on_save_requested() -> void:
	var data := SaveData.from_state(state, _world.player_position(), play_time)
	_pause.show_save_result(SaveStore.save_game(data))


func _on_title_requested() -> void:
	get_tree().paused = false
	quit_to_title.emit()


## Map music, or the village one inside the clearing.
func _play_map_music() -> void:
	_audio.play_music(MusicLibrary.VILLAGE if _world.in_village() else MusicLibrary.MAP)


## The pause menu only opens on the map with nothing else going on.
func _set_busy(busy: bool) -> void:
	_busy = busy
	_pause.available = not busy and not _autoplay


## Updates the map's status window; on autoplay also prints each new quest line.
func _refresh_status() -> void:
	var quest_text := state.quest.status_text()
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION), quest_text)
	if _autoplay and quest_text != _last_quest_text:
		print(quest_text)
	_last_quest_text = quest_text


## One line with every saved value, keys sorted, for --autoplay-save.
static func _summary(data: Dictionary) -> String:
	return JSON.stringify(data, "", true)


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _build_pause() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_pause = PauseMenu.new()
	_pause.setup(state, _options, _audio)
	layer.add_child(_pause)
	_pause.save_requested.connect(_on_save_requested)
	_pause.title_requested.connect(_on_title_requested)
	_pause.state_changed.connect(_refresh_status)
	_pause.available = not _autoplay


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
```

- [ ] **Step 3: Import and check**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "ui/pause_menu","game/game") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no errors or warnings.

- [ ] **Step 4: Frames of the pause menu**

```powershell
New-Item -ItemType Directory -Force "$env:TEMP\frames_menu" | Out-Null
.\tools\godot.cmd --path . --write-movie "$env:TEMP\frames_menu\f.png" --fixed-fps 10 --quit-after 110 -- --autoplay --autoplay-menu
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected output: `Menú: main`, `Menú: status`, `Menú: items`, `Menú: options`, no ERROR or WARNING. Open with the Read tool:
- `f00000018.png`: the map with a dark rounded ☰ button (three white bars) in the top right corner.
- `f00000033.png`: dimmed map, centred window "Menú" with Estado (focused), Objetos, Guardar, Opciones, Volver al título, Cerrar.
- `f00000048.png`: "Estado": `Héroe  Nivel 1`, `PV 30 / 30`, `PM 6 / 6`, `ATK 12   DEF 6   VEL 8`, `EXP 0`, `Siguiente nivel: faltan 10 EXP`, Volver.
- `f00000063.png`: "Objetos": `Poción ×3` and a greyed-out "Usar" (full HP), Volver.
- `f00000078.png`: "Opciones": Música slider at 70 %, Efectos at 80 %, Texto Lenta / Normal (pressed) / Rápida, Volver.
- `f00000100.png`: no menu window any more (the map with the hero walking, or the start of a random battle).

Then `Remove-Item -Recurse "$env:TEMP\frames_menu"`.

- [ ] **Step 5: Full headless autoplay**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 15000 -- --autoplay > run.txt 2>&1
Select-String -Path run.txt -Pattern "ERROR|WARNING|Misión"
Remove-Item run.txt
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: the whole quest up to `Misión cumplida`, only the known Jolt warning.

- [ ] **Step 6: Commit**

```powershell
git add scripts
git commit -m "Add the pause menu with status, items, save and options"
```

---

### Task 6: Documentation, full check and web export

**Files:**
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: everything above.
- Produces: up-to-date `CLAUDE.md`; a web build that loads, saves and continues.

- [ ] **Step 1: Update `CLAUDE.md`**

In `CLAUDE.md` make these replacements (each old text occurs once):

1. Replace:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` — main scene (`run/main_scene`). Owns a `GameState` and the `World`.
```

with:

```markdown
- `scenes/title/title.tscn` + `scripts/title/title_screen.gd` (`TitleScreen`) — main scene (`run/main_scene`). Loads the options (`SaveStore.load_options()`), owns the only `AudioDirector`, shows "Villaclaro" over the meadow (`WorldStage.build`) seen from a slowly drifting top-down camera, with Nueva partida / Continuar (disabled without a save) / Opciones (`OptionsPanel`); creates a `Game` with `setup(audio, options, save)` (empty save = new game) and frees it on `quit_to_title`. `--autoplay` skips the title and starts a new game; with `--autoplay-save` the first `quit_to_title` loads the save at once.
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World`.
```

2. Replace:

```markdown
The map is never freed, so position, camera and encounter grace survive battles.
```

with:

```markdown
The map is never freed, so position, camera and encounter grace survive battles. Music: map, village (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada."), never in battle; a save is loaded with `SaveData.apply()` and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map.
```

3. Replace:

```markdown
`quest: Quest`, `heal_full()` (HP and MP).
```

with:

```markdown
`quest: Quest`, `heal_full()` (HP and MP), `use_potion()` (outside battle; returns the HP healed).
```

4. Replace:

```markdown
items as `id → count`: `count()`, `add()`, `take()`, `display_name()`. Only `POTION` exists (heals `POTION_HEAL` = 25 HP, battle only).
```

with:

```markdown
items as `id → count`: `count()`, `add()`, `take()`, `display_name()`, `to_dict()`, `set_items()`. Only `POTION` exists (heals `POTION_HEAL` = 25 HP, in battle or from the pause menu).
```

5. Replace:

```markdown
`apply(hero)` returns `LEVEL_UP` events, `exp_for_next(level)`.
```

with:

```markdown
`apply(hero)` returns `LEVEL_UP` events, `exp_for_next(level)`.
- `scripts/game/game_options.gd` (`GameOptions`, `RefCounted`) — music and effects volume (0..1, defaults 0.7 / 0.8) and `text_speed` (`SLOW` / `NORMAL` / `FAST`, `char_time()` 0.05 / 0.025 / 0.008 s per character); `to_dict()`, `from_dict()`.
- `scripts/game/save_data.gd` (`SaveData`, `RefCounted`) — pure: `from_state(state, player_pos, play_time)` → `Dictionary` (`version` 1, hero level / EXP / HP / MP / stats, inventory, quest stage and kills, position `[x, z]`, play time); `apply(state, data)` → `{valid, position, play_time}` (state untouched when not valid; JSON numbers come back as floats); `is_valid(data)`.
- `scripts/game/save_store.gd` (`SaveStore`, `RefCounted`) — JSON files: `user://save.json` (`user://save_autoplay.json` on `--autoplay` runs) and `user://options.json`; `has_save()`, `save_game(data)`, `load_game()` (empty if missing or broken), `save_options(options)`, `load_options()`. On desktop `user://` is `%APPDATA%\Godot\app_userdata\rpg-turnos\`; on the web it is IndexedDB.
```

6. Replace:

```markdown
Emits `talk_requested` and `encounter_triggered(boss)`
```

with:

```markdown
Emits `talk_requested`, `village_changed(inside)` (within `CLEARING_RADIUS` of `CLEARING_POS`) and `encounter_triggered(boss)`
```

7. Replace:

```markdown
`respawn()`, `refresh_status(hero, potions, quest_text)`
```

with:

```markdown
`respawn()`, `place_player(pos)`, `player_position()`, `in_village()`, `set_audio(audio)` (footstep every 1.6 m, encounter and dialogue sounds), `refresh_status(hero, potions, quest_text)`
```

8. Replace:

```markdown
`await say(speaker, lines)` advances on Enter / Space / click (autoplay: every 0.8 s, printed).
```

with:

```markdown
`await say(speaker, lines)` advances on Enter / Space / click (autoplay: every 0.8 s, printed); `set_audio()` plays the dialogue sound when it opens.
```

9. Replace:

```markdown
one battle: call `setup(hero, enemy_data, inventory)` before adding it (hero and inventory used as is, enemy duplicated);
```

with:

```markdown
one battle: call `setup(hero, enemy_data, inventory)`, `set_audio(audio)` and set `char_time` before adding it (hero and inventory used as is, enemy duplicated; without audio it is silent);
```

10. Replace:

```markdown
Every message goes through `_say()`.
```

with:

```markdown
Every message goes through `_say()`. Effects: hit, crit, miss, fire on spell casts, potion, heal, level up, accept on "Continuar"; music: victory fanfare on the VICTORY event, defeat when the hero falls.
```

11. Replace:

```markdown
typed message window; `await show_message(text)` returns on click / Enter / Space or after auto-advance;
```

with:

```markdown
typed message window (`char_time` seconds per character); `await show_message(text)` returns on click / Enter / Space or after auto-advance; `set_audio()` adds cursor and accept sounds;
```

12. Replace:

```markdown
with "Continuar" (`continue_requested`).
```

with:

```markdown
with "Continuar" (`continue_requested`).
- `scripts/ui/options_panel.gd` (`OptionsPanel`, `VBoxContainer`) — music and effects sliders (0-100 % in steps of 10) and text speed (Lenta / Normal / Rápida), applied at once; `setup(options, audio)`, `focus_first()`, `back()` (saves the options, emits `closed`). Used by the title and the pause menu.
- `scripts/ui/pause_menu.gd` (`PauseMenu`, `Control`, `PROCESS_MODE_ALWAYS`) — Esc / P or the ☰ button (top right, three `ColorRect` bars) open it while `available`; sets `get_tree().paused`. Pages: main (Estado, Objetos, Guardar, Opciones, Volver al título, Cerrar), Estado, Objetos ("Usar" the potion), Opciones (`OptionsPanel`), confirmation before the title. Signals `save_requested` (answered with `show_save_result(ok)`), `title_requested`, `state_changed`; `tour()` for `--autoplay-menu`.
- `scripts/audio/music_library.gd` (`MusicLibrary`) — original tracks as note tables (`TRACKS`: bpm, loop, lead duty, bars of tokens like `"F#5/4"` = note / length in sixteenths, `r` rest, drums `k` / `s` / `h`): title, map, village (waltz), battle, boss loop; victory and defeat don't. `build(id)` synthesizes square lead, triangle bass and noise drums into a cached `AudioStreamWAV` (22050 Hz, 16-bit mono, `LOOP_FORWARD` over the whole track); `to_stream()`, `peak()`, `clear_cache()`.
- `scripts/audio/sfx_library.gd` (`SfxLibrary`) — sfxr-style effects as parameter dictionaries (`SOUNDS`: wave, pitch slide or notes, time, volume, decay); `build(id)` cached; `clear_cache()`.
- `scripts/audio/audio_director.gd` (`AudioDirector`, `Node`, `PROCESS_MODE_ALWAYS`) — not an autoload; two music players with a 0.5 s cross-fade (`play_music(id)`, `stop_music()`), 6 effect players (`play_sfx(id)`), `set_volumes(music, sfx)`. Muted on autoplay (prints `Música: <id>`); headless and `--write-movie` runs never call `play()` (their audio drivers would leak the playbacks at exit). Empties the caches when it leaves the tree.
```

13. Replace:

```markdown
- No autoloads: `Game` owns the state and passes it explicitly.
```

with:

```markdown
- No autoloads: `TitleScreen` owns the `AudioDirector` and the options, `Game` owns the session state, and both pass them on explicitly (`setup()`, `set_audio()`).
```

14. Replace:

```markdown
- Run the game: `.\tools\godot.cmd --path .`
- Run the game on autoplay (walks a route, fights picking "Atacar", continues by itself): `.\tools\godot.cmd --path . -- --autoplay`
```

with:

```markdown
- Run the game (title screen): `.\tools\godot.cmd --path .`
- Run the game on autoplay (no title: a new game that walks a route, fights picking commands and continues by itself; saves to `user://save_autoplay.json`): `.\tools\godot.cmd --path . -- --autoplay`
- Save round trip: `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay --autoplay-save` (the `Guardado:` and `Cargado:` JSON lines must be identical). Delete `%APPDATA%\Godot\app_userdata\rpg-turnos\save_autoplay.json` afterwards.
- Pause menu frames: `.\tools\godot.cmd --path . --write-movie <dir>\f.png --fixed-fps 10 --quit-after 110 -- --autoplay --autoplay-menu` (☰ around frame 18, then main, Estado, Objetos, Opciones every 15 frames).
- Run one session without the title: `.\tools\godot.cmd --path . res://scenes/game/game.tscn -- --autoplay`
```

15. Replace:

```markdown
- Known noise: windowed runs with `--fixed-fps` print one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` right after the world map starts.
```

with:

```markdown
- Known noise: runs with `--fixed-fps` (headless or windowed) may print one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` after the world map starts.
```

- [ ] **Step 2: Check every new and changed script once more**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "game/game_options","audio/music_library","audio/sfx_library","audio/audio_director","game/save_data","game/save_store","game/inventory","game/game_state","world/world","ui/dialogue_box","ui/battle_hud","battle/battle_scene","game/game","ui/options_panel","title/title_screen","ui/pause_menu") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no errors or warnings.

- [ ] **Step 3: Full autoplay and save round trip**

Run Task 4 Step 7 and Task 5 Step 5 again. Expected: identical `Guardado` / `Cargado` JSON; the quest completes; only the known Jolt warning.

- [ ] **Step 4: Web export**

```powershell
.\tools\godot.cmd --headless --path . --export-release "Web" build/web/index.html
Get-ChildItem build/web
```

Expected: `index.html`, `index.js`, `index.wasm`, `index.pck` (about 3 MB), the audio worklets and icons; no ERROR. (Checked while writing this plan: the export works with the new scripts.)

- [ ] **Step 5: Web save / reload / continue**

Serve the build and open it in the built-in browser pane (load the `anthropic-skills:built-in-browser` skill first):

```powershell
python -m http.server 8060 --directory build/web
```

(run it in the background), then open `http://localhost:8060/`. Check, with screenshots:
1. The title shows; "Continuar" is greyed out on a fresh browser profile.
2. Click "Nueva partida": the map appears (the music starts after this first click; browsers only allow audio after a user gesture).
3. Click the ☰ button, then "Guardar": "Partida guardada." appears in the menu. Click "Cerrar".
4. Reload the page: "Continuar" is now enabled. Click it: the map shows the hero where it was saved, same status window values.
5. Stop the server. `build/` is git-ignored.

- [ ] **Step 6: Windowed run with sound (for the user)**

```powershell
.\tools\godot.cmd --path .
```

The title music must play; "Nueva partida" goes to the map music, the clearing switches to the village waltz, battles have their own track and effects, Esc / P / ☰ pause the map. Listening can only be confirmed by the user: say in the final report that the sound has not been heard by the agent and ask the user to listen once.

- [ ] **Step 7: Commit**

```powershell
git add CLAUDE.md
git commit -m "Document the game-feel phase"
```

Do not merge or push; report to the user.

---

## Self-review

Checked against `docs/boost/specs/2026-11-03-sensacion-juego-design.md`:

- **Audio generated in code** (no downloads, no licences): `MusicLibrary` / `SfxLibrary` build `AudioStreamWAV` at 22050 Hz, 16-bit mono and cache them (Task 1). The spec says "al arrancar"; the streams are built on first use and cached (each track takes 25-145 ms on desktop, all seven about 0.7 s), which avoids a long freeze before the title on the web.
- **Seven tracks** title, map, village, battle, boss (loops of 20-29 s) and victory, defeat (no loop), square lead, triangle bass, noise drums, own tempo and key each; **original** note tables (Task 1).
- **14 effects** (cursor, accept, cancel, hit, crit, miss, fire, heal, level up, encounter, potion, footsteps on the map only, dialogue, save): Task 1, wired in Tasks 3-5.
- **Player**: `AudioDirector` is not an autoload, 0.5 s cross-fade, 6 effect players, separate volumes saved in the options; muted on autoplay and headless (Task 1). Deviation: the title screen (not `Game`) creates it, because the title already needs music before any `Game` exists; `Game` makes its own only when `game.tscn` runs on its own.
- **Title screen**: "Villaclaro" over the meadow seen from a slowly drifting top-down camera; Nueva partida, Continuar (disabled without a save), Opciones; keyboard, mouse and touch (Task 4).
- **Save**: one file `user://save.json` (IndexedDB on the web), hero (level, HP, MP, EXP, stats), inventory, quest, map position, play time, `version` (Tasks 2 and 4). Autosave after talking to the old woman and after every won battle, manual save from the pause menu, never during a battle; defeat unchanged and saved by the next autosave.
- **Pause menu**: Esc / P and the ☰ button; Estado (level, PV, PM, ATK, DEF, VEL, EXP and what is missing for the next level), Objetos (potion usable), Guardar, Opciones (music, effects, text speed), Volver al título (with a confirmation page); the map pauses (Task 5).
- **Options** in `user://options.json`: music 70 %, effects 80 %, text speed lenta / normal / rápida (Tasks 1, 4). The text speed sets the typing speed of the battle messages (the map dialogue shows each line whole, as before).
- **Pure rules**: `SaveData` converts without nodes or files; `SaveStore` does the files (Task 2). Interface names: `SaveStore.save_game()` / `load_game()` instead of `save()` / `load()`, because `load` is a GDScript global function.
- **Other classes get the director through `set_audio()`** and stay silent without it (Task 3).
- **Autoplay** starts a new game without the title; `--autoplay-save` saves, goes back to the title, continues and prints values before and after (Task 4). Also added: `--autoplay-menu` to record frames of the pause menu (Task 5), and autoplay uses its own save file.
- **Verification**: `--check-only` and `--import`, full autoplay, `--autoplay-save`, one-off audio script, frames of title / pause (Estado, Objetos) / options, web export with save → reload → Continuar; sound heard by the user.
- Out of scope respected: one slot, no export / import, no languages, no key remapping.
