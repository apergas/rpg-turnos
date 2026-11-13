# Implementación en Godot

Hoy cada script escribe sus colores y tamaños a mano: `Color(0.04, 0.04, 0.12, 0.9)` aparece en varios sitios, cada página tiene su `FONT_SIZE` y los estilos de ventana se repiten. El design system propone una sola fuente de verdad, en tres archivos de `godot/` dentro de este sistema:

- **`godot/ui_tokens.gd`** (`UiTokens`): **generado** desde `tokens.json`. Contiene:
  - todos los colores de los dos temas, con `UiTokens.color(&"text-accent")` (devuelve el de alto contraste si `UiTokens.high_contrast` es true);
  - las escalas como constantes: `SPACE_4`, `RADIUS_M`, `TYPE_BODY_SIZE`…
- **`godot/ui_theme.gd`** (`UiTheme`): construye el `Theme` del juego en código, siguiendo la costumbre del proyecto de crearlo todo en código:
  - ventana para `PanelContainer`;
  - estilo `MapWindow` para el cuadro del mapa;
  - filas de menú para `Button`;
  - deslizadores;
  - variaciones de `Label`: `TitleLabel`, `CaptionLabel`, `MoneyLabel`, `OutlinedLabel`, `DisplayLabel`, `BadgeLabel`;
  - las dos letras como `FontVariation` de un archivo variable.
- **`godot/menu_cursor.gd`** (`MenuCursor`): el cursor ▶ que sigue a la fila elegida.

## Cómo se aplicaría

1. Copiar `fonts/Nunito-Variable.ttf` y `fonts/Baloo2-Variable.ttf` a `res://assets/fonts/` y los tres scripts a `res://scripts/ui/`.
2. Al arrancar (en `TitleScreen._ready()`, junto a `DisplaySettings.apply()`):
   `ThemeDB.get_default_theme().merge_with(UiTheme.build())`.
   Va sobre el tema por defecto porque es el único que llega a los controles bajo un `CanvasLayer`.
3. Sustituir, pantalla a pantalla:
   - `BattleHud.make_window()` → `PanelContainer.new()`;
   - `add_theme_color_override("font_color", UiStyle.GREY)` → `label.theme_type_variation = UiTheme.CAPTION`;
   - cada `Color(...)` suelto → `UiTokens.color(&"…")`.
4. Añadir un `MenuCursor` a cada ventana con menú.

Los scripts son una propuesta: no se han compilado con el proyecto. Este design system no toca el código del juego; la adopción se hace en la sesión de desarrollo, revisándolos con `--check-only`.

## Mantenerlo al día

Cuando cambie un token en esta página, se vuelve a generar `ui_tokens.gd` a partir de `tokens.json` y se copia al juego. Ningún valor visual vive solo en un script.
