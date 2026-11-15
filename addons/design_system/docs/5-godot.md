# Implementación en Godot

Un solo camino lleva un valor de la interfaz hasta la pantalla:

```
base.json + tokens.json  →  gen_ui_tokens.gd  →  UiTokens  →  DsTheme + el tema del juego  →  pantallas
(núcleo)    (juego)          (generador)          (generado)   (el Theme)                      (variaciones y UiTokens.color())
                                   ↓
                              tokens.css  →  bundle.css del núcleo y del juego
                              (generado)     (las fichas)
```

## Las piezas

| Pieza | Dónde | Qué es |
| --- | --- | --- |
| `base.json` | `addons/design_system/tokens/` | Los tokens genéricos, con valores neutros. |
| `tokens.json` | el juego (`tokens` en `design_system.json`) | Lo del juego: `"extends"` el `base.json`, su paleta, sus fuentes, sus tokens y, en `"overrides"`, el valor que da a los del núcleo. |
| `design_system.json` | la raíz del juego | Todas las rutas que leen las herramientas y el hook. |
| Generador | `addons/design_system/tools/gen_ui_tokens.gd` | Junta las dos capas y escribe enteros `UiTokens` y `tokens.css`. No usa clases del juego. |
| `UiTokens` | el juego (`gd_out`) | **Generado: no se edita a mano.** Siempre `class_name UiTokens`: el núcleo lo usa. Los colores de los dos temas en dos diccionarios con el id de cada tema en mayúsculas (`UiTokens.color(&"text-accent")`; con `UiTokens.high_contrast`, el de alto contraste), las escalas como constantes (`SPACE_4`, `RADIUS_M`, `BORDER_3`, `OUTLINE_M`, `TOUCH_TARGET`, `TYPE_BODY_SIZE`…), `TYPE`, `FAMILY_DISPLAY` y `FAMILY_UI`, `FONT_DISPLAY_PATH` y `FONT_UI_PATH` (vacías si el juego no da letra) y la sombra de ventana. |
| `tokens.css` | el juego (`css_out`) | **Generado.** Las variables CSS (`--text-accent`, `--space-4`…) de los `bundle.css`: los colores del tema normal en `:root` y, en `[data-theme="…"]`, los que cambian en alto contraste. |
| `DsTheme` | `addons/design_system/runtime/ds_theme.gd` | La base del `Theme`, construida desde `UiTokens`. |
| `MenuCursor` | `addons/design_system/runtime/menu_cursor.gd` | El cursor ▶ de cada ventana con filas. |
| El tema del juego | el juego | Hereda de `DsTheme` y añade lo suyo. |

## DsTheme

Un constructor estático (`## Constructor:`). Solo depende de `UiTokens` y `MenuCursor`.

- `apply(window, high_contrast, extend)`: pone el tema sobre el tema por defecto (un `Control` bajo un `CanvasLayer` solo recibe ese, por eso hace `merge_with` sobre `ThemeDB.get_default_theme()`), con la letra `ui` en `body` para todos los tipos. Lo rehace en vivo si cambia el alto contraste. `ensure(window, extend)` lo pone una vez, para escenas que corren solas. `build(extend)` devuelve el `Theme`. `extend` es un `Callable` que recibe el `Theme` y le añade lo del juego.
- `DsTheme.touch`: `true` en un móvil o una tableta. Lo pone el juego antes de `apply()` o `ensure()`; si en algún camino llama a `ensure()` o `apply()` de `DsTheme` sin pasar por el tema propio del juego, debe ponerlo antes también ahí. Con él, las filas miden `touch-target` × `touch-min-width` y el cursor se acerca al borde.
- **Variaciones de `Label`**: `TITLE`, `SECTION`, `SMALL`, `CAPTION`, `NOTE`, `REASON`, `MONEY`, `POSITIVE`, `NEGATIVE`, `BADGE`, `MICRO`, `OUTLINED`. Se usan con `label.theme_type_variation = DsTheme.CAPTION` (o por el nombre del tema del juego, que las hereda).
- **Variaciones de ventana y botón**: `CARD`, `SELECTED_ROW`, `SELECTOR`, `KEY`, `CARD_HIT`, `MENU_BUTTON`, `TITLE_ROW`, `ACTION_BUTTON`, `STATUS_LINE`.
- **Estilos sueltos**: `window_style()`, `selected_style()` (fondo de la fila elegida), `row_style()`.
- **Ayudantes**: `font_for(style)` (la letra de un estilo: familia, peso y, en `display`, el interlineado recortado), `font(path, weight)`, `style_label(label, style, color, outline)`, `style_3d(label3d, ...)`, `menu_row(button)` (una fila de menú plana, con sangría para el cursor y del tamaño de un dedo en móvil; el ratón mueve la selección), `add_cursor(window)` y `row_indent()`.

### El tema del juego

```gdscript
class_name GameTheme extends DsTheme

static func apply(window: Window, high_contrast := false, extend := Callable()) -> void:
	DsTheme.touch = OS.has_feature("mobile")  # lo decide el juego
	DsTheme.apply(window, high_contrast, _extend if extend.is_null() else extend)


static func _extend(theme: Theme) -> void:
	theme.set_type_variation(&"MapWindow", &"PanelContainer")
```

`ensure()` y `build()` se redefinen igual. En GDScript una función estática no se despacha por la subclase, por eso lo del juego entra con el `Callable` y no sobrescribiendo funciones de `DsTheme`; y una función estática redefinida debe tener la misma firma que la de `DsTheme` (GDScript lo comprueba). Las pantallas siguen llamando a todo por el nombre del tema del juego: lo heredado también se llama así.

## MenuCursor

El ▶ dibujado (no es un glifo, así se ve igual en la web) sobre la fila con foco de su ventana, sea con teclado, ratón o dedo. Sigue a un botón de menú o, si el foco está en un selector (`SELECTOR`) o un deslizador, a la fila que lo contiene. Las teclas y las tarjetas dibujan su propio marco y no llevan cursor. No dibuja el fondo de la fila elegida: es el estilo de foco del botón (`selected_style()`). Se pone con `add_cursor(window)`.

## Las comprobaciones

| Qué | Comando | Falla si… |
| --- | --- | --- |
| `gen_ui_tokens.gd -- --check` | `godot --headless --path . --script res://addons/design_system/tools/gen_ui_tokens.gd -- --check` | `UiTokens` o `tokens.css` no son idénticos a lo que escribiría el generador (dice la primera línea distinta); un token del juego pisa uno del núcleo o un override nombra uno que el núcleo no tiene; un token del núcleo no está escrito como `` `nombre` `` en el `2-fundamentos.md` o `components/*.md` del núcleo, o uno del juego o un override, en los del juego (lista los nombres); o un `bundle.css` usa un `var(--x)` que `tokens.css` no define, o el del núcleo una variable que no es del núcleo. |
| `check_ui_values.gd` | `godot --headless --path . --script res://addons/design_system/tools/check_ui_values.gd` | hay `Color(` en un archivo de `color_dirs` (salvo `gd_out`), un `add_theme_color_override` con `Color(` o un tamaño de letra literal en cualquier `.gd` de `scan_roots`. Lista cada `archivo:línea`. |

Para regenerar: `godot --headless --path . --script res://addons/design_system/tools/gen_ui_tokens.gd`. Con `-- --files` solo escribe, una por línea, las rutas que vigila el hook (`ds-file: source|generated|docs <ruta>`).

Las dos herramientas empiezan `_init` con `quit(1)`: si fallan por dentro (un JSON roto), Godot no se queda colgado. Son de desarrollo y quedan fuera de la exportación.

## El hook y la publicación

`hooks/pre-commit`, que el juego llama desde su `.githooks/pre-commit`:

1. Si lo preparado no tiene ningún `.gd`, `.json`, `.md` ni `.css`, no hace nada.
2. Busca Godot (`tools/godot.cmd` o `godot` del PATH; sin él avisa y deja pasar) y le pide a `gen_ui_tokens.gd -- --files` qué rutas vigilar.
3. Si lo preparado no toca ninguna de ellas ni un `.gd`, no hace nada.
4. Falla si las fuentes (`base.json`, `tokens.json`, `design_system.json`) o los generados tienen cambios sin añadir: las comprobaciones leen el árbol de trabajo, no lo preparado.
5. Pasa las dos comprobaciones. Cada llamada a Godot lleva `timeout 120` si existe `timeout`.

La publicación las repite después de `--import`; si fallan, no se publica.

## Cómo añadir un token

1. Decide la capa: uno que valga para cualquier juego va en `base.json` y en estas guías; uno de un solo juego, en el `tokens.json` del juego y sus guías. Para darle otro valor a uno del núcleo, `"overrides"`.
2. Escríbelo con su `usage` (y su valor de alto contraste si es un color semántico).
3. Documéntalo como `` `nombre` `` en el `2-fundamentos.md` o la ficha del componente de su capa: `--check` falla si falta.
4. Regenera.
5. Úsalo: `UiTokens.color(&"nuevo")` o `UiTokens.NUEVO`. Nunca escribas el valor en un script.
6. Añade el archivo de tokens y los dos generados al mismo commit: el hook lo exige.
