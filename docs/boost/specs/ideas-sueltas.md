# Ideas sueltas

Ideas que se le van ocurriendo al usuario mientras juega. No están decididas ni planificadas. Cuando una se trabaje, pasa a su propio diseño y se marca aquí con el enlace.

Formato: una sección por idea, con la fecha, la idea en palabras del usuario y notas, si hacen falta.

---

## Controlar el combate con WASD

- **Fecha:** 2026-11-03
- **Idea:** poder usar WASD también dentro del combate para elegir qué hacer: atacar, usar una habilidad, etc.
- **Notas:**
  - Ahora el menú de combate se maneja con las flechas arriba y abajo, Enter o Espacio, o con clic.
  - W y S moverían el cursor del menú igual que las flechas.
  - Con varios enemigos (fase de combate), A y D podrían servir para elegir el objetivo.
- **Estado:** hecha en la fase 3: [diseño](2026-11-03-combate-completo-design.md) y [plan](../plans/2026-11-03-combate-completo.md).

## Más encuentros con enemigos

- **Fecha:** 2026-11-04
- **Idea:** aumentar la probabilidad de que salgan enemigos.
- **Notas:**
  - Ahora (`EncounterMeter`): 15 m de gracia tras cada combate y luego un 0,6 % por metro andado sobre la hierba. De media sale un combate cada ~180 m, unos 35 s andando a 5 m/s.
  - Opción: bajar la gracia a 8-10 m y subir a ~1 % por metro, que da un combate cada ~110 m (~22 s). Hay que repasar el equilibrio, porque más combates dan más EXP y oro por hora.
  - Se puede hacer que cada zona tenga su propio ritmo en `ZoneData` (fase de mundo).
- **Estado:** hecha en la fase 5a: 9 m de gracia y 1 % por metro en la pradera y el bosque, cada zona con su ritmo en `ZoneData` ([plan](../plans/2026-11-04-mundo-bosque.md)).

## Recuadros de mensajes ajustados al contenido

- **Fecha:** 2026-11-04
- **Idea:** el recuadro del combate donde sale lo que haces y cuando te atacan es gigantesco. En general, todos los recuadros de mensajes tienen que ajustarse un poco al contenido, con márgenes, pero no "súper márgenes".
- **Estado:** hecha: [plan](../plans/2026-11-04-interfaz.md), tarea 2.

## Héroe color carne

- **Fecha:** 2026-11-04
- **Idea:** el héroe sale blanco. Tiene que ser color carne, lo más parecido a un humano.
- **Estado:** hecha: el héroe sin casco, con su piel y el cielo sin quemar los colores ([plan](../plans/2026-11-04-interfaz.md), tarea 1).

## Vida de los enemigos encima de su figura

- **Fecha:** 2026-11-04
- **Idea:** en combate, una barrita roja encima de cada enemigo con la vida que le queda, sin número.
- **Notas:** no estaba en ningún plan. Hoy solo se ve la vida del héroe.
- **Estado:** hecha: [plan](../plans/2026-11-04-interfaz.md), tarea 3.

## Colores y barras de los datos del héroe

- **Fecha:** 2026-11-04
- **Idea:** la misma regla de colores siempre, también en combate: oro dorado, PV rojo, PM azul y EXP verde. La vida y los PM siempre en formato barra. La EXP se muestra como la vida, "EXP X/YY", y ya no pone "siguiente nivel".
- **Estado:** hecha: [plan](../plans/2026-11-04-interfaz.md), tarea 2.

## Menú de pausa reorganizado

- **Fecha:** 2026-11-04
- **Idea:**
  - Tabla de fuera: "Héroe lvl X", Estado, Objetos y Equipo, y además las misiones.
  - Menú de la derecha: Guardar, Opciones, Volver al título y Cerrar.
  - Página Estado: sin "Héroe nivel X"; salen directamente las estadísticas y los hechizos.
- **Estado:** hecha: [plan](../plans/2026-11-04-interfaz.md), tarea 4.

## Misiones siempre visibles y sin "Misión cumplida" fijo

- **Fecha:** 2026-11-04
- **Idea:**
  - Solo se listan las misiones en curso.
  - "Misión cumplida" aparece unos segundos y luego se quita.
  - Nunca está vacío: si no hay ninguna asignada (siempre debería haber alguna), pone "Sigue el sendero" o "Explora el mapa".
- **Notas:** la fase 6 cambia `Quest` por un `QuestLog`, así que conviene que esto use ese registro.
- **Estado:** hecha: [plan](../plans/2026-11-04-interfaz.md), tarea 4; la fase 6 añade su registro en `GameState.current_missions()` ([plan](../plans/2026-11-04-historia-misiones.md)). Nota: sin misiones en curso, esa línea muestra `StoryState.goal_text()` (la historia) en lugar de "Sigue el sendero" / "Explora el mapa".

## Curarse nunca cuesta oro

- **Fecha:** 2026-11-04
- **Idea:** curarse, en la posada o donde sea, nunca debe costar oro.
- **Notas:**
  - Ahora las posadas cuestan 5, 15, 30 y 50 G (`Inn.INNS`), y solo la anciana cura gratis.
  - El oro de las posadas sale del equilibrio: hay que repasar el oro y las reglas de descanso de la partida automática.
  - Si se entiende al pie de la letra, las pociones y el Éter también curan y cuestan oro. Se interpreta que esto va por las posadas y otros puntos de descanso; las pociones se siguen comprando.
- **Estado:** hecha: posadas gratis en todas partes, sin tocar precios ([plan](../plans/2026-11-04-interfaz.md), tarea 5).

## Descripción de los objetos

- **Fecha:** 2026-11-04
- **Idea:** en los objetos tiene que poner para qué sirven o qué ventajas dan.
- **Estado:** hecha: [plan](../plans/2026-11-04-interfaz.md), tarea 4.

## Pergaminos de regreso al pueblo

- **Fecha:** 2026-11-04
- **Idea:** poder comprar pergaminos de regreso al pueblo, tipo Tomo del Portal de Diablo 2.
- **Notas:**
  - Ya existe el Ala de viaje (25 G, en las tiendas desde el bosque), que te lleva al último pueblo pero solo de ida.
  - Lo que añadiría el pergamino es poder volver al sitio donde lo usaste, como el portal. Al consumir el ala de viaje, que aparezca en el mapa un portal (o una marca en el suelo), te lleva al pueblo, te curas o lo que sea, y luego vuelves a pulsar en el portal/marca y vuelves donde estabas.
- **Estado:** hecha como Ala de viaje: deja un portal para volver una vez y se vende en todas las tiendas ([plan](../plans/2026-11-04-interfaz.md), tarea 5).

## Mapa de lo explorado

- **Fecha:** 2026-11-04
- **Idea:** que se vea el mapa de lo que has explorado en la vista general, cuando vas andando, en un cuadrado debajo de la tabla de fuera (Estado, Objetos, Equipo), un poco translúcido.
- **Notas:** hay que guardar lo explorado en la partida. Como es un mapa por zona, se guarda por zona.
- **Estado:** hecha: [plan](../plans/2026-11-04-interfaz.md), tarea 6.

## Adaptar el juego a móviles

- **Fecha:** 2026-11-05
- **Idea:** adaptar el juego a móviles.
- **Notas:**
  - No se hace hasta que esté todo el juego, porque requiere más investigación. Queda para futuras versiones.
  - No forma parte de ningún plan actual.
- **Estado:** hecha: [diseño](2026-11-06-moviles-design.md) y [plan](../plans/2026-11-06-moviles.md). Palanca flotante, zoom con dos dedos, botones y ventanas grandes, aviso de girar el móvil, calidad y fotogramas bajos y la instalación en la pantalla de inicio. Queda abierto: probarlo en un móvil de verdad (fotogramas, calor, Safari en iPhone, el sonido tras el primer toque, la instalación); si no llega a 30 FPS en un móvil medio, bajar primero `TOUCH_3D_LOW` y luego `Vegetation.SPACING`.

## Lo que no entra en la versión 1.0

- **Fecha:** 2026-11-06
- **Idea:** lo que queda fuera de la fase 7 ([plan](../plans/2026-11-06-pulido-publicacion.md)).
- **Notas:**
  - Inglés: descartado por el usuario, el juego queda solo en español.
  - Subir a itch.io: el material está en `docs/itch/`, y subirlo lo decide y lo hace el usuario.
  - Probar los ejecutables de Windows y Linux: las plantillas de escritorio no están en este PC; los genera el workflow con un tag `v*`.
  - Mando, tutoriales, bestiario, ciclo de día y noche, correr, exportar la partida y partida nueva +: siguen en `2026-11-03-ideas-juego-completo.md`, sin plan.
- **Estado:** sin decidir.
