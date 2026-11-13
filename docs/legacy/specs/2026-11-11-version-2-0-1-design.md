# Versión 2.0.1: decoración Kenney

Fecha: 2026-11-11. Parte de la 2.0.0 (la caravana, los compañeros y la jungla). Cubre M-48 del documento maestro, la única entrada de la prioridad 7.

## Objetivo

Los mapas que ya existen se ven más vivos con decoración pequeña del **Kenney Nature Kit** (CC0, ya descargado en `assets_src/kenney-nature-kit/`): flores, setas, tocones, troncos, helechos, vallas, un campo de cultivo y hogueras. KayKit sigue siendo la base: árboles, rocas, casas y personajes no cambian. Kenney entra solo donde no hay nada todavía, y en los arbustos hechos en código solo si los suyos quedan mejor.

No cambia ninguna regla del juego, ningún texto del juego, ni el guardado (sigue en la versión 14).

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Regla del usuario | "Usa siempre la mejor opción a nivel gráficos (la más bonita), teniendo en cuenta que tiene que quedar bien y ser todo del mismo estilo." Cada elección se compara con fotogramas antes y después, lado a lado, antes de quedarse |
| Base | KayKit (árboles, rocas, casas, personajes) no se toca. Las palmeras de Kenney de la 2.0.0 siguen como están |
| Color | Los modelos del kit son de color plano por material (`grass`, `woodBark`, `wood`, `stone`, `colorRed`...). Sus verdes son turquesa: todos se tiñen con un verde de la zona (`ZoneData.decor_green`); maderas, piedras y colores de flor se llevan a una paleta propia más apagada, cerca de los marrones de KayKit |
| Cómo se dibuja | Una `MultiMesh` por modelo y por zona, con el `tree.gdshader` de los árboles (el agujero que deja ver al héroe), como las palmeras. Un modelo de varias piezas (un ramo de flores, una fila de trigo, la hoguera) se funde en una malla, con una superficie por material |
| Cuántos | Presupuesto: como mucho **20 llamadas de dibujo más** por zona que en la 2.0.0, medido en pantalla |
| Calidad baja | La mitad de la decoración suelta pequeña (flores, setas, helechos), como `Vegetation.half_density`. Lo que tiene colisión no cambia nunca con la calidad, para que el mapa sea el mismo |
| Tamaño web | Solo se copian a `assets/nature/` los GLB usados, sin cambios (unos 16 archivos de 4-30 KB) |
| Colisión | Solo donde un obstáculo real tiene sentido: vallas, troncos grandes, tocones, montones de leña, vasijas, la hoguera. Nada en flores, setas, helechos ni cultivos |
| Arbustos | Se prueban los de Kenney (`plant_bushDetailed`, `plant_bushLarge`) teñidos contra el blob de `LowPoly`, en mapa y en combate. Se queda el que se vea mejor; la recomendación de partida es Kenney, porque su silueta de hojas casa mejor con los árboles de KayKit que una gota facetada |
| Combate | Los fondos `pradera`, `bosque` y `jungla` ganan unas pocas piezas fijas (flores, setas, tocón, tronco, helechos) fuera de donde están los luchadores. Mina y castillo no cambian |

## Qué lleva cada zona

| Zona | Puesta a mano | Suelta (semilla de la zona) |
|---|---|---|
| `pradera` (Villaclaro y la pradera) | Un campo de cultivo al este del pueblo: vallas (`fence_simple`) con una puerta (`fence_gate`), filas de trigo, maíz, calabazas y zanahorias sobre surcos (`crops_dirtRow`); un montón de leña (`log_stackLarge`) junto a una casa | Ramos de flores rojas, amarillas y moradas; tocones bajos; algún tronco caído; setas rojas sueltas |
| `bosque` | Un montón de leña junto a la taberna | Tocones altos y bajos, troncos caídos grandes, grupos de setas rojas y marrones |
| `jungla` | Nada | Helechos (`plant_flatTall`), hojas grandes (`grass_leafsLarge`), setas rojas, algún tronco caído |
| `mina_1` (el refugio) | Dos vasijas (`pot_large`) y un montón de leña junto al Herrero | Nada (bajo tierra no se ve y no hace falta) |
| `mina_2`, `mina_3`, `castillo_trono` | Nada | Nada |
| `castillo_patio` (el campamento) | Una hoguera (piedras y troncos, `campfire_stones` + `campfire_logs`, con llama y luz) entre las tiendas y un montón de leña | Nada |
| `caravana` | La hoguera en el centro del corro de tiendas | Nada |

La hoguera usa la llama y la luz de las antorchas (`BattleStage`), sin palo. Con la calidad baja (`BattleStage.plain_light`), la llama sin luz.

Fuera del kit queda todo lo que no casa: los acantilados, los caminos y ríos de baldosa, las estatuas, los puentes, las tiendas de campaña de Kenney (ya hay la de KayKit) y sus árboles y rocas (KayKit manda).

## Reglas de sitio

La decoración nunca estorba al juego. Toda pieza, puesta a mano o suelta, se aparta de:

- el camino y los discos seguros, la ruta de la partida automática, las salidas (y las escaleras de una planta), las entradas y el portal;
- los cofres y los pozos, las figuras, el jefe, las medallas pequeñas (a 2 m como mínimo, para que su brillo se vea), las rocas, las casas y los árboles;
- en una planta de celdas, solo sobre celdas de suelo y fuera de las salas de las escaleras.

Además:

- los árboles y los arbustos se apartan de lo puesto a mano (el campo de cultivo no tiene un árbol en medio);
- la hierba alta no crece sobre lo que tiene colisión ni sobre lo puesto a mano;
- los grupos de monstruos (`MonsterGroups`) no se colocan sobre nada que tenga colisión: `WorldStage.is_clear_of_props()` lo cuenta.

Una pieza puesta a mano en un sitio prohibido no se quita sola: el mapa avisa al construirse con un `WARNING` que dice qué pisa ("Decoración: valla en (14.0, -19.0) pisa la ruta automática"). Cualquier `WARNING` en una partida automática es un fallo.

## Lo que no entra

- Ni árboles, ni rocas, ni casas, ni personajes de Kenney.
- Ninguna decoración en la mina (salvo el refugio), en el salón del trono ni en los fondos de combate de mina y castillo.
- Nada se mueve ni se anima: la llama de la hoguera es la de las antorchas de los fondos de combate, quieta.
- Ningún texto nuevo en el juego.

## Cómo se comprueba

Sin tests. A mano:

- `--check-only` de cada script tocado;
- un script del scratchpad que construye cada zona y cada fondo de combate con la cámara en unos puntos fijos y guarda una foto, antes (en `develop`) y después, y las junta lado a lado; también imprime las llamadas de dibujo de cada vista;
- la partida automática entera (`-- --autoplay`) y las de zona (`bosque`, `mina_1`, `castillo_patio`, `caravana`, `medallas`) acaban como antes y sin `WARNING` nuevos;
- el móvil, con `--resolution 740x360 -- --touch` y con la calidad baja.

Pendiente para el usuario: cómo se ve y cómo va en un móvil real.
