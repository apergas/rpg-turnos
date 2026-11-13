# Versión 2: la caravana del portal

Fecha: 2026-11-10. Parte de la 1.9.0 (se hace después de todas las 1.x planificadas). Cubre M-39 a M-47 del documento maestro. Es el diseño de toda la v2; se publica en cuatro versiones, de la 2.0.0 a la 2.3.0 (ver "Versiones").

## Objetivo

Una segunda parte de unas dos horas que continúa una partida terminada. El héroe de la v1 se une a una caravana que viaja hacia un portal al norte, cruza cuatro tierras salvajes (jungla, desierto, montaña y una ciudad abandonada), vence a cinco jefes y cruza el portal. Al otro lado se ve, de lejos, el pueblo de la v3: el gancho para la siguiente parte.

Lo nuevo se apoya en lo que ya existe: el compañero es un ALLY como las criaturas, las misiones son `QuestData`, los jefes usan `next_phase`, las zonas son `ZoneData` abiertas o de celdas y el bloqueo de salidas usa `lock`. El guardado pasa a la **versión 14**.

## Decisiones tomadas (2026-11-10)

| Tema | Decisión |
|---|---|
| Cómo se llega | Desde una partida de la v1 terminada, con el mismo héroe, su equipo, su oro y sus objetos. Una vez parte la caravana, no se vuelve al mundo de la v1 |
| Compañero | Se elige uno de tres en la caravana. Solo cambian sus números; no hay regla de combate nueva |
| Criatura de la v1 | El compañero ocupa su sitio. En la v2 no hay Domadora |
| Nivel máximo | 40, con dos hechizos nuevos |
| Zonas | Jungla y desierto abiertas (`WorldStage`); montaña y ciudad de celdas (`DungeonMap`) |
| Partida nueva + | Solo repite la v1. La v2 queda fuera |
| Orden | Después de la 1.9.0: las zonas se diseñan con monstruos a la vista, familias del bestiario y ambiente |
| Arte | Paquetes CC0 nuevos en el estilo de KayKit para palmeras, cactus, ruinas y nieve |

## Mecánicas nuevas (lista cerrada)

Solo estas. Todo lo demás es contenido de datos con las reglas de hoy.

1. **Tramo derivado:** el tramo se calcula de las banderas de los jefes; no se guarda.
2. **Caravana:** un solo mapa de base cuyo mercader, salida y frases cambian con el tramo.
3. **Salidas por tramo:** una salida puede no existir según las banderas.
4. **Misiones por tramo:** una oferta solo sale a partir de una bandera.
5. **Compañero:** un ALLY elegido una vez cuyos números suben con el tramo.
6. **Nivel máximo 40** y dos hechizos nuevos.
7. **Pantalla del más allá:** la escena final con el pueblo de la v3 al fondo.

## M-39. El paso de la v1 a la v2

### La caravana llega a Villaclaro

- En una partida terminada (`GameState.is_finished()`), la próxima vez que el héroe entra en Villaclaro se ve la escena `caravana_llega`: unas carretas al norte del pueblo y el Jefe de caravana, que cuenta que la niebla escondía un camino hacia un portal y que necesitan a alguien que sepa luchar.
- Desde entonces el Jefe de caravana está en Villaclaro, junto a sus carretas, con la marca "!" de las misiones.
- Hablar con él pregunta: "Cuando partamos, no volverás por aquí en mucho tiempo. ¿Te unes a la caravana?" (Sí / No, foco en "No").
  - Con "Sí", una segunda confirmación dice lo que se pierde: "No podrás volver a Villaclaro, ni al bosque, la mina o el castillo. Las misiones que no hayas cumplido se quedan sin hacer." (Partir / Aún no, foco en "Aún no").
  - Con "Partir": escena `caravana_parte`, la bandera `caravana` y el héroe aparece en la Caravana (tramo 1).
- Hasta entonces la partida es la de la v1 tal cual: el Eco de la Niebla, las medallas, la Partida nueva + y lo que quede por hacer siguen ahí.
- En la Partida nueva + (1.8.0) la caravana no llega: la segunda vuelta acaba en los créditos de la v1, como hoy.

### Qué se lleva el héroe

| Se lleva | Se queda atrás |
|---|---|
| Nivel, EXP, estadísticas y hechizos | La criatura comprada (`ally_id` pasa a ser el compañero) |
| Equipo puesto y bolsa | Las misiones de la v1 no cumplidas (siguen en el Diario como no cumplidas) |
| Oro y objetos | El portal de un Ala de viaje abierto en la v1 (se cierra) |
| Objetos clave de la v1, bestiario, medallas | La posibilidad de volver a las zonas de la v1 |

### Cómo se sabe en qué parte está

- `GameState.in_caravan()`: la bandera `caravana` está puesta.
- Con la bandera, `town_zone` es siempre `caravana` (la derrota y el Ala de viaje llevan allí) y `ZoneData.IDS` de la v1 no se pueden cargar como zona del héroe (`SaveData.is_valid()` lo rechaza).

## M-40. El tramo

- `StoryState.tramo(flags)`: 1 + el número de jefes de zona de la v2 vencidos, de 1 a 4. Con el Devorador del portal vencido, 5 (el epílogo).
- Las banderas de los jefes: `jaguar_sombrio`, `gusano_dunas`, `grifo_cumbre`, `guardian_ciudad` y, el final, `devorador_portal`.
- El capítulo de `StoryState.chapter()` sigue después del 5 de la v1: 6 caravana (tramo 1), 7, 8, 9 (tramos 2-4) y 10 (el final de la v2). `npc_lines(i, chapter)` y `lines_by_chapter` ya bastan para que los personajes digan otra cosa en cada tramo.
- `goal_text()` gana las líneas de la v2: "Cruza la jungla y vence a su guardián", "Atraviesa el desierto", "Sube a la cumbre", "Entra en la ciudad abandonada", "Vence al Devorador del portal". En las zonas de celdas siguen la planta y las banderas, como `MINE_GOALS`.

## M-41. La Caravana

### El mapa

- Una zona nueva, `caravana.tres`: un claro abierto de 40 × 40 m con un círculo de carretas y tiendas (el `tent` de la v1 y carretas nuevas), una hoguera en el centro y un tablón.
- Su aspecto no cambia con el tramo: suelo de tierra batida, sin hierba, cielo de atardecer. La caravana se mueve entre tramos con una escena (fundido, `travel`), y el mapa es el mismo campamento montado en otro sitio.
- Es zona segura: sin monstruos, como un pueblo (`village_radius` cubre todo el claro). Tiene sus dos pozos.
- Música propia (`caravan`, una melodía de viaje).

### Las figuras

| Figura | Tipo | Qué hace |
|---|---|---|
| Jefe de caravana | `npc` | La historia de cada tramo. En el tramo 1, la elección del compañero |
| Curandera | `inn` | La posada de siempre, gratis (`Inn.stay()`): "Siéntate junto al fuego." |
| Mercader | `shop` | Su tienda depende del tramo |
| Tablón | `board` | Las misiones de la v2 |
| Dos viajeros | `npc` | Frases por tramo, una misión cada uno (la segunda llega con la 2.1.0) |

- El mercader es un solo personaje con cuatro tiendas: `Shop.SHOPS` gana `caravana_1` a `caravana_4`, y la figura usa `"caravana_%d" % tramo`. Cada tienda vende el equipo de su tramo y los consumibles (ver M-45). Lo de los tramos anteriores se deja de vender.

### Salidas por tramo

- Cada salida de `ZoneData.exits` gana dos campos opcionales: `needs` (una bandera que debe estar puesta) y `gone` (una bandera que la quita). Sin ellos, la salida está siempre, como hoy.
- Una salida que no cumple `needs` o tiene `gone` puesto no se construye: ni arco, ni rótulo, ni marca en el mapa (`MapMarks`).
- La Caravana tiene cuatro salidas en el mismo sitio del claro, una por tramo:

| Salida | `needs` | `gone` | Lleva a |
|---|---|---|---|
| "A la jungla" | `companero` | `jaguar_sombrio` | `jungla` |
| "Al desierto" | `jaguar_sombrio` | `gusano_dunas` | `desierto` |
| "A la montaña" | `gusano_dunas` | `grifo_cumbre` | `montana_1` |
| "A la ciudad" | `grifo_cumbre` | — | `ciudad_1` |

- Al vencer al jefe de una zona, la vuelta a la Caravana es la escena del tramo siguiente: el campamento "se traslada" (fundido y un texto) y la salida nueva ya está.
- Las zonas de tramos ya pasados no se pueden volver a visitar: su salida desaparece. El Ala de viaje y la derrota llevan siempre a la Caravana.

## M-42. El compañero

### La elección

- En la escena de llegada a la Caravana (tramo 1), el Jefe de caravana presenta a tres voluntarios y pide elegir uno. La elección usa la página "Criaturas" de `ShopWindow` (la de las Domadoras) con precio 0 y el título "Compañeros": cada fila dice el nombre, los números y una frase.
- Se elige una vez: queda la bandera `companero` y el Jefe no vuelve a ofrecerlo. Sin compañero no se abre la salida a la jungla.

| id | Nombre | Figura | Fuerte en |
|---|---|---|---|
| `brena` | Brena, la guerrera | `Knight.glb` con su casco, tinte rojo | ATK alto, VEL baja |
| `tadeo` | Tadeo, el explorador | `Knight.glb` sin casco, tinte verde, dos hojas | VEL alta, golpea primero |
| `ulma` | Ulma, la escudera | `Knight.glb` con casco y escudo grande, tinte gris | PV y DEF altos, recibe más golpes sin caer |

- Ulma recibe los golpes igual que los demás (30 % de los ataques de un objetivo, `ALLY_TARGET_CHANCE`); aguanta más porque tiene más PV y DEF, no por una regla.

### Sus números

- Los compañeros son tres entradas más de `Allies` (`companion: true`), con `Allies.COMPANIONS`, `is_companion(id)` y `data(id, tramo)`: una copia nueva con los números de ese tramo, la vida llena. Así la tienda, la pausa y el guardado, que ya saben de `Allies`, sirven sin cambios (corregido al escribir el plan de la 2.0.0).
- Los números están en `data/companions/<id>.tres` (los del tramo 1) y suben por tramo con una tabla por compañero (`GROWTH`: cuánto suma cada tramo a PV, ATK, DEF y VEL). El plan los ajusta para que un compañero se parezca a un Esqueleto leal en el tramo 1 (90 PV, ATK 38, DEF 28) y llegue al tramo 4 a unos 220 PV y ATK 80.
- `GameState.ally_id` guarda el id del compañero. `Game` le da a cada combate `Allies.data(ally_id, tramo)`.
- Todo lo demás es la regla del ALLY de hoy: ataca solo al enemigo más débil, no gana EXP, no toma estados, si cae vuelve curado al siguiente combate, anima al ganar.
- En la pausa, Estado dice "Compañero: Brena" en lugar de "Criatura: ...".

## M-43. Las cuatro zonas

### Resumen

| Zona | id | Tipo | Tamaño | Jefe | Objeto clave | Nv al salir (`exit_level`) |
|---|---|---|---|---|---|---|
| Jungla | `jungla` | Abierta | 70 × 90 m | Jaguar sombrío | Insignia de la jungla | 25 |
| Desierto | `desierto` | Abierta | 90 × 70 m | Gusano de las dunas | Sello del desierto | 30 |
| Montaña | `montana_1`, `montana_2` | Celdas, roca y nieve | 15 × 13 cada planta | Grifo de la cumbre | Mapa de la montaña | 35 |
| Ciudad abandonada | `ciudad_1`, `ciudad_2` | Celdas, muros de piedra | 17 × 15 y 13 × 13 | Guardián de la ciudad, y el Devorador del portal | Llave del portal | 40 |

- Cada objeto clave entra en `Inventory.KEY_ITEMS` y lo da su jefe (`key_item` del `Combatant`, como los fragmentos). Lo que abre la siguiente zona es la bandera del jefe; el objeto es para el Diario y la historia. La Llave del portal es la excepción: la puerta del portal en `ciudad_2` es una reja (`D`) que se abre con ella (`door_key`, como la Llave de la mina).
- Cada zona tiene sus dos pozos, tres cofres y su número de grupos de monstruos (1.7.0). No tiene medallas (ver "Fuera de la v2").

### Jungla

- Árboles grandes y lianas, mucha hierba alta, maleza espesa (sin río: necesitaría paredes por tramos que `WorldStage` no tiene). Un sendero de la entrada al claro del jefe; tres claros con cofre.
- Hierba verde oscura, niebla verde clara, luz filtrada.
- Ambiente: insectos y pájaros; partículas: luciérnagas y polen.

### Desierto

- Dunas (colinas bajas dentro del campo), rocas, cactus, un oasis con palmeras donde están los pozos y una ruina con el jefe. Poca hierba: los grupos de monstruos están en la arena (`has_grass` false; la regla de dónde se ponen pasa de "sobre hierba" a "fuera del sendero" en las zonas sin hierba).
- Cielo amarillo pálido, sol fuerte, bruma de calor.
- Ambiente: viento con arena; partículas: granos de arena a ráfagas.

### Montaña

- Dos plantas de celdas como la mina: roca gris con nieve encima (`rock_color`, un tinte blanco en la cara de arriba), suelo de piedra y nieve. Al aire libre, con cielo (no `underground`).
- Planta 1: la subida, con una palanca que abre el paso. Planta 2: la cumbre, con el Grifo en una explanada.
- Ambiente: viento fuerte; partículas: copos de nieve.

### Ciudad abandonada

- Dos plantas de celdas con los muros del castillo (`castle`), calles estrechas, plazas y casas en ruinas.
- `ciudad_1`: las calles, con el Guardián de la ciudad en la plaza mayor, que da la Llave del portal.
- `ciudad_2`: el barrio del portal, con la reja que abre la Llave y, al fondo, el portal (un anillo de piedra con una luz roja que gira) y el Devorador delante.
- Cielo rojizo y niebla, como un presagio de la v3.
- Ambiente: viento que silba entre ruinas y un rumor grave cerca del portal; partículas: ceniza.

### Lo que cada zona necesita además del mapa

- Un fondo de combate en `BattleStage`: `jungla`, `desierto`, `montana` y `ciudad` (este último puede ser el `castillo` con otro cielo y ceniza).
- Su música (`jungle`, `desert`, `mountain`, `city`), en `MusicLibrary`.
- Su ambiente y sus partículas (1.9.0).
- Su punto de entrada en `--autoplay-zone`, y su ruta de la partida automática.

## M-44. Los enemigos

### Comunes

Cinco por zona, veinte en total. Donde se puede, son variantes de figuras que ya existen (otro color y otra escala); las demás son figuras nuevas hechas en código con `LowPoly`, como el Lobo o la Araña.

| Zona | Enemigo | Figura | Rasgo |
|---|---|---|---|
| Jungla | Rana dardo | Nueva (pequeña, salta) | Su golpe envenena |
| Jungla | Serpiente de liana | Nueva (cuerpo de segmentos) | Rápida |
| Jungla | Mono aullador | Nueva | Pide ayuda a una Rana dardo |
| Jungla | Planta trampa | `PLANT`, verde intenso, ×1,3 | Esporas de sueño |
| Jungla | Seta tropical | `MUSHROOM`, naranja | Débil al fuego |
| Desierto | Escorpión | Nueva | Su golpe envenena; DEF alta |
| Desierto | Slime de arena | `SLIME`, ocre | Resiste el fuego, débil al hielo |
| Desierto | Buitre | `BAT` con otra cabeza y alas, marrón | Muy rápido |
| Desierto | Golem de arena | `MUD_GOLEM`, arena | Golpe cargado, como el Golem de piedra |
| Desierto | Momia | `SKELETON_WARRIOR` vendado (tinte blanco sucio) | Débil al fuego |
| Montaña | Lobo de las nieves | `WOLF`, blanco | Va en pareja |
| Montaña | Golem de hielo | `STONE_GOLEM`, azul hielo | Resiste el hielo, débil al fuego |
| Montaña | Espíritu de la cumbre | `SPECTER`, blanco | Hielo a todos |
| Montaña | Murciélago de la cueva helada | `BAT`, azul | Rápido |
| Montaña | Cabra montesa | Nueva | Golpe que aturde (pierde el turno, `stagger`) |
| Ciudad | Armadura hueca | `Knight.glb` sin cabeza, tinte negro | DEF muy alta, débil al rayo |
| Ciudad | Gárgola | Nueva | Resiste todo menos el rayo |
| Ciudad | Sombra | `SPECTER`, negro y rojo | Silencio |
| Ciudad | Esqueleto centinela | `SKELETON_WARRIOR`, tinte rojizo | Pide ayuda a otro esqueleto |
| Ciudad | Rata de las ruinas | Nueva | Veneno, va en pareja |

- Sus números se fijan con la partida automática para que cada zona se juegue en unos 25 minutos y el héroe salga con el `exit_level` de la tabla.
- Todos tienen `map_roam` y `map_speed` (1.7.0), retrato en `assets/bestiary/` y botín.

### Los jefes de zona

| Jefe | Figura | Fase | Rasgo |
|---|---|---|---|
| Jaguar sombrío | Nueva (felino negro con manchas que brillan) | Una | Zarpazo (daño fuerte a uno) y VEL 30, que casi siempre lo hace actuar primero; el combate no da dos turnos a nadie |
| Gusano de las dunas | Nueva (segmentos que salen de la arena) | Una | Golpe cargado y pide ayuda a un Slime de arena |
| Grifo de la cumbre | Nueva (cuerpo de león, alas y cabeza de águila) | Una | Hielo a todos y se cura una vez (`rescue_heal`) |
| Guardián de la ciudad | `Knight.glb` ×1,6, tinte bronce, espada a dos manos | Una | Golpe cargado y silencio |

### El jefe final: el Devorador del portal

- Un monstruo nuevo, sin relación con la niebla de la v1 ni con las zonas de la v2: una masa oscura con muchas bocas y un ojo central, hecha en código (`LowPoly`), que sale del portal. Figura `PORTAL_DEVOURER`.
- Dos fases (`next_phase`, como el Señor de la Niebla):
  - **Fase 1, "El Devorador del portal":** golpes fuertes y "Mordisco" (daño a uno con veneno).
  - **Fase 2, "El Devorador despierto":** el ojo se abre y la figura crece (`play_phase()`). Gana "Vacío" (daño a todos con silencio) y un golpe cargado.
- Sus habilidades son `Skill` de datos (`data/skills/mordisco.tres`, `vacio.tres`).
- Pensado para un héroe de Nv 39-40 con el equipo del tramo 4 y su compañero.
- Al vencerlo: la bandera `devorador_portal` y el final (M-47).

### El bestiario

- Las familias de la 1.6.0 no cambian (se completan con los enemigos de la v1, y sus premios ya se dieron o se darán).
- La v2 añade cuatro familias nuevas con sus premios (la regla de `Bestiary` de siempre):

| Familia | Enemigos | Premio |
|---|---|---|
| Fieras salvajes | Rana dardo, Serpiente de liana, Mono aullador, Escorpión, Buitre, Lobo de las nieves, Cabra montesa, Rata de las ruinas | Anillo de garra (ATK +6 · VEL +3) |
| Plantas y bichos de la arena | Planta trampa, Seta tropical, Slime de arena, Murciélago de la cueva helada | Amuleto del oasis (inmune al veneno · VEL +2) |
| Constructos y almas | Golem de arena, Golem de hielo, Espíritu de la cumbre, Armadura hueca, Gárgola, Sombra, Esqueleto centinela, Momia | Amuleto del vigía (inmune al silencio · DEF +6) |
| Jefes de la caravana | Jaguar sombrío, Gusano de las dunas, Grifo de la cumbre, Guardián de la ciudad, Devorador del portal | Espada del portal (ATK +80) |

- El bestiario pasa de 22 a 47. La página Bestiario separa la v1 y la v2 con un título por parte.

## M-45. Equipo, objetos y niveles

### Nivel máximo 40

- `MAX_LEVEL` pasa a 40 y `EXP_TABLE` sigue hasta el nivel 40. El plan fija los números con la partida automática para que el héroe llegue a la v2 con Nv 19-20, salga de cada zona con su `exit_level` y llegue al Devorador con Nv 39-40.
- `GAINS` no cambia (PV +6, PM +3, ATK +2, DEF +1, VEL +1 por nivel).
- Dos hechizos nuevos en el `learn` del héroe:

| Nivel | Hechizo | PM | Qué hace | Sustituye a |
|---|---|---|---|---|
| 24 | Ventisca | 14 | Daño de hielo a todos | — |
| 32 | Sanación | 12 | Cura 150 PV | Curar+ |

- Ventisca es el primer hechizo de hielo del héroe, así que las debilidades al hielo de la v2 se pueden aprovechar.

### Equipo

- Cuatro niveles más, uno por tramo (zonas 5 a 8 de `Equipment`), con un casco cada uno:

| Tramo | Material | Arma | Armadura | Escudo | Casco |
|---|---|---|---|---|---|
| 1 | Jade | ATK +38 | DEF +28 | DEF +13 | DEF +9 |
| 2 | Oricalco | ATK +48 | DEF +35 | DEF +16 | DEF +11 |
| 3 | Adamantita | ATK +60 | DEF +44 | DEF +20 | DEF +14 |
| 4 | Estelar | ATK +74 | DEF +54 | DEF +25 | DEF +18 |

- Los números y los precios son un punto de partida que el plan ajusta. Usan las mallas del Knight que ya existen, con tinte (`tint`), como los cascos.
- Las piezas de premio de la v1 (Espada del alba, las de medallas, el Yelmo de bruma) quedan por debajo del equipo del tramo 1 o 2. Eso está bien: eran premios de la v1.

### Objetos

- Dos objetos nuevos, solo de datos: **Poción grande** (100 PV, 40 G) y **Éter grande** (40 PM, 90 G). Con Nv 30 una Poción de 30 PV ya no sirve de mucho.
- Las tiendas de la Caravana venden Poción grande, Éter grande, Antídoto, Ala de viaje, Incienso, Pluma de fénix y Despertador. La Poción y el Éter normales dejan de venderse.
- `BattleAutoplay` y `Shop.autoplay_picks()` usan la Poción grande en lugar de la Poción cuando la llevan.

## M-46. Las ocho misiones

- Todas son `QuestData`, con los tipos de siempre (`HUNT`, `GATHER`, `FIND`, `DELIVER`).
- `QuestData` gana `needs` (una bandera): la oferta no sale hasta que está puesta. Una misión aceptada sigue aunque cambie el tramo.
- Dos por tramo, aceptadas en la Caravana (tablón o un viajero) y entregadas en la Caravana:

| Tramo | id | Tipo | Quién la da | Qué pide | Premio |
|---|---|---|---|---|---|
| 1 | `pieles_mono` | `GATHER` | Tablón | 4 Pieles de mono (botín del Mono aullador, 50 %) | 300 G, 2 Pociones grandes |
| 1 | `explorador_perdido` | `FIND` | Viajera | Un explorador en un claro de la jungla | Semilla de agilidad |
| 2 | `escorpiones` | `HUNT` | Tablón | 6 Escorpiones | 450 G, Pluma de fénix |
| 2 | `cantimplora` | `FIND` | Viajero | La cantimplora del Jefe, junto al oasis | Semilla de fuerza |
| 3 | `cabras` | `HUNT` | Tablón | 5 Cabras montesas | 600 G, 2 Éteres grandes |
| 3 | `cristales_hielo` | `GATHER` | Viajera | 3 Cristales de hielo (botín del Golem de hielo, 40 %) | Semilla de defensa |
| 4 | `centinelas` | `HUNT` | Tablón | 6 Esqueletos centinela | 800 G, 2 Plumas de fénix |
| 4 | `superviviente` | `FIND` | Viajero | Un superviviente escondido en una casa de la ciudad | Semilla de fuerza y Semilla de agilidad |

- Los objetos de misión (Piel de mono, Cristal de hielo) son como la Seta: efecto `quest`, sin uso propio.
- Las figuras que se buscan (`FIND`) solo están en el mapa mientras se buscan (`hidden_figures()`, como el gato).
- `QuestLog.total_count()` pasa de 7 a 15. El Diario, en "Colección", cuenta las de la v1 y las de la v2 en dos líneas.

## M-47. El final

- Al vencer al Devorador se ve la escena `cruce`: el portal se calma, el Jefe de caravana y el compañero llegan, y el héroe lo cruza.
- **Pantalla del más allá:** una escena construida en código (como `WorldStage`, sin jugar): un camino de tierra roja que baja hacia un pueblo de casas oscuras con humo, bajo un cielo rojo y un sol negro, con la cámara acercándose despacio. Texto: "Al otro lado del portal, otro mundo espera..." Es el gancho de la v3: solo se ve, no se pisa.
- Después, los créditos de la v2 (`CreditsScreen`, con los números de esta parte: tiempo, combates, misiones de la v2, compañero) y "Continuará".
- La partida queda terminada en la v2 (bandera `devorador_portal` y `story.finished_v2`). Al cargarla aparece en la Caravana, que se puede recorrer; las salidas de los tramos ya no están. No hay jefe de después del final en la v2.
- `SaveData.summary_line()` dice la zona de la v2 ("Rocío · Nv 34 · Montaña · 2:40") y añade "· v2" cuando el héroe está en la caravana.

## Guardado (versión 14)

- `ZoneData.IDS` gana `caravana`, `jungla`, `desierto`, `montana_1`, `montana_2`, `ciudad_1` y `ciudad_2`.
- `ally` acepta los compañeros (están en `Allies`). Con la bandera `caravana`, solo un compañero o ninguno; sin ella, ningún compañero.
- `story` gana `finished_v2`.
- `KEY_ITEMS`, `Inventory.IDS`, `Equipment` y las misiones crecen con lo nuevo; un guardado anterior no lo tiene y no le falta nada.
- `is_valid()`: el nivel llega hasta 40; con la bandera `caravana`, la zona debe ser de la v2; sin ella, de la v1.
- Un guardado de la versión 13 carga igual que hoy.

## Duración

| Parte | Objetivo |
|---|---|
| Llegada de la caravana y elección del compañero | 3 min |
| Cada zona (jungla, desierto, montaña, ciudad) | ~25 min |
| Cada vuelta a la Caravana (tienda, posada, misiones) | 2-3 min |
| Devorador del portal | ~15 min con su sala |
| **Total** | **~2 h** |

La partida automática lo mide: una pasada completa de la v2 debe acabar con el héroe en Nv 39-40 y cerca de las dos horas de juego en Normal.

## Partida automática

- `--autoplay-zone=caravana`: la v1 terminada (Nv 19, el equipo de platino, Esqueleto leal), en Villaclaro con la caravana llegada; habla con el Jefe, parte, elige a Brena y juega la v2 entera hasta `Juego completado`.
- `--autoplay-zone=jungla`, `desierto`, `montana`, `ciudad` y `portal`: empieza en esa zona con el nivel, el oro y el equipo de un héroe que llega allí (como `AUTOPLAY_ZONES`).
- `--autoplay-companion=<id>`: elige otro compañero, para comparar los tres.
- Elige al compañero sin preguntar, acepta las misiones que encuentra y vuelve a la Caravana para descansar con las reglas de retirada de hoy.

## Versiones

Todo de golpe es demasiado: unos 20 enemigos, 5 jefes, 7 mapas, 16 piezas de equipo, 4 fondos de combate y 5 músicas. Se reparte en cuatro versiones. Cada una se publica jugable: la última zona que trae acaba en su jefe, y al volver a la Caravana el Jefe dice "Aún no podemos seguir. Montaremos el camino cuando la ruta sea segura." en lugar de abrir la salida que todavía no existe.

| Versión | Contenido | Puntos |
|---|---|---|
| **2.0.0** | La base y la jungla: la caravana llega a Villaclaro, la Caravana, el tramo, las salidas y las misiones por tramo, el compañero, el nivel 40 (con Ventisca), las Pociones y Éteres grandes, la jungla entera (mapa, 5 enemigos, Jaguar sombrío, equipo de jade, 2 misiones, fondo, música, ambiente) y la página Bestiario partida en v1 y v2. El guardado pasa a la versión 14 | M-39 a M-42, y la jungla de M-43 a M-46 |
| **2.1.0** | El desierto: mapa, 5 enemigos, Gusano de las dunas, equipo de oricalco, 2 misiones, fondo, música y ambiente. La regla de grupos de monstruos fuera de la hierba | M-43 a M-46 (desierto) |
| **2.2.0** | La montaña: dos plantas de celdas con nieve, 5 enemigos, Grifo de la cumbre, equipo de adamantita, 2 misiones, Sanación (Nv 32), fondo, música y ambiente | M-43 a M-46 (montaña) |
| **2.3.0** | La ciudad y el final: dos plantas, 5 enemigos, Guardián de la ciudad, Devorador del portal, equipo estelar, 2 misiones, la escena del cruce, la pantalla del más allá, los créditos de la v2 y las cuatro familias del bestiario con sus premios | M-43 a M-47 |

- Las familias del bestiario de la v2 van en la 2.3.0, cuando ya están todos sus enemigos: antes se completarían con la mitad.
- El nivel máximo sube a 40 en la 2.0.0 de una vez; `EXP_TABLE` llega hasta el 40 desde el principio, aunque en la 2.0.0 el héroe solo llegue a Nv 25.
- Cada versión ajusta su zona con su `--autoplay-zone` y la partida automática completa de lo que ya existe. La 2.3.0 mide la v2 entera (~2 h).
- Una zona nueva solo añade ids a `ZoneData.IDS`, `Inventory`, `Equipment` y las misiones: no cambia el guardado. Si una versión necesita un campo nuevo, sube la versión del guardado en ese momento.
- Cada versión tiene su propio plan en `docs/boost/plans/`. Los paquetes CC0 se buscan en el plan de la 2.0.0 (los de la jungla) y en el de cada zona después: deben encajar con KayKit (low poly, colores planos) y quedar en `assets/` con su línea en `assets/CREDITS.md`.

## Verificación

- `--check-only` e `--import` (la clase nueva `ChoiceWindow` y las figuras nuevas de `BattleActor`).
- Cada parte con su `--autoplay-zone`, sin errores y con el héroe en el nivel que toca.
- `--autoplay-zone=caravana` completo, con los tres compañeros (`--autoplay-companion`): anotar nivel, tiempo, derrotas y misiones.
- Fotogramas de cada zona, de cada fondo de combate, de los jefes, del Devorador en sus dos fases, de la elección del compañero, de la pantalla del más allá y de los créditos, en escritorio y en el móvil (`--resolution 740x360 -- --touch`), también con textos grandes.
- Cargar un guardado de la versión 13 terminado y otro sin terminar: todo igual, y en el terminado llega la caravana.
- Viaje de ida y vuelta del guardado dentro de la v2 y exportación web.

## Fuera de la v2

- Volver al mundo de la v1 durante la v2.
- Medallas pequeñas en la v2 (el Coleccionista está en Villaclaro).
- Compañeros con papeles propios (curar, magia) o que sigan al héroe por el mapa, hablen o tengan historia.
- Partida nueva + de la v2.
- Jefe de después del final en la v2.
- La v3: solo se ve su pueblo en la pantalla del más allá.
