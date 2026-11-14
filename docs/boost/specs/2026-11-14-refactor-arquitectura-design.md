# Refactor de arquitectura: trocear las clases grandes y aislar el piloto automático

Fecha: 2026-11-14. Estado: spec, pendiente de revisión. Sin versión asignada. Se recomienda hacerlo **después de la 2.7.0 y antes de la v3**, porque la v3 añadirá zonas, escenas y figuras justo en `Game` y `World`. Cubre M-70 a M-74. El orden de trabajo y las comprobaciones de cada paso están en la [guía del refactor](2026-11-14-refactor-arquitectura-guia.md).

## Objetivo

Reordenar el código **sin que cambie nada del juego**. Ni reglas, ni textos, ni aspecto, ni partida guardada (sigue en la versión 14), ni salida del piloto automático (las mismas líneas `Zona:`, `Escena:`, `Juego completado: ...`).

Parte del análisis de arquitectura del 2026-11-14 (unas 25.000 líneas en 91 clases). Lo que ya está bien no se toca:

- las reglas puras en `RefCounted` / `Resource`;
- los datos en `.tres`;
- la ausencia de autoloads, con la sesión pasada a mano por `setup()`;
- las señales hacia arriba;
- el tipado;
- el design system.

Lo que se arregla son los cuatro puntos donde el código se aparta de las guías de Godot (*GDScript style guide* y *Best practices*) o de un diseño limpio:

| ID | Problema | Hoy |
|---|---|---|
| M-70 | `Game` hace de todo | 1.840 líneas, 77 funciones, 34 variables, 57 clases usadas; 139 menciones del piloto automático y 36 de depuración |
| M-71 | `World` hace de todo | 1.839 líneas, 97 funciones, 80 variables, 15 señales |
| M-72 | `BattleActor` lleva todas las figuras del juego | 2.473 líneas: unas 740 de la tabla `LOOKS`, unas 30 funciones `_build_*` y las primitivas de malla |
| M-73 | Constructores que se presentan como reglas puras | 7 clases `extends RefCounted` que crean nodos: `WorldStage`, `BattleStage`, `Vegetation`, `ZoneParticles`, `LowPoly`, `UiTheme`, `UiStyle` |
| M-74 | El piloto automático está repartido por el juego | 19 lecturas sueltas de `OS.get_cmdline_user_args()`; `"--autoplay"` se comprueba en 14 sitios |

**Escenas casi vacías.** Se queda como está. Es una decisión consciente: trabajamos sin editor, y una `.tscn` con decenas de nodos escrita a mano es más frágil que el código. El equivalente en Godot de "escenas pequeñas reutilizables" son las clases de nodo con una sola responsabilidad, y eso es lo que crea este refactor (`MapHud`, `MapMonsters`...). La decisión se escribe en la sección *Conventions* de `CLAUDE.md`, con su motivo.

**Tests.** Siguen sin existir. La comprobación es a mano, como siempre (ver la guía).

## Reglas comunes

1. **Fachada primero.** Cada clase grande conserva su API pública mientras se trocea. `Game`, `CutscenePlayer`, `DebugPanel` y el piloto automático siguen llamando a `World.show_dialogue()`, `World.figure_node()`, `Game.setup()`... La fachada solo delega. Las llamadas se pueden mover más tarde a la pieza nueva, pero no hace falta.
2. **Un paso, un commit, el juego entero funcionando.** Nunca se mueve una pieza a medias.
3. **Sin lógica nueva.** Se mueve código y se le cambia el nombre. No se reescribe. Si al mover algo aparece un error, se apunta y se arregla en otro commit, nunca mezclado con el movimiento.
4. **Las piezas nuevas siguen las convenciones de hoy:**
   - reglas puras en `RefCounted`;
   - piezas con nodos como `Node` o `Control` hijos de su dueño, creados en código;
   - la sesión pasada con `setup()`;
   - nada de autoloads.
5. **Una pieza no conoce a su dueño.** Recibe lo que necesita con `setup()` (estado, mundo, audio, `Callable`s como `fade` o `autosave`) y avisa con señales. No guarda una referencia a `Game` ni a `World`. Así se evitan las dependencias circulares y cada pieza se puede leer sola.
6. **`CLAUDE.md` se actualiza en el mismo commit que el código.** Hoy describe cada función por su nombre, así que cada movimiento cambia su sección *Layout*.

## M-70. Trocear `Game`

`Game` queda como coordinador de la sesión:

- `setup()`, `_ready()` y `_exit_tree()`;
- el `GameState`, el `World` actual, la música, el fundido, el guardado (`_autosave()`), `_set_busy()`, `_refresh_status()` y el menú de pausa;
- conectar las señales del mundo con la pieza que las atiende.

**Meta orientativa:** menos de 600 líneas.

| Pieza nueva | Tipo | Se lleva de `Game` |
|---|---|---|
| `ZoneTravel` (`scripts/game/zone_travel.gd`) | `Node` | `_switch_zone`, `_on_exit`, `_on_travel_requested`, `_on_portal`, `_show_portal`, `_go_to_town`, `_respawn_groups`, `_spawn_rare`, `_to_place` |
| `BattleFlow` (`scripts/game/battle_flow.gd`) | `Node` | `_on_encounter` (170 líneas), `_note_enemies`, `_give_family_rewards`, `_boss_notice`, `_update_boss`, `_boss_id`, `_boss_wanted` |
| `BattleRewards` (`scripts/game/battle_rewards.gd`) | `RefCounted`, puro | Lo que `_on_encounter` decide tras una victoria (oro, misiones, medallas, Slime de Metal, jefe) y devuelve como `{notices, lines, flags}`, sin tocar nodos. `BattleFlow` solo lo reproduce |
| `FigureTalk` (`scripts/game/figure_talk.gd`) | `Node` | `_on_talk`, `_quest_npc`, `_on_npc`, `_talk_to_collector`, `_after_quest_talk`, `_done_text`, `_figure_with_quest`, `_on_shop`, `_on_inn`, `_on_well`, `_on_chest`, `_on_lever`, `_on_key`, `_on_door` |
| `CaravanFlow` (`scripts/game/caravan_flow.gd`) | `Node` | `_ask_departure`, `_choose_companion` y la llegada de la caravana de `_check_village_scene` |
| `StoryFlow` (`scripts/story/story_flow.gd`) | `Node` | `_play_scene`, `_play_prologue`, `_check_village_scene`, `_check_arrival_line`, `_scene_travel`, `_scene_flag`, `_finish_game`, `_finish_v2`, `_build_cutscenes` |
| `CreditsData` (`scripts/story/credits_data.gd`) | `RefCounted`, puro | `_credits_sections`, `_v2_credits_sections`, `_v2_numbers`, `_clock`, `_summary`: las secciones de los créditos a partir de un `GameState` |
| `GameAutoplay` (`scripts/game/game_autoplay.gd`) | `Node`, solo con `--autoplay` | `_apply_autoplay_zone`, `_autoplay_retreat`, `_wants_retreat`, `_needs_groups`, `_autoplay_hunts`, `_boss_needs_rest`, `_rested_for_boss`, `_autoplay_restock`, `_on_medal_tour_timeout`, `_finish_medal_tour`, la parte de autoplay de `_process()` |
| `AutoplayStarts` (`scripts/game/autoplay_starts.gd`) | `RefCounted`, puro | `AUTOPLAY_ZONES`, `ECHO_START`, `MEDAL_TOUR*`, `V2_STARTS`: los arranques como datos |
| `GameDebug` (`scripts/game/game_debug.gd`) | `Node`, solo con `--debug` | `_build_debug`, `_on_debug`, `_debug_go` |

- Las piezas se avisan a través de `Game`, con señales. Por ejemplo, `BattleFlow.boss_beaten(id)` hace que `Game` pida a `StoryFlow` la escena del jefe. Nunca se llaman directamente entre ellas.
- Lo que varias piezas necesitan (estado, mundo actual, audio, `fade`, `autosave`, `set_busy`) se lo da `Game` en un objeto pequeño, `SessionContext` (`RefCounted`, `scripts/game/session_context.gd`). Cuando `_switch_zone` crea un mundo nuevo, `Game` actualiza `context.world`.
- **El piloto automático solo usa la API pública** de las demás piezas y del mundo. Si `GameAutoplay` necesita algo que hoy es privado de `Game`, ese algo pasa a ser público en la pieza que lo tiene, con su nombre sin guion bajo.

## M-71. Trocear `World`

`World` queda como la escena del mapa: construir la zona (`WorldStage.build`), el jugador, la cámara, `set_active()` / `freeze()`, las señales hacia `Game` y la fachada de su API pública.

**Meta orientativa:** menos de 700 líneas.

| Pieza nueva | Tipo | Se lleva de `World` |
|---|---|---|
| `MapMonsters` (`scripts/world/map_monsters.gd`) | `Node3D` | `respawn_groups`, `group_count`, `clear_groups`, `add_rare`, `has_rare`, `_add_group`, `_tick_refill`, `_move_groups`, `_fade_group`, `contact_enemies`, `end_contact`, `_calm`, `_check_groups`, `_group_index`, `set_monsters_shy`, `set_repel`, `debug_no_groups` |
| `AutoplayHunter` (`scripts/world/autoplay_hunter.gd`) | `RefCounted` | `set_autoplay_hunt`, `_update_hunt` y los temporizadores `_sim_ms` de la caza |
| `MapUses` (`scripts/world/map_uses.gd`) | `Node` | Los avisos y los usos: `_prompt_text`, `_show_prompt`, `_hide_prompt`, `_prompt_showing`, `_clear_signs_under`, `_restore_signs`, `_paint_prompt_cap`, `_action_key_name`, `_nearest_use`, `_tapped_use`, `_in_reach`, `_uses`, `_use`, `_trigger`, `_is_open`, `_check_exits` |
| `MapFigures` (`scripts/world/map_figures.gd`) | `Node3D` | `_add_figure`, `_add_figure_sign`, `_figure_sign_text`, `_build_mark`, `set_quest_view`, `_show_quest_marks`, `figure_node`, `figure_turn`, `figure_actor`, `reset_figures`, `npc_lines` |
| `MapProps` (`scripts/world/map_props.gd`) | `Node3D` | `_build_exit`, `_build_portal`, `set_portal`, `set_return_mark`, `_build_well`, `set_dry_wells`, `_well_kind`, `build_chest`, `set_chest_open`, `_build_marker` |
| `MapHud` (`scripts/world/map_hud.gd`) | `CanvasLayer` (`UiTokens.LAYER_HUD`) | `_build_ui`, `refresh_status`, `set_status_shown`, `show_mission_done`, `_show_missions`, `show_notice`, `_build_banner`, `_show_banner`, `_label`, `show_touch_hint`, `_build_touch_controls`, el `MapSquare` y `_refresh_map_marks` |

- Las señales públicas de `World` (`talk_requested`, `shop_requested`...) **no cambian de dueño**. Las piezas emiten las suyas y `World` las reenvía, así que `Game` no nota nada.
- `begin_cutscene()` y `end_cutscene()` se quedan en `World` y reparten la orden: `MapHud` se oculta, `MapFigures` quita las marcas y `MapUses` quita el aviso.
- `_physics_process` sigue en `World` y llama a cada pieza por orden (`MapMonsters.step()`, `MapUses.step()`...). Así el orden de cada tic queda explícito y no depende del orden de los nodos en el árbol.

## M-72. Trocear `BattleActor`

`BattleActor` queda como la figura viva: `_ready()`, la animación (`play_*`, `_start_*`, `_hop`, `_start`, `_end`), los números flotantes, el equipo (`set_equipment`, `_build_horns`), el brillo y la transparencia.

**Meta orientativa:** menos de 900 líneas.

| Pieza nueva | Tipo | Se lleva de `BattleActor` |
|---|---|---|
| `ActorLooks` (`scripts/battle/actor_looks.gd`) | `RefCounted`, solo datos | `enum Look`, `LOOKS`, `CHARACTER_ANIMS`, `SKELETON_ANIMS`, `ROGUE_ANIMS`, `HAIR_PIECES`, `HAIR_PROFILES` y las rutas de modelos y texturas |
| `CreatureBuilder` (`scripts/battle/creature_builder.gd`) | `RefCounted`, constructor estático | Las funciones `_build_*` de figuras hechas en código (slime, murciélago, lobo, grifo, gárgola, Devorador...), cada una como `static func build_x(actor: BattleActor, look: Dictionary)` |
| `CharacterBuilder` (`scripts/battle/character_builder.gd`) | `RefCounted`, constructor estático | `_build_character`, `_add_hair`, `_add_mummy_wraps`, `_hang_on_bone`: las figuras KayKit con su pelo, capa y tintes |
| `LowPoly` (ya existe) | | Las primitivas `_hemisphere`, `_disc`, `_sphere`, `_cylinder`, `_cone` y `_merged` |

- **`EnemyLibrary.LOOKS` y `Look` siguen funcionando igual:** `BattleActor.Look` pasa a ser `ActorLooks.Look`. `BattleActor.Look.X` sale 64 veces en seis scripts (57 en `EnemyLibrary`), así que se deja un alias: `const Look = ActorLooks.Look` en `BattleActor`.
- **Lo que los constructores escriben en la figura** (las alas de `_wings`, los materiales de la transparencia, los nodos de `props`) se hace con métodos pequeños de `BattleActor`: `add_wing()`, `add_part()`... Así el constructor no toca variables privadas.

## M-73. Constructores con su etiqueta

`WorldStage`, `BattleStage`, `Vegetation`, `ZoneParticles`, `LowPoly`, `UiTheme` y `UiStyle` crean nodos o recursos de render, así que no son reglas puras.

- No cambian de nombre ni de carpeta, para no tocar cientos de llamadas.
- Su comentario de cabecera empieza por `## Constructor:` y dice qué crea.
- La sección *Conventions* de `CLAUDE.md` distingue tres clases de script:
  - **reglas puras** (`RefCounted` / `Resource`, nunca tocan nodos);
  - **constructores** (estáticos, crean nodos para quien los llama y no guardan estado);
  - **nodos** (escenas y piezas vivas).
- Las piezas nuevas `CreatureBuilder` y `CharacterBuilder` son constructores.

## M-74. El piloto automático y las banderas de arranque en un solo sitio

- **Clase nueva `RunFlags`** (`scripts/game/run_flags.gd`, `RefCounted`, estática). Lee `OS.get_cmdline_user_args()` una sola vez y responde a:
  - `autoplay()`, `autoplay_save()`, `autoplay_menu()`, `autoplay_easy()`;
  - `autoplay_zone()`, `autoplay_companion()`;
  - `debug()`, `touch()`.
- Las 19 lecturas sueltas de la línea de órdenes pasan a `RunFlags`. Las cadenas `"--autoplay..."` solo aparecen en `run_flags.gd`.
- **Dentro de cada clase, la parte de autoplay va junta,** en una región marcada (`#region Autoplay` / `#endregion`, que Godot 4 entiende) o en su propia pieza: `GameAutoplay`, `AutoplayHunter`, `BattleAutoplay` (ya existe). En `BattleScene`, `ShopWindow`, `Player`, `DialogueBox`, `CreditsScreen` y `NameEntry` queda en su región.
- **No se quita ninguna función del piloto automático.** Es la red de comprobación del proyecto y tiene que seguir dando las mismas líneas.

## Lo que no entra

- Nada de reglas, equilibrio, textos ni partida guardada.
- No se renombran clases que ya existen, salvo el alias `Look`.
- No se mueven archivos que ya existen.
- No se cambia `.tscn` ni `project.godot`. Lo único nuevo es la caché de clases, que regenera `--import`.
- Nada de tests.
- `BattleScene` (764 líneas), `PauseMenu` (864) y `BattleHud` (720) no entran. Son grandes, pero cada una hace una sola cosa. Se pueden revisar más adelante con estas mismas reglas.

## Cómo se comprueba que nada ha cambiado

En la [guía](2026-11-14-refactor-arquitectura-guia.md): antes de empezar se guarda una referencia (registros del piloto automático, ida y vuelta del guardado y los retratos del bestiario). Después de cada paso se compara con ella.
