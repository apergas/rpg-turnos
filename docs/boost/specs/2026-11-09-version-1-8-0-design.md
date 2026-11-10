# Versión 1.8.0: medallas pequeñas y Partida nueva +

Fecha: 2026-11-09. Parte de la 1.7.0. Cubre M-34 (medallas pequeñas) y M-35 (Partida nueva +).

## Objetivo

Dar motivos para explorar y para volver a jugar: doce medallas escondidas que un coleccionista cambia por premios, y una segunda vuelta con el héroe ya hecho y los monstruos más duros.

El guardado pasa a la **versión 13**.

## M-34. Medallas pequeñas

### Dónde están

- Doce medallas, tres por región: pradera, bosque, mina (una por planta) y castillo (dos en el patio y una en el salón del trono).
- Cada una es un destello dorado pequeño en el suelo: un disco brillante de unos 0,3 m que parpadea despacio, sin rótulo. Se ve de cerca, no desde lejos: está pensado para encontrarla al explorar.
- Siempre fuera del sendero y de la ruta de la partida automática: en un rincón, detrás de una casa, al fondo de un claro, en un callejón sin salida de la mina.
- Datos en una clase pura nueva, `Medals` (`MEDALS`: id → zona y posición, como `Chests.CHESTS`), con `of_zone()`.
- Acción "Coger" a menos de 1,5 m, con un toque también. Mensaje en la ventana de diálogo: "¡Encuentras una Medalla pequeña! (n/12)".
- No salen en el mapa pequeño ni en la página Mapa: son para buscarlas.

### El Coleccionista

- Figura nueva en Villaclaro, `Coleccionista`, junto a la posada (el plan elige el sitio con el mapa delante, lejos de la ruta), con la figura `VILLAGER` teñida de morado. Sin rótulo encima.
- Al hablar, entrega de una vez todos los premios cuyas medallas ya se tienen y no se han dado. Las medallas no se gastan: se cuentan.
- Sin premios nuevos, dice cuántas medallas llevas y cuántas faltan para el siguiente: "Llevas 4 medallas. Con 6 te daré algo bueno."
- La primera vez que se le habla explica: "Colecciono medallas pequeñas. Hay doce escondidas por el mundo. Tráemelas y te daré premios."

| Medallas | Premio |
|---|---|
| 2 | 2 Plumas de fénix |
| 4 | Semilla de fuerza y Semilla de agilidad |
| 6 | Escudo de medallas (Escudo, DEF +12; el de platino da +10) |
| 9 | Cota de medallas (Armadura, DEF +25; la de platino da +22) |
| 12 | Amuleto de medallas (Amuleto, VEL +4 · ATK +3) |

- Las piezas son de zona −1, precio 0, "No se vende". Se ponen si su casilla está vacía, si no, a la bolsa (`QuestRewards`).
- El Escudo y la Cota usan la malla y el tinte de la pieza de platino, con un tinte dorado.

### En los menús

- Diario, "Colección": una línea nueva "Medallas n/12".
- Página Objetos: "Medalla pequeña ×n" en los objetos clave, con su texto: "El Coleccionista de Villaclaro las colecciona."

### Partida automática

Coge las medallas que caen a su alcance (la regla de siempre: lo que está cerca, una vez). Como están lejos de la ruta, casi nunca coge ninguna, y eso está bien: no cambia el ritmo. Para comprobarlas hay un modo nuevo, `--autoplay-zone=medallas`: empieza con el juego terminado en Villaclaro, con el héroe en Nv 20 y la ruta de cada región pasa por sus medallas (una lista aparte de puntos, `Medals.AUTOPLAY_ROUTE`, solo para ese modo), y al acabar habla con el Coleccionista e imprime los premios.

## M-35. Partida nueva +

### Cómo se empieza

- Solo con una partida terminada (`GameState.is_finished()`).
- En la lista de ranuras del título, al elegir "Continuar" sobre una ranura terminada, una página pregunta: "Continuar" (la partida tal cual, en el mundo de después del final) o "Partida nueva +". El foco va en "Continuar".
- "Partida nueva +" pregunta antes: "Empiezas de nuevo la historia con tu héroe, su equipo y su oro. Los monstruos serán más fuertes. ¿Seguro?" (foco en "No").
- Escribe sobre la misma ranura.

### Qué se queda y qué no

| Se queda | Empieza de nuevo |
|---|---|
| Nivel, EXP, estadísticas y hechizos | La historia, las escenas vistas y el capítulo |
| Equipo puesto y bolsa | Todas las misiones |
| Oro y objetos (no los objetos clave) | Los cofres (se pueden volver a abrir) |
| Criatura aliada | Las banderas del mundo, los objetos clave, el portal |
| Bestiario (vistos y vencidos) y las banderas `familia_<id>` | Los pozos y el mapa explorado |
| Medallas cogidas y premios ya dados | La zona: casa del héroe, con el prólogo |
| Nombre y dificultad | El tiempo de juego, pasos, combates y oro ganado (para los créditos) |

- Las medallas ya cogidas no vuelven a salir en el mapa (se recuerdan por id).
- `GameState.ng_plus`: 0 en una partida normal, 1 en la primera Partida nueva +, 2 en la siguiente, y así.

### Monstruos más fuertes

- En `ng_plus` ≥ 1, todos los enemigos (jefes incluidos, también el Eco) multiplican PV, ATK y DEF por `NgPlus.stat_mult(ng_plus, zone)` y la EXP y el oro por `NgPlus.reward_mult(ng_plus)`. Clase pura nueva, `NgPlus`.
- Punto de partida, que el plan ajusta con la partida automática:
  - Los enemigos de la zona `z` (1 pradera, 2 bosque, 3 mina, 4 castillo) se suben hasta parecerse a los del castillo para un héroe de Nv 20 con equipo de platino. Fórmula de partida: `stat_mult = 1 + (4 - z) × 0.6 + (ng_plus - 1) × 0.3`, para que la pradera sea un reto y el castillo un poco más duro que en la primera vuelta.
  - `reward_mult = 1.5` (el nivel máximo es 20, así que la EXP solo sirve si el héroe no llegó al máximo).
- Las misiones dan el mismo oro y los mismos objetos.
- Ninguna otra regla cambia.

### Créditos y título

- Al acabar una Partida nueva + salen los créditos como siempre, con una línea más: "Partida nueva + n".
- `SaveData.summary_line()` añade "· +n" al final: "Rocío · Nv 20 · Pradera · 0:05 · +1".

### Partida automática

`--autoplay-zone=ngplus` empieza una Partida nueva + 1 con el héroe de `ECHO_START` (Nv 20, platino, Yelmo de bruma, Esqueleto leal) y juega la historia entera. Debe acabar en `Juego completado` sin derrotas en bucle. Con esa salida se ajusta `stat_mult`.

## Guardado (versión 13)

- `medals`: lista de ids cogidos (ordenada). `medal_prizes`: cuántos premios del Coleccionista se han dado. `collector_met`: si ya habló con él.
- `ng_plus`: entero ≥ 0.
- En un guardado anterior: sin medallas, 0 premios, 0 vueltas.
- `is_valid()`: ids de `Medals.MEDALS`, premios entre 0 y 5 y no más de los que permiten las medallas, `ng_plus` ≥ 0.

## Verificación

- `--check-only` e `--import` (clases nuevas `Medals` y `NgPlus`).
- `--autoplay-zone=medallas`: coge las doce, recibe los cinco premios.
- `--autoplay-zone=ngplus`: completa la vuelta; anotar nivel, tiempo y derrotas.
- Fotogramas de una medalla en cada región, del Coleccionista, del Diario y de la página de la ranura terminada en el título, en escritorio y en el móvil.
- Cargar un guardado de la versión 12: sin medallas, todo igual.
- Partida automática normal completa, viaje de ida y vuelta del guardado, exportación web.

## Fuera de esta versión

- Medallas con premio de oro o una tienda de medallas.
- Contenido nuevo propio de la Partida nueva + (enemigos o escenas nuevas): solo cambian los números.
