# Hub, NPC, misión y jefe — diseño

Fecha: 2026-11-03
Paso: sub-proyecto 3 de 3 del vertical slice (hoja de ruta en `2026-11-02-mundo-exploracion-design.md`)

## Objetivo

Cerrar el vertical slice con un objetivo de juego: el claro del norte pasa a ser el pueblo **Villaclaro**, con una **anciana** que cura al hablar con ella y encarga la misión **"derrota 3 slimes"**. Al entregarla da 2 pociones y aparece el **Rey Slime** al norte del pueblo, un jefe con una habilidad especial. Derrotarlo completa la misión.

## Decisiones tomadas

El usuario pidió que no se le pregunte; todas son la opción recomendada.

| Tema | Decisión |
|---|---|
| Pueblo | En el claro: 2 casas (caja + tejado prisma) con colisión, un pozo; sin encuentros (el claro ya es zona segura) |
| NPC | Una anciana (`BattleActor` con look nuevo `VILLAGER`), quieta, con colisión |
| Hablar | A menos de 2,5 m sale "Enter: hablar"; Enter / Espacio (`ui_accept`) abre el diálogo. E no sirve: ya gira la cámara |
| Curación | Hablar con la anciana siempre cura PV y PM del todo |
| Misión | Etapas `OFFER → HUNT → REPORT → BOSS → DONE`; solo cuentan slimes derrotados durante `HUNT` |
| Recompensa | 2 pociones al entregar los 3 slimes |
| Jefe | Rey Slime: aparece al entregar la misión, en el borde norte del claro; tocarlo (≤ 2,5 m) empieza el combate |
| Habilidad del jefe | "Aplastar": 4 PM, poder 12, ignora DEF (misma regla que Llama); tiene 12 PM, así que 3 usos como mucho |
| Derrota contra el jefe | Igual que siempre: vuelta al inicio curado; el jefe sigue ahí |
| Victoria contra el jefe | Desaparece del mapa, misión `DONE`, aviso "¡Villaclaro está a salvo!"; se puede seguir jugando |
| Arquitectura | La misión es una clase pura (`Quest`) dentro de `GameState`; `World` solo avisa de que se quiere hablar o de que se toca al jefe, y `Game` decide |

## Reglas de la misión (`Quest`, `RefCounted`)

- `stage` empieza en `OFFER`, `kills` en 0. `GOAL = 3`, `REWARD_POTIONS = 2`, `TARGET_ID = "slime"`, `BOSS_ID = "rey_slime"`.
- `on_victory(enemy_id)`:
  - en `HUNT` con `TARGET_ID`: `kills += 1`; al llegar a `GOAL`, pasa a `REPORT`;
  - en `BOSS` con `BOSS_ID`: pasa a `DONE`;
  - en cualquier otro caso no hace nada.
- `talk() -> Dictionary` con `lines: Array[String]` y `potions: int` (pociones a dar). Cambia de etapa así:

| Etapa al hablar | Líneas | Pociones | Etapa después |
|---|---|---|---|
| `OFFER` | "¡Bienvenido a Villaclaro, viajero!" / "Los slimes no dejan salir a nadie del pueblo." / "¿Podrías derrotar a 3 de ellos?" | 0 | `HUNT` |
| `HUNT` | "Llevas %d de 3 slimes. ¡Ánimo!" | 0 | `HUNT` |
| `REPORT` | "¡Lo has conseguido! Toma, 2 pociones." / "Pero el Rey Slime ha llegado al norte del pueblo..." / "¡Derrótalo, por favor!" | 2 | `BOSS` |
| `BOSS` | "El Rey Slime espera al norte del pueblo." | 0 | `BOSS` |
| `DONE` | "¡Gracias, héroe! Villaclaro está a salvo." | 0 | `DONE` |

- `boss_available()`: `stage == BOSS`.
- `status_text()` para la ventana del mapa: `OFFER` "Misión: habla con la anciana", `HUNT` "Misión: slimes %d / 3", `REPORT` "Misión: vuelve con la anciana", `BOSS` "Misión: derrota al Rey Slime", `DONE` "Misión cumplida".
- `Game` añade siempre al final del diálogo "Descansas un momento. PV y PM recuperados." y aplica `heal_full()` y las pociones.

## Datos

- `Combatant` gana `id: String` y `is_boss: bool`. `slime.tres`: `id = "slime"`. `hero.tres`: `id = "hero"`.
- `Skill` gana `color: Color` (por defecto el naranja de fuego actual, `Color(1.0, 0.45, 0.1)`); `play_burn` usa el color de la habilidad. `llama.tres` no cambia.
- `data/skills/aplastar.tres`: `id = "aplastar"`, "Aplastar", 4 PM, poder 12, color `Color(1.0, 0.85, 0.3)`.
- `data/rey_slime.tres`: `id = "rey_slime"`, "Rey Slime", `is_boss = true`, PV 70, PM 12, ATK 12, DEF 6, VEL 6, EXP 30, `skills = [aplastar]`, `ai_weights = {"attack": 60, "aplastar": 30, "stagger": 10}`, `potion_drop_chance = 0`.
- Equilibrio esperado: tras la misión el héroe está en nivel 2–3 (PV 35–40) con hasta 5 pociones. El jefe hace ~8 por golpe y ~12 con Aplastar, y aguanta 5–6 rondas: se gana usando pociones, se pierde si no.

## Combate

- `BattleScene` elige el aspecto del enemigo: `KING_SLIME` si `enemy.is_boss`, si no `SLIME`.
- Mensaje de entrada del jefe: "¡El %s te cierra el paso!" (el resto, "¡Un %s salvaje aparece!" como ahora).
- `BattleEngine` casi no cambia: la IA ponderada y las habilidades del enemigo ya existen (una habilidad sin PM se convierte en ataque). Solo pasa `skill.color` al evento SKILL (`BattleEvent.skill(..., color)`), y `BattleScene` usa ese color en `play_cast` y en el `play_burn` del daño que sigue.
- `BattleActor`: looks nuevos `VILLAGER` (como el héroe pero túnica morada, pelo blanco, bastón en lugar de espada; sin bote) y `KING_SLIME` (slime a escala 1,6 con corona dorada de cilindro y conos; bota como el slime). `play_burn(amount, color)` recibe el color.

## Mapa

- `WorldStage` añade el pueblo: casas en `(-5.5, 0, -25)` y `(5.5, 0, -25)` (3 × 2,5 × 3 m, pared crema, tejado rojo, `StaticBody3D` con caja), pozo en `(4.5, 0, -19)` (cilindro de piedra, colisión). Constantes `NPC_POS = (-2.5, 0, -20)` y `BOSS_POS = (0, 0, -27.5)`.
- `World` crea la anciana (mirando al sur) y el Rey Slime (oculto hasta `set_boss_present(true)`), cada uno con un `StaticBody3D` cilíndrico. El jefe oculto desactiva su colisión.
- Señales de `World`: `encounter_triggered(boss: bool)` (antes sin argumentos) y `talk_requested`.
- Hablar: si el jugador está a ≤ `TALK_RADIUS = 2.5` m de la anciana y nada lo bloquea, se ve el aviso "Enter: hablar" abajo en el centro; `ui_accept` emite `talk_requested`.
- Jefe: con el jefe presente, a ≤ `BOSS_RADIUS = 2.5` m se emite `encounter_triggered(true)` y se congela al jugador como en un encuentro normal.
- `await show_dialogue(lines)`: congela al jugador, muestra un `DialogueBox` y lo vuelve a soltar al acabar.
- `refresh_status(hero, potions, quest_text)`: nueva línea con el texto de la misión (vacía en el mapa suelto).
- El mapa suelto (`world.tscn`) contesta a `talk_requested` con un diálogo de una línea "Hola, viajero." y no muestra jefe.

## Diálogo (`DialogueBox`)

- `scripts/ui/dialogue_box.gd`, ventana `BattleHud.make_window()` abajo, ancho casi completo, con el nombre "Anciana" arriba y la línea debajo.
- `await say(speaker, lines)`: una línea cada vez; avanza con `ui_accept` o clic. Ignora la pulsación que abrió el diálogo (espera un frame antes de escuchar). Con `--autoplay` avanza solo cada 0,8 s e imprime cada línea.

## Autoplay

- `Player.AUTOPLAY_ROUTE` pasa por el pueblo en cada vuelta: tras `(10, 0, -6)` va a `(1, 0, -14)`, `(-1.5, 0, -18)` (dentro del radio de la anciana), `(0, 0, -25.5)` (dentro del radio del jefe), `(2, 0, -14)` y sigue con `(-6, 0, -4)`.
- Con `--autoplay`, `World` emite `talk_requested` al entrar en el radio de la anciana (una vez por entrada).
- Así una partida en autoplay recorre la misión entera: oferta, caza, entrega, jefe (gane o pierda) y vuelta a empezar.

## Verificación (sin tests)

- `--check-only` en los scripts tocados; `--import` tras añadir `Quest` y `DialogueBox`.
- Autoplay con salida: se ven las líneas de la anciana, "Misión" avanzando, "¡El Rey Slime te cierra el paso!" y "Aplastar".
- Fotogramas con `--write-movie`: pueblo, anciana, aviso "Enter: hablar", diálogo, jefe en el mapa y en combate.
- Exportación web sin errores.

## Fuera de alcance

Varios NPC, tienda, guardado, diálogos con opciones, más misiones, música, pantalla de créditos o final, huir del combate.

## Otros cambios

- `CLAUDE.md`: actualizar el Layout y quitar "No remote yet" (ya existe el remote `RPG` en GitHub, con despliegue en Pages desde `main`).
