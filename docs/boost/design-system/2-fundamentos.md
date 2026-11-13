# Fundamentos

## Color

| Para | Token | No usar para |
| --- | --- | --- |
| Fondo de ventana | `surface-window` (opaco: `surface-window-solid`) | — |
| Fila elegida | `surface-selected` + cursor `border-focus` | botones normales |
| Texto | `text-primary`, `text-secondary`, `text-disabled` | — |
| Títulos, quien habla, objetivo | `text-accent` | dinero |
| Dinero | `text-money` | títulos |
| Bueno / malo / peligro / info | `text-positive`, `text-negative`, `text-danger`, `text-info` | decoración |
| PV / PM / EXP | `stat-hp`, `stat-mp`, `stat-exp` | cualquier otra cosa |
| Estados | `status-*` | otra cosa que no sea la insignia |
| Efectos | `element-*` | menús |

Antes había seis dorados casi iguales. Ahora son cuatro tonos con papel propio: `gold-100` subtítulo, `gold-200` logotipo, `gold-300` acento y cursor, `gold-400` dinero.

## Tipografía

- **Baloo 2** (`display`): redondeada y con cuerpo, como los personajes low-poly. Para logotipo, rótulos de lugar, números de daño y marcas de misión.
- **Nunito** (`ui`): redondeada y muy legible en pequeño. Para todo texto de ventana, a peso 700 (600 en `caption`, 800 en `title-s` y `micro`).

Ambas son libres (OFL, licencias en `licenses/`) y variables: un solo archivo por familia cubre todos los pesos. Van incluidas en el juego, así que escritorio, web y móvil se ven igual. Antes, la letra por defecto del motor cambiaba según la plataforma.

Escala, sobre un lienzo de 1280 × 720 que el motor escala (×1,25 con texto grande, ×1,35 en móvil):

| Estilo | px | Uso |
| --- | --- | --- |
| `display-xl` | 96 | Logotipo |
| `display-l` | 64 | Logotipo en móvil, «Fin» |
| `display-m` | 48 | Rótulo de lugar, daño |
| `title-l` | 36 | Subtítulo |
| `title-m` | 30 | Planta, créditos |
| `title-s` | 26 | Título de ventana |
| `body` | 24 | **Base**: filas, mensajes, diálogo |
| `label` | 20 | Texto en barras, Diario |
| `caption` | 18 | Descripciones |
| `micro` | 16 | Insignias, leyendas |

Antes había trece tamaños sueltos (16, 18, 20, 22, 24, 26, 28, 30, 36, 44, 48, 72, 96); ahora son diez con nombre.

## Espaciado y forma

- Pasos de 4 px: `space-1` 4, `space-2` 8, `space-3` 12, `space-4` 16, `space-5` 20, `space-6` 24, `space-8` 32, `space-12` 48.
- Ventana: relleno `space-4` × `space-3`, separación entre ventanas `space-4`, margen de pantalla `space-6`.
- Radios: `radius-s` 4 (insignias, fila elegida, mapa), `radius-m` 8 (ventanas), `radius-l` 12 (tarjetas grandes), `radius-full` (botón de acción en móvil).
- Anchos de ventana: `window-w-s` 240, `-m` 360, `-l` 480, `-xl` 640, `-max` 1000.

## Elevación

Una sola sombra, `shadow-window`, en toda ventana. Sobre cielo, nieve o arena, el marco blanco se perdía; la sombra lo despega.

## Movimiento

| Qué | Duración |
| --- | --- |
| Fundido entre escenas | 0,5 s |
| Rótulo de lugar | 0,5 s entrada · 2,5 s · 0,5 s salida |
| Aviso | 0,2 s entrada · 4 s · 0,2 s salida |
| Número de daño | sube 0,8 m en 0,8 s |
| Latido de PV críticos | 1 s por ciclo |
| Bloqueo al abrir un menú | 0,3 s |
| Escritura de texto | 0,05 / 0,025 / 0,008 s por letra |

Solo fundidos y desplazamientos cortos en la capa 2D, sin rebotes. La vida la ponen las figuras 3D.

## Capas de pantalla

`layer-hud` 1 · `layer-shop` 4 · `layer-pause` 5 · `layer-debug` 6 · `layer-cinematic` 9 · `layer-fade` 10 · `layer-overlay` 11 · `layer-title-fade` 20 · `layer-system` 100. Una pantalla nueva elige su capa de esta lista; si no encaja, se añade aquí antes de usarla.
