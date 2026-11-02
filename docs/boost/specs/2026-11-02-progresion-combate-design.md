# Progresión de combate — diseño

Fecha: 2026-11-02
Proyecto: `rpg-turnos` (RPG 3D por turnos, estilo visual Dragon Quest)
Paso: sub-proyecto 2 de 3 del vertical slice (ver la hoja de ruta en `2026-11-02-mundo-exploracion-design.md`)

## Objetivo

Que ganar combates haga más fuerte al héroe y que cada turno sea una decisión: **niveles** con subida de stats, **PM** y un hechizo de fuego (**Llama**), **pociones** en un inventario que persiste entre combates y un enemigo que **elige acción** según pesos definidos en sus datos. Todo con la arquitectura actual: reglas puras que devuelven eventos y una escena que los reproduce.

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Habilidad | Hechizo de fuego "Llama": 3 PM, daño mágico que ignora la defensa, sin fallo ni crítico |
| Pociones | El héroe empieza con 3; cada slime suelta una con un 25 %; solo se usan en combate; curan 25 PV |
| Subida de nivel | Tabla fija de EXP, tope nivel 10; cada nivel +5 PV máx., +2 PM máx., +2 ATK, +1 DEF, +1 VEL; los PV/PM actuales suben lo mismo que el máximo, no se cura del todo |
| Recuperar PM | Solo al subir de nivel (+2) y al reaparecer tras una derrota (completos). El hub del sub-proyecto 3 añadirá otra vía |
| IA enemiga | Base genérica ahora: el enemigo elige entre acciones con pesos de sus datos. Slime: atacar 80, tambalearse 20 |
| Modelo | Enfoque A: habilidades como `Resource` (`Skill`, `.tres`), comandos como diccionarios, `Leveling` e `Inventory` como clases puras |

## Reglas

**Llama** (`data/skills/llama.tres`): `id = "llama"`, `display_name = "Llama"`, `mp_cost = 3`, `power = 16`. Daño = `power × randf_range(0.875, 1.125)` redondeado, mínimo 1. No mira ATK ni DEF, no falla y no hace crítico. Cuesta los PM al lanzarse.

**Héroe** (`data/hero.tres`): se añaden `level = 1`, `max_mp = 6`, `mp = 6`, `skills = [llama]`. Con 6 PM lanza dos Llamas.

**Niveles** (`Leveling`): EXP total necesaria para cada nivel:

| Nivel | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| EXP | 0 | 10 | 25 | 45 | 70 | 100 | 135 | 175 | 220 | 270 |

Tras sumar la EXP de una victoria se sube tantos niveles como toque (puede ser más de uno). Cada nivel suma `max_hp +5, max_mp +2, attack +2, defense +1, speed +1` y suma también `+5` a `hp` y `+2` a `mp`. En nivel 10 la EXP sigue acumulándose, pero no sube nada más.

**Pociones** (`Inventory`): diccionario `id → cantidad`; `GameState` crea uno con `{"potion": 3}`. Una poción cura 25 PV sin pasar del máximo. Usarla gasta el turno del héroe y respeta el orden de iniciativa como cualquier otra acción. Si el enemigo derrotado tiene `potion_drop_chance > 0` y la tirada sale, se añade 1 poción y el resultado lo anuncia.

**IA enemiga**: `Combatant.ai_weights: Dictionary` (por ejemplo `{"attack": 80, "stagger": 20}`). Las claves son `"attack"`, `"stagger"` (no hace nada, "se tambalea") o el `id` de una `Skill` de su lista `skills`. Se elige al azar según los pesos. Si sale una skill sin PM suficientes, ataca. Un diccionario vacío equivale a `{"attack": 1}`. Así, el jefe del sub-proyecto 3 se define solo con datos.

**Derrota**: `GameState.heal_full()` restaura PV y PM. Las pociones y la EXP se conservan.

## Componentes

Nuevos:

| Archivo | Responsabilidad |
|---|---|
| `scripts/battle/skill.gd` (`Skill`, `Resource`) | Datos de un hechizo: `id`, `display_name`, `mp_cost`, `power` |
| `data/skills/llama.tres` | La Llama |
| `scripts/game/leveling.gd` (`Leveling`, `RefCounted`) | `EXP_TABLE`, `MAX_LEVEL`, ganancias; `static apply(hero) -> Array[Dictionary]` sube los niveles pendientes y devuelve un evento `LEVEL_UP` por nivel; `static exp_for_next(level) -> int` (−1 en el tope) |
| `scripts/game/inventory.gd` (`Inventory`, `RefCounted`) | `POTION`, `POTION_HEAL`, `START_POTIONS`, `display_name(id)`; `count(id)`, `add(id, n)`, `take(id) -> bool` |

Modificados:

| Archivo | Cambio |
|---|---|
| `scripts/battle/combatant.gd` | `level`, `max_mp`, `mp`, `skills: Array[Skill]`, `ai_weights: Dictionary`, `potion_drop_chance: float` |
| `data/hero.tres`, `data/slime.tres` | Héroe con nivel, PM y Llama. Slime con `ai_weights = {"attack": 80, "stagger": 20}` y `potion_drop_chance = 0.25` |
| `scripts/battle/battle_event.gd` | `damage()` gana `magic` (para la animación de fuego). Eventos nuevos: `SKILL` (actor, target, nombre, mp_left), `ITEM` (actor, nombre), `HEAL` (target, amount, hp_left), `STAGGER` (actor), `LEVEL_UP` (level, gains), `DROP` (item) |
| `scripts/battle/battle_engine.gd` | Constructor `(hero, enemy, rng, inventory)`. Comandos como diccionarios creados con `static cmd_attack()`, `cmd_skill(skill)` y `cmd_item(id)`. `resolve_round(cmd: Dictionary)`. El enemigo elige su comando con `ai_weights`. En la victoria suma la EXP, llama a `Leveling.apply` y tira el botín. Afirma que el comando sea válido (PM y pociones) |
| `scripts/game/game_state.gd` | `inventory: Inventory` con 3 pociones; `heal_full()` también llena los PM |
| `scripts/battle/battle_scene.gd` | `setup(hero, enemy_data, inventory)`; reproduce los eventos nuevos; autoplay con una política simple (ver Verificación) |
| `scripts/battle/battle_actor.gd` | Animaciones nuevas que se pueden esperar con `await`: `play_cast()` (salto corto y destello naranja), `play_burn(amount)` (bola naranja que crece y se desvanece, más el número), `play_heal(amount)` (destello verde y número verde), `play_stagger()` (balanceo lateral) |
| `scripts/ui/battle_hud.gd` | Estado con "Nv N", PV y PM. Menú plano con tres botones: "Atacar", "Llama (3 PM)" y "Poción ×N"; los dos últimos se desactivan si no hay PM o pociones. Flechas arriba/abajo para moverse; Enter/Espacio pulsan el botón con el foco. Señal `command_chosen(cmd: Dictionary)`. `set_hero(c, potions)`, `update_mp(mp, max_mp)`, `update_level(level)` |
| `scripts/ui/battle_result.gd` | `show_victory(exp_gained, total_exp, new_level, got_potion)`: añade "¡Nivel N!" y "+1 Poción" cuando toca |
| `scripts/game/game.gd` | Pasa `state.inventory` a la batalla y al mapa |
| `scripts/world/world.gd` | `refresh_status(hero, potions)`: Nv, PV, PM, EXP (y la del siguiente nivel) y pociones |
| `CLAUDE.md` | Layout y descripción de reglas al día |

## Mensajes (español)

- `¡Héroe lanza Llama!` y después el daño, con el mensaje de siempre: `¡Slime recibe N de daño!`
- `¡Héroe usa una Poción!` y después `¡Héroe recupera N PV!`
- `El Slime se tambalea.`
- `¡Héroe sube al nivel N!`, seguido de `PV +5  PM +2  ATK +2  DEF +1  VEL +1`
- `¡El Slime ha dejado una Poción!`

## Flujo de un turno

1. El HUD muestra el menú y el jugador elige, lo que emite `command_chosen(cmd)`.
2. `engine.resolve_round(cmd)` decide el comando del enemigo y el orden de iniciativa, y resuelve las dos acciones.
3. La escena reproduce cada evento: mensaje, animación y actualización de PV/PM en el HUD.
4. Al ganar, la escena reproduce `VICTORY`, después los `LEVEL_UP` y por último el `DROP`. El resultado muestra lo ganado; "Continuar" emite `finished(won)`.
5. `Game` refresca el mapa con el héroe y las pociones.

## Verificación (sin tests)

- `--check-only` en cada script cambiado e `--import` tras añadir clases nuevas.
- Con `--autoplay` la escena también imprime cada mensaje del combate, de modo que la salida muestra qué ha pasado.
- Autoplay de combate (`-- --autoplay`): poción si PV < 40 % y quedan pociones; si no, Llama si hay PM y el enemigo tiene más de 12 PV; si no, Atacar. Así se recorren las tres ramas. En la salida no debe aparecer ningún ERROR ni WARNING.
- Recorrido largo de autoplay (`--quit-after` alto) hasta ver al menos una subida de nivel y un botín. Se graban fotogramas para comprobar el menú, el HUD con PM, el mensaje de nivel y el estado del mapa.
- Prueba a mano del usuario antes del merge.

## Fuera de alcance

Menú en el mapa o fuera de combate; tienda; más hechizos u objetos; elegir objetivo (solo hay un enemigo); huir; equipo; guardado en disco; el jefe, el NPC y el hub (sub-proyecto 3); sonido.
