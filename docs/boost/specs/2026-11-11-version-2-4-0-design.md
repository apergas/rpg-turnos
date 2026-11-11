# Versión 2.4.0: lo que pide el usuario tras jugar la v2

Fecha: 2026-11-11. Parte de la 2.3.0 (la v2 completa). Cubre M-49 a M-55, los puntos del usuario tras jugar la 2.3.0 (M-55, el campamento vestido según el tramo, llegó después de la revisión del spec). Textos nuevos: [anexo de textos](2026-11-11-version-2-4-0-textos.md).

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

- `QuestLog.wanted_items(state)` → `{id: meta}`: los `target` de las misiones `GATHER` que no están `DONE` y que están aceptadas (`ACTIVE`) **o se pueden ofrecer ya** (`_offered()`: su `needs` puesto), mientras el inventario no tenga los que piden. Así un mono vencido antes de leer el tablón de la Caravana también da su piel, que es justo lo que pedía el usuario.
- `BattleEngine` gana `quest_items` (`{id: meta}`, de `QuestLog.wanted_items()`; lo pone `Game` antes del combate, por `BattleScene`). En `_win()`, la suerte de un objeto con efecto `quest` en `Inventory.ITEMS` (la Seta, la Piel de mono, el Cristal de hielo) es 1,0 si está en `quest_items` y 0 si no; la de los demás objetos no cambia. Con cuatro monos, cuatro pieles; con la misión cumplida (o antes de que se pueda ofrecer), ninguna, para que no se llene la bolsa de pieles que no sirven.
- Si un combate lleva más de un mono, cada uno deja la suya mientras la misión las pida todavía (el motor cuenta las que ya ha dado en ese combate contra lo que falta).
- Afecta a las tres misiones de recoger: `pieles_mono`, `cristales_hielo` y `setas` de la v1 (la Seta ya caía siempre, `mushroom.tres` 1,0; ahora deja de caer cuando la misión está cumplida). `setas` no tiene `needs`: se puede ofrecer desde el principio, así que una partida de la v1 sigue sacando setas antes de leer el tablón de Villaclaro. Aun así la v1 y la Partida nueva + se vuelven a medir con la partida automática (ver "Partida automática y ajuste"); no se da por hecho que no cambian.
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
2. **Una charla con el Jefe entrega todo lo que espera.** Con todas las entregas en el mismo sitio pueden juntarse dos o tres. `QuestLog.talk()` junta las frases de cada entrega lista para esa figura (una tras otra, cada una con su pago) y devuelve `done` como lista de títulos, y además `kind` (`"report"`, `"found"`, `"offer"` o `"wait"`). `Game._after_quest_talk()` pasa a recibir la lista; sus dos llamadas cambian: `_on_npc()` y `_on_talk()` (la Abuela Rosa, `game.gd:1243`, que manda `[]` o un título). Enseña un solo aviso con un solo sonido: con una misión, "Misión cumplida: Pieles para el frío"; con varias, en el escritorio "Misión cumplida: Pieles para el frío · La exploradora perdida" y en el móvil (`Device.is_touch()`, donde la ventana de estado tiene una línea de 300 px) "Misiones cumplidas: 2".
3. **Qué dice el Jefe en cada caso.** Hoy `talk()` devuelve las frases de espera de cualquier misión activa que se le entregue a esa figura (el último bucle de `talk()`, `quest_log.gd:134-144`), y entonces `_on_npc()` ya no dice las frases de capítulo (`game.gd:1298-1301`). Con las ocho misiones en el Jefe, desde la jungla casi siempre tendría una esperando y nunca diría "la montaña está al norte" ni su broma del capítulo. La regla, en la Caravana y una vez elegido el compañero:
   - **Hay entregas listas:** dice las frases de entrega de cada una, en el orden de `QuestLog.QUESTS`, cada una con su pago. Nada más.
   - **No hay entregas, pero sí misiones suyas en curso** (`kind` `"wait"`): primero sus frases del capítulo (`World.npc_lines()`), y después la primera frase de espera de la primera misión en curso (orden de `QUESTS`), con "Llevas n de m." detrás si es de cazar o de recoger varias. Una sola misión, para que no se haga largo; las demás están en el Diario.
   - **Nada en curso:** sus frases del capítulo, como hoy.
   - La regla es solo del Jefe de caravana (`CARAVAN_CHIEF`). Las figuras de la v1 que esperan una entrega (la Leñadora, el Granjero, el Soldado) siguen diciendo solo su frase de espera.
4. **Nunca más una entrega atascada en una tienda o una posada.** `_figure_with_report()` sirve para `shop` y para `inn`: `_on_inn()` entrega antes de que hable el posadero, como ya hace `_on_shop()`. Y `QuestLog.problems()` (estática, como `Decor.problems()`) da un `WARNING` al arrancar `Game` por cada misión cuyo `turn_in` no sea una figura `npc` o `quest` de su `turn_in_zone` ("Misión pieles_mono: se entrega a Mercader, que no es una figura con quien hablar"), o cuya figura pueda faltar cuando la misión está lista: si la figura tiene `needs` o `gone` (`ZoneData.is_present()`), su `needs` tiene que ser el `needs` de la misión o uno que siempre esté puesto antes que él, y su `gone` no puede ser una bandera que llegue antes de que la misión se pueda cumplir. Hoy no saldría ninguno.
5. **Guardado.** Nada cambia: `QuestLog.set_from()` (`quest_log.gd:271-279`) solo guarda etapa y cuenta por id, y quién entrega es dato. Un guardado con `pieles_mono` lista (4 pieles) o con `superviviente` en `REPORT` enseña "?" sobre el Jefe al cargarlo y se entrega allí.
6. **Nara y el Superviviente vuelven a la Caravana.** Hoy, una vez encontrados, desaparecen para siempre (`hidden_figures()` los quita del mapa en cuanto su misión deja `ACTIVE`, `quest_log.gd:186-193`), y sus frases de después (`jungla.tres:67`, `ciudad_1.tres:57`) nunca se oyen. Traerlos es barato: `QuestData` gana `done_flag` (texto, "" por defecto), que `QuestLog._finish()` pone en las banderas del mundo; `explorador_perdido` pone `nara_vuelve` y `superviviente` pone `superviviente_vuelve`. `caravana.tres` gana dos figuras `npc` con ese `needs`: **Nara** (junto a la Viajera, su hermana) y el **Superviviente** (junto al fuego), con las frases del anexo. Un guardado con esas misiones ya `DONE` recibe la bandera al cargarse (`SaveData.apply()`, un bucle sobre las misiones con `done_flag`; sin campo nuevo). Las frases de la Exploradora en `jungla.tres` y del Superviviente en `ciudad_1.tres` no se tocan: no se ven nunca.

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
| `montana_1` | 8 → **10** (caben 11, pero al reponerlos lejos del héroe, `ENTRY_GAP` 10 m, a menudo salen 9-10) | igual |
| `montana_2` | 7 → **12** | igual |
| `ciudad_1` | 7 → **12** | igual |
| `ciudad_2` | 5 → **9** | igual |

- Con 22 grupos y tres formaciones de mono de nueve, una visita a la jungla trae unos 6 monos: con M-49, las cuatro pieles en una sola visita.
- `MonsterGroups` no cambia: las reglas de sitio ya dejan pasar estos números, y el sendero sigue libre.
- **La v1 no cambia.** El usuario juega ahora la v2, y la v1 está ajustada al minuto con la Partida nueva + (`NgPlus`); tocar sus grupos rompería ese ajuste.
- **Combates obligados.** En `montana_2` y `ciudad_1`, 12 grupos en 21-24 celdas de sala dejan un grupo en casi cada sala, y algunas salas son paso obligado. El ajuste mira también cuántos combates se pelean sin querer al cruzar la planta (la partida automática sin cazar, `_autoplay_hunts()` falso): si un cruce pasa de 4 o 5 combates, esa planta baja a 10.
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
   - **Nunca en los materiales compartidos.** Los materiales importados del `Knight.glb` (la capa, las armas y escudos de las manos, el casco) son los mismos para todos los Knight: Brena, Tadeo, Ulma, el héroe en combate y las siete figuras nuevas de la caravana (M-53). Por eso el efecto no va en `next_pass` ni en la emisión de un material, sino en **`material_overlay`**, que es una propiedad de cada `MeshInstance3D` (de esa figura, no del material). En el mapa nadie más lo usa: el destello de golpe y el brillo de apuntar (`battle_actor.gd:2176-2187`) solo existen en combate.
   - `BattleActor.set_map_readable(on)`, que llama `Player` al crear su figura: solo el héroe del mapa; ni en combate, ni los compañeros, ni las figuras. Pone en el `material_overlay` de cada `MeshInstance3D` del héroe (cuerpo, brazos, piernas, cabeza, capa, lo de las manos, el casco y los cuernos del Yelmo de bruma, también los ocultos) un mismo `ShaderMaterial` con un shader nuevo, `shaders/hero_rim.gdshader`: sin sombreado, mezcla aditiva, sin escribir profundidad. Suma dos cosas: **el borde**, blanco cálido, `pow(1 - dot(N, V), 3) × 0,35`, y **la luz propia**, un tono cálido constante muy bajo (del orden de 0,03-0,05 en lineal), para que la túnica no se vuelva negra en la sombra. Se ve igual al sol que a la sombra; al sol la luz propia casi no se nota.
   - **Se vuelve a poner tras cambiar de equipo.** `set_equipment()` cambia los materiales de las manos y del casco (`battle_actor.gd:1003-1037`) y `_build_horns()` crea mallas nuevas. Al final de `set_equipment()`, si `set_map_readable()` está activo, se repasan todas las `MeshInstance3D` del héroe y se les pone el overlay otra vez (`_apply_map_overlay()`).
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

- **El pelo, con el truco del héroe.** La cara y el pelo comparten la malla de la cabeza; el héroe usa `hero_head_texture.png`, el atlas del Knight (1024 px) con la celda del pelo multiplicada por un marrón (comparando las dos imágenes, el cambio está en x 128-252, y 0-252). El script que lo hizo en la 1.x no está en el repositorio: **el plan escribe uno nuevo**, `scripts/tools/head_textures.gd`, que se queda en `scripts/tools/` (fuera de la exportación por el `exclude_filter` de `export_presets.cfg`, como `bestiary_shots.gd`). Parte de `Knight_knight_texture.png` y escribe `assets/characters/head_<pelo>_<piel>.png` (con su `.import`, `mipmaps/generate=true` como el del héroe).
- **Los colores de pelo:** gris, negro, rubio, pelirrojo y castaño oscuro, cada uno un multiplicador de la celda del pelo, como el marrón del héroe.
- **La piel, tres tonos.** **Clara**: la del héroe (la celda de la cara sin cambiar; brazos `HERO_SKIN`). **Morena**: celda de la cara × (0,78, 0,62, 0,50); brazos `HERO_SKIN` × lo mismo. **Pálida**: celda de la cara × (1,0, 0,94, 0,90) y un poco menos saturada; brazos igual. El script busca la celda de la piel de la cara con las UV de `Knight_Head` que no caen en la celda del pelo.
- **Si la celda de la cara no se puede teñir sola** (comparte celda con otra cosa del atlas, o el resultado se ve manchado), **todas las figuras se quedan con la piel del héroe, brazos incluidos**: unos brazos morenos bajo una cara clara se verían mal. Entonces las texturas son solo de pelo, `head_<pelo>.png`.
- Solo se hacen las combinaciones que se usan: `gris_clara`, `negro_morena`, `pelirrojo_clara`, `rubio_clara`, `castano_morena` y `castano_palida`.
- **El peinado, en código, si queda bien.** Tres piezas pequeñas hechas con `LowPoly` (facetadas, como los slimes y los arbustos), colgadas del nodo `Rig/Skeleton3D/head` (el `BoneAttachment3D` de la cabeza, que ya existe en `Knight.glb`) y del color del pelo (el color medio de la celda del pelo ya teñida, que imprime el script de las texturas y va como constante en `BattleActor`, para que la pieza plana case con la textura sombreada): **barba** (una cuña bajo la barbilla), **moño** (una esfera detrás y arriba) y **coleta** (un cono que cae por la nuca). Se miran en fotogramas de cerca y desde la cámara del mapa; la que no asiente bien en la cabeza en todas las animaciones se quita y esa figura se queda solo con el color.
- **La ropa**, con `mesh_tints` como el héroe (`Knight_Body`, brazos, piernas) y la capa (`Knight_Cape`) teñida u oculta.
- `BattleActor` gana `head_texture` y `hair` en `LOOKS` (además de `mesh_tints`), y una función que los aplica a cualquier Knight (hoy solo el héroe tiene ese código, `battle_actor.gd:1293-1297`).

| Figura | Look | Pelo | Peinado | Piel | Ropa | Capa |
|---|---|---|---|---|---|---|
| Jefe de caravana | `CARAVAN_CHIEF` (×1,05) | gris | barba (la escena `caravana_llega` dice "un hombre de barba gris") | la del héroe | túnica marrón, piernas marrón oscuro | verde oscuro |
| Mercader | `CARAVAN_MERCHANT` (nuevo; el `MERCHANT` de la v1 sigue igual) | negro | sin peinado extra | morena | túnica mostaza, piernas oscuras | morada |
| Curandera | `HEALER` | pelirrojo | moño | la del héroe | túnica blanca, piernas verde pálido | verde |
| Viajera | `TRAVELLER_F` (nuevo) | rubio | coleta | la del héroe | túnica turquesa, piernas grises | sin capa |
| Viajero | `TRAVELLER_M` (nuevo) | castaño oscuro | sin peinado extra | morena | túnica roja teja, piernas grises | marrón |
| Exploradora (Nara) | `EXPLORER` (nuevo) | rubio (hermana de la Viajera) | coleta | la del héroe | túnica naranja tostado (no verde: un Knight verde sin casco es Tadeo), piernas de cuero | sin capa |
| Superviviente | `SURVIVOR` (nuevo) | castaño oscuro | barba (de semanas escondido) | pálida | túnica gris sucia, piernas grises | sin capa |

- Todos con los brazos al aire como el héroe, sin armas (todo lo de las manos oculto) y con `CHARACTER_ANIMS`.
- El héroe (pelo castaño, túnica azul, capa roja), Brena (roja, con casco), Tadeo (verde) y Ulma (gris azulado, con casco) siguen siendo distintos de todos ellos.
- Las figuras cambian de `look` en `caravana.tres`, `jungla.tres`, `ciudad_1.tres`; el Jefe de `ciudad_2.tres` y `pradera.tres` ya es `CARAVAN_CHIEF`. Nara y el Superviviente de la Caravana (M-50) usan `EXPLORER` y `SURVIVOR`.

## M-54. Los personajes, con un poco más de gracia

### Lo que hay

Las frases de la v2 son correctas pero serias: el Jefe (por capítulo), la Viajera, el Viajero, el tablón, la Exploradora, el Superviviente, las ocho misiones (ofertas, esperas, entregas), las escenas y la frase del Jefe en `Game._choose_companion()` cuando no se elige a nadie. La v1 ya tiene el tono que pide el usuario (el Granjero y sus gallinas que ponen los huevos de lado).

### Decisión

- **Una broma de vez en cuando:** en lo primero que dice el Jefe en cada capítulo, en las frases de misión cumplida, en alguna frase de la Viajera, el Viajero y la Curandera, y en una frase nueva del compañero al llegar a cada zona. Las ofertas, las esperas, los objetivos y las escenas siguen diciendo qué hacer sin rodeos. Todo está en el [anexo de textos](2026-11-11-version-2-4-0-textos.md), listo para pegar.
- **La llegada a cada zona (nuevo):** la primera vez que el héroe llega a `jungla`, `desierto`, `montana_1` y `ciudad_1`, tras el rótulo del lugar, el compañero dice una frase suya (`Allies.arrival_line(id, zone_id)`: doce frases, una por compañero y zona). Se recuerda con una bandera del mundo, `llegada_<zona>` (las banderas son texto libre en el guardado). Sin compañero no dice nada. En la partida automática se imprime y sigue.
- **Guardados que ya pasaron por allí.** Al cargar, `Game` pone `llegada_<zona>` de cada zona cuyo jefe de tramo ya está vencido (`jungla` con `jaguar_sombrio`, `desierto` con `gusano_dunas`, `montana_1` con `grifo_cumbre`, `ciudad_1` con `guardian_ciudad`) y de la zona donde está el guardado: quien carga en medio de la jungla no oye la frase de llegar a ella.
- **La Curandera** tiene sus propias frases de posada (`Inn.LINES`, solo la posada `caravana`); las posadas de la v1 siguen con `Inn.REST` / `Inn.FULL`.
- Las preguntas de partir (`JOIN_QUESTION`, `LEAVE_QUESTION`), las escenas de los jefes y el final no cambian: son los momentos serios.

## M-55. El campamento de la caravana, vestido según dónde acampa

### Lo que pide el usuario

"El campamento base del desierto con arena, cactus, etc.; el de la jungla con más vegetación; el de la montaña como el mapa de la montaña; aunque no sea con mucho detalle, que se vea que estás en un sitio diferente." Hoy la Caravana (`caravana.tres`) es siempre un claro de tierra con árboles de la pradera, en los cuatro tramos.

### Decisión

- **La planta no cambia:** las tiendas, las figuras, las salidas, las entradas, los pozos, la hoguera, la ruta de la partida automática y todas las posiciones son las de `caravana.tres`. Así nada más se rompe (misiones, marcas del mapa, `ExploredMap`, guardados).
- **Cambia el aspecto, según `GameState.tramo()`:** colores del suelo, del camino y de las colinas; cielo, sol, niebla y bruma; `has_grass` y el color de la hierba; los árboles; la decoración de Kenney esparcida; las partículas y el ambiente (la música sigue siendo la de la caravana).

| Tramo | Acampa junto a | Aspecto (tomado de esa zona) |
|---|---|---|
| 1 | la jungla | colores, cielo y niebla de `jungla`, hierba alta, palmeras en los bordes, helechos y arbustos (`fern`, `leafy`), luciérnagas, ambiente `jungle` |
| 2 | el desierto | arena y cielo de `desierto`, sin hierba, unas pocas palmeras de oasis, cactus, matorral y piedras (`cactus`, `cactus_tall`, `scrub`), arena en el aire, ambiente `desert` |
| 3 | la montaña | el suelo gris y el cielo frío de `montana_1`, sin hierba ni árboles de la pradera, pinos y piedras con nieve (`pine`, `pine_small`, `snow_stones`, `rock_tall`), nieve, ambiente `mountain` |
| 4 | la ciudad | suelo oscuro, colinas y cielo rojizos de `ciudad_1`, tocones viejos (`stump_tall`) y restos de ruinas (`city_block`, `city_column_broken`, `rubble`), ceniza, ambiente `city` |
| 5 | la ciudad, la v2 terminada | lo mismo que el tramo 4, pero en calma: el cielo y la bruma más suaves y claros, sin ceniza |

- **Como datos:** una clase pura nueva, `CampLook`, con una tabla por tramo (los valores se copian de la zona de origen al construir, más lo propio de cada tramo) y `CampLook.dressed(zone, tramo)`, que devuelve una copia de la Caravana con ese aspecto. `Game._switch_zone()` la usa al entrar en la Caravana. `ZoneData` gana `look_key` (texto, "" por defecto): las cachés de `Decor` y `WorldStage` se guardan por `id` + `look_key`, para que la decoración de un tramo no se reutilice en otro.
- **Límites:** la decoración de una vista cuesta como mucho **+18 llamadas de dibujo** (la regla de la 2.0.1). Nada se pone sobre las tiendas, las figuras, los pozos, las salidas, las entradas o la ruta: `Decor.problems()` no puede dar ningún `WARNING`.
- **Verificación:** fotos de la Caravana en cada tramo al lado de su zona (la jungla, el desierto, la montaña, la ciudad), y del tramo 5.

## Qué cambia, por archivo

| Archivo | Cambio |
|---|---|
| `scripts/battle/battle_engine.gd` | `quest_items` (`{id: meta}`); en `_win()` un objeto de misión cae siempre si se pide y nunca si no; el `DROP` lleva `progress` |
| `scripts/battle/battle_event.gd`, `battle_scene.gd` | el `DROP` con "(n/m)"; `BattleScene.quest_items` pasa al motor |
| `scripts/game/quest_log.gd`, `quest_data.gd` | `wanted_items()`; `talk()` entrega todas las listas de una figura (`done` lista, `kind`); `problems()` con `is_present()`; `done_flag` |
| `scripts/game/game.gd` | `quest_items` al combate; `_after_quest_talk()` con varias misiones (desde `_on_npc()` y `_on_talk()`); las frases del Jefe (capítulo y espera); `_on_inn()` entrega primero; `QuestLog.problems()` al arrancar; la frase del compañero al llegar (`_check_arrival_line()` tras el rótulo) y las banderas `llegada_<zona>` al cargar; la frase nueva de `_choose_companion()` |
| `scripts/game/save_data.gd` | al cargar, las `done_flag` de las misiones ya cumplidas (sin campo nuevo) |
| `scripts/game/inn.gd` | `LINES` por posada (la Curandera) |
| `scripts/game/allies.gd` | `ARRIVALS` y `arrival_line()` |
| `data/quests/*.tres` (las 8 de la v2) | `turn_in` al Jefe donde falta; los textos del anexo |
| `data/zones/` (las 6 de la v2 con grupos, `caravana`, `ciudad_2`) | `monster_count`, el mono de más en la jungla, las frases, los `look` nuevos, y Nara y el Superviviente en la Caravana |
| `data/cutscenes/caravana_campamento.tres` | la frase del Jefe del anexo |
| `data/enemies/*` (normales de la v2) | EXP y oro reajustados con la partida automática |
| `shaders/tree.gdshader`, `project.godot`, `scripts/world/world.gd`, `world_stage.gd` | fuera el agujero y `hero_pos` |
| `shaders/hero_rim.gdshader` (nuevo), `scripts/world/player.gd`, `scripts/battle/battle_actor.gd` | el borde de luz del héroe del mapa (`set_map_readable()`, `material_overlay`, otra vez tras `set_equipment()`); los looks nuevos de la caravana, el pelo, la piel y los peinados |
| `scripts/tools/head_textures.gd` (nuevo, fuera de la exportación) y `assets/characters/head_*.png` (nuevos, con su `.import`) | las cabezas con otro pelo y otra piel; `assets/CREDITS.md` lo dice |
| `scripts/world/camp_look.gd` (nuevo), `scripts/world/zone_data.gd` (`look_key`), `scripts/world/decor.gd`, `scripts/world/world_stage.gd` | el aspecto de la Caravana por tramo (M-55) |
| `CLAUDE.md`, `CHANGELOG.md`, `project.godot` (versión 2.4.0) | lo de siempre al cerrar la versión. En `CLAUDE.md`, además: la Seta no es "a 50 % drop" (siempre fue 1,0 en `mushroom.tres`): pasa a decir que cae siempre mientras `setas` la pide; fuera `hero_pos` y el agujero de los árboles (`tree.gdshader`, `World`, `WorldStage`); las misiones de la v2 entregadas al Jefe; los looks nuevos |

## Lo que no cambia

- La v1: sus grupos, sus figuras, sus textos y su ajuste (también la Partida nueva +). Solo cambian para ella el agujero de los árboles (fuera en todos los mapas), el borde de luz del héroe y que la Seta deje de caer cuando la misión `setas` no la pide.
- `MonsterGroups`, `MonsterRoam` y la regla de reaparición.
- Las paredes medio transparentes de las mazmorras (`DungeonMap.see_through()`).
- Los compañeros (looks, números, frases de la lista).
- El guardado: versión 14, sin campos nuevos. Las banderas `llegada_<zona>` son banderas del mundo como las demás.
- El brief de QA: no cubre la v2.

## Partida automática y ajuste

- `--autoplay-zone=jungla` con los tres compañeros: las cuatro pieles en la primera visita a la jungla (antes, tres visitas), entregadas al Jefe en la primera retirada; el Jaguar a Nv 24-25 en 23-28 min como en la 2.0.0.
- `--autoplay-zone=caravana` (la v2 entera) con los tres compañeros: las ocho misiones de la caravana, todas entregadas al Jefe ("Jefe de caravana: ..."), y Nara y el Superviviente en la Caravana después; `Juego completado (v2): ...` en 1:50-2:20 con el Devorador a Nv 39-40. Si se pasa de nivel o de tiempo, se baja la EXP y el oro de los enemigos normales de la zona que se adelanta, como en la 2.3.0.
- La partida automática dice la frase del compañero al llegar (`Compañero: ...`) y no se para.
- **La v1 y la Partida nueva + se vuelven a medir**, no se dan por buenas: la v1 entera (`--autoplay`, `--quit-after 150000`) debe seguir en Nv 18 a 1:12-1:26 con 5 misiones, y `--autoplay-zone=ngplus` debe acabar con `Juego completado: ...` sin más derrotas que en la última medida (0). Lo que les cambia es la Seta (deja de caer con `setas` cumplida) y el borde de luz del héroe del mapa, que no toca las reglas.

## Verificación a mano

Sin pruebas automáticas de ningún tipo (decisión del usuario). Se comprueba así:

- `--check-only` de cada script tocado; `--import` tras añadir las texturas y el shader.
- Las partidas automáticas de arriba, leyendo la salida: ningún `ERROR` ni `WARNING` nuevo (el de Jolt es el ruido conocido) y ningún `WARNING` de `QuestLog.problems()`.
- Ida y vuelta del guardado (`--autoplay-save`): las líneas `Guardado:` y `Cargado:` iguales.
- Un guardado de la 2.3.0 con `pieles_mono` lista (4 pieles) y otro con `superviviente` en `REPORT`, hecho con `--debug`: al cargarlos, "?" sobre el Jefe y entrega al hablar con él.
- Fotos de la Caravana en los cinco tramos, cada una junto a la de su zona (M-55), sin `WARNING` de `Decor.problems()` y con +18 llamadas de dibujo como mucho.
- Fotogramas (`--write-movie`, no headless) de: la jungla con el héroe detrás de una palmera (tapado, sin trama) y sobre su sombra (sombra entera, el héroe con su borde de luz); el desierto, el bosque y la pradera igual; la mina con el farol; la Caravana con sus seis figuras de cerca y desde la cámara del mapa; Nara en la jungla y el Superviviente en la ciudad. Lo mismo a 740 × 360 con `--touch`.
- Una partida a mano en la jungla: un mono con la planta da su piel "(1/4)", y otro que pide ayuda también; un mono vencido antes de leer el tablón también la da.
- A mano en la Caravana: el Jefe con una misión en curso dice primero su frase del capítulo y luego la de espera; con dos entregas listas, las dos en una charla y un solo aviso ("Misiones cumplidas: 2" con `--touch`).
- Fotogramas de combate de Brena, Tadeo, Ulma y del héroe: sin borde de luz (solo lo lleva el héroe del mapa). El héroe del mapa tras equiparse un arma, un escudo y el Yelmo de bruma: el borde sigue en todo.
- Pendiente para el usuario: jugarlo en un móvil real (el borde de luz y las figuras nuevas en una pantalla pequeña).
