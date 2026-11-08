# Estado del proyecto

Fecha: 2026-11-08. `develop` (`916819b`) lleva implementadas las versiones 1.1.1, 1.2.0, 1.3.0 y 1.4.0 de `docs/boost/documento-maestro.md` (M-01 a M-16 y M-18 a M-25; M-17 descartado). Nada de eso está subido: `main` y la web siguen en la 1.1.0. Sin tag ni itch.io. Las pruebas que piden un móvil real o una mano están en los informes de cada versión y en el resumen de abajo.

Incidente: el 2026-11-07, durante la 1.2.0, el subagente implementador borró por error `save.json` y `options.json` de la carpeta real de escritorio (`%APPDATA%/Godot/app_userdata/rpg-turnos/`), sin copia. Desde entonces las reglas obligan a poner `APPDATA` en el mismo comando y a borrar solo con rutas literales del scratchpad.

**Lo que queda por hacer está en `docs/boost/documento-maestro.md`**, que reúne las conclusiones de las pasadas de QA sobre la 1.0.0 y la 1.1.0 y los pendientes de este documento. Si algo de aquí lo contradice, manda aquel.

El estado sale del historial de git y de los planes en `docs/boost/plans/`. "Publicado" significa que está en `main`, que se despliega en GitHub Pages.

## Resumen

| Bloque | Tareas | Hechas | Pendientes | Estado |
|---|---|---|---|---|
| Base previa a las fases | 18 | 18 | 0 | Publicado |
| Fase 1: base visual y de control | 7 | 7 | 0 | Publicado |
| Fase 2: sensación de juego | 6 | 6 | 0 | Publicado |
| Fase 3: combate completo | 5 | 5 | 0 | Publicado |
| Fase 4: economía y equipo | 5 | 5 | 0 | Publicado |
| Fase 5: mundo (bosque, mina y castillo) | 12 | 12 | 0 | Publicado |
| Pasada de interfaz (ideas sueltas) | 7 | 7 | 0 | Publicado |
| Fase 6a: historia | 5 | 5 | 0 | Publicado |
| Fase 6b: misiones secundarias | 5 | 5 | 0 | Publicado |
| Fase 7: pulido y publicación | 6 | 6 | 0 | Publicado (sin inglés) |
| Adaptación a móviles | 4 | 4 | 0 | Publicado |
| Arreglos de QA en móvil | 7 | 7 | 0 | Publicado |
| Evolutivos de la versión 1.1.0 | 15 | 15 | 0 | Publicado |
| Arreglos de QA sobre la 1.1.0 | 9 | 9 | 0 | Publicado |
| **Total con plan** | **111** | **111** | **0** | |

## Tareas hechas

### Base previa a las fases

| Plan | Merge | Tarea | Estado |
|---|---|---|---|
| Prototipo de combate | `a907207` | 1. Proyecto Godot y tooling | Hecha |
| | | 2. Datos y motor de combate | Hecha |
| | | 3. Actor 3D de combate | Hecha |
| | | 4. HUD de combate y pantalla de resultado | Hecha |
| | | 5. Escenario, escena de combate y verificación jugando | Hecha |
| | | 6. Documentación y merge a develop | Hecha |
| Mundo y exploración | `80a7630` | 1. Reglas puras (GameState y EncounterMeter) | Hecha |
| | | 2. Combate reutilizable y Game mínimo | Hecha |
| | | 3. Mundo andable (escenario, jugador, cámara y encuentros) | Hecha |
| | | 4. Bucle completo (mapa, combate encima y fundidos) | Hecha |
| | | 5. Documentación y merge a develop | Hecha |
| Progresión de combate | `ed40b1e` | 1. Datos y reglas puras | Hecha |
| | | 2. Motor con comandos, hechizo, poción, IA, nivel y botín | Hecha |
| | | 3. Menú de comandos, PM en el HUD y animaciones nuevas | Hecha |
| | | 4. Estado del mapa y documentación | Hecha |
| Pueblo y misión | `cbdd092` | 1. Reglas de la misión y datos del jefe | Hecha |
| | | 2. Aspecto del jefe y de los aldeanos en combate | Hecha |
| | | 3. Pueblo, diálogos, jefe en el mapa y conexión con Game | Hecha |

### Fase 1: base visual y de control

| Plan | Merge | Tarea | Estado |
|---|---|---|---|
| Cámara y vegetación | `410df40` | 1. Cámara cenital y movimiento según la pantalla | Hecha |
| | | 2. Hierba alta y flores en el mapa | Hecha |
| | | 3. Hierba en combate, documentación, exportación web y partida completa | Hecha |
| Modelos low-poly | `c46b960` | 1. Modelos en el repositorio, con créditos | Hecha |
| | | 2. Personajes animados y slimes | Hecha |
| | | 3. Pueblo, rocas, árboles y arbustos en el mapa y en combate | Hecha |
| | | 4. Documentación, comprobación completa y exportación web | Hecha |

### Fase 2: sensación de juego

| Plan | Merge | Tarea | Estado |
|---|---|---|---|
| Sensación de juego | `403be03` | 1. Música y efectos procedurales, y director de audio | Hecha |
| | | 2. Datos de guardado, almacén y archivo de opciones | Hecha |
| | | 3. Música y efectos en el mapa y en combate | Hecha |
| | | 4. Pantalla de título, carga y autoguardado | Hecha |
| | | 5. Menú de pausa | Hecha |
| | | 6. Documentación, comprobación completa y exportación web | Hecha |

### Fase 3: combate completo

| Plan | Merge | Tarea | Estado |
|---|---|---|---|
| Combate completo | `77cc7ba` | 1. Reglas de combate y datos de la zona 1 | Hecha |
| | | 2. Figuras de enemigos y HUD de combate | Hecha |
| | | 3. Combate con uno o dos enemigos | Hecha |
| | | 4. Encuentros, oro, misión y objetos en el mapa | Hecha |
| | | 5. Documentación, comprobaciones finales y exportación web | Hecha |

### Fase 4: economía y equipo

| Plan | Merge | Tarea | Estado |
|---|---|---|---|
| Economía y equipo | `7d3a9de` | 1. Reglas de equipo, tienda, posada y cofres, oro y guardado v3 | Hecha |
| | | 2. Arma y escudo en el caballero, oro perdido en combate | Hecha |
| | | 3. Mercader, posadero y cofres en el mapa, oro en la ventana de estado | Hecha |
| | | 4. Ventana de tienda, posada y página Equipo | Hecha |
| | | 5. Documentación, comprobaciones finales y exportación web | Hecha |

### Fase 5: mundo

| Plan | Merge | Tarea | Estado |
|---|---|---|---|
| 5a. Bosque | `3c95925` | 1. Biblioteca de enemigos, enemigos del bosque y Bruja | Hecha |
| | | 2. Zonas como datos, salidas, cambio de zona y guardado v4 | Hecha |
| | | 3. El bosque, su aldea y la Bruja | Hecha |
| | | 4. Documentación, comprobaciones finales y exportación web | Hecha |
| 5b. Mina | `fd46f92` | 1. Enemigos de la mina y carga del Golem | Hecha |
| | | 2. Plantas de mazmorra y las tres plantas de la mina | Hecha |
| | | 3. El paso del bosque a la mina | Hecha |
| | | 4. Documentación, comprobaciones finales y exportación web | Hecha |
| 5c. Castillo | `c3fe452` | 1. Esqueletos y las dos fases del Señor de la Niebla | Hecha |
| | | 2. Plantas del castillo, campamento y final del juego | Hecha |
| | | 3. El paso desde la mina y una partida automática que descansa | Hecha |
| | | 4. Documentación, créditos, comprobaciones finales y exportación web | Hecha |

### Pasada de interfaz (merge `5851c8f`)

| Tarea | Estado |
|---|---|
| 1. Héroe con aspecto humano | Hecha |
| 2. Ventanas ajustadas, barras y regla de colores | Hecha |
| 3. Barra roja sobre cada enemigo | Hecha |
| 4. Menú de pausa, misiones y descripción de objetos | Hecha |
| 5. Posadas gratis y portal del Ala de viaje | Hecha |
| 6. Mapa de lo explorado | Hecha |
| 7. Documentación y exportación web | Hecha |

### Fase 6a: historia (merge `f739a35`)

| Tarea | Estado |
|---|---|
| 1. Nombre del héroe, estado de la historia y guardado | Hecha |
| 2. Reproductor de escenas y prólogo | Hecha |
| 3. Escenas de la historia y frases de los aldeanos por capítulo | Hecha |
| 4. Final, créditos y partida terminada | Hecha |
| 5. Documentación, comprobaciones finales y exportación web | Hecha |

### Fase 6b: misiones secundarias (merge `28db326`)

| Tarea | Estado |
|---|---|
| 1. Ranura de accesorio, semillas y guardado v7 | Hecha |
| 2. Registro de misiones, las 6 misiones y Slime de Metal | Hecha |
| 3. Tablones, Niña, gato, explorador y marcas "!" y "?" | Hecha |
| 4. Página Diario | Hecha |
| 5. Documentación, partidas completas y exportación web | Hecha |

## Tareas pendientes

No queda ninguna tarea con plan. Estas tablas quedan como registro de lo último que se ha hecho.

### Fase 7: pulido y publicación (`docs/boost/plans/2026-11-06-pulido-publicacion.md`)

| Tarea | Estado |
|---|---|
| 1. Piezas de menú compartidas, scroll y solape del menú de pausa | Hecha y revisada (`02ee027`) |
| 2. Opciones: velocidad de combate, pantalla completa, calidad, temblor y texto grande | Hecha y revisada (`ebb374f`) |
| 3. Teclas reasignables | Hecha y revisada (`c743e71`) |
| 4. Dificultad Fácil / Normal y guardado v8 | Hecha y revisada (`0ac15a8`) |
| 5. Nombre, versión, icono, portada, presets de escritorio, `CHANGELOG.md` y `docs/itch/` | Hecha y revisada (`5e9599f`) |
| Extra: más encuentros (pradera y bosque 5 m + 2,5 %, mina y castillo 4 m + 4 %) | Hecha (`141dbd6`), a confirmar al jugar |
| 6. Repaso de ventanas y textos, documentación, partidas completas y exportación web | Hecha (`b593e48`) |
| Revisión final de la rama y merge a `develop` | Hecha (`8a6ea08`) |

El inglés queda descartado: el juego es solo en español. Fuera de esta fase: subir a itch.io o crear tags (necesita tu permiso).

### Adaptación a móviles (`docs/boost/plans/2026-11-06-moviles.md`)

| Tarea | Estado |
|---|---|
| 1. Detección, escala, botones, rendimiento y opciones | Hecha y revisada |
| 2. Palanca, zoom con dos dedos y botón de usar | Hecha y revisada |
| 3. Ventana de estado compacta y ventanas que caben | Hecha y revisada |
| 4. Instalar en la pantalla de inicio, documentación y exportación | Hecha, revisada en la revisión final |
| Prueba en navegador a 740 × 360 con toques reales | Hecha |

## Ideas del listado sin fase ni plan

Están en `2026-11-03-ideas-juego-completo.md`, pero las fases no las recogen. Las he buscado por palabra clave y no aparecen en el código ni en los diseños y planes de las fases 6 y 7, salvo las notas indicadas. La búsqueda no prueba por sí sola que falte todo: conviene decidir si entran o no.

| Área | Ideas |
|---|---|
| Combate | Ataque sorpresa |
| Objetos | Despertador, Pluma de fénix |
| Enemigos | Variantes de color, Bestiario |
| Mundo | Jarrones, ciclo de día y noche, correr, estatuas de guardado |
| Pueblos | Iglesia, personajes que pasean y animales |
| Economía | Medallas pequeñas |
| Interfaz | Soporte de mando, tutoriales |
| Audio | Sonido de ambiente |
| Visuales | Partículas |
| Guardado | Exportar e importar la partida |
| Contenido final | Partida nueva + (el diseño de la historia la menciona) |
| Herramientas | Menú de depuración |

## Asuntos abiertos

| Asunto | Quién | Estado |
|---|---|---|
| Chrome en Android, en emulador | Tú | Dado por bueno. Reporte y arreglos en `docs/boost/qa/2026-11-06-android-emulador.md`; queda sin resolver una banda negra a pantalla completa, vista 1 vez de 4 |
| Jugar el nivel 1 con la Seta y el Murciélago suavizados | Tú | Pendiente |
| Probar en un móvil real: FPS, calor, Safari en iPhone, sonido e instalar en la pantalla de inicio | Tú | Pendiente |
| Probar a mano: encuentros nuevos, ventana de dificultad, reasignar teclas, pantalla completa, x2 en combate, nombre con teclado y clics, avanzar el prólogo, WASD en combate, tienda con teclado, ratón y táctil, FPS reales | Tú | Pendiente |
| Ver a la vista la ventana de derrota | Yo | Pendiente |
| Ejecutables de Windows y Linux sin probar: aquí solo están las plantillas web, y descargar las otras necesita tu permiso | Tú, con un tag `v*` o lanzando el workflow a mano | Abierto |
| La partida automática dura 1:16-1:27; el objetivo de unas 2 h es para una persona y no está medido | Tú, al jugar | Abierto |
| Archivos locales ausentes: `tools/godot-mcp`, `tools/serve_web.ps1`, `.mcp.json`, `.claude/launch.json`, `assets_src/` | Tú, si los necesitas | Abierto |
| Autor de los créditos: ahora "apergas" (`Game.AUTHOR`) | Tú, si quieres cambiarlo | Abierto |

## Modelos de los subagentes

| Trabajo | Modelo |
|---|---|
| Escribir planes | Opus |
| Implementar y revisar, incluida la revisión final | Sonnet |
