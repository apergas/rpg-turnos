# Versión 3.9.0: tests unitarios de las reglas

Fecha: 2026-11-16. Estado: spec. Cubre M-121 a M-123 del [documento maestro](../documento-maestro.md). Va después de la 3.8.2 y la necesita fusionada en `develop`. El juego no cambia: la partida guardada sigue en la **versión 16**, ningún texto, dato ni equilibrio se toca.

## Objetivo

Hasta hoy CLAUDE.md decía «No tests — ever». El 2026-11-16 el usuario ha decidido que quiere tests unitarios a partir de ahora, «que tengan utilidad a la hora de probar el juego y detectar errores».

1. **Un marco de tests (M-121).** GUT, copiado en `addons/gut/`, fuera de las exportaciones, y una primera tanda de unos **160 tests** sobre las reglas puras del juego, en `tests/`, que se ejecuta con una sola orden.
2. **En GitHub Actions (M-122).** Un flujo propio, `tests.yml`, los pasa en cada subida a `develop`. Un test que falla pone la ejecución en rojo.
3. **Las reglas nuevas (M-123).** CLAUDE.md sustituye «No tests — ever» por una sección de tests: cuándo un cambio añade o cambia tests, qué no se prueba nunca y que el piloto automático sigue siendo la comprobación del juego entero. La skill del piloto, la guía de QA y la forma de escribir los planes se ponen al día.

## Decisiones tomadas (2026-11-16)

El usuario tomó la primera: tener tests. Las demás siguen sus preferencias de siempre (la opción recomendada, sin preguntar).

| Tema | Decisión |
|---|---|
| Tener tests | Sí, desde la 3.9.0. Que sirvan para encontrar errores, no para contar cobertura |
| Marco | **GUT 9.7.1** (`bitwes/Gut`, licencia MIT). Ver §1 |
| Descarga | La única descarga del plan. Al implementar, antes de bajar nada, se pide permiso explícito al usuario diciendo el archivo, de dónde sale y su tamaño. Versión exacta, copiada en el repositorio (`addons/gut/`), nunca descargada en CI |
| Exportación | `addons/gut/*`, `tests/*` y `.gutconfig.json` van al `exclude_filter` de los tres presets. El juego publicado no lleva nada de esto |
| Qué se prueba | Solo **reglas puras** (los `RefCounted` / `Resource` que no tocan nodos) y la **coherencia de los datos** (`data/`). Nunca escenas, nodos, constructores, imagen, sonido ni archivos |
| Prioridad | Lo que más se ha roto o más cuesta ver jugando: partidas guardadas, fórmulas de combate, niveles y topes, tiendas, misiones, historia, bestiario y medallas (§2) |
| Azar | `BattleEngine` ya recibe su `RandomNumberGenerator`: los tests le pasan uno con semilla. Ningún test depende de los números de una semilla: comprueban límites sobre muchas semillas o combates amañados en los que el azar no decide nada. No hace falta cambiar ningún script del juego |
| Tamaño | Unos 160 tests en 21 archivos. Útil sin ser enorme; cada versión que toque una regla añade los suyos |
| Carpetas | `tests/` como `scripts/`: `tests/<carpeta>/test_<script>.gd`. Los datos, en `tests/data/`. Los constructores de apoyo, en `tests/fixtures.gd`, sin `class_name` |
| Orden local | Una: `godot --headless --path . --script res://addons/gut/gut_cmdln.gd`, con `APPDATA` en una carpeta de pruebas escrita a mano. Lee `res://.gutconfig.json`. Sale con 0 si todo pasa y con 1 si algo falla |
| CI | Flujo propio, `.github/workflows/tests.yml`, en cada subida a `develop` y a mano. Falla si falla un test o si sale una línea `ERROR` |
| Hook de pre-commit | **No** pasa los tests. El hook es el del núcleo del design system y solo mira el design system. Los tests se pasan en cada tarea, en cada versión y en CI |
| El piloto automático | Sigue siendo la comprobación del juego entero (`autoplay_all.sh`, `autoplay.yml`). Los tests lo complementan, nunca lo sustituyen |
| Planes (boost) | Un plan que cambia una regla lleva sus pasos de test en la misma tarea. Para arreglar un fallo de una regla, primero el test que falla. Nunca pasos de test para nodos, escenas o lo visual |
| La 3.8.2 | Los tests de lo que trae la 3.8.2 (guardado 2 a 8, números recortados, `ClosingLands`, misiones perdidas, «n/m») van marcados. Se escriben contra el código ya fusionado |
| Versión | 3.9.0: una menor, porque cambia la forma de trabajar aunque el juego no cambie |

## 1. El marco: GUT

### Por qué GUT y no GdUnit4

Las dos son de código abierto con licencia MIT, se mantienen en 2026 y tienen ejecutor por línea de órdenes. Lo que decide es lo que este proyecto necesita: probar reglas de GDScript sin editor, sin ventana y en CI.

| | GUT 9.7.x | GdUnit4 6.2.x |
|---|---|---|
| Godot 4.7 | La 9.7.0 dice en sus notas «Compatibility changes for Godot 4.7»; la 9.7.1 es su arreglo | La 6.2.3 es de noviembre de 2026 y nombra Godot 4.7 en un arreglo, pero sus notas no dicen qué versiones soporta |
| Ejecutor | `gut_cmdln.gd`, un `SceneTree` de GDScript: `--headless --script`, sin editor ni plugin activado | `GdUnitCmdTool.gd`, más pensado para el editor; su fuerte son las escenas |
| Resultado | Código de salida 1 si falla algo (`should_exit`), informe JUnit XML | Igual, más una acción oficial de GitHub |
| Lo que trae de más | Dobles y parámetros, que bastan | Aserciones encadenadas, fuzzers, mocks y un ejecutor de escenas |
| Peso | GDScript solo | GDScript y, opcional, C# |

GdUnit4 es más rico, pero lo que tiene de más (escenas, entradas, mocks) es justo lo que queda fuera de estos tests. GUT dice soportar Godot 4.7, es GDScript solo y su ejecutor es un script que se lanza como cualquier otra herramienta del proyecto (`--script`, como `gen_ui_tokens.gd`). Se elige GUT.

### Instalación

- **Versión exacta: 9.7.1**, la última de la línea 9.7 (la de Godot 4.7) al escribir esta spec. Si al implementar la página de versiones enseña un parche más nuevo de la 9.7, se le dicen las dos al usuario y se usa la que él diga.
- **Descarga con permiso.** Es la única descarga del plan. Antes de bajarla se le dice al usuario: el archivo, su origen (la página oficial `github.com/bitwes/Gut/releases`, la etiqueta 9.7.1) y su tamaño, y se espera un sí. Sin ese sí no se instala nada y el plan se para.
- Se descarga en una carpeta vacía y propia de la carpeta de pruebas, no en el repositorio. Del archivo solo se copia `addons/gut/` (y su licencia) a `addons/gut/` del proyecto.
- **Se guarda en el repositorio.** CI no descarga GUT: usa la copia de `addons/gut/`. Así cada ejecución usa la misma versión y no depende de la red.
- **No se activa su plugin** en `project.godot`: el trabajo se hace sin editor y el ejecutor no lo necesita.
- **Fuera de las exportaciones:** `addons/gut/*`, `tests/*` y `.gutconfig.json` se añaden al `exclude_filter` de `Web`, `Windows Desktop` y `Linux`.
- **No rompe nada de lo que hay:** `check_ui_values.gd` solo mira `res://scripts` y el `runtime` del design system (`design_system.json`), así que ni GUT ni `tests/` le afectan. La importación y las carreras del piloto no deben enseñar ningún `ERROR` ni `WARNING` nuevo.
- **`.gutconfig.json`** en la raíz: los directorios (`res://tests/`, con subcarpetas), el prefijo `test_`, el sufijo `.gd` y salir al acabar.

## 2. Qué se prueba

### La regla

- **Sí:** las reglas puras de `scripts/game/`, `scripts/battle/`, `scripts/story/` y las consultas de `scripts/world/` (`ZoneData`, `EncounterMeter`), y la coherencia de los datos de `data/`.
- **No:** nodos, escenas, constructores (`WorldStage`, `CreatureBuilder`, `UiTheme`…), interfaz, imagen, sonido, el piloto automático, archivos (`SaveStore`, opciones en disco) ni `InputMap` (`KeyMap`).
- Los tests no tocan `user://`. Ningún test llama a `SaveStore`, `FileAccess` ni `DirAccess`.
- Nunca cambian un recurso cargado (`data/*.tres`): trabajan con `GameState.new()`, que duplica el héroe, con duplicados o con combatientes hechos en el propio test.

### La primera tanda (unos 160 tests)

Por riesgo y por lo que ya se rompió antes:

| Área | Archivo | Qué comprueba | Tests |
|---|---|---|---|
| Partidas guardadas | `tests/game/test_save_data.gd` | Ida y vuelta por JSON de una partida de la parte 1 y otra de la parte 3; **cada versión de 2 a 16 carga** (las 2 a 8 fallaban: QA2-01); el Incienso retirado se vende al cargar (3.7.0); la EXP se recorta al tope al cargar (3.8.0); los PV del Slime de Metal; el accesorio único de antes del 1.6.0 va a su hueco; `medal_prizes` de antes de la 3.6.0 empieza en 0; partidas falsas rechazadas (18 casos); importar basura o una versión más nueva; la línea de la ranura. Marcados 3.8.2: números enormes recortados a 9 999 999, base64 malo, portal de otra parte quitado, `is_newer()` | 22 |
| Opciones | `tests/game/test_game_options.gd` | Volúmenes recortados, lo que falta queda por defecto, ida y vuelta | 3 |
| Combate | `tests/battle/test_battle_engine.gd` | Daño dentro del margen (golpe y crítico); defender divide; hechizos que crecen un 3 % por nivel (3.5.0) y los de enemigos no; debilidad y resistencia; los objetos van primero (3.5.0); huida (fórmula y límites, nunca ante un jefe); sin sorpresa ante jefe ni Slime de Metal; veneno, Fácil, inmunidad, silencio de tres rondas; Pluma de fénix una vez; fase de jefe; EXP de Fácil; medallas (Slime de Metal siempre, jefe nunca, tope); objetos de misión | 20 |
| Niveles | `tests/game/test_leveling.gd` | Subir y aprender (y sustituir Ascuas); topes 20, 40 y 60 con la EXP recortada; levantar el tope; la tabla; `set_level()`; textos de EXP | 10 |
| Estado de partida | `tests/game/test_game_state.gd` | Tope por parte, tienda y compañero por etapa, oro perdido, jefe y objeto clave una vez, Slime de Metal, portal | 8 |
| Dificultad y encuentros | `tests/game/test_difficulty.gd`, `tests/world/test_encounter_meter.gd` | Multiplicadores; la timidez a 4 niveles de la salida | 4 |
| Versión | `tests/game/test_game_version.gd` | `check()` número a número (3.10 > 3.9), textos que no se leen, `current()` | 6 |
| Objetos y equipo | `tests/game/test_inventory.gd`, `tests/game/test_loadout.gd` | Curar con tope, por qué no se puede usar algo, Elixir, semillas; bonos, ATK extra, inmunidades, ida y vuelta | 11 |
| Tiendas | `tests/game/test_shop.gd` | Comprar, sin oro, ×5, vender a la mitad, lo puesto no se vende, semillas y objetos de misión no, premios por tienda (2.4.1), compañeros y criaturas; qué tienda abre cada paso y qué serie vende cada una; la Pluma no se vende | 13 |
| Misiones | `tests/game/test_quest_log.gd` | Ofrecida solo en su parte y antes de su `gone`; contar y entregar; recoger; la misión del pueblo; cuentas por parte; ida y vuelta. Marcados 3.8.2: las 8 de la Caravana con `gone`, perdidas, «n/m» | 15 |
| Tierras que se cierran | `tests/game/test_closing_lands.gd` (3.8.2) | Las siete tierras y sus zonas; ninguna tras el Eco ni los jefes de la v1; cerrada o no; lo que falta y el aviso | 5 |
| Historia | `tests/story/test_story_state.gd` | Parte, tramo, etapa, capítulo, lo que dice Orvalla, el nombre, escenas vistas, ida y vuelta | 9 |
| Bestiario y medallas | `tests/game/test_bestiary.gd`, `tests/game/test_medals.gd` | 5 / 9 / 13 familias y 22 / 47 / 71 fichas; familia completa y su premio una vez; premios cada 4, el Coleccionista (primera vez, en otro pueblo, todas); la probabilidad por parte | 10 |
| Mundo | `tests/game/test_wells.gd`, `test_chests.gd`, `test_allies.gd`, `test_run_flags.gd` | Pozos secos 10 combates; cofres una vez y 13 / 25 / 37 por parte; compañeros que crecen y su equipo; las opciones de la línea de órdenes | 13 |
| Datos | `tests/data/test_data_integrity.gd` | `QuestLog.problems()` vacío; enemigos, salidas, tiendas y posadas de cada zona; misiones, cofres y tiendas apuntan a cosas que existen; cada pieza con tienda se vende en alguna; las IA de los enemigos solo nombran órdenes o hechizos suyos; familias sin repetir; premios del Coleccionista; escenas con archivo; objetos clave con texto; hechizos del héroe | 13 |

### Errores que habrían cazado

- Las partidas de la 1.0 y anteriores rechazadas (QA2-01): el test de versiones 2 a 16.
- La EXP que se perdía al pasar del tope (antes de la 3.8.0): los topes y la EXP al cargar.
- Las misiones de la Caravana ofrecidas con su tierra cerrada (QA1-01): el `gone` de las ocho.
- Un premio de anillo o amuleto que valía 0 G al venderlo (2.4.1), el Incienso retirado (3.7.0), los premios del Coleccionista contados con la tabla vieja (3.6.0).
- Una errata en un dato (un enemigo de un grupo, una salida, una IA, una tienda) que el piloto solo ve si pasa por ahí: los tests de datos.

### El azar

- `BattleEngine` recibe su `RandomNumberGenerator` en `_init()`. El test crea uno con `seed` y se lo pasa: no hay que tocar el juego.
- Los tests nunca fijan los números de una semilla. Hacen una de dos cosas:
  - comprobar un límite sobre muchas semillas (200): «todo golpe normal hace entre 26 y 34»;
  - montar un combate en el que el azar no decide: un enemigo que solo se tambalea, un hechizo de estado con probabilidad 1, un enemigo con velocidad 999.
- Así un cambio en el orden de las tiradas no rompe los tests; uno en las fórmulas, sí.
- Una regla nueva con azar recibe su generador como `BattleEngine` (nunca `randi()` global), para que se pueda probar.

### Los valores fijados

Algunos tests fijan valores del diseño: la tabla de EXP, los topes, el precio de venta de los premios, cuántas misiones y cofres tiene cada parte. Es a propósito: un cambio de equilibrio que los mueve cambia el test en el mismo commit, y así se ve en el diff.

### Si un test de datos falla

La 3.9.0 no cambia el juego. Si un test, escrito contra el código fusionado, encuentra un error de verdad en los datos o en una regla, la tarea se para y se informa. Nunca se afloja un test para que pase. El arreglo va aparte, con su línea en el CHANGELOG, o el test se quita si el que estaba mal era él.

## 3. Carpetas y nombres

```
tests/
  fixtures.gd                  ## constructores: estado, combatiente, hechizo, motor, guardado
  battle/test_battle_engine.gd
  game/test_<script>.gd        ## uno por regla: save_data, leveling, shop, quest_log...
  story/test_story_state.gd
  world/test_encounter_meter.gd
  data/test_data_integrity.gd  ## la coherencia de data/, que no es de un solo script
.gutconfig.json
addons/gut/                    ## GUT 9.7.1, tal cual
```

- Un archivo por script de regla, con el nombre del script: `scripts/game/shop.gd` → `tests/game/test_shop.gd`.
- Cada archivo empieza por `extends GutTest` y un comentario `##` que dice qué prueba. Sin `class_name`: `tests/` no es parte del juego y no entra en la caché de clases.
- Cada test es `func test_<lo que debe pasar>() -> void:`, en inglés como el resto del código, y dice en su nombre lo que comprueba.
- `tests/fixtures.gd` se carga con `const Fx := preload("res://tests/fixtures.gd")`.
- Los tests marcados 3.8.2 llevan un comentario `# 3.8.2 (M-1xx)` encima.

## 4. Cómo se ejecutan

### En local

Desde Git Bash en la raíz, con la carpeta de datos redirigida a mano (GUT escribe sus temporales en `user://`, que en el PC es la carpeta de las partidas):

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-390/appdata" ./tools/godot.cmd --headless --path . --script res://addons/gut/gut_cmdln.gd
```

- Sale con 0 si todo pasa y con 1 si algo falla, y escribe el resumen de GUT.
- Una línea `ERROR` o `SCRIPT ERROR` en la salida también es un fallo aunque el código sea 0 (un test que no compila).
- Tarda segundos.

### En GitHub Actions

- Flujo propio, `.github/workflows/tests.yml`, en cada subida a `develop` y a mano. No va dentro de `autoplay.yml`: aquel juega cinco carreras largas en una matriz; este acaba en un par de minutos y su resultado se lee aparte.
- Instala Godot 4.7.2 como `autoplay.yml`, importa y ejecuta la misma orden con `XDG_DATA_HOME` en la carpeta temporal del runner.
- El paso falla si el código de salida no es 0 o si la salida tiene `ERROR`. Guarda la salida y el informe JUnit como el artefacto `tests`.
- No bloquea ni publica nada, como `autoplay.yml`. En `main` no se pasa: lo que llega a `main` ha pasado por `develop`.

## 5. Las reglas nuevas

### CLAUDE.md

La sección «No tests — ever» pasa a «Tests». En una línea: **los cambios de reglas puras llevan sus tests en el mismo commit; los tests nunca sustituyen al piloto automático.** En detalle:

- Qué se prueba (reglas puras y datos) y qué nunca (nodos, escenas, constructores, imagen, sonido, archivos, `InputMap`).
- Cuándo:
  - un cambio en una regla pura añade o cambia sus tests en el mismo commit;
  - un script de regla nuevo trae su `tests/<carpeta>/test_<script>.gd`;
  - un fallo de una regla se arregla con un test que falla sin el arreglo;
  - un cambio de datos que mueve un valor fijado cambia ese test a propósito.
- Cómo: GUT, `tests/` como `scripts/`, `fixtures.gd`, el azar con semilla, sin `user://`, sin tocar recursos cargados.
- Dónde se pasan: en cada tarea que toca reglas o datos, al cerrar cada versión y en CI. No en el hook de pre-commit.
- El piloto: `autoplay_all.sh` sigue siendo la comprobación del juego, y una versión pasa las dos cosas.
- Lo de verificar a mano sigue igual para todo lo demás (escenas, interfaz, imagen): `--check-only`, ejecutar, fotogramas, las dos comprobaciones del design system.
- La orden, en «Commands», y `addons/gut/` y `tests/` en «Layout».

### Los planes de boost

- Un plan puede tener pasos de test, pero solo para reglas y datos. La tarea que cambia una regla escribe o cambia sus tests y los pasa antes de su commit.
- Para un fallo de una regla, primero el test que falla y luego el arreglo (el TDD de boost vale aquí). Para lo demás, los tests acompañan al cambio en la misma tarea.
- La verificación de un plan sigue incluyendo el piloto automático. Los tests no la sustituyen.
- Nunca pasos de test para nodos, escenas o lo visual: eso se sigue mirando a mano.

### Otros documentos

- **La guía de QA** (`docs/brief-qa-agentes.md`): la regla 2 ya no dice que el proyecto no quiere tests. El proyecto tiene tests de reglas (GUT, `tests/`) que mantiene el equipo: el agente de QA los puede ejecutar, no añadir ni cambiar. Sus scripts propios siguen fuera del repositorio.
- **La skill del piloto:** una viñeta de la 3.9.0. Los tests no sustituyen a estas carreras, y una versión pasa las dos cosas.
- El CHANGELOG y el documento maestro.

## 6. Fuera de alcance

- Tests de nodos, escenas, interfaz, cámara, imagen, sonido o rendimiento, y el ejecutor de escenas de cualquier marco.
- `SaveStore` y las opciones en disco: escriben en `user://`. El guardado de verdad lo sigue comprobando la carrera `save` del piloto.
- `KeyMap`: cambia el `InputMap` del motor, que no es una regla pura.
- La lógica del piloto (`GameAutoplay`, `BattleAutoplay`), `Shop.autoplay_picks()` incluido.
- Cifras de cobertura y tests de cada función.
- Mocks y dobles: las reglas puras se prueban con objetos de verdad.
- Pasar los tests en el hook de pre-commit, en `main`, en Windows o en `pages.yml` y `release.yml`.
- Cambiar código del juego para poder probarlo: no hace falta ninguno.

## Verificación

- Instalación:
  - el permiso del usuario para la descarga, con archivo, origen y tamaño;
  - `--import` sin `ERROR` ni `WARNING` de `addons/gut/`;
  - un test que falla a propósito (fuera del commit) da código 1, y quitado vuelve a dar 0.
- Cada tarea de tests: la orden de §4 con código 0, sin `ERROR` en la salida, y el número de tests que GUT cuenta.
- Ningún test usa `user://`, `SaveStore`, `FileAccess` ni `DirAccess`: lo comprueba un `grep`.
- La exportación no lleva GUT ni `tests/`: un `--export-pack` del preset `Windows Desktop` no contiene sus rutas.
- `gen_ui_tokens.gd -- --check` y `check_ui_values.gd` siguen en 0.
- Todas las carreras del piloto con `autoplay_all.sh`, en OK y sin `WARNING` nuevos: GUT no debe cambiar nada del juego. `autoplay_expected.json` no se toca.
- CI: queda para el usuario ver la primera ejecución de `tests.yml` en GitHub tras subir `develop`, porque subir lo decide él.
- CLAUDE.md, la skill del piloto, la guía de QA, el CHANGELOG y el documento maestro, al día.
