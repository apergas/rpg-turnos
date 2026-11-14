# Versión 2.7.1: el design system generado y vigilado

Fecha: 2026-11-14. Estado: spec. Versión técnica: el jugador no ve ningún cambio. La partida guardada no cambia (versión 14).

## Objetivo

Que el design system (`docs/boost/design-system/`) sea la única fuente de verdad de la interfaz y que el código no pueda desincronizarse de él, como manda la skill de arquitectura (`structuring-godot-code`, `topics/ui-data-scenes.md`): "si el proyecto tiene un archivo de tokens, la clase de tokens se genera desde él" y "ningún `Color(...)` ni tamaño de letra a mano en la interfaz".

Hoy:
- `scripts/ui/ui_tokens.gd` dice ser generado, pero se mantiene a mano.
- `docs/boost/design-system/godot/` guarda tres copias `.txt` de scripts que ya han cambiado en el juego.
- Quedan transparencias y colores de efectos escritos a mano.
- Nada comprueba nada.

## 1. El generador

- **`scripts/tools/gen_ui_tokens.gd`** es una herramienta, como las demás de `scripts/tools/`: queda fuera de la exportación, se ejecuta con `godot --headless --path . --script` y no usa ninguna clase del juego.
  - Lee `docs/boost/design-system/tokens.json` y escribe **todo** `scripts/ui/ui_tokens.gd`:
    - los colores de los dos temas, resolviendo las referencias `{token}`;
    - las escalas de espaciado, radio, borde, contorno, tamaño, capa y opacidad;
    - la tipografía: la tabla `TYPE`, las familias y las rutas de las letras;
    - la sombra;
    - las funciones `color()` y `type_size()` y `high_contrast`.
  - No queda ningún bloque escrito a mano en `ui_tokens.gd`. Lo que hoy está en el "bloque propio del juego" pasa a `tokens.json`: el valor en Godot de la sombra (`shadow_size`, `shadow_offset`) y la ruta `res://` de cada letra.
  - Con `-- --check` no escribe: compara lo que generaría con el archivo y sale con error si difieren, diciendo cuál.
- El `ui_tokens.gd` generado da los mismos nombres y valores que el actual, así que el resto del código no cambia por esto.
- Se borra `docs/boost/design-system/godot/`, con `ui_tokens.gd.txt`, `ui_theme.gd.txt` y `menu_cursor.gd.txt`. La documentación apunta a los scripts reales de `scripts/ui/`.

## 2. La comprobación de valores a mano

- **`scripts/tools/check_ui_values.gd`** es otra herramienta. Recorre los scripts y falla, diciendo archivo y línea, cuando encuentra:
  - un `Color(` en `scripts/ui/` (salvo el `ui_tokens.gd` generado) o en `scripts/title/`;
  - un `add_theme_color_override` con un `Color(` literal en cualquier script;
  - un `add_theme_font_size_override` o un `font_size` con un número literal en cualquier script.
- Los colores del mundo 3D (madera, agua, cielo, niebla, las figuras) quedan fuera a propósito: no son interfaz. Viven en `ZoneData` y en los builders. El design system lo dice explícitamente.

## 3. Que no se desincronice nunca

- **Antes de cada commit:** un hook versionado, `.githooks/pre-commit`, ejecuta las dos herramientas cuando el commit toca `tokens.json`, `scripts/ui/`, `scripts/title/` o algún `.gd`. Se activa una vez por clon con `git config core.hooksPath .githooks`, escrito en CLAUDE.md. Usa `tools/godot.cmd` si existe y, si no, `godot` del PATH.
- **En la CI:** `.github/workflows/pages.yml` ejecuta las dos herramientas antes de exportar. Si algo está desincronizado o hay un valor a mano, no se publica.
- **En cada versión:** las dos herramientas entran en las comprobaciones de CLAUDE.md.

## 4. Valores a mano que pasan al design system

Cada valor entra primero en `tokens.json` y en su documentación, y después se regenera:

| Dónde | Hoy | Token nuevo o existente |
|---|---|---|
| `battle_actor.gd` `FADED_TRANSPARENCY` 0.5 | a mano | `opacity-faded` (ya existe y describe justo esto) |
| `name_entry.gd` `EMPTY_ALPHA` 0.45 | a mano | `opacity-placeholder` 0.45 (nombre aún sin escribir) |
| `map_square.gd` `ALPHA` 0.8 | a mano | `opacity-map-picture` 0.8 (la imagen del mapa dentro del cuadro) |
| fundidos `Color(0, 0, 0, 0)` en `title_screen.gd` y `game.gd` | a mano | `black` con alfa 0 |
| fila del título con tamaño de letra puesto a mano en `title_screen.gd` | `add_theme_font_size_override` | una variación del tema (`UiTheme`) para las filas de la portada |
| `battle_scene.gd` brillos de estado y efecto (veneno, sueño, silencio, aturdido, defender, carga, despertador) | siete `Color(...)` | `effect-poison`, `effect-sleep`, `effect-silence`, `effect-stun`, `effect-defend`, `effect-charge`, `effect-wake`, con los valores de hoy en los dos temas |

Los tokens de efecto son distintos de `status-*`: `status-*` son fondos oscuros de insignia con texto blanco, y los efectos son brillos claros sobre las figuras 3D. Con los valores de hoy, nada cambia en pantalla.

## 5. Documentación

- **`5-godot.md`**, reescrito: cómo está montado de verdad.
  - `tokens.json` → generador → `UiTokens` → `UiTheme` → pantallas.
  - Las dos herramientas y el hook.
  - El límite: el mundo 3D queda fuera.
  - Cómo añadir un token: editar `tokens.json`, documentarlo, regenerar y usarlo.
- **`2-fundamentos.md`:** las filas de los tokens nuevos (efectos y opacidades).
- **`README.md`:** sin la carpeta `godot/`.
- **CLAUDE.md:**
  - la entrada de `UiTokens` dice que el archivo es generado del todo;
  - la convención de UI nombra el generador, la comprobación y el hook;
  - en Comandos: generar, comprobar y activar el hook.
- **El documento maestro:** una fila de la 2.7.1.

## Verificación

- `gen_ui_tokens.gd` deja `ui_tokens.gd` igual en nombres y valores. Tras regenerar, `--check` pasa.
- `check_ui_values.gd` pasa en el código final y falla si se le añade a propósito un `Color(` en `scripts/ui/`. Esa prueba se deshace después.
- El hook bloquea un commit con `tokens.json` cambiado sin regenerar. Se prueba en una rama de usar y tirar.
- Después: `--import`, `--check-only` de los scripts tocados, la ida y vuelta del guardado y un combate grabado con `--write-movie`, para ver que los brillos de estado y la transparencia de los grupos siguen igual.
