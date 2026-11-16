# Versión 3.8.1: el juego se prueba solo

Fecha: 2026-11-16. Estado: spec. Cubre M-108, M-109 y M-110 del [documento maestro](../documento-maestro.md). Va después de la 3.8.0. El juego no cambia para el jugador, salvo lo que exija el arreglo del cuelgue. La partida guardada sigue en la **versión 16**.

## Objetivo

1. **Sin cuelgues en el piloto automático (M-108).** A veces una carrera sin ventana del piloto automático se queda parada para siempre, justo después del aviso de Jolt («Jolt Physics job system exceeded the maximum number of jobs»). Pasa en una de cada seis carreras de la v3, y en más si van varias a la vez. Se busca la causa y se arregla.
2. **Un lanzador de todas las carreras (M-109).** Una sola orden juega a la vez las partidas completas del piloto automático y el guardado de ida y vuelta. Al acabar da un resumen con OK o FALLO en cada una, comparando con lo medido.
3. **Integración continua (M-110).** El mismo lanzador se ejecuta en GitHub Actions cada vez que se sube `develop`. Así una regresión se ve sin tener que lanzar nada a mano.

## Decisiones tomadas (2026-11-16)

| Tema | Decisión |
|---|---|
| Qué es «probar» aquí | Jugar el juego con el piloto automático y mirar el resultado, como hasta ahora. No son tests unitarios: esos tendrán su propio spec, después de esta versión |
| Qué carreras | La v1 entera, la v2 entera, la v3 entera (final «Devolver el amuleto»), el final «Acabar con el Eco» (desde `albor` con `--autoplay-ending=vencer`) y el guardado de ida y vuelta |
| Dónde se lanza | En tu PC (Git Bash) y en GitHub Actions (Ubuntu), con el mismo script |
| Cuándo en GitHub | En cada push a `develop` y a mano desde la pestaña Actions. No en `main`: allí ya publica Pages, y lo que llega a `main` ha pasado antes por `develop` |
| Si falla en GitHub | El job sale en rojo y deja los registros de cada carrera como artefacto. No bloquea nada ni publica nada |

## 1. Sin cuelgues (M-108)

- Primero se reproduce el cuelgue y se mira si el proceso está parado (CPU a 0) o en un bucle (CPU alta). Después se prueban las hipótesis una a una:
  - el sistema de trabajos de Jolt se bloquea al quedarse sin trabajos;
  - quedan cuerpos físicos sin liberar entre zonas;
  - hay demasiados pasos de física por fotograma con `--fixed-fps 10`;
  - una espera del piloto automático no termina nunca.
- El arreglo va a la causa, no esconde el síntoma. Si es un ajuste del proyecto, lleva un comentario que lo explique y no puede empeorar el juego con ventana ni la web, que va en un solo hilo.
- Si el aviso de Jolt desaparece o cambia de significado, se corrige la línea «Known noise» de CLAUDE.md.
- **Prueba de que está arreglado:** seis carreras `brumaclara` (de dos en dos o de tres en tres, que es cuando más se colgaba) llegan todas a «Juego completado (v3)». Además, una v1 y una v2 completas sin errores nuevos.

## 2. El lanzador (M-109)

### Cómo se usa

```bash
scripts/tools/autoplay_all.sh            # todas las carreras, en paralelo
scripts/tools/autoplay_all.sh v3 save    # solo esas
```

- Cada carrera tiene un nombre (`v1`, `v2`, `v3`, `vencer`, `save`) y se lanza en segundo plano con su propia carpeta de datos temporal. Así nunca toca la partida real:
  - en Windows, `APPDATA` apunta a una carpeta nueva bajo `%TEMP%`;
  - en Linux, `XDG_DATA_HOME`.
- `GODOT` dice qué ejecutable usar: por defecto `./tools/godot.cmd` en Windows y `./godot` en Linux. `JOBS` dice cuántas carreras van a la vez: por defecto 3.
- Cada carrera tiene un tiempo máximo real. Si se pasa, se mata su proceso y sale como **FALLO (colgada)**.

### Qué se comprueba

Lo que se espera de cada carrera está en un archivo de datos junto al script, `scripts/tools/autoplay_expected.json`:

| Carrera | Orden | Debe acabar con | Nivel | Derrotas como mucho |
|---|---|---|---|---|
| `v1` | `--autoplay` | `Juego completado:` | 18 | 3 |
| `v2` | `--autoplay-zone=caravana` | el fin de la v2 (la línea que imprime hoy) | 40 | 3 |
| `v3` | `--autoplay-zone=brumaclara` | `Juego completado (v3):` | 53 ± 1 | 2 |
| `vencer` | `--autoplay-zone=albor --autoplay-ending=vencer` | `Pregunta: ... -> Acabar con el Eco` y `Juego completado (v3):` | 53 ± 1 | 1 |
| `save` | `--autoplay --autoplay-save` (corta) | `Guardado:` y `Cargado:` iguales, con `"version":16` | — | — |

- Una carrera es **OK** si:
  - acaba con su línea;
  - el nivel cae en su margen y las derrotas no pasan del máximo;
  - el tiempo de juego no se aleja más de un 20 % de lo medido;
  - y no hay ninguna línea `ERROR` ni ninguna `WARNING`, salvo la de Jolt mientras CLAUDE.md la dé por conocida.
- Si falla, el resumen dice qué ha fallado («nivel 49, se esperaba 52-54», «ERROR: … en la línea 812 del registro», «colgada a los 40 min»).
- Al acabar escribe una tabla con cada carrera: nombre, OK o FALLO, nivel, tiempo de juego, derrotas, tiempo real y la ruta de su registro. Si alguna falla, sale con código 1.
- Los registros se guardan en una carpeta temporal y en local no se borran, para poder mirarlos.
- Lo medido (niveles y tiempos) sale de la skill `villaclaro-autoplay`. Cada versión que cambie el equilibrio actualiza `autoplay_expected.json` en su tarea de publicación, igual que hoy actualiza la skill.

### Dónde va

- `scripts/tools/autoplay_all.sh` y `scripts/tools/autoplay_expected.json`. `scripts/tools/` ya está fuera de la exportación.
- El script es Bash, para que el mismo funcione en Git Bash y en Ubuntu. No necesita nada que no esté en Git for Windows ni en el runner de GitHub: `jq` está en el runner; en Windows, si no está, el script lee el JSON con `sed` o el propio Godot lo pasa a líneas.
- La skill `villaclaro-autoplay` y CLAUDE.md (Commands) explican cómo usarlo.

## 3. Integración continua (M-110)

- Un flujo nuevo, `.github/workflows/autoplay.yml`, que se lanza con `push` a `develop` y con `workflow_dispatch`.
- Una matriz con una carrera por job (`v1`, `v2`, `v3`, `vencer`, `save`), para que vayan en paralelo en máquinas distintas.
- Cada job:
  1. instala Godot 4.7.2 igual que `pages.yml`, sin plantillas de exportación;
  2. ejecuta `--import`;
  3. ejecuta `scripts/tools/autoplay_all.sh <carrera>`;
  4. sube el registro como artefacto (`actions/upload-artifact`), falle o no.
- `timeout-minutes` por job: el tiempo máximo de la carrera más un margen, como mucho 120.
- `concurrency` por rama, con `cancel-in-progress`: si se sube otra vez `develop`, la ejecución anterior se cancela.
- El job usa `--fixed-fps 10` y el modo sin ventana, igual que en local. Sus tiempos reales serán otros, pero lo que se compara es el tiempo de juego, no el real.

## Verificación

- `--check-only` en lo que cambie de GDScript.
- El lanzador en local: todas las carreras en OK. Además, se fuerza un fallo de prueba para ver el FALLO, el código 1 y el mensaje: un margen imposible en una copia temporal del JSON, sin guardarla.
- El flujo de GitHub se prueba de verdad al subir `develop` con la versión fusionada: la ejecución debe quedar toda en verde. Antes se valida su YAML (`actionlint` si está, si no leyéndolo con cuidado) y se ensaya en local lo mismo que ejecuta cada job.
- La skill, CLAUDE.md, el CHANGELOG (una línea: «Sin cambios en el juego: el piloto automático ya no se cuelga y el juego se prueba solo en cada subida») y el documento maestro, al día.
