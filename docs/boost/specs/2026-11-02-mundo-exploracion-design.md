# Mundo y bucle de exploración — diseño

Fecha: 2026-11-02
Proyecto: `rpg-turnos` (RPG 3D por turnos, estilo visual Dragon Quest)
Paso: 2 de la hoja de ruta; sub-proyecto 1 de 3 del vertical slice

## Objetivo

Que el combate existente deje de ser una pantalla aislada y forme parte de un **bucle de juego**: el héroe anda por un campo 3D en tercera persona, en la hierba salta un **encuentro aleatorio**, se juega el combate y se **vuelve al mapa** donde se estaba, con los PV y la EXP conservados. Si pierde, reaparece en el inicio curado.

## Vertical slice: hoja de ruta

El vertical slice se divide en tres sub-proyectos, cada uno con su spec, plan y rama `feature/`:

| # | Sub-proyecto | Contenido | Depende de |
|---|---|---|---|
| 1 | **Mundo y bucle** (este spec) | Mapa 3D, movimiento, encuentros aleatorios, combate ↔ mapa, estado del héroe en memoria, derrota y reaparición | Prototipo de combate |
| 2 | Progresión de combate | Niveles (subida, stats, mensaje), PM y una habilidad, poción e inventario, comandos con datos en `BattleEngine`, IA de enemigo que elige acción | 1 |
| 3 | Hub y contenido | Hub en el claro del mapa, NPC que cura y da la misión "derrota 3 slimes", jefe con habilidad especial | 1 y 2 |

Origen: una propuesta inicial pedía las 8 funcionalidades en un solo plan, con interfaces y sin código. Se adaptó a este proyecto así: tres sub-proyectos en lugar de uno; spec antes de plan; los planes llevan el código completo (permite implementadores baratos y revisión línea a línea); la verificación del mapa se diseña explícitamente (el `--autoplay` del combate no basta); "persistencia" significa en memoria, no en disco.

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Movimiento | Libre en 3ª persona, WASD / flechas relativo a la cámara |
| Cámara | Sigue al héroe por detrás y arriba; Q/E la rotan; no gira sola |
| Encuentros | Invisibles, por metros andados en hierba; el camino es seguro |
| Persistencia | Solo en memoria mientras el juego está abierto |
| PV | Persisten entre combates; no se regeneran solos |
| Derrota | Vuelta al punto de inicio con PV completos; la EXP se conserva |
| Arquitectura | Escena raíz `Game` que mantiene el mapa cargado y crea/destruye el combate encima; sin autoloads |

## Componentes

Nuevos:

| Archivo | Responsabilidad | Depende de |
|---|---|---|
| `scripts/game/game_state.gd` (`GameState`, `RefCounted`) | Estado de la partida: `hero: Combatant` (copia de `hero.tres` que vive toda la partida), `heal_full()`. No toca nodos | `Combatant` |
| `scripts/world/encounter_meter.gd` (`EncounterMeter`, `RefCounted`) | Regla pura de encuentros: `advance(meters, in_grass) -> bool`, `reset()` | `RandomNumberGenerator` |
| `scenes/game/game.tscn` + `scripts/game/game.gd` | Escena principal. Tiene el `GameState`, el `World` y el combate activo; hace los fundidos y decide qué pasa al terminar el combate | `GameState`, `World`, `BattleScene` |
| `scenes/world/world.tscn` + `scripts/world/world.gd` (`World`, `Node3D`) | Mapa: escenario, jugador, cámara, ventana de estado (PV, EXP), encuentros. Señal `encounter_triggered`; `set_active(bool)`, `respawn()`, `refresh_status(hero)` | `WorldStage`, `Player`, `FollowCamera`, `EncounterMeter`, `BattleHud.make_window` |
| `scripts/world/world_stage.gd` (`WorldStage`, `RefCounted`) | Construye el campo con primitivas y colisiones; `static is_on_path(pos) -> bool`; constantes `SPAWN_POS`, `CLEARING_POS` | `BattleStage.build_environment` |
| `scenes/world/player.tscn` + `scripts/world/player.gd` (`Player`, `CharacterBody3D`) | Movimiento relativo a la cámara, gravedad, giro suave; el modelo es un `BattleActor` (`look = HERO`) hijo, sin duplicar la construcción de mallas. Modo autoplay que sigue una lista de puntos | `BattleActor` |
| `scripts/world/follow_camera.gd` (`FollowCamera`, `Camera3D`) | Sigue a un objetivo con suavizado a distancia/altura fijas; Q/E rotan; `snap()` coloca la cámara sin suavizado | — |

Modificados:

| Archivo | Cambio |
|---|---|
| `scripts/battle/battle_scene.gd` | `setup(hero, enemy_data)` antes de entrar al árbol; señal `finished(won: bool)`; monta un único combate (sin `_start_battle` repetido, sin arrastre de EXP, sin reinicio). Autoplay: elige Atacar y emite `finished` 2 s después del resultado |
| `scripts/ui/battle_result.gd` | Botón "Continuar"; señal `continue_requested` (sustituye a `retry_requested`) |
| `scripts/battle/battle_stage.gd` | Extrae `static build_environment(root)` (cielo, entorno, sol) de `build()`; `build()` la llama |
| `project.godot` | `run/main_scene` = `res://scenes/game/game.tscn` |
| `CLAUDE.md` | Layout nuevo, comandos nuevos y la nota de convenciones pendiente (ver Documentación) |

`BattleEngine`, `BattleEvent`, `Combatant`, `BattleActor` y `BattleHud` no cambian.

## Flujo

```
Game._ready: GameState.new(hero.tres) → World (activo) → status con PV/EXP
World: Player anda → EncounterMeter.advance(metros, en_hierba) → true → encounter_triggered
Game: fundido a negro → World.set_active(false) → BattleScene.setup(state.hero, slime.tres) → add_child → quitar fundido
BattleScene: combate → resultado → "Continuar" (o autoplay) → finished(won)
Game: fundido → liberar BattleScene →
      won:  World.set_active(true)
      lost: state.heal_full() → World.respawn() → World.set_active(true) → aviso "Has vuelto al inicio"
      → World.refresh_status(state.hero) → quitar fundido
```

- El mapa nunca se destruye: posición, orientación de la cámara y contador de encuentros se conservan solos.
- `World.set_active(false)`: `process_mode = PROCESS_MODE_DISABLED`, `hide()`, la cámara del mapa deja de ser `current` y se oculta la ventana de estado. `set_active(true)` lo revierte, hace `current` la cámara del mapa y reinicia la gracia del `EncounterMeter`.
- El combate usa **el mismo** `Combatant` del `GameState` (no una copia): el motor ya modifica PV y suma EXP sobre él, así que al volver el estado está al día. El enemigo sí se duplica en `setup`.
- `World.respawn()`: coloca al jugador en `WorldStage.SPAWN_POS` mirando al camino, `FollowCamera.snap()`, `EncounterMeter.reset()`.
- Fundido: un `ColorRect` negro a pantalla completa en un `CanvasLayer` alto de `Game`; tween de alfa de 0,3 s en cada sentido (se espera con `await`).

### API

```gdscript
# GameState
var state := GameState.new(preload("res://data/hero.tres"))
state.hero            # Combatant persistente
state.heal_full()     # hp = max_hp

# EncounterMeter
var meter := EncounterMeter.new(rng)
meter.advance(0.08, true)   # metros recorridos este frame, ¿en hierba? → true = combate
meter.reset()               # vuelve a dar la gracia

# BattleScene
var battle: BattleScene = BATTLE_SCENE.instantiate()
battle.setup(state.hero, preload("res://data/slime.tres"))
add_child(battle)
var won: bool = await battle.finished
```

`BattleScene` pasa a tener `class_name BattleScene` para tipar la API.

## Reglas

### Movimiento (`Player`)

- Velocidad 5 m/s; dirección = entrada WASD/flechas proyectada sobre el plano horizontal de la cámara.
- El modelo gira suavemente hacia la dirección de marcha (interpolación de ángulo, ~10 rad/s).
- Gravedad estándar del proyecto; `move_and_slide()` contra suelo, rocas y bordes.
- Andando, el `BattleActor` hijo hace un leve balanceo vertical (tween); parado, vuelve a reposo.
- Expone los metros horizontales recorridos en el último frame (`last_step_m`) para el `EncounterMeter`.
- Autoplay: recorre en bucle una lista fija de puntos (`AUTOPLAY_ROUTE`, mayoritariamente en hierba), como si se pulsara la dirección hacia el siguiente punto.

### Cámara (`FollowCamera`)

- Distancia horizontal 6 m, altura 3,5 m sobre el objetivo, mira a 1 m por encima del objetivo.
- Sigue con suavizado exponencial (factor ~6/s) en posición; el ángulo (yaw) solo cambia con Q/E, a 120 °/s.
- `snap()` coloca la cámara en su sitio sin suavizado (al empezar y al reaparecer).

### Mapa (`WorldStage`)

- Campo de unos 60 × 60 m centrado en el origen, hierba (`GRASS` de `BattleStage`).
- Camino de tierra de unos 3 m de ancho desde `SPAWN_POS` (borde sur, ~`(0, 0, 26)`) hasta un claro circular de ~8 m de radio en `CLEARING_POS` (borde norte, ~`(0, 0, -22)`), con una curva suave formada por 3–4 tramos rectos. El claro es tierra y está vacío (reservado para el hub del sub-proyecto 3).
- `is_on_path(pos)`: distancia horizontal a cualquier tramo < medio ancho, o dentro del claro, o dentro de un radio de 4 m de `SPAWN_POS`.
- 8–12 rocas dispersas por la hierba con `StaticBody3D` + `CollisionShape3D` (esfera escalada → caja o cápsula aproximada).
- Borde: colinas grandes semienterradas fuera del cuadrado (decorado) y cuatro `StaticBody3D` con `WorldBoundaryShape3D` o cajas invisibles en los lados.
- Suelo con `StaticBody3D` + `WorldBoundaryShape3D` (plano infinito) o una caja fina.
- Entorno y sol: `BattleStage.build_environment(root)` (mismo cielo, niebla y luz que el combate).

### Encuentros (`EncounterMeter`)

- `GRACE_M = 5.0`: tras `reset()` (inicio, vuelta de un combate, reaparición) los primeros 5 m en hierba no cuentan.
- `CHANCE_PER_M = 0.08`: pasada la gracia, por cada metro completo andado en hierba se tira `rng.randf() < 0.08`. Media ≈ 12,5 m entre combates tras la gracia.
- Los metros en el camino no cuentan ni consumen gracia.
- El meter acumula fracciones de metro entre frames; si salta combate, devuelve `true` una vez y el `World` emite `encounter_triggered` (que deja de mover al jugador hasta que `Game` lo desactive).
- Enemigo: siempre `slime.tres` en este sub-proyecto.

### Fin del combate

- Victoria: se vuelve al mismo punto; PV los que queden, EXP sumada.
- Derrota: se vuelve a `SPAWN_POS` con PV completos y la misma EXP; la ventana de estado muestra "Has vuelto al inicio." durante ~2 s.

## Presentación

- Ventana de estado del mapa (arriba a la izquierda, mismo estilo `BattleHud.make_window()`): nombre, `PV a / b`, `EXP n`.
- El combate se ve exactamente como ahora (su propio escenario, cámara y HUD). Solo cambia el botón del resultado a "Continuar".
- Mensaje de inicio de combate sin cambios ("¡Un Slime salvaje aparece!").

## Verificación (sin tests)

No se escriben tests unitarios ni automatizados. Por tarea:

- `.\tools\godot.cmd --headless --path . --import` tras crear scripts con `class_name`, y `--check-only` de cada script nuevo o cambiado, sin `ERROR` / `SCRIPT ERROR` / `Parse Error`.
- Mundo solo: `.\tools\godot.cmd --path . res://scenes/world/world.tscn -- --autoplay` y grabación de fotogramas (`--write-movie`) para ver al héroe andar por el campo, la cámara siguiéndolo y el escenario.
- Bucle completo: `.\tools\godot.cmd --path . -- --autoplay` y grabación de fotogramas suficientes para ver mapa → fundido → combate → "Continuar" → vuelta al mapa en el mismo sitio, con PV/EXP actualizados en la ventana de estado. Leer toda la salida de consola: sin `ERROR` ni `WARNING`.
- Prueba manual del usuario: andar con WASD/flechas, girar con Q/E, comprobar que el camino es seguro, ganar y perder combates (perder vuelve al inicio curado).

## Orden de implementación

1. **Reglas puras**: `GameState`, `EncounterMeter`. Sin dependencias; se validan con `--check-only`.
2. **Combate reutilizable**: `BattleScene.setup`/`finished`, `BattleResult` "Continuar", `BattleStage.build_environment`. En esta tarea se crea `Game` en su forma mínima (con `GameState`, encadena combates: al terminar uno, crea otro; la derrota cura) y pasa a ser la escena principal, para que el juego siga jugable sin escena de prueba temporal.
3. **Mundo andable**: `WorldStage`, `Player`, `FollowCamera`, `World` (todavía sin conectar encuentros a `Game`). Se verifica lanzando `world.tscn` directamente.
4. **Bucle completo**: `Game` crea el `World`, conecta `encounter_triggered`, fundidos, victoria/derrota con reaparición y ventana de estado. Verificación con autoplay y fotogramas; después prueba manual del usuario.
5. **Documentación y merge**: `CLAUDE.md` y merge a `develop` con `--no-ff`.

Rama: `feature/mundo-exploracion`.

## Documentación

`CLAUDE.md` se actualiza con:
- Layout: `Game` como escena principal y su flujo; `World`, `WorldStage`, `Player`, `FollowCamera`, `GameState`, `EncounterMeter`; `BattleScene` como escena que se instancia con `setup` y emite `finished`.
- Comandos: lanzar el mundo solo (`res://scenes/world/world.tscn`) y el autoplay del bucle completo.
- Convenciones (pendientes desde el primer spec): escenas y scripts escritos como texto; los `.tscn` solo llevan el nodo raíz y su script, el resto se crea por código; lógica de reglas en clases puras (`RefCounted`/`Resource`) que no tocan nodos; sin autoloads (el estado lo tiene `Game` y lo pasa explícitamente); si algún día hay autoloads, un script con `class_name` nunca usa su nombre a pelo (compila antes de que existan los autoloads, p. ej. en ejecuciones `--script`); se busca en tiempo de ejecución con `get_node_or_null("/root/...")`.

## Criterios de terminado

- `.\tools\godot.cmd --path .` abre el mapa; se anda, se gira la cámara y salen combates solo en la hierba.
- Tras ganar se vuelve al mismo sitio con PV/EXP actualizados; tras perder se vuelve al inicio curado con la EXP intacta.
- El autoplay recorre el mapa y encadena combates sin errores en la salida de Godot.
- Trabajo commiteado en `feature/mundo-exploracion` y mergeado a `develop` con `--no-ff`.

## Fuera de alcance

Niveles, PM, habilidades, objetos e IA de enemigo (sub-proyecto 2); NPC, hub, misión y jefe (sub-proyecto 3); guardado en disco; menú de pausa o de estado; minimapa; huir del combate; varios tipos de enemigo; modelos o animaciones reales; sonido; mando; rotación de cámara con ratón.
