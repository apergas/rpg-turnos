class_name AudioDirector extends Node
## Plays the music, the sound effects and the ambient of each place. Not an autoload:
## TitleScreen creates the only one and passes it on (Game, World, BattleScene, BattleHud,
## DialogueBox, PauseMenu get it through set_audio()). Two music players cross-fade over
## CROSSFADE seconds; SFX_PLAYERS players take turns for the effects. The ambient
## (AmbientLibrary: a bed that loops and short sounds now and then) has two players of its
## own that cross-fade over AMBIENT_CROSSFADE seconds and one more for its short sounds, at
## the effects volume × AMBIENT_SHARE. With `-- --autoplay` everything plays the same but
## muted, and each music change and each ambient started is printed. On a headless run or
## while recording frames (--write-movie) the streams are built and set but never started:
## those audio drivers keep the playbacks alive at exit and Godot reports them as leaked.
## Keeps running while the tree is paused (the ambient's short sounds wait).

const CROSSFADE := 0.5
const SFX_PLAYERS := 6
const AMBIENT_CROSSFADE := 1.0
## The ambient plays at the effects volume times this.
const AMBIENT_SHARE := 0.5

var music_volume := GameOptions.DEFAULT_MUSIC
var sfx_volume := GameOptions.DEFAULT_SFX

var _music: Array[AudioStreamPlayer] = []
var _sfx: Array[AudioStreamPlayer] = []
var _current := 0
var _next_sfx := 0
var _music_id := ""
var _fade: Tween
## The two players of the ambient's bed, the one in use, its id ("" for none) and its own
## cross-fade; the player of its short sounds and the seconds until the next one.
var _ambient: Array[AudioStreamPlayer] = []
var _ambient_current := 0
var _ambient_id := ""
var _ambient_fade: Tween
var _shot: AudioStreamPlayer
var _shot_in := 0.0
var _rng := RandomNumberGenerator.new()
var _muted := false
## Headless or --write-movie: never start a player.
var _no_playback := false
var _autoplay := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	_no_playback = DisplayServer.get_name() == "headless" \
		or Engine.get_write_movie_path() != ""
	_muted = _autoplay or _no_playback
	_rng.randomize()
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.volume_linear = 0.0
		add_child(player)
		_music.append(player)
	for i in SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx.append(player)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.volume_linear = 0.0
		add_child(player)
		_ambient.append(player)
	_shot = AudioStreamPlayer.new()
	add_child(_shot)


## Empties the stream caches, so no stream is left at exit.
func _exit_tree() -> void:
	MusicLibrary.clear_cache()
	SfxLibrary.clear_cache()
	AmbientLibrary.clear_cache()


## The ambient's short sounds: one every AmbientLibrary.gap() seconds, a variant picked at
## random. None while muted or while the tree is paused.
func _process(delta: float) -> void:
	if _ambient_id == "" or _muted or get_tree().paused:
		return
	_shot_in -= delta
	if _shot_in > 0.0:
		return
	_shot_in = AmbientLibrary.gap(_ambient_id, _rng)
	_shot.stream = AmbientLibrary.shot(_ambient_id, _rng.randi() % AmbientLibrary.VARIANTS)
	_shot.volume_linear = _ambient_level()
	_start(_shot)


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


## Cross-fades over AMBIENT_CROSSFADE to the ambient (an AmbientLibrary id; "" stops it);
## does nothing if it already plays. Prints "Ambiente: <id>" on autoplay.
func play_ambient(id: String) -> void:
	if id == "":
		stop_ambient()
		return
	if id == _ambient_id:
		return
	_ambient_id = id
	if _autoplay:
		print("Ambiente: %s" % id)
	var old := _ambient[_ambient_current]
	_ambient_current = 1 - _ambient_current
	var new := _ambient[_ambient_current]
	new.stream = AmbientLibrary.bed(id)
	new.volume_linear = 0.0
	_start(new)
	_new_ambient_fade()
	_ambient_fade.tween_property(new, "volume_linear", _ambient_level(), AMBIENT_CROSSFADE)
	_ambient_fade.tween_property(old, "volume_linear", 0.0, AMBIENT_CROSSFADE)
	_ambient_fade.chain().tween_callback(old.stop)
	_shot_in = AmbientLibrary.gap(id, _rng)


## Fades the ambient out (a battle, the credits, a cutscene that changes the music, back to
## the title); a short sound playing stops at once.
func stop_ambient() -> void:
	if _ambient_id == "":
		return
	_ambient_id = ""
	_shot.stop()
	_new_ambient_fade()
	for player in _ambient:
		_ambient_fade.tween_property(player, "volume_linear", 0.0, AMBIENT_CROSSFADE)
	_ambient_fade.chain().tween_callback(func() -> void:
		for player in _ambient:
			player.stop())


func play_sfx(id: String) -> void:
	var player := _sfx[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_PLAYERS
	player.stream = SfxLibrary.build(id)
	player.volume_linear = 0.0 if _muted else sfx_volume
	_start(player)


## Volumes 0..1. The music and the ambient change at once (any cross-fade ends where it is).
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
	if _ambient_fade:
		_ambient_fade.kill()
	for i in 2:
		var player := _ambient[i]
		if i == _ambient_current and _ambient_id != "":
			player.volume_linear = _ambient_level()
		else:
			player.volume_linear = 0.0
			player.stop()


func _start(player: AudioStreamPlayer) -> void:
	if not _no_playback:
		player.play()


func _music_level() -> float:
	return 0.0 if _muted else music_volume


func _ambient_level() -> float:
	return 0.0 if _muted else sfx_volume * AMBIENT_SHARE


func _new_fade() -> void:
	if _fade:
		_fade.kill()
	_fade = create_tween().set_parallel()


func _new_ambient_fade() -> void:
	if _ambient_fade:
		_ambient_fade.kill()
	_ambient_fade = create_tween().set_parallel()
