# Versión 2.4.0: lo que pide el usuario tras jugar la v2

Fecha: 2026-11-11. Parte de la 2.3.0 (la v2 completa). Cubre M-49 a M-54, los seis puntos del usuario tras jugar la 2.3.0. Textos nuevos: [anexo de textos](2026-11-11-version-2-4-0-textos.md).

## Objetivo

Seis retoques de la v2 que salen de jugarla de verdad: las misiones de recoger dan lo que piden, todas se entregan al Jefe de caravana, hay más monstruos en las zonas de la caravana, el héroe ya no se "camufla" bajo las palmeras, la gente de la caravana parece gente y no brujas, y los personajes dicen alguna tontería de vez en cuando.

El guardado sigue en la **versión 14**: no hace falta ningún campo nuevo (ver "Guardado").

## M-49. Las pieles de mono: siempre que hacen falta

### Lo que pasa

El usuario: si el mono sale con otro enemigo y lo matas, no da la piel; solo la da cuando sale solo.

### Causa (medida)

**No es un error del código: es el azar y la escasez.**

- El motor tira la suerte de cada enemigo vencido, venga solo, en pareja o llamado como ayuda: `BattleEngine._win()` recorre `enemies` entero (`scripts/battle/battle_engine.gd:632-637`) y una piel va directa al `Inventory` del héroe (`inventory.add(id)`, línea 635), el mismo objeto que `GameState.inventory` (`BattleScene.setup()`, `battle_scene.gd:112-114`; `Game._on_encounter()`, `game.gd:679`).
- La misión `GATHER` no cuenta combates: mira el inventario (`QuestLog._is_ready()` y `_progress()`, `quest_log.gd:282-310`). Da igual quién matara al mono (el héroe o el compañero) o cuántos enemigos hubiera.
- Comprobado con un script de prueba sobre el motor (1000 combates por formación, el héroe contra el mono, con Brena): mono solo, 48 % de pieles (en 379 de los 1000 pidió ayuda a la Rana dardo y aun así la dio); mono con Planta trampa, 53 %.
- La partida automática de la jungla (`--autoplay-zone=jungla`) mató 13 monos y sacó 4 pieles: 2 de 5 monos solos, 2 de 5 monos con la planta y 0 de 3 monos que pidieron ayuda. Es una racha corriente con una suerte del 50 % (`data/enemies/mono_aullador.tres`, `drops` 0,5), y quien juega a mano la lee como una regla.
- El mono sale en 2 de las 8 formaciones de la jungla y en ninguna de las del principio (`data/zones/jungla.tres:75-76`): unos 3 o 4 monos por visita, menos de 2 pieles. De ahí el "tienes que entrar y salir varias veces" (M-51).

Las demás misiones de la v2 se revisaron igual:

- `escorpiones`, `cabras` y `centinelas` (`HUNT`) cuentan en `QuestLog.on_victory()` (`quest_log.gd:78-92`) cada enemigo de `battle.engine.enemies` (`game.gd:734-735`), también los llamados como ayuda: el centinela de ayuda es otro archivo con el mismo id (`esqueleto_centinela_ayuda.tres`, `id = "esqueleto_centinela"`) y cuenta. Están bien.
- `cristales_hielo` (`GATHER`) tiene el mismo problema que las pieles: el Golem de hielo suelta el cristal al 40 % (`golem_hielo.tres`).

### Decisión

**Un objeto de misión cae siempre mientras una misión lo pide, y nunca si no.** Es la opción que pide el usuario ("que la dé venga solo o con otros") sin tocar las formaciones, y deja claro en el juego qué pasa:

- `QuestLog.wanted_items(inventory)` → `{id: meta}`: los `target` de las misiones `GATHER` aceptadas (`ACTIVE`) que aún no tienen los que piden en el inventario.
- `BattleEngine` gana `quest_items` (`{id: meta}`, de `QuestLog.wanted_items()`; lo pone `Game` antes del combate, por `BattleScene`). En `_win()`, la suerte de un objeto con efecto `quest` en `Inventory.ITEMS` (la Seta, la Piel de mono, el Cristal de hielo) es 1,0 si está en `quest_items` y 0 si no; la de los demás objetos no cambia. Con cuatro monos, cuatro pieles; con la misión cumplida (o aún sin aceptar), ninguna, para que no se llene la bolsa de pieles que no sirven.
- Si un combate lleva más de un mono, cada uno deja la suya mientras la misión las pida todavía (el motor cuenta las que ya ha dado en ese combate contra lo que falta).
- Afecta a las tres misiones de recoger: `pieles_mono`, `cristales_hielo` y `setas` de la v1 (la Seta ya caía siempre, `mushroom.tres` 1,0; ahora deja de caer cuando la misión no la pide).
- El mensaje del combate dice cuántas lleva: "¡El Mono aullador ha dejado una Piel de mono! (2/4)". El evento `DROP` gana `progress` ("" si no es de misión); `BattleEngine` lo calcula con `inventory.count()` y la meta de `quest_items`.
- Un mono más en las formaciones de la jungla (M-51).

## M-50. Todas las misiones de la caravana se entregan al Jefe

### Lo que pasa

El usuario: las pieles se entregan al Mercader; al tocarlo se abre la tienda y no dice nada de la misión, aunque sobre su cabeza salga "?".

### Causa

- En la 2.0.0, `pieles_mono` se entregaba al Mercader (`data/quests/pieles_mono.tres`, `turn_in = "Mercader"`), que es una figura de tienda (`caravana.tres`, `kind` "shop"). `World._use()` manda `shop_requested` (`world.gd:1364-1365`) y `Game._on_shop()` abría la tienda sin mirar las misiones. Un jugador nunca podía entregarla; la partida automática sí, porque `_autoplay_restock()` visita las figuras con entrega (`game.gd:900-905`). Es el fallo que vio el usuario al jugar la jungla.
- La 2.1.0 lo arregló a medias (commit `912a05d`): `Game._figure_with_report()` (`game.gd:880-886`) entrega antes de abrir la tienda (`_on_shop()`, `game.gd:1386-1388`). Funciona igual con Intro, con un clic y con un toque (los tres pasan por `World._use()`), y la partida automática de la jungla lo confirma ("Mercader: ¡Cuatro pieles, y buenas!..." y luego la tienda). Si el usuario lo sigue viendo en la 2.3.0 es porque jugó la jungla antes de la 2.1.0, o porque la versión web sigue en la caché del service worker hasta que se cierran todas las pestañas.
- Lo que sigue mal en el diseño: la entrega en una tienda es un caso especial que solo existe para `shop`. Una posada (`_on_inn()`, `game.gd:1409`) no lo tiene, y nada impide que unos datos nuevos vuelvan a poner una entrega en una figura que abre una ventana.

Las misiones de la v1 están bien: `carta` y `lobos` se entregan a la Leñadora, `setas` al Granjero, `gato` a la Niña y `explorador` al Soldado (todas figuras `npc`); `slime_metal` acaba en el sitio (`turn_in` ""). De la v2, solo `pieles_mono` estaba en una tienda; `escorpiones`, `cantimplora`, `cabras` y `centinelas` ya iban al Jefe, y `explorador_perdido`, `cristales_hielo` (la Viajera) y `superviviente` (el Viajero) a quien las da.

### Decisión

1. **Las ocho misiones de la v2 se entregan al Jefe de caravana**, como pide el usuario: cambian `pieles_mono`, `explorador_perdido`, `cristales_hielo` y `superviviente` (`turn_in` "Jefe de caravana"). Quien la ofrece sigue siendo el mismo (el tablón, la Viajera, el Viajero). Los textos que nombraban a otro (objetivo, `report`, ofertas, frases de espera y de entrega) pasan a nombrar al Jefe; están en el anexo. El Jefe habla de las hermanas Nara y la Viajera, del superviviente del Viajero, etc.
2. **Una charla con el Jefe entrega todo lo que espera.** Con todas las entregas en el mismo sitio pueden juntarse dos o tres. `QuestLog.talk()` junta las frases de cada entrega lista para esa figura (una tras otra, cada una con su pago) y devuelve `done` como lista de títulos. `Game._after_quest_talk()` enseña un "Misión cumplida" con todos ("Misión cumplida: Pieles para el frío · La exploradora perdida") y un solo sonido.
3. **Nunca más una entrega atascada en una tienda o una posada.** `_figure_with_report()` sirve para `shop` y para `inn`: `_on_inn()` entrega antes de que hable el posadero, como ya hace `_on_shop()`. Y `QuestLog.problems()` (estática, como `Decor.problems()`) da un `WARNING` al arrancar `Game` por cada misión cuyo `turn_in` no sea una figura `npc` o `quest` de su `turn_in_zone` ("Misión pieles_mono: se entrega a Mercader, que no es una figura con quien hablar"). Hoy no saldría ninguno.
4. **Guardado.** Nada cambia: `QuestLog.set_from()` (`quest_log.gd:271-279`) solo guarda etapa y cuenta por id, y quién entrega es dato. Un guardado con `pieles_mono` lista (4 pieles) o con `superviviente` en `REPORT` enseña "?" sobre el Jefe al cargarlo y se entrega allí.

## M-51. Más monstruos en las zonas de la caravana

### Lo que hay

`ZoneData.monster_count` y lo que cabe de verdad (`MonsterGroups.spots()` con 5 semillas, medido con un script):

| Zona | Hoy | Caben como mucho |
|---|---|---|
| `jungla` (70 × 90 m) | 14 | 38-40 |
| `desierto` (90 × 70 m) | 14 | 33-39 |
| `montana_1` (15 × 13 celdas) | 8 | 11 |
| `montana_2` (15 × 13) | 7 | 21-24 |
| `ciudad_1` (17 × 15) | 7 | 21-23 |
| `ciudad_2` (13 × 13) | 5 | 17-18 |

Los grupos vuelven todos cuando se construye el mapa otra vez: al cambiar de zona, al volver por el portal, al cargar y al dormir en una posada (`Game._respawn_groups()`). En la jungla no hay posada: para tener más monos hay que salir y entrar. Lo que no deja poner más grupos no son las reglas de `MonsterGroups` (`MIN_GAP` 8 m, los márgenes): es `monster_count`.

### Decisión

| Zona | Grupos | Formaciones |
|---|---|---|
| `jungla` | 14 → **22** | + `["mono_aullador"]` (tres de nueve con mono) |
| `desierto` | 14 → **22** | igual |
| `montana_1` | 8 → **11** (lo que cabe) | igual |
| `montana_2` | 7 → **12** | igual |
| `ciudad_1` | 7 → **12** | igual |
| `ciudad_2` | 5 → **9** | igual |

- Con 22 grupos y tres formaciones de mono de nueve, una visita a la jungla trae unos 6 monos: con M-49, las cuatro pieles en una sola visita.
- `MonsterGroups` no cambia: las reglas de sitio ya dejan pasar estos números, y el sendero sigue libre.
- **La v1 no cambia.** El usuario juega ahora la v2, y la v1 está ajustada al minuto con la Partida nueva + (`NgPlus`); tocar sus grupos rompería ese ajuste.
- **El ritmo se reajusta después.** Más grupos dan más EXP y oro por pasada. El plan baja la EXP y el oro de los enemigos normales de la v2 (no los de los jefes) hasta que la partida automática vuelva a los números de la 2.3.0: el Jaguar a Nv 24-25, el Devorador a Nv 39-40 y la v2 entera en 1:50-2:20 con los tres compañeros. Punto de partida: ×0,7 la EXP y ×0,75 el oro, zona a zona.
- En el móvil, más figuras en el mapa: los grupos lejanos ya no se animan (`GROUP_ANIMATE_RADIUS` 30 m). El plan mira las llamadas de dibujo de la jungla y el desierto con 22 grupos frente a 14.

## M-52. Sin agujero en los árboles; el héroe se ve bajo su sombra

### Lo que pasa

El usuario: el truco para ver al héroe detrás de una palmera queda feo; y al pisar la sombra de una palmera sale el mismo efecto, como si el héroe estuviera detrás. Quiere quitar del todo el "ver a través" de palmeras, árboles y lo demás (si el héroe queda tapado por un árbol, está bien), y que sobre la sombra el héroe se vea y no se camufle.

### Causa

- `shaders/tree.gdshader` abre un agujero tramado (Bayer 4 × 4, deja el 20 % de los píxeles) en un cilindro de 1,4 m alrededor de la línea entre el pecho del héroe y `CAMERA_POSITION_WORLD` (`tree.gdshader:31-41`), con `discard`. La posición del héroe es el parámetro global `hero_pos` (`project.godot:72`), que `World` pone cada paso de física (`world.gd:398`) y quita al salir (`world.gd:455`). Lo usan todos los árboles (las palmeras de `PalmModels` incluidas), los arbustos y la decoración de Kenney (`world_stage.gd:464`, `512`, `545`), en todos los mapas abiertos.
- **La sombra:** como el shader hace `discard`, Godot lo ejecuta también al dibujar el mapa de sombras del sol. En esa pasada, `CAMERA_POSITION_WORLD` es la cámara de la sombra, que está en la dirección del sol, y `FRAGCOORD` son píxeles del mapa de sombras. El agujero se abre entonces en la línea entre el héroe y el sol: justo la parte de la copa que hace sombra sobre él. La sombra de la palmera sale agujereada y tramada encima del héroe, y la túnica azul oscura con esa trama de luz y sombra parece un camuflaje.

### Decisión

1. **Fuera el agujero, en todos los mapas.** `tree.gdshader` se queda solo con lo suyo (textura, color, colores de vértice) y sin `discard`; se quitan `hero_pos` de `project.godot`, `HERO_POS_PARAM` / `NO_HERO_POS` y sus dos llamadas en `World`, y los comentarios que hablan del agujero (`WorldStage`, `PalmModels`, `NatureModels`, `CLAUDE.md`). Sin `discard`, la sombra de un árbol vuelve a ser entera: el héroe camina por encima de ella como por el suelo.
2. **Las paredes de las mazmorras siguen como están.** `DungeonMap.see_through()` (mina, castillo, montaña, ciudad) no es este efecto: vuelve medio transparentes las rocas y muros de las dos filas al sur del héroe, sin trama. Sin eso, en un pasillo de este a oeste la pared del sur taparía al héroe todo el rato. El usuario hablaba de palmeras y árboles; las paredes no se tocan.
3. **El héroe se lee sobre la sombra.** Lo más bonito que casa con el estilo low-poly: **un borde de luz suave** (rim) en el héroe del mapa, y además un poco de luz propia para que no se apague del todo:
   - `BattleActor.set_map_readable(on)`, que llama `Player` al crear su figura (solo el héroe del mapa; en combate no). Cada malla del héroe (cuerpo, brazos, piernas, cabeza, capa y lo que lleve en las manos y en la cabeza) gana un `next_pass` con un shader nuevo, `shaders/hero_rim.gdshader`: sin sombreado, mezcla aditiva, color blanco cálido, fuerza `pow(1 - dot(N, V), 3) × 0,35`. Se ve igual al sol que a la sombra, solo en el contorno.
   - Y un levantamiento de las sombras: la emisión de los materiales del héroe toma su propia textura con energía 0,12, para que la túnica no se vuelva negra en la sombra. Al sol casi no se nota.
   - Los valores finales se eligen con fotogramas al sol, a la sombra de una palmera, en la mina con el farol y en el móvil. Si el borde se ve como un brillo raro sobre las caras planas, se baja; no se cambia por un contorno oscuro, que en la sombra no ayuda.
4. **Lo que dijo la QA de la 1.1.0** (I09: "árboles y arbustos tapan al héroe") queda sustituido por esta decisión del usuario: un héroe tapado por una copa es aceptable.

## M-53. La gente de la caravana: personas, como el héroe

### Lo que hay

Las figuras de la v2 que hoy son el `Mage.glb` (el mago de la v1, con su gorro de bruja):

| Figura | Dónde | Hoy |
|---|---|---|
| Jefe de caravana | `caravana`, `ciudad_2` (escena `cruce`), `pradera` (antes de partir) | `CARAVAN_CHIEF`, el mago en marrón |
| Mercader | `caravana` | `MERCHANT` (el de la v1) |
| Curandera | `caravana` | `HEALER`, el mago en blanco y verde |
| Viajera | `caravana` | `VILLAGER` (el de la v1) |
| Viajero | `caravana` | `FARMER` (el de la v1) |
| Exploradora (Nara) | `jungla` | `VILLAGER` |
| Superviviente | `ciudad_1` | `VILLAGER` |

Los compañeros (Brena, Tadeo, Ulma) ya son el `Knight.glb`, y no cambian. Las escenas usan las figuras de las zonas. La Domadora y demás figuras de la v1 no cambian.

### Decisión (del usuario)

**Las figuras de la caravana son como el héroe: el Knight sin casco, con otro peinado si se puede y otros colores de pelo, piel y ropa. Sin sombreros, turbantes ni cascos.**

- **El pelo, con el truco del héroe.** La cara y el pelo comparten la malla de la cabeza; el héroe usa `hero_head_texture.png`, el atlas del Knight con la celda del pelo (x 128-255, y 0-255) multiplicada por un marrón. Un script de una vez (como el de la 1.x, fuera del juego) hace una textura por color de pelo: **gris**, **negro**, **rubio**, **pelirrojo** y **castaño oscuro**, `assets/characters/head_<color>.png`. Si en el atlas se encuentra la celda de la piel de la cara, el mismo script saca la variante **morena** de la que haga falta (la piel de los brazos ya se tiñe con `mesh_tints`).
- **El peinado, en código, si queda bien.** Tres piezas pequeñas hechas con `LowPoly` (facetadas, como los slimes y los arbustos), colgadas del hueso `head` con un `BoneAttachment3D` y del color del pelo: **barba** (una cuña bajo la barbilla), **moño** (una esfera detrás y arriba) y **coleta** (un cono que cae por la nuca). Se miran en fotogramas de cerca y desde la cámara del mapa; la que no asiente bien en la cabeza en todas las animaciones se quita y esa figura se queda solo con el color.
- **La ropa**, con `mesh_tints` como el héroe (`Knight_Body`, brazos, piernas) y la capa (`Knight_Cape`) teñida u oculta.
- `BattleActor` gana `head_texture` y `hair` en `LOOKS` (además de `mesh_tints`), y una función que los aplica a cualquier Knight (hoy solo el héroe tiene ese código, `battle_actor.gd:1293-1297`).

| Figura | Look | Pelo | Peinado | Piel | Ropa | Capa |
|---|---|---|---|---|---|---|
| Jefe de caravana | `CARAVAN_CHIEF` (×1,05) | gris | barba (la escena `caravana_llega` dice "un hombre de barba gris") | la del héroe | túnica marrón, piernas marrón oscuro | verde oscuro |
| Mercader | `CARAVAN_MERCHANT` (nuevo; el `MERCHANT` de la v1 sigue igual) | negro | sin peinado extra | morena | túnica mostaza, piernas oscuras | morada |
| Curandera | `HEALER` | pelirrojo | moño | la del héroe | túnica blanca, piernas verde pálido | verde |
| Viajera | `TRAVELLER_F` (nuevo) | rubio | coleta | la del héroe | túnica turquesa, piernas grises | sin capa |
| Viajero | `TRAVELLER_M` (nuevo) | castaño oscuro | sin peinado extra | morena | túnica roja teja, piernas grises | marrón |
| Exploradora (Nara) | `EXPLORER` (nuevo) | rubio (hermana de la Viajera) | coleta | la del héroe | túnica verde, piernas de cuero | sin capa |
| Superviviente | `SURVIVOR` (nuevo) | castaño oscuro | barba (de semanas escondido) | pálida | túnica gris sucia, piernas grises | sin capa |

- Todos con los brazos al aire como el héroe, sin armas (todo lo de las manos oculto) y con `CHARACTER_ANIMS`.
- El héroe (pelo castaño, túnica azul, capa roja), Brena (roja, con casco), Tadeo (verde) y Ulma (gris azulado, con casco) siguen siendo distintos de todos ellos.
- Las figuras cambian de `look` en `caravana.tres`, `jungla.tres`, `ciudad_1.tres`; el Jefe de `ciudad_2.tres` y `pradera.tres` ya es `CARAVAN_CHIEF`.

## M-54. Los personajes, con un poco más de gracia

### Lo que hay

Las frases de la v2 son correctas pero serias: el Jefe (por capítulo), la Viajera, el Viajero, el tablón, la Exploradora, el Superviviente, las ocho misiones (ofertas, esperas, entregas), las escenas y las dos frases del Jefe en `Game._choose_companion()`. La v1 ya tiene el tono que pide el usuario (el Granjero y sus gallinas que ponen los huevos de lado).

### Decisión

- **Una broma de vez en cuando:** en lo primero que dice el Jefe en cada capítulo, en las frases de misión cumplida, en alguna frase de la Viajera, el Viajero y la Curandera, y en una frase nueva del compañero al llegar a cada zona. Las ofertas, las esperas, los objetivos y las escenas siguen diciendo qué hacer sin rodeos. Todo está en el [anexo de textos](2026-11-11-version-2-4-0-textos.md), listo para pegar.
- **La llegada a cada zona (nuevo):** la primera vez que el héroe llega a `jungla`, `desierto`, `montana_1` y `ciudad_1`, tras el rótulo del lugar, el compañero dice una frase suya (`Allies.arrival_line(id, zone_id)`: doce frases, una por compañero y zona). Se recuerda con una bandera del mundo, `llegada_<zona>` (las banderas son texto libre en el guardado). Sin compañero no dice nada. En la partida automática se imprime y sigue.
- **La Curandera** tiene sus propias frases de posada (`Inn.LINES`, solo la posada `caravana`); las posadas de la v1 siguen con `Inn.REST` / `Inn.FULL`.
- Las preguntas de partir (`JOIN_QUESTION`, `LEAVE_QUESTION`), las escenas de los jefes y el final no cambian: son los momentos serios.

## Qué cambia, por archivo

| Archivo | Cambio |
|---|---|
| `scripts/battle/battle_engine.gd` | `quest_items` (`{id: meta}`); en `_win()` un objeto de misión cae siempre si se pide y nunca si no; el `DROP` lleva `progress` |
| `scripts/battle/battle_event.gd`, `battle_scene.gd` | el `DROP` con "(n/m)"; `BattleScene.quest_items` pasa al motor |
| `scripts/game/quest_log.gd` | `wanted_items()`; `talk()` entrega todas las listas de una figura (`done` lista); `problems()` |
| `scripts/game/game.gd` | `quest_items` al combate; `_after_quest_talk()` con varias misiones; `_on_inn()` entrega primero; `QuestLog.problems()` al arrancar; la frase del compañero al llegar (`_check_arrival_line()` tras el rótulo); las frases nuevas de `_choose_companion()` |
| `scripts/game/inn.gd` | `LINES` por posada (la Curandera) |
| `scripts/game/allies.gd` | `ARRIVALS` y `arrival_line()` |
| `data/quests/*.tres` (las 8 de la v2) | `turn_in` al Jefe donde falta; los textos del anexo |
| `data/zones/` (las 6 de la v2 con grupos, `caravana`, `pradera`) | `monster_count`, el mono de más en la jungla, las frases y los `look` nuevos |
| `data/cutscenes/caravana_campamento.tres` | la frase del Jefe del anexo |
| `data/enemies/*` (normales de la v2) | EXP y oro reajustados con la partida automática |
| `shaders/tree.gdshader`, `project.godot`, `scripts/world/world.gd`, `world_stage.gd` | fuera el agujero y `hero_pos` |
| `shaders/hero_rim.gdshader` (nuevo), `scripts/world/player.gd`, `scripts/battle/battle_actor.gd` | el borde de luz del héroe del mapa (`set_map_readable()`); los looks nuevos de la caravana, el pelo y los peinados |
| `assets/characters/head_*.png` (nuevos, con su `.import`) | las cabezas con otro pelo; `assets/CREDITS.md` lo dice |
| `CLAUDE.md`, `CHANGELOG.md`, `project.godot` (versión 2.4.0) | lo de siempre al cerrar la versión |

## Lo que no cambia

- La v1: sus grupos, sus figuras, sus textos y su ajuste (también la Partida nueva +). Solo cambian para ella el agujero de los árboles (fuera en todos los mapas), el borde de luz del héroe y que la Seta deje de caer cuando la misión `setas` no la pide.
- `MonsterGroups`, `MonsterRoam` y la regla de reaparición.
- Las paredes medio transparentes de las mazmorras (`DungeonMap.see_through()`).
- Los compañeros (looks, números, frases de la lista).
- El guardado: versión 14, sin campos nuevos. Las banderas `llegada_<zona>` son banderas del mundo como las demás.
- El brief de QA: no cubre la v2.

## Partida automática y ajuste

- `--autoplay-zone=jungla` con los tres compañeros: las cuatro pieles en la primera visita a la jungla (antes, tres visitas), entregadas al Jefe en la primera retirada; el Jaguar a Nv 24-25 en 23-28 min como en la 2.0.0.
- `--autoplay-zone=caravana` (la v2 entera) con los tres compañeros: las ocho misiones de la caravana, todas entregadas al Jefe ("Jefe de caravana: ..."); `Juego completado (v2): ...` en 1:50-2:20 con el Devorador a Nv 39-40. Si se pasa de nivel o de tiempo, se baja la EXP y el oro de los enemigos normales de la zona que se adelanta, como en la 2.3.0.
- La partida automática dice la frase del compañero al llegar (`Compañero: ...`) y no se para.
- La v1 entera (`--autoplay`) sigue en Nv 18 a 1:12-1:26 con 5 misiones: solo cambia la Seta, que ya caía siempre.

## Verificación a mano

Sin pruebas automáticas de ningún tipo (decisión del usuario). Se comprueba así:

- `--check-only` de cada script tocado; `--import` tras añadir las texturas y el shader.
- Las partidas automáticas de arriba, leyendo la salida: ningún `ERROR` ni `WARNING` nuevo (el de Jolt es el ruido conocido) y ningún `WARNING` de `QuestLog.problems()`.
- Ida y vuelta del guardado (`--autoplay-save`): las líneas `Guardado:` y `Cargado:` iguales.
- Un guardado de la 2.3.0 con `pieles_mono` lista (4 pieles) y otro con `superviviente` en `REPORT`, hecho con `--debug`: al cargarlos, "?" sobre el Jefe y entrega al hablar con él.
- Fotogramas (`--write-movie`, no headless) de: la jungla con el héroe detrás de una palmera (tapado, sin trama) y sobre su sombra (sombra entera, el héroe con su borde de luz); el desierto, el bosque y la pradera igual; la mina con el farol; la Caravana con sus seis figuras de cerca y desde la cámara del mapa; Nara en la jungla y el Superviviente en la ciudad. Lo mismo a 740 × 360 con `--touch`.
- Una partida a mano en la jungla: un mono con la planta da su piel "(1/4)", y otro que pide ayuda también.
- Pendiente para el usuario: jugarlo en un móvil real (el borde de luz y las figuras nuevas en una pantalla pequeña).
