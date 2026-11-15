# Versión 3.4.0: una interfaz más clara

Fecha: 2026-11-15. Estado: spec. Cubre M-86 a M-90 del [documento maestro](../documento-maestro.md). Sale de las ideas del 2026-11-14 y 2026-11-15. La partida guardada sigue en la versión 15 y no gana ni pierde campos.

## Objetivo

Cinco retoques de interfaz, sin reglas de juego nuevas:

1. **Vender solo lo vendible (M-86).** La lista de «Vender» deja de enseñar las piezas puestas y lo que no se vende.
2. **El efecto, debajo del nombre (M-87).** En «Equipo», lo que da cada pieza va en una línea pequeña debajo de su nombre, como en «Objetos».
3. **Los números del compañero en Estado (M-88).** Debajo del nombre del compañero o la criatura, sus estadísticas de ese momento.
4. **El menú en gris al elegir objetivo (M-89).** En combate, mientras eliges a quién atacar, las demás órdenes quedan en gris y solo responde «Volver».
5. **Rótulos con el nombre (M-90).** Las figuras con una función concreta llevan su nombre encima, como ya llevan «Tienda», «Criaturas» o «Posada».

## Decisiones tomadas (2026-11-15)

| Tema | Decisión |
|---|---|
| Menú al elegir objetivo | En gris (no oculto) en ordenador; en móvil sigue como hoy, con todo oculto menos «Volver» |
| Texto de los rótulos nuevos | El nombre de la figura: «Coleccionista», «Jefe de caravana», «Orvalla», «Tablón» |
| Quién da misiones | Sigue con su «!» o «?» y sin rótulo |

## 1. Vender solo lo vendible (M-86)

### Lo que ve el jugador

- La página «Vender (pago la mitad)» solo lista lo que se puede vender en ese momento:
  - las piezas de equipo de la bolsa (`bag_equipment`), una fila por pieza con «×N» si hay varias copias;
  - los objetos de `Inventory.IDS` que lleves y que tengan precio de venta.
- Desaparecen:
  - **las piezas puestas.** Si llevas una puesta y otra igual de repuesto en la bolsa, sale la de repuesto, con la cuenta de las de la bolsa, como hoy;
  - **lo que no se vende:** todo lo que hoy da «No se vende», es decir, lo que tiene `Shop.sell_price() <= 0`. Son la Espada del Alba, el Escudo de medallas, la Cota de medallas, el Yelmo de bruma, la Espada del portal, la Espada de Albor, los objetos de misión (Seta, Piel de mono, Cristal de hielo, Junco de bruma, Esquirla de geoda…) y las semillas.
- Siguen saliendo los anillos y amuletos de premio (se venden por `prize_accessory_price()`), el Palo y la Ropa (1 G) y todo lo demás con precio.
- Si no queda nada, sale el texto de siempre: «No llevas nada que vender.»
- Al vender la última copia de algo, su fila desaparece y el cursor pasa a la fila siguiente (o a la anterior, si era la última). Hoy el cursor se queda en la misma fila, que ahora ya no existiría.

### Lo que cambia en el código

- **`Shop.sell_list(state)`** (`scripts/game/shop.gd`) deja de añadir las piezas puestas y filtra con una regla pura nueva, `Shop.sellable(state, id)`, que es verdadera cuando hay copias para vender (`sell_count > 0`) y el precio de venta es mayor que 0. Es la misma regla que hoy usa `sell_problem()`, puesta antes de listar.
- `sell_problem()` se queda (la usa `Shop.sell()` como red), pero en la lista ya no aparece ninguna fila desactivada. `_add_sell_row()` (`scripts/ui/shop_window.gd`) deja de pintar el motivo en gris; el texto `WORN` («Lo llevas puesto») queda sin uso en la lista y se borra si nada más lo usa.
- **El cursor tras vender:** `_sell()` vuelve a poner el foco en la misma pieza si sigue en la lista, y si no, en la fila de la misma posición o en la anterior.
- **Partida automática:** no vende (solo abre y cierra la página), así que no cambia.
- El comentario de cabecera de `shop_window.gd` que dice que se listan las piezas puestas se corrige.

## 2. El efecto, debajo del nombre (M-87)

### Lo que ve el jugador

- **La lista de huecos de «Equipo»:** cada fila dice el hueco y la pieza («Arma: Espada de hierro»). Debajo, en letra pequeña (`caption`, `text-secondary`), va lo que da: «ATK +12», «DEF +8 · Inmune al veneno». Un hueco vacío dice «Arma: nada» y no lleva línea debajo.
- **La lista de piezas de un hueco** (al elegir uno): cada fila lleva el nombre de la pieza y la flecha de comparación a la derecha, como hoy. Debajo va el efecto en letra pequeña, igual que la descripción de un objeto en «Objetos».
- Los totales «ATK · DEF · VEL» del final no cambian.

### Lo que cambia en el código

- `PauseMenu._fill_equipment()` (`scripts/ui/pause_menu.gd`):
  - El botón del hueco pasa a llevar solo `"%s: %s" % [SLOT_NAMES[slot], nombre]`, y debajo se añade `UiStyle.add_small_text(caja, Equipment.effect_text(id))`. La caja es un `VBoxContainer` por fila, con el botón (`UiTheme.menu_row`) y la línea pequeña, como hace `_fill_items()`.
  - En la lista de piezas de un hueco, la etiqueta del efecto deja la fila horizontal y pasa a una línea pequeña debajo. La fila se queda con el nombre (ancho fijo de hoy) y la flecha de `ShopWindow.comparison()`.
- No hacen falta tokens nuevos: `caption` y `text-secondary` ya existen.
- **Móvil (740 × 360):** con seis huecos, cada uno de dos líneas, la página crece. Hay que comprobar que cabe. Si no cabe, la lista de huecos va dentro de un `ScrollBox` (`scripts/ui/scroll_box.gd`), como las listas largas de hoy. El cursor ▶ y `MenuCursor` siguen sobre los botones; la línea pequeña no recibe el foco.

## 3. Los números del compañero en Estado (M-88)

### Lo que ve el jugador

- En «Estado», debajo de «Compañero: Tadeo» (o «Criatura: Lobezno»), una línea pequeña con sus números de ese momento: «PV 205 · ATK 80 · DEF 43 · VEL 34».
- Para un compañero de la caravana son los números con lo que haya crecido en cada tramo o etapa (`Allies.GROWTH`). Desde la 3.5.0 se suma también su equipo (ver la [3.5.0](2026-11-15-version-3-5-0-design.md)). Para una criatura, sus números fijos.
- Sin compañero no sale nada, como hoy.

### Lo que cambia en el código

- **`Allies.stats_text(id, step)`** (`scripts/game/allies.gd`) pasa a recibir el paso de crecimiento y a leer `Allies.data(id, step)` en lugar de la ficha base. Devuelve «PV %d · ATK %d · DEF %d · VEL %d», con `total_attack()`, `total_defense()` y `total_speed()` para que la 3.5.0 sume el equipo sin tocar este texto.
  - La página de «Criaturas» de la Domadora, su único uso de hoy, pasa a llamarla con paso 1: las criaturas no crecen y se ve lo mismo que ahora, con «VEL» añadida.
  - La página «Compañeros» del Jefe de caravana la llama con el paso actual (`state.ally_step()`), así enseña los números que tendrá de verdad.
- **`PauseMenu._fill_status()`**: tras `_ally_label`, añade `UiStyle.add_small_text()` con `Allies.stats_text(_state.ally_id, _state.ally_step())`. La línea se crea en `_build_status()` y se rellena, o se oculta, en `_fill_status()`, para no crear nodos cada vez.
- Se corrige el comentario de `GameState.ally_step()`: dice «6 to 9», pero tras el Eco de Albor devuelve 10.

## 4. El menú en gris al elegir objetivo (M-89)

### Lo que ve el jugador

- Con dos o más enemigos en pie, al pulsar «Atacar» aparece «¿A quién?». Ahora:
  - **Atacar, Hechizos, Objetos, Defender y Huir** se quedan en su sitio, en gris (`text-disabled`), sin cursor, sin el sonido al pasar el ratón y sin responder al clic.
  - **«Volver»** es la única fila activa y el cursor ▶ pasa a ella (`MenuCursor` nunca se queda en una fila desactivada). Esc o un clic sobre ella vuelven atrás, como hoy.
  - Las flechas izquierda y derecha, o el clic sobre un enemigo, siguen cambiando de objetivo, y la tecla de aceptar sigue atacando al elegido: en esta página aceptar mira la flecha sobre el enemigo, no el ▶ del menú.
- Lo mismo pasa con un hechizo que pide objetivo: la lista de hechizos queda en gris y solo «Volver» responde.
- Al volver (Esc, «Volver» o un clic fuera), el menú o la lista vuelven a estar como antes, con el cursor donde estaba.
- **En móvil** no cambia: ya se ocultan todas las filas menos «Volver».

### Lo que cambia en el código

- `BattleHud._ask_target()` (`scripts/ui/battle_hud.gd`): fuera de la rama táctil, pasa cada fila que no sea `_back_row` por `_set_enabled(row, false)`, la misma función que ya pone en gris un hechizo sin PM. El estado de cada fila (activa o no, por su motivo) se guarda antes para devolverlo.
- `_back()` desde `Page.TARGET` devuelve a cada fila el estado que tenía, en lugar de dejarlas todas activas: un «Huir» que estaba en gris contra un jefe sigue en gris, igual que un hechizo sin PM.
- El texto de cada fila no cambia: no se añade «(motivo)» a las filas en gris de este caso.
- **Partida automática:** `demo()` pasa por `_ask_target()` y `_back()` como un jugador, así que recorre el cambio sola. Hay que comprobar que su cursor de demostración no intenta ir a una fila en gris.

## 5. Rótulos con el nombre (M-90)

### Lo que ve el jugador

- Encima de estas figuras sale su nombre, con el mismo estilo que «Tienda» o «Posada» (`display-m`, `text-display-soft`, contorno `outline-l`):

| Figura | Dónde | Rótulo |
|---|---|---|
| Coleccionista | Villaclaro, bosque, mina, castillo, Caravana y Brumaclara (cuando están) | «Coleccionista» |
| Jefe de caravana | La Caravana y la pradera de Villaclaro (donde elige compañero, pregunta por la salida o recibe misiones) | «Jefe de caravana» |
| Orvalla | Brumaclara | «Orvalla» |
| Tablón | Villaclaro, bosque, castillo, Caravana y Brumaclara | «Tablón» |

- **Sin rótulo**: el Jefe de caravana de la ciudad abandonada (solo dice unas líneas), los que dan o reciben misiones (ya llevan «!» o «?»), la Abuela Rosa (es la figura de la misión del pueblo y lleva su marca), los objetos que se cogen («Coger · X» ya sale al acercarse) y la gente de relleno (viajeros, vecinos, el gato, Albor y el Eco de Albor).
- Como hoy, el rótulo se oculta mientras el aviso de la acción está encima y durante las escenas, y la marca de misión sube cuando la figura tiene rótulo.

### Lo que cambia en el código

- **Un campo de datos, no nombres en el código:** cada entrada de `ZoneData.npcs` gana un campo opcional `"sign"` con el texto del rótulo. Va en las figuras de la tabla, en sus `.tres` de `data/zones/`.
- `MapFigures._figure_sign_text(npc)` (`scripts/world/map_figures.gd`) devuelve `npc.sign` si existe y, si no, sigue la regla de hoy (Tienda, Criaturas, Posada por `kind`).
- `ZoneData` documenta el campo junto a los demás de `npcs` (`scripts/world/zone_data.gd`).
- No hacen falta tokens nuevos.

## Verificación (a mano; el proyecto no tiene tests)

- `--check-only` en cada script tocado, `gen_ui_tokens.gd -- --check` y `check_ui_values.gd`.
- Partida automática de una zona de la v1, una de la v2 y una de la v3 (skill `villaclaro-autoplay`) sin ERROR ni WARNING nuevos.
- Capturas de pantalla, en ventana y a 740 × 360 con `--touch`:
  - «Vender» con una pieza puesta, una de repuesto, la Espada del Alba y objetos de misión en la bolsa;
  - «Equipo», la lista de huecos y la de piezas;
  - «Estado» con un compañero de la v2, con una criatura y sin nada;
  - el combate con dos enemigos tras «Atacar» y tras un hechizo de un objetivo;
  - los rótulos de la Caravana y de Brumaclara.
- `CHANGELOG.md`, sección 3.4.0, y `application/config/version` = 3.4.0.
