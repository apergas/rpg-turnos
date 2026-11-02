# Prototipo de combate por turnos — diseño

Fecha: 2026-11-02
Proyecto: `rpg-turnos` (RPG 3D por turnos, estilo visual Dragon Quest)
Paso: 1 de la hoja de ruta (prototipo de combate con placeholders)

## Objetivo

Un combate jugable de **un héroe contra un slime**, por **rondas al estilo Dragon Quest**, con cámara en **tercera persona en diagonal** y una sola acción: **Atacar**. Sirve para validar el flujo de combate y la arquitectura antes de añadir progresión, habilidades, mapa o modelos reales.

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Turnos | Por rondas: el héroe elige su orden, luego la ronda se ejecuta ordenada por iniciativa |
| Grupo | Solo el héroe (sin compañeros) |
| Cámara | 3ª persona, detrás y por encima del héroe, en diagonal |
| Acciones | Solo "Atacar" |
| Arquitectura | Lógica pura (`BattleEngine`) separada de la presentación (`BattleScene`) |

## Proyecto

- Ruta: `C:\Users\peixe\Documents\rpg-turnos`.
- Godot **4.7.2**, renderizador **Forward+**, física 3D **Jolt**.
- Ventana base 1280×720, stretch `canvas_items` / aspect `expand`.
- Tooling copiado de `godot-example` (git-ignorado en `tools/`): `tools\godot.cmd`, Node portable, servidor MCP de Godot; `.mcp.json` registra el MCP con `GODOT_PATH` al exe de consola 4.7.2.
- **Sin tests unitarios ni automatizados**, en ningún momento del proyecto (decisión del usuario, prevalece sobre cualquier skill que pida TDD o tests). La verificación es manual: ejecutar el juego y comprobarlo visualmente.
- Git local con gitflow: `main`, `develop`, trabajo en `feature/<nombre>` mergeado con `--no-ff` a `develop`. Sin remoto por ahora.
- `CLAUDE.md` propio describiendo proyecto, layout, comandos y convenciones (mismas notas que `godot-example`: scripts y escenas escritos como texto, autoloads no usados desde scripts `class_name`, etc.).

## Componentes

| Archivo | Responsabilidad | Depende de |
|---|---|---|
| `scripts/battle/combatant.gd` (`Combatant`, `Resource`) | Datos de un luchador: `display_name`, `max_hp`, `hp`, `attack`, `defense`, `speed`, `exp_reward`, `exp` (acumulada; solo se usa en el héroe) | — |
| `data/hero.tres`, `data/slime.tres` | Estadísticas iniciales (ver Reglas) | `Combatant` |
| `scripts/battle/battle_event.gd` (`BattleEvent`) | Constantes de tipo y constructores de eventos (diccionarios) | — |
| `scripts/battle/battle_engine.gd` (`BattleEngine`, `RefCounted`) | Resuelve rondas y devuelve eventos; no toca nodos | `Combatant`, `BattleEvent`, `RandomNumberGenerator` |
| `scenes/battle/battle_scene.tscn` + `scripts/battle/battle_scene.gd` | Escena principal: monta escenario y actores, pide la orden al HUD, llama al motor, reproduce eventos en cola con `await` | `BattleEngine`, `BattleActor`, `BattleHud`, `BattleResult` |
| `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` (`BattleActor`, `Node3D`) | Representación 3D de un combatiente con primitivas; animaciones por tween | — |
| `scenes/ui/battle_hud.tscn` + `scripts/ui/battle_hud.gd` (`BattleHud`) | Ventana de mensajes, panel de PV del héroe, menú de comandos | — |
| `scenes/ui/battle_result.tscn` + `scripts/ui/battle_result.gd` (`BattleResult`) | Resultado de victoria/derrota y botón "Luchar otra vez" | — |

Flujo: **HUD emite orden → `BattleEngine.resolve_round(order)` → `BattleScene` reproduce los eventos → vuelve a mostrar el menú** (o el resultado si terminó). El motor nunca toca nodos; la escena nunca calcula daño.

### API del motor

```gdscript
var engine := BattleEngine.new(hero: Combatant, enemy: Combatant, rng: RandomNumberGenerator)
var events: Array[Dictionary] = engine.resolve_round(BattleEngine.CMD_ATTACK)
engine.state  # ONGOING, WON o LOST
```

El motor modifica directamente los `Combatant` que recibe. La escena, al empezar cada combate, crea copias (`duplicate()`) de `hero.tres` y `slime.tres` y traslada a la copia nueva del héroe la `exp` acumulada en combates anteriores; así los `.tres` nunca se alteran. Al ganar, el motor suma `exp_reward` del enemigo a `exp` del héroe. En este paso la EXP vive solo en memoria (no se guarda en disco).

### Eventos

Cada evento es un `Dictionary` con `type` y campos:

| `type` | Campos |
|---|---|
| `attack` | `actor`, `target` (`"hero"` / `"enemy"`) |
| `miss` | `actor`, `target` |
| `damage` | `target`, `amount`, `crit` (bool), `hp_left` |
| `defeated` | `target` |
| `victory` | `exp` |
| `defeat` | — |

Secuencia por acción: `attack` seguido de `miss` o de `damage` (y `defeated` si `hp_left == 0`). Al final de la ronda, si el combate terminó: `victory` o `defeat`.

## Reglas

Estadísticas iniciales:

| | PV | ATQ | DEF | VEL | EXP |
|---|---|---|---|---|---|
| Héroe | 30 | 12 | 6 | 8 | — |
| Slime | 24 | 7 | 3 | 5 | 4 |

Ronda:

1. El héroe da su orden (`CMD_ATTACK`); el slime siempre ataca.
2. Iniciativa de cada uno: `speed × rng.randf_range(0.5, 1.5)` (con ±20 % el héroe, VEL 8, nunca perdería contra VEL 5; con ±50 % el slime se adelanta a veces). Actúa primero la mayor; en empate exacto, el héroe.
3. Ataque:
   - 5 % de fallo (`rng.randf() < 0.05`) → evento `miss`.
   - Si no falla, 1/16 de crítico (`rng.randf() < 1.0 / 16.0`): daño = `round(attack × 1.5 × rng.randf_range(0.875, 1.125))`, ignora la defensa.
   - Normal: daño = `round(max(1.0, attack − defense / 2.0) × rng.randf_range(0.875, 1.125))`.
   - El daño mínimo final es 1. Los PV no bajan de 0.
4. Un combatiente con 0 PV no actúa; la ronda acaba en cuanto uno cae.

Fin: si el enemigo cae → `WON`, evento `victory{exp}` y EXP sumada al héroe. Si el héroe cae → `LOST`, evento `defeat`. Llamar a `resolve_round` con el combate terminado devuelve un array vacío.

Todo el azar sale del `RandomNumberGenerator` inyectado; en el juego se usa `rng.randomize()`.

## Presentación

Escenario (solo primitivas):
- Suelo: `PlaneMesh` grande verde hierba; un camino de tierra (plano más claro, ligeramente elevado) entre héroe y slime.
- Fondo: rocas (cubos/esferas grises escalados irregularmente) y colinas (esferas grandes semienterradas, verde más oscuro).
- `WorldEnvironment`: `ProceduralSkyMaterial`, niebla de distancia, glow suave, SSAO, tonemap filmic/ACES.
- `DirectionalLight3D` cálida de tarde, con sombras.

Actores (`BattleActor` con una propiedad `look` que elige forma):
- Héroe: cápsula roja (cuerpo), esfera color carne (cabeza), caja fina gris (espada). De espaldas en diagonal, primer plano a la izquierda.
- Slime: esfera aplastada morada, dos esferas blancas con pupila negra como ojos. Bucle de rebote (tween de escala), unos 4–5 m frente al héroe.

Cámara: `Camera3D` detrás y por encima del héroe, en diagonal, mirando al slime. Al atacar, acerca un poco el encuadre al objetivo y vuelve; en crítico, sacudida breve.

Animaciones (`BattleActor`, todas se pueden esperar con `await`):

| Método | Efecto |
|---|---|
| `play_attack(target_pos)` | Avanza hacia el rival y vuelve |
| `play_hit(amount, crit)` | Parpadeo blanco, empujón atrás, `Label3D` flotante (blanco; amarillo y mayor en crítico) |
| `play_dodge()` | Paso lateral y vuelta |
| `play_defeat()` | Se encoge y desvanece |

HUD (estilo DQ, parte inferior):
- Ventana de mensajes: panel oscuro con borde blanco, texto letra a letra. Avanza con clic, Enter o auto-avance (≈0,6 s tras completar). Mensajes: "¡El héroe ataca!", "¡El slime recibe 11 de daño!", "¡Golpe crítico!", "¡Pero falla!", "¡El slime ha sido derrotado!", "¡Has sido derrotado…!".
- Panel del héroe: nombre, `PV actual/máx` y barra.
- Menú de comandos: solo "Atacar" (ratón, Enter o Espacio). Oculto mientras se reproducen eventos. Señal `command_chosen(cmd)`.
- `BattleResult`: overlay con "¡Victoria! +4 EXP (total N)" o "Has sido derrotado", botón "Luchar otra vez" que reinicia el combate con PV llenos (la EXP del héroe se conserva).

## Verificación (sin tests)

No se escriben tests unitarios ni automatizados. Se verifica a mano:

- Validar cada script con `.\tools\godot.cmd --headless --path . --check-only --script <ruta>` y que el proyecto arranque sin errores en la salida.
- Ejecutar el juego (con el MCP de Godot o `.\tools\godot.cmd --path .`), jugar varios combates y capturar pantalla para revisar cámara, luz, animaciones, mensajes, victoria, derrota y "Luchar otra vez".

## Criterios de terminado

- `.\tools\godot.cmd --path .` abre directamente el combate (`run/main_scene` = `battle_scene.tscn`).
- Se puede pulsar "Atacar" hasta ganar o perder; "Luchar otra vez" reinicia.
- El juego arranca y se juega sin errores en la salida de Godot.
- Trabajo commiteado en `feature/combate-prototipo` y mergeado a `develop` con `--no-ff`.

## Fuera de alcance

Niveles y reparto de puntos, habilidades/PM, objetos, huir, varios enemigos, mapa y encuentros aleatorios, editor de personaje, modelos/animaciones reales, sonido, guardado en disco, remoto de GitHub y despliegue web.
