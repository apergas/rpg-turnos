class_name Game extends Node
## One play session, created by TitleScreen (setup() before add_child). Owns the
## GameState and the map of the current zone (a World built from its ZoneData), and puts
## a battle on top of the map when the hero touches a group of monsters on it (its
## formation, World.contact_enemies()) or the zone's boss. The map stays while battles
## come and go, so the hero's position, the camera and the groups survive them; walking
## into an open exit fades to black, frees the map and builds the next zone at the exit's
## entry (GameState.zone_id), every group back. A victory adds the gold and counts
## every enemy defeated for the quest; a boss also sets its world flag (the Rey Slime
## lifts the fog of the meadow's north exit) and gives its key item. Fleeing just goes
## back to the map; a defeat takes half the gold (GameState.defeat_gold_loss()), heals the
## hero and sends them to the last village visited (GameState.town_zone), EXP kept, like
## the Ala de viaje used from the pause menu, which also leaves a portal in that village
## that leads back once (GameState.open_portal(); a second Ala replaces it, a defeat leaves
## it open). Talking to the old woman heals, moves the
## quest on and, once the slimes are reported, brings out the Rey Slime; the other
## villagers say their ZoneData lines. The Coleccionista of Villaclaro trades the small medals for
## prizes (Medals.talk()); a battle's medal drops go to GameState.medals (Medals.take()).
## The merchant opens the ShopWindow; the innkeeper
## offers a free night (Inn.stay(): fade to black, full HP and MP, autosave); a chest gives
## what it holds (Chests.open()) and stays open. The hero's figure on the map and in
## battle shows the weapon and shield worn. On a dungeon floor the lever sets its world
## flag (and opens the gates it works), the key goes to the key items (and its flag is
## set, so it stays taken) and a locked gate opens with the key, which is used up; all
## three autosave silently. Picks the zone's music (map, village, battle,
## boss), autosaves after talking, after every won battle, after shopping, (silently)
## after opening a chest, after a defeat and after every change of zone, and opens the
## pause menu. Emits quit_to_title when the player goes back to the title.
## With `--debug` on the command line (never otherwise) it owns a DebugPanel: F1 on the map
## opens it, and Game does what its buttons ask (_on_debug(), printed as "Depuración: ...").
## The story (GameState.story): a new game opens with the prologue in the hero's house
## (data/cutscenes/prologo.tres, which starts the slimes quest); each boss beaten plays
## its cutscene (StoryState.AFTER_BOSS) and the first visit to each village its own
## (StoryState.ON_VILLAGE), through the CutscenePlayer; the villagers' lines follow the
## chapter. Beating the Señor de la Niebla (GameState.FINAL_BOSS) plays the ending (back
## to Villaclaro), marks the save as finished (story.finished) and rolls the credits with
## the numbers of the game (CreditsScreen); then it goes back to the title. A finished
## save loads in Villaclaro and the world can still be walked. On a finished save the title may
## start a Partida nueva + (setup(..., new_cycle)): NgPlus.begin() keeps the hero and starts the
## story again, and every enemy of every battle is a stronger copy (NgPlus.scaled(), by the zone's
## number); the credits add its round.
## Each bestiary family beaten whole (Bestiary) gives its prize once, after the battle that completes it or when a game is loaded, in the dialogue window.
## The side quests (GameState.quests): a villager or a board asks the QuestLog first (a
## report, a figure found, a new offer) and says its chapter lines if it has nothing about
## any; the map shows the marks and the sought figures it says. Each finished quest shows
## for a few seconds (World.show_mission_done()) and no quest holds anything back. On
## autoplay it reads and talks like a player on its route, uses the seeds at once and flies
## back to report to whoever is waiting in the last village.
## On autoplay it prints the gold and the equipment each time they change, the level and
## the play time on every change of zone and, after the credits, the play time of the
## whole run (TitleScreen then quits). After a won battle, when the hero needs rest
## (GameState.needs_rest()) or the map has no group left (_needs_groups()) away from a
## village, it flies back with an Ala de viaje, sleeps at the inn, restocks at the shop
## and goes back through the portal; after a defeat it
## sleeps and restocks too. With no Ala de viaje an empty map gets its groups back at once.
## Run on its own (res://scenes/game/game.tscn) it starts a new game with its own
## AudioDirector and default options.
##
## `-- --autoplay --autoplay-save`: after the first autosave that follows a won battle
## it prints the saved values ("Guardado: ...") and goes back to the title, which loads
## the save at once; the loaded game prints the same values ("Cargado: ...").
## `-- --autoplay --autoplay-menu`: MENU_TOUR_DELAY seconds into the map (before any group
## is in reach) it shows every page of the pause menu (PauseMenu.tour()), to
## record frames of it.
## `-- --autoplay --autoplay-zone=<id>`: a new game that starts in that zone with the
## level, gold, gear and progress AUTOPLAY_ZONES gives it.
## `-- --autoplay --autoplay-zone=ciudad` / `portal`: the v2's last stretch: Lv 35 at the city's
## first floor (the Grifo beaten), or Lv 38 at the portal quarter (the Guardián beaten, its
## key); they play on to the Devorador, the ending, the v2's credits and "Continuará".
## `-- --autoplay --autoplay-zone=medallas`: the finished game of ECHO_START in Villaclaro;
## it hunts the meadow's groups until it carries every medal dropped (MEDAL_TOUR_CHANCE),
## then talks to the Coleccionista and prints "Medallas: n/12 · premios n/5".
## `-- --autoplay --autoplay-zone=ngplus`: a first Partida nueva + with the hero of ECHO_START
## and the Yelmo de bruma, the whole story again.
## `-- --autoplay --autoplay-zone=eco`: a finished game in the throne room at Lv 20 that
## fights the Eco de la Niebla again and again, printing each result.
## `-- --autoplay --autoplay-easy`: a new game on Fácil.

signal quit_to_title

const HERO_DATA := preload("res://data/hero.tres")
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const WORLD_SCENE := preload("res://scenes/world/world.tscn")
const CUTSCENE_PATH := "res://data/cutscenes/%s.tres"
## The author shown in the credits.
const AUTHOR := "apergas"
const FADE_TIME := 0.3
const TOUCH_HINT := "Toca el suelo para ir allí, o arrastra el dedo para andar."
## The v2's Jefe de caravana: in Villaclaro once the caravan has come, then in the Caravana.
const CARAVAN_CHIEF := "Jefe de caravana"
const JOIN_QUESTION := "Cuando partamos, no volverás por aquí en mucho tiempo. ¿Te unes a la caravana?"
const LEAVE_QUESTION := "No podrás volver a Villaclaro, ni al bosque, la mina o el castillo. Las misiones que no hayas cumplido se quedan sin hacer."
const REPEL_END_NOTICE := "El incienso se ha consumido."
const HEAL_LINE := "Descansas un momento. PV y PM recuperados."
const SAVED_NOTICE := "Partida guardada."
const LOAD_FAILED_NOTICE := "No se pudo cargar la partida. Empiezas de nuevo."
## Notice after beating a boss (by id); other bosses announce their key item.
const BOSS_NOTICES := {
	"rey_slime": "¡Villaclaro está a salvo! La niebla deja libre el camino del norte.",
	"senor_niebla": "¡Consigues el último Fragmento del amuleto! La niebla se levanta.",
	"eco_niebla": "El Eco de la Niebla se deshace en la bruma... por ahora.",
}
## Said before a boss's first-victory prize (Combatant.reward_equipment).
const REWARD_LINE := "Entre la bruma brilla algo."
const KEY_ITEM_NOTICE := "¡Consigues un %s!"
const LEVER_NOTICE := "¡Tiras de la palanca! Se oye cómo se abre una reja."
const KEY_NOTICE := "¡Encuentras la %s!"
const DOOR_NOTICE := "Abres la reja con la %s."
const PORTAL_OPEN_NOTICE := "Vuelas %s. El portal te espera para volver."
const PORTAL_REPLACED_NOTICE := "Vuelas %s. El portal anterior se ha cerrado."
const PORTAL_BACK_NOTICE := "El portal te devuelve y se cierra tras de ti."
const MENU_TOUR_DELAY := 1.0
## Seconds of black while the hero sleeps at the inn.
const INN_NIGHT_TIME := 0.8
## On autoplay the hero only stops at an inn below this share of max HP or MP.
const AUTOPLAY_INN_RATIO := 0.5
## Autoplay: seconds on a map without a battle, below the zone's autoplay_boss_level, after
## which its groups are put back (the ones left may be out of reach of the route).
const AUTOPLAY_STALL_S := 90.0
## On autoplay the boss only comes out while the hero has these shares of max HP and MP.
const AUTOPLAY_BOSS_HP := 0.7
const AUTOPLAY_BOSS_MP := 0.4
## --autoplay-zone=eco: a finished game in the throne room, ready for the Eco de la Niebla.
const ECHO_START := "eco"
## --autoplay-zone=medallas: the finished game of ECHO_START in Villaclaro; it hunts the
## meadow's groups with MEDAL_TOUR_CHANCE (the real DROP_CHANCE would take hours) until it
## carries every medal, or MEDAL_TOUR_TIME seconds pass, then talks to the Coleccionista in
## Villaclaro and in the forest village.
const MEDAL_TOUR := "medallas"
const MEDAL_TOUR_CHANCE := 0.25
const MEDAL_TOUR_TIME := 1800.0
## --autoplay-zone=ngplus: the hero of ECHO_START with the Yelmo de bruma, and a first
## Partida nueva + from the prologue.
const NG_PLUS_START := "ngplus"
## The autoplay starts that play the v2: only they answer the Jefe de caravana's questions
## with Sí (every other run, the finished-game ones included, stays in the v1).
const V2_STARTS := ["caravana", "jungla", "desierto", "montana", "ciudad", "portal"]
## --autoplay-zone=<id>: what a new game starting in each zone gets, as planned when
## arriving there (zone 1 done: Lv 5, its shop's gear, the Rey Slime beaten).
const AUTOPLAY_ZONES := {
	"bosque": {
		"experience": 136,
		"gold": 150,
		"gear": [Equipment.COPPER_SWORD, Equipment.LEATHER_MAIL, Equipment.WOODEN_SHIELD],
		"flags": ["rey_slime"],
		"quest_done": true,
	},
	# Zone 2 done: Lv 9 with the Bruja's EXP, the forest gear and the first fragment.
	"mina_1": {
		"experience": 541,
		"gold": 250,
		"gear": ["espada_hierro", "cota_malla", "escudo_hierro"],
		"flags": ["rey_slime", "bruja"],
		"key_items": ["fragmento_bosque"],
		"quest_done": true,
	},
	# Ready for the Golem: Lv 13, the mine's gear, the gates of floors 2 and 3 open.
	"mina_3": {
		"experience": 1073,
		"gold": 100,
		"gear": ["espada_acero", "armadura_acero", "escudo_acero"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta"],
		"key_items": ["fragmento_bosque"],
		"quest_done": true,
		"town": "mina_1",
	},
	# Zone 3 done: Lv 13 with the Golem's EXP and gold, the mine's gear and two fragments.
	"castillo_patio": {
		"experience": 1373,
		"gold": 600,
		"gear": ["espada_acero", "armadura_acero", "escudo_acero"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra"],
		"key_items": ["fragmento_bosque", "fragmento_mina"],
		"quest_done": true,
		"town": "mina_1",
	},
	# After the ending (--autoplay-zone=eco): Lv 20, the platinum gear with its helmet, the
	# Esqueleto leal, every boss beaten and the story finished, in the throne room.
	ECHO_START: {
		"zone": "castillo_trono",
		"experience": 3600,
		"gold": 1000,
		"gear": ["espada_platino", "armadura_platino", "escudo_platino", "casco_platino"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo"],
		"quest_done": true,
		"town": "castillo_patio",
		"ally": "esqueleto_leal",
		"items": {Inventory.POTION: 2, Inventory.ETHER: 3, Inventory.WING: 3},
	},
	# --autoplay-zone=medallas: the hero of ECHO_START, the game finished, in Villaclaro.
	MEDAL_TOUR: {
		"zone": "pradera",
		"experience": 3600,
		"gold": 1000,
		"gear": ["espada_platino", "armadura_platino", "escudo_platino", "casco_platino"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo"],
		"quest_done": true,
		"town": "pradera",
		"ally": "esqueleto_leal",
		"items": {Inventory.POTION: 5, Inventory.ETHER: 3, Inventory.WING: 3},
	},
	# --autoplay-zone=ngplus: the hero of ECHO_START with the Yelmo de bruma (the Eco beaten
	# once: its flag stays), then NgPlus.begin().
	NG_PLUS_START: {
		"zone": "pradera",
		"experience": 3600,
		"gold": 1000,
		"gear": ["espada_platino", "armadura_platino", "escudo_platino", Equipment.MIST_HELM],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "eco_niebla"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo"],
		"quest_done": true,
		"town": "castillo_patio",
		"ally": "esqueleto_leal",
		"items": {Inventory.POTION: 2, Inventory.ETHER: 3, Inventory.WING: 3},
		"new_cycle": true,
	},
	# --autoplay-zone=caravana: the v1 finished, in Villaclaro: Lv 20, the platinum gear, the
	# Esqueleto leal, every boss beaten and the credits seen. The caravan comes on arrival,
	# the hero leaves with it (V2_STARTS answers the Jefe's questions) and plays the v2 on.
	"caravana": {
		"zone": "pradera",
		"experience": 3600,
		"gold": 1200,
		"gear": ["espada_platino", "armadura_platino", "escudo_platino", "casco_platino"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo"],
		"quest_done": true,
		"town": "pradera",
		"ally": "esqueleto_leal",
		"items": {Inventory.POTION: 3, Inventory.ETHER: 3, Inventory.WING: 2},
		"finished": true,
	},
	# --autoplay-zone=jungla: ready for the jungle: the caravan joined, Brena chosen, Lv 20 with
	# the platinum gear, at the jungle's entrance.
	"jungla": {
		"experience": 3600,
		"gold": 1500,
		"gear": ["espada_platino", "armadura_platino", "escudo_platino", "casco_platino"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo"],
		"quest_done": true,
		"town": "caravana",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 3, Inventory.ETHER: 3, Inventory.WING: 2},
		"finished": true,
	},
	# --autoplay-zone=desierto: the jungle done: Lv 25 with the jade gear, Brena, the Jaguar
	# beaten and its insignia, at the desert's entrance.
	"desierto": {
		"experience": 6850,
		"gold": 900,
		"gear": ["espada_jade", "armadura_jade", "escudo_jade", "casco_jade"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero",
			"jaguar_sombrio"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo",
			"insignia_jungla"],
		"quest_done": true,
		"town": "caravana",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 3, Inventory.BIG_ETHER: 2, Inventory.WING: 2},
		"finished": true,
	},
	# --autoplay-zone=montana: the desert done: Lv 30 with the orichalcum gear, Brena, the
	# Gusano beaten and its seal, at the mountain's entrance (its first floor).
	"montana": {
		"zone": "montana_1",
		"experience": 11350,
		"gold": 1000,
		"gear": ["espada_oricalco", "armadura_oricalco", "escudo_oricalco", "casco_oricalco"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero",
			"jaguar_sombrio", "gusano_dunas"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo",
			"insignia_jungla", "sello_desierto"],
		"quest_done": true,
		"town": "caravana",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 3, Inventory.BIG_ETHER: 2, Inventory.WING: 2},
		"finished": true,
	},
	# --autoplay-zone=ciudad: the mountain done: Lv 35 with the adamantite gear, Brena, the
	# Grifo beaten and its map, at the city's entrance (its first floor).
	"ciudad": {
		"zone": "ciudad_1",
		"experience": 17100,
		"gold": 1200,
		"gear": ["espada_adamantita", "armadura_adamantita", "escudo_adamantita",
			"casco_adamantita"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero",
			"jaguar_sombrio", "gusano_dunas", "montana_palanca", "grifo_cumbre"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo",
			"insignia_jungla", "sello_desierto", "mapa_montana"],
		"quest_done": true,
		"town": "caravana",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 3, Inventory.BIG_ETHER: 2, Inventory.WING: 2},
		"finished": true,
	},
	# --autoplay-zone=portal: the Guardián beaten: Lv 38 with the stellar gear, Brena and the
	# Llave del portal, at the portal quarter's entrance (the city's second floor).
	"portal": {
		"zone": "ciudad_2",
		"experience": 21150,
		"gold": 800,
		"gear": ["espada_estelar", "armadura_estelar", "escudo_estelar", "casco_estelar"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero",
			"jaguar_sombrio", "gusano_dunas", "montana_palanca", "grifo_cumbre",
			"guardian_ciudad"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo",
			"insignia_jungla", "sello_desierto", "mapa_montana", "llave_portal"],
		"quest_done": true,
		"town": "caravana",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 4, Inventory.BIG_ETHER: 3, Inventory.WING: 2,
			Inventory.PHOENIX: 1},
		"finished": true,
	},
	# Ready for the Señor de la Niebla: Lv 17 with the castle's gear.
	"castillo_trono": {
		"experience": 2244,
		"gold": 300,
		"gear": ["espada_platino", "armadura_platino", "escudo_platino"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra"],
		"key_items": ["fragmento_bosque", "fragmento_mina"],
		"quest_done": true,
		"town": "castillo_patio",
	},
}

var state: GameState
## Seconds played, saved with the game; stops while paused.
var play_time := 0.0

var _world: World
var _zone: ZoneData
var _fade: ColorRect
var _pause: PauseMenu
var _audio: AudioDirector
var _options: GameOptions
var _save := {}
## The name typed on the NameEntry for a new game ("" for the default).
var _hero_name := ""
## The difficulty chosen for a new game.
var _difficulty := Difficulty.NORMAL
var _cutscenes: CutscenePlayer
var _busy := false
## Autoplay: seconds since the last battle or change of map (AUTOPLAY_STALL_S).
var _quiet_s := 0.0
var _leaving := false
var _autoplay := false
var _autoplay_save := false
var _autoplay_menu := false
## --autoplay-companion=<id>: the companion autoplay chooses at the Caravana (Brena if none).
var _autoplay_companion := "brena"
## --autoplay-zone=caravana / jungla: autoplay leaves with the caravan and plays the v2.
var _autoplay_v2 := false
var _last_missions: Array[String] = []
var _last_gear_text := ""
## The save slot this game writes to (SaveStore; ignored on autoplay runs).
var _slot := 1
## A Partida nueva + on the save given (TitleScreen): NgPlus.begin() once it is loaded.
var _new_cycle := false
## The save could not be read: the new game says so after the prologue.
var _load_failed := false
## Autoplay: defeats so far (each prints "Derrota en <zone> (n)"; the credits say the total).
var _defeats := 0
## --autoplay-zone=eco: autoplay goes for the Eco de la Niebla (never on any other run).
var _autoplay_echo := false
## --autoplay-zone=eco: fights with the Eco and how many were won, printed after each.
var _echo_fights := 0
var _echo_wins := 0
## --autoplay-zone=medallas: the tour is on.
var _medal_tour := false
## Autoplay: common enemies beaten in won battles (the credits print it with the medals, to
## tune Medals.DROP_CHANCE).
var _common_beaten := 0
var _shop: ShopWindow
## Something was bought, sold or equipped since the shop opened.
var _shop_changed := false
var _rng := RandomNumberGenerator.new()
## The development panel, only with --debug (null otherwise).
var _debug: DebugPanel


## audio and options come from the title screen; save is the Dictionary read by
## SaveStore.load_game(), empty for a new game, which gets hero_name and difficulty; slot is
## the save slot it writes to; new_cycle starts a Partida nueva + on that (finished) save.
func setup(audio: AudioDirector, options: GameOptions, save: Dictionary,
		hero_name := "", difficulty := Difficulty.NORMAL, slot := 1, new_cycle := false) -> void:
	_slot = slot
	_audio = audio
	_options = options
	_save = save
	_hero_name = hero_name
	_difficulty = difficulty
	_new_cycle = new_cycle


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_autoplay = args.has("--autoplay")
	_autoplay_save = _autoplay and args.has("--autoplay-save")
	_autoplay_menu = _autoplay and args.has("--autoplay-menu")
	for arg in args:
		if arg.begins_with("--autoplay-companion="):
			var companion := arg.trim_prefix("--autoplay-companion=")
			if Allies.is_companion(companion):
				_autoplay_companion = companion
			else:
				push_error("Not a companion for --autoplay-companion: %s" % companion)
	_rng.randomize()
	for line in QuestLog.problems():
		push_warning(line)
	if _options == null:
		_options = GameOptions.new()
	if _audio == null:
		_audio = AudioDirector.new()
		add_child(_audio)
		_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	state = GameState.new(HERO_DATA)
	var load_failed := false
	var start_pos: Variant = null
	if not _save.is_empty():
		var info := SaveData.apply(state, _save)
		if info.valid:
			start_pos = info.position
			play_time = info.play_time
			if _autoplay_save:
				print("Cargado: %s" % _summary(SaveData.from_state(state, info.position,
					info.play_time)))
			# The arrival lines of the lands already passed (and of this one) are not said
			# again on loading.
			Allies.mark_arrivals(state.world_flags, state.zone_id)
			if _new_cycle:
				# Partida nueva +: the hero as he is, the story from the prologue again, in the
				# hero's house, with the clock at 0.
				NgPlus.begin(state)
				start_pos = null
				play_time = 0.0
		else:
			load_failed = true
	_load_failed = load_failed
	if _save.is_empty() or load_failed:
		state.hero.display_name = StoryState.clean_name(_hero_name)
		state.difficulty = _difficulty
		if _autoplay and OS.get_cmdline_user_args().has("--autoplay-easy"):
			state.difficulty = Difficulty.EASY
	if _save.is_empty() and _autoplay:
		_apply_autoplay_zone(args)
	# A loaded game (or an --autoplay-zone start) may have a family complete already: a
	# finished game gets the Espada del alba now. After the "Cargado:" line, so the save
	# round trip still compares what was saved.
	var family_lines := _give_family_rewards()
	_build_shop()
	_build_fade()
	_build_pause()
	if args.has("--debug"):
		_build_debug()
	_build_cutscenes()
	if _autoplay_menu:
		# The tour of the pause menu needs the map, not a scene.
		state.story.mark_seen("prologo")
	# Busy until the map is ready (no ☰ either): arriving inside a village must not start its
	# cutscene yet.
	_set_busy(true)
	_switch_zone(state.zone_id, "")
	if start_pos != null:
		_world.place_player(start_pos)
		_respawn_groups()
	var prologue := state.chapter() == StoryState.Chapter.PROLOGUE
	if prologue:
		# Under black: the prologue fades in by itself.
		_fade.color.a = 1.0
		_play_prologue.call_deferred()
	# Synthesize the tracks played later now, under black, so no first play stalls.
	for id in [MusicLibrary.VILLAGE, MusicLibrary.VICTORY, MusicLibrary.DEFEAT]:
		MusicLibrary.build(id)
	_play_map_music()
	if _autoplay_menu:
		get_tree().create_timer(MENU_TOUR_DELAY).timeout.connect(_pause.tour)
	if not prologue:
		await _world.freeze(false)
		if not family_lines.is_empty():
			_audio.play_sfx(SfxLibrary.LEVEL_UP)
			await _world.show_dialogue("", family_lines)
			_autosave(false)
		if _save.is_empty():
			await _check_arrival_line()  # an --autoplay-zone start in a land (the jungle)
		_set_busy(false)
		_show_touch_hint()
		_check_village_scene()
		if _medal_tour:
			print("Medallas: a cazar en %s" % _zone.id)
			get_tree().create_timer(MEDAL_TOUR_TIME).timeout.connect(_on_medal_tour_timeout)


## The first time a phone reaches the map (never on autoplay): how to walk, once for good.
func _show_touch_hint() -> void:
	if not Device.is_touch() or _autoplay or _options.touch_hint_seen:
		return
	_options.touch_hint_seen = true
	SaveStore.save_options(_options)
	_world.show_touch_hint(TOUCH_HINT)


func _process(delta: float) -> void:
	play_time += delta / Engine.time_scale  # a fast battle takes less play time, not more
	if _autoplay and not _busy and _world != null and not _world.in_village():
		_quiet_s += delta
		if _quiet_s > AUTOPLAY_STALL_S and _autoplay_hunts():
			_quiet_s = 0.0
			print("Grupos repuestos (partida automática, sin combates)")
			_respawn_groups()
		elif _quiet_s > AUTOPLAY_STALL_S and _boss_needs_rest() \
				and state.inventory.count(Inventory.WING) > 0:
			# At the boss's level but too worn for it, with no battle coming that would bring
			# the retreat: one Ala, made here (the quiet clock starts over).
			_quiet_s = 0.0
			_autoplay_retreat()


## Back to the title: the map's ambient stops with the game. A Game run on its own frees its
## own AudioDirector first (it is a child), so there is nothing to stop.
func _exit_tree() -> void:
	if _audio and _audio.is_inside_tree():
		_audio.stop_ambient()


## --autoplay-zone=<id>: starts the new game in that zone with AUTOPLAY_ZONES' state.
func _apply_autoplay_zone(args: PackedStringArray) -> void:
	for arg in args:
		if not arg.begins_with("--autoplay-zone="):
			continue
		var start_id := arg.trim_prefix("--autoplay-zone=")
		var start: Dictionary = AUTOPLAY_ZONES.get(start_id, {})
		var zone_id: String = start.get("zone", start_id)
		if not zone_id in ZoneData.IDS:
			push_error("Unknown zone for --autoplay-zone: %s" % start_id)
			return
		state.zone_id = zone_id
		if start.is_empty():
			return
		state.hero.experience = start.experience
		Leveling.apply(state.hero)
		state.heal_full()
		state.gold = start.gold
		for id: String in start.gear:
			state.bag_equipment.append(id)
			state.equip(id)
		for flag: String in start.flags:
			state.world_flags[flag] = true
			if Bestiary.has(flag):
				# A boss of the flags was beaten on the way: the bestiary says so too.
				state.defeat_enemy(flag)
		for id: String in start.get("key_items", []):
			state.key_items.append(id)
		state.town_zone = start.get("town", state.town_zone)
		if start.quest_done:
			state.quest.stage = Quest.Stage.DONE
		# The v2's level cap needs the "caravana" flag, set just above: levels again.
		# (the first pass at the v1 cap clamped the EXP: give it back).
		state.sync_level_cap()
		state.hero.experience = start.experience
		Leveling.apply(state.hero)
		state.heal_full()
		state.ally_id = start.get("ally", "")
		if Allies.is_companion(state.ally_id):
			state.ally_id = _autoplay_companion
		var items: Dictionary = start.get("items", {})
		for id: String in items:
			state.inventory.add(id, items[id])
		_autoplay_echo = start_id == ECHO_START
		_autoplay_v2 = start_id in V2_STARTS
		_medal_tour = start_id == MEDAL_TOUR
		state.story.mark_seen_for_flags(state.world_flags)
		if start.get("finished", false):
			state.story.finished = true
		state.sync_level_cap()
		if start.get("new_cycle", false):
			NgPlus.begin(state)
			print("Partida nueva + %d" % state.ng_plus)
		print("Zona de inicio: %s (Nv %d)" % [zone_id, state.hero.level])


## Frees the current map and builds zone_id with the player at entry_id ("" for the
## zone's start entry). No fade: callers fade around it. The new map starts frozen
## (World.freeze()), so nothing on it can fire while Game is still busy fading in;
## every caller unfreezes it once the fade is over.
func _switch_zone(zone_id: String, entry_id: String) -> void:
	if _world:
		remove_child(_world)
		_world.queue_free()
	_zone = ZoneData.by_id(zone_id)
	if zone_id == CampLook.ZONE:
		_zone = CampLook.dressed(_zone, state.tramo())  # the land it camps by (2.4.0)
	state.zone_id = zone_id
	_quiet_s = 0.0
	_world = WORLD_SCENE.instantiate()
	_world.zone = _zone
	_world.boss_id = _boss_id()
	add_child(_world)
	move_child(_world, 0)
	_world.freeze(true)
	_world.set_audio(_audio)
	_world.encounter_triggered.connect(_on_encounter)
	_world.talk_requested.connect(_on_talk)
	_world.npc_requested.connect(_on_npc)
	_world.shop_requested.connect(_on_shop)
	_world.inn_requested.connect(_on_inn)
	_world.chest_opened.connect(_on_chest)
	_world.well_requested.connect(_on_well)
	_world.exit_requested.connect(_on_exit)
	_world.map_requested.connect(_pause.open_map)
	_world.portal_used.connect(_on_portal)
	_world.lever_pulled.connect(_on_lever)
	_world.key_taken.connect(_on_key)
	_world.door_used.connect(_on_door)
	_world.village_changed.connect(_on_village_changed)
	_world.stepped.connect(_on_stepped)
	_world.set_dry_wells(Wells.dry_ids(state))
	if entry_id != "":
		_world.place_at_entry(entry_id)
	for id in state.opened_chests:
		_world.set_chest_open(id, true, true)
	_world.set_explored(state.explored_map(zone_id))
	_world.set_world_flags(state.world_flags)
	_show_portal()
	_update_boss()
	_spawn_rare()
	_refresh_status()
	MusicLibrary.build(_zone.music)
	AmbientLibrary.prepare(_zone.ambient)  # under black, like the music
	if _world.in_village():
		_on_village_changed(true)
	if _autoplay:
		print("Zona: %s (Nv %d, %s)" % [zone_id, state.hero.level, _clock(play_time)])


func _on_encounter(boss: bool) -> void:
	if _busy:
		return
	_set_busy(true)
	_quiet_s = 0.0
	state.battles += 1
	var enemies: Array[Combatant] = []
	if boss:
		enemies.append(EnemyLibrary.data(_boss_id()))
	else:
		enemies = _world.contact_enemies()
	# Partida nueva +: stronger copies of every enemy, the boss too (a first game: as is).
	enemies = NgPlus.scaled(enemies, state.ng_plus, _zone.number)
	if not boss:
		var kept := state.give_metal_slime_hp(enemies)
		if _autoplay and kept > 0:
			print("Slime de Metal con PV %d" % kept)
	if _autoplay and state.ng_plus > 0:
		var shown := PackedStringArray()
		for enemy in enemies:
			shown.append("%s PV %d ATK %d DEF %d" % [enemy.display_name, enemy.max_hp,
				enemy.attack, enemy.defense])
		print("Partida nueva + %d (×%.1f): %s" % [state.ng_plus,
			NgPlus.stat_mult(state.ng_plus, _zone.number), ", ".join(shown)])
	_note_enemies(enemies, false)
	var echo := boss and _boss_id() == _zone.postgame_boss_id
	await _fade_to(1.0)
	_world.set_active(false)
	_audio.play_music(MusicLibrary.BOSS if boss else MusicLibrary.BATTLE)
	_audio.stop_ambient()
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, enemies, state.inventory)
	battle.set_audio(_audio)
	battle.set_equipment(state.loadout.worn(Equipment.WEAPON),
		state.loadout.worn(Equipment.SHIELD), state.loadout.worn(Equipment.HELMET))
	battle.gold_lost = state.defeat_gold_loss()
	battle.char_time = _options.char_time()
	battle.time_scale = _options.combat_scale()
	battle.camera_shake = _options.camera_shake
	state.sync_level_cap()
	battle.difficulty = state.difficulty
	battle.zone = _zone
	battle.quest_items = state.quests.wanted_items(state)
	battle.medals_carried = state.medals.size()
	battle.medal_chance = MEDAL_TOUR_CHANCE if _medal_tour else Medals.DROP_CHANCE
	if state.ally_id != "":
		battle.ally = Allies.data(state.ally_id, state.tramo())
	add_child(battle)
	await _fade_to(0.0)
	var outcome: int = await battle.finished
	# A call for help adds enemies during the fight.
	_note_enemies(battle.engine.enemies, false)
	var won := outcome == BattleEngine.State.WON
	if _autoplay and echo:
		_echo_fights += 1
		_echo_wins += 1 if won else 0
		print("Eco de la Niebla: %s (%d de %d ganados)" % ["victoria" if won else "derrota",
			_echo_wins, _echo_fights])
	if won or outcome == BattleEngine.State.LOST:
		Wells.on_battle(state)
		_world.set_dry_wells(Wells.dry_ids(state))
	await _fade_to(1.0)
	if not boss:
		# Under black: a beaten group leaves the map, one fled from stays half see-through.
		_world.end_contact(outcome)
	if state.keep_metal_slime_hp(battle.engine.enemies, outcome) > 0:
		if _autoplay:
			print("Slime de Metal: PV %d guardados" % state.metal_slime_hp)
		_autosave(false)  # a fled battle saves nothing else: quitting now must not lose them
	var notice := ""
	var reward_lines: Array[String] = []
	var scene := ""
	var mission_done := false
	var finished_quests: Array[Dictionary] = []
	var family_lines: Array[String] = []
	var ending_v2 := false
	if won:
		state.gold += battle.engine.gold_won
		state.gold_earned += battle.engine.gold_won
		var quest_was_on := state.quest.stage != Quest.Stage.DONE
		_note_enemies(battle.engine.enemies, true)
		for n in battle.engine.medals_won:
			Medals.take(state, Medals.next_missing(state))
		if _autoplay:
			for enemy in battle.engine.enemies:
				if not enemy.is_boss:
					_common_beaten += 1
			if battle.engine.medals_won > 0:
				print("Medalla: %d/%d" % [state.medals.size(), Medals.MEDALS.size()])
		for enemy in battle.engine.enemies:
			state.quest.on_victory(enemy.id)
			if enemy.is_boss:
				var first := not state.has_flag(enemy.id)
				notice = _boss_notice(enemy)
				scene = state.story.scene_after_boss(enemy.id)
				if first and enemy.reward_equipment != "":
					reward_lines.append(REWARD_LINE)
					reward_lines.append_array(QuestRewards.wear_prize(state,
						enemy.reward_equipment))
		mission_done = quest_was_on and state.quest.stage == Quest.Stage.DONE
		for enemy in battle.engine.enemies:
			finished_quests.append_array(state.quests.on_victory(state, enemy.id))
		# The enemies are noted as beaten above: a family may be complete now.
		# The v2's last boss (the first time): its ending follows. It also completes the Jefes
		# de la caravana, but no map is left to show the prize on: it comes when the game is
		# next loaded, in the Caravana (_ready() gives it).
		ending_v2 = boss and _boss_id() == StoryState.V2_FINAL_BOSS \
			and not state.story.finished_v2
		if not ending_v2:
			family_lines = _give_family_rewards()
	elif outcome == BattleEngine.State.LOST:
		if _autoplay:
			_defeats += 1
			print("Derrota en %s (%d)" % [_zone.id, _defeats])
		state.gold -= battle.gold_lost
		state.heal_full()
		_go_to_town()
		notice = "Has vuelto %s." % _to_place(_zone.village_name)
	battle.queue_free()
	_world.set_world_flags(state.world_flags)
	_update_boss()
	_refresh_status()
	_world.set_active(true)
	# Frozen until the fade is over: an exit or an encounter while Game is busy would be
	# ignored and leave the map waiting forever.
	_world.freeze(true)
	_play_map_music()
	if scene != "":
		# Under black: no status window or map square while the map fades in.
		_world.begin_cutscene()
	await _fade_to(0.0)
	if scene != "":
		# The boss's cutscene says what the notice would (the fragment, the open road).
		await _play_scene(scene)
	else:
		await _world.freeze(false)
		if not reward_lines.is_empty():
			await _world.show_dialogue("", reward_lines)
		elif notice != "":
			_world.show_notice(notice)
	if not family_lines.is_empty():
		_audio.play_sfx(SfxLibrary.LEVEL_UP)
		await _world.show_dialogue("", family_lines)
	if mission_done:
		_world.show_mission_done(QuestLog.done_text(Quest.TITLE))
	for finished: Dictionary in finished_quests:
		_world.show_mission_done(QuestLog.done_text(finished.title))
		_world.show_notice(" ".join(finished.lines))
	if ending_v2:
		await _finish_v2()
		return
	if won and state.is_finished() and not state.story.finished:
		await _finish_game()
		return
	if outcome == BattleEngine.State.LOST:
		_autosave(false)  # the gold lost sticks: going back to the title can't undo it
	if won:
		var data := _autosave(not boss and finished_quests.is_empty())  # keep its reward readable
		if _autoplay_save and _save.is_empty() and not data.is_empty():
			print("Guardado: %s" % _summary(data))
			quit_to_title.emit()
			return
	_set_busy(false)
	if _medal_tour and won and state.medals.size() >= Medals.MEDALS.size():
		await _finish_medal_tour()
		return
	if _autoplay and won and _wants_retreat():
		await _autoplay_retreat()
	elif _autoplay and won and _needs_groups():
		# No Ala de viaje (or in a village): the groups come back as if it had flown away
		# and back. Only the autoplay does this.
		print("Grupos repuestos (partida automática)")
		_respawn_groups()
	elif _autoplay and outcome == BattleEngine.State.LOST:
		await _autoplay_restock()


## Autoplay: flies back to the last village with an Ala de viaje, rests and shops there and
## comes back through the portal.
func _autoplay_retreat() -> void:
	state.inventory.take(Inventory.WING)
	print("Retirada al pueblo (PV %d/%d, PM %d, pociones %d)" % [state.hero.hp,
		state.hero.max_hp, state.hero.mp, _potion_count()])
	await _on_travel_requested()
	await _autoplay_restock()
	await _on_portal()


## Autoplay: needs rest (GameState.needs_rest()), is only kept from the zone's boss by its
## HP or MP, has a report waiting in the last village or has no group left to fight
## (_needs_groups(): the portal back brings them), away from a village, with an Ala de
## viaje (the night at the inn is free). The route may never pass the one who waits.
func _wants_retreat() -> bool:
	if _medal_tour:
		return false  # the medal tour never flies back: it hunts where it is
	var report := not state.quests.reports_here(state.town_zone, state.inventory).is_empty()
	return (state.needs_rest() or _boss_needs_rest() or report or _needs_groups()) \
		and not _world.in_village() and state.inventory.count(Inventory.WING) > 0


## Autoplay: no group left on this map while the hero still has levels to win before its
## boss (they only come back when the map is built again).
func _needs_groups() -> bool:
	return _world.group_count() == 0 and _autoplay_hunts()


## Autoplay: the hero goes after the groups while he has levels to win before the zone's
## boss or, in a Partida nueva + (he is at the top already), while the village quest wants
## its slimes (or the Rey Slime would never come out). The medal tour hunts until it carries
## every medal.
func _autoplay_hunts() -> bool:
	if _medal_tour:
		return state.medals.size() < Medals.MEDALS.size()
	return state.hero.level < _zone.autoplay_boss_level \
		or (state.ng_plus > 0 and state.quest.stage == Quest.Stage.HUNT)


## Autoplay: the zone's boss is due at this level but the hero is too worn for it. MP
## doesn't come back by walking, so without a rest the boss would never show up.
func _boss_needs_rest() -> bool:
	return _boss_wanted() and state.hero.level >= _zone.autoplay_boss_level \
		and not _rested_for_boss()


func _rested_for_boss() -> bool:
	var hero := state.hero
	return hero.hp >= hero.max_hp * AUTOPLAY_BOSS_HP \
		and hero.mp >= hero.max_mp * AUTOPLAY_BOSS_MP


## The boss of the current map: the zone's, or its postgame boss (ZoneData.postgame_boss_id)
## once the game is finished.
func _boss_id() -> String:
	if _zone.postgame_boss_id != "" and state.is_finished():
		return _zone.postgame_boss_id
	return _zone.boss_id


func _boss_wanted() -> bool:
	var boss := _boss_id()
	if boss == "":
		return false
	if boss == _zone.postgame_boss_id:
		# It can always be fought again; autoplay only meets it on --autoplay-zone=eco.
		return not _autoplay or _autoplay_echo
	return state.quest.boss_available() if boss == Quest.BOSS_ID else not state.has_flag(boss)


## The index of the figure of this kind and id (a shop's) with a quest report waiting
## (QuestLog.reports_here()), -1 if none. A shop's or an inn's.
func _figure_with_report(kind: String, id: String) -> int:
	var waiting := state.quests.reports_here(_zone.id, state.inventory)
	for i in _zone.npcs.size():
		var npc: Dictionary = _zone.npcs[i]
		if npc.kind == kind and npc.get("id", "") == id and npc.name in waiting:
			return i
	return -1


## Autoplay, in the village: a night at its inn and the shop's picks, as if the hero had
## walked up to the innkeeper and the merchant.
func _autoplay_restock() -> void:
	for npc: Dictionary in _zone.npcs:
		if npc.kind == "inn":
			await _on_inn(npc.id)
	for npc: Dictionary in _zone.npcs:
		if npc.kind == "shop":
			await _on_shop(npc.id)
	# On a caravan game the figures that offer a quest ("!") are visited too, or autoplay
	# would never take the v2's quests; a v1 game keeps the reports only.
	var marks := {}
	if state.in_caravan():
		marks = state.quests.markers(_zone.id, state.inventory, state.world_flags)
	for i in _zone.npcs.size():
		var npc_name: String = _zone.npcs[i].name
		if npc_name in state.quests.reports_here(_zone.id, state.inventory) \
				or marks.get(npc_name, "") == QuestLog.NEW_MARK:
			await _on_npc(i)


## Notes enemies in the bestiary: seen, or beaten too after a won battle. Only those with a
## card (Bestiary.has()): the Eco de la Niebla never counts.
func _note_enemies(enemies: Array[Combatant], beaten: bool) -> void:
	for enemy in enemies:
		if not Bestiary.has(enemy.id):
			continue
		if beaten:
			state.defeat_enemy(enemy.id)
		else:
			state.see_enemy(enemy.id)


## Gives the prize of every bestiary family completed and not paid yet (Bestiary): its
## flag and its piece. Returns the lines that say so, for the dialogue window.
func _give_family_rewards() -> Array[String]:
	var lines: Array[String] = []
	for family_id in Bestiary.new_rewards(state):
		lines.append(Bestiary.give(state, family_id))
	return lines


## Sets the boss's world flag, gives its key item and says so.
func _boss_notice(boss: Combatant) -> String:
	var key_item := state.on_boss_defeated(boss)
	if BOSS_NOTICES.has(boss.id):
		return BOSS_NOTICES[boss.id]
	if key_item != "":
		return KEY_ITEM_NOTICE % Inventory.KEY_ITEMS[key_item]
	return ""


## Puts the player at the town entry of the last village visited, switching zones if
## needed (no fade: the caller is already under black). The groups of the map come back
## either way.
func _go_to_town() -> void:
	var town := ZoneData.by_id(state.town_zone)
	if state.town_zone != state.zone_id:
		_switch_zone(state.town_zone, town.town_entry)
	else:
		_world.place_at_entry(town.town_entry)
		_respawn_groups()
		_on_village_changed(_world.in_village())


## Every group of this map comes back (the map counts as built again: a defeat, the portal,
## a game loaded), clear of where the hero stands.
func _respawn_groups() -> void:
	var avoid: Array[Vector3] = [_world.player_position()]
	_world.respawn_groups(avoid)
	_spawn_rare()


## The zone's rare enemy on this map (the Slime de Metal on the mine floors): always while
## its quest is on, now and then once it is done (EncounterTable.rare_on_map()).
func _spawn_rare() -> void:
	if _zone.rare_enemy == "" or _world.has_rare():
		return
	if EncounterTable.rare_on_map(_zone, state.quests.wanted_enemies(),
			state.quests.hunted_enemies(), _rng):
		_world.add_rare(_zone.rare_enemy)


## An open exit: fades to black, builds the next zone at the exit's entry, autosaves.
func _on_exit(zone_id: String, entry_id: String) -> void:
	if _busy:
		return
	_set_busy(true)
	await _fade_to(1.0)
	_switch_zone(zone_id, entry_id)
	_play_map_music()
	await _fade_to(0.0)
	await _world.freeze(false)
	await _check_arrival_line()
	_autosave(false)
	_set_busy(false)
	_check_village_scene()


## The Ala de viaje, used from the pause menu (it has already taken it): to the last
## village visited, with the portal back to this spot open there. The menu only opens when
## nothing is going on, so the spot is always a settled one.
func _on_travel_requested() -> void:
	if _busy:
		state.inventory.add(Inventory.WING)
		return
	_set_busy(true)
	# The pause menu has already unpaused the tree: without this the hero could still walk
	# into an encounter or an exit during the fade and leave the map stuck waiting.
	_world.freeze(true)
	var replaced := state.open_portal(_world.player_position())
	await _fade_to(1.0)
	_go_to_town()
	_show_portal()
	_refresh_status()
	_play_map_music()
	await _fade_to(0.0)
	await _world.freeze(false)
	var place := _to_place(_zone.village_name)
	_world.show_notice((PORTAL_REPLACED_NOTICE if replaced else PORTAL_OPEN_NOTICE) % place)
	_autosave(false)
	_set_busy(false)


## The hero used the return portal (or autoplay, once restocked): back to the spot the Ala
## was used at. It works once. The map stays frozen through the fade, like every other trip.
func _on_portal() -> void:
	if _busy or not state.has_portal():
		return
	_set_busy(true)
	_quiet_s = 0.0
	_world.freeze(true)
	await _fade_to(1.0)
	var zone_id := state.portal_zone
	var pos := state.portal_pos
	state.close_portal()
	if zone_id != _zone.id:
		_switch_zone(zone_id, "")
	else:
		_show_portal()
	_world.place_player(pos)
	_respawn_groups()
	_on_village_changed(_world.in_village())
	_refresh_status()
	_update_boss()
	await _fade_to(0.0)
	await _world.freeze(false)
	_world.show_notice(PORTAL_BACK_NOTICE)
	_autosave(false)
	_set_busy(false)


## The portal stands in the village it was opened in and the mark on the spot it leads
## back to, whatever map is on now.
func _show_portal() -> void:
	_world.set_portal(state.portal_town == _zone.id)
	_world.set_return_mark(state.has_portal() and state.portal_zone == _zone.id,
		state.portal_pos)


## Inside a village it becomes the last one visited; the music follows. The first
## visit plays the village's cutscene.
func _on_village_changed(inside: bool) -> void:
	if inside and _zone.town_entry != "":
		state.town_zone = _zone.id
	_play_map_music()
	if inside:
		_check_village_scene()


## The companion's line the first time the hero reaches a land of the caravan
## (Allies.ARRIVALS), once the place's name is up; remembered with its llegada_<zone> flag.
## Nothing without a companion. The caller is busy.
func _check_arrival_line() -> void:
	var line := Allies.arrival_line(state.ally_id, _zone.id)
	var flag := Allies.arrival_flag(_zone.id)
	if line == "" or state.has_flag(flag):
		return
	state.world_flags[flag] = true
	_world.freeze(true)
	await get_tree().create_timer(World.BANNER_FADE).timeout
	if _autoplay:
		print("Compañero: %s" % line)
	await _world.show_dialogue(Allies.display_name(state.ally_id), [line])


## Plays the cutscene of this zone's village if the hero is inside it and has not seen
## it yet (only when nothing else is going on); autosaves after it.
func _check_village_scene() -> void:
	if _busy or not _world.in_village():
		return
	var scene := state.story.scene_on_village(_zone.id)
	if scene == "" and _zone.id == "pradera" and state.can_meet_caravan() \
			and not state.story.has_seen("caravana_llega"):
		scene = "caravana_llega"
	if scene == "":
		return
	_set_busy(true)
	await _play_scene(scene)
	if scene == "caravana_campamento":
		await _choose_companion()
	_autosave(false)
	_set_busy(false)


## Plays data/cutscenes/<scene_id>.tres on the current map and marks it seen. The
## caller is busy; the map is the player's again when it returns.
func _play_scene(scene_id: String) -> void:
	var scene := load(CUTSCENE_PATH % scene_id) as Cutscene
	state.story.mark_seen(scene_id)
	_cutscenes.world = _world
	_cutscenes.hero_name = state.hero.display_name
	_cutscenes.companion_name = Allies.display_name(state.ally_id) if state.ally_id != "" else ""
	await _cutscenes.play(scene)
	_audio.play_ambient(_zone.ambient)  # a "music" step silenced it
	_refresh_status()


## A new game: the prologue (it fades in from black), then the slimes quest is on. A
## save that could not be read also lands here, and says so now the map is visible.
func _play_prologue() -> void:
	await _play_scene("prologo")
	state.quest.start()
	_refresh_status()
	_autosave(false)
	_set_busy(false)
	_show_touch_hint()
	if _load_failed:
		_world.show_notice(LOAD_FAILED_NOTICE)


## After the ending: the save is marked finished (the hero is back in Villaclaro), the
## credits roll with the numbers of the game and Game goes back to the title. They cover
## everything, and Game stays busy, so no status window, map square, ☰ or prompt shows.
func _finish_game() -> void:
	state.story.finished = true
	_world.freeze(true)
	_autosave(false)
	var time_text := _clock(play_time)
	_audio.play_music(MusicLibrary.TITLE)
	_audio.stop_ambient()
	var layer := CanvasLayer.new()
	layer.layer = 11
	add_child(layer)
	var credits := CreditsScreen.new()
	layer.add_child(credits)
	await _fade_to(0.0)
	await credits.run(_credits_sections(time_text))
	if _autoplay:
		print("Juego completado: Nv %d, tiempo de juego %s, misiones %d" % [state.hero.level,
			time_text, state.quests_done()])
		print("Familias completas: %d/%d" % [Bestiary.complete_count(state),
			Bestiary.families(state).size()])
		print("Derrotas: %d" % _defeats)
		print("Medallas: %d/%d (enemigos comunes vencidos: %d)" % [state.medals.size(),
			Medals.MEDALS.size(), _common_beaten])
	quit_to_title.emit()


## After the v2's ending (the cruce scene ends under black): the game is finished in the v2
## and saved in the Caravana, which can still be walked; then the screen beyond the portal,
## the v2's credits and "Continuará", and Game goes back to the title. Game stays busy, so no
## window, ☰ or prompt shows over them.
func _finish_v2() -> void:
	MusicLibrary.build(MusicLibrary.BEYOND)  # under black
	state.story.finished_v2 = true
	_switch_zone("caravana", "")
	_world.freeze(true)
	_autosave(false)
	var numbers := _v2_numbers()
	_world.set_active(false)
	_audio.stop_ambient()
	_audio.play_music(MusicLibrary.BEYOND)
	var beyond := BeyondScreen.new()
	beyond.setup(state.loadout.worn(Equipment.WEAPON), state.loadout.worn(Equipment.SHIELD),
		state.loadout.worn(Equipment.HELMET), state.ally_id)
	add_child(beyond)
	await _fade_to(0.0)
	await beyond.run()
	await _fade_to(1.0)
	beyond.queue_free()
	var layer := CanvasLayer.new()
	layer.layer = 11
	add_child(layer)
	var credits := CreditsScreen.new()
	credits.end_text = CreditsScreen.TO_BE_CONTINUED
	layer.add_child(credits)
	await _fade_to(0.0)
	await credits.run(_v2_credits_sections(numbers))
	if _autoplay:
		print("Juego completado (v2): Nv %d, tiempo en la caravana %s, tiempo de juego %s, misiones de la caravana %d/%d"
			% [state.hero.level, numbers.time, _clock(play_time), state.quests.done_of(true),
			QuestLog.total_of(true)])
		print("Familias completas: %d/%d" % [Bestiary.complete_count(state),
			Bestiary.families(state).size()])
		print("Derrotas: %d" % _defeats)
		print("Medallas: %d/%d (enemigos comunes vencidos: %d)" % [state.medals.size(),
			Medals.MEDALS.size(), _common_beaten])
	quit_to_title.emit()


## The v2's time and battles: since the hero left with the caravan (story.v2_start), or the
## whole game's for a save that was already in the caravan before 2.3.0 ("since" false).
func _v2_numbers() -> Dictionary:
	var start: Array = state.story.v2_start
	var since := not start.is_empty()
	return {
		"time": _clock(play_time - (float(start[0]) if since else 0.0)),
		"battles": state.battles - (int(start[1]) if since else 0),
		"since": since,
	}


## The v2's credits: the caravan's story, this journey's numbers, who made the game.
func _v2_credits_sections(numbers: Dictionary) -> Array:
	var journey: Array[String] = []
	if state.ally_id != "":
		journey.append("Compañero: %s" % Allies.display_name(state.ally_id))
	journey.append(("Tiempo en la caravana: %s" if numbers.since else "Tiempo de juego: %s")
		% numbers.time)
	journey.append(("Combates en la caravana: %d" if numbers.since else "Combates: %d")
		% numbers.battles)
	journey.append("Misiones de la caravana: %d/%d" % [state.quests.done_of(true),
		QuestLog.total_of(true)])
	journey.append("Nivel: %d" % state.hero.level)
	return [
		["La caravana del portal", ["La historia de %s" % state.hero.display_name]],
		["Tu viaje", journey],
		["Creado por", [AUTHOR]],
		["Motor", ["Godot Engine 4.7"]],
		["Modelos 3D", ["KayKit, de Kay Lousberg (CC0)", "Nature Kit, de Kenney (CC0)"]],
		["Música y sonido", ["Generados por el propio juego"]],
		["Gracias por jugar", []],
	]


## The credits: who made the game, with what, and the numbers of this game (and its round,
## in a Partida nueva +).
func _credits_sections(time_text: String) -> Array:
	var numbers: Array[String] = [
		"Tiempo de juego: %s" % time_text,
		"Combates: %d" % state.battles,
		"Pasos: %d" % state.steps,
		"Oro ganado: %d G" % state.gold_earned,
		"Misiones cumplidas: %d" % state.quests_done(),
		"Nivel: %d" % state.hero.level,
	]
	if state.ng_plus > 0:
		numbers.append("Partida nueva + %d" % state.ng_plus)
	return [
		["Villaclaro", ["La historia de %s" % state.hero.display_name]],
		["Creado por", [AUTHOR]],
		["Motor", ["Godot Engine 4.7"]],
		["Modelos 3D", ["KayKit, de Kay Lousberg (CC0)"]],
		["Música y sonido", ["Generados por el propio juego"]],
		["Tu partida", numbers],
		["Gracias por jugar", []],
	]


## What CutscenePlayer's "travel" step does: builds zone_id at entry_id under black and
## hands the new map over.
func _scene_travel(zone_id: String, entry_id: String) -> World:
	_switch_zone(zone_id, entry_id)
	return _world


## What CutscenePlayer's "flag" step does.
func _scene_flag(flag: String) -> void:
	state.world_flags[flag] = true
	_world.set_world_flags(state.world_flags)
	_refresh_status()  # a figure may come with the flag (the Jefe de caravana)


## The old woman always heals; what she says and gives comes from the quest.
func _on_talk() -> void:
	if _busy:
		return
	_set_busy(true)
	var done := state.quest.stage == Quest.Stage.DONE
	var result := state.quest.talk()
	var said: Array = result.lines
	if done:
		# Her quest over, the Abuela Rosa speaks of the story (her ZoneData lines).
		var story_lines := _world.npc_lines(_quest_npc(), state.chapter())
		if not story_lines.is_empty():
			said = story_lines
	var lines: Array[String] = []
	for line: String in said:
		lines.append(StoryState.fill(line, state.hero.display_name))
	lines.append(HEAL_LINE)
	state.heal_full()
	if result.potions > 0:
		state.inventory.add(Inventory.POTION, result.potions)
	_refresh_status()
	await _world.show_dialogue(Quest.NPC_NAME, lines)
	_update_boss()
	_autosave(true)
	_set_busy(false)


## The index of the zone's "quest" figure (the Abuela Rosa) in ZoneData.npcs.
func _quest_npc() -> int:
	for i in _zone.npcs.size():
		if _zone.npcs[i].kind == "quest":
			return i
	return -1


## A villager or a board: what it has about a quest (the log moves the quest on and pays),
## or else its lines (World.npc_lines(): they change with the chapter).
func _on_npc(index: int) -> void:
	if _busy:
		return
	_set_busy(true)
	var figure: String = _zone.npcs[index].name
	if figure == Medals.COLLECTOR:
		await _talk_to_collector()
		_set_busy(false)
		return
	if figure == CARAVAN_CHIEF and _zone.id == "caravana" \
			and not state.has_flag(StoryState.COMPANION_FLAG):
		await _choose_companion()
		_set_busy(false)
		return
	if figure == CARAVAN_CHIEF and _zone.id == "pradera":
		await _ask_departure()
		_set_busy(false)
		_check_village_scene()  # the Caravana's first visit, if the hero left
		return
	var chief := figure == CARAVAN_CHIEF
	var talk := state.quests.talk(state, _zone.id, figure, chief)
	var said: Array = talk.get("lines", _world.npc_lines(index, state.chapter()))
	if chief and talk.get("kind", "") == QuestLog.TALK_WAIT:
		# The Jefe with quests under way and nothing to deliver: his chapter lines first (the
		# way on, his joke), then one waiting line.
		said = _world.npc_lines(index, state.chapter()) + talk.lines
	var lines: Array[String] = []
	for line: String in said:
		lines.append(StoryState.fill(line, state.hero.display_name))
	# A thing picked up (kind "item", the cantimplora) has no voice: the narrator says it.
	var speaker := "" if _zone.npcs[index].kind == "item" else figure
	await _world.show_dialogue(speaker, lines)
	if not talk.is_empty():
		var done: Array[String] = []
		done.assign(talk.done)
		_after_quest_talk(done)
	_set_busy(false)


## The Jefe de caravana in Villaclaro: two questions (focus on the answer that changes
## nothing), then the farewell, the v1 left behind and the Caravana built under black.
func _ask_departure() -> void:
	if _autoplay and not _autoplay_v2:
		return  # the v1 runs never leave with the caravan
	if await _world.ask(JOIN_QUESTION, ["Sí", "No"], 1) != 0:
		return
	if await _world.ask(LEAVE_QUESTION, ["Partir", "Aún no"], 1) != 0:
		return
	await _play_scene("caravana_parte")  # ends under black
	state.leave_for_caravan()
	state.story.v2_start = [play_time, state.battles]  # the v2's credits count from here
	_switch_zone("caravana", "")
	_play_map_music()
	await _fade_to(0.0)
	await _world.freeze(false)
	_autosave(false)


## The Jefe de caravana's choice of companion: the Compañeros list (a shop at no cost).
## Closing it without choosing leaves it for the next talk; once one is chosen, the jungle's
## exit is there. Autoplay takes --autoplay-companion=<id> (Brena if none) at once.
func _choose_companion() -> void:
	if _autoplay:
		state.ally_id = _autoplay_companion
		print("Compañero: %s" % Allies.display_name(state.ally_id))
	else:
		_world.freeze(true)
		await _shop.run(Shop.COMPANIONS_SHOP)
		await _world.freeze(false)
	if not Allies.is_companion(state.ally_id):
		await _world.show_dialogue(CARAVAN_CHIEF, ["Piénsalo bien. Te espero aquí, que yo no tengo prisa."])
		return
	state.world_flags[StoryState.COMPANION_FLAG] = true
	_world.set_world_flags(state.world_flags)
	_refresh_status()
	var who := Allies.display_name(state.ally_id)
	await _world.show_dialogue(CARAVAN_CHIEF, ["%s irá contigo. La jungla está al norte." % who])
	_autosave(false)


## The Coleccionista (Medals.talk()): every prize the medals reach, at once, with a sound;
## then how many are carried. Saves silently (he has met the hero, maybe given something).
func _talk_to_collector() -> void:
	var talk := Medals.talk(state, _zone.id)
	var lines: Array[String] = []
	for line: String in talk.lines:
		lines.append(StoryState.fill(line, state.hero.display_name))
	if talk.given > 0:
		_audio.play_sfx(SfxLibrary.LEVEL_UP)
		_refresh_status()
	await _world.show_dialogue(Medals.COLLECTOR, lines)
	_autosave(false)


## The map shows what changed (a done_flag brings a figure back: Nara, the Superviviente);
## the quests finished say so with one notice and one sound; the game is saved.
func _after_quest_talk(done: Array[String]) -> void:
	if _zone.rare_enemy in state.quests.wanted_enemies():
		_spawn_rare()  # its hunt was just taken: it is on this floor at once
	if _autoplay:
		for id in Inventory.SEEDS:
			while state.inventory.count(id) > 0:
				state.use_item(id)
	_world.set_world_flags(state.world_flags)
	_refresh_status()
	if not done.is_empty():
		_audio.play_sfx(SfxLibrary.LEVEL_UP)
		_world.show_mission_done(_done_text(done))
	_autosave(done.is_empty())


## "Misión cumplida: <title>"; with several, all their titles on a desktop and how many on a
## phone (its status window has one line of 300 px).
func _done_text(done: Array[String]) -> String:
	if done.size() == 1:
		return QuestLog.done_text(done[0])
	if Device.is_touch():
		return QuestLog.done_count_text(done.size())
	return QuestLog.done_text(" · ".join(done))


## The merchant: the ShopWindow until the player leaves; autosaves if anything changed.
## On autoplay it only opens when there is something to buy.
func _on_shop(shop_id: String) -> void:
	if _busy:
		return
	var waiting := _figure_with_report("shop", shop_id)
	if waiting >= 0:
		await _on_npc(waiting)  # a report waiting at the merchant goes first (pieles_mono)
	if shop_id == Shop.CARAVAN_SHOP:
		shop_id = Shop.caravan_shop(state.tramo())
	if _busy or (_autoplay and Shop.autoplay_picks(state, shop_id).is_empty()):
		return
	_set_busy(true)
	_shop_changed = false
	_world.freeze(true)
	await _shop.run(shop_id)
	await _world.freeze(false)
	_refresh_status()
	if _shop_changed:
		_autosave(true)
	_set_busy(false)


## The innkeeper speaks; if HP or MP are missing, the hero rests at once (fade to black and
## back with HP and MP full, free) and the game saves, with no question asked. Full HP and
## MP: the keeper just remarks on it. On autoplay it only stops there below
## AUTOPLAY_INN_RATIO of max HP or MP, on GameState.needs_rest() or below the boss's
## thresholds (or a retreat for the boss would come back unhealed).
func _on_inn(inn_id: String) -> void:
	if _busy:
		return
	var waiting := _figure_with_report("inn", inn_id)
	if waiting >= 0:
		await _on_npc(waiting)  # a report waiting at the keeper goes first, as at a shop
	var hurt := state.hero.hp < state.hero.max_hp * AUTOPLAY_INN_RATIO \
		or state.hero.mp < state.hero.max_mp * AUTOPLAY_INN_RATIO or state.needs_rest() \
		or not _rested_for_boss()
	if _busy or (_autoplay and not hurt):
		return
	_set_busy(true)
	var keeper := Inn.keeper(inn_id)
	var lines: Array[String] = [Inn.full_line(inn_id) if Inn.is_rested(state)
		else Inn.rest_line(inn_id)]
	await _world.show_dialogue(keeper, lines)
	if Inn.is_rested(state):
		_set_busy(false)
		return
	_world.freeze(true)
	Inn.stay(state)
	await _fade_to(1.0)
	_respawn_groups()
	_refresh_status()
	_audio.play_sfx(SfxLibrary.HEAL)
	await get_tree().create_timer(INN_NIGHT_TIME).timeout
	await _fade_to(0.0)
	await _world.freeze(false)
	_refresh_status()
	_update_boss()
	_autosave(true)
	_set_busy(false)


## The hero used a well: drinks if it is full and the hero is not. On autoplay only a full
## well and a hero in need.
func _on_well(id: String, kind: String) -> void:
	if _busy or (_autoplay and (Wells.is_dry(state, id) or Inn.is_rested(state))):
		return
	_set_busy(true)
	var was_dry := Wells.is_dry(state, id)
	var text := Wells.drink(state, id, kind)
	if not was_dry and Wells.is_dry(state, id):
		_audio.play_sfx(SfxLibrary.HEAL)
		_refresh_status()
		_world.set_dry_wells(Wells.dry_ids(state))
		_autosave(false)
	var lines: Array[String] = [text]
	await _world.show_dialogue("", lines)
	_set_busy(false)


## A closed chest: gives what it holds, opens the lid, saves without a notice and says what
## was found in the dialogue window, which waits for Enter or a tap (on autoplay it goes on
## by itself).
func _on_chest(chest_id: String) -> void:
	if _busy:
		return
	var result := Chests.open(state, chest_id)
	if not result.opened:
		return
	_set_busy(true)
	state.gold_earned += Chests.CHESTS[chest_id].get("gold", 0)
	_world.set_chest_open(chest_id, true)
	_audio.play_sfx(SfxLibrary.LEVEL_UP)
	_refresh_status()
	_autosave(false)
	var lines: Array[String] = [result.text]
	await _world.show_dialogue("", lines)
	_set_busy(false)


## --autoplay-zone=medallas: the time is up with medals still missing; it ends anyway.
func _on_medal_tour_timeout() -> void:
	if not _medal_tour:
		return
	while _busy:
		await get_tree().create_timer(1.0).timeout
	if not _medal_tour:  # the tour finished by itself while this waited
		return
	print("Medallas: tiempo agotado (%d/%d)" % [state.medals.size(), Medals.MEDALS.size()])
	await _finish_medal_tour()


## --autoplay-zone=medallas: under black to Villaclaro, the Coleccionista; then the forest
## village's (his joke); the counts printed and back to the title (which quits on autoplay).
func _finish_medal_tour() -> void:
	_medal_tour = false
	_set_busy(true)
	for zone_id in [Medals.COLLECTOR_ZONE, "bosque"]:
		await _fade_to(1.0)
		var town := ZoneData.by_id(zone_id)
		_switch_zone(town.id, town.town_entry)
		_play_map_music()
		await _fade_to(0.0)
		await _world.freeze(false)
		await _talk_to_collector()
	print("Medallas: %d/%d · premios %d/%d" % [state.medals.size(), Medals.MEDALS.size(),
		state.medal_prizes, Medals.PRIZES.size()])
	quit_to_title.emit()


## The dungeon floor's lever: sets its flag, which opens the gates it works.
func _on_lever() -> void:
	if _busy or _zone.lever_flag == "":
		return
	state.world_flags[_zone.lever_flag] = true
	_world.pull_lever()
	_audio.play_sfx(SfxLibrary.DOOR)
	_world.set_world_flags(state.world_flags)
	_world.show_notice(LEVER_NOTICE)
	_autosave(false)
	_refresh_status()


## The key lying on the floor: into the key items; its flag keeps it taken.
func _on_key() -> void:
	if _busy or _zone.floor_key == "":
		return
	state.world_flags[_zone.floor_key] = true
	state.key_items.append(_zone.floor_key)
	_audio.play_sfx(SfxLibrary.LEVEL_UP)
	_world.set_world_flags(state.world_flags)
	_world.show_notice(KEY_NOTICE % Inventory.KEY_ITEMS[_zone.floor_key])
	_autosave(false)
	_refresh_status()


## A closed gate: the key of the floor opens it (and is used up); otherwise its text.
func _on_door() -> void:
	if _busy:
		return
	var key := _zone.door_key
	if key == "" or not key in state.key_items:
		_world.show_notice(_zone.door_text)
		return
	state.key_items.erase(key)
	state.world_flags[_zone.door_flag] = true
	_audio.play_sfx(SfxLibrary.DOOR)
	_world.set_world_flags(state.world_flags)
	_world.show_notice(DOOR_NOTICE % Inventory.KEY_ITEMS[key])
	_autosave(false)
	_refresh_status()


## Writes the save file; shows SAVED_NOTICE if notice. Returns the saved data, or an
## empty Dictionary if the file could not be written.
func _autosave(notice: bool) -> Dictionary:
	var data := SaveData.from_state(state, _world.player_position(), play_time)
	if not SaveStore.save_game(_slot, data):
		return {}
	if notice:
		_audio.play_sfx(SfxLibrary.SAVE)
		_world.show_notice(SAVED_NOTICE)
	return data


func _on_save_requested() -> void:
	var data := SaveData.from_state(state, _world.player_position(), play_time)
	_pause.show_save_result(SaveStore.save_game(_slot, data))


## The tree stays paused (TitleScreen unpauses when it frees this game), so the map can't
## walk or roll an encounter during the fade; the menu is shut and deaf meanwhile.
func _on_title_requested() -> void:
	if _leaving:
		return
	_leaving = true
	_set_busy(true)
	_pause.hide()
	_pause.set_process_unhandled_input(false)
	quit_to_title.emit()


## The zone's boss is on the map until beaten: the Rey Slime only while the quest asks
## for it; on autoplay only from the zone's autoplay_boss_level on, and only while the
## hero has AUTOPLAY_BOSS_HP of his max HP and AUTOPLAY_BOSS_MP of his max MP (a worn-out
## hero fights on, or rests, first).
func _update_boss() -> void:
	if _boss_id() == "":
		return
	var strong_enough := not _autoplay or (state.hero.level >= _zone.autoplay_boss_level \
		and _rested_for_boss())
	_world.set_boss_present(_boss_wanted() and strong_enough)


## The zone's map music, or its village one inside the village, and the zone's ambient
## under it (after a battle or a cutscene that silenced it, it comes back here).
func _play_map_music() -> void:
	_audio.play_music(_zone.village_music if _world.in_village() else _zone.music)
	_audio.play_ambient(_zone.ambient)


## The pause menu (and, with --debug, the debug panel) only opens on the map with nothing
## else going on.
func _set_busy(busy: bool) -> void:
	_busy = busy
	_pause.available = not busy and not _autoplay
	if _debug:
		_debug.available = not busy


## Updates the map's status window, the quests' marks and sought figures and the hero's
## weapon and shield; on autoplay also prints each new quest line and each change of gold
## or equipment.
## Every STEP_DISTANCE metres walked: two steps for the credits, and the Incienso burns.
func _on_stepped() -> void:
	state.steps += 2
	if state.repel_m <= 0.0:
		return
	state.repel_m = maxf(0.0, state.repel_m - World.STEP_DISTANCE)
	if state.repel_m == 0.0:
		_world.set_repel(false)
		_world.show_notice(REPEL_END_NOTICE)


## The healing potions carried, big ones too: the map's counter and the retreat line.
func _potion_count() -> int:
	return state.inventory.count(Inventory.POTION) + state.inventory.count(Inventory.BIG_POTION)


func _refresh_status() -> void:
	state.sync_level_cap()
	var missions := state.current_missions()
	_world.refresh_status(state.hero, _potion_count(), state.gold,
		missions)
	_world.set_monsters_shy(EncounterMeter.is_shy(state.hero.level, _zone.exit_level))
	_world.set_repel(state.repel_m > 0.0)
	_world.set_autoplay_hunt(_autoplay and _autoplay_hunts())
	var hidden := state.quests.hidden_figures(_zone.id)
	hidden.append_array(_zone.absent_figures(state.world_flags))
	# The companions not chosen never show (the figures of the cruce scene in ciudad_2).
	for id in Allies.COMPANIONS:
		if id != state.ally_id:
			hidden.append(Allies.display_name(id))
	_world.set_quest_view(state.quests.markers(_zone.id, state.inventory, state.world_flags),
		hidden)
	var loadout := state.loadout
	_world.set_hero_equipment(loadout.worn(Equipment.WEAPON), loadout.worn(Equipment.SHIELD),
		loadout.worn(Equipment.HELMET))
	if _autoplay and missions != _last_missions:
		print(" · ".join(missions))
	_last_missions = missions
	var worn := PackedStringArray()
	for slot in Equipment.SLOTS:
		if loadout.worn(slot) != "":
			worn.append(Equipment.display_name(loadout.worn(slot)))
	var gear_text := "Oro %d G · Equipo: %s · ATK %d DEF %d VEL %d" % [state.gold,
		", ".join(worn), state.hero.total_attack(), state.hero.total_defense(),
		state.hero.total_speed()]
	if _autoplay and gear_text != _last_gear_text:
		print(gear_text)
	_last_gear_text = gear_text


## "a Villaclaro", "a la aldea del bosque", "al refugio de la mina".
static func _to_place(place: String) -> String:
	return "al " + place.substr(3) if place.begins_with("el ") else "a " + place


## Seconds as "h:mm:ss".
static func _clock(seconds: float) -> String:
	return "%d:%02d:%02d" % [floori(seconds / 3600.0), floori(seconds / 60.0) % 60,
		floori(seconds) % 60]


## One line with every saved value, keys sorted, for --autoplay-save.
static func _summary(data: Dictionary) -> String:
	return JSON.stringify(data, "", true)


func _build_shop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	_shop = ShopWindow.new()
	_shop.setup(state, _audio)
	layer.add_child(_shop)
	_shop.changed.connect(func() -> void:
		_shop_changed = true
		_refresh_status())


func _build_cutscenes() -> void:
	_cutscenes = CutscenePlayer.new()
	_cutscenes.audio = _audio
	_cutscenes.fade = _fade_to
	_cutscenes.set_flag = _scene_flag
	_cutscenes.travel = _scene_travel
	add_child(_cutscenes)


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
	_pause.travel_requested.connect(_on_travel_requested)
	_pause.in_village = func() -> bool: return _world.in_village()
	_pause.hero_position = func() -> Vector3: return _world.player_position()
	_pause.state_changed.connect(_refresh_status)
	_pause.open_changed.connect(func(is_open: bool) -> void:
		_world.set_status_shown(not is_open))
	_pause.available = not _autoplay


## --debug: the panel over the pause menu, under the fade. While it is open Game is busy (no
## ☰, no pause) and the status window and map square hide, as with the pause menu.
func _build_debug() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	_debug = DebugPanel.new()
	_debug.setup(state)
	layer.add_child(_debug)
	_debug.action_chosen.connect(_on_debug)
	_debug.open_changed.connect(func(is_open: bool) -> void:
		_set_busy(is_open)
		_world.set_status_shown(not is_open))


## What a DebugPanel button asks: done at once on the state and the map, printed as
## "Depuración: ..." and said on the panel. Ir a goes on under black (_debug_go()).
func _on_debug(action: String, arg: String) -> void:
	var text := ""
	match action:
		DebugPanel.ZONE:
			_debug_go(arg)
			return
		DebugPanel.LEVEL:
			Leveling.set_level(state.hero, state.hero.level + int(arg), HERO_DATA.skills)
			var spells := PackedStringArray()
			for skill in state.hero.skills:
				spells.append(skill.display_name)
			text = "nivel %d (PV %d/%d, PM %d/%d, EXP %d; hechizos: %s)" % [state.hero.level,
				state.hero.hp, state.hero.max_hp, state.hero.mp, state.hero.max_mp,
				state.hero.experience, ", ".join(spells)]
		DebugPanel.GOLD:
			state.gold += int(arg)
			text = "+%s G (%d G)" % [arg, state.gold]
		DebugPanel.ITEMS:
			for id in Inventory.IDS:
				state.inventory.add(id)
			text = "+1 de cada objeto (%d objetos)" % Inventory.IDS.size()
		DebugPanel.HEAL:
			state.heal_full()
			text = "PV y PM llenos"
		DebugPanel.MONSTERS:
			World.debug_no_groups = not World.debug_no_groups
			if World.debug_no_groups:
				_world.clear_groups()
				text = "grupos quitados (quedan %d)" % _world.group_count()
			else:
				_respawn_groups()
				text = "grupos puestos (%d)" % _world.group_count()
		DebugPanel.BOSS:
			var boss := EnemyLibrary.data(arg)
			var item := state.on_boss_defeated(boss)
			if arg == Quest.BOSS_ID:
				state.quest.stage = Quest.Stage.DONE  # as its real victory does
			if Bestiary.has(arg):
				# As --autoplay-zone does: beaten in the bestiary too, and a family may be complete.
				state.see_enemy(arg)
				state.defeat_enemy(arg)
			state.story.mark_seen_for_flags(state.world_flags)
			_world.set_world_flags(state.world_flags)
			text = "%s %s" % [boss.display_name, "vencida" if boss.female else "vencido"]
			if item != "":
				text += " (+%s)" % Inventory.KEY_ITEMS[item]
			for line in _give_family_rewards():
				text += " · " + line
		DebugPanel.QUEST:
			state.quest.skip_stage()
			text = "misión de la aldea: %s" % DebugPanel.STAGE_NAMES[state.quest.stage]
		DebugPanel.SAVE:
			var data := SaveData.from_state(state, _world.player_position(), play_time)
			text = "guardado en la ranura %d" % _slot if SaveStore.save_game(_slot, data) \
				else "no se pudo guardar"
	_update_boss()
	_refresh_status()
	print("Depuración: %s" % text)
	_debug.show_result(text)


## DebugPanel's Ir a (the panel is already shut): under black to zone_id's start entry, as
## through an exit, with no autosave.
func _debug_go(zone_id: String) -> void:
	if _busy:
		return
	_set_busy(true)
	_world.freeze(true)
	await _fade_to(1.0)
	_switch_zone(zone_id, "")
	_play_map_music()
	await _fade_to(0.0)
	await _world.freeze(false)
	print("Depuración: a %s" % _zone.map_label())
	_set_busy(false)
	_check_village_scene()


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
