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
