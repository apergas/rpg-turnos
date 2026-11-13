# Versión 2.2.0: la montaña (decisiones del plan)

Fecha: 2026-11-11. El diseño es el de la v2, `docs/boost/specs/2026-11-10-version-2-0-0-design.md` (M-43 a M-46, la montaña; la fila 2.2.0 de "Versiones"; "Partida automática"; "Verificación"). Esta hoja solo fija lo que aquel dejó abierto. Plan: `docs/boost/plans/2026-11-11-version-2-2-0.md`.

## Decisiones

| Tema | Decisión |
|---|---|
| La roca con nieve | Cada bloque de roca de las dos plantas es el `cliff_block_stone` del Kenney Nature Kit (un cubo con la cara de arriba de "hierba" y los lados de piedra), teñido: la hierba pasa a nieve y la piedra a gris. Es exactamente "roca gris con nieve encima", y cuesta lo mismo que la caja de hoy (una llamada por bloque junto al suelo, los enterrados en un `MultiMesh`). `ZoneData` gana `rock_piece` (la pieza de `NatureModels` del bloque; vacío: la caja de `rock_color`, como en la mina) |
| Al aire libre | Las plantas no son `underground`: cielo, sol y niebla clara. Como en el patio del castillo, el suelo sigue más allá de la cuadrícula; aquí, de nieve (`hill_color`), con picos nevados alrededor (`hills`, que ahora también se construyen en las plantas de celdas). Sin antorchas ni farol |
| Suelo | Nieve (`floor_color` gris muy claro) con grupos de piedras planas de Kenney (`snow_stones`) puestos a mano: "piedra y nieve" sin cuadros ni texturas |
| Decoración | Pinos (`tree_pineTallA`, `tree_pineSmallA`), piedras altas (`stone_tallA`) y piedras planas, todos de Kenney, teñidos de verde oscuro y gris. Puestos a mano en las salas, fuera de la ruta. Los pinos usan el sombreador de los árboles, así que el héroe se ve a través |
| Planta 1, "La subida" | 15 × 13 celdas. Se entra por el sur desde la Caravana. Una reja (`D`) cierra la sala de la escalera de subida (`S`, noroeste); la palanca (`L`) está en un recoveco del centro. Bandera `montana_palanca` (palanca y reja a la vez, como en la segunda planta de la mina). Dos cofres |
| Planta 2, "La cumbre" | 15 × 13 celdas. Se llega por la escalera de bajada (`B`, al sur). Al norte, una explanada de 7 × 3 celdas con el Grifo en `(0, -18)`. Un cofre. Sin reja |
| Pozos | Dos por planta, como en la mina: `montana_1_vida` / `_mana` y `montana_2_vida` / `_mana` |
| Grupos de monstruos | 8 en la planta 1 y 7 en la 2. El Lobo de las nieves solo va en pareja. El Golem de hielo sale en las dos plantas (lleva los cristales) |
| Figuras | Variantes: Lobo de las nieves (`SNOW_WOLF`, el lobo blanco con ojos azules), Golem de hielo (`ICE_GOLEM`, el golem de piedra azul hielo ×1,3), Espíritu de la cumbre (`SUMMIT_SPIRIT`, el espectro blanco ×1,2 con un aura dorada pálida: el Espectro de escarcha ya es blanco y azul), Murciélago de la cueva helada (`ICE_BAT`, azul). Nuevas en código: Cabra montesa (`GOAT`) y Grifo de la cumbre (`GRIFFIN`: cuerpo de león, pecho y cabeza de águila blancos, pico dorado y dos alas que baten despacio) |
| El golpe que aturde | El spec pide que la Cabra montesa haga perder el turno. El `stagger` de hoy es otra cosa (el propio enemigo se tambalea y pierde su turno). Se añade un estado de combate pequeño, `stun`: lo pone el golpe de la Cabra (`attack_status` "stun", 25 %), el que lo sufre pierde su siguiente turno y se le quita al perderlo. Sin insignia en la ventana de estado (dura un turno), sin inmunidad, y el compañero no lo sufre (como los demás estados). Textos: "¡El golpe deja sin aliento a {nombre}!" y "{nombre} aún no se recupera del golpe." |
| Hechizos de los enemigos | `ventisca_cumbre` (el Espíritu: hielo a todos, 40), `vendaval_grifo` ("Vendaval helado", hielo a todos, 62) y `curar_grifo` (el `rescue_heal` del Grifo: 500 PV, una vez, por debajo del 35 %) |
| El Grifo | Una fase. Débil al rayo, resiste el hielo. Da el Mapa de la montaña |
| Sanación | Nv 32, 12 PM, cura 150, sustituye a Curar+. `BattleAutoplay` ya usa siempre la curación más fuerte que sabe: no cambia |
| Adamantita | Zona 7 de `Equipment`: espada ATK +60 (1750 G), armadura DEF +44 (1450 G), escudo DEF +20 (800 G), casco DEF +14 (640 G), las mallas de platino teñidas de violeta acero. La tienda `caravana_3` las vende con los objetos de siempre |
| Misiones | `cabras` (tablón, 5 Cabras montesas, se entrega al Jefe de caravana; 600 G y 2 Éteres grandes) y `cristales_hielo` (la Viajera, 3 Cristales de hielo, 40 % del Golem de hielo, se le entrega a ella, que es una figura `npc`; Semilla de defensa). Las dos con `needs` `gusano_dunas` |
| Cofres | 500 G (planta 1, noreste), una Pluma de fénix (planta 1, oeste) y un Éter grande (planta 2, oeste). La colección pasa de 19 a 22 cofres |
| Cuentas | Misiones de la caravana n/6; bestiario n/40 en una partida con la caravana (los seis de la montaña en `Bestiary.V2_ENEMIES`, sin familia hasta la 2.3.0) |
| Historia | La escena `gusano` ya no dice "aún no podemos seguir": se abre la montaña. Lo dice ahora la escena `grifo` (que acaba en la Caravana) y el Jefe en el capítulo 9. En el capítulo de la montaña el objetivo sigue la planta y la palanca (`MOUNTAIN_GOALS`, como `MINE_GOALS`) |
| Fondo de combate `montana` | Nieve, una senda de piedra gris, las rocas de KayKit (la base de todos los fondos), acantilados nevados detrás (el mismo bloque del mapa) y picos blancos, con pinos y una piedra alta de Kenney. Sin hierba ni arbustos |
| Sonido y partículas | Música `mountain` (Mi menor, 92 bpm, una melodía amplia); ambiente `mountain` (un viento fuerte que no para, con aullidos por encima); partículas `snow` (copos que caen despacio, de lado) |
| Guardado | Sigue en la versión 14: solo hay ids nuevos |
| Brief de QA | No se toca: no cubre la v2 y la v1 no cambia |
