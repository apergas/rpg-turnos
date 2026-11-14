# Versión 2.7.0: partida nueva de verdad, bestiario en tres estados y Sanación compartida

Fecha: 2026-11-14. Estado: spec, pendiente de revisión. Va antes de la v3 ([desarrollo](../v3-desarrollo.md)), porque cambia cosas de la v1 que también afectan a las partidas de ahora. La partida guardada sigue en la versión 14 y no gana ni pierde campos.

## Objetivo

1. **Partida nueva de verdad.** Empezar otra vez es siempre empezar de cero: Villaclaro, nivel 1, nada guardado. Desaparece la Partida nueva +.
2. **Bestiario en tres estados.** Las cartas distinguen bien un enemigo no visto, uno visto pero sin vencer y uno vencido. El premio de una familia solo llega cuando todos sus enemigos están vencidos, como ya pasa.
3. **Sanación compartida.** Sanación cura también al compañero o criatura, la mitad que al héroe.

## 1. Se quita la Partida nueva +

### Lo que ve el jugador

- En "Continuar", una ranura con una partida terminada (`SaveData.is_finished()`) sigue abriendo su página, pero ahora con solo dos opciones: "Continuar" (con el foco) y "Volver". "Partida nueva +" desaparece. Esc o un toque fuera hacen lo mismo que "Volver". Las ranuras sin terminar se siguen cargando directamente al elegirlas, como ahora.
- La ranura sigue diciendo " · terminada" en la lista.
- Para volver a empezar se usa "Nueva partida", tanto al abrir el juego como al volver al título desde el menú de pausa: se elige una ranura vacía, o una ocupada para sobrescribirla. Sobre una ocupada ya pregunta antes de borrar ("La partida de la ranura n se borrará. ¿Empezar una nueva?", con el foco en "No"), así que no cambia nada ahí. Sale el nombre, luego la dificultad, luego el prólogo en Villaclaro con nivel 1, el Palo, la Ropa, 50 G, tres pociones y nada más: ni bestiario, ni medallas, ni familias, ni criatura.
- Los créditos dejan de mostrar la línea "Partida nueva + n", y la ranura ya no dice " · +n".

### Las partidas que ya están en una Partida nueva +

- Siguen cargando, con su héroe, su equipo y su progreso tal cual.
- Los monstruos dejan de hacerse más fuertes: se juega con la fuerza normal.
- Cuando terminen la v1, pueden encontrarse con la caravana como cualquier otra partida. Hoy `GameState.can_meet_caravan()` lo impide con `ng_plus > 0`.
- **Slime de Metal:** en una Partida nueva + sus PV guardados pueden pasar del máximo normal. Al cargar se recortan al máximo de siempre, en vez de dar la partida por dañada. Hoy `SaveData._valid_metal_slime()` usa el multiplicador de la Partida nueva + para validar.

### Lo que cambia en el código

- Se borra `scripts/game/ng_plus.gd` (`NgPlus`) y todo lo que lo usa:
  - **`Game`:** `setup(..., new_cycle)` pierde el parámetro. Se van `NgPlus.begin()` al cargar, `NgPlus.scaled()` antes de cada combate y su impresión en autoplay. También `NG_PLUS_START` y `--autoplay-zone=ngplus`, la condición `ng_plus > 0` de `_autoplay_hunts()` y la línea de los créditos.
  - **`TitleScreen`:** se van `_on_ng_plus_chosen()` y su conexión.
  - **`SlotList`:** la página `cycle` se queda con "Continuar", que emite `chosen(slot)`, y "Volver", que lleva de vuelta a la lista. Se van `NG_PLUS`, `NG_PLUS_CONFIRM`, `NG_PLUS_YES` y la señal `ng_plus_chosen`.
  - **`GameState`:** `ng_plus` desaparece y `can_meet_caravan()` deja de mirarlo.
- **La partida guardada:** el campo `ng_plus` se sigue escribiendo, siempre a 0, para que la versión 14 siga igual y una 2.6.1 pueda leer una partida de la 2.7.0. Al cargar se lee y se valida como hoy (un número entero ≥ 0), pero no se usa. `summary_line()` deja de añadir " · +n".
- `_valid_metal_slime()` acepta cualquier valor ≥ 0. `apply()` recorta `metal_slime_hp` al máximo normal del Slime de Metal.
- `CLAUDE.md` deja de hablar de la Partida nueva +, de `ngplus` y de `NG_PLUS_START`.

## 2. El bestiario en tres estados

### Lo que ve el jugador

| Estado | Condición | La carta |
|---|---|---|
| No visto | No está en `seen_enemies` | Sin retrato ni silueta: un recuadro con "??" y "??" como nombre. No se puede pulsar. |
| Visto | En `seen_enemies` y no en `defeated_enemies`: huiste, perdiste o el combate no acabó en victoria | Su retrato con el color apagado (casi gris y algo transparente) y su nombre. Se puede pulsar; la ficha dice "Aún no vencido". |
| Vencido | En `defeated_enemies` | Su retrato con el color nítido, como ahora. |

- El título de cada familia sigue contando los vencidos ("Plantas 3/4"). Cuando la familia está completa se pinta en dorado y nombra su premio ("Plantas 4/4 · Anillo de savia"), como hoy.
- **El premio no cambia de regla:** se da cuando todos los enemigos de la familia están vencidos (`Bestiary.is_complete()`), justo después del combate que lo consigue o al cargar la partida. Ver o huir no cuenta.
- El contador del menú ("Bestiario n/22", n/47 en la caravana) sigue contando los vistos.

### Lo que cambia en el código

- **`BestiaryPage._card(id, seen)`** pasa a recibir el estado: no visto, visto o vencido.
  - **No visto:** sin `TextureRect` de retrato, solo el texto "??" sobre el fondo de la carta.
  - **Visto:** el retrato con un `modulate` o un shader de desaturación.
  - **Vencido:** el retrato tal cual.
  - El tinte del estado "visto" es un token nuevo del design system, `portrait-seen`, con valor para los dos temas (gris al 55 % en el normal, más claro y opaco en alto contraste). Se añade primero al design system (`tokens.json`, la tabla de color de `2-fundamentos.md` y una ficha nueva del componente, `components/BestiaryCard.md`) y luego a la parte generada de `ui_tokens.gd`. Lo mismo vale para cualquier color o tamaño nuevo: siempre entra por el design system.
- `UNKNOWN` pasa de "???" a "??".
- No cambia nada en `Bestiary`, `GameState` ni la partida guardada.

### La causa de la duda del usuario

No hay ningún error en la lógica de los premios. Hoy una carta vista sale con el retrato nítido aunque no esté vencida, así que una familia parecía completa sin estarlo. Además, la familia Plantas incluye el Hongo de cueva, que solo vive en la mina. Con los tres estados la diferencia se ve de un vistazo.

## 3. Sanación cura también al compañero

### Lo que ve el jugador

- En combate, Sanación cura al héroe 150 PV, como ahora, y al compañero o criatura la mitad: 75 PV, sin pasar de su máximo.
- Se puede lanzar aunque el héroe tenga los PV al máximo, si el compañero está herido. Solo sale gris con "PV al máximo" cuando los dos están llenos, o el héroe lleno y el compañero caído o ausente.
- No levanta a un compañero caído.
- Fuera de combate (Hechizos del menú de pausa) cura solo al héroe, como hoy: allí la vida del compañero no existe, porque cada combate empieza con él entero.
- Curar y Curar+ no cambian.
- La ficha de Sanación dice que cura al héroe y la mitad a su compañero.

### Lo que cambia en el código

- **`Skill`** gana `ally_share: float`, la parte de `power` que recibe el aliado. Vale 0.0 por defecto y 0.5 en `data/skills/sanacion.tres`.
- **`BattleEngine._cast()`:** en una curación lanzada por el héroe con `ally_share > 0` y el aliado en pie, cura también al aliado con `ceil(power × ally_share)`, como mucho lo que le falte. Lo hace con otro evento `BattleEvent.heal(BattleEvent.ALLY, ...)`, que `BattleScene` ya sabe reproducir con la vida del aliado. Las curaciones de los enemigos no cambian.
- **`BattleEngine.problem()`:** con `ally_share > 0` solo dice "PV al máximo" si tampoco hay un aliado en pie y herido.
- **`BattleAutoplay`:** no cambia. Sigue curando cuando el héroe baja del 40 %.

## Verificación

Sin tests, como siempre: `--check-only` de los scripts tocados, `--import` y partidas a mano o en autoplay.

- **Nueva partida desde cero:** una partida en autoplay desde cero sigue llegando a los créditos (`Juego completado: ...`) con los números de la 2.5.0 (Nv 18, alrededor de una hora).
- **Guardado:** el ida y vuelta (`--autoplay-save`) da las mismas líneas `Guardado:` y `Cargado:`.
- **Partida antigua en Partida nueva +:** con `APPDATA` apuntando al scratchpad, se carga una partida de versión 14 con `ng_plus` 1 y el Slime de Metal por encima del máximo normal. Carga, los PV del Slime quedan recortados y los monstruos tienen su fuerza normal.
- **Ranura terminada:** en la pantalla de título, "Continuar" abre su página solo con "Continuar" y "Volver", y "Nueva partida" sobre ella pregunta y empieza de cero.
- **Bestiario:** se revisan las fotos de la página con los tres estados a la vez, en escritorio y con `--touch` a 740 × 360.
- **Sanación:** autoplay de `--autoplay-zone=montana` o `ciudad` con Brena, donde el héroe ya la tiene. En los combates en que la lanza se ve la curación del compañero, y la v2 se sigue terminando con sus números de siempre.
- **Antes de cerrar:** el mismo repaso de errores y avisos de la salida de Godot que en cada versión.

## Fuera de esta versión

- Todo lo de la v3 (Alba, Brumaclara, sus habitantes con cuernos y cola, nivel 50): va en su propio spec.
- Mejoras del bestiario más allá de los tres estados, como decir qué enemigo falta en el título de la familia.
