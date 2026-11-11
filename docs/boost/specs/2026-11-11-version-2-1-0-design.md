# Versión 2.1.0: el desierto (decisiones del plan)

Fecha: 2026-11-11. El diseño es el de la v2, `docs/boost/specs/2026-11-10-version-2-0-0-design.md` (M-43 a M-46, la fila 2.1.0 de "Versiones"). Esta hoja solo fija lo que aquel dejó abierto. Plan: `docs/boost/plans/2026-11-11-version-2-1-0.md`.

## Decisiones

| Tema | Decisión |
|---|---|
| Dunas dentro del campo | Elipsoides medio enterrados del color de la arena (`ZoneData.dunes`), **sólidos**: una fila de cilindros a lo largo de su eje largo. Un montículo que se pudiera atravesar taparía los pies del héroe con la cámara cenital. Los árboles, la decoración, la hierba y los grupos de monstruos se apartan de ellas; una duna que pisa el camino, la ruta automática, una entrada, una salida, un cofre, un pozo, una figura o el jefe da un `WARNING` al construir el mapa ("Duna en (x, z) pisa ...") |
| Palmeras solo en el oasis | `ZoneData.tree_areas` (discos): si una zona los tiene, sus árboles solo salen dentro. Las palmeras son las de la jungla (`PalmModels`) |
| Colores del suelo | `ZoneData.path_color` (el sendero de tierra pisada, más oscuro que la arena), `hill_color` (las colinas de fuera y las dunas) y `ground_patches` (el verde del oasis). Por defecto, los de hoy: las zonas que ya existen no cambian |
| Grupos de monstruos sin hierba | `MonsterGroups` ya no pide hierba: en cualquier mapa abierto, fuera del camino (como decía el spec). Además se apartan de las dunas lo que un grupo puede andar (`MAX_ROAM` + 0,5 m) |
| La ruina | Columnas, columnas rotas y bloques del Nature Kit (`statue_column`, `statue_columnDamaged`, `statue_block`) teñidos de arenisca. En la 2.0.1 las estatuas se quedaron fuera de los mapas de la v1; aquí son la ruina, con el tono del desierto. Los cactus son `cactus_short` / `cactus_tall` y los matojos `plant_bushSmall`, todos de Kenney, teñidos |
| Figuras nuevas | Escorpión y Gusano de las dunas, nuevas en código. Buitre: el murciélago con cabeza calva, pico ganchudo, gorguera y alas más anchas. Momia: el `Skeleton_Warrior` teñido de blanco sucio y **sin armas** (las vendas no llevan espada). Slime de arena y Golem de arena: colores nuevos de los de siempre |
| El Gusano | Una fase, sin hechizos: golpe cargado (`charge`) y pide ayuda a un Slime de arena (`help`). Débil al hielo, resiste el fuego |
| La cantimplora | La misión `FIND` busca una figura. La cantimplora es una figura de un tipo nuevo, `item` (prompt "Coger · Cantimplora", la figura `CANTEEN`, quieta); lo que se dice al encontrarla lo dice el narrador. Solo está en el mapa mientras se busca |
| Quién entrega | `escorpiones` (tablón) y `cantimplora` (el Viajero) se entregan al Jefe de caravana: el Mercader y la Curandera son tienda y posada, y hablar con ellos abre su ventana |
| El Viajero | Una figura nueva de la Caravana con `needs` `jaguar_sombrio`: llega con el tramo 2, como pedía el spec ("la segunda llega con la 2.1.0") |
| Entregas en una tienda | Se corrige lo que la 2.0.0 dejó: `pieles_mono` se entrega al Mercader, que es una tienda, y un jugador nunca podía entregarla (solo la partida automática). Ahora una entrega que espera en la figura de una tienda se hace antes de abrir la tienda |
| Números | Equipo de oricalco en la zona 6 de `Equipment` (el jade es la 5). El desierto es el `ZoneData.number` 7 (la jungla, el 6) |
| Cofres | 400 G tras una duna del oeste, un Éter grande en el oasis y una Pluma de fénix en la ruina. Con la caravana, la colección pasa de 16 a 19 cofres |
| Textos de la Caravana | La escena `jaguar` ya no dice "aún no podemos seguir": el desierto se abre. Lo dice ahora la escena `gusano` y el Jefe en el capítulo 8. `StoryState.NOT_YET_GOAL` sale en cualquier capítulo de la v2 cuya zona no esté en `ZoneData.IDS` (la montaña, en la 2.1.0) |
| Bestiario | Los seis del desierto entran en `Bestiary.V2_ENEMIES` (de 28 a 34 en una partida con la caravana), sin familia hasta la 2.3.0 |
| Guardado | Sigue en la versión 14: solo hay ids nuevos |
| Brief de QA | No se toca: no cubre la v2 y la v1 no cambia |
