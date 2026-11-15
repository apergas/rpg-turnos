# Fundamentos

Los tokens genéricos de `tokens/base.json`. Cada juego les da sus valores en el `"overrides"` de su `tokens.json` y añade los suyos (barras, estados, mapa, capas…). Los valores del núcleo son neutros: grises y un acento azul.

## Temas

Dos: el normal (`role` `normal`) y el de alto contraste (`role` `contrast`), con ventanas opacas y texto más claro. El juego pone sus ids. Solo cambian los colores semánticos.

## Color

| Token | Para | No usar para |
| --- | --- | --- |
| `surface-window` | relleno de toda ventana, translúcido (opaco en alto contraste) | — |
| `surface-window-solid` | ventana opaca: pantallas sin escena detrás | — |
| `surface-selected` | fondo de la fila elegida, junto al cursor | botones normales |
| `surface-track` | parte vacía de una barra o un deslizador | fondos de ventana |
| `surface-scrim` | velo a pantalla completa detrás de un menú; tocarlo es «volver» | ventanas |
| `border-window` | marco de toda ventana | separadores |
| `border-subtle` | separadores y líneas internas de una ventana | marcos |
| `border-focus` | cursor y anillo de foco: dónde está la selección | decoración |
| `text-primary` | texto de filas, mensajes y diálogos | — |
| `text-secondary` | descripciones bajo una fila, notas | texto principal |
| `text-disabled` | filas que no se pueden elegir y su motivo | — |
| `text-accent` | títulos de ventana, quien habla, el objetivo | dinero |
| `text-money` | toda cantidad de dinero | títulos |
| `text-positive`, `text-negative` | mejor y peor, lo ganado y lo perdido | decoración |
| `text-danger` | un dato en estado crítico | decoración |
| `text-info` | avisos informativos | — |
| `text-on-fill` | texto sobre una barra o una insignia de color | texto sobre una ventana |
| `text-outline` | contorno del texto claro sobre la escena o una barra | — |

Un color, un significado: si un token ya dice algo, no se usa para otra cosa.

## Tipografía

Dos familias de rol: `display`, para rótulos, logotipo y números grandes, y `ui`, para todo lo demás. El núcleo no trae letras: el juego da las suyas (`type.fonts`) y, si no, se usa la del motor. En CSS son `--font-display` y `--font-ui`.

| Estilo | px | Peso | Interlineado | Familia |
| --- | --- | --- | --- | --- |
| `display-xl` | 96 | 800 | 1,0 | display |
| `display-l` | 64 | 800 | 1,05 | display |
| `display-m` | 48 | 700 | 1,1 | display |
| `title-l` | 36 | 700 | 1,15 | display |
| `title-m` | 30 | 700 | 1,2 | display |
| `title-s` | 26 | 800 | 1,3 | ui |
| `body` | 24 | 700 | 1,35 | ui |
| `label` | 20 | 700 | 1,3 | ui |
| `caption` | 18 | 600 | 1,35 | ui |
| `micro` | 16 | 800 | 1,25 | ui |

`body` es la base: filas, mensajes y diálogos. Los tamaños son de un lienzo de 1280 × 720 que el motor escala.

## Espaciado y forma

- Pasos de 4 px: `space-1` 4, `space-2` 8, `space-3` 12, `space-4` 16, `space-5` 20, `space-6` 24, `space-8` 32, `space-12` 48.
- Ventana: relleno `space-4` × `space-3`, separación entre ventanas `space-4`, margen de pantalla `space-6`.
- Radios: `radius-s` 4 (insignias, fila elegida), `radius-m` 8 (ventanas), `radius-l` 12 (tarjetas grandes), `radius-full` (botón de acción en móvil).
- Bordes: `border-1` 1 (separadores), `border-2` 2 (anillo de foco), `border-3` 3 (marco de ventana).
- Contornos de texto: `outline-s` 4 (sobre barras e insignias), `outline-m` 8 (texto claro sobre la escena), `outline-l` 12 (rótulos), `outline-xl` 18 (logotipo).

## Medidas

| Token | px | Para |
| --- | --- | --- |
| `touch-target` | 56 | alto mínimo de una fila o un botón en móvil |
| `touch-min-width` | 120 | ancho mínimo de un botón en móvil |
| `row-height` | 40 | alto de una fila de menú en escritorio |
| `cursor-size` | 14 | el triángulo del cursor |
| `icon-m` | 24 | iconos dibujados |
| `window-w-s` | 240 | ventana estrecha: un menú de comandos |
| `window-w-m` | 360 | ventana media: descripciones, mensajes laterales |
| `window-w-l` | 480 | ventana ancha: preguntas, texto de páginas |
| `window-w-xl` | 640 | avisos arriba al centro |
| `window-w-max` | 1000 | diálogo, antes de partir líneas |

## Opacidades

`opacity-window` 0,9 (el relleno de ventana) y `opacity-faded` 0,5 (algo que está pero no cuenta ahora).

## Elevación

Una sola sombra, `shadow-window`, en toda ventana: sobre un fondo claro el marco se perdería.
