# Combate completo: diseño

Fecha: 2026-11-03
Paso: fase 3 de `2026-11-03-ideas-juego-completo.md`. Incluye la idea suelta de controlar el combate con WASD (`ideas-sueltas.md`).

## Objetivo

Cerrar el sistema de combate con las cifras de equilibrio del listado de ideas:

- **Órdenes nuevas:** Defender y Huir.
- **Menús** de hechizos y de objetos.
- **Combates contra 1 o 2 enemigos**, eligiendo el objetivo.
- **Elementos y estados alterados.**
- **Progresión nueva:** la nueva tabla de EXP y el nuevo crecimiento del héroe.
- **Encuentros** con la nueva frecuencia.
- **Teclado completo:** todo el combate se maneja con WASD además de con las flechas.

Esta fase solo cubre la **zona 1**: la pradera y el Rey Slime. Las zonas 2 a 4 llegan en la fase de mundo, con el mismo sistema.

## Decisiones tomadas

El usuario pidió que no se le pregunte, así que todas son la opción recomendada. Las cifras vienen de la sección "Equilibrio" de `2026-11-03-ideas-juego-completo.md`.

| Tema | Decisión |
|---|---|
| Menú principal | **Atacar · Hechizos · Objetos · Defender · Huir**. Hechizos y Objetos abren una lista; Esc / X / clic fuera vuelve atrás |
| Teclado | **W/S o ↑/↓** mueven el cursor. **A/D o ←/→** eligen el objetivo cuando hay que elegirlo. **Enter / Espacio / E** aceptan y **Esc / Q / Retroceso** cancelan. Ratón y toque funcionan igual que ahora |
| Elegir objetivo | Con dos enemigos vivos, Atacar y los hechizos de un objetivo piden elegir: una flecha parpadea sobre el enemigo; A/D o clic la cambian y Enter, o un segundo clic, confirma. Con uno solo no se pregunta |
| Defender | El daño recibido esa ronda baja a la mitad (redondeando hacia arriba, mínimo 1) y el héroe actúa primero esa ronda |
| Huir | Probabilidad `clamp(0.5 + (VEL héroe − VEL media enemigos) × 0.05, 0.2, 0.95)`. Contra jefes no se puede: sale "¡No puedes huir!" y no se pierde el turno. Si falla, los enemigos atacan. Si sale bien, no se gana EXP y se vuelve al mapa con la gracia de encuentros |
| Hechizos del héroe | **Llama** (Nv 1, 3 PM, 16, fuego, un objetivo) · **Curar** (Nv 3, 3 PM, cura 30) · **Llamarada** (Nv 7, 6 PM, 28, fuego, todos) · **Rayo** (Nv 10, 8 PM, 70, rayo, uno) · **Curar+** (Nv 11, 7 PM, cura 90). Se aprenden al subir de nivel, con el mensaje "¡Héroe aprende Curar!" |
| Elementos | `fire`, `ice` y `thunder` (más ninguno). Cada enemigo tiene `weak` (×1,5) y `resist` (×0,5). El número de daño muestra "¡Débil!" o "¡Resiste!" y el mensaje lo dice |
| Estados | **Veneno** (pierde un 8 % de los PV máximos al final de cada ronda; se cura al acabar el combate o con Antídoto), **Sueño** (pierde el turno; cada ronda tiene un 50 % de despertar, y despierta seguro al recibir daño) y **Silencio** (no puede lanzar hechizos durante 3 rondas). Iconos en el HUD junto a los PV. Los enemigos también pueden sufrirlos, pero el héroe no tiene hechizos de estado en esta fase |
| Objetos | **Poción** (cura 30, precio 8 G; sube de 25 a 30 por el equilibrio), **Éter** (+15 PM), **Antídoto** (quita el veneno). En combate gastan el turno; fuera de combate se usan desde el menú de pausa de la fase 2. Al mismo tiempo, la poción deja de estar desactivada con los PV llenos si el menú es de objetos: el objeto se marca en gris con el motivo |
| Progresión | Base del héroe a Nv 1: PV 30 · PM 6 · ATK 10 · DEF 5 · VEL 8, más el equipo inicial (Palo +2 ATK, Ropa +2 DEF), así que queda igual que ahora: ATK 12, DEF 7. Por nivel: PV +6 · PM +3 · ATK +2 · DEF +1 · VEL +1. Tabla de EXP hasta Nv 20 del listado. `Leveling` usa estas tablas; el equipo como sistema llega en la fase 4, aquí son dos bonificaciones fijas en `hero.tres` |
| Enemigos de la zona 1 | **Slime** (24 PV, ATK 7, DEF 3, VEL 5, 4 EXP, 3 G; débil a fuego) · **Murciélago** (26, 12, 2, 12, 5 EXP, 4 G; débil a rayo; 20 % de morder con veneno) · **Seta saltarina** (43, 11, 5, 4, 6 EXP, 5 G; Esporas: 2 PM, 10 de daño y 30 % de dormir; débil a fuego). El oro se acumula en el `GameState` aunque las tiendas lleguen en la fase 4 |
| Formaciones | Cerca del inicio (a menos de 20 m de `SPAWN_POS`) solo salen slimes, solos o en pareja. En el resto: `[Slime]`, `[Slime]`, `[Murciélago]`, `[Seta]`, `[Slime, Slime]` y `[Slime, Murciélago]`, todas con el mismo peso |
| Rey Slime | 142 PV, 12 PM, ATK 17, DEF 8, VEL 7, Aplastar 19 de daño, 40 EXP, 60 G. Débil a rayo. **Pide ayuda**: con menos del 50 % de PV, una vez por combate, llama a un slime |
| Encuentros | 15 m de gracia y **0,6 % por metro** de hierba (antes, 5 m y 8 %) |
| Botín | Cada enemigo tiene una tabla de objetos con su probabilidad: Slime (poción 20 %), Murciélago (antídoto 15 %), Seta (éter 10 %) |
| Pantalla | Con dos enemigos, se colocan separados a izquierda y derecha. La cámara de combate no cambia |
| Mensajes | Todo pasa por `_say()`, como ahora. Los mensajes nuevos van en español, al estilo de los actuales ("¡El Murciélago te muerde! ¡Estás envenenado!") |
| Equilibrio | Al acabar, se repite el simulador del listado (herramienta local, fuera del repositorio) con las reglas reales de esta fase: veneno, sueño, Defender y debilidades. Si algún objetivo se desvía más de 5 puntos, se ajustan los números de los enemigos y se anota |

## Arquitectura

- **`BattleEngine`:**
  - Pasa a manejar `Array[Combatant]` de enemigos, y las órdenes llevan objetivo: `cmd_attack(target)`, `cmd_skill(skill, target)`, `cmd_item(id)`, `cmd_defend()`, `cmd_flee()`.
  - Los eventos nuevos (`DEFEND`, `FLEE_OK`, `FLEE_FAIL`, `STATUS_ON`, `STATUS_TICK`, `STATUS_OFF`, `ASLEEP`, `LEARN`, `CALL_HELP`, `GOLD`) se crean en `BattleEvent`.
  - Sigue siendo puro: nunca toca nodos.
- **`Combatant`:** gana `weak: Array[String]`, `resist: Array[String]`, `gold_reward`, `drops: Dictionary` (id → probabilidad), `status: Dictionary` (estado → rondas, solo durante el combate) y `learn: Dictionary` (nivel → hechizo, solo el héroe).
- **`Skill`:** gana `element`, `kind` (`damage`, `heal` o `status`), `targets` (`one` o `all`), `status` y `status_chance`.
- **`Inventory`:** los objetos se describen en una tabla `ITEMS` (nombre, efecto, valor, precio, si se puede usar en combate y fuera de él). `use(id, combatant) -> Dictionary` aplica el efecto y devuelve el resultado, y así lo comparten el combate y el menú de pausa.
- **`EncounterTable` (nueva, `RefCounted`):** formaciones por zona y la regla de "cerca del inicio".
- **`BattleScene`:**
  - Varios `BattleActor` enemigos, la flecha de objetivo y la reproducción de los eventos nuevos.
  - `BattleHud` gana los submenús, la elección de objetivo, la navegación WASD completa y los iconos de estado.
- **Autoplay:**
  - Elige hechizos por debilidad y se cura con Curar.
  - Defiende con PV bajos si no le quedan curaciones.
  - Huye una vez de cada cinco en combates normales, para probar Huir.

## Verificación (sin tests)

- `--check-only` en los scripts tocados.
- **Autoplay completo:** la misión con los mensajes nuevos (Defender, Huir, veneno, sueño, "¡Débil!", "aprende Curar") y sin ERROR ni WARNING.
- **Fotogramas:** combate contra 2 enemigos, flecha de objetivo, submenú de hechizos e iconos de estado.
- **Simulador de equilibrio:** los resultados se anotan en el informe.
- **Versión web:** se exporta.

## Fuera de alcance

- Tiendas y equipo (fase 4).
- Zonas 2 a 4 y sus enemigos (fase 5).
- Velocidad de combate configurable (fase 7, en Opciones).
