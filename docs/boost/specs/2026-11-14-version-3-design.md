# Versión 3: el origen de la Niebla

Fecha: 2026-11-14. Parte de la 2.7.2. Cubre M-76 a M-85 del documento maestro. Es el diseño de toda la v3; se publica en cuatro versiones, de la 3.0.0 a la 3.3.0 (ver "Versiones"). Sale del borrador [v3-desarrollo.md](../v3-desarrollo.md) (opción 1 de [v3-guiones.md](../v3-guiones.md)), que queda como historia de la decisión.

## Objetivo

Una tercera parte de unas dos horas que sigue a una partida de la v2 terminada. Al otro lado del portal está **Brumaclara**, un pueblo que vive bajo un sol negro y respira la Niebla. Al vencer al Devorador el héroe rompió el cerrojo que separaba los dos mundos: la Niebla se escapa hacia Villaclaro y Brumaclara se queda sin aire. El héroe cruza cuatro zonas (la Ciénaga, las Cuevas de cristal, las Ruinas flotantes y la Fuente), vuelve un momento a Villaclaro a por el Amuleto del Alba y, en la Fuente, vence o libera al Eco de Albor, el antiguo guardián que se convirtió en el Señor de la Niebla.

Lo nuevo se apoya en lo que ya existe, como en la v2: zonas `ZoneData` abiertas o de celdas, salidas con `needs` y `gone`, misiones `QuestData` con `needs`, familias de `Bestiary`, jefes con `next_phase`, el pueblo vestido por tramo como `CampLook`, el portal del Ala de viaje (`TravelPortal`) y `World.ask()`. El guardado pasa a la **versión 15**.

## Decisiones tomadas (2026-11-14)

| Tema | Decisión |
|---|---|
| Cómo se llega | Desde una partida de la v2 terminada, con el mismo héroe, su compañero, su equipo, su oro y sus objetos. Las partidas de la v2 terminadas que ya existen también entran (hoy se quedan en una Caravana sin salidas) |
| Nombres | Brumaclara, Orvalla, Neblí, Albor, Garza de légamo, Coloso de cuarzo, Vigía de la bruma y Eco de Albor, tal cual |
| El final | Dos finales: liberar a Albor con el amuleto o vencerlo. Los dos acaban bien |
| Vuelta a Villaclaro | Una visita corta a la pradera: la Abuela Rosa cuenta la historia y da el amuleto. El resto de la v1 sigue cerrado |
| Nivel máximo | 50, con un hechizo nuevo (Alba, Nv 45) |
| Niebla espesa | No se hace. Las Ruinas son un mapa de celdas normal con otro aspecto |
| Partida nueva + | Ya no existe (2.7.0); no hay nada que decidir |
| Mecánicas | Una por versión como mucho (lista cerrada abajo) |
| Arte | KayKit y Kenney, como hasta ahora. Las figuras nuevas se hacen en código (`LowPoly`) o son variantes con tinte y escala |

## Mecánicas nuevas (lista cerrada)

Solo estas. Todo lo demás es contenido de datos con las reglas de hoy.

1. **La parte 3:** la bandera `brumaclara` abre la v3; la etapa de la v3 sale de las banderas de sus jefes y no se guarda (como el tramo).
2. **Salida con portal:** una salida de `ZoneData` puede dibujarse como el portal del Ala de viaje en lugar del arco de madera. Une la Caravana y Brumaclara en los dos sentidos.
3. **El pueblo que crece:** Brumaclara se viste según la etapa, como la Caravana según el tramo.
4. **El elemento luz** y el hechizo Alba.
5. **La elección del final:** una pregunta con `World.ask()` tras el último combate y dos finales.

## M-76. El paso de la v2 a la v3

### El fin de la v2 ya no vuelve al título

- Hoy `StoryFlow.finish_v2()` acaba con `quit_requested`: tras la pantalla del más allá y los créditos de la v2 se vuelve al título, y la partida guardada se queda en una Caravana sin ninguna salida.
- En la v3, tras los créditos de la v2 ("Continuará" se queda) la partida **sigue en la Caravana**: fundido desde negro, el héroe junto a la hoguera, y el Jefe de caravana dice "El portal se ha quedado quieto. Si quieres ver qué hay al otro lado, ya sabes dónde está.".
- La partida automática de la v2 (`--autoplay-zone=caravana`) sigue terminando en "Juego completado (v2)" y vuelve al título como hoy: solo cambia la partida a mano.

### El portal en la Caravana

- La Caravana del tramo 5 (el aspecto en calma de `CampLook`) gana una salida **"Al portal"** con `needs` `devorador_portal`, que lleva a `brumaclara`. Se dibuja con `TravelPortal` (mecánica 2) en el borde norte del claro, donde hoy estaban las salidas de los tramos.
- Así una partida de la v2 terminada que ya existe la ve al cargar, sin migración.
- La primera vez que el héroe entra en Brumaclara se ve la escena `brumaclara_llega` (M-78) y se pone la bandera `brumaclara`. Desde entonces la partida está en la v3.

### Qué se lleva el héroe

Todo: nivel, EXP, hechizos, equipo, bolsa, oro, objetos, objetos clave, bestiario, medallas y el compañero. No se pierde nada, y por eso no hay pregunta de confirmación: el portal se cruza en los dos sentidos y la Caravana sigue ahí.

## M-77. La parte 3 en el estado

### Cómo se sabe en qué parte está

- `GameState.part()`: 1 sin `caravana`, 2 con `caravana` y sin `brumaclara`, 3 con `brumaclara`. Sustituye las comprobaciones sueltas de `in_caravan()` donde haga falta distinguir la v3; `in_caravan()` sigue siendo verdad en la v3 (el compañero, la tienda de la Caravana y el tramo siguen sirviendo).
- `StoryState.etapa(flags)`: 0 sin `brumaclara`; si no, 1 + los jefes de la v3 vencidos seguidos (`garza_legamo`, `coloso_cuarzo`, `vigia_bruma`), de 1 a 4; con `eco_albor` vencido, 5 (el epílogo). Las banderas de los jefes son sus ids, como en la v1 y la v2.
- El tramo de la v2 se queda en 5 durante toda la v3.

### Capítulos y objetivos

- `StoryState.Chapter` sigue después de `V2_END` (10): `BRUMACLARA` 11 (Ciénaga), `CUEVAS` 12, `RUINAS` 13, `FUENTE` 14, `V3_END` 15. Con `brumaclara`, `chapter()` = 10 + etapa.
- `npc_lines` y `lines_by_chapter` bastan para que la gente diga otra cosa en cada etapa, también en la Caravana y en Villaclaro.
- Objetivos nuevos de `goal_text()`:

| Capítulo | Objetivo |
|---|---|
| 10 con el portal y sin `brumaclara` | "Objetivo: cruza el portal" |
| 11 | "Objetivo: atraviesa la Ciénaga y devuelve la luz al faro" |
| 12 | "Objetivo: busca los cristales en las Cuevas" (en las celdas, por planta, como `MOUNTAIN_GOALS`) |
| 13 sin `amuleto_alba` | "Objetivo: vuelve a Villaclaro a por el Amuleto del Alba" |
| 13 con `amuleto_alba` | "Objetivo: sube a las Ruinas flotantes" |
| 14 | "Objetivo: llega a la Fuente de la Niebla" |
| 15 | Liberado: "Albor guarda la Fuente" · Vencido: "La Niebla ha vuelto a su sitio" |

- Las escenas nuevas se añaden a `StoryState.SCENES` (si no, `set_from` las pierde al cargar) y las de después de cada jefe a `AFTER_BOSS`.

### Las zonas de la v3

- `ZoneData.IDS` gana `brumaclara`, `cienaga`, `cuevas_1`, `cuevas_2`, `ruinas_1`, `ruinas_2` y `fuente`, y hay una lista nueva `V3_ZONES` con ellas.
- Zonas que una partida puede tener guardadas (`zone` y `town`), según la parte:

| Parte | Zonas |
|---|---|
| 1 | Las de la v1 |
| 2 | `V2_ZONES` |
| 3 | `caravana`, `V3_ZONES` y `pradera` (la visita a Villaclaro) |

- `SaveData._valid_caravan`, `QuestLog.is_v2` (que pasa a decir la parte de una misión) y `Chests.total` dejan de leer `V2_ZONES` a pelo y usan esta regla.

### Guardado (versión 15)

- `VERSION` pasa a 15 (`V3_VERSION`): una versión vieja del juego rechaza una partida de la v3 en lugar de cargarla a medias.
- `story` gana `finished_v3` y `v3_start` (tiempo y combates al entrar en Brumaclara, como `v2_start`), opcionales.
- El final elegido es una bandera: `albor_liberado` o `albor_vencido`.
- `is_valid()`: el nivel llega a 50; la bandera `brumaclara` solo con `devorador_portal` y versión 15; las zonas según la tabla de arriba.
- Una partida de la versión 14 carga igual que hoy.
- `SaveData.summary_line()` añade "· v3" en la parte 3.

## M-78. Brumaclara y el pueblo que crece

### El mapa

- Una zona abierta nueva, `brumaclara.tres`, de unos 44 × 44 m: un pueblo de casas KayKit oscuras en torno a una plaza con un pozo, con un faro de piedra al norte (hecho con piezas de KayKit o `LowPoly`) y el portal al sur. Es pueblo (`village_radius` cubre el mapa), sin monstruos, con sus dos pozos y su `town_entry`.
- **El sol negro:** el cielo de la v3 es un crepúsculo violeta con un disco negro y una corona azul clara, el mismo dibujo que el portal del Ala (`portal_swirl.gdshader` con la corona). Es un campo nuevo de `ZoneData`, `black_sun`, que dibuja el disco en el cielo del mapa y en el fondo de combate de todas las zonas abiertas de la v3.
- Niebla baja que se mueve hacia el portal (partículas `mist` y `fog_density` alta).
- Música propia (`brumaclara`).

### La gente

| Figura | Tipo | Desde | Qué hace |
|---|---|---|---|
| Orvalla, la farera | `npc` | Siempre | La historia de cada etapa. Recibe todas las misiones de la v3 (como el Jefe en la v2) |
| Neblí | `npc` | Siempre | Pregunta por el sol en cada etapa |
| Tablón | `board` | Siempre | Las misiones de la v3 |
| Curandera | `inn` | `garza_legamo` | La posada, gratis: "El agua de bruma no sabe a nada, pero cura." |
| Herrero de cristal | `shop` | `coloso_cuarzo` | La tienda de equipo de la etapa |
| Coleccionista | `npc` | `vigia_bruma` | Las medallas, como en cada pueblo |
| Albor | `npc` | `albor_liberado` | El guardián, en la plaza |
| Dos vecinos | `npc` | Siempre | Frases por etapa; dan misiones |

- Antes de que abra la posada, el héroe descansa en la Caravana, al otro lado del portal (son diez pasos).

### Lo que vuelve con cada jefe

`BrumaclaraLook.dressed(zone, etapa)` (un constructor como `CampLook`) viste el pueblo según la etapa: luces de las ventanas, humo, figuras y adornos.

| Etapa | Qué se ve |
|---|---|
| 1 | Apagado: casas sin luz, faro frío, la forja apagada, el mercado cerrado con tablas |
| 2 (Garza vencida) | El faro da luz (un `OmniLight3D` y un haz que gira); la posada con luz; algunas ventanas |
| 3 (Coloso vencido) | La forja con fuego (`ZoneFire`) y el Herrero |
| 4 (Vigía vencido) | El mercado abierto, la Coleccionista, todas las ventanas con luz |
| 5 (Eco vencido) | La plaza en fiesta (guirnaldas, faroles). Liberado: Albor en la plaza y el cielo un poco más claro, con el sol que asoma. Vencido: una estatua de Albor junto al pozo |

### La Caravana durante la v3

- La Caravana sigue en calma, pero con niebla hasta las rodillas mientras dure la v3 (otro aspecto de `CampLook`, `v3`: partículas `mist` y más niebla). Con `eco_albor` vencido vuelve el aspecto en calma.
- El Jefe de caravana tiene frases por capítulo de la v3 ("Te fuiste diez minutos y ya no veo mis botas."), y su Mercader sigue vendiendo.

### La escena de llegada

- `brumaclara_llega`: el héroe y el compañero salen del portal; la niebla del suelo corre hacia él como un río. Orvalla se acerca con un farol: la Niebla es su aire, siempre ha salido de la Fuente, y ahora "se va por tu agujero". Si se vacía, Brumaclara se ahoga; si pasa toda, Villaclaro vuelve a tener lo de antes, pero peor. Neblí pregunta si al otro lado hay sol de verdad.
- Pone `brumaclara` y `story.v3_start`.

## M-79. Las cuatro zonas

### Resumen

| Zona | id | Tipo | Tamaño | Jefe | Objeto clave | Nv al salir (`exit_level`) |
|---|---|---|---|---|---|---|
| Ciénaga de Brumaclara | `cienaga` | Abierta | 80 × 80 m | Garza de légamo | Lámpara del faro | 43 |
| Cuevas de cristal | `cuevas_1`, `cuevas_2` | Celdas, bajo tierra, con luz propia | 15 × 13 cada planta | Coloso de cuarzo | Cristal de la Fuente | 46 |
| Ruinas flotantes | `ruinas_1`, `ruinas_2` | Celdas, al aire libre, islas sobre el vacío | 15 × 13 y 13 × 13 | Vigía de la bruma | Sello de Albor | 49 |
| La Fuente de la Niebla | `fuente` | Celdas, una planta abierta al sol negro | 13 × 15 | Eco de Albor (dos fases) | — | 50 |

- Cada zona tiene sus dos pozos, tres cofres y sus grupos de monstruos a la vista. Cada objeto clave entra en `Inventory.KEY_ITEMS` y lo da su jefe. Lo que abre la siguiente zona es la bandera del jefe; el objeto es para el Diario y la historia.
- Las salidas de Brumaclara, una por etapa en el mismo sitio (norte, junto al faro), como las de la Caravana:

| Salida | `needs` | `gone` | Lleva a |
|---|---|---|---|
| "A la Ciénaga" | `brumaclara` | `garza_legamo` | `cienaga` |
| "A las Cuevas" | `garza_legamo` | `coloso_cuarzo` | `cuevas_1` |
| "A las Ruinas" | `amuleto_alba` | `vigia_bruma` | `ruinas_1` |
| "A la Fuente" | `vigia_bruma` | — | `fuente` |
| "Al portal" | — | — | `caravana` (con `TravelPortal`) |

- Una zona de una etapa pasada no se puede volver a visitar, como en la v2. Tras el final, las salidas a las zonas no vuelven (la Fuente tampoco: su salida tiene `gone` `eco_albor`).

### Ciénaga de Brumaclara

- Agua quieta (planos oscuros a ras de suelo, sin nadar: el sendero los rodea), juncos, troncos caídos y árboles muertos con musgo (Kenney Nature Kit). Un sendero de tablas hasta el nido de la Garza; tres islotes con cofre.
- Hierba corta verde oliva, niebla verdosa, el sol negro.
- Ambiente: ranas y agua; partículas: luciérnagas y bruma (`fireflies`, `mist`).

### Cuevas de cristal

- Dos plantas de celdas como la mina, pero sin linterna: cristales azules y violetas en las paredes que dan luz (`OmniLight3D` en algunas celdas `T`, con otra cara: cristal en lugar de antorcha). Suelo de piedra clara.
- Planta 1: la palanca y la reja de la mina con otra cara (`lever_flag`, `door_flag`). Planta 2: la sala del Coloso.
- Ambiente: gotas y un zumbido grave; partículas: destellos (una clase nueva de `ZoneParticles`, `sparkle`).

### Ruinas flotantes

- Dos plantas de celdas al aire libre: las celdas de roca no son muros sino vacío (un campo nuevo, `floating`: la roca se dibuja como un abismo de niebla bajo el borde de las islas y no se pinta ninguna pared). Suelo de losas viejas, columnas rotas.
- Planta 1: puentes entre islas. Planta 2: la explanada del Vigía.
- Ambiente: viento (`mountain`); partículas: bruma.

### La Fuente de la Niebla

- Una planta de celdas abierta al cielo: una caverna sin techo bajo el sol negro, con la Fuente en el centro (un pozo de luz azul que "respira": una luz que sube y baja y partículas que suben). El Eco de Albor espera delante.
- Ambiente: `portal` con un latido grave; partículas: bruma que sube.

### Lo que cada zona necesita además del mapa

- Un fondo de combate en `BattleStage`: `cienaga`, `cuevas` (una variante de `mina` con cristales), `ruinas` y `fuente`.
- Su música en `MusicLibrary`: `swamp`, `crystal`, `ruins`, `source`, y `albor` para el último combate.
- Su ambiente y sus partículas.
- Su punto de entrada en `--autoplay-zone` y su ruta de la partida automática.

## M-80. Los enemigos

### Comunes

Cinco por zona, veinte en total. Donde se puede son variantes de figuras que ya existen (otro color y otra escala); las demás son figuras nuevas hechas en código.

| Zona | Enemigo | Figura | Rasgo |
|---|---|---|---|
| Ciénaga | Sapo de légamo | `RANA_DARDO` gris verdoso, ×1,4 | Su golpe envenena |
| Ciénaga | Sanguijuela | `SERPIENTE_LIANA`, corta y morada | Roba vida (se cura una vez, `rescue_heal`) |
| Ciénaga | Fuego fatuo | Nueva (llama azul que flota) | Rápido; débil a la luz |
| Ciénaga | Junco andante | `PLANT`, ocre | Esporas de sueño |
| Ciénaga | Caimán de bruma | Nueva | DEF alta; golpe cargado |
| Cuevas | Murciélago de cristal | `BAT`, violeta translúcido | Muy rápido |
| Cuevas | Slime de cristal | `SLIME`, azul cristal | Resiste el hielo y el rayo |
| Cuevas | Golem de cuarzo | `STONE_GOLEM`, violeta | Golpe que aturde |
| Cuevas | Araña de cristal | `ARANA`, azul | Va en pareja; veneno |
| Cuevas | Topo de geoda | Nueva | Pide ayuda a un Slime de cristal |
| Ruinas | Ave de bruma | `BUITRE`, gris azulado | Muy rápido |
| Ruinas | Gárgola antigua | `GARGOLA`, piedra clara con musgo | Resiste todo menos la luz |
| Ruinas | Caballero de bruma | `ARMADURA_HUECA`, azul | DEF muy alta; débil a la luz |
| Ruinas | Espíritu del viento | `SPECTER`, blanco azulado | Vendaval a todos |
| Ruinas | Medusa de niebla | Nueva (campana que flota y tentáculos) | Silencio |
| Fuente | Sombra de Albor | `SOMBRA`, azul y blanco | Débil a la luz; silencio |
| Fuente | Ojo de la Niebla | Nueva (un ojo con un halo) | Sueño a todos |
| Fuente | Lobo de niebla | `WOLF`, gris translúcido | Va en pareja |
| Fuente | Slime de bruma | `SLIME`, blanco azulado | Pide ayuda a otro Slime de bruma |
| Fuente | Centinela caído | `Knight.glb` con armadura azul gastada | Golpe cargado |

- Sus números se fijan con la partida automática para que cada zona se juegue en unos 25 minutos y el héroe salga con el `exit_level` de la tabla.
- Todos tienen `map_roam` y `map_speed`, retrato en `assets/bestiary/` y botín.

### Los jefes de zona

| Jefe | Figura | Rasgo |
|---|---|---|
| Garza de légamo | Nueva (garza enorme de patas largas, con una lámpara que brilla en el buche) | Picotazo fuerte a uno y pide ayuda a un Sapo de légamo |
| Coloso de cuarzo | `STONE_GOLEM` ×1,9 con cristales en la espalda | Golpe cargado y se cura una vez; resiste el fuego |
| Vigía de la bruma | `Knight.glb` ×1,6, armadura azul y una lanza | Silencio y golpe cargado; al vencerlo: "Lleváis su luz. Pasad." |

### El jefe final: el Eco de Albor

- Es el Eco de la Niebla de la v1, ya completo: la misma figura del Señor de la Niebla, más grande y con una corona azul clara.
- Dos fases (`next_phase`):
  - **Fase 1, "El Eco de Albor":** golpes fuertes y "Bruma negra" (daño a todos con sueño).
  - **Fase 2, "Albor corrompido":** la figura crece y la corona se apaga (`play_phase()`). Gana "Sol negro" (mucho daño a uno) y un golpe cargado. Es débil a la luz.
- Pensado para un héroe de Nv 49-50 con el equipo del alba, el compañero y Alba.
- Al vencerlo, la elección (M-84).

### El bestiario

- La v3 añade cuatro familias con sus premios (las reglas de `Bestiary` de siempre, en una lista `V3_FAMILIES` y su `V3_ENEMIES`):

| Familia | Enemigos | Premio |
|---|---|---|
| Bestias de Brumaclara | Sapo de légamo, Sanguijuela, Junco andante, Caimán de bruma, Araña de cristal, Topo de geoda, Lobo de niebla | Anillo de bruma (VEL +4 · ATK +8) |
| Cristal y piedra | Murciélago de cristal, Slime de cristal, Golem de cuarzo, Gárgola antigua, Caballero de bruma, Centinela caído | Amuleto de cuarzo (inmune al sueño · DEF +8) |
| Hijos de la Niebla | Fuego fatuo, Ave de bruma, Espíritu del viento, Medusa de niebla, Sombra de Albor, Ojo de la Niebla, Slime de bruma | Amuleto del faro (inmune al silencio y al veneno · VEL +3) |
| Guardianes de la Fuente | Garza de légamo, Coloso de cuarzo, Vigía de la bruma, Eco de Albor | Espada de Albor (ATK +100) |

- El bestiario pasa de 47 a 71. La página Bestiario gana una tercera parte con el título "Brumaclara".
- Las familias se dan en la 3.3.0, cuando ya están todos sus enemigos (como en la v2).

## M-81. Equipo, objetos y niveles

### Nivel máximo 50

- `Leveling.MAX_LEVEL` pasa a 50 y `EXP_TABLE` sigue hasta el 50 desde la 3.0.0. `level_cap()`: 20 en la parte 1, 40 en la 2, 50 en la 3.
- El plan fija los números con la partida automática: el héroe entra con Nv 40, sale de cada zona con su `exit_level` y llega al Eco de Albor con Nv 49-50.
- `GAINS` no cambia.
- El compañero sigue creciendo: en la parte 3, `Allies.data(ally_id, tramo)` recibe 5 + la etapa (6 a 9: un paso de `GROWTH` más por etapa). `Allies.ARRIVALS` gana una frase de cada compañero al llegar a cada zona de la v3.

### El elemento luz y Alba

- `Skill` gana el elemento `light` ("luz"), con su color. Lo usan las debilidades (`weak`) de los enemigos de la Niebla y solo un hechizo del héroe.
- **Alba** (Nv 45, 20 PM): daño de luz a todos. Es el hechizo más fuerte del héroe contra los Hijos de la Niebla y el Eco.

### Equipo

- Cuatro juegos más, uno por etapa (zonas 9 a 12 de `Equipment`), con casco:

| Etapa | Material | Arma | Armadura | Escudo | Casco | Dónde se compra |
|---|---|---|---|---|---|---|
| 1 | Bruma | ATK +86 | DEF +62 | DEF +28 | DEF +20 | Mercader de la Caravana |
| 2 | Cristal | ATK +98 | DEF +70 | DEF +31 | DEF +22 | Mercader de la Caravana |
| 3 | Luna | ATK +110 | DEF +78 | DEF +34 | DEF +25 | Herrero de cristal |
| 4 | Alba | ATK +124 | DEF +88 | DEF +38 | DEF +28 | Herrero de cristal |

- Los números y precios son un punto de partida que el plan ajusta. Usan las mallas y los tintes de los juegos de la v2.
- `Shop.SHOPS` gana `caravana_5`, `caravana_6`, `brumaclara_3` y `brumaclara_4`; un selector por etapa (como `caravan_shop`) elige la tienda. El Herrero vende también los consumibles; el mercado de la etapa 4 es solo adorno.

### Objetos

- Un objeto nuevo, solo de datos: **Elixir** (cura todos los PV y PM, 400 G), a la venta desde la etapa 3.
- Objetos de misión nuevos, como la Seta: Junco de bruma, Esquirla de geoda.

## M-82. Las ocho misiones

- Todas son `QuestData` con los tipos de siempre, aceptadas en Brumaclara (tablón o un vecino) y entregadas a **Orvalla** en Brumaclara (la regla de las entregas al Jefe pasa a ser "la figura que recibe las de su parte").

| Etapa | id | Tipo | Quién la da | Qué pide | Premio |
|---|---|---|---|---|---|
| 1 | `juncos` | `GATHER` | Tablón | 4 Juncos de bruma (botín del Junco andante) | 900 G, 2 Pociones grandes |
| 1 | `pescador` | `FIND` | Vecino | Un pescador perdido en un islote de la Ciénaga | Semilla de agilidad |
| 2 | `gato_nebli` | `FIND` | Neblí | Su gato, perdido en las Cuevas | Semilla de defensa |
| 2 | `geodas` | `GATHER` | Tablón | 3 Esquirlas de geoda (botín del Topo de geoda) | 1200 G, 2 Éteres grandes |
| 3 | `cartas` | `DELIVER` | Vecina | Unas cartas para la Viajera de la Caravana | Semilla de fuerza |
| 3 | `caballeros` | `HUNT` | Tablón | 5 Caballeros de bruma | 1500 G, Elixir |
| 4 | `ojos` | `HUNT` | Tablón | 4 Ojos de la Niebla | 1800 G, 2 Elixires |
| 4 | `piezas_faro` | `FIND` | Orvalla | La última pieza del faro, en la Fuente | Semilla de fuerza y Semilla de agilidad |

- `QuestLog.total_of(part)` cuenta las de cada parte. El Diario, en "Colección", gana "Misiones de Brumaclara: n/8" y "Brumaclara: terminada|en camino".

## M-83. La vuelta a Villaclaro

- Al vencer al Coloso se ve el primer recuerdo de Albor (`recuerdo_albor`): un joven guardián mira un amuleto partido en tres. Orvalla: "Esa luz la conozco. Es de la Fuente. ¿Dónde la habéis visto?". El objetivo pasa a "vuelve a Villaclaro".
- La Caravana gana una salida **"A Villaclaro"** con `needs` `coloso_cuarzo` y `gone` `amuleto_alba`: el Jefe tiene "un atajo que encontramos al venir". Lleva a la entrada norte de `pradera`.
- En la parte 3, la pradera solo tiene esa salida de vuelta ("A la caravana"): las salidas al bosque y al resto de la v1 tienen `gone` `brumaclara`. Los monstruos de la pradera se quedan (son flojos y huyen del héroe, como en las zonas superadas).
- Los vecinos de Villaclaro tienen frases nuevas para el capítulo 13; las salidas de la pradera vuelven a tener niebla (la Niebla se escapa).
- Al hablar con la Abuela Rosa se ve la escena `amuleto`: su abuelo encontró en el norte "una piedra que brillaba", la partió en tres para repartirla, y desde entonces la niebla rondaba el castillo. Da el **Amuleto del Alba** (objeto clave `amuleto_alba`, y la bandera del mismo nombre).
- Con el amuleto, la salida "A Villaclaro" de la Caravana desaparece: el héroe ya no vuelve. La pradera sigue siendo una zona válida en la parte 3, por si la partida se guardó allí; la salida "A la caravana" de la pradera no tiene `gone`, así que nadie se queda atrapado.
- Visita corta: unos 5 minutos.

## M-84. El Eco de Albor, la elección y los finales

- Al vencer la fase 2 se ve la escena `albor`: el Eco se arrodilla junto a la Fuente y la corona se apaga. Habla como Albor: salió a buscar la luz que se llevaron y la Niebla lo fue llenando.
- La pregunta (`World.ask()`): "El Amuleto del Alba brilla en tu mano. ¿Qué haces?" con **"Devolver el amuleto"** y **"Acabar con el Eco"**. El foco empieza en la primera; Esc y tocar fuera eligen la última, como siempre (las dos acaban bien).
- **Devolver el amuleto** (`albor_liberado`): el amuleto vuelve a la Fuente, Albor recupera su forma y se queda de guardián. El sol negro se aclara un poco y Neblí ve el sol por primera vez.
- **Acabar con el Eco** (`albor_vencido`): la Fuente se cierra a medias, la Niebla vuelve a su sitio y Brumaclara se salva, pero Albor desaparece. Orvalla pone una estatua en la plaza.
- Las dos ponen `eco_albor` y `story.finished_v3`; cambian la escena final (`final_v3_liberado` o `final_v3_vencido`), una frase de los créditos y lo que se ve en Brumaclara después.
- El Eco de la Niebla del salón del trono de la v1 ya no se puede visitar (la v1 está cerrada); no cambia nada allí.
- **Créditos de la v3** (`CreditsData.v3_credits_sections`): "El origen de la Niebla", la historia del héroe, Compañero, Tiempo en Brumaclara, Combates en Brumaclara, Misiones de Brumaclara, Familias, Nivel y el final ("Albor guarda la Fuente" o "La Niebla ha vuelto a su sitio"). Texto final: "Fin".
- Después de los créditos la partida sigue en Brumaclara en fiesta, que se puede recorrer. No hay jefe de después del final.

## M-85. Partida automática de la v3

- `--autoplay-zone=brumaclara`: la v2 terminada (Nv 40, equipo estelar, Brena), en la Caravana con el portal; cruza, juega la v3 entera (con la visita a Villaclaro) y acaba en "Juego completado (v3): Nv %d, tiempo en Brumaclara %s, tiempo de juego %s, misiones de Brumaclara %d/%d" con las líneas de familias, derrotas y medallas.
- `--autoplay-zone=cienaga`, `cuevas`, `ruinas` y `fuente`: empiezan en esa zona con el héroe que llega allí, como `V2_STARTS`.
- `--autoplay-ending=vencer`: elige "Acabar con el Eco" en la pregunta final (sin la opción, la primera, como todas las preguntas en piloto automático).
- La salida de la v2 en piloto automático no cambia: `--autoplay-zone=caravana` sigue acabando en la v2.

## Duración

| Parte | Objetivo |
|---|---|
| Llegada a Brumaclara | 3 min |
| Cada zona | ~25 min |
| Cada vuelta a Brumaclara o a la Caravana | 2-3 min |
| Visita a Villaclaro | ~5 min |
| Eco de Albor y final | ~15 min |
| **Total** | **~2 h** |

## Arquitectura

Se sigue `structuring-godot-code` y las convenciones de `CLAUDE.md`. Los dueños grandes (`game.gd`, `world.gd`, `battle_actor.gd`) no crecen; lo nuevo va en piezas:

| Qué | Dónde |
|---|---|
| La parte, la etapa, los capítulos y objetivos | Reglas puras: `GameState.part()`, `StoryState.etapa()` y sus tablas |
| El paso por el portal, la llegada y la vuelta a Villaclaro | `StoryFlow` (el fin de la v2) y una pieza nueva `V3Flow` (`Node` hijo de `Game` con `SessionContext`), como `CaravanFlow` |
| La elección y los finales | `V3Flow`; los créditos en `CreditsData` |
| Brumaclara vestida | Constructor nuevo `BrumaclaraLook`, como `CampLook` |
| La salida con portal | `MapProps._build_exit` usa `TravelPortal` cuando la salida tiene `look: "portal"` |
| El sol negro | Constructor nuevo `BlackSun`, usado por `WorldStage`, `DungeonMap` (la Fuente) y `BattleStage` |
| Las islas flotantes | `DungeonMap` con `floating` |
| Las figuras nuevas | Sus datos en un archivo aparte de `ActorLooks` (`ActorLooksV3`, unido a `LOOKS`) y su construcción en un constructor nuevo `MistCreatureBuilder`, al que `CreatureBuilder.build` llama: `actor_looks.gd` (824 líneas) y `creature_builder.gd` (772) no crecen |
| Fondos de combate | `BattleStage` con un `_build_x` por fondo; si pasa de ~700 líneas, los de la v3 van en un constructor `V3Backdrops` |
| Interfaz | Solo `UiTokens` / `UiTheme`; un color nuevo (la luz) entra por `tokens.json` |

## Versiones

| Versión | Contenido | Puntos |
|---|---|---|
| **3.0.0** | La base y la Ciénaga: el fin de la v2 sin volver al título, la salida con portal, la parte 3 (etapa, capítulos, zonas, guardado 15), Brumaclara apagada y con el faro encendido tras la Garza (etapas 1-2 de `BrumaclaraLook`), el sol negro, Orvalla y Neblí, la Caravana con niebla, el nivel 50, el juego de bruma, la Ciénaga entera (mapa, 5 enemigos, Garza de légamo, 2 misiones, fondo, música, ambiente) y la tercera parte del Bestiario | M-76 a M-78, M-81 (nivel, bruma), y la Ciénaga de M-79, M-80 y M-82 |
| **3.1.0** | Las Cuevas de cristal: dos plantas, 5 enemigos, Coloso de cuarzo, el juego de cristal, el elemento luz y Alba, la forja de Brumaclara (etapa 3), el recuerdo de Albor, 2 misiones, fondo, música, ambiente y los destellos | M-79 a M-82 (Cuevas) |
| **3.2.0** | La vuelta a Villaclaro y las Ruinas: la salida de la Caravana, la escena del amuleto, las dos plantas flotantes, 5 enemigos, Vigía de la bruma, el juego de luna, el Elixir, el mercado y la Coleccionista (etapa 4), 2 misiones, fondo, música y ambiente | M-83, M-79 a M-82 (Ruinas) |
| **3.3.0** | La Fuente y el final: la planta de la Fuente, 5 enemigos, el Eco de Albor en dos fases, el juego del alba, 2 misiones, la elección, los dos finales, la fiesta (etapa 5), los créditos de la v3 y las cuatro familias con sus premios | M-79 a M-82 (Fuente), M-84, M-85 completo |

- Cada versión se publica jugable: si la salida de la siguiente zona no existe todavía, Orvalla dice "Todavía no sabemos cómo seguir. Descansa, y vuelve cuando la luz nos diga algo." en lugar de abrirla.
- Cada versión tiene su plan en `docs/boost/plans/` y su fila en el documento maestro, y se mide con su `--autoplay-zone` y la partida automática de lo que ya existe. La 3.3.0 mide la v3 entera.

## Verificación

- `--check-only` de lo cambiado, `--import` tras cada `class_name` nuevo, `gen_ui_tokens.gd -- --check` y `check_ui_values.gd`.
- Cada zona con su `--autoplay-zone`, sin errores y con el héroe en el nivel que toca; la v3 entera con `--autoplay-zone=brumaclara` y los dos finales.
- `--autoplay-zone=caravana` sigue acabando en "Juego completado (v2)".
- Fotogramas (`--write-movie`) de Brumaclara en cada etapa, de cada zona y su fondo de combate, de los jefes, del Eco en sus dos fases, de la elección, de los dos finales y de los créditos, también en el móvil (`--resolution 740x360 -- --touch`).
- Cargar una partida de la versión 14 terminada en la v2: aparece en la Caravana con el portal. Una de la v1 y otra de la v2 a medias: todo igual que hoy.
- El viaje de ida y vuelta del guardado en la v3 y la exportación web.

## Fuera de la v3

- Volver al bosque, la mina o el castillo de la v1.
- La niebla espesa de las Ruinas.
- Un premio nuevo de la Coleccionista; las medallas siguen siendo doce.
- Un jefe de después del final de la v3.
- Que el compañero o la criatura se vean en el mapa (está en `ideas.md`, aparte).
- Una v4.
