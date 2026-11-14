La interfaz de Villaclaro es una capa clásica de RPG de consola que flota sobre un mundo 3D low-poly luminoso: ventanas azul marino con marco blanco, texto blanco, dorado para lo importante y un color fijo para cada dato del héroe. Este sistema la ordena para que crezca sin perder esa identidad. Todo valor sale de un token, todo color tiene un significado y la selección se ve igual con teclado, ratón o dedo.

## Principios

1. **El mundo primero.** Ventanas translúcidas, pequeñas y en las esquinas; nunca tapan la acción sin motivo.
2. **Un color, un significado.** Rojo es PV, azul es PM, verde es EXP, dorado es «mira aquí» o dinero. Si un color ya significa algo, no se usa para otra cosa.
3. **Siempre se sabe dónde estás.** La fila elegida lleva el cursor dorado ▶ y un fondo, en cualquier dispositivo.
4. **Teclado, ratón y dedo por igual.** Todo se puede hacer con los tres; en móvil nada mide menos de `touch-target`.
5. **Legible sobre cualquier escena.** Las ventanas llevan sombra; el texto sobre el mundo lleva contorno.
6. **Nunca solo color.** Estados, comparaciones y marcas del mapa llevan siempre palabra, forma o signo.

## Cómo está organizado

- **Paleta base** (`navy-*`, `gold-*`, `red-*`, `blue-*`, `green-*`…): los colores en bruto. No se usan directamente en la interfaz.
- **Tokens semánticos**: lo que se usa. Cada uno dice para qué sirve y apunta a la paleta:
  - `surface-*`: fondos;
  - `border-*`: marcos y foco;
  - `text-*`: texto;
  - `stat-*`: barras del héroe;
  - `status-*`: estados de combate;
  - `element-*`: efectos;
  - `map-*`: marcas del mapa;
  - `world-*`: referencia del mundo.
- **Temas**: `juego` (el normal) y `alto-contraste` (opción de accesibilidad: ventanas opacas, texto a 7:1 o más). Solo cambian los semánticos.
- **Escalas**:
  - espaciado `space-1…12` en pasos de 4 px;
  - radios `radius-s/m/l/full`;
  - bordes `border-1/2/3`;
  - contornos de texto `outline-s…xl`;
  - medidas `size`;
  - capas de pantalla `layer-*`.
- **Tipografía**: dos familias. `display` es Baloo 2, para rótulos, logotipo y números; `ui` es Nunito, para todo lo demás. Diez estilos, de `display-xl` (96 px) a `micro` (16 px); `body` (24 px) es la base.

## Reglas rápidas

- Escribe `text-primary` sobre `surface-window`; las descripciones en `caption` con `text-secondary`.
- Títulos de ventana en `title-s` con `text-accent`. El oro siempre en `text-money`.
- Una ventana: `surface-window`, marco `border-3` `border-window`, `radius-m`, relleno `space-4` × `space-3`, `shadow-window`.
- Separa ventanas con `space-4` y despégalas del borde de la pantalla con `space-6`.
- Texto sobre el mundo: blanco con `outline-m` en `text-outline`, o dorado `text-display` con `outline-l` en `text-outline-warm`.
- Nunca escribas un color o un tamaño a mano en un script: usa `UiTokens` (sección Implementación en Godot).

## Iconografía

No hay fuente de iconos: la interfaz se apoya en el texto. Los pocos pictogramas se dibujan en código para que se vean igual en la web:
- el botón ☰: tres barras blancas de 32 × 5;
- el cursor ▶ y las flechas ▲▼ de comparación: triángulos;
- las marcas de misión «!» y «?»: texto 3D en `display`;
- las marcas del mapa: cuadrados de 5 px.

Las únicas imágenes de la interfaz son los retratos del bestiario (grupo **Bestiary**) y el icono de la app (grupo **Logos**). No hay logotipo en archivo: «Villaclaro» se compone siempre con TitleLogo.

## Componentes

- **Ventanas**: Window, DialogueBox, Notice, ChoiceWindow.
- **Menús**: MenuList, ItemRow, ShopRow, OptionRow.
- **Héroe**: StatBar, StatusBadge, HeroPanel.
- **Combate**: EnemyBar, DamageNumber.
- **Bestiario**: BestiaryCard.
- **Mundo**: PlaceBanner, TitleLogo, InteractionPrompt, QuestMark, MapSquare.

Las vistas previas son representaciones estáticas en HTML/CSS (`components/bundle.css`). En el juego, cada componente se construye en Godot con el tema de `godot/ui_theme.gd`.
