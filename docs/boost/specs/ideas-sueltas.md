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
- **Estado:** pendiente.

## Héroe color carne

- **Fecha:** 2026-11-04
- **Idea:** el héroe sale blanco. Tiene que ser color carne, lo más parecido a un humano.
- **Estado:** pendiente.

## Vida de los enemigos encima de su figura

- **Fecha:** 2026-11-04
- **Idea:** en combate, una barrita roja encima de cada enemigo con la vida que le queda, sin número.
- **Notas:** no estaba en ningún plan. Hoy solo se ve la vida del héroe.
- **Estado:** pendiente.

## Colores y barras de los datos del héroe

- **Fecha:** 2026-11-04
- **Idea:** la misma regla de colores siempre, también en combate: oro dorado, PV rojo, PM azul y EXP verde. La vida y los PM siempre en formato barra. La EXP se muestra como la vida, "EXP X/YY", y ya no pone "siguiente nivel".
- **Estado:** pendiente.

## Menú de pausa reorganizado

- **Fecha:** 2026-11-04
- **Idea:**
  - Tabla de fuera: "Héroe lvl X", Estado, Objetos y Equipo, y además las misiones.
  - Menú de la derecha: Guardar, Opciones, Volver al título y Cerrar.
  - Página Estado: sin "Héroe nivel X"; salen directamente las estadísticas y los hechizos.
- **Estado:** pendiente.

## Misiones siempre visibles y sin "Misión cumplida" fijo

- **Fecha:** 2026-11-04
- **Idea:**
  - Solo se listan las misiones en curso.
  - "Misión cumplida" aparece unos segundos y luego se quita.
  - Nunca está vacío: si no hay ninguna asignada (siempre debería haber alguna), pone "Sigue el sendero" o "Explora el mapa".
- **Notas:** la fase 6 cambia `Quest` por un `QuestLog`, así que conviene que esto use ese registro.
- **Estado:** pendiente.

## Curarse nunca cuesta oro

- **Fecha:** 2026-11-04
- **Idea:** curarse, en la posada o donde sea, nunca debe costar oro.
- **Notas:**
  - Ahora las posadas cuestan 5, 15, 30 y 50 G (`Inn.INNS`), y solo la anciana cura gratis.
  - El oro de las posadas sale del equilibrio: hay que repasar el oro y las reglas de descanso de la partida automática.
  - Si se entiende al pie de la letra, las pociones y el Éter también curan y cuestan oro. Se interpreta que esto va por las posadas y otros puntos de descanso; las pociones se siguen comprando.
- **Estado:** pendiente.

## Descripción de los objetos

- **Fecha:** 2026-11-04
- **Idea:** en los objetos tiene que poner para qué sirven o qué ventajas dan.
- **Estado:** pendiente.

## Pergaminos de regreso al pueblo

- **Fecha:** 2026-11-04
- **Idea:** poder comprar pergaminos de regreso al pueblo, tipo Tomo del Portal de Diablo 2.
- **Notas:**
  - Ya existe el Ala de viaje (25 G, en las tiendas desde el bosque), que te lleva al último pueblo pero solo de ida.
  - Lo que añadiría el pergamino es poder volver al sitio donde lo usaste, como el portal. Falta decidir si sustituye al Ala o convive con ella, y venderlo también en Villaclaro.
- **Estado:** pendiente.

## Mapa de lo explorado

- **Fecha:** 2026-11-04
- **Idea:** que se vea el mapa de lo que has explorado en la vista general, cuando vas andando, en un cuadrado debajo de la tabla de fuera (Estado, Objetos, Equipo), un poco translúcido.
- **Notas:** hay que guardar lo explorado en la partida. Como es un mapa por zona, se guarda por zona.
- **Estado:** pendiente.
