# v3: El origen de la Niebla (desarrollo)

Fecha: 2026-11-14. Desarrolla la opción 1 de [v3-guiones.md](v3-guiones.md), con el pueblo que crece de la opción 5. Todavía no es un spec: es el borrador con el que decidir la historia, las mecánicas y la progresión antes de escribirlo. Las decisiones abiertas están al final.

## La idea en una frase

Al otro lado del portal está Brumaclara, un pueblo que vive bajo un sol negro y respira la Niebla. Al vencer al Devorador el héroe rompió el sello que separaba los dos mundos, y ahora la Niebla se escapa hacia Villaclaro mientras Brumaclara se queda sin aire. Hay que llegar a la Fuente de la Niebla y equilibrarla, no apagarla.

## Lo que ya tenemos y se aprovecha

- **El sol negro.** La Viajera de la caravana ya lo dice en el capítulo 10 ("un pueblo bajo un sol negro"). Es un eclipse permanente, el mismo dibujo que el portal del Ala de viaje: el disco oscuro con la corona azul clara. Brumaclara tiene ese cielo.
- **El Amuleto del Alba.** En la v1 se juntan los tres fragmentos y se queda en Villaclaro. En la v3 se descubre qué es: un trozo de la luz de la Fuente que alguien de Villaclaro se llevó hace siglos. Por eso la Niebla bajó al norte en la v1: buscaba lo que le faltaba.
- **El Señor de la Niebla y el Eco.** El Señor era Albor, el antiguo guardián de la Fuente, que salió a buscar el amuleto y la Niebla lo corrompió. El Eco que sigue apareciendo en el salón del trono es lo que queda de él.
- **El Devorador del portal.** No era un monstruo sin más: era el cerrojo que Albor dejó antes de corromperse, para que la Niebla no cruzara. El héroe lo venció sin saberlo.
- **La caravana y el compañero.** La caravana espera junto al portal; el compañero de la v2 cruza con el héroe y sigue creciendo.
- **Las bases técnicas:** zonas abiertas y de celdas, `ZoneData`, misiones de datos, familias del bestiario, el campamento vestido por tramo (`CampLook`), el portal bidireccional que ya existe para el Ala de viaje.

## Personajes nuevos

| Quién | Dónde | Papel |
|---|---|---|
| **Orvalla**, la farera | Brumaclara | Guarda el faro de bruma que alumbra el pueblo bajo el sol negro. Es la que recibe al héroe y la voz principal de la v3, como el Jefe de caravana en la v2. Seria pero con humor seco. |
| **Neblí**, una niña | Brumaclara | Nunca ha visto el sol de verdad. Pregunta por él en cada capítulo; en el final lo ve. La parte tierna. |
| **El Herrero de cristal** | Brumaclara | Abre la tienda de equipo cuando vuelve la forja (ver "el pueblo que crece"). |
| **La Curandera** | Brumaclara | La posada. Cura con agua de bruma. |
| **Albor** | La Fuente | El guardián original. Aparece en recuerdos (escenas) y al final, liberado o no. |
| **La Alcaldesa Rosa** de Villaclaro | Villaclaro | Al volver a por el amuleto, la Abuela Rosa cuenta la vieja historia del abuelo que trajo "una piedra que brillaba". Sin ella no se sabe de dónde salió. |

Los nombres son provisionales.

## La historia, acto por acto

### Prólogo de la v3: el otro lado (3.0.0)

- La v2 termina con el cruce. La v3 empieza en Brumaclara: el pueblo está apagado, la gente callada y la Niebla del suelo se mueve hacia el portal, como un río.
- Orvalla explica que la Niebla es su aire, que siempre ha venido de la Fuente y que ahora "se va por tu agujero". Si se vacía, Brumaclara se ahoga; si llega toda a Villaclaro, vuelve lo de la v1, pero peor.
- **Primera vuelta por el portal.** El héroe vuelve a la caravana y la encuentra con niebla hasta las rodillas. El Jefe: "Te fuiste diez minutos y ya no veo mis botas". Así se ve la mecánica del portal en los dos sentidos.
- **Zona 1: la Ciénaga de Brumaclara.** Agua quieta, juncos y troncos podridos bajo el sol negro. El jefe es la **Garza de légamo**, un pájaro enorme que se ha tragado una lámpara del faro. Al vencerla, el faro vuelve a dar luz y Brumaclara recupera su primer edificio.

### Las cuevas de cristal (3.1.0)

- Orvalla cuenta que la Fuente está en lo alto de las Ruinas, y que para subir hace falta la luz de tres cristales que alguien partió hace siglos.
- **Zona 2: las Cuevas de cristal.** Un mapa de celdas, como la mina, pero luminoso: cristales que brillan en azul y violeta y alumbran sin linterna. Se reaprovecha la palanca y la reja de la mina con otra cara.
- El jefe es el **Coloso de cuarzo**. Al vencerlo se ve el primer recuerdo de Albor: un joven guardián que mira un amuleto partido en tres.

### Volver a por el amuleto (3.2.0, primera mitad)

- El recuerdo deja claro que el amuleto es la pieza que falta. Hay que volver a Villaclaro: portal → caravana → el camino de vuelta que se abrió en la v2.
- En Villaclaro, la Abuela Rosa cuenta que su abuelo encontró "una piedra que brillaba" en el norte, la partió en tres para repartirla y desde entonces la niebla rondaba el castillo. El amuleto está en su casa.
- Es una visita corta y muy de fan: los mapas de la v1 ya existen, con la niebla otra vez en las salidas y los vecinos con frases nuevas.

### Las ruinas flotantes (3.2.0, segunda mitad)

- **Zona 3: las Ruinas flotantes.** Islas de piedra unidas por puentes sobre un vacío de niebla, como la montaña pero hacia arriba. Dos pisos.
- El jefe es **Vigía de la bruma**, el último guardia que dejó Albor, que no deja pasar a nadie de Villaclaro. Al vencerlo dice: "Lleváis su luz. Pasad".

### La Fuente de la Niebla y el final (3.3.0)

- **Zona 4: la Fuente.** Una caverna abierta al sol negro, con la Fuente en el centro: un pozo de luz azul que respira.
- Allí espera el **Eco de Albor** (el Eco de la Niebla de la v1, ya completo). El combate tiene dos fases, como el Devorador.
- **La elección.** Al final de la segunda fase el héroe puede:
  - **Vencerlo:** la Fuente se cierra a medias, la Niebla vuelve a su sitio y Brumaclara se salva, pero Albor desaparece y el Eco no vuelve al castillo.
  - **Liberarlo con el amuleto:** el amuleto vuelve a la Fuente, Albor recupera su forma y se queda de guardián. El sol negro se aclara un poco: Neblí ve el sol por primera vez.
  - Las dos acaban bien. Cambian la escena final, una frase de los créditos y quién queda en Brumaclara en el juego de después.
- Créditos de la v3 con sus números (tiempo desde el cruce, misiones, familias, derrotas), como los de la v2.

## Mecánicas nuevas

Una por versión como mucho, como en la v2.

### 1. El portal en los dos sentidos (3.0.0)

- El portal de la ciudad deja de ser solo el final de la v2: une Brumaclara con la caravana de forma fija. Se cruza a pie, sin Ala de viaje.
- La caravana pasa a ser el "otro pueblo": tienda, posada y el Jefe con sus frases nuevas. El Ala de viaje sigue llevando al último pueblo visitado.
- Técnicamente es otra salida de `ZoneData` en la Caravana (`needs` del final de la v2) y otra en Brumaclara, con el aspecto del portal del Ala.

### 2. El pueblo que crece (3.0.0 a 3.3.0)

- Brumaclara empieza casi vacía y apagada: casas sin luz, la forja fría, el mercado cerrado.
- Cada jefe vencido trae algo que se ve en el mapa:

| Jefe | Lo que vuelve a Brumaclara |
|---|---|
| Garza de légamo | El faro se enciende: el pueblo se ve, y la posada abre |
| Coloso de cuarzo | La forja: el Herrero de cristal abre la tienda de equipo |
| Vigía de la bruma | El mercado y la Coleccionista; las casas con luz |
| Eco de Albor | La plaza en fiesta; Albor o una estatua de él, según el final |

- Se monta como el campamento vestido de la caravana: un `CampLook` por tramo, con edificios, luces y figuras que aparecen según las banderas de los jefes. No hay que construir nada a mano.

### 3. La niebla espesa (3.2.0, opcional)

- En las Ruinas, la niebla entre islas tapa el camino. Los faroles de bruma que se encuentran en el mapa la apartan durante un rato, como el Incienso pero con la vista.
- Solo si cabe: si la versión crece demasiado, se cae y las Ruinas se quedan sin ella.

### 4. La elección del final (3.3.0)

- Una pregunta con `World.ask()` al final del combate y una bandera (`albor_liberado` o `albor_vencido`). El resto es contenido.

## Progresión

- **Nivel:** el máximo sube de 40 a 50 al cruzar el portal, como la caravana lo subió de 20 a 40. Entradas aproximadas: Ciénaga Nv 40, Cuevas Nv 43, Ruinas Nv 46, Fuente Nv 49. Hacen falta diez filas nuevas en `EXP_TABLE`.
- **Hechizo nuevo:** uno solo, hacia el Nv 45 (por ejemplo **Alba**, luz contra todos, fuerte contra los de la Niebla). Encaja con el amuleto.
- **Equipo:** cuatro juegos nuevos, uno por tienda y tramo: bruma, cristal, luna y alba. Se compran en Brumaclara cuando vuelve la forja; antes, el Mercader de la caravana vende el primero.
- **Compañero:** sigue con el tramo (`Allies.GROWTH`) y dice una frase al llegar a cada zona nueva, como en la v2.
- **Bestiario:** unos 20 enemigos nuevos (cinco por zona) y cuatro jefes, en tres o cuatro familias nuevas con su premio. Hay que añadir un elemento débil a "luz", o reaprovechar los que hay.
- **Misiones:** unas ocho opcionales, dos por zona, todas entregadas a Orvalla (como al Jefe en la v2). Ideas: los juncos de la ciénaga, el gato de Neblí perdido en las cuevas, cartas de alguien de Brumaclara para la caravana, piezas del faro.
- **Medallas:** las doce no cambian. Como mucho, la Coleccionista de Brumaclara da un premio nuevo a quien ya las tenga todas.

## Reparto en versiones

| Versión | Qué trae |
|---|---|
| 3.0.0 | Brumaclara (apagada), el portal en los dos sentidos, la Ciénaga y la Garza de légamo, Orvalla y Neblí, el nivel 50, el primer juego de equipo |
| 3.1.0 | Las Cuevas de cristal, el Coloso de cuarzo, la forja de Brumaclara, el primer recuerdo de Albor |
| 3.2.0 | La vuelta a Villaclaro por el amuleto, las Ruinas flotantes, el Vigía de la bruma, el mercado y quizá la niebla espesa |
| 3.3.0 | La Fuente, el Eco de Albor en dos fases, la elección, los dos finales y los créditos de la v3 |

## Lo técnico que ya se ve venir

- `V3_ZONES` y un capítulo por tramo después del 10 (`StoryState`). Un `tramo()` de la v3 que siga al de la v2.
- La partida guardada probablemente pasa a la versión 15 (zonas nuevas, el final elegido); hay que mantener la carga de las de la 14.
- `SaveData.is_valid()` tiene que aceptar las zonas de la v3 solo con la bandera de cruce, como ya separa la v1 de la v2.
- `--autoplay-zone=` nuevas por zona y una vuelta entera de la v3, como `caravana` para la v2.
- La pantalla del más allá (`BeyondScreen`) deja de ser el final y pasa a ser la entrada a Brumaclara, o se cambia por la primera escena de la v3.

## Decisiones abiertas

1. **Nombres:** Brumaclara, Orvalla, Neblí, Albor y los jefes valen o se cambian.
2. **El final:** dos finales con la elección, o uno solo (liberar a Albor) para que sea más barato.
3. **La vuelta a Villaclaro:** una visita corta con escena, o una misión con algo de juego (buscar el amuleto, que la Abuela Rosa lo haya escondido).
4. **La niebla espesa:** se hace, o las Ruinas se quedan como mapa normal.
5. **El nivel máximo:** 50, o se para en 45 para que la v3 sea más corta.
6. **Partida nueva +:** si la v3 entra en ella o, como la v2, se queda fuera.
