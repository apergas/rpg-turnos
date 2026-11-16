# Versión 3.10.0: armeros con el estilo de su lugar y nivel máximo 55

Fecha: 2026-11-16. Estado: plan ([plan](../plans/2026-11-16-version-3-10-0.md)). Cubre M-124 a M-126 del [documento maestro](../documento-maestro.md). Va después de la 3.9.0. Nace de dos ideas de [ideas.md](../ideas.md) («Armero con el estilo de cada zona» y «Nivel máximo 55») y de un fallo que encontraron los tests de la 3.9.0. La partida guardada sigue en la **versión 16**: no gana ni pierde campos.

## Objetivo

1. **Cada armero con el estilo de su lugar (M-124).** El usuario: «el sprite del armero tiene que ser siguiendo el estilo de cada zona: en Villaclaro, tipo bruja, etc.». Hoy el armero de Villaclaro y el del castillo son el mismo Superviviente, el del bosque un viajero de la caravana y el de la Caravana un granjero de Villaclaro. Cada uno pasa a vestir como su sitio, y el de la Caravana cambia con la tierra junto a la que acampa.
2. **Nivel máximo 55 (M-125).** El tope del héroe en la parte 3 baja de 60 a 55. El aura dorada sale al llegar al 55. Una partida guardada con el héroe entre el 56 y el 60 sigue cargando, con el héroe en el 55.
3. **El oro de los objetos retirados respeta el tope (M-126).** Al cargar, el oro que da la venta de un objeto que ya no existe (el Incienso) se sumaba después de recortar el oro, así que un archivo editado a mano podía pasar de 9 999 999. Con él, unos retoques de los tests de la 3.9.0 que pidieron sus revisiones.

## Decisiones tomadas (2026-11-16)

El usuario pidió «hazlo como creas conveniente, sin preguntar»: se toma siempre la opción recomendada.

| Tema | Decisión |
|---|---|
| Qué armeros cambian | Los seis lugares con figura `"kind": "armory"`: Villaclaro, la aldea del bosque, la mina, el campamento del castillo, la Caravana y Brumaclara. El Herrero de cristal de Brumaclara ya tiene el estilo de la Niebla desde la 3.8.0 (`MIST_SMITH`): no cambia |
| Villaclaro | Una **armera bruja**: el Mago de KayKit, con su sombrero de pico y su túnica, en un gris azul de noche (distinto del verde del Mercader, el morado del Coleccionista y el violeta de la Bruja del bosque), con un martillo de cobre en la mano. Se llama **Armera** (nombre, rótulo y ventana) |
| Bosque | Un **leñador**: barba pelirroja, cuero verde hoja, capa de musgo, delantal de cuero y martillo de hierro |
| Mina | Un **minero**: gorro de latón con su lámpara encendida, barba castaña, ropa tiznada, delantal y martillo de acero. Sigue llamándose Herrero |
| Castillo | El **armero del rey**: el Caballero con su armadura y su yelmo, capa carmesí y martillo de platino |
| Caravana | **Uno por tramo**, como ya cambia el campamento: en la jungla, verde y caqui con las mangas remangadas (martillo de jade); en el desierto, ropas de arena con capucha (oricalco); en la montaña, pieles con capucha blanca (adamantita); en la ciudad, tras el Devorador y en toda la v3, armadura de bronce con yelmo y capa de ceniza (estelar) |
| El martillo | Todos llevan uno, con la cabeza del metal que vende su mostrador: cobre, hierro, acero, platino, jade, oricalco, adamantita y estelar. Así se ve que es el armero y qué vende |
| Recursos | Solo los modelos que ya usa el juego: el Caballero y el Mago de KayKit, teñidos, con las cabezas de `head_textures.gd` que ya existen, el pelo, la capa y la capucha que ya se construyen en código, y tres piezas nuevas hechas en código (martillo, delantal, gorro de minero con lámpara). Ninguna descarga. El paquete completo de KayKit no está en `assets_src/` |
| Dónde va el código | Los ocho aspectos en un archivo nuevo de datos, `ActorLooksArmory`, que `ActorLooks.entry()` lee como lee `ActorLooksV3`. Las tres piezas, en un constructor nuevo, `SmithDress`, como `MistDress` para la gente de Brumaclara. `actor_looks.gd` no crece: sus siete listas iguales de lo que esconde un Mago pasan a una constante y deja sitio al enumerado y a `entry()` |
| El armero de la Caravana por tramo | Lo decide `CampLook`, la regla pura que ya viste el campamento para cada tramo: una tabla tramo → aspecto, aplicada sobre una copia de las figuras. Es lo que se prueba |
| Nivel máximo | 55 (`Leveling.MAX_LEVEL`). La tabla de EXP acaba en el 55 (58 600); sus cinco últimas entradas se quitan. Los topes de 20 y 40 no cambian |
| Equilibrio | No cambia: el piloto acaba la v3 en el Nv 53 (con la EXP ×1,35 de la 3.8.0) y no llega al tope. Ningún enemigo, premio ni precio se toca, y `autoplay_expected.json` tampoco |
| La Fuente | Sus monstruos se apartaban del héroe solo en el 60 (`exit_level` 56). Pasa a 51: se apartan en el 55, el nuevo tope, como antes en el 60 |
| Partidas del 56 al 60 | Cargan siempre, nunca se rechazan: el héroe baja al 55, con los números de un héroe del 55 (cada nivel quitado resta lo que dio: PV +6, PM +3, ATK +2, DEF +1, VEL +1; las semillas y el equipo se quedan) y su EXP en la del 55. Los hechizos no cambian (el último llega en el 45). Sin aviso: el héroe sigue en el tope y con su aura |
| Versión de la partida | Sigue en la 16. No hay campo nuevo: la bajada es una cuenta al cargar, como el recorte de la EXP. Una partida del 61 o más sigue siendo dañada, como hasta ahora |
| El oro de los objetos retirados | Se recorta a 9 999 999 después de sumarlo. Primero el test que falla, después el arreglo |
| Retoques de los tests | Se hacen, en una tarea pequeña: el ayudante de `test_chests.gd` falla con un mensaje si no encuentra cofre, `test_wells.gd` deja de decir «ten» en el nombre, `test_run_flags.gd` explica por qué su `after_each()` no lleva `-> void` y `test_quest_log.gd` gana su control positivo |
| Versión | 3.10.0: una menor, porque cambia lo que se ve y el tope del juego |

## 1. Los armeros (M-124)

### Lo que ve el jugador

- **Villaclaro:** la Armera, una bruja buena del pueblo: sombrero de pico y túnica gris azul de noche, martillo de cobre. Su rótulo dice «Armera», la acción «Comprar · Armera» y su ventana «Armera».
- **Aldea del bosque:** el Armero leñador, de verde y cuero, con capa de musgo, delantal y martillo de hierro.
- **Mina:** el Herrero minero, con gorro de latón y una lámpara que brilla en la frente, ropa tiznada, delantal y martillo de acero.
- **Campamento del castillo:** el Armero del rey, con armadura, yelmo, capa carmesí y martillo de platino.
- **Caravana:** el Armero viste como la tierra junto a la que acampa: la jungla, el desierto, la montaña y la ciudad (y así sigue tras el Devorador y en la v3).
- **Brumaclara:** el Herrero de cristal, como en la 3.8.0.
- Todos están en su sitio de siempre, venden lo mismo y hablan igual. Fuera del mapa no salen (ni en combate ni en escenas).

### Cómo se hace

- **Los aspectos.** Ocho entradas nuevas del enumerado `ActorLooks.Look` (`ARMORER_VILLACLARO`, `ARMORER_FOREST`, `ARMORER_MINE`, `ARMORER_CASTLE`, `ARMORER_JUNGLE`, `ARMORER_DESERT`, `ARMORER_MOUNTAIN`, `ARMORER_CITY`), al final, para no mover las demás. Sus datos, en `scripts/battle/actor_looks_armory.gd` (`ActorLooksArmory`, solo datos, con la forma de `ActorLooks.LOOKS`). `ActorLooks.entry()` busca en las tres tablas.
- **Las piezas.** `scripts/battle/smith_dress.gd` (`SmithDress`, constructor estático): el martillo en la mano derecha (`"hammer"`: el color de su cabeza), el delantal de cuero en el pecho (`"apron"`) y el gorro de minero con su lámpara (`"miner_cap"`). Cuelgan de huesos y siguen la animación; la lámpara brilla sin dar luz. `CharacterBuilder.build()` lo llama justo después de `MistDress.dress()`. La capucha del desierto y la de la montaña son la de `MistDress`, que ya vale para cualquier Caballero.
- **Los datos.** Cada zona pone el aspecto de su armero en su `.tres` (`"look"`). En la pradera, además, `"name": "Armera"` y `"sign": "Armera"`, y la tienda `villaclaro` de `Shop` dice `"armorer": "Armera"`.
- **La Caravana.** `CampLook.ARMORERS`, tramo → aspecto: 1 la jungla, 2 el desierto, 3 la montaña, 4 y 5 la ciudad. `CampLook.dressed()` copia las figuras y cambia la del armero. La Caravana guardada en caché (`ZoneData.by_id()`) no se toca: `duplicate()` es superficial y por eso las figuras se copian una a una.
- **Ajuste.** Los colores y las piezas salen con valores de partida y se ajustan con fotogramas de cerca de cada aspecto (de frente, de tres cuartos y de espaldas), como los de la 3.8.0. Lo que se busca: se distinguen entre sí y de las demás figuras de su pueblo; el martillo se agarra por el mango; el delantal no atraviesa el cuerpo de pie; el gorro y la lámpara asientan en la cabeza; el rótulo no queda tapado.

### Tests

Lo puro de esto es qué aspecto lleva cada armero:

- **Datos** (`tests/data/test_data_integrity.gd`): el armero de cada uno de los seis lugares lleva el aspecto de su sitio, todos distintos, existen en el enumerado y ninguna otra figura lleva un aspecto de armero; la Armera se llama así en la tienda.
- **`CampLook`** (`tests/world/test_camp_look.gd`, nuevo): cada tramo viste a su Armero con su aspecto (también por el portal en calma, en la v3 y con el mundo abierto); cada tramo tiene uno que existe; vestir el campamento no cambia la Caravana guardada ni las demás figuras.
- Lo que se ve (colores, piezas, posiciones) no se prueba: se mira en los fotogramas.

## 2. Nivel máximo 55 (M-125)

### Lo que ve el jugador

- En la parte 3 el héroe sube hasta el **55**. En el 55 la EXP se queda en 58 600 y la barra llena, como en cualquier tope.
- El **aura dorada** se enciende al llegar al 55 (con su destello tras el aviso de subida) y se queda.
- Una partida de la 3.8.0 a la 3.9.0 con el héroe entre el 56 y el 60 carga con el héroe en el 55, con su aura. Pierde los puntos de esos niveles (PV, PM, ATK, DEF y VEL), no sus semillas, su equipo ni sus hechizos.
- En la Fuente, los monstruos se apartan del héroe en el 55.
- El panel de depuración no pasa del 55.

### Cómo se hace

- `Leveling.MAX_LEVEL` 55; `EXP_TABLE` acaba en 58 600 (55 entradas). Todo lo que lee el tope lo sigue: `GameState.level_cap()`, `Leveling.at_max()` (el aura en `Player` y `BattleScene`), `set_level()` (el panel), `exp_for_next()`.
- `Leveling.lower_to_max(hero)`: baja a un héroe de más del tope al tope, nivel a nivel, restando lo que dio cada uno (lo mismo que `set_level()` al bajar, compartido), con la EXP del tope. No toca los hechizos.
- `SaveData`: `OLD_MAX_LEVEL` 60, el tope de las partidas de la 3.8.0 a la 3.9.0. `_valid_hero_ranges()` acepta hasta ese nivel, y `apply()` llama a `lower_to_max()` al leer el héroe. Del 61 en adelante, dañada.
- `data/zones/fuente.tres`: `exit_level` 51.
- Textos que dicen 60: los comentarios de `leveling.gd`, `v3_flow.gd` y `save_data.gd`, CLAUDE.md, la guía de QA (topes, aura, tabla, la Fuente, T-178, T-230 a T-233, T-237) y la skill del piloto.

### Tests

- `tests/game/test_leveling.gd`: el de Brumaclara pasa a «llega al 55»; nuevos: la tabla acaba en el 55 con 58 600, y un héroe por encima del tope baja a él con los números de un héroe del 55 (uno en el tope no cambia).
- `tests/game/test_save_data.gd`: una partida con el héroe en cada nivel del 56 al 60 carga, en el 55, con el aura, y al volver a guardarla es la de un héroe del 55. El caso del 61 de las partidas dañadas se queda.
- `tests/data/test_data_integrity.gd`: los monstruos de la Fuente pelean hasta el penúltimo nivel y se apartan en el tope.
- Los tests que ya leen `Leveling.MAX_LEVEL` siguen valiendo sin cambiar.

## 3. El oro de los objetos retirados (M-126)

`SaveData.apply()` recorta el oro con `whole()` y después le suma lo que dan los objetos retirados (`_sell_retired()`). Con un archivo editado a mano (9 999 999 G y algún Incienso) el oro acaba por encima del tope. Se arregla recortando después de sumar, con un test que falla antes del arreglo (`test_the_gold_of_retired_items_stays_within_the_cap`).

Los retoques de los tests (de las revisiones de la 3.9.0), en el mismo punto: `_first_with()` de `test_chests.gd` falla con un mensaje en vez de devolver `""` en silencio, el test de los pozos de `test_wells.gd` deja de llamarse «ten battles», `test_run_flags.gd` dice por qué su `after_each()` no lleva `-> void` (la firma de GUT 9.7.1) y el test de las misiones de la Caravana que se van con su jefe comprueba también que antes del jefe sí se ofrecen.

## 4. Fuera de alcance

- Otros aspectos de figuras (tenderos, posaderos, domadoras): la idea habla del armero.
- Modelos nuevos o descargas.
- Cambiar la EXP, los enemigos o los premios.
- Una versión nueva de la partida guardada.

## Verificación

- `--check-only` en cada script cambiado, `--import` tras las dos clases nuevas, `gen_ui_tokens.gd -- --check` y `check_ui_values.gd`. Ninguna orden usa la carpeta de datos real (`APPDATA` en una carpeta de pruebas escrita a mano).
- Los tests (GUT) en cada tarea y al final: 172, todos en verde, sin `ERROR`.
- Fotogramas de cerca (en ventana, no headless) de los ocho aspectos nuevos, de frente, de tres cuartos y de espaldas, y del Herrero de cristal para comparar. Sin `ERROR` en la salida.
- Todas las carreras del piloto automático con `scripts/tools/autoplay_all.sh`, en OK. El equilibrio no cambia: `autoplay_expected.json` no se toca.
- Queda para el usuario:
  - ver cada armero en su pueblo, de día y de noche, en el PC y en el móvil (740 × 360);
  - una partida suya de la 3.9.0 en el 56-60, si la tiene: carga en el 55.
- La guía de QA (pruebas nuevas tras la T-254), CLAUDE.md, la skill del piloto, `assets/CREDITS.md`, el CHANGELOG y el documento maestro, al día.
