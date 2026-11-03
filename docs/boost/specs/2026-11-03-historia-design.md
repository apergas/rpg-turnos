# Historia: diseño

Fecha: 2026-11-03
Paso: fase 6 de `2026-11-03-ideas-juego-completo.md`. Va después de la fase 5 (zonas, jefes y fragmentos del amuleto).

## Objetivo

Unir las cuatro zonas con un argumento corto y original, escenas sencillas, misiones secundarias, un diario y un final con créditos. Todo cabe en las 2 horas previstas.

## Decisiones tomadas

El usuario pidió que no se le pregunte, así que todas son la opción recomendada.

| Tema | Decisión |
|---|---|
| Argumento | Desde hace semanas, una **niebla** baja del norte, del viejo Castillo de la Niebla, y despierta a los monstruos. La anciana de Villaclaro, **Abuela Rosa**, guardaba el **Amuleto del Alba**, que mantenía la niebla a raya, pero se partió en tres. Cada fragmento acabó en manos de un guardián: la Bruja del bosque, el Golem de la mina y el Señor de la Niebla. El héroe es un joven de Villaclaro sin nombre fijo (se elige al empezar). Con dos fragmentos se puede entrar al castillo, y el tercero lo guarda el propio Señor de la Niebla. Al vencerlo, el amuleto se recompone y la niebla se disipa |
| Tono | Cuento amable al estilo clásico: diálogos cortos, algo de humor de los PNJ y nada de violencia explícita |
| Nombre del héroe | Pantalla de nombre al empezar una partida nueva, con teclado en pantalla (cuadrícula de letras para ratón y móvil, y escritura directa con teclado). Máximo 8 letras y por defecto "Héroe". Todos los textos usan el nombre |
| Prólogo | 1-2 minutos. El héroe despierta en su casa de Villaclaro (una casa pasa a ser la suya, con la puerta como punto de inicio), la niebla tapa el cielo y la Abuela Rosa le cuenta lo del amuleto. La misión de los slimes queda como el primer encargo: "Primero demuestra que puedes con los slimes" |
| Escenas | Escenas sencillas con **guiones de datos** (`Cutscene`, `Resource`): una lista de pasos `say(quién, texto)`, `move(quién, punto)`, `face`, `wait`, `camera_to(punto, zoom)`, `fade_out` / `fade_in`, `music(id)` y `flag(nombre)`. Un `CutscenePlayer` las reproduce y bloquea los controles; Enter o un toque pasan el texto. Hay unas 8 escenas: prólogo, tras el Rey Slime, entrada a la aldea, tras la Bruja, entrada a la mina, tras el Golem, puerta del castillo y final |
| Diálogos de PNJ | Cada PNJ tiene **líneas por etapa de la historia** en su `ZoneData`, así que cambian según el avance. 2-4 PNJ por pueblo |
| Misiones secundarias | **6 misiones** en un **tablón** por pueblo y en algunos PNJ. Tipos: cazar ("Derrota 5 lobos"), recoger ("Trae 3 setas" del botín de las Setas saltarinas), entregar (llevar una carta de Villaclaro a la aldea del bosque), buscar (encontrar al gato perdido en el bosque), un **jefe opcional** (el **Slime de Metal**, un raro de la pradera que aparece tras vencer a la Bruja: muy rápido, DEF muy alta, huye a menudo y da mucha EXP) y una del castillo (rescatar a un explorador). Recompensas: oro, un objeto, una **semilla de estadística** (+2 a una estadística) o un equipo único (el **Anillo antiveneno**, accesorio) |
| Ranura de accesorio | Se añade la 4ª ranura de equipo, **accesorio**, solo para recompensas: Anillo antiveneno (inmune al veneno) y Amuleto de velocidad (+3 VEL) |
| Diario | Opción **Diario** en el menú de pausa: misiones activas con su objetivo y progreso, misiones completadas y "Qué hacer ahora" (el siguiente paso de la historia en una línea) |
| Indicadores | Un **"!"** amarillo flota sobre un PNJ con una misión nueva y un **"?"** sobre el que espera una entrega |
| Final | Al vencer al Señor de la Niebla hay una escena de 1-2 minutos: la niebla se disipa, el héroe vuelve a Villaclaro (fundido) y la Abuela Rosa y el pueblo lo celebran. Después vienen los **créditos**: equipo de desarrollo (el usuario como autor, más el motor Godot, KayKit / Kay Lousberg y "Música y efectos generados por el juego"), las **estadísticas de la partida** (tiempo, combates, pasos, oro ganado, misiones y nivel) y "Fin". Se vuelve al título. La partida guardada queda marcada como terminada y se puede seguir jugando en el mundo después del final para las secundarias |
| Lo que ya existe | La misión de los slimes y la del Rey Slime se integran en la historia como capítulo 1. `Quest` pasa a ser una de las misiones de un `QuestLog` |

## Arquitectura

- **`QuestLog`** (`RefCounted`): todas las misiones, cada una con id, etapas, objetivo, progreso y recompensa, definidas en `data/quests/*.tres` (`QuestData`). `on_victory(enemy_id)`, `on_item(id)`, `on_talk(npc_id)`, `on_flag(flag)`. Es puro.
- **`StoryState`**: el capítulo actual (0 prólogo, 1 pradera, 2 bosque, 3 mina, 4 castillo, 5 final) y los indicadores. Vive en `GameState` y lo guarda `SaveData`.
- **`Cutscene`** (`Resource`) y **`CutscenePlayer`** (`Node`) en `scripts/story/`.
- **Ventanas nuevas:** `NameEntry` (`Control`), el diario del menú de pausa y `CreditsScreen`.
- **PNJ:** `ZoneData.npcs` gana `lines_by_chapter` y `quest_id`.

## Verificación (sin tests)

- `--check-only` en los scripts tocados.
- **Autoplay completo con historia:** pasa por las escenas (cada paso impreso), hace al menos 3 secundarias de camino, termina el juego y llega a los créditos. Imprime las estadísticas finales y la duración del tiempo de juego, que se compara con ~2 h.
- **Fotogramas:** nombre, prólogo, diario, "!" y "?", final y créditos.
- **Guardar y cargar** a mitad de la historia conserva el capítulo, las misiones y el nombre.
- **Versión web:** se exporta.

## Fuera de alcance

- Varios finales.
- Partida nueva + y superjefe (contenido final, fuera de las 2 horas).
- Voces y retratos.
