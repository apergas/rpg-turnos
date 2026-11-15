# Versión 3.6.0: el compañero en el mapa, la tienda y el armero

Fecha: 2026-11-15. Estado: spec. Cubre M-96, M-97 y M-99 del [documento maestro](../documento-maestro.md). Va después de la [3.5.0](2026-11-15-version-3-5-0-design.md), cuyo equipo del compañero también se ve en el mapa. La partida guardada sigue en la versión 15 y no gana ni pierde campos.

## Objetivo

1. **El compañero te sigue por el mapa (M-96).** La criatura de la v1 o el compañero de la v2 y la v3 anda a poca distancia detrás del héroe y se para cuando él se para. Solo se ve: no se habla con él ni choca con nada.
2. **La tienda y el armero (M-97).** En cada pueblo, la tienda vende los consumibles y un armero nuevo vende el equipo. En los dos se puede vender.
3. **La Pluma de fénix no se compra (M-99).** Solo cae de los enemigos o sale de los cofres.

## Decisiones tomadas (2026-11-15)

| Tema | Decisión |
|---|---|
| Dónde se ve el compañero | En todas las zonas: pueblos, caminos y mazmorras |
| Cuándo no se ve | En las escenas, y donde su figura ya está en el mapa como personaje (Brumaclara al llegar, la ciudad tras el Devorador) |
| Dónde hay armero | En los seis pueblos con tienda: Villaclaro, el bosque, la mina, el castillo, la Caravana y Brumaclara |
| La Domadora y el Jefe de caravana | No cambian |

## 1. El compañero te sigue por el mapa (M-96)

### Lo que ve el jugador

- Si llevas criatura (gallina, lobezno, gólem pequeño o esqueleto leal) o compañero (Brena, Tadeo o Ulma), anda detrás del héroe a unos 1,6 m, por el mismo camino que él.
- **Se para cuando el héroe se para**, con su animación de quieto. Cuando el héroe echa a andar, arranca detrás, con su animación de andar. Las criaturas hechas en código (gallina, lobezno, gólem pequeño) no tienen animación de andar: se deslizan con su balanceo de siempre.
- **No es un personaje del mapa:** no hay aviso de «Hablar», no lleva rótulo ni marca de misión, no choca con el héroe, los monstruos ni las paredes, y no sale en el mapa pequeño.
- **Al entrar en una zona,** cruzar un portal o usar el Ala de viaje, aparece ya detrás del héroe, mirando hacia donde mira él.
- **Si se queda lejos** (más de 8 m: una esquina cerrada o un atajo), aparece de golpe detrás del héroe, sin cruzar paredes a la vista.
- **No se ve:**
  - durante las escenas (vuelve al acabar, detrás del héroe);
  - mientras su figura está en el mapa como personaje: Brena, Tadeo o Ulma en Brumaclara antes de `brumaclara_vista`, y en la ciudad abandonada tras el Devorador. Así no hay dos iguales.
- Lleva el mismo equipo que en combate (la tabla de la 3.5.0), pero sin el borde de lectura del héroe (`set_map_readable()` es solo para el héroe).
- Al comprar otra criatura o elegir compañero, el que te sigue cambia al momento.

### Lo que cambia en el código

- **Una pieza nueva, `MapCompanion`** (`scripts/world/map_companion.gd`, un `Node3D`), creada por `World` como sus otras piezas (`MapFigures`, `MapProps`…). Sigue la skill `structuring-godot-code`: `world.gd` es uno de los grandes dueños y no crece más que lo justo para crearla y pasarle llamadas.
  - Tiene un `BattleActor` con el aspecto `EnemyLibrary.look(ally_id)` y, si es compañero, `set_companion_gear(Allies.gear(id, step))`. No tiene cuerpo físico: es un nodo sin colisión, así que nada choca con él.
  - **El seguimiento:** guarda un rastro de posiciones del héroe (un punto cada 0,25 m andados, unos 40 como mucho) y se mueve hacia el punto que queda a 1,6 m de camino detrás del héroe, a la velocidad del héroe (`Player.SPEED`), o hasta 1,5 veces más rápido si se ha quedado atrás. Gira hacia donde anda con `lerp_angle`, como `Player`.
  - **Quieto:** si el héroe no se mueve y el compañero ya ha llegado a su punto, `set_walking(false)`; mientras se mueve, `set_walking(true)`.
  - **Recolocarse:** `snap_behind(pos, yaw)` borra el rastro y lo pone detrás del héroe. Se llama al colocar al héroe (`World.place_player()`, `place_at_entry()`) y cuando la distancia pasa de 8 m.
- **`World.set_companion(ally_id: String, step: int)`**: crea, cambia o quita el `MapCompanion`. `Game._refresh_status()` la llama, junto a `set_hero_equipment()` y las demás, con `state.ally_id` y `state.ally_step()`. Así la recibe cada `World` nuevo y cada cambio de criatura o de compañero.
- **Ocultarlo:**
  - `World.begin_cutscene()` lo oculta y `end_cutscene()` lo vuelve a mostrar y lo recoloca detrás del héroe;
  - cuando `MapFigures` tiene visible una figura con el nombre del compañero (`Allies.display_name(ally_id)`), también se oculta. `Game._refresh_status()` ya oculta las figuras de los demás compañeros con `set_quest_view()`; el `MapCompanion` mira la misma lista.
- **Partida automática:** el compañero solo se ve y no cambia nada de lo que hace. `AutoplayHunter` y `MapUses` no lo conocen.
- **Rendimiento:** es un actor más en pantalla. En móvil se comprueba que el mapa sigue a su ritmo (`DisplaySettings` ya baja la resolución 3D).

## 2. La tienda y el armero (M-97)

### Lo que ve el jugador

- En cada pueblo hay dos figuras para comprar:
  - **La tienda**, con su rótulo «Tienda», vende los consumibles: pociones, éteres, antídotos, Ala de viaje, Incienso, Pluma de fénix, Despertador y el Elixir.
  - **El armero**, con su rótulo «Armero», vende el equipo del pueblo: arma, armadura, escudo y casco.
- **En las dos se puede vender todo**, con la página «Vender» de la 3.4.0.
- Las dos tienen la misma ventana de hoy: «Comprar», «Vender» y «Salir». En el armero, «Comprar» solo lista el equipo, con su comparación y la pregunta «¿Te lo equipas ahora?»; en la tienda, solo los objetos, con el botón «×5».

| Pueblo | Tienda | Armero |
|---|---|---|
| Villaclaro | El Mercader de hoy | Un Armero nuevo |
| Bosque | El Mercader de hoy | Un Armero nuevo |
| Mina | Una Tendera nueva | El Herrero de hoy |
| Castillo | El Mercader de hoy | Un Armero nuevo |
| Caravana | El Mercader de hoy | Un Armero nuevo |
| Brumaclara | Un Tendero nuevo (desde el Coloso, como hoy el Herrero) | El Herrero de cristal, en su forja |

- Las figuras nuevas usan aspectos que ya existen (KayKit y Kenney, con tinte si hace falta, como el resto) y se colocan junto a la tienda de cada pueblo. Si alguna línea de diálogo dice que el Herrero o el Herrero de cristal venden pociones, se corrige.
- **La Domadora** («Criaturas») y **el Jefe de caravana** (la elección del compañero) no cambian.

### Lo que cambia en el código

- **Las existencias no se parten:** `Shop.SHOPS` (`scripts/game/shop.gd`) sigue teniendo una entrada por pueblo y paso (`villaclaro`, `caravana_3`, `brumaclara_4`…) con su `equipment` y sus `items`. La parte que vende cada figura se elige al abrir:
  - Hay dos mostradores nuevos, `const ITEMS_COUNTER := "items"` y `const ARMORY_COUNTER := "armory"`.
  - `Shop.stock(shop_id, counter)` devuelve solo los `items` o solo el `equipment` según el mostrador. Las tiendas de criaturas y la de compañeros no lo miran.
- **Un tipo de figura nuevo, `"armory"`**, en `ZoneData.npcs`, con el mismo `id` de pueblo que la tienda (`"villaclaro"`, `"caravana"`, `"brumaclara"`). En los datos:
  - El Herrero de la mina y el Herrero de cristal pasan de `"kind": "shop"` a `"kind": "armory"`.
  - Las figuras nuevas se añaden en `data/zones/pradera.tres`, `bosque.tres`, `mina_1.tres`, `castillo_patio.tres`, `caravana.tres` y `brumaclara.tres`. El Tendero de Brumaclara lleva `"needs": "coloso_cuarzo"`.
- **`MapUses`:** `NPC_KINDS` gana `"armory"`, que abre la misma ventana con el mostrador del armero. La señal `shop_requested(id)` pasa a llevar también el mostrador: `shop_requested(id, counter)`. `World` y `Game` la pasan igual a `FigureTalk.on_shop(id, counter)`, que llama a `ShopWindow.run(shop_id, counter)`.
- **`MapFigures._figure_sign_text()`:** `"armory"` da «Armero».
- **`ShopWindow`** (`scripts/ui/shop_window.gd`) guarda el mostrador y lo usa en la página «Comprar» y en su título («Armero» o «Tienda»). «Vender» no lo mira.
- **`FigureTalk.on_shop()`:** las misiones que esperan en una tienda (`_figure_with_quest("shop", id)`) se buscan también entre las figuras `"armory"`, para que una misión que hoy se entrega al Herrero o al Herrero de cristal siga funcionando.
- **Partida automática:**
  - `GameAutoplay.restock()` recorre las figuras `"shop"` y las `"armory"`.
  - `Shop.autoplay_picks(state, shop_id, counter)` compra lo que compraba hoy, pero solo de la parte de ese mostrador: el equipo mejor en el armero; el Ala y las pociones en la tienda.
  - `_caravan_errand()` cruza el portal y visita el armero de la Caravana cuando `Shop.gear_to_buy()` lo pide, y la tienda si le faltan pociones. Sus mensajes «Recado en la Caravana» y «Visita a Villaclaro» no cambian.
  - `_gear_pending()` (la Domadora espera a que el héroe compre el equipo del pueblo) no cambia: mira las existencias del pueblo, que siguen juntas.
- **`CLAUDE.md`:** la línea del Herrero de cristal («opens the shop of the etapa») pasa a decir que abre el armero de la etapa, y se añade el tipo de figura `"armory"` donde se habla de las salidas y figuras.

## 3. La Pluma de fénix no se compra (M-99)

### Cómo está hoy

- La venden todas las tiendas desde el bosque: el bosque, la mina, el castillo, las seis de la Caravana y las dos del Herrero de cristal (`Shop.SHOPS`).
- Sale de siete cofres, ninguno de la v1:
  - en la v2, `desierto_ruina`, `montana_1_oeste` y `ciudad_2_cofre`;
  - en la v3, `cienaga_islote_norte`, `cuevas_2_cofre`, `ruinas_2_cofre` y `fuente_este`.
- Solo la deja caer la Momia del desierto (3 %).
- El Coleccionista da dos por 2 medallas (`Medals.PRIZES`).
- La partida automática no la compra (`Shop.autoplay_picks()` solo compra equipo, el Ala y pociones).

### Lo que ve el jugador

- Ninguna tienda la vende: no sale en «Comprar» de ninguna tienda.
- **Se puede seguir vendiendo:** conserva su precio, así que en «Vender» se paga la mitad, como hoy.
- **Se consigue así:**
  - en los siete cofres de hoy y en dos cofres de la v1 que hoy dan oro: uno de la mina (`mina_2_cofre`) y uno del castillo (`castillo_patio_oeste` o el que el plan vea mejor colocado);
  - de los enemigos: la Momia, como hoy, y un enemigo común de cada zona de combate que hoy no la da, del bosque a la Fuente, con un 2 % (uno solo por zona, elegido en el plan entre los más frecuentes);
  - del Coleccionista, como hoy.
- Para los jefes no cambia nada: sus botines son los de siempre.

### Lo que cambia en el código

- **`Shop.SHOPS`** (`scripts/game/shop.gd`): `Inventory.PHOENIX` sale de la lista `items` de todas las tiendas. Con eso deja de comprarse también en la tienda de la 3.6.0, que lee esa lista.
- **`Chests.CHESTS`** (`scripts/game/chests.gd`): los dos cofres de la v1 cambian `"gold"` por `"item": Inventory.PHOENIX`. Una partida que ya abrió ese cofre no lo vuelve a abrir (los cofres abiertos se guardan por id), así que no recibe nada de más.
- **Los enemigos:** `"pluma_fenix": 0.02` en el diccionario `drops` de un enemigo por zona, en sus `.tres` de `data/enemies/`.
- **El texto:** el `CHANGELOG.md` de la 1.5.0 dice «150 G, desde la tienda del bosque». No se toca, porque es historia, pero la sección 3.6.0 dice que ya no se compra y dónde se encuentra.

## Verificación (a mano; el proyecto no tiene tests)

- `--check-only` en cada script tocado, `--import` tras crear `map_companion.gd` (es un `class_name` nuevo), `gen_ui_tokens.gd -- --check` y `check_ui_values.gd`.
- Partida automática de la v1 completa, de la v2 desde la Caravana y de la v3 hasta `Juego completado (v3)` (skill `villaclaro-autoplay`). Compra equipo y pociones en cada pueblo, y los tiempos y derrotas son los de la 3.5.0.
- Capturas en ventana y a 740 × 360 con `--touch`:
  - el compañero detrás del héroe, andando y quieto, en un pueblo, en una mazmorra y en Brumaclara;
  - con una criatura de la v1;
  - la tienda y el armero de Villaclaro, de la mina y de Brumaclara, con sus rótulos;
  - «Comprar» de una tienda del bosque, de la Caravana y de Brumaclara, sin la Pluma de fénix.
- La partida automática termina la v1, la v2 y la v3 sin más derrotas que en la 3.5.0: sin plumas en las tiendas, revivir depende de lo encontrado.
- La partida guardada de antes carga igual (el compañero no se guarda aparte: sale de `ally_id`).
- `CHANGELOG.md`, sección 3.6.0, y `application/config/version` = 3.6.0.
