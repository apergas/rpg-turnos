# Versión 2.6.0: la interfaz con el design system

Fecha: 2026-11-13. Parte de la 2.5.0. Cubre M-62 a M-66.

## Objetivo

Llevar la interfaz del juego (ventanas, menús, textos, barras, insignias, rótulos y marcas) al **Villaclaro Design System** que el usuario creó (artifact `https://claude.ai/artifact/EQiwKQoCNTAEZDCMRYCuik`). Su contenido está copiado en `docs/boost/design-system/`:

- `README.md` y las secciones `1-voz-y-tono.md` a `6-migracion.md`;
- `tokens.json` (la fuente de los valores);
- `components/*.md` (las guías de cada componente) y `components/bundle.css` (cómo se ve cada uno);
- `godot/ui_tokens.gd.txt`, `godot/ui_theme.gd.txt` y `godot/menu_cursor.gd.txt`: la propuesta de código. Lleva `.txt` para que Godot no la compile; nunca se ha compilado con el proyecto.

Las dos letras (Nunito y Baloo 2, OFL, variables) ya están en `assets/fonts/` con sus licencias.

El juego no cambia de reglas. Lo que cambia es el aspecto: colores con significado, una sola tipografía en todas las plataformas, la fila elegida que se ve igual con teclado, ratón o dedo, y más contraste.

**Manda el design system.** Si un valor del código y uno del design system chocan, gana el del design system. Las excepciones se anotan aquí o en el plan, con el motivo.

## Decisiones

### M-62. Una sola fuente de verdad: `UiTokens` y `UiTheme`

- `scripts/ui/ui_tokens.gd` (`UiTokens`) se escribe desde `godot/ui_tokens.gd.txt`, comprobado contra `tokens.json`. Se comprueba con `--check-only`.
- `scripts/ui/ui_theme.gd` (`UiTheme`) se escribe desde `godot/ui_theme.gd.txt`. Se aplica una vez al arrancar, en `TitleScreen._ready()` junto a `DisplaySettings.apply()`: `ThemeDB.get_default_theme().merge_with(UiTheme.build())`. `Game` y las escenas que corren solas (`battle_scene.tscn`, `world.tscn`, `game.tscn`) también lo aplican si no se ha aplicado ya.
- Encaja con lo que ya hay en `DisplaySettings._set_touch_buttons()`: en un móvil, las filas siguen midiendo `TOUCH_BUTTON_HEIGHT` 56, sin recuadro de foco.
- **Ningún color ni tamaño de la interfaz queda escrito a mano en un script de `scripts/ui/`** ni en las partes 2D de `World`, `BattleScene`, `TitleScreen`, `CreditsScreen` y `BeyondScreen`. Todo sale de `UiTokens.color(&"…")`, de sus constantes o de una variación del tema. Para pasar los valores de hoy a tokens se sigue la tabla de `6-migracion.md`.
- `UiStyle`, `StatBar` y `BattleHud.make_window()` se quedan como fachadas finas sobre los tokens, para no reescribir cada llamada. Se borra lo que quede sin uso.
- Los colores del **mundo 3D** no entran: cielo, suelos, figuras, luces, partículas y el fuego. Los `Label3D` sí entran (rótulos sobre las figuras, marcas de misión «!» y «?», números de daño, el letrero «Portal»): usan las letras y los colores de texto del design system.

### M-63. La fila elegida y el cursor ▶

- `scripts/ui/menu_cursor.gd` (`MenuCursor`), desde la propuesta: un cursor dorado ▶ por ventana con menú. Sigue al botón con foco o, en un móvil, al último tocado.
- La fila elegida lleva el fondo `surface-selected`. Desaparece el recuadro gris de foco del motor.
- Lo llevan todas las ventanas con filas: título, ranuras, nombre (la rejilla de letras), dificultad, pausa y todas sus páginas, tienda, preguntas (`ChoiceWindow`), combate (el menú de órdenes y sus páginas), opciones, teclas y depuración.
- Se respetan las reglas de `3-interaccion.md`: ↑/↓, tocar elige, tocar fuera vuelve, 0,3 s de bloqueo y el parpadeo al abrir (ya existen), y las filas desactivadas fuera de la cadena de foco.
- Una fila desactivada se ve en `text-disabled` y su motivo en `caption`.

### M-64. Tipografía

- Las dos letras, como `FontVariation` del archivo variable (`UiTheme.font()`):
  - `ui` = Nunito, para todo el texto de ventana;
  - `display` = Baloo 2, para el logotipo, los rótulos de lugar, los números de daño y las marcas de misión.
- Los trece tamaños sueltos pasan a los **diez estilos** de `2-fundamentos.md` (de `display-xl` 96 a `micro` 16, con `body` 24 como base). La tabla de `6-migracion.md` dice cómo: 22 → 20, 28 → 26, 44 → 48 y 72 → 64.
- Los contornos pasan a `outline-s/m/l/xl` (4, 8, 12, 18).
- Todo tiene que seguir cabiendo:
  - en 740 × 360 (un móvil apaisado) y con texto grande;
  - en 1024 × 576 virtuales (texto grande en escritorio).
  
  Nunito es algo más ancha que la letra del motor. Si una ventana deja de caber, se ajusta su ancho con los `window-w-*` o el texto se parte en líneas, nunca a base de bajar el tamaño de un estilo. Los diseños de móvil se comprueban con `--touch` a 740 × 360.
- `NameEntry` y su rejilla usan `body`. El título usa `TitleLogo` (`display-xl`, o `display-l` en un móvil), y su subtítulo `title-l`.

### M-65. Accesibilidad y tono

- La barra de EXP pasa a `stat-exp` #237a33, que con blanco encima da 5,4:1. El texto secundario pasa a `text-secondary` #b8b8cc.
- Toda ventana lleva `shadow-window`, la sombra de `UiTheme.window_style()`. Todas tienen el mismo marco, radio y relleno, de `space-4` × `space-3`.
- **Opción nueva «Alto contraste»** en Opciones, junto a «Texto grande». Va en `GameOptions.high_contrast`: `to_dict()` / `from_dict()` y, si falta, `false`. Aplicarla pone `UiTokens.high_contrast` y vuelve a construir el tema. Los colores son los de `ALTO_CONTRASTE`. Se aplica al momento, como las demás opciones. Si hace falta reabrir una ventana para ver el cambio, se dice en la descripción de la opción.
- Los textos de la interfaz se repasan con `1-voz-y-tono.md`:
  - solo mayúscula inicial;
  - signos de apertura;
  - las cifras con su forma fija («PV 42/42», «50 G», «×3»);
  - el punto medio entre datos;
  - motivos en gris en vez de errores;
  - foco en «No» cuando una pregunta borra algo;
  - sin emojis.
  
  Solo se cambian los textos que incumplan alguna de estas reglas. Las frases de los personajes no se tocan.

### M-66. Componentes del design system

Cada componente de `components/*.md` se comprueba contra lo que ya hay en el juego y se lleva a su guía:

- **Window**, **DialogueBox** (con indicador de «sigue» ▼ cuando el diálogo espera, y el nombre de quien habla en `text-accent`), **Notice** (con tono: la palabra «Misión cumplida» / «Guardado», y su color), **ChoiceWindow**.
- **MenuList**, **ItemRow**, **ShopRow** (las comparaciones ▲/▼ en `text-positive` / `text-negative`), **OptionRow** (deslizadores y selectores con el estilo del design system: pista `surface-track`, relleno `border-focus`, el selector elegido en dorado).
- **StatBar** (con PV críticos: texto `text-danger` y un latido de 1 s por debajo del 25 %), **StatusBadge** (la insignia nueva «Aturdido», `status-stun`, para el `STUN` de la 2.2.0), **HeroPanel**.
- **EnemyBar**, **DamageNumber** (`display`, los colores de `element-*`).
- **PlaceBanner** (`display-m`, con su animación de entrada y salida), **TitleLogo**, **InteractionPrompt** (en un móvil, el botón de acción redondo, `radius-full`), **QuestMark** («!» y «?» en `display` y `quest-mark`), **MapSquare** (`MapWindow`, las marcas `map-*`).
- Las capas de pantalla (`CanvasLayer.layer`) pasan a las constantes `LAYER_*`. Si una pantalla no encaja en la lista, se añade una constante y se anota.

## Lo que no cambia

- Las reglas del juego, los guardados (versión 14) y los textos de los personajes.
- El mundo 3D: colores de zonas, figuras, luces y partículas.
- La estructura de las pantallas. Solo cambia su aspecto, salvo para que algo quepa.

## Comprobación

Sin tests, como siempre:

- `--check-only` de los scripts cambiados e `--import` tras añadir clases y letras.
- Fotos, antes y después, de cada pantalla con interfaz: título, ranuras, nombre, dificultad, mapa con HUD, diálogo, aviso, rótulo de lugar, pausa y cada página (Estado, Hechizos, Objetos, Equipo, Mapa, Diario, Bestiario, Opciones, Teclas), tienda, pregunta, combate (menú, hechizos, objetos, objetivo, insignias, resultado de victoria y de derrota), créditos y depuración.
- Cada foto en tres versiones:
  - escritorio 1280 × 720;
  - texto grande;
  - `--touch` a 740 × 360.
- Con «Alto contraste» activado, al menos el mapa, la pausa y el combate.
- La partida automática entera de la v1 y la de la caravana siguen terminando sin ERROR.
- Lo que solo se ve en un móvil real (si la letra se lee y si todo cabe al tacto) queda pendiente para el usuario.
