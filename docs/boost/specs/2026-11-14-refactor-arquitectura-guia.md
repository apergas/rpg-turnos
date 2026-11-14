# Guía del refactor de arquitectura

Acompaña al [spec](2026-11-14-refactor-arquitectura-design.md). El spec dice **qué** se mueve y **adónde**. Esta guía dice **en qué orden**, **cómo se mueve cada cosa sin romper nada** y **cómo se comprueba**, sin tests.

Se trabaja en `feature/refactor-arquitectura`, sacada de `develop` cuando la 2.7.0 ya esté fusionada. Todas las órdenes ponen `APPDATA` a una carpeta de pruebas escrita tal cual, para no tocar nunca las partidas reales:

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd ...
```

## 0. La referencia, antes de tocar nada

Sobre `develop` sin cambios, con los registros en una carpeta fuera del repo:

| Qué | Orden (tras `--path .`) | Se guarda |
|---|---|---|
| v1 entera | `--headless --fixed-fps 10 --quit-after 150000 -- --autoplay` | `v1.log` |
| v2 entera | `--headless --fixed-fps 10 --quit-after 500000 -- --autoplay --autoplay-zone=caravana` | `v2.log` (unos 20 min) |
| Medallas | `--headless --fixed-fps 10 --quit-after 60000 -- --autoplay --autoplay-zone=medallas` | `medallas.log` |
| Eco | `--headless --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=eco` | `eco.log` |
| Guardado | `--headless --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-save` | las líneas `Guardado:` y `Cargado:` |
| Menú de pausa | `--write-movie <dir>/f.png --fixed-fps 10 --quit-after 140 -- --autoplay --autoplay-menu` | los fotogramas de cada página |
| Móvil | `--resolution 740x360 -- --touch`, a mano: mapa, combate, tienda y pausa | capturas |
| Retratos | `--script res://scripts/tools/bestiary_shots.gd` (sin `--headless`) | `git status assets/bestiary` debe quedar limpio |

**Las partidas automáticas no salen iguales línea a línea**, porque hay azar sin semilla fija. Lo que se compara en cada registro es:

1. **Cero `ERROR` y cero `WARNING` nuevos.** Solo se acepta el aviso conocido de Jolt.
2. **Los hitos, en el mismo orden.** Se sacan con:

   ```bash
   grep -E '^(Zona|Escena|Lugar|Compañero|Pregunta|Misión cumplida|Juego completado|Medallas|Eco de la Niebla)' x.log
   ```

3. **Los números finales dentro del margen de siempre:** nivel igual y tiempo dentro de la variación habitual (unos 5 minutos).
4. **El guardado, igual en la ida y en la vuelta.** `Guardado:` y `Cargado:` deben ser idénticos.
5. **Los retratos, iguales píxel a píxel.** Si algo cambia, `git status assets/bestiary` lo enseña. Antes de empezar se ejecuta dos veces sobre `develop` para confirmar que sale siempre igual. Si no fuera así, se comparan a ojo.

Los puntos 1 y 2 se miran a mano. Se pasa el `grep` de arriba a los dos registros (la referencia y el nuevo) y se comparan las dos listas con `diff`, junto con un `grep -E 'ERROR|WARNING'` de cada uno.

## Orden de los pasos

De menos a más riesgo. Los pequeños y transversales van primero porque dejan el terreno limpio para los grandes.

| Paso | ID | Riesgo | Qué |
|---|---|---|---|
| 1 | M-74 | bajo | `RunFlags` y las regiones de autoplay |
| 2 | M-73 | nulo | Cabeceras `## Constructor:` y la convención en `CLAUDE.md` |
| 3 | M-72 | medio | `BattleActor`: datos, constructores y primitivas |
| 4 | M-71 | alto | `World`, de pieza en pieza |
| 5 | M-70 | alto | `Game`, de pieza en pieza (necesita a `World` estable) |
| 6 | | | La pasada final: las cinco comprobaciones de la referencia, más `CLAUDE.md` y `CHANGELOG.md` |

Cada fila de las tablas del spec es **un commit**, como mucho. Si una pieza sale grande (`MapUses`, `FigureTalk`), se parte en dos commits, y el juego tiene que funcionar entre los dos.

## Cómo se mueve una pieza

Es la misma receta para todas.

1. **Crear el archivo de la pieza** con su `class_name`, su tipo y un `setup()` que reciba lo que necesita. Nunca recibe al dueño.
2. **Cortar y pegar las funciones tal cual.** Se les quita el guion bajo a las que el dueño seguirá llamando. Lo único que se cambia dentro son los accesos:
   - `state.` pasa a `_ctx.state.`;
   - `_world.` pasa a `_ctx.world.`;
   - lo que la pieza emitía como señal del dueño ahora lo emite como señal propia.
3. **Dejar en el dueño una fachada de una línea** por cada función pública que antes estaba ahí:

   ```gdscript
   func show_notice(text: String, word := "Aviso", tone := &"text-info") -> void:
       _hud.show_notice(text, word, tone)
   ```

4. **Pasar las variables que solo usa la pieza.** Si el dueño también las lee, la pieza las expone con un `get` (`var groups: Array: get = ...`) y el dueño la lee a través de ella. Nunca debe haber una copia de la variable en cada lado.
5. **Crear la pieza en el dueño**, en el mismo punto del `_ready()` donde antes se construía lo que ahora contiene. Así se respeta el orden de los nodos, que importa para el dibujo, la entrada y el `process`.
6. **Importar y validar:**

   ```bash
   ./tools/godot.cmd --headless --path . --import
   ```

   ```bash
   ./tools/godot.cmd --headless --path . --check-only --script res://<pieza>.gd
   ```

   La validación se pasa a la pieza y también a su dueño.
7. **Ejecutar la partida automática que pasa por esa pieza** (ver la tabla siguiente) y compararla con la referencia.
8. **Actualizar `CLAUDE.md`:** la entrada del dueño pierde las funciones que se fueron y gana una línea que lo dice («... en `MapHud`»), y la pieza nueva tiene su propia entrada en *Layout*.
9. **Commit**, con un mensaje que diga qué se movió y adónde, sin atribuciones.

## Qué ejecutar después de cada pieza

| Pieza | Partida mínima | Qué mirar además |
|---|---|---|
| `RunFlags` | todas las de la referencia, una vez | que `--debug`, `--touch` y `--autoplay-companion=tadeo` sigan funcionando |
| `ActorLooks`, `CreatureBuilder`, `CharacterBuilder` | `bestiary_shots.gd` y la v1 con `--write-movie` (600 fotogramas) | retratos idénticos; el héroe con equipo, el casco, los cuernos del Yelmo, la gente de la caravana y las alas del grifo |
| `MapHud` | v1 en ventana y el móvil a mano | estado, misiones, aviso, cartel del lugar, cuadro del mapa y botón de uso |
| `MapMonsters`, `AutoplayHunter` | v1 y `medallas` | `Grupos: n`, `Grupo vencido (quedan n)`, `Grupo repuesto (n)`, el Slime de Metal en la mina |
| `MapUses`, `MapFigures`, `MapProps` | v1 y `jungla` | hablar, comprar, la posada, los pozos, los cofres, la palanca, la llave y la reja; las marcas «!» y «?»; el portal del Ala |
| `ZoneTravel` | v1 y `--autoplay-save` | cada `Zona:`, el Ala y su portal, la derrota y la vuelta al pueblo |
| `BattleFlow`, `BattleRewards` | v1, `eco` y `ciudad` | oro, misiones, medallas, jefes, familias, Slime de Metal y la segunda fase del Devorador |
| `FigureTalk`, `CaravanFlow` | v1 y `caravana` (hasta `Zona: jungla`) | las entregas, el Coleccionista, las dos preguntas del Jefe, el compañero |
| `StoryFlow`, `CreditsData` | v1 entera y v2 entera | cada `Escena:`, los créditos y `Juego completado` / `Juego completado (v2)` |
| `GameAutoplay`, `AutoplayStarts` | cada `--autoplay-zone` una vez | la retirada al pueblo, el reabastecimiento, `Grupos repuestos` |
| `GameDebug` | `-- --debug` en ventana, a mano | cada botón imprime su `Depuración: ...` |

## Trampas conocidas

- **`await` en piezas nuevas.** Si una función que hace `await` pasa a otro nodo y ese nodo se libera a medias (en `_switch_zone`, al volver al título), la corrutina muere en silencio. Las piezas de `Game` viven lo mismo que `Game`. Nunca se hacen hijas del `World`, que se libera en cada cambio de zona.
- **El mundo cambia y la pieza se queda.** `SessionContext.world` se actualiza en `_switch_zone` antes de conectar las señales del mapa nuevo. Ninguna pieza guarda el mundo en una variable propia.
- **El orden dentro de `_physics_process`.** `World` llama a las piezas en el orden de hoy. Si una pieza tuviera su propio `_physics_process`, el orden dependería del árbol: por eso no lo tienen.
- **`PROCESS_MODE` y pausa.** Las piezas heredan el modo de su dueño. `GameDebug` y lo que trabaje con el árbol en pausa necesitan `PROCESS_MODE_ALWAYS`, como hoy `DebugPanel` y `PauseMenu`.
- **`static var`** (`World.debug_no_groups`, `Vegetation.half_density`...). Se mueven con su clase y se deja un alias en el sitio viejo solo si alguien de fuera los lee.
- **La caché de clases.** Cada `class_name` nuevo necesita `--import` antes del primer `--check-only`. Si un `--check-only` dice que no encuentra una clase recién creada, falta ese paso.
- **El tamaño de la exportación web.** Al acabar se exporta una vez la versión web, para confirmar que `index.pck` no cambia de tamaño de forma notable y que no hay errores nuevos en la consola del navegador.

## Cuándo parar

- Si una pieza obliga a cambiar una regla, un texto o el resultado de una partida para encajar, **no se mueve**. Se apunta en el spec como excepción, con el motivo, y se pasa a la siguiente.
- Si después de dos intentos una partida automática da hitos distintos de la referencia, se deshace el paso (`git reset --hard` al commit anterior, siempre en la rama del refactor) y se replantea la pieza antes de seguir.
- Las metas de líneas (600, 700, 900) son orientativas. Mejor una pieza de más que una pieza a medias.
