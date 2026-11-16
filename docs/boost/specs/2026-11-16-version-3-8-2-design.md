# Versión 3.8.2: los arreglos de las dos pasadas de QA

Fecha: 2026-11-16. Estado: spec. Cubre de M-111 a M-120 del [documento maestro](../documento-maestro.md). Va después de la 3.8.1. Arregla lo que encontraron las dos pasadas de QA sobre la 3.8.0 (QA1: reglas y datos; QA2: historia, guardados, interfaz y textos). La partida guardada sigue en la **versión 16**: no gana ni pierde campos.

## Objetivo

1. **Aviso antes del jefe de una tierra que se cierra (M-111).** Si al vencer a un jefe su tierra se va a cerrar para siempre y aún te queda algo en ella (cofres, bestias o misiones), el juego te avisa antes del combate y te deja volver.
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

Las dos primeras las tomó el usuario. Las demás siguen sus preferencias de siempre (la opción recomendada, sin preguntar).

| Tema | Decisión |
|---|---|
| Tierras que se cierran tras su jefe (QA1-03) | Antes del combate con el jefe sale un aviso, solo si de esa tierra aún falta algo: «Al vencerlo, esta tierra se cerrará. Te faltan: 2 cofres, 1 bestia.». Se elige entre luchar ahora o volver; el foco empieza en «Volver», y Esc y tocar fuera también eligen volver. El viaje sigue siendo solo hacia delante. Solo en las tierras que de verdad se cierran: los tramos de la v2 (jungla, desierto, montaña, ciudad) y las etapas de la v3 (Ciénaga, Cuevas, Ruinas); no en la v1 ni en la Fuente. El piloto automático contesta «Luchar ahora» (ver §1) |
| La pregunta final de la v3 (QA2-06) | En esa pregunta Esc y tocar fuera no hacen nada: hay que elegir una de las dos respuestas |
| Qué falta en el aviso | Cofres sin abrir, bestias del bestiario sin vencer que solo viven ahí y misiones tomadas que quedarían perdidas. Solo lo que no se recupera después |
| Foco de «Salir» (QA2-04) | En «No», como pide la guía de voz: lo seguro por defecto |
| Misiones que ya no se pueden cumplir (QA2-02, QA1-01, QA1-02) | Las 8 de la Caravana ganan su flag `gone`: el jefe de su tierra. Una misión tomada que ya no se puede cumplir (de una parte anterior, o de una tierra cerrada sin estar lista para entregar) se marca como **perdida**, no se esconde: sale de las líneas de misión y de «En curso», y el Diario la lista en «Perdidas». Así el Diario dice la verdad. Es una cuenta, no un dato: no se guarda y la partida sigue en la versión 16 |
| Partidas de las versiones 2 a 8 (QA2-01) | Vuelven a cargar: el fallo era una sola lectura de un campo que esas partidas no tienen |
| «Estado» con textos grandes (QA2-03) | Toda la página va dentro de una lista que se desplaza, como el Diario; «Volver» queda fuera, siempre a la vista |
| Ranuras (QA2-05) | La lista dice «Partida de una versión más nueva» en vez de «Partida dañada» cuando es eso. «Nueva partida» e «Importar» preguntan, con el foco en «No», antes de tocar cualquier ranura que tenga un archivo, también una dañada o más nueva |
| Formato de cifras (QA2-07) | «lobos 0/5» en las líneas de misión y «(0/5)» en el Diario, sin espacios |
| La misión del pueblo (QA2-08) | Sus líneas dicen «Objetivo:», como todos los objetivos del juego |
| Teclas (QA2-09) | Los signos se ven como el signo («.», «,», «-»…) y el resto con nombre en castellano («Num 0», «Bloq Num», «Impr Pant»…) |
| La pregunta de partir (QA2-10) | «Villaclaro quedará muy lejos, y no podrás volver al bosque, la mina ni el castillo. Las misiones que no hayas cumplido se perderán.» |
| Los objetos clave (QA2-11) | En el Diario, en una sección «Objetos clave» con el nombre y el texto de cada uno (y las medallas pequeñas). No en «Objetos»: esa página solo enseña lo que se puede usar (lo decidió el usuario en la 2.x, y la guía de QA lo pide en T-067); el propio código ya decía que el Diario los sigue |
| Mayúsculas (QA2-12) | «Aviso:», «Se busca:», «Se buscan:» |
| Números de un archivo editado a mano (QA2-13) | Se hace, porque es barato: al cargar, cada número se queda entre 0 y 9 999 999. Un mapa explorado que no es base64 deja la partida como dañada (sin el error en la consola). Un portal del Ala de viaje que lleva a otra parte o a una tierra cerrada se quita al cargar. No se hace lo del nombre con un salto de línea: el teclado del juego no lo puede escribir y no rompe nada |
| Créditos (QA2-14) | «Nature Kit, de Kenney (CC0)» también en los de la parte 1 |
| Guardado (QA2-15) | En el PC se escribe en `save_n.json.tmp` y se renombra encima. En la web se sigue escribiendo directamente: allí la partida está en IndexedDB y se guarda al cerrar el archivo, no al renombrarlo |

## Lo que dijo la QA, comprobado en el código

Cada hallazgo se ha mirado en `develop` (3.8.1). Ninguno era falso. Dos se juntan con otros y uno se hace solo en parte.

| Hallazgo | Comprobado | Va en |
|---|---|---|
| QA1-01 Las misiones de la Caravana se ofrecen con su tierra cerrada | Sí: las 8 no tienen `gone` | M-112 |
| QA1-02 Misiones de partes cerradas en las líneas de misión | Sí: es el mismo fallo que QA2-02 | M-112 |
| QA1-03 Tierras que se cierran sin avisar | Sí | M-111 |
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

## 1. Aviso antes del jefe (M-111)

### Lo que ve el jugador

- Al tocar a un jefe cuya tierra se cierra tras él, si en esa tierra falta algo, sale una pregunta sobre el mapa antes del combate:
  - «Al vencerlo, esta tierra se cerrará. Te faltan: 2 cofres, 1 bestia, 1 misión.»
  - Con una sola cosa: «Te falta: 1 cofre.».
  - Solo aparece lo que falta, en este orden: cofres, bestias, misiones.
- Respuestas: «Luchar ahora» y «Volver». El foco empieza en «Volver»; Esc y tocar fuera eligen «Volver».
- **«Luchar ahora»:** empieza el combate de siempre.
- **«Volver»:** el mapa sigue, y el jefe no vuelve a preguntar hasta que el héroe se aleja de él y vuelve a tocarlo, igual que tras huir de un grupo.
- Si de la tierra no falta nada, no hay pregunta: el combate empieza como hoy.
- Tierras con aviso: la jungla (Jaguar sombrío), el desierto (Gusano de las dunas), la montaña (Grifo de la cumbre), la ciudad (Devorador del portal), la Ciénaga (Garza de légamo), las Cuevas (Coloso de cuarzo) y las Ruinas (Vigía de la bruma). Sin aviso: los jefes de la v1, el Guardián de la ciudad (la ciudad aún sigue abierta tras él), el Eco de Albor (la Fuente no se cierra) y el Eco de la Niebla.
- Un portal del Ala de viaje que lleva a una tierra que se acaba de cerrar se cierra con ella.

### Qué cuenta como «falta»

- **Cofres:** los de las zonas de esa tierra que siguen cerrados.
- **Bestias:** los enemigos con ficha en el bestiario que viven en las zonas de esa tierra (en sus grupos, el raro o el otro jefe de la tierra) y que no has vencido nunca. No cuenta el jefe al que vas a vencer, ni un enemigo que también vive en otra zona de la parte, porque ahí aún se puede vencer.
- **Misiones:** las tomadas que quedarían perdidas (§2): su flag `gone` es ese jefe y aún no están listas para entregar.

### Cómo funciona

- **Qué tierras se cierran** sale de los datos, no de una lista escrita a mano. Una salida de un pueblo con `gone` igual a un jefe lleva a una tierra. La tierra son la zona de esa salida y todas a las que se llega desde ella, por salidas y escaleras, sin volver por el pueblo. Hoy salen siete tierras: las cuatro de la Caravana y las tres de Brumaclara.
- Es una regla pura nueva, `ClosingLands`: las zonas de cada tierra, lo que falta y el texto de la pregunta.
- `BattleFlow` pregunta al empezar el combate de un jefe, con `World.ask()`. Con «Volver» devuelve el mapa como estaba.
- `GameState.on_boss_defeated()` cierra el portal del Ala si lleva a una tierra cerrada. `SaveData` lo quita al cargar una partida antigua que lo tenga.
- **Piloto automático:** sí se le pregunta. `World.ask()` en el piloto no abre ventana: imprime `Pregunta: <texto> -> Luchar ahora` y elige la primera respuesta. Por eso «Luchar ahora» va primera y «Volver» última. Así el piloto sigue igual y cada registro dice qué se dejó atrás en cada tierra.

## 2. Misiones de tierras cerradas (M-112)

### Lo que cambia

- **Las 8 misiones de la Caravana** ganan su flag `gone`, el jefe de su tierra:
  - Jaguar sombrío: «La exploradora perdida» y «Pieles para el frío».
  - Gusano de las dunas: «Escorpiones en las dunas» y «La cantimplora del Jefe».
  - Grifo de la cumbre: «Cabras en la subida» y «Cristales de hielo».
  - Devorador del portal: «Los centinelas de la ciudad» y «El superviviente».

  Tras ese jefe ya no se ofrecen, como las de Brumaclara.
- **Una misión perdida** es una tomada que ya no se puede cumplir:
  - es de una parte anterior: la v1 en la Caravana, o la v1 y la v2 en Brumaclara;
  - o su flag `gone` es el jefe de una tierra que ya se ha cerrado y no estaba lista para entregar. Una lista para entregar se sigue entregando en el pueblo, que no se cierra.
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
- **La pregunta de partir con la caravana:** «Villaclaro quedará muy lejos, y no podrás volver al bosque, la mina ni el castillo. Las misiones que no hayas cumplido se perderán.».
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
  - las siete tierras de `ClosingLands` con sus zonas, y el texto del aviso con y sin cosas pendientes;
  - las misiones perdidas en las líneas y el Diario;
  - la pregunta final no se cierra con Esc ni tocando fuera.
- Fotogramas:
  - «Estado» con textos grandes a 740 × 360 (`--touch`), con el héroe de `albor` (Nv 52, cinco hechizos, Brena);
  - la página «Salir» con el foco en «No»;
  - el Diario con «Perdidas» y «Objetos clave»;
  - el aviso del jefe a 1280 × 720 y a 740 × 360;
  - la lista de ranuras con una partida de la versión 17.
- Todas las carreras del piloto automático con `scripts/tools/autoplay_all.sh`, en OK:
  - cada jefe de una tierra que se cierra imprime su `Pregunta: Al vencerlo… -> Luchar ahora` si dejó algo atrás;
  - nada más cambia en el equilibrio, así que `autoplay_expected.json` no se toca salvo que una carrera se salga de su margen.
- Queda para el usuario:
  - elegir «Volver» ante un jefe y alejarse;
  - la pregunta final con el dedo en un móvil;
  - una partida de la 1.0 real, si la conserva;
  - el guardado en la web (Chrome y el móvil) tras el cambio de escritura.
- La guía de QA (`docs/brief-qa-agentes.md`), CLAUDE.md, la skill del piloto, el CHANGELOG y el documento maestro, al día.
