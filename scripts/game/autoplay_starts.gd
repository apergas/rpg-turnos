class_name AutoplayStarts extends RefCounted
## Rule (data): the starts of --autoplay-zone=<id> (AUTOPLAY_ZONES, ECHO_START, MEDAL_TOUR,
## V2_STARTS), the thresholds the self-playing run plays by (when it stops at an inn, when
## the boss may come out, when a quiet map gets its groups back) and the companion of
## --autoplay-companion=<id>. GameAutoplay plays them; nothing here touches nodes.

## The companion autoplay chooses at the Caravana when --autoplay-companion names none.
const DEFAULT_COMPANION := "brena"
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
	# --autoplay-zone=brumaclara: the v2 finished: Lv 40 with the stellar gear and Brena, in the
	# Caravana by the calmed portal. It buys the bruma gear from the Mercader, crosses the portal
	# and plays the v3 as far as it goes.
	"brumaclara": {
		"zone": "caravana",
		"experience": 24100,
		"gold": 7200,
		"gear": ["espada_estelar", "armadura_estelar", "escudo_estelar", "casco_estelar"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero",
			"jaguar_sombrio", "gusano_dunas", "montana_palanca", "grifo_cumbre",
			"guardian_ciudad", "ciudad_reja", "devorador_portal", "portal_calmo"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo",
			"insignia_jungla", "sello_desierto", "mapa_montana"],
		"quest_done": true,
		"town": "caravana",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 5, Inventory.BIG_ETHER: 4, Inventory.WING: 3,
			Inventory.PHOENIX: 1},
		"finished": true,
	},
	# --autoplay-zone=cienaga: Brumaclara reached: Lv 40 with the bruma gear and Brena, at the
	# Ciénaga's entrance.
	"cienaga": {
		"experience": 24100,
		"gold": 1500,
		"gear": ["espada_bruma", "armadura_bruma", "escudo_bruma", "casco_bruma"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero",
			"jaguar_sombrio", "gusano_dunas", "montana_palanca", "grifo_cumbre",
			"guardian_ciudad", "ciudad_reja", "devorador_portal", "portal_calmo",
			"brumaclara", "brumaclara_vista"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo",
			"insignia_jungla", "sello_desierto", "mapa_montana"],
		"quest_done": true,
		"town": "brumaclara",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 4, Inventory.BIG_ETHER: 3, Inventory.WING: 3,
			Inventory.PHOENIX: 1},
		"finished": true,
	},
	# --autoplay-zone=garza: the Ciénaga almost done: Lv 42 with the bruma gear and Brena, at its
	# entrance; it walks to the nest and fights the Garza de légamo.
	"garza": {
		"zone": "cienaga",
		"experience": 27400,
		"gold": 2500,
		"gear": ["espada_bruma", "armadura_bruma", "escudo_bruma", "casco_bruma"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero",
			"jaguar_sombrio", "gusano_dunas", "montana_palanca", "grifo_cumbre",
			"guardian_ciudad", "ciudad_reja", "devorador_portal", "portal_calmo",
			"brumaclara", "brumaclara_vista"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo",
			"insignia_jungla", "sello_desierto", "mapa_montana"],
		"quest_done": true,
		"town": "brumaclara",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 5, Inventory.BIG_ETHER: 4, Inventory.WING: 3,
			Inventory.PHOENIX: 1},
		"finished": true,
	},
	# --autoplay-zone=cuevas: the Ciénaga done: Lv 43 with the bruma gear and Brena, the Garza
	# beaten and its lamp, at the Cuevas' entrance (their first floor).
	"cuevas": {
		"zone": "cuevas_1",
		"experience": 29200,
		"gold": 6000,
		"gear": ["espada_bruma", "armadura_bruma", "escudo_bruma", "casco_bruma"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero",
			"jaguar_sombrio", "gusano_dunas", "montana_palanca", "grifo_cumbre",
			"guardian_ciudad", "ciudad_reja", "devorador_portal", "portal_calmo",
			"brumaclara", "brumaclara_vista", "garza_legamo"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo",
			"insignia_jungla", "sello_desierto", "mapa_montana", "lampara_faro"],
		"quest_done": true,
		"town": "brumaclara",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 4, Inventory.BIG_ETHER: 3, Inventory.WING: 3,
			Inventory.PHOENIX: 1},
		"finished": true,
	},
	# --autoplay-zone=coloso: the Cuevas almost done: Lv 45 with the cristal gear and Brena, the
	# reja open, at the second floor's stairs; it walks to the hall and fights the Coloso.
	"coloso": {
		"zone": "cuevas_2",
		"experience": 33100,
		"gold": 3000,
		"gear": ["espada_cristal", "armadura_cristal", "escudo_cristal", "casco_cristal"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero",
			"jaguar_sombrio", "gusano_dunas", "montana_palanca", "grifo_cumbre",
			"guardian_ciudad", "ciudad_reja", "devorador_portal", "portal_calmo",
			"brumaclara", "brumaclara_vista", "garza_legamo", "cuevas_palanca"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo",
			"insignia_jungla", "sello_desierto", "mapa_montana", "lampara_faro"],
		"quest_done": true,
		"town": "brumaclara",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 5, Inventory.BIG_ETHER: 4, Inventory.WING: 3,
			Inventory.PHOENIX: 1},
		"finished": true,
	},
	# --autoplay-zone=ruinas: the Cuevas done and the amulet brought from Villaclaro: Lv 46 with
	# the cristal gear and Brena, at the Ruinas' entrance (their first floor).
	"ruinas": {
		"zone": "ruinas_1",
		"experience": 35200,
		"gold": 6000,
		"gear": ["espada_cristal", "armadura_cristal", "escudo_cristal", "casco_cristal"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero",
			"jaguar_sombrio", "gusano_dunas", "montana_palanca", "grifo_cumbre",
			"guardian_ciudad", "ciudad_reja", "devorador_portal", "portal_calmo",
			"brumaclara", "brumaclara_vista", "garza_legamo", "cuevas_palanca", "coloso_cuarzo",
			"amuleto_recuperado"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo",
			"insignia_jungla", "sello_desierto", "mapa_montana", "lampara_faro", "cristal_fuente",
			"amuleto_recuperado"],
		"quest_done": true,
		"town": "brumaclara",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 4, Inventory.BIG_ETHER: 3, Inventory.WING: 3,
			Inventory.PHOENIX: 1},
		"finished": true,
	},
	# --autoplay-zone=vigia: the Ruinas almost done: Lv 48 with the luna gear and Brena, at the
	# esplanade's stairs; it walks to the esplanade and fights the Vigía.
	"vigia": {
		"zone": "ruinas_2",
		"experience": 39700,
		"gold": 3000,
		"gear": ["espada_luna", "armadura_luna", "escudo_luna", "casco_luna"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero",
			"jaguar_sombrio", "gusano_dunas", "montana_palanca", "grifo_cumbre",
			"guardian_ciudad", "ciudad_reja", "devorador_portal", "portal_calmo",
			"brumaclara", "brumaclara_vista", "garza_legamo", "cuevas_palanca", "coloso_cuarzo",
			"amuleto_recuperado"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo",
			"insignia_jungla", "sello_desierto", "mapa_montana", "lampara_faro", "cristal_fuente",
			"amuleto_recuperado"],
		"quest_done": true,
		"town": "brumaclara",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 5, Inventory.BIG_ETHER: 4, Inventory.WING: 3,
			Inventory.PHOENIX: 1},
		"finished": true,
	},
	# --autoplay-zone=fuente: the Ruinas done: Lv 49 with the luna gear and Brena, the Vigía
	# beaten and its seal, at the Fuente's entrance; at the first retreat it buys the amanecer gear
	# and takes the Fuente's two quests.
	"fuente": {
		"zone": "fuente",
		"experience": 42100,
		"gold": 7000,
		"gear": ["espada_luna", "armadura_luna", "escudo_luna", "casco_luna"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra", "senor_niebla", "caravana_vista", "caravana", "companero",
			"jaguar_sombrio", "gusano_dunas", "montana_palanca", "grifo_cumbre",
			"guardian_ciudad", "ciudad_reja", "devorador_portal", "portal_calmo",
			"brumaclara", "brumaclara_vista", "garza_legamo", "cuevas_palanca", "coloso_cuarzo",
			"amuleto_recuperado", "vigia_bruma"],
		"key_items": ["fragmento_bosque", "fragmento_mina", "fragmento_castillo",
			"insignia_jungla", "sello_desierto", "mapa_montana", "lampara_faro", "cristal_fuente",
			"amuleto_recuperado", "sello_albor"],
		"quest_done": true,
		"town": "brumaclara",
		"ally": "brena",
		"items": {Inventory.BIG_POTION: 4, Inventory.BIG_ETHER: 3, Inventory.WING: 3,
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


## --autoplay-companion=<id>: that companion, DEFAULT_COMPANION if none is given or the id
## is not a companion (with an error that names it).
static func companion() -> String:
	var id := RunFlags.autoplay_companion()
	if id == "":
		return DEFAULT_COMPANION
	if not Allies.is_companion(id):
		push_error("Not a companion for --autoplay-companion: %s" % id)
		return DEFAULT_COMPANION
	return id


## The hero has AUTOPLAY_BOSS_HP of his max HP and AUTOPLAY_BOSS_MP of his max MP: on
## autoplay the zone's boss only comes out then.
static func rested_for_boss(hero: Combatant) -> bool:
	return hero.hp >= hero.max_hp * AUTOPLAY_BOSS_HP \
		and hero.mp >= hero.max_mp * AUTOPLAY_BOSS_MP
