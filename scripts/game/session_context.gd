class_name SessionContext extends RefCounted
## What the pieces of one play session share. Game builds it in _ready() (_make_context())
## and keeps it up to date; each piece gets it in setup() and reads the current map from it
## every time (world changes on every change of zone: a piece never keeps a World of its
## own). Holds no rules.

var state: GameState
## The current map. Game sets it each time ZoneTravel builds one (Game._on_world_replaced()).
var world: World
## The current map's zone (World.zone; the Caravana's is dressed by CampLook, Brumaclara's by BrumaclaraLook).
var zone: ZoneData:
	get:
		return world.zone if world != null else null
var audio: AudioDirector
var options: GameOptions
## The save slot this game writes to (SaveStore; ignored on autoplay runs). Set once.
var slot := 1
## Seconds played, saved with the game; Game._process() counts it (it stops while paused).
var play_time := 0.0
## A battle, a dialogue, a fade, a menu or a scene is on. Written only by Game._set_busy().
var busy := false
## await fade.call(alpha): to black (1.0) or back (0.0).
var fade: Callable
## autosave.call(notice) -> Dictionary: writes the save (shows "Partida guardada." if
## notice); returns the saved data, empty if the file could not be written.
var autosave: Callable
## set_busy.call(busy): the pause menu and the debug panel only open when not busy.
var set_busy: Callable
## refresh_status.call(): the map's status window, quest marks and the hero's equipment.
var refresh_status: Callable
## play_map_music.call(): the zone's map or village music and its ambient.
var play_map_music: Callable


## The healing potions carried, big ones too: the map's counter and the retreat line.
func potion_count() -> int:
	return state.inventory.count(Inventory.POTION) + state.inventory.count(Inventory.BIG_POTION)
