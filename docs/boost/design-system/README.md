La interfaz de Villaclaro es una capa clásica de RPG de consola que flota sobre un mundo 3D low-poly luminoso: ventanas azul marino con marco blanco, texto blanco, dorado para lo importante y un color fijo para cada dato del héroe. Este sistema la ordena para que crezca sin perder esa identidad. Todo valor sale de un token, todo color tiene un significado y la selección se ve igual con teclado, ratón o dedo.

## Las dos capas

- **El núcleo** ([`addons/design_system/`](../../../addons/design_system/README.md)): las herramientas, los tokens genéricos (escalas, medidas, los diez estilos de texto y los semánticos de superficie, marco y texto), la base del tema (`DsTheme`), el cursor (`MenuCursor`) y las guías de [fundamentos](../../../addons/design_system/docs/2-fundamentos.md), [interacción](../../../addons/design_system/docs/3-interaccion.md), [accesibilidad](../../../addons/design_system/docs/4-accesibilidad.md) y [Godot](../../../addons/design_system/docs/5-godot.md). Es igual en todos los juegos y no se edita desde aquí.
- **La capa de Villaclaro** (esta carpeta): su identidad, su [voz y tono](1-voz-y-tono.md), su paleta, sus fuentes, los valores que da a los tokens del núcleo y sus tokens propios ([fundamentos](2-fundamentos.md)), su [tabla de contraste](4-accesibilidad.md), la [migración](6-migracion.md) y las fichas de sus componentes. Sus rutas están en `design_system.json`, en la raíz del juego.

## Principios

1. **El mundo primero.** Ventanas translúcidas, pequeñas y en las esquinas; nunca tapan la acción sin motivo.
2. **Un color, un significado.** Rojo es PV, azul es PM, verde es EXP, dorado es «mira aquí» o dinero. Si un color ya significa algo, no se usa para otra cosa.
3. **Siempre se sabe dónde estás.** La fila elegida lleva el cursor dorado ▶ y un fondo, en cualquier dispositivo.
4. **Teclado, ratón y dedo por igual.** Todo se puede hacer con los tres; en móvil nada mide menos de `touch-target`.
5. **Legible sobre cualquier escena.** Las ventanas llevan sombra; el texto sobre el mundo lleva contorno.
6. **Nunca solo color.** Estados, comparaciones y marcas del mapa llevan siempre palabra, forma o signo.

## Cómo está organizado

- **`tokens.json`**: la capa de Villaclaro sobre el `base.json` del núcleo (`"extends"`).
  - **Paleta base** (`navy-*`, `gold-*`, `red-*`, `blue-*`, `green-*`…): los colores en bruto. No se usan directamente en la interfaz.
  - **`"overrides"`**: el valor que Villaclaro da a los semánticos del núcleo (`surface-*`, `border-*`, `text-*`): el azul marino, el blanco y el dorado.
  - **Tokens propios**: `stat-*` (barras del héroe), `status-*` (estados de combate), `element-*` y `effect-*` (efectos), `map-*` (marcas del mapa), `world-*` (referencia del mundo), los rótulos dorados (`text-display*`, `text-outline-warm`), sus medidas, sus opacidades y las capas de pantalla `layer-*`.
- **Temas**: `juego` (el normal) y `alto-contraste` (opción de accesibilidad: ventanas opacas, texto a 7:1 o más). Solo cambian los semánticos.
- **Tipografía**: `display` es Baloo 2, para rótulos, logotipo y números; `ui` es Nunito, para todo lo demás. Los diez estilos son los del núcleo, de `display-xl` (96 px) a `micro` (16 px); `body` (24 px) es la base.
- **Lo generado**: `scripts/ui/ui_tokens.gd` (`UiTokens`) y `tokens.css`, desde el `base.json` del núcleo y este `tokens.json`. No se editan a mano.

## Reglas rápidas

- Escribe `text-primary` sobre `surface-window`; las descripciones en `caption` con `text-secondary`.
- Títulos de ventana en `title-s` con `text-accent`. El oro siempre en `text-money`.
- Una ventana: `surface-window`, marco `border-3` `border-window`, `radius-m`, relleno `space-4` × `space-3`, `shadow-window`.
- Separa ventanas con `space-4` y despégalas del borde de la pantalla con `space-6`.
- Texto sobre el mundo: blanco con `outline-m` en `text-outline`, o dorado `text-display` con `outline-l` en `text-outline-warm`.
- Nunca escribas un color o un tamaño a mano en un script: usa `UiTokens` ([Godot](../../../addons/design_system/docs/5-godot.md)).

## Iconografía

No hay fuente de iconos: la interfaz se apoya en el texto. Los pocos pictogramas se dibujan en código para que se vean igual en la web:
- el botón ☰: tres barras blancas de 32 × 5;
- el cursor ▶ y las flechas ▲▼ de comparación: triángulos;
- las marcas de misión «!» y «?»: texto 3D en `display`;
- las marcas del mapa: cuadrados de 5 px.

Las únicas imágenes de la interfaz son los retratos del bestiario (grupo **Bestiary**) y el icono de la app (grupo **Logos**). No hay logotipo en archivo: «Villaclaro» se compone siempre con TitleLogo.

## Componentes

- **Del núcleo** ([`addons/design_system/docs/components/`](../../../addons/design_system/docs/components/)): Window, DialogueBox, Notice, ChoiceWindow, MenuList, ItemRow, OptionRow.
- **De Villaclaro** (`components/`):
  - **Menús**: ShopRow.
  - **Héroe**: StatBar, StatusBadge, HeroPanel.
  - **Combate**: EnemyBar, DamageNumber.
  - **Bestiario**: BestiaryCard.
  - **Mundo**: PlaceBanner, TitleLogo, InteractionPrompt, QuestMark, MapSquare.

Las vistas previas son representaciones estáticas en HTML/CSS: el `bundle.css` del núcleo (clases `ds-`) y, encima, el de Villaclaro (`components/bundle.css`, clases `vc-` y el fondo del escenario), los dos con las variables de `tokens.css`.

## En Godot

- **`UiTheme`** (`scripts/ui/ui_theme.gd`) hereda de `DsTheme` y conserva toda la API que usan las pantallas (`UiTheme.menu_row()`, `UiTheme.CAPTION`…). Añade lo de Villaclaro: la variación `WINDOW_MAP` con `map_style()` (`surface-map`, `border-map`), las etiquetas `DISPLAY` y `DISPLAY_SUB` (`text-display` con `text-outline-warm`) y `badge_style(status)`. Su `apply()` y su `ensure()` ponen `DsTheme.touch` con `Device.is_touch()`; `DisplaySettings.apply()` llama a `apply()`.
- **`FocusRow`** (`scripts/ui/focus_row.gd`): una fila de varios controles (nombre, selector, deslizador) que pinta el fondo de la fila elegida mientras algo dentro de ella tiene el foco. Así las opciones se ven como las demás filas.
- **`StatBar`** (`scripts/ui/stat_bar.gd`): una barra del héroe con su texto encima. `StatBar.HP`, `MP` y `EXP` son nombres de token (`stat-hp`, `stat-mp`, `stat-exp`). Con PV por debajo del 25 % el relleno late y el texto pasa a `text-danger`.
- `UiStyle`, `ScrollBox`, `ChoiceWindow` y `DialogueBox` se quedan en `scripts/ui/`: dependen de piezas del juego.

## Qué queda fuera del design system

Los colores del mundo 3D no son tokens: `ZoneData` (cielo, niebla, suelo, sol), los constructores (`WorldStage`, `BattleStage`, `DungeonMap`, `LowPoly`) y los modelos. Son contenido del juego, no interfaz. Sí son del design system los brillos de efecto sobre las figuras en combate (`effect-*`) y los colores de elemento (`element-*`).

## Cómo añadir un token

Uno de Villaclaro: en `tokens.json` (con su `usage`, y su valor de `alto-contraste` si es un semántico), escrito como `` `nombre` `` en [2-fundamentos.md](2-fundamentos.md) o en la ficha de su componente. Uno que valga para cualquier juego: en el `base.json` del núcleo y sus guías. Después se regenera y se añaden `tokens.json`, `scripts/ui/ui_tokens.gd` y `tokens.css` al mismo commit ([cómo](../../../addons/design_system/docs/5-godot.md)).
