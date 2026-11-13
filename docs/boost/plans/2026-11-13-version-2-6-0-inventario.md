# Versión 2.6.0 / 2.6.1: inventario de la interfaz (anexo del plan)

Anexo de `docs/boost/plans/2026-11-13-version-2-6-0.md`. Todo valor visual escrito a mano en la interfaz de hoy (rama `feature/version-2-6-0`, versión 2.5.0), con el token o el estilo que lo sustituye y la tarea que lo cambia. Los números de línea son los de la rama de partida: **busca siempre por el texto citado**, las líneas se mueven.

Columnas: `archivo:línea` · lo que hay hoy · a qué pasa · tarea (A3 = Parte A, Task 3...).

Notación: `c(x)` = `UiTokens.color(&"x")`; `T.X` = constante de `UiTokens` (`T.SPACE_4`, `T.OUTLINE_M`...); `V.X` = variación de `UiTheme` (`UiTheme.TITLE`...); «estilo `body`» = el tamaño, la familia y el peso del estilo de tipo (`UiTheme.style_label(label, &"body", ...)` o la variación que lo lleva).

## 0. Reglas de traducción (valen para todo lo que no esté en una tabla)

- **Tamaños de letra** (los 13 de hoy y los dos sueltos): 16 → `micro` · 18 → `caption` · 20 → `label` · 22 → `label` · 24 → `body` · 26 → `title-s` · 28 → `title-s` · 30 → `title-m` · 34 → `title-l` · 36 → `title-l` · 40 → `title-l` (pantalla) · 44 → `display-m` · 48 → `display-m` · 64 → `display-l` · 72 → `display-l` · 96 → `display-xl`. `title-l`, `title-m` y los tres `display-*` son de la familia `display` (Baloo 2); el resto, `ui` (Nunito).
- **Sin tamaño hoy:** el tema por defecto del motor da `font_size` 16 a **cada** tipo (medido: `Label`, `Button`, `Label3D`, `LineEdit`... tienen 16 propio). Con `UiTheme` puesto, un `Label` o `Button` sin tamaño pasa a `body` 24. Pasa en `ChoiceWindow` (pregunta y respuestas, `choice_window.gd:39`, `:46`) y en `DebugPanel` (título `debug_panel.gd:82`, botones `:208`): crecen de 16 a 24 (es lo que pide el design system).
- **Contornos:** 4 → `T.OUTLINE_S` · 6 → `T.OUTLINE_M` · 8 → `T.OUTLINE_M` · 10 → `T.OUTLINE_L` · 12 → `T.OUTLINE_L` · 14 → `T.OUTLINE_L` · 16 → el que diga el componente (números de daño y marcas: `T.OUTLINE_M`) · 18 → `T.OUTLINE_XL`.
- **Separaciones** (`separation`, `h_separation`, `v_separation`): al token más cercano, y los valores intermedios **hacia abajo** (protege el alto en el móvil): 0 → 0 · 2 → 0 · 4 → `T.SPACE_1` · 6 → `T.SPACE_1` · 8 → `T.SPACE_2` · 10 → `T.SPACE_2` · 12 → `T.SPACE_3` · 16 → `T.SPACE_4` · 24 → `T.SPACE_6` · 48 → `T.SPACE_12`.
- **Márgenes de pantalla:** 24 → `T.SPACE_6`; 12 (rincón pequeño) → `T.SPACE_3`; separación entre ventanas 16 → `T.SPACE_4`.
- **Anchos de composición** (`*_WIDTH`, `*_RESERVED`, `*_SIDE`, `KEY_SIZE`...): si valen lo mismo que un token, pasan al token (`window-w-s` 240, `-m` 360, `-l` 480, `-xl` 640, `-max` 1000, `bar-width` 220, `map-size` 150, `menu-button` 64, `touch-min-width` 120, `touch-target` 56, `enemy-bar-*`); si no, **se quedan** como constante con nombre en su archivo (son la composición de esa pantalla, no un estilo). Las tablas dicen cuáles cambian de valor.
- **Alfas sueltas** (0.45 del nombre vacío, 0.35 / 0.6 del pad táctil): se quedan como constante con nombre; el color base sale de un token.
- **Mundo 3D:** cielo, suelo, figuras, luces, partículas, fuego, cofres, pozos, arcos, el brillo de estado de los combates (`battle_scene.gd:40-50`), el resplandor de apuntar (`battle_actor.gd:75`), los colores de `BeyondScreen` (`beyond_screen.gd:22-35`, `:166`, `:219`, `:304-306`) **no entran**.
- **Fundidos a negro** (`game.gd:1768`, `title_screen.gd:522`): no son interfaz, se quedan `Color(0, 0, 0, a)` (excepción anotada en el plan).

## 1. Capas de pantalla (`CanvasLayer.layer`) — Task A3

| archivo:línea | hoy | pasa a |
|---|---|---|
| `scripts/title/title_screen.gd:90-91` | `hint_layer.layer = 100` («Gira la pantalla») | `T.LAYER_SYSTEM` |
| `scripts/title/title_screen.gd:370` | `_ui = CanvasLayer.new()` (capa 1 por defecto) | `_ui.layer = T.LAYER_HUD` explícito |
| `scripts/title/title_screen.gd:518-519` | `layer.layer = 20` (fundido del título) | `T.LAYER_TITLE_FADE` |
| `scripts/story/beyond_screen.gd:345-346` | `layer.layer = 9` | `T.LAYER_CINEMATIC` |
| `scripts/world/world.gd:1571` | `_ui = CanvasLayer.new()` (1) | `T.LAYER_HUD` explícito |
| `scripts/battle/battle_scene.gd:158` | `var ui := CanvasLayer.new()` (1) | `T.LAYER_HUD` explícito |
| `scripts/game/game.gd:1152-1153` | créditos de la v1, `11` | `T.LAYER_OVERLAY` |
| `scripts/game/game.gd:1192-1193` | créditos de la v2, `11` | `T.LAYER_OVERLAY` |
| `scripts/game/game.gd:1743-1744` | tienda (y elección de compañero), `4` | `T.LAYER_SHOP` |
| `scripts/game/game.gd:1764-1765` | fundido, `10` | `T.LAYER_FADE` |
| `scripts/game/game.gd:1775-1776` | pausa, `5` | `T.LAYER_PAUSE` |
| `scripts/game/game.gd:1795-1796` | depuración, `6` | `T.LAYER_DEBUG` |

No hace falta ninguna capa nueva. (El design system dice que la elección de compañero va en `layer-overlay`; en el código es la tienda «Compañeros», capa 4. Se queda en `T.LAYER_SHOP`; ver «Correcciones».)

## 2. Estilos de caja (`StyleBox`) y tema

| archivo:línea | hoy | pasa a | tarea |
|---|---|---|---|
| `scripts/ui/battle_hud.gd:313-327` `make_window()` | `StyleBoxFlat` a mano: `Color(0.04, 0.04, 0.12, 0.9)`, marco blanco 3, radio 8, margen 14 × 10 | fachada: `PanelContainer.new()` sin override + `mouse_filter = IGNORE`; el estilo sale de `UiTheme.window_style()` (`c(surface-window)`, `T.BORDER_3` `c(border-window)`, `T.RADIUS_M`, `T.SPACE_4` × `T.SPACE_3`, sombra) | A3 |
| `scripts/ui/battle_hud.gd:47` `WINDOW_MARGIN := Vector2(14, 10)` | margen interior | se borra; sus usos (`_set_message()` `:340`) pasan a `T.SPACE_4` | A3 |
| `scripts/ui/battle_hud.gd:709-723` `_badge()` | `StyleBoxFlat` (radio 4, margen 6), texto 16 blanco | `UiTheme.badge_style(&"status-…")` + `V.BADGE` | A6 |
| `scripts/ui/battle_hud.gd:484-494` `_shrink_row()` | duplica los estilos del tema por defecto y les pone margen | sigue igual (lee el tema ya fusionado); `FONT_SIZE` → `T.TYPE_BODY_SIZE` | A6 |
| `scripts/ui/display_settings.gd:12-15`, `:51-65` `_set_touch_buttons()` | margen de 56 y foco vacío en el tema por defecto, solo en móvil | **se borra**: lo hace `UiTheme.build()` (`Device.is_touch()`: filas de `T.TOUCH_TARGET`; el foco ya no es vacío, es la fila elegida). `TOUCH_BUTTON_HEIGHT` queda como alias de `T.TOUCH_TARGET`; `BUTTON_FONT` se borra; `BUTTON_STYLES` se queda (lo usa `_shrink_row()`) | A3 |
| `scripts/ui/map_square.gd:42-48` | `StyleBoxFlat` `BACK` / `BORDER`, borde 2, radio 4 | `theme_type_variation = V.WINDOW_MAP` (sin override) | A5 |
| `scripts/ui/pause_menu.gd:499-501`, `:520-526` `_menu_button_style()` | tres `StyleBoxFlat` con alfa 0.75 / 0.9 / 1 | `theme_type_variation = V.MENU_BUTTON` (normal `c(surface-window)`, hover y pulsado `c(surface-window-solid)`, marco `T.BORDER_3`, `T.RADIUS_M`, sombra) | A7 |
| `scripts/world/world.gd:1669-1682` `_use_button` | `Button` sin estilo (gris del motor), letra 28, 180 × 72 | `theme_type_variation = V.ACTION_BUTTON` (pastilla `T.RADIUS_FULL`, `c(surface-window)`, marco `T.BORDER_3`, letra `title-s`); tamaño `USE_BUTTON_SIZE` se queda (lo dice InteractionPrompt) | A3 (variación puesta) · A5 (estilo final) |
| `scripts/ui/options_panel.gd:188-205` `_choice_row()` | botones con `toggle_mode` y el gris del motor | `theme_type_variation = V.SELECTOR` (texto `caption`; el elegido: fondo `c(border-focus)`, texto `c(surface-window-solid)`) | A3 (variación puesta) · A7 |
| `scripts/ui/options_panel.gd:171-185` `_volume_row()` | `HSlider` del motor, 260 × 32 | estilo del tema (`slider` `c(surface-track)` de 8 px, `grabber_area` `c(border-focus)`); 260 se queda | A3 (tema) · A7 |
| `scripts/ui/name_entry.gd:194-200` `_button()` (teclas) | `Button` del motor 58 × 50, letra 26 | `theme_type_variation = V.KEY` (fondo `c(surface-selected)` y marco `T.BORDER_2` `c(border-focus)` con foco; sin hueco de cursor); letra `body` | A3 (variación) · A8 |

## 3. Colores escritos a mano

### `scripts/ui/ui_style.gd` (fachada) — A3

| línea | hoy | pasa a |
|---|---|---|
| `:5` `TITLE_COLOR` | `Color(1.0, 0.85, 0.3)` | se borra; títulos con `V.TITLE` |
| `:6` `GREY` | `Color(0.6, 0.6, 0.65)` | se borra; `V.CAPTION` (`c(text-secondary)`) o `V.REASON` (`c(text-disabled)`) según sea descripción o motivo |
| `:7` `TEXT_SIZE` 18 | | se borra; `V.CAPTION` / `T.TYPE_CAPTION_SIZE` |
| `:9-10` `DESCRIPTION_WIDTH` 340 / `TOUCH_DESCRIPTION_WIDTH` 240 | | `T.WINDOW_W_M` 360 (MenuList: «descripción... ancho window-w-m») / 240 se queda (`T.WINDOW_W_S`) |
| `:21-22` `add_small_text()` | tamaño 18 + `GREY` | `label.theme_type_variation = V.CAPTION` |
| `:37` `TOUCH_BUTTON_WIDTH` 120 | | `T.TOUCH_MIN_WIDTH` |

### `scripts/ui/stat_bar.gd` (fachada) — A3

| línea | hoy | pasa a |
|---|---|---|
| `:6-8` `HP` / `MP` / `EXP` | `Color(0.8, 0.16, 0.16)` / `(0.2, 0.4, 0.92)` / `(0.18, 0.62, 0.26)` | **nombres de token**: `const HP := &"stat-hp"`, `MP := &"stat-mp"`, `EXP := &"stat-exp"`; `StatBar.new(token)` guarda el nombre y lee `UiTokens.color()` en `_draw()` (#cc2929 / #3366eb / **#237a33**) |
| `:9` `GOLD` | `Color(1.0, 0.8, 0.25)` | se borra; `V.MONEY` (`c(text-money)` #ffcc40) |
| `:11` `EXP_TEXT` | `Color(0.4, 0.9, 0.48)` | se borra; `V.POSITIVE` (`c(text-positive)`) |
| `:12` `BACK` | `Color(0, 0, 0, 0.55)` | `c(surface-track)` (#0000008c, el mismo 0,55) |
| `:13` `BAR_SIZE` 220 × 30 | | `Vector2(T.BAR_WIDTH, T.BAR_HEIGHT)` |
| `:14` `FONT_SIZE` 20 | | `T.TYPE_LABEL_SIZE`, letra `UiTheme.font_for(&"label")` en vez de `get_theme_default_font()` |
| `:15` `OUTLINE` 4 | | `T.OUTLINE_S` |
| `:58-60` | contorno `Color.BLACK`, texto `Color.WHITE` | `c(text-outline)`, `c(text-on-fill)` |

### `scripts/ui/battle_hud.gd` — A6 (salvo lo dicho en A3)

| línea | hoy | pasa a |
|---|---|---|
| `:28` `FONT_SIZE` 24 | | `T.TYPE_BODY_SIZE` (o se borra: el tema ya da 24) |
| `:29` `BADGE_FONT_SIZE` 16 | | `V.BADGE` (`micro`) |
| `:31` `MENU_WIDTH` 240 | | `T.WINDOW_W_S` |
| `:33` `TOUCH_BAR_WIDTH` 170 | | se queda (el token `bar-width` dice «170 px en móvil») |
| `:34` `TOUCH_ALLY_BAR_WIDTH` 110 | | se queda (HeroPanel: «barra de PV de 110 px») |
| `:38-39` `EDGE` 24 / `GAP` 16 | | `T.SPACE_6` / `T.SPACE_4` |
| `:41` `ENEMY_BAR_SIZE` 96 × 8 | | `Vector2(T.ENEMY_BAR_WIDTH, T.ENEMY_BAR_HEIGHT)` |
| `:43` `TARGET_NAME_COLOR` | `Color(1.0, 0.9, 0.3)` | `c(text-accent)` |
| `:45` `ENEMY_BAR_BACK` | `Color(0, 0, 0, 0.7)` | `c(surface-track)` (0,55: un poco más claro, lo pide EnemyBar) |
| `:61-63` `BADGES` | `Color(0.5, 0.2, 0.65)` / `(0.2, 0.35, 0.8)` / `(0.4, 0.4, 0.45)` | nombres de token `&"status-poison"` / `&"status-sleep"` / `&"status-silence"` (+ `STUN` `&"status-stun"` «Aturdido» en B3) |
| `:168` | `fill.color = StatBar.HP` | `c(stat-hp)` |
| `:177-180` | nombre del enemigo: 18, `TARGET_NAME_COLOR`, contorno negro 6 | EnemyBar: `label` (20), `c(text-accent)`, contorno `T.OUTLINE_S` `c(text-outline)` |
| `:473-474` | filas: 24 y `font_disabled_color` `Color(0.5, 0.5, 0.55)` | sin overrides (tema: `body`, `c(text-disabled)`) |
| `:722-723` | insignia 16 blanca | `V.BADGE` |
| `:741-742` | `_label()` 24 blanco | sin overrides |
| `:636-689` | separaciones 4 / 10 / 4 / 8 / 8 / GAP / 0 | regla de separaciones (10 → `T.SPACE_2`) |

### `scripts/ui/battle_result.gd` — A6

| línea | hoy | pasa a |
|---|---|---|
| `:17` | velo `Color(0, 0, 0, 0.55)` | `c(surface-scrim)` (0,5) |
| `:22` | `make_window()` | `V.CARD` (radio `T.RADIUS_L`: «resultado del combate») |
| `:27` | separación 10 | `T.SPACE_2` |
| `:28` | título 40 | estilo `title-l` (Baloo 2), `c(text-accent)` |
| `:37` | «Continuar» 24 | sin override (fila del tema) |
| `:48` | `+n EXP` `StatBar.EXP_TEXT` | `V.POSITIVE` |
| `:50`, `:54`, `:66` | `Color.WHITE` | sin override |
| `:52`, `:65` | oro `StatBar.GOLD` | `V.MONEY` |
| `:93-96` `_label()` | tamaño + blanco | sin override de color |

### `scripts/ui/bestiary_page.gd` — A7

| línea | hoy | pasa a |
|---|---|---|
| `:17` `SILHOUETTE` | `Color(0.05, 0.05, 0.1)` (modulate del retrato) | `c(surface-window-solid)` |
| `:21` `PART_SIZE` 26 | | `V.TITLE` (`title-s`) |
| `:23` `TITLE_SIZE` 20 | | estilo `label` |
| `:63` | `StatBar.GOLD` si completa, si no `UiStyle.TITLE_COLOR` | título de familia `V.SECTION` (`label`, `c(text-accent)`); completa, con el color `c(text-positive)` (override: no cambia en alto contraste). El oro es dinero y no se usa aquí; la palabra del premio ya dice que está completa — ver «Correcciones» del plan |
| `:72` | `Color.WHITE` | sin override |
| `:85-86` | 8 / 8 | `T.SPACE_2` |
| `:157` | nombre de la tarjeta 18 | `V.NOTE` (`caption` en `c(text-primary)`) |

### `scripts/ui/choice_window.gd` — A5 (fila y letra), B2 (componente)

| línea | hoy | pasa a |
|---|---|---|
| `:9` `WIDTH` 460 | | `T.WINDOW_W_L` 480 |
| `:11` `TOUCH_WIDTH` 300 | | se queda (ChoiceWindow: «300 px en móvil») |
| `:28` | velo `Color(0, 0, 0, 0.35)` | `c(surface-scrim)` |
| `:37` | 10 / 4 | `T.SPACE_2` / `T.SPACE_1` |
| `:39`, `:46` | sin tamaño (16 hoy) | tema: `body` 24 |

### `scripts/ui/credits_screen.gd` — A8

| línea | hoy | pasa a |
|---|---|---|
| `:11` `HEADING_COLOR` | `Color(1.0, 0.85, 0.3)` | `c(text-accent)` (encabezados), `c(text-display)` («Fin»/«Continuará») |
| `:12` `HEADING_SIZE` 30 | | `title-m` (Baloo 2) |
| `:13` `LINE_SIZE` 26 | | `title-s` (Nunito 800) en `c(text-primary)` |
| `:14` `END_SIZE` 72 | | `display-l` 64 |
| `:18` `SECTION_GAP` 48 | | `T.SPACE_12` |
| `:38` | fondo `Color.BLACK` | `c(surface-window-solid)` (Window: «créditos, final: opaca») |
| `:43` | separación 6 | `T.SPACE_1` |
| `:61` | `Color.WHITE` | `c(text-primary)` |

### `scripts/ui/debug_panel.gd` — A7

| línea | hoy | pasa a |
|---|---|---|
| `:28` `ROW_WIDTH` 720 | | se queda |
| `:67` | velo `Color(0, 0, 0, 0.5)` | `c(surface-scrim)` |
| `:82-84` | título sin tamaño, `TITLE_COLOR` | `V.TITLE` |
| `:192-193` | sección 18 `TITLE_COLOR` | `V.SECTION` (`label` 20, `c(text-accent)`: encabezado pequeño) |
| `:208-214` | botones del motor 16 | filas del tema (`UiTheme.menu_row()`), `body` |
| `:219` | línea 18 | `V.CAPTION` |

### `scripts/ui/dialogue_box.gd` — A5 (letra y color), B2 (▼)

| línea | hoy | pasa a |
|---|---|---|
| `:9` `FONT_SIZE` 24 | | tema (`body`) |
| `:10` `SPEAKER_COLOR` | `Color(1.0, 0.85, 0.3)` | `V.TITLE` (`title-s`, `c(text-accent)`) |
| `:12` `MAX_WIDTH` 1000 | | `T.WINDOW_W_MAX` |
| `:13` `BOTTOM` 24 | | `T.SPACE_6` |
| `:15` `SIDE_ROOM` 76 | 2 × 24 + 2 × 14 | `2 * T.SPACE_6 + 2 * T.SPACE_4` (80) |
| `:41` | `Color.WHITE` | sin override |

### `scripts/ui/difficulty_window.gd` — A8

| línea | hoy | pasa a |
|---|---|---|
| `:9` `FONT_SIZE` 26 | | título `V.TITLE`; filas del tema (`body`) |
| `:29` | 8 | `T.SPACE_2` |
| `:31` | `UiStyle.TITLE_COLOR` | `V.TITLE` |
| `:38` | `UiStyle.GREY`, 18 | `V.CAPTION` |
| `:66-71` `_button()` | `flat`, 26 | `UiTheme.menu_row()` |

### `scripts/ui/journal_page.gd` — A7

| línea | hoy | pasa a |
|---|---|---|
| `:9` `HEADING_SIZE` 22 | | `V.SECTION` (`label` 20, `c(text-accent)`) |
| `:10` `ENTRY_SIZE` 20 | | estilo `label` (`V.SMALL`) |
| `:11-13` | `TEXT_SIZE`, `TITLE_COLOR`, `GREY` | `V.CAPTION` / `V.SECTION` |
| `:15` `TEXT_WIDTH` 720 | | se queda |
| `:28`, `:33`, `:39`, `:42` | `Color.WHITE` | `V.SMALL` / `V.CAPTION` según el tamaño que tenían |
| `:31`, `:34`, `:37` | `GREY` | `V.CAPTION` (`:31`, `:37` tenían 20: pasan a `caption` 18 — son notas, no entradas) |

### `scripts/ui/keys_panel.gd` — A7

| línea | hoy | pasa a |
|---|---|---|
| `:9` `FONT_SIZE` 24 | | tema |
| `:29`, `:33` | 6 / 8 | `T.SPACE_1` / `T.SPACE_2` |
| `:30` | «Teclas» `UiStyle.TITLE_COLOR` | `V.TITLE` |
| `:35`, `:43` | `Color.WHITE` | sin override |
| `:118-123` `_button()` | botón del motor | `UiTheme.menu_row()` |

### `scripts/ui/map_square.gd` — A5

| línea | hoy | pasa a |
|---|---|---|
| `:11` `SIDE` 150 | | `T.MAP_SIZE` |
| `:12` `TOUCH_SIDE` 110 | | se queda (MapSquare: «110 px en móvil») |
| `:13` `BACK` | `Color(0.04, 0.04, 0.12, 0.45)` | `V.WINDOW_MAP` (`c(surface-map)`) |
| `:14` `BORDER` | `Color(1, 1, 1, 0.7)` | `V.WINDOW_MAP` (`c(border-map)`) |
| `:17` `MARKER_COLOR` | `Color.WHITE` | `c(map-hero)` |
| `:16`, `:18` | 7 / 5 px | se quedan (MapSquare: marcas de 5 px) |

### `scripts/world/map_marks.gd` — A5

| línea | hoy | pasa a |
|---|---|---|
| `:25-37` `COLORS` | trece `Color(...)` | `COLORS` pasa a nombres de token (`SHOP: &"map-shop"`, `INN: &"map-inn"`, `WELL_HP: &"map-well-hp"`, `WELL_MP: &"map-well-mp"`, `WELL_DRY: &"map-well-dry"`, `EXIT: &"map-exit"`, `STAIRS_UP: &"map-stairs-up"`, `STAIRS_DOWN: &"map-stairs-down"`, `LEVER: &"map-lever"`, `LEVER_DOWN: &"map-lever-down"`, `DOOR: &"map-door"`, `DOOR_OPEN: &"map-door-open"`, `KEY: &"map-key"`) y `of_zone()` sigue dando `color` (un `Color`, con `UiTokens.color()`) a quien lo lea: `MapSquare` y la leyenda de la página Mapa no cambian. Los valores son los mismos (redondeo de 8 bits). |

### `scripts/world/explored_map.gd` — A5

| línea | hoy | pasa a |
|---|---|---|
| `:13` `FIELD_COLOR` | `Color(0.3, 0.55, 0.26)` | `c(world-meadow)` #4d8c2e (MapSquare: «campo world-meadow») |
| `:14` `PATH_COLOR` | `Color(0.78, 0.68, 0.48)` | `c(world-path)` #c7ad7a |
| `:15-18` roca, suelo, escaleras, puerta | | se quedan (celdas de mazmorra: no hay token; ver «Correcciones») |

Como son constantes y `UiTokens.color()` es una llamada, `FIELD_COLOR` y `PATH_COLOR` pasan a leerse en `color_of()` (o a `UiTokens.JUEGO[&"world-meadow"]`, que sí es expresión constante: los `world-*` no cambian en alto contraste).

### `scripts/ui/name_entry.gd` — A8

| línea | hoy | pasa a |
|---|---|---|
| `:12` `FONT_SIZE` 26 | | título `V.TITLE`; teclas y filas `body` |
| `:13` `NAME_SIZE` 44 | | `display-m` 48 (Baloo 2; tokens.json: «nombre del héroe al escribirlo») en `c(text-display)` |
| `:14` `TITLE_COLOR` | | `V.TITLE` |
| `:15` `HINT_COLOR` | `Color(0.7, 0.72, 0.8)` | `V.CAPTION` (`c(text-secondary)`) |
| `:16` `KEY_SIZE` 58 × 50 | | se queda (en móvil la tecla mide lo que pide `fit_finger()`) |
| `:53`, `:64-65`, `:74` | 10 / 4 / 4 / 8 | `T.SPACE_2` / `T.SPACE_1` / `T.SPACE_1` / `T.SPACE_2` |
| `:56` | `Color.WHITE` | `c(text-display)` (estilo `display-m`) |
| `:61` | pista 20 `HINT_COLOR` | `V.CAPTION` (18) |
| `:188-190` | `modulate` 0.45 / blanco | se queda (alfa del nombre vacío; constante con nombre `EMPTY_ALPHA`) |

### `scripts/ui/options_panel.gd` — A7

| línea | hoy | pasa a |
|---|---|---|
| `:14` `FONT_SIZE` 24 | | tema |
| `:16` `NAME_WIDTH` 220 | | 260 (A7) |
| `:47`, `:53`, `:218` | 8 / 6 / 8 | `T.SPACE_2` / `T.SPACE_1` / `T.SPACE_2` |
| `:49` | «Opciones» `UiStyle.TITLE_COLOR` | `V.TITLE` |
| `:54`, `:56` | valor del volumen `Color.WHITE`, 24 | `V.CAPTION` con `c(text-primary)` («70 %» en `caption`, OptionRow) |
| `:178` | deslizador 260 × 32 | 260 se queda; alto 32 se queda (zona de toque; la pista mide 8) |
| `:181` | 80 | se queda |
| `:220` | nombre `Color.WHITE` | sin override |
| `:226-231` `_button()` | botón del motor | filas: `UiTheme.menu_row()`; selectores: `V.SELECTOR` |

### `scripts/ui/pause_menu.gd` — A7

| línea | hoy | pasa a |
|---|---|---|
| `:24` `FONT_SIZE` 24 | | tema |
| `:25-26` `TITLE_COLOR`, `GREY` | | `V.TITLE`, `V.REASON` / `V.CAPTION` |
| `:40` `TEXT_WIDTH` 480 | | `T.WINDOW_W_L` |
| `:41` `MISSION_WIDTH` 420 | | se queda |
| `:42` `MESSAGE_WIDTH` 240 | | `T.WINDOW_W_S` |
| `:45` `STATUS_BAR_WIDTH` 300 | | se queda |
| `:46` `MENU_BUTTON_SIZE` 64 × 64 | | `Vector2.ONE * T.MENU_BUTTON` |
| `:47` `MENU_BUTTON_MARGIN` 24 | | `T.SPACE_6` |
| `:124` | velo `Color(0, 0, 0, 0.5)` | `c(surface-scrim)` |
| `:300`, `:319`, `:351`, `:363`, `:439`, `:444`, `:568`, `:598`, `:602`, `:656`, `:673`, `:690`, `:696`, `:724`, `:739`, `:741`, `:768`, `:785`, `:815` | `_label(..., Color.WHITE)` | `_label(text)` sin color (tema) |
| `:316`, `:426`, `:537`, `:553`, `:835` | `_label(..., TITLE_COLOR)` | `V.TITLE` |
| `:360`, `:705` | motivo `GREY` | `V.REASON` |
| `:512` | barras del ☰ `Color.WHITE` | `c(text-primary)`; su geometría (16, 18 + 12 i, 32 × 5) se queda (README: «tres barras blancas de 32 × 5») |
| `:520-526` | ver tabla 2 | `V.MENU_BUTTON` |
| `:600` | oro `StatBar.GOLD` | `V.MONEY` |
| `:592-596`, `:666-668` | `StatBar.new(StatBar.HP, ...)` | igual (ahora `HP` es un nombre de token) |
| `:657`, `:786` | 18 | `V.CAPTION` |
| `:348`, `:433`, `:532`, `:543-544`, `:555`, `:579`, `:587`, `:590`, `:605`, `:614`, `:640`, `:649`, `:671`, `:694`, `:759`, `:832` | separaciones | regla de separaciones (`:605` 2 → 0; `:544` 6 → `T.SPACE_1`) |
| `:352`, `:436`, `:697` | 260 | se queda |
| `:857-866` `_button()` | `flat` + 24 | `UiTheme.menu_row()` |
| `:869-874` `_label()` | tamaño + color | `_label(text, variation := &"")` |

### `scripts/ui/rotate_hint.gd` — A8

| línea | hoy | pasa a |
|---|---|---|
| `:5` `FONT_SIZE` 40 | | `title-l` 36 (Baloo 2) en `c(text-primary)` |
| `:13` | fondo `Color(0.05, 0.05, 0.1)` | `c(surface-window-solid)` |

### `scripts/ui/shop_window.gd` — A7

| línea | hoy | pasa a |
|---|---|---|
| `:16` `FONT_SIZE` 24 | | tema |
| `:17-18` | `TITLE_COLOR`, `GREY` | `V.TITLE`, `V.REASON` |
| `:19` `BETTER` | `Color(0.35, 1.0, 0.4)` | `c(text-positive)` |
| `:20` `WORSE` | `Color(1.0, 0.35, 0.3)` | `c(text-negative)` |
| `:21-31` anchos | | se quedan (`MESSAGE_WIDTH` 640 → `T.WINDOW_W_XL`) |
| `:57` | `Arrow` color por defecto `Color.WHITE` | sin valor por defecto (siempre se pasa) |
| `:62` | flecha 18 × 18 | se queda (`T.TYPE_CAPTION_SIZE` si se quiere nombrar: es el alto del texto `caption`) |
| `:102` | dueño `TITLE_COLOR` | `V.TITLE` |
| `:105` | oro `StatBar.GOLD` | `V.MONEY` |
| `:107`, `:116`, `:196`, `:238`, `:251`, `:305` | `Color.WHITE` | sin override |
| `:232` | precio: gris / blanco (elegido) / oro | `V.REASON` (no se puede) / `V.MONEY` (se puede) — ShopRow: «precio en text-money», «sin oro: text-disabled». El blanco del compañero elegido pasa a `c(text-primary)` |
| `:242`, `:246`, `:262`, `:296` | `GREY` | `V.REASON` |
| `:290` | precio de venta gris / oro | `V.REASON` / `V.MONEY` |
| `:97`, `:100`, `:113`, `:303`, `:394` | 8 / 24 / 6 / 4 / 12 | regla de separaciones |
| `:448-455` `_button()` | `flat` + 24 | `UiTheme.menu_row()` |

### `scripts/ui/slot_list.gd` — A8

| línea | hoy | pasa a |
|---|---|---|
| `:22` `FONT_SIZE` 24 | | tema |
| `:41` `MESSAGE_WIDTH` 360 | | `T.WINDOW_W_M` |
| `:79`, `:307` | 8 | `T.SPACE_2` |
| `:80` | título `UiStyle.TITLE_COLOR` | `V.TITLE` |
| `:92`, `:101`, `:113`, `:119` | `Color.WHITE` | sin override |
| `:102`, `:114`, `:120` | 18 | `V.CAPTION` (la línea de detalle, el mensaje y la de la partida terminada) |
| `:320-327` `_button()` | `flat` + 24 | `UiTheme.menu_row()` |

### `scripts/title/title_screen.gd` — A8

| línea | hoy | pasa a |
|---|---|---|
| `:24` `TITLE_SIZE` 96 | | TitleLogo: `display-xl` |
| `:26` `SUBTITLE_SIZE` 36 | | `title-l` |
| `:27` `VERSION_SIZE` 18 | | `caption` |
| `:28` `FONT_SIZE` 28 | filas del menú | `title-s` 26 (tokens.json: «filas de la pantalla de título») |
| `:31` `UPDATE_WIDTH` 300 | | se queda |
| `:34`, `:36-37` `MENU_TOP` 160, `TOUCH_MENU_TOP` 135, `TOUCH_TITLE_TOP` 8 | | se recalculan en A8 con las alturas medidas de Baloo 2 (ver la tarea) |
| `:40` `TOUCH_TITLE_SIZE` 64 | | `display-l` |
| `:41` `TOUCH_SUBTITLE_SIZE` 26 | | `title-m` 30 (Baloo 2): en móvil el subtítulo baja un estilo, como el logotipo (`display-xl` → `display-l`). Si no cabe, se mueve el menú (`TOUCH_MENU_TOP`), nunca el estilo (ver «Decisiones» del plan) |
| `:380-382` | título: `Color(1.0, 0.9, 0.45)`, contorno `Color(0.1, 0.05, 0.0)` 18 | `c(text-display)`, `c(text-outline-warm)`, `T.OUTLINE_XL` |
| `:391-393` | subtítulo: `Color(1.0, 0.95, 0.8)`, contorno 10 | `c(text-display-soft)`, `c(text-outline-warm)`, `T.OUTLINE_L` |
| `:404-406` | versión: 18, contorno cálido 6 | `caption`, `c(text-primary)`, contorno `T.OUTLINE_S` `c(text-outline-warm)` |
| `:409`, `:369` | márgenes 12 / 90 | `T.SPACE_3` / se queda (90: composición) |
| `:420` | 8 | `T.SPACE_2` |
| `:417` | menú de 320 de ancho mínimo | se queda |
| `:505-514` `_button()` | `flat` + 28 | `UiTheme.menu_row()` + estilo `title-s` |
| `:522` | fundido `Color(0, 0, 0, 0)` | se queda (fundido, no interfaz) |

### `scripts/story/beyond_screen.gd` — A8

| línea | hoy | pasa a |
|---|---|---|
| `:15` `TEXT_SIZE` 34 | | `title-l` 36 (Baloo 2) |
| `:353-355` | blanco, contorno negro 8 | `c(text-primary)`, `c(text-outline)`, `T.OUTLINE_M` |
| `:22-35`, `:166`, `:219`, `:304-306` | el paisaje | **no entran** (3D) |

### `scripts/world/world.gd` (partes 2D) — A5

| línea | hoy | pasa a |
|---|---|---|
| `:63` `NOTICE_MAX_WIDTH` 640 | | `T.WINDOW_W_XL` |
| `:64` `UI_EDGE` 24 | | `T.SPACE_6` |
| `:66` `TOUCH_MISSION_WIDTH` 300 | | se queda |
| `:68` `USE_BUTTON_FONT` 28 | | `V.ACTION_BUTTON` (`title-s`) |
| `:69` `USE_BUTTON_SIZE` 180 × 72 | | se queda (InteractionPrompt: 180 × 72) |
| `:71` `PLACE_OUTLINE` 6 | | `V.OUTLINED` (`T.OUTLINE_M`) |
| `:73` `TOUCH_HINT_WIDTH` 480 | | `T.WINDOW_W_L` |
| `:75` `BANNER_TOP` 110 | | se queda (PlaceBanner: «a 110 px de arriba») |
| `:76-78` `BANNER_NAME_FONT` 48, `BANNER_FLOOR_FONT` 30, `BANNER_COLOR` | | `V.DISPLAY` (`display-m`) y `V.DISPLAY_SUB` (`title-m`), `c(text-display)` |
| `:81` `FONT_SIZE` 24 | | tema |
| `:159` `MARKER_COLOR` | `Color(1.0, 0.9, 0.4)` (anillo del clic en el suelo, 3D) | `c(border-focus)` (es el «aquí» del jugador; dorado de foco) |
| `:168` `QUEST_MARK_COLOR` | `Color(1.0, 0.85, 0.2)` | `c(quest-mark)` |
| `:174-177` | letrero de figura: 48, 0,012, contorno 14, `Color(1.0, 0.95, 0.8)` | ver tabla 4 |
| `:181` `MISSION_WIDTH` 420 | | se queda |
| `:1163`, `:1179` | misiones `Color.WHITE` | `V.CAPTION` (HeroPanel: misiones en `caption` / `text-secondary`) |
| `:1173` | «Misión cumplida» `StatBar.GOLD` | `c(text-positive)` (`V.POSITIVE` en `caption`): oro es dinero |
| `:1580`, `:1617`, `:1634`, `:1708` | 8 / 4 / 0 / 0 | regla de separaciones |
| `:1592-1594` | línea del lugar: 18, contorno negro 6 | `V.OUTLINED` (`caption`, `T.OUTLINE_M`) |
| `:1626-1631` | nombre del héroe 24 blanco; oro `StatBar.GOLD` | nombre `V.TITLE` (HeroPanel: `title-s` / `text-accent`); oro `V.MONEY` |
| `:1650-1651` | acción en escritorio: 24, contorno negro 8 | `V.OUTLINED` (`caption`) |
| `:1713-1720` | rótulo: ver arriba, contorno cálido 12 | `V.DISPLAY` / `V.DISPLAY_SUB` |
| `:1745-1749` `_label()` | 24 blanco | sin overrides |

### `scripts/battle/battle_scene.gd` — A6

| línea | hoy | pasa a |
|---|---|---|
| `:36` `ARROW_COLOR` | `Color(1.0, 0.9, 0.3)` (flecha 3D del objetivo) | `c(border-focus)` (EnemyBar: «una flecha amarilla») |
| `:39` `MP_COLOR := StatBar.MP` | | `c(stat-mp)` en el momento de usarlo (ya no es un `Color` constante) |
| `:40-50` | brillos 3D | no entran |

### `scripts/world/touch_pad.gd` — A5

| línea | hoy | pasa a |
|---|---|---|
| `:13-14` | `Color(1, 1, 1, 0.35)` / `(1, 1, 1, 0.6)` | `c(border-window)` con alfa `RING_ALPHA` 0.35 / `KNOB_ALPHA` 0.6 |

## 4. `Label3D` — A5 y A6

Regla: la letra sale de `UiTheme.font_for(estilo)`, el tamaño del estilo, el color y el contorno de tokens; **el alto en el mundo no cambia**: `pixel_size` nuevo = `pixel_size` viejo × tamaño viejo / tamaño nuevo. Todos con `outline_modulate = c(text-outline)` salvo que se diga.

| archivo:línea | qué | hoy | pasa a |
|---|---|---|---|
| `scripts/world/world.gd:1089-1097` | letrero de figura («Tienda», «Posada», «Criaturas») | 48, `pixel_size` 0,012, contorno 14, `Color(1.0, 0.95, 0.8)` | `display-m` 48 (Baloo 2), 0,012, `T.OUTLINE_L`, `c(text-display-soft)` |
| `scripts/world/world.gd:1102-1111` | marca «!» / «?» | 96, 0,01, contorno 16, `QUEST_MARK_COLOR` | `display-xl` 96, 0,01, `T.OUTLINE_M` (QuestMark), `c(quest-mark)` |
| `scripts/world/world.gd:1430-1435` | rótulo del arco de salida | 48, 0,008, contorno 10, `Color(1.0, 0.95, 0.8)` | `display-m`, 0,008, `T.OUTLINE_L`, `c(text-display-soft)` |
| `scripts/world/dungeon_map.gd:508-513` | «Subir» / «Bajar» | 48, 0,008, 10, `Color(1.0, 0.95, 0.8)` | igual que el arco |
| `scripts/world/travel_portal.gd:45-51` | «Portal» | 48, 0,008, 10, sin color | igual que el arco |
| `scripts/battle/battle_actor.gd:2306-2312` `_spawn_number()` | número de daño | 64 (crítico 96), 0,005, contorno 16; crítico `Color(1.0, 0.85, 0.2)` | `display-m` 48 con `pixel_size` 0,005 × 64 / 48; crítico × 1,3 (62); contorno `T.OUTLINE_M`; normal `c(text-primary)`, crítico `c(text-display)`; el color de un hechizo, por elemento (`element-fire` / `-ice` / `-thunder`); curación `c(element-heal)` |
| `scripts/battle/battle_actor.gd:2309` | etiqueta «¡Débil!» / «¡Resiste!» | 40, `TAG_COLOR` | estilo `label` 20 con `pixel_size` 0,005 × 40 / 20; «¡Débil!» `c(element-weak)`, «¡Resiste!» `c(text-secondary)` (B3 añade «¡Crítico!» en `c(text-accent)`) |
| `scripts/battle/battle_actor.gd:23-26` | `FIRE_COLOR`, `HEAL_COLOR`, `TAG_COLOR` | | `c(element-fire)`, `c(element-heal)`, `c(element-weak)` (también los usa el brillo del lanzamiento: el mismo color, no hay conflicto) |
| `scripts/battle/battle_actor.gd:2315-2329` `_float_label()` | sube 0,8 m en 0,9 s; se apaga desde 0,3 s en 0,6 s | DamageNumber: «sube 0,8 m en 0,8 s»: 0,9 → 0,8 (se apaga desde 0,2 s en 0,6 s) |

## 5. Botones: cuáles son filas y cuáles no

| dónde | hoy | pasa a (A3 pone la variación, A4 el cursor) |
|---|---|---|
| `battle_hud.gd:466` filas del menú de combate | `flat` | `UiTheme.menu_row()` (no planas: el estilo `normal` vacío con hueco de cursor) |
| `title_screen.gd:506` menú del título | `flat` | `menu_row()` |
| `slot_list.gd:321` ranuras y páginas | `flat` | `menu_row()` |
| `difficulty_window.gd:66` | `flat` | `menu_row()` |
| `pause_menu.gd:857` todas las páginas | `flat` | `menu_row()` |
| `shop_window.gd:449` | `flat` | `menu_row()` |
| `bestiary_page.gd:159` tarjeta (botón invisible sobre el retrato) | `flat` sin texto | no es fila, es la zona de toque: `V.CARD_HIT` (sin fondo; con foco, marco `T.BORDER_2` `c(border-focus)` y `T.RADIUS_S`), deja de ser `flat` para que se dibuje el foco |
| `choice_window.gd:46` | del motor | `menu_row()` |
| `keys_panel.gd:118` | del motor | `menu_row()` |
| `debug_panel.gd:208` | del motor | `menu_row()` |
| `options_panel.gd:227` (Volver, Teclas, Exportar) | del motor | `menu_row()` |
| `options_panel.gd:193` selectores | del motor, `toggle_mode` | `V.SELECTOR` |
| `name_entry.gd:195` teclas y filas | del motor | letras `V.KEY`; «Borrar», «Aceptar», «Volver», mayúsculas: `menu_row()` |
| `battle_result.gd:35` «Continuar» | del motor | `menu_row()` |
| `pause_menu.gd:496` ☰ | estilos propios | `V.MENU_BUTTON` |
| `world.gd:1669` botón de acción del móvil | del motor | `V.ACTION_BUTTON` |
| `shop_window.gd` «×5» | sale de `_button()` | `menu_row()` (es una fila corta) |

## 6. Cómo volver a sacar este inventario

```bash
cd /c/Users/peixe/Documents/rpg-turnos
F="scripts/ui/*.gd scripts/title/*.gd scripts/story/*.gd scripts/world/world.gd scripts/world/touch_pad.gd scripts/world/map_marks.gd scripts/world/explored_map.gd scripts/battle/battle_scene.gd"
grep -nE "Color\(|Color\.[A-Z]" $F
grep -nE "font_size|FONT_SIZE|_SIZE :?=|outline_size|OUTLINE" $F
grep -rnE "CanvasLayer.new|\.layer = |Label3D.new|StyleBox|ThemeDB" scripts
grep -nE "constant_override\(\"(separation|h_separation|v_separation)\"" $F
```

Al acabar la Parte A, los dos primeros `grep` solo deben encontrar: el mundo 3D de las listas de arriba, los fundidos, las alfas con nombre y los `Color` que se construyen desde `UiTokens`.
