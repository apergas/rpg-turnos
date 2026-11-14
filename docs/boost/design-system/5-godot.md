# Implementación en Godot

Un solo camino lleva un valor de la interfaz hasta la pantalla:

```
tokens.json  →  gen_ui_tokens.gd  →  UiTokens  →  UiTheme  →  pantallas
(fuente)        (generador)          (generado)   (el Theme)   (variaciones y UiTokens.color())
```

## Las piezas

| Pieza | Archivo | Qué es |
| --- | --- | --- |
| `tokens.json` | `docs/boost/design-system/tokens.json` | La única fuente: paleta, semánticos de los dos temas, escalas, tipografía y sombra. Cada token lleva su `usage`. |
| Generador | `scripts/tools/gen_ui_tokens.gd` | Escribe `ui_tokens.gd` entero desde `tokens.json`. No usa clases del juego. |
| `UiTokens` | `scripts/ui/ui_tokens.gd` | **Generado: no se edita a mano.** Colores de los dos temas (`UiTokens.color(&"text-accent")`; con `UiTokens.high_contrast` devuelve el de alto contraste), escalas como constantes (`SPACE_4`, `RADIUS_M`, `BORDER_3`, `OUTLINE_M`, `TOUCH_TARGET`, `LAYER_HUD`, `OPACITY_WINDOW`, `TYPE_BODY_SIZE`…), `TYPE`, rutas de las fuentes y la sombra de ventana. |
| `UiTheme` | `scripts/ui/ui_theme.gd` | El único `Theme` del juego, construido desde `UiTokens`. `apply()` lo pone sobre el tema por defecto (lo llama `DisplaySettings.apply()`; `ensure()` para escenas que corren solas) y lo rehace en vivo si cambia «Alto contraste». |
| Pantallas | `scripts/ui/`, `scripts/title/`… | Piden estilo al tema; no escriben valores. |

## UiTheme

- **Variaciones de `Label`**: `TITLE`, `SECTION`, `SMALL`, `CAPTION`, `NOTE`, `REASON`, `MONEY`, `POSITIVE`, `NEGATIVE`, `BADGE`, `MICRO`, `OUTLINED`, `DISPLAY`, `DISPLAY_SUB`. Se usan con `label.theme_type_variation = UiTheme.CAPTION`.
- **Variaciones de ventana y botón**: `WINDOW_MAP`, `CARD`, `SELECTED_ROW`, `SELECTOR`, `KEY`, `CARD_HIT`, `MENU_BUTTON`, `TITLE_ROW`, `ACTION_BUTTON`, `STATUS_LINE`.
- **Estilos sueltos**: `window_style()`, `map_style()`, `selected_style()` (fondo de la fila elegida), `badge_style(status)`.
- **Ayudantes**:
  - `font_for(style)`: Nunito (`ui`) o Baloo 2 (`display`) según el estilo;
  - `style_label(label, style, color, outline)`: fuente, tamaño, color y contorno de un `Label` con tokens;
  - `style_3d(label3d, ...)`: lo mismo para un `Label3D` (letra de Baloo 2, a la misma altura en el mundo);
  - `menu_row(button)`: una fila de menú plana, con sangría para el cursor y del tamaño de un dedo en móvil;
  - `add_cursor(window)`: pone un `MenuCursor` en una ventana con filas;
  - `row_indent()`.
- Un `Control` bajo un `CanvasLayer` solo recibe el tema por defecto, por eso `apply()` hace `merge_with` sobre `ThemeDB.get_default_theme()`.

## Piezas compartidas

- **`MenuCursor`** (`scripts/ui/menu_cursor.gd`): el ▶ dorado dibujado (no es un glifo, así se ve igual en la web) sobre la fila con foco de su ventana, sea con teclado, ratón o dedo. Solo dibuja el cursor; el fondo de la fila elegida es el estilo de foco del botón (`UiTheme.selected_style()`).
- **`FocusRow`** (`scripts/ui/focus_row.gd`): una fila de varios controles (nombre, selector, deslizador) que pinta ese mismo fondo mientras algo dentro de ella tiene el foco. Así las opciones se ven como las demás filas.
- **`StatBar`** (`scripts/ui/stat_bar.gd`): una barra del héroe con su texto encima. `StatBar.HP`, `MP` y `EXP` son nombres de token (`stat-hp`, `stat-mp`, `stat-exp`); es la regla «un color, un significado». Con PV por debajo del 25 % el relleno late y el texto pasa a `text-danger`.

## Qué queda fuera del design system

Los colores del mundo 3D no son tokens: `ZoneData` (cielo, niebla, suelo, sol), los constructores (`WorldStage`, `BattleStage`, `DungeonMap`, `LowPoly`) y los modelos. Son contenido del juego, no interfaz.

Sí son del design system:
- los brillos de efecto sobre las figuras en combate (`effect-defend`, `effect-charge`, `effect-wake`, `effect-poison`, `effect-sleep`, `effect-silence`, `effect-stun`), que no son los `status-*` (esos son las insignias);
- los colores de elemento (`element-*`: fuego, hielo, rayo, curación).

## Las comprobaciones

| Qué | Comando | Falla si… |
| --- | --- | --- |
| `gen_ui_tokens.gd -- --check` | `godot --headless --path . --script res://scripts/tools/gen_ui_tokens.gd -- --check` | `ui_tokens.gd` no es idéntico a lo que escribiría el generador (dice la primera línea distinta). |
| `check_ui_values.gd` | `godot --headless --path . --script res://scripts/tools/check_ui_values.gd` | hay `Color(` en `scripts/ui/` o `scripts/title/` (salvo `ui_tokens.gd`), un `add_theme_color_override` con `Color(`, o un tamaño de letra literal en cualquier script. Lista cada `archivo:línea`. |

Para regenerar: `godot --headless --path . --script res://scripts/tools/gen_ui_tokens.gd`.

Las dos se ejecutan:
- **Antes de cada commit**, con `.githooks/pre-commit`, solo si lo preparado incluye `tokens.json` o algún `.gd`. Se activa una vez por clon con `git config core.hooksPath .githooks`. Usa `tools/godot.cmd` si existe o `godot` del PATH; sin Godot avisa y deja pasar.
- **Antes de publicar**, en el paso «Import and export» de `.github/workflows/pages.yml`, justo después de `--import`. Si fallan, no se publica nada.

Ambas herramientas son de desarrollo y quedan fuera de la exportación.

## Cómo añadir un token

1. Edita `tokens.json`: añade el token (y su color en la paleta si hace falta) con su `usage`, y el valor de `alto-contraste` si es un semántico.
2. Documéntalo en `2-fundamentos.md` y en la página del componente que lo usa.
3. Regenera: `godot --headless --path . --script res://scripts/tools/gen_ui_tokens.gd`.
4. Úsalo: `UiTokens.color(&"nuevo")` o `UiTokens.NUEVO`. Nunca escribas el valor en un script.
5. Añade `tokens.json` y `scripts/ui/ui_tokens.gd` al mismo commit: el hook lo exige.
