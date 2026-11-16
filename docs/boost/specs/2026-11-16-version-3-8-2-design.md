# Versión 3.8.2: los arreglos de las dos pasadas de QA

Fecha: 2026-11-16. Estado: spec. Cubre de M-111 a M-120 del [documento maestro](../documento-maestro.md). Va después de la 3.8.1. Arregla lo que encontraron las dos pasadas de QA sobre la 3.8.0 (QA1: reglas y datos; QA2: historia, guardados, interfaz y textos). La partida guardada sigue en la **versión 16**: no gana ni pierde campos.

## Objetivo

1. **Todas las tierras se reabren al acabar (M-111).** Durante el juego el viaje sigue siendo solo hacia delante, sin aviso antes de los jefes. Cuando acabas la v3, las tierras de las tres partes vuelven a abrirse, para ir a donde te quedó algo por hacer. Un portal del Ala hacia una tierra que se cierra se cierra con ella.
2. **Misiones de tierras cerradas (M-112).** Las misiones de la Caravana dejan de ofrecerse cuando su tierra se cierra, como las de Brumaclara. Una misión tomada que ya no se puede cumplir deja de ocupar las líneas de misión y el Diario la apunta como perdida.
3. **La pregunta final no se contesta sola (M-113).** En «El Amuleto del Alba brilla en tu mano. ¿Qué haces?», Esc y tocar fuera ya no eligen «Acabar con el Eco».
4. **Partidas muy antiguas (M-114).** Las partidas guardadas con la 1.0 y anteriores (versiones de guardado 2 a 8) vuelven a cargar.
5. **Ranuras que no se pierden sin preguntar (M-115).** Una partida de una versión más nueva lo dice, y el juego pregunta antes de borrar o sustituir cualquier ranura que tenga un archivo, también una dañada.
6. **Guardado más seguro (M-116).** Un corte en mitad del guardado ya no deja la ranura rota, y un archivo editado a mano con números enormes o datos raros ya no rompe la partida.
7. **«Estado» con textos grandes en el móvil (M-117).** La página se desplaza y «Volver» siempre se ve.
8. **«Salir» empieza en «No» (M-118).**
9. **Los objetos clave, con su texto (M-119).** El Diario enseña qué llevas: la Lámpara del faro, el Sello de Albor, las cartas…
10. **Textos (M-120).** Cifras «n/m», «Objetivo:» también en la misión del pueblo, teclas en castellano, la pregunta de partir con la caravana, avisos de tablón sin mayúsculas y Kenney en los créditos de la parte 1.

## Decisiones tomadas (2026-11-16)

Las tres primeras las tomó el usuario; la primera la cambió el mismo día, con la spec ya en marcha. Las demás siguen sus preferencias de siempre (la opción recomendada, sin preguntar).

| Tema | Decisión |
|---|---|
| Tierras que se cierran tras su jefe (QA1-03) | Cambio del usuario (2026-11-16): no sale ningún aviso antes del jefe. Durante el juego el viaje sigue siendo solo hacia delante, como hasta ahora. Cuando acabas la v3 (el final de Albor, liberado o vencido), todas las tierras de las tres partes vuelven a abrirse, para ir a donde te quedó algo por hacer |
| Qué se reabre tras el final | Las salidas que se cerraron, cada una con su arco: en la pradera, la del bosque (y con él la mina y el castillo); en la Caravana, las cuatro tierras y Villaclaro; en Brumaclara, la Ciénaga, las Cuevas y las Ruinas. Además, la partida se puede guardar en cualquier zona, ninguna tierra cuenta como cerrada, ninguna misión queda perdida y se vuelven a ofrecer todas las que no tomaste, de las tres partes |
| Cuándo cuenta como acabada la v3 | Con el flag del final (`albor_liberado` o `albor_vencido`), que pone la escena final antes de los créditos. Todas las reglas que se reabren leen flags; `story.finished_v3` llega un instante después, antes de cualquier guardado |
| Misiones de la v1 tras el final | También se vuelven a ofrecer. Sus tierras están abiertas otra vez, y si no, la cuenta «Misiones de Villaclaro» del Diario se quedaría a medias para siempre. Sus premios son de la v1, pequeños para un héroe de nivel 53 o más: sirven para completar, no para subir |
| Dónde salen los arcos | Cada uno en su sitio, alrededor del pueblo, con su entrada delante para volver. En la Caravana, las cuatro tierras entre las tiendas: la jungla al noroeste, el desierto al suroeste, la montaña al sureste y la ciudad al sur (el portal sigue al norte y Villaclaro al este). En Brumaclara, la Ciénaga y las Ruinas al oeste y las Cuevas al este (la Fuente sigue al norte y el portal al sur). En la pradera, el bosque al norte, como en la v1, y la Caravana al sur, al final del camino. Los escombros y columnas que la Caravana pone a mano y que pisarían los caminos nuevos se quitan. La niebla de la pradera se va con el final, como la de la Caravana |
| Lo que se queda de la primera idea | Nada del aviso. Se queda `ClosingLands` (qué tierras se cierran, para las misiones perdidas), el portal del Ala que se cierra con su tierra y el que se quita al cargar una partida antigua: sin eso, la ranura de la ciudad sale «Partida dañada» |
| Un héroe de nivel alto en tierras viejas | Las reglas no cambian. Los grupos tímidos se apartan, pero no salen de su zona y se pueden alcanzar (los quietos ni se mueven), así que se pueden completar las familias del bestiario. Los jefes vencidos siguen vencidos. Cada figura dice la frase de su último capítulo |
| Figuras que quedarían raras | La Abuela Rosa, el Granjero y el Tablón de Villaclaro ganan una frase para después del final: la de la visita del amuleto ya no encaja. El Jefe de caravana y el compañero de la escena del cruce, en la ciudad, se van al empezar la v3; si no, el compañero saldría dos veces |
| La Domadora con compañero | Ya no vende una criatura si viajas con un compañero: «Ya tienes compañero». Hasta ahora la vendía en la Villaclaro de la parte 3, y una partida de la parte 2 o 3 con criatura sale «Partida dañada». Con las tierras de la v1 abiertas habría cuatro Domadoras, no una |
| Comprobación del piloto | Sin carrera nueva: la v3 del piloto acaba en sus créditos. Un script de comprobación, fuera del repositorio, mira una partida acabada: salidas, zonas válidas, misiones, portal, Domadora. Otro recorre los arcos nuevos con cada pueblo construido solo, y saca sus fotogramas. Las carreras `vencer` y `v3` construyen Brumaclara ya abierta |
| La pregunta final de la v3 (QA2-06) | En esa pregunta Esc y tocar fuera no hacen nada: hay que elegir una de las dos respuestas |
| Foco de «Salir» (QA2-04) | En «No», como pide la guía de voz: lo seguro por defecto |
| Misiones que ya no se pueden cumplir (QA2-02, QA1-01, QA1-02) | Las 8 de la Caravana ganan su flag `gone`: el jefe de su tierra. Una misión tomada que ya no se puede cumplir (de una parte anterior, o de una tierra cerrada sin estar lista para entregar) se marca como **perdida**, no se esconde: sale de las líneas de misión y de «En curso», y el Diario la lista en «Perdidas». Así el Diario dice la verdad. Es una cuenta, no un dato: no se guarda y la partida sigue en la versión 16. Hasta el final de la v3: después ninguna está perdida y todas se pueden acabar |
| Partidas de las versiones 2 a 8 (QA2-01) | Vuelven a cargar: el fallo era una sola lectura de un campo que esas partidas no tienen |
| «Estado» con textos grandes (QA2-03) | Toda la página va dentro de una lista que se desplaza, como el Diario; «Volver» queda fuera, siempre a la vista |
| Ranuras (QA2-05) | La lista dice «Partida de una versión más nueva» en vez de «Partida dañada» cuando es eso. «Nueva partida» e «Importar» preguntan, con el foco en «No», antes de tocar cualquier ranura que tenga un archivo, también una dañada o más nueva |
| Formato de cifras (QA2-07) | «lobos 0/5» en las líneas de misión y «(0/5)» en el Diario, sin espacios |
| La misión del pueblo (QA2-08) | Sus líneas dicen «Objetivo:», como todos los objetivos del juego |
| Teclas (QA2-09) | Los signos se ven como el signo («.», «,», «-»…) y el resto con nombre en castellano («Num 0», «Bloq Num», «Impr Pant»…) |
| La pregunta de partir (QA2-10) | «Villaclaro quedará muy lejos: no volverás al bosque, la mina ni el castillo hasta que termines el viaje. Las misiones que dejes a medias quedarán pendientes hasta entonces.» |
| Los objetos clave (QA2-11) | En el Diario, en una sección «Objetos clave» con el nombre y el texto de cada uno (y las medallas pequeñas). No en «Objetos»: esa página solo enseña lo que se puede usar (lo decidió el usuario en la 2.x, y la guía de QA lo pide en T-067); el propio código ya decía que el Diario los sigue |
| Mayúsculas (QA2-12) | «Aviso:», «Se busca:», «Se buscan:» |
| Números de un archivo editado a mano (QA2-13) | Se hace, porque es barato: al cargar, cada número se queda entre 0 y 9 999 999. Un mapa explorado que no es base64 deja la partida como dañada (sin el error en la consola). Un portal del Ala de viaje que lleva a otra parte o a una tierra cerrada (antes del final de la v3) se quita al cargar. No se hace lo del nombre con un salto de línea: el teclado del juego no lo puede escribir y no rompe nada |
| Créditos (QA2-14) | «Nature Kit, de Kenney (CC0)» también en los de la parte 1 |
| Guardado (QA2-15) | En el PC se escribe en `save_n.json.tmp` y se renombra encima. En la web se sigue escribiendo directamente: allí la partida está en IndexedDB y se guarda al cerrar el archivo, no al renombrarlo |

## Lo que dijo la QA, comprobado en el código

Cada hallazgo se ha mirado en `develop` (3.8.1). Ninguno era falso. Dos se juntan con otros y uno se hace solo en parte.

| Hallazgo | Comprobado | Va en |
|---|---|---|
| QA1-01 Las misiones de la Caravana se ofrecen con su tierra cerrada | Sí: las 8 no tienen `gone` | M-112 |
| QA1-02 Misiones de partes cerradas en las líneas de misión | Sí: es el mismo fallo que QA2-02 | M-112 |
| QA1-03 Tierras que se cierran sin avisar | Sí. Se resuelve de otra forma: sin aviso, y las tierras se reabren al acabar | M-111 |
| QA2-01 Guardados 2 a 8 rechazados | Sí: `save_data.gd` lee `data.ally`, que esas partidas no tienen | M-114 |
| QA2-02 Misiones imposibles «En curso» para siempre | Sí | M-112 |
| QA2-03 «Estado» se sale de la pantalla | Sí: es la única página larga sin lista que se desplaza | M-117 |
| QA2-04 «Salir» con el foco en «Sí, salir» | Sí | M-118 |
| QA2-05 Más nueva = «dañada», y se sobrescribe sin preguntar | Sí | M-115 |
| QA2-06 Esc elige el final | Sí | M-113 |
| QA2-07 «n / m» | Sí: 12 misiones, el Diario y la misión del pueblo | M-120 |
| QA2-08 «Misión:» en el objetivo del pueblo | Sí | M-120 |
| QA2-09 Teclas en inglés | Sí | M-120 |
| QA2-10 «No podrás volver a Villaclaro» | Sí: en la parte 3 se vuelve a por el amuleto | M-120 |
| QA2-11 Textos de objetos clave sin usar | Sí | M-119 |
| QA2-12 Avisos en mayúsculas | Sí: 8 misiones | M-120 |
| QA2-13 Números enormes y datos raros | Sí; se hace todo salvo el nombre con salto de línea | M-116 |
| QA2-14 Kenney en los créditos de la parte 1 | Sí: la parte 1 usa la olla, flores y setas de Kenney | M-120 |
| QA2-15 Guardado sobre el mismo archivo | Sí | M-116 |

Al comprobarlos ha salido un fallo más, del mismo tema que QA1-03: un portal del Ala de viaje abierto en una tierra antes de vencer a su jefe se queda abierto cuando la tierra se cierra. Si es la ciudad, en la parte 3 el portal de la Caravana lleva a una zona de la parte 2, el juego guarda allí al llegar y la ranura sale «Partida dañada» al volver a abrirla. Se arregla en M-111: el portal se cierra con su tierra, y uno así guardado se quita al cargar.

## 1. Todas las tierras se reabren al acabar (M-111)

### Lo que ve el jugador

- **Durante el juego**, nada cambia. Al vencer al jefe de una tierra de la v2 o de la v3, esa tierra se cierra, como hasta ahora. No hay pregunta antes del combate.
- **Al acabar la v3** (tras la pregunta del amuleto, con cualquiera de los dos finales), todas las tierras de las tres partes vuelven a abrirse. Se nota al llegar a Brumaclara en fiesta:
  - **Brumaclara:** vuelven los arcos de la Ciénaga y de las Ruinas, al oeste, y el de las Cuevas, al este. La Fuente sigue al norte y el portal al sur.
  - **La Caravana:** vuelven los arcos de la jungla (noroeste), el desierto (suroeste), la montaña (sureste) y la ciudad (sur), y el de Villaclaro, al este. El portal sigue al norte.
  - **La pradera de Villaclaro:** vuelve el camino del bosque, al norte, y por él la mina y el castillo. El de la Caravana pasa al sur, al final del camino, y la niebla de sus caminos se ha ido.
  - Cada arco lleva a su tierra, y al volver de ella apareces delante de él.
- Lo que te dejaste se puede hacer:
  - los cofres y las bestias de cualquier tierra;
  - las misiones tomadas que estaban perdidas: dejan «Perdidas», vuelven a las líneas de misión y se entregan a quien las pidió;
  - las que nunca tomaste, de las tres partes, se ofrecen otra vez, con su «!».
- Los jefes vencidos siguen vencidos. Los monstruos de las tierras viejas se apartan del héroe, como siempre con un nivel alto, pero se les puede alcanzar.
- La partida se puede guardar en cualquier zona y se vuelve a abrir sana.
- Un portal del Ala que lleva a una tierra que se acaba de cerrar se cierra con ella. Tras el final, un portal abierto en cualquier tierra se queda.

### Lo que cambia además

- **Frases.** En Villaclaro, la Abuela Rosa, el Granjero y el Tablón tienen una frase para después del final; la de la visita del amuleto ya no encaja:
  - Abuela Rosa: «Dicen que al otro lado ya no hay niebla, y aquí se fue la misma noche. Algo habrás tenido que ver, {nombre}.» y «Los caminos vuelven a estar limpios. Ve a donde quieras, pero vuelve a cenar.».
  - Granjero: «La niebla se ha ido otra vez. Las gallinas vuelven a poner los huevos derechos.» y «Esta vez les he dicho que no se acostumbren.».
  - Tablón: «Aviso nuevo: «Los caminos vuelven a estar limpios. Ya se puede salir al bosque, y más allá.» — La Abuela Rosa», como su aviso de la parte 3.
- **La ciudad.** El Jefe de caravana y el compañero de la escena del cruce, en la segunda planta de la ciudad, se van al empezar la v3.
- **La Domadora.** Con un compañero no vende su criatura: «Ya tienes compañero». Una partida de la parte 2 o 3 solo lleva un compañero, y con una criatura salía «Partida dañada».

### Cómo funciona

- **Cuándo.** `StoryState.world_open(flags)`: en la parte 3, con `albor_liberado` o `albor_vencido`. Es una cuenta de los flags, no un dato nuevo: la partida sigue en la versión 16.
- **Qué tierras se cierran** sigue saliendo de los datos (`ClosingLands`): las siete de la Caravana y Brumaclara. `ClosingLands.is_closed()` es falso tras el final. `ClosingLands` ya no tiene aviso, ni cuenta lo que falta.
- **Las salidas.** Los datos de las zonas no cambian. `CampLook`, `BrumaclaraLook` y `VillaclaroLook`, con el mundo abierto, quitan el `gone` de cada salida y dan a las que se reabren su sitio y su entrada (`ZoneData.reopen_exits()`). `ZoneTravel` les dice si el mundo está abierto.
- **La partida.** `ZoneData.open_zones(flags)` son las zonas de la parte o, tras el final, todas. Las usan `SaveData._valid_caravan()` (zona y último pueblo) y el portal al cargar.
- **Las misiones.** `QuestLog.is_lost()` es falso tras el final. `QuestLog._offered()` ofrece, tras el final, cualquier misión sin tomar con su `needs` puesto, de cualquier parte y sin mirar su `gone`.
- **El portal** se cierra con su tierra en `GameState.on_boss_defeated()`, y `SaveData.apply()` quita el de una partida antigua, como antes.
- **El combate del jefe** empieza como en la 3.8.1. `BattleFlow` ya no pregunta.
- **Piloto automático.** No cambia: ya no hay pregunta ante los jefes, y la v3 acaba en sus créditos, sin andar por el mundo abierto.

## 2. Misiones de tierras cerradas (M-112)

### Lo que cambia

- **Las 8 misiones de la Caravana** ganan su flag `gone`, el jefe de su tierra:
  - Jaguar sombrío: «La exploradora perdida» y «Pieles para el frío».
  - Gusano de las dunas: «Escorpiones en las dunas» y «La cantimplora del Jefe».
  - Grifo de la cumbre: «Cabras en la subida» y «Cristales de hielo».
  - Devorador del portal: «Los centinelas de la ciudad» y «El superviviente».

  Tras ese jefe ya no se ofrecen, como las de Brumaclara. Tras el final de la v3 se vuelven a ofrecer, como todas (§1).
- **Una misión perdida** es una tomada que ya no se puede cumplir:
  - es de una parte anterior: la v1 en la Caravana, o la v1 y la v2 en Brumaclara;
  - o su flag `gone` es el jefe de una tierra que ya se ha cerrado y no estaba lista para entregar. Una lista para entregar se sigue entregando en el pueblo, que no se cierra.
  - Tras el final de la v3 ninguna está perdida: todas las tierras se reabren (§1).
- Una misión perdida:
  - no sale en las líneas de misión (mapa y pausa);
  - no sale en «En curso» del Diario: sale en una sección nueva, «Perdidas», con sus títulos;
  - quien la pidió deja de repetir sus frases de espera.
- Lo que no cambia: las cuentas de «Misiones de …» del Diario y de los créditos (no estaba cumplida) y la partida guardada (nada se guarda: se calcula).
- Las misiones que vigila un jefe que no cierra tierra (las del Eco de Albor) no se pierden: la Fuente sigue abierta.
- Un efecto pequeño: hasta hoy, quien juntaba 4 pieles de mono sin leer el tablón podía tomar «Pieles para el frío» después del Jaguar y entregarla en el acto. Ya no se puede, como pasa con las de Brumaclara.

## 3. La pregunta final (M-113)

- En la pregunta «El Amuleto del Alba brilla en tu mano. ¿Qué haces?», Esc y tocar fuera de la ventana no hacen nada. El foco empieza en «Devolver el amuleto», como hoy, y hay que pulsar una de las dos.
- `ChoiceWindow.ask()` y `World.ask()` aceptan que una pregunta no se pueda cancelar. Las demás preguntas no cambian: Esc y tocar fuera siguen eligiendo la última opción.
- El piloto automático no cambia (no abre la ventana).

## 4. Partidas de las versiones 2 a 8 (M-114)

- `SaveData` lee el compañero con `data.get("ally", "")` en la comprobación de las partes. Las partidas de la 1.0 y anteriores vuelven a salir en su ranura y a cargar migradas, sin el `SCRIPT ERROR` en la consola.

## 5. Ranuras (M-115)

- En la lista de ranuras, una partida de una versión de guardado más nueva que la del juego dice «Partida de una versión más nueva». Sigue sin poder continuarse.
- **«Nueva partida»** sobre una ranura con un archivo que no se puede abrir (dañada o más nueva) pregunta, con el foco en «No»: «El archivo de la ranura n se borrará. ¿Empezar una nueva?» y «Sí, empezar de nuevo». Sobre una que funciona, la pregunta de hoy.
- **«Importar»** sobre una ranura así pregunta «El archivo de la ranura n se sustituirá por el que has elegido. ¿Seguir?» y «Sí, sustituir». Sobre una que funciona, la pregunta de hoy.
- Sobre una ranura vacía no se pregunta nada, como hoy.

## 6. Guardado más seguro (M-116)

- **Escritura.** En el PC, el guardado y las opciones se escriben en `<archivo>.tmp`, se cierra y se renombra encima del archivo. Un corte a mitad deja el archivo anterior entero.
  - Donde renombrar encima no sea un solo paso (en Windows Godot puede borrar el destino antes de mover el nuevo), un corte justo entre los dos deja solo el `.tmp`, ya completo. El título lo recupera al arrancar: un `.tmp` sin su archivo pasa a ser el archivo.
  - Un `.tmp` junto a su archivo es un corte de antes de renombrar: se deja y el siguiente guardado lo pisa.
- **En la web** se escribe directamente, como hoy. IndexedDB guarda el archivo al cerrarlo, no al renombrarlo.
- El piloto automático sigue con su propio archivo y nunca recupera ni toca las ranuras.
- **Números de un archivo editado a mano.** Al cargar, se quedan entre 0 y 9 999 999: el oro, cada objeto, las estadísticas del héroe, la EXP, las cuentas de las misiones, los pozos, los PV del Slime de Metal y los números de los créditos. El tiempo de juego también tiene ese tope, en segundos.
- **Mapa explorado.** Uno que no es base64 válido deja la partida «dañada», sin el `ERROR` de la consola.
- **Portal.** Uno que lleva a una zona de otra parte o a una tierra cerrada se quita al cargar (§1).

## 7. «Estado» con textos grandes (M-117)

- La página «Estado» pasa a ser su propia pieza de UI, `StatusPage`. Muestra:
  - a la izquierda, las barras, ATK · DEF · VEL, el oro y el compañero o la criatura;
  - a la derecha, los hechizos.
- El menú de pausa la mete en una `ScrollBox`, igual que el Diario. Con textos grandes a 740 × 360 la página se desplaza (con las flechas, la rueda o el dedo) y «Volver» queda debajo, siempre visible.
- En escritorio y sin textos grandes se ve igual que hoy.
- Así `pause_menu.gd` adelgaza, y caben los otros cambios del menú.

## 8. «Salir» empieza en «No» (M-118)

- Al abrir la página «Salir» del menú de pausa, el foco está en «No». El orden de los botones no cambia: «Sí, salir» y debajo «No».

## 9. Los objetos clave en el Diario (M-119)

- El Diario gana una sección «Objetos clave», entre «Perdidas» (o «Cumplidas») y «Colección», con cada objeto clave que llevas, en el orden en que los conseguiste: su nombre y debajo su texto en letra pequeña («Lámpara del faro» / «La guardaba la Garza de légamo en el buche…»).
- Si llevas medallas pequeñas, al final: «Medalla pequeña ×n» y su texto.
- Sin objetos clave ni medallas, la sección no sale.
- «Objetos» no cambia: solo lo que se puede usar.

## 10. Textos (M-120)

- **Cifras:** «Misión: lobos 0/5» (12 misiones) y en el Diario «… (0/5).».
- **La misión del pueblo** se lee como los demás objetivos:
  - «Objetivo: habla con la Abuela Rosa»;
  - «Objetivo: vence a los slimes (0/3)»;
  - «Objetivo: vuelve con la Abuela Rosa»;
  - «Objetivo: derrota al Rey Slime».

  En el Diario: «Vence a los slimes (0/3).». Las dos líneas de `StoryState.GOALS` del prólogo y la pradera se quedan, aunque no se vean: la tabla de objetivos va por capítulos.
- **Teclas** («Opciones» → «Teclas», solo en escritorio):
  - los signos se ven como el propio signo: `.` `,` `/` `\` `;` `'` `` ` `` `-` `=` `+` `*` `<` `>` `[` `]` `#` `§`;
  - el teclado numérico, «Num 0» a «Num 9», «Num +», «Num -», «Num *», «Num /» y «Num .»;
  - el resto: «Bloq Num», «Bloq Despl», «Impr Pant», «Pausa», «Menú» y «Windows».
- **La pregunta de partir con la caravana:** «Villaclaro quedará muy lejos: no volverás al bosque, la mina ni el castillo hasta que termines el viaje. Las misiones que dejes a medias quedarán pendientes hasta entonces.».
- **Tablones:** «Aviso: las cabras montesas…», «Se busca: quien despida…», «Se buscan: esquirlas de geoda…» (8 misiones).
- **Créditos de la parte 1:** «Modelos 3D»: «KayKit, de Kay Lousberg (CC0)» y «Nature Kit, de Kenney (CC0)».

## Verificación

- `--check-only` en cada script cambiado, `--import` tras las clases nuevas (`ClosingLands`, `StatusPage`), `gen_ui_tokens.gd -- --check` y `check_ui_values.gd`. Ninguna orden usa la carpeta de datos real.
- Scripts de comprobación fuera del repositorio (nunca en él):
  - una partida de las versiones 2 a 8 carga;
  - números enormes recortados y base64 malo rechazado sin `ERROR`;
  - un portal de otra parte se quita;
  - guardar dos veces deja el archivo bueno y ningún `.tmp`;
  - un `.tmp` sin su archivo se recupera;
  - las siete tierras de `ClosingLands` con sus zonas, y una partida acabada: tierras abiertas, salidas y entradas de la Caravana, Brumaclara y la pradera, partidas en zonas de la v1 y la v2, el portal, las misiones y la Domadora;
  - los arcos nuevos, recorridos uno a uno con su pueblo construido solo, con un fotograma de cada uno;
  - las misiones perdidas en las líneas y el Diario;
  - la pregunta final no se cierra con Esc ni tocando fuera.
- Fotogramas:
  - «Estado» con textos grandes a 740 × 360 (`--touch`), con el héroe de `albor` (Nv 52, cinco hechizos, Brena);
  - la página «Salir» con el foco en «No»;
  - el Diario con «Perdidas» y «Objetos clave»;
  - cada arco que se reabre en la Caravana, Brumaclara y la pradera;
  - la lista de ranuras con una partida de la versión 17.
- Todas las carreras del piloto automático con `scripts/tools/autoplay_all.sh`, en OK:
  - ninguna imprime `Pregunta: Al vencerlo`; `v3` y `vencer` construyen Brumaclara abierta sin `WARNING`;
  - nada más cambia en el equilibrio, así que `autoplay_expected.json` no se toca salvo que una carrera se salga de su margen.
- Queda para el usuario:
  - acabar una partida real y andar por los arcos que se reabren, ida y vuelta; guardar y cargar en una tierra de la v1 tras el final;
  - la pregunta final con el dedo en un móvil;
  - una partida de la 1.0 real, si la conserva;
  - el guardado en la web (Chrome y el móvil) tras el cambio de escritura.
- La guía de QA (`docs/brief-qa-agentes.md`), CLAUDE.md, la skill del piloto, el CHANGELOG y el documento maestro, al día.
