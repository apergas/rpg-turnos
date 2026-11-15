# Versión 3.5.0: combate, compañero y portales

Fecha: 2026-11-15. Estado: spec. Cubre M-91 a M-95 del [documento maestro](../documento-maestro.md). Va después de la [3.4.0](2026-11-15-version-3-4-0-design.md), que ya enseña los números del compañero en «Estado». La partida guardada sigue en la versión 15 y no gana ni pierde campos: todo lo nuevo sale del nivel del héroe o del paso del compañero, que ya se calculan.

## Objetivo

1. **Los hechizos crecen con el héroe (M-91).** El daño de un hechizo sube un poco con cada nivel. Curar no cambia.
2. **Los objetos, primero (M-92).** Usar un objeto en combate va siempre antes que nadie, como en Pokémon.
3. **El compañero estrena equipo (M-93).** Brena, Tadeo o Ulma estrenan una pieza en cada tramo o etapa: se ve en combate y suma un poco.
4. **Sin portal en el fondo del Barrio del portal (M-94).** Salvo contra el Devorador.
5. **Un portal rojizo para la v3 (M-95).** El portal que une la Caravana con Brumaclara deja de ser azul, para no confundirse con el del Ala de viaje.

## Antes de cambiar: lo que hace hoy el juego

Las ideas pedían comprobar primero cómo funciona. Esto es lo que hay:

| Idea | Hoy | ¿Hay que cambiarlo? |
|---|---|---|
| Daño de los hechizos | `BattleEngine._cast()` hace `power × afinidad × azar(0,875-1,125)`. No mira ni el nivel ni el ataque: Rayo hace 70 a nivel 10 y a nivel 50 | Sí |
| Curar | Cura siempre `power` | No (es lo pedido) |
| Orden del turno | `_turn_order()` ordena por `VEL × azar(0,5-1,5)`. Solo Defender y Huir ponen al héroe el primero; un objeto va con su tirada | Sí |
| Crecimiento del compañero | `Allies.GROWTH` ya suma PV, ATK, DEF y VEL en cada paso (`GameState.ally_step()`: el tramo en la v2, 5 + la etapa en la v3) | No: se mantiene |
| Equipo del compañero | No tiene. Su aspecto es fijo (`ActorLooks` BRENA, TADEO, ULMA) y `BattleActor.set_equipment()` solo vale para el héroe | Sí |

## Decisiones tomadas (2026-11-15)

| Tema | Decisión |
|---|---|
| Cuánto suben los hechizos | +3 % por nivel por encima del nivel en que se aprende |
| A quién afecta | Solo a los hechizos que lanza el héroe. Los enemigos usan otros recursos (`data/skills/*_bruja`, `rayo_esqueleto`…) y no cambian |
| Equipo del compañero | Se ve y da un poco. El crecimiento de hoy se mantiene |
| Criaturas de la v1 | No crecen ni llevan equipo, como hoy |

## 1. Los hechizos crecen con el héroe (M-91)

### La regla

- El daño de un hechizo del héroe es `power × (1 + 0,03 × niveles)`, donde *niveles* son los que el héroe tiene por encima del nivel en que aprendió ese hechizo (0 como mínimo). Después se aplican la afinidad y el azar, como hoy.
- El nivel en que se aprende sale de `hero.learn` (`data/hero.tres`). Un hechizo con el que se empieza (Ascuas) cuenta como aprendido a nivel 1.

| Hechizo | Se aprende | Poder hoy | Nv 20 | Nv 40 | Nv 50 |
|---|---|---|---|---|---|
| Ascuas | 1 | 16 | 25 | — (lo sustituye Llamarada a nivel 7) | — |
| Llamarada | 7 | 28 | 39 | 56 | 64 |
| Rayo | 10 | 70 | 91 | 133 | 154 |
| Ventisca | 24 | 48 | — | 71 | 85 |
| Alba | 45 | 240 | — | — | 276 |

- Curar, Curar+ y Sanación no cambian. La parte de Sanación para el compañero tampoco.
- Los textos de los hechizos no dicen números de daño («Gran daño de rayo a un enemigo»), así que no cambian.

### Lo que cambia en el código

- **`Leveling.learned_at(hero, skill) -> int`** (`scripts/game/leveling.gd`), pura: el nivel de `hero.learn` que enseña ese hechizo, o 1 si no está.
- **`BattleEngine.spell_power(who, skill) -> float`** (`scripts/battle/battle_engine.gd`): `skill.power` tal cual si `who` no es `BattleEvent.HERO`; si lo es, `skill.power × (1 + SPELL_GROWTH × maxi(hero.level - Leveling.learned_at(hero, skill), 0))`, con `const SPELL_GROWTH := 0.03`. `_cast()` la usa solo para `Skill.DAMAGE`.
- **Partida automática:** `BattleAutoplay` estima el daño de un hechizo con `skill.power` (`battle_autoplay.gd`, dos sitios) y pasa a usar `spell_power()`, para elegir bien entre golpe y hechizo.
- **Equilibrio:** se mide con la partida automática (skill `villaclaro-autoplay`) en una zona de cada parte (el castillo, la ciudad y la Fuente), antes y después. Los tiempos pueden bajar un poco; las derrotas no deben subir. Si una zona se vuelve demasiado fácil, se baja `SPELL_GROWTH`, no se toca a los enemigos.

## 2. Los objetos, primero (M-92)

### La regla

- Si el héroe usa un objeto (poción, éter, antídoto, Pluma de fénix, Despertador, Ala…), actúa el primero del turno, antes que los enemigos y el compañero, aunque sean más rápidos. Después, todos los demás actúan en su orden de siempre.
- Defender y Huir siguen yendo primero, como hoy.
- **Emboscada enemiga:** el primer turno, el de la sorpresa, sigue siendo solo de los enemigos. El héroe no puede elegir nada en él, así que no cambia.
- **Emboscada del héroe:** solo actúan el héroe y el compañero; el objeto también va primero.
- Ni los enemigos ni el compañero usan objetos, así que la regla solo toca al héroe.

### Lo que cambia en el código

- `BattleEngine._turn_order()`: `CMD_ITEM` se suma a `[CMD_DEFEND, CMD_FLEE]` en la lista de órdenes que ponen al héroe delante. El comentario de la función lo dice.
- `docs/legacy/qa/brief-qa-agentes.md` (se mantiene al día con el juego): la fila «Iniciativa» pasa a decir «si defiende, huye o usa un objeto, el héroe va primero».

## 3. El compañero estrena equipo (M-93)

### Lo que ve el jugador

- Brena, Tadeo y Ulma estrenan una pieza en cada paso, a partir del desierto: un arma con el color de una serie mejor, un casco o una capa. Cada pieza nueva se ve en combate y suma un poco: el arma, ATK, y el casco o la capa, DEF.
- Una pieza que no se estrena en ese paso conserva el color del paso en que la estrenó.
- En «Estado» los números del compañero ya incluyen ese equipo (la línea de la 3.4.0 lee `total_attack()` y `total_defense()`).
- Las criaturas de la Domadora no cambian.

### La tabla

Cada paso pinta la pieza que estrena con los colores de una serie del héroe, un paso por detrás de lo que vende la Caravana o el Herrero en ese momento. Así el compañero no luce mejor que el héroe.

| Paso (`ally_step`) | Dónde | Serie de color | Pieza que estrena | Suma |
|---|---|---|---|---|
| 1 | Jungla | — | Ninguna: su aspecto de hoy | — |
| 2 | Desierto | jade | Arma | ATK +6 |
| 3 | Montaña | oricalco | Casco (Tadeo, que hoy no lo lleva, lo estrena aquí) | DEF +4 |
| 4 | Ciudad | adamantita | Capa | DEF +4 |
| 5 | Tras el Devorador | estelar | Arma | ATK +6 |
| 6 | Brumaclara y la Ciénaga | bruma | Casco | DEF +4 |
| 7 | Cuevas de cristal | cristal | Capa | DEF +4 |
| 8 | Ruinas flotantes | luna | Arma | ATK +6 |
| 9 | La Fuente | amanecer | Casco | DEF +4 |
| 10 | Tras el Eco de Albor | amanecer | Capa | DEF +4 |

- En el paso 10, todo junto suma ATK +18 y DEF +24. Para comparar, el crecimiento de hoy le da a Brena ATK +108 en ese paso.
- **Cada uno conserva su forma:** Brena, la espada a dos manos; Tadeo, las dos espadas cortas (las dos cambian de color); Ulma, espada y escudo rectangular. En el caso de Ulma, el escudo toma el color de la capa en los pasos de capa. Brena y Tadeo no llevan escudo.
- Se usan las piezas que ya trae el modelo `Knight.glb` (`1H_Sword`, `1H_Sword_Offhand`, `2H_Sword`, `Rectangle_Shield`, `Knight_Helmet`, `Knight_Cape`) con los tintes de las piezas del héroe (`Equipment.tint()`, `Equipment.helmet_tint()`). No hay modelos nuevos ni animaciones nuevas. Si la capa del modelo no se ve bien sobre el tinte del cuerpo, el paso de capa colorea el escudo de Ulma y, en Brena y Tadeo, el cinturón u otra pieza del modelo; lo decide la captura del plan.

### Lo que cambia en el código

- **`Allies.GEAR`** (`scripts/game/allies.gd`): la tabla de arriba como datos (paso → pieza, serie y suma), y **`Allies.gear(id, step) -> Dictionary`**, pura: para cada pieza (arma, casco, capa) el id de la pieza del héroe cuyo tinte lleva (vacío si aún no la estrenó), y las sumas `attack` y `defense` acumuladas. Para una criatura devuelve un diccionario vacío.
- **`Allies.data(id, step)`** pone esas sumas en `equip_attack` y `equip_defense` del `Combatant`. `BattleEngine` ya usa `total_attack()` y `total_defense()` para todos (`_roll_damage()`), así que el combate no cambia. El comentario «Hero only» de esos campos en `combatant.gd` se corrige.
- **`BattleActor.set_companion_gear(gear: Dictionary)`** (`scripts/battle/battle_actor.gd`): solo para los aspectos BRENA, TADEO y ULMA. Muestra u oculta el casco y tiñe las piezas con los tintes de `gear`. `set_equipment()` sigue siendo solo del héroe. Si `battle_actor.gd` crece demasiado, la parte que tiñe piezas del caballero se pasa a `CharacterBuilder`, el constructor que ya monta estos modelos (skill `structuring-godot-code`).
- **`BattleScene`** recibe el paso del compañero en `setup()`, desde `BattleFlow`, que ya llama a `Allies.data(ally_id, ally_step())`, y tras crear `_ally_actor` llama a `set_companion_gear(Allies.gear(id, step))`.
- La 3.6.0 (el compañero en el mapa) usa la misma llamada, así que el compañero lleva el mismo equipo en el mapa que en combate.

## 4. Sin portal en el fondo del Barrio del portal (M-94)

### Lo que ve el jugador

- En los combates normales del Barrio del portal (`ciudad_2`) el fondo es la ciudad, sin el portal.
- Contra el Devorador del portal, en sus dos fases, el portal sí sale detrás, como hoy.

### Lo que cambia en el código

- `BattleStage.build(root, zone, boss := false)` (`scripts/battle/battle_stage.gd`) pasa el valor a `_build_city()`, que solo añade el `PortalRing` cuando `zone.portal_flag != ""` y `boss`. El comentario de cabecera de `BattleStage` se corrige.
- `BattleScene._ready()` llama a `BattleStage.build(self, zone, _has_boss())`, con los enemigos de `setup()` (que ya están cargados): verdadero si alguno tiene `is_boss`.
- Los demás fondos ignoran el parámetro.

## 5. Un portal rojizo para la v3 (M-95)

### Lo que ve el jugador

- Al terminar la v2, la salida que lleva de la Caravana a Brumaclara, y la de vuelta en Brumaclara, se ven con la misma forma de hoy: el remolino, la corona de rayos, las chispas y la luz que late. Pero en tonos rojizos, de rojo oscuro en el centro a un rosa claro en el borde.
- El portal del Ala de viaje sigue azul, y su anillo de vuelta en el suelo también.
- El rojizo es el del portal de la ciudad ya calmado (`PortalRing`, `DISC_CALM` y `SPARK_CALM`): es el mismo paso que el Devorador guardaba.

### Lo que cambia en el código

- **`TravelPortal`** (`scripts/world/travel_portal.gd`) gana `var red := false`. Con `red`, `_add_surface()` pasa al shader `portal_swirl.gdshader` los colores rojizos en sus uniformes (`edge_color`, `swirl_color`, `core_color`, `corona_inner`, `corona_outer`), y las chispas y la luz usan sus colores rojizos. Los valores azules de hoy siguen siendo los de por defecto.
- Los colores son constantes de `TravelPortal` junto a las azules (`RUNE`, `LIGHT` y sus equivalentes rojizos). No son colores de interfaz, así que no entran en el design system.
- **`MapProps._build_exit()`** (`scripts/world/map_props.gd`): una salida con `"look": "portal"` crea el `TravelPortal` con `red = true`. Hoy solo la usan la Caravana y Brumaclara.
- El comentario de cabecera de `TravelPortal` y el de `PORTAL_LOOK` en `ZoneData` dicen que la salida-portal es rojiza.

## Verificación (a mano; el proyecto no tiene tests)

- `--check-only` en cada script tocado, `gen_ui_tokens.gd -- --check` y `check_ui_values.gd`.
- Partida automática del castillo, la ciudad y la Fuente (skill `villaclaro-autoplay`), comparando tiempos y derrotas con la 3.4.0. También el recorrido completo de la v3 hasta `Juego completado (v3)`.
- Capturas:
  - un combate con Brena, Tadeo y Ulma en los pasos 1, 4 y 9 (`--autoplay-zone` de la jungla, la ciudad y la Fuente);
  - un combate normal y el del Devorador en el Barrio del portal;
  - el portal de la Caravana y el de Brumaclara junto al del Ala de viaje, con `--write-movie` o en ventana.
- En un combate de prueba: con un enemigo más rápido, una poción va antes que su golpe.
- `CHANGELOG.md`, sección 3.5.0, y `application/config/version` = 3.5.0.

## Ajustes del plan

Lo que el [plan](../plans/2026-11-15-version-3-5-0.md) precisa o corrige de este spec. Manda lo que dice el plan.

- **Partida automática:** `BattleAutoplay` solo estima el daño de los hechizos en un sitio (`_spell_damage()`), que es el que cambia. El otro uso de `power` compara curas y no se toca.
- **El paso del compañero:** `BattleScene` lo recibe en un campo, `ally_step`, que `BattleFlow` pone junto a `ally`, en lugar de por `setup()`. Así recibe ya `BattleScene` todo lo demás.
- **La capa:** las armaduras del héroe no llevan tinte. En los pasos de capa, la capa toma el color del escudo de esa serie, más oscuro (`CAPE_SHADE` 0,6). `Knight.glb` no tiene cinturón. Si la capa no se ve en las capturas, primero se sube `CAPE_SHADE` a 0,8 y, si aún no se ve, se tiñen los brazos (`Knight_ArmLeft` y `Knight_ArmRight`).
- **`PORTAL_LOOK`** está en `MapProps`, no en `ZoneData`. Se corrigen los comentarios de los dos.
- **Brief de QA:** además de la fila «Iniciativa», cambia la de «Hechizos», por el crecimiento.
- **Equilibrio:** si una zona queda más de un 15 % más corta que antes, `SPELL_GROWTH` baja a 0,02 y, como mucho, a 0,015.
