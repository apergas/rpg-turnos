# Fundamentos de Villaclaro

Las escalas, las medidas genéricas, los diez estilos de texto y el papel de cada semántico de superficie, marco y texto están en los [fundamentos del núcleo](../../../addons/design_system/docs/2-fundamentos.md). Aquí está lo de Villaclaro.

## Los valores que Villaclaro da al núcleo

En el `"overrides"` de `tokens.json`:

| Token | `juego` | `alto-contraste` |
| --- | --- | --- |
| `surface-window` | #0a0a1fe6 (`navy-900` al 90 %: el mundo se ve detrás) | #05050f |
| `surface-window-solid` | `navy-900` | `navy-950` |
| `surface-selected` | `navy-800` | `navy-700` |
| `surface-track` | #0000008c | `black` |
| `surface-scrim` | #00000080 | #000000b3 |
| `border-window` | `white` (marco de 3 px de toda ventana y del botón ☰) | `white` |
| `border-subtle` | `navy-600` | `grey-400` |
| `border-focus` | `gold-300` (11:1 sobre `surface-window-solid`) | `gold-300` |
| `text-primary` | `white` | `white` |
| `text-secondary` | `grey-300` | `grey-200` |
| `text-disabled` | `grey-500` | `grey-400` |
| `text-accent` | `gold-300` | `gold-300` |
| `text-money` | `gold-400` | `gold-400` |
| `text-positive` | `green-300` | `green-300` |
| `text-negative` | `red-300` | `red-300` |
| `text-danger` | `orange-300` | `orange-300` |
| `text-info` | `blue-300` | `blue-300` |
| `text-on-fill` | `white` | `white` |
| `text-outline` | `black` | `black` |

## Color propio

| Para | Token | No usar para |
| --- | --- | --- |
| PV / PM / EXP | `stat-hp`, `stat-mp`, `stat-exp` | cualquier otra cosa |
| Estados | `status-*` | otra cosa que no sea la insignia |
| Efectos | `element-*` | menús |
| Brillo sobre la figura en combate (defender, cargar, Despertador, veneno, sueño, silencio, aturdido) | `effect-*` (no son `status-*`: esos son las insignias) | insignias, texto |
| Retrato del bestiario visto, sin vencer | `portrait-seen` (color de lavado: retrato desaturado y aclarado) | texto |
| Logotipo y rótulos de lugar | `text-display`, `text-display-soft`, con contorno `text-outline-warm` | texto de ventana |

Opacidades: `opacity-placeholder` 0,45 (nombre aún sin escribir), `opacity-map-picture` 0,8 (la imagen del mapa dentro de su cuadro), `opacity-map` 0,45 (el cuadro del mapa) y `opacity-portrait-desaturate` 0,85 (cuánto se desatura el retrato visto sin vencer), junto a las del núcleo. El joystick táctil se dibuja en `border-window` con `opacity-touch-ring` 0,35 (el aro) y `opacity-touch-knob` 0,6 (el pomo).

Antes había seis dorados casi iguales. Ahora son cuatro tonos con papel propio: `gold-100` subtítulo, `gold-200` logotipo, `gold-300` acento y cursor, `gold-400` dinero.

### Paleta base

Colores en bruto: la interfaz usa los semánticos, que apuntan a estos. Ninguno se escribe a mano en un script.

| Token | Papel |
| --- | --- |
| `navy-950` | fondo opaco de ventana en alto contraste |
| `navy-900` | el azul de Villaclaro: base de las ventanas |
| `navy-800` | fila elegida, paneles interiores |
| `navy-700` | fila elegida en alto contraste, pistas de deslizador |
| `navy-600` | separadores dentro de una ventana |
| `white` | texto principal y marco |
| `grey-200`, `grey-300` | texto secundario (alto contraste, normal) |
| `grey-400`, `grey-500` | texto desactivado (alto contraste, normal) |
| `grey-600` | insignia de Silencio |
| `black` | contorno de texto sobre el mundo |
| `gold-100` | crema del subtítulo |
| `gold-200` | dorado del logotipo y los rótulos de lugar |
| `gold-300` | dorado de acento: títulos, cursor, hablante, marcas de misión |
| `gold-400` | dorado del dinero |
| `brown-950` | contorno cálido del texto dorado |
| `red-300` | rojo legible sobre azul: peor, daño |
| `red-500` | rojo de PV |
| `red-700` | rojo oscuro: reja cerrada en el mapa |
| `blue-300` | azul legible sobre azul: avisos |
| `blue-500` | azul de PM |
| `blue-600` | insignia de Sueño |
| `green-300` | verde legible: EXP como texto, mejor, éxito |
| `green-500` | verde antiguo de la barra de EXP (sustituido por `green-600`) |
| `green-600` | verde de la barra de EXP (el texto blanco encima pasa 4,5:1) |
| `orange-300` | naranja legible: peligro, PV críticos, «¡Débil!» |
| `orange-500` | naranja del fuego |
| `orange-700` | insignia de Aturdido |
| `purple-300` | violeta del rayo |
| `purple-500` | insignia de Veneno |
| `cyan-300` | celeste del hielo |
| `mint-300` | verde de la curación |

### Otros semánticos

| Token | Papel |
| --- | --- |
| `effect-defend`, `effect-charge`, `effect-wake` | brillo sobre la figura: defenderse, enemigo que carga, Despertador |
| `effect-poison`, `effect-sleep`, `effect-silence`, `effect-stun` | brillo sobre la figura al recibir ese estado |
| `map-well-dry`, `map-lever-down`, `map-door-open` | marcas del mapa: pozo seco, palanca tirada, reja abierta |
| `world-sky`, `world-wood` | referencia del mundo: cielo de la pradera, madera de arcos y carteles |

## Tipografía

- **Baloo 2** (`display`): redondeada y con cuerpo, como los personajes low-poly. Para logotipo, rótulos de lugar, números de daño y marcas de misión.
- **Nunito** (`ui`): redondeada y muy legible en pequeño. Para todo texto de ventana, a peso 700 (600 en `caption`, 800 en `title-s` y `micro`).

Ambas son libres (OFL, licencias en `licenses/`) y variables: un solo archivo por familia cubre todos los pesos. Van incluidas en el juego, así que escritorio, web y móvil se ven igual. Antes, la letra por defecto del motor cambiaba según la plataforma.

La escala es la del núcleo, sobre un lienzo de 1280 × 720 que el motor escala (×1,25 con texto grande, ×1,35 en móvil). En Villaclaro:

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

## Medidas propias

- Botón ☰: `menu-button` 64, con iconos de `icon-m` 24.
- Barras del héroe: `bar-width` 220 (170 en móvil) × `bar-height` 30; del enemigo, `enemy-bar-width` 96 × `enemy-bar-height` 8.
- Cuadro del mapa: `map-size` 150 (110 en móvil).

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
