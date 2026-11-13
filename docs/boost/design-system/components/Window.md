Ventana: el panel azul translúcido con marco blanco en el que vive toda la interfaz.

## Cuándo usarla
Para cualquier menú, mensaje, estado o diálogo. Solo hay dos variantes: la normal y la del mapa (MapSquare). En pantallas sin escena 3D detrás (créditos, final) se usa la opaca `surface-window-solid`.

## Qué aporta quien la usa
El contenido. La ventana se ajusta a él: una línea hasta su ancho máximo (`window-w-*`) y después parte el texto.

## Especificación
- Relleno `surface-window`, marco `border-3` en `border-window`, esquinas `radius-m`, sombra `shadow-window`.
- Relleno interior `space-4` × `space-3`.
- Título opcional en `title-s` / `text-accent`; separadores de `border-1` en `border-subtle`.
- A `space-6` del borde de la pantalla y a `space-4` de otra ventana.
- En alto contraste el relleno es opaco.

## No hacer
Otros colores de marco, degradados o un segundo radio. La sombra es la única elevación.

## En Godot
Un `PanelContainer` sin overrides cuando el tema `UiTheme` está aplicado (sustituye a `BattleHud.make_window()`).
