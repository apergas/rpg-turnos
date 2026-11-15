# Documento maestro

Lo que se ha hecho y lo que queda por hacer en Villaclaro. Una fila por versión o por punto (`M-nn`). Estados: idea, spec, plan, en curso, hecho. Las ideas nuevas se apuntan primero en [ideas.md](ideas.md) y pasan aquí cuando se diseñan. El registro anterior (QA, propuestas largas, descartes) está en el historial de git y en `docs/legacy/`.

| Versión / ID | Qué | Estado |
|---|---|---|
| 1.0.0 y anteriores | El juego base: Villaclaro, el bosque, la mina, el castillo y el final; móviles y web | hecho |
| 1.1.1 · M-01 a M-06, M-23 a M-25 | Errores y confusiones: pantalla blanca en la web, bestiario completable, no huir de jefes, botín de los cofres, teclas mantenidas, pantalla completa | hecho |
| 1.2.0 · M-07 a M-16 | Orientación y comodidad: nombre del lugar, mapa grande, objetivos de la mina, curar fuera de combate, menos combates en zonas superadas | hecho |
| 1.3.0 · M-18 a M-21 | Colección en el Diario, fichas del bestiario, tres ranuras, exportar e importar la partida | hecho |
| 1.4.0 · M-22 | El Eco de la Niebla tras el final | hecho |
| 1.4.1 · M-26, M-27 | Retoques del combate: hechizos y enemigos iguales | hecho |
| 1.5.0 · M-28 a M-30 | Ataque sorpresa, Pluma de fénix y Despertador | hecho |
| 1.6.0 · M-31, M-32 | Cinco enemigos nuevos y familias del bestiario; anillo y amuleto | hecho |
| 1.7.0 · M-33 | Monstruos a la vista en el mapa | hecho |
| 1.8.0 · M-34, M-35 | Medallas pequeñas y Coleccionista; Partida nueva + | hecho |
| 1.9.0 · M-36, M-38 | Ambiente y partículas por zona; menú de depuración | hecho |
| 2.0.0 · M-39 a M-42 | La v2: la caravana, el compañero, nivel 40 y la jungla | hecho |
| 2.0.1 · M-48 | Decoración Kenney en los mapas | hecho |
| 2.1.0 | El desierto | hecho |
| 2.2.0 | La montaña | hecho |
| 2.3.0 · M-43 a M-47 | La ciudad, el Devorador del portal y el final de la v2 | hecho |
| 2.4.0 · M-49 a M-55 | Lo que pidió el usuario tras jugar la v2: misiones de recoger, entregas al Jefe, más monstruos, árboles, gente de la caravana, humor, campamento vestido | hecho |
| 2.4.1 | Vender los anillos y amuletos de premio | hecho |
| 2.5.0 · M-56 | Las medallas pequeñas caen de los enemigos; el Coleccionista en cada pueblo ([spec](../legacy/specs/2026-11-13-version-2-5-0-design.md) · [plan](../legacy/plans/2026-11-13-version-2-5-0.md)) | hecho |
| 2.5.0 · M-57 | Más monstruos en las zonas de la v1, y grupos que vuelven solos en todas | hecho |
| 2.5.0 · M-58 | El Slime de Metal a la mitad de velocidad | hecho |
| 2.5.0 · M-59 | Un portal del Ala de viaje más bonito | hecho |
| 2.5.0 · M-60 | Una misión opcional más en la mina y otra en el castillo | hecho |
| 2.5.0 · M-61 | Un fuego más realista en antorchas y hogueras | hecho |
| 2.6.0 · M-62 | Una sola fuente de verdad para la interfaz: `UiTokens` y `UiTheme`, desde el [design system](design-system/README.md) ([spec](../legacy/specs/2026-11-13-version-2-6-0-design.md) · [plan](../legacy/plans/2026-11-13-version-2-6-0.md)) | hecho |
| 2.6.0 · M-63 | La fila elegida y el cursor ▶ en todos los menús, igual con teclado, ratón o dedo | hecho |
| 2.6.0 · M-64 | Tipografía: Nunito y Baloo 2 en todas las plataformas, diez estilos de texto | hecho |
| 2.6.1 · M-65 | Accesibilidad y tono: más contraste, sombra de ventana, opción «Alto contraste» y repaso de textos | hecho |
| 2.6.1 · M-66 | Componentes del design system: aviso con tono, PV críticos, insignia «Aturdido», indicador de diálogo, botón de acción… | hecho |
| 2.7.0 · M-67 | Partida nueva de verdad: se quita la Partida nueva + y empezar otra vez es empezar de cero ([spec](../legacy/specs/2026-11-14-version-2-7-0-design.md) · [plan](../legacy/plans/2026-11-14-version-2-7-0.md)) | hecho |
| 2.7.0 · M-68 | Bestiario en tres estados: no visto, visto sin vencer y vencido | hecho |
| 2.7.0 · M-69 | Sanación cura también al compañero, la mitad | hecho |
| 2.7.1 · M-75 | El design system generado: UiTokens sale de tokens.json, sin valores a mano en la interfaz, comprobado antes de cada commit y en la publicación ([spec](../legacy/specs/2026-11-14-version-2-7-1-design.md) · [plan](../legacy/plans/2026-11-14-version-2-7-1.md)) | hecho |
| 2.7.2 · M-70 | Trocear `Game`: `SessionContext` y las piezas `ZoneTravel`, `BattleFlow`, `BattleRewards`, `FigureTalk`, `CaravanFlow`, `StoryFlow`, `CreditsData`, `GameAutoplay`, `AutoplayStarts` y `GameDebug`; `Game` queda como coordinador de la sesión ([spec](../legacy/specs/2026-11-14-refactor-arquitectura-design.md) · [guía](../legacy/specs/2026-11-14-refactor-arquitectura-guia.md) · [plan](../legacy/plans/2026-11-14-refactor-4-game.md)) | hecho |
| 2.7.2 · M-71 | Refactor de arquitectura: `World` troceado en `MapHud`, `MapProps`, `MapFigures`, `MapMonsters`, `AutoplayHunter` y `MapUses` ([plan](../legacy/plans/2026-11-14-refactor-3-world.md)) | hecho |
| 2.7.2 · M-72 | Refactor de arquitectura: `BattleActor` troceado en `ActorLooks`, `CreatureBuilder`, `CharacterBuilder` y las primitivas de `LowPoly` ([plan](../legacy/plans/2026-11-14-refactor-2-battle-actor.md)) | hecho |
| 2.7.2 · M-73 | Refactor de arquitectura: los constructores llevan `## Constructor:` y `CLAUDE.md` distingue reglas puras, constructores y nodos ([plan](../legacy/plans/2026-11-14-refactor-1-runflags-builders.md)) | hecho |
| 2.7.2 · M-74 | Refactor de arquitectura: la línea de órdenes solo se lee en `RunFlags`, y el piloto automático de cada clase va en su `#region Autoplay` ([plan](../legacy/plans/2026-11-14-refactor-1-runflags-builders.md)) | hecho |
| 3.0.0 · M-76 | El paso al otro lado: el fin de la v2 sigue en la Caravana y el portal une la Caravana con Brumaclara en los dos sentidos ([spec](../legacy/specs/2026-11-14-version-3-design.md) · [plan](../legacy/plans/2026-11-14-version-3-0-0.md)) | hecho |
| 3.0.0 · M-77 | La parte 3 en el estado: etapa, capítulos, zonas por parte, guardado 15 | hecho |
| 3.0.0 a 3.3.0 · M-78 | Brumaclara, el sol negro y el pueblo que crece con cada jefe, hasta la fiesta del final | hecho |
| 3.0.0 a 3.3.0 · M-79 | Las cuatro zonas: Ciénaga, Cuevas de cristal, Ruinas flotantes y la Fuente · [plan 3.1.0](../legacy/plans/2026-11-14-version-3-1-0.md) · [plan 3.2.0](../legacy/plans/2026-11-14-version-3-2-0.md) · [plan 3.3.0](../legacy/plans/2026-11-14-version-3-3-0.md) | hecho |
| 3.0.0 a 3.3.0 · M-80 | Veinte enemigos, tres jefes, el Eco de Albor y cuatro familias del bestiario | hecho |
| 3.0.0 a 3.3.0 · M-81 | Nivel 50, el elemento luz y Alba, cuatro juegos de equipo, el Elixir | hecho |
| 3.0.0 a 3.3.0 · M-82 | Ocho misiones de Brumaclara | hecho |
| 3.1.0 a 3.2.0 · M-83 | La vuelta a Villaclaro a por el Amuleto del Alba | hecho |
| 3.3.0 · M-84 | El Eco de Albor, la elección, los dos finales y los créditos de la v3 ([plan](../legacy/plans/2026-11-14-version-3-3-0.md)) | hecho |
| 3.0.0 a 3.3.0 · M-85 | Partida automática de la v3 | hecho |
| 3.4.0 · M-86 | Vender solo lo vendible: fuera de la lista las piezas puestas y lo que no se vende ([spec](specs/2026-11-15-version-3-4-0-design.md)) | spec |
| 3.4.0 · M-87 | En «Equipo», lo que da cada pieza va debajo de su nombre | spec |
| 3.4.0 · M-88 | En «Estado», los números del compañero o la criatura debajo de su nombre | spec |
| 3.4.0 · M-89 | En combate, al elegir objetivo, el resto del menú queda en gris y solo responde «Volver» | spec |
| 3.4.0 · M-90 | Rótulos con el nombre sobre el Coleccionista, el Jefe de caravana, Orvalla y el Tablón | spec |
| 3.5.0 · M-91 | Los hechizos de daño del héroe crecen un 3 % por nivel; curar no cambia ([spec](specs/2026-11-15-version-3-5-0-design.md)) | spec |
| 3.5.0 · M-92 | Usar un objeto en combate va siempre el primero, como Defender y Huir | spec |
| 3.5.0 · M-93 | El compañero de la caravana estrena una pieza de equipo en cada tramo y etapa | spec |
| 3.5.0 · M-94 | Sin portal en el fondo de los combates del Barrio del portal, salvo contra el Devorador | spec |
| 3.5.0 · M-95 | El portal entre la Caravana y Brumaclara, con la misma forma pero rojizo | spec |
| 3.6.0 · M-96 | El compañero o la criatura te sigue por el mapa ([spec](specs/2026-11-15-version-3-6-0-design.md)) | spec |
| 3.6.0 · M-97 | La tienda vende los consumibles y un armero nuevo, el equipo, en cada pueblo | spec |
| 3.6.1 · M-98 | El design system en un núcleo reutilizable (`addons/design_system/`) y la capa de Villaclaro; el juego no cambia ([spec](specs/2026-11-15-version-3-6-1-design-system-nucleo-design.md)) | spec |
