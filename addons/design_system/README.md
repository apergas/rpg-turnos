# Design system: el núcleo

El núcleo de un design system para juegos hechos con Godot 4: las herramientas que generan los tokens y comprueban la interfaz, los tokens genéricos, la base del tema (`DsTheme`), el cursor de los menús (`MenuCursor`), el hook de git y las guías que valen para cualquier juego. Es igual en todos los juegos y **nunca se edita desde un juego**: lo propio de cada juego (su paleta, sus fuentes, sus tokens, sus componentes y su voz) va en su capa.

No es un plugin del editor y no lleva `plugin.cfg`: se usa sin abrir el editor. No usa ninguna clase del juego; solo el `UiTokens` que genera para él.

## Qué hay

| Carpeta | Qué |
| --- | --- |
| `tokens/base.json` | Las escalas, las medidas, los diez estilos de texto y los semánticos genéricos, con valores neutros. |
| `runtime/` | `DsTheme` (`ds_theme.gd`), la base del tema, y `MenuCursor` (`menu_cursor.gd`). Es lo único que entra en el juego exportado. |
| `tools/` | `gen_ui_tokens.gd` (genera `UiTokens` y `tokens.css`) y `check_ui_values.gd` (prohíbe colores y tamaños escritos a mano). |
| `hooks/pre-commit` | El hook que pasa las dos comprobaciones antes de cada commit. |
| `docs/` | Las guías: [fundamentos](docs/2-fundamentos.md), [interacción](docs/3-interaccion.md), [accesibilidad](docs/4-accesibilidad.md), [Godot](docs/5-godot.md) y las fichas de los componentes genéricos (`docs/components/`). |

## Las dos capas

- **El núcleo** (esta carpeta): lo que vale para cualquier juego.
- **La capa del juego**: su `design_system.json`, su `tokens.json` (paleta, fuentes, tokens propios y el valor que da a los del núcleo), sus guías (identidad, voz y tono, paleta, tokens propios, contraste) y las fichas de sus componentes, y su tema, que hereda de `DsTheme`. Lo generado (`UiTokens` y `tokens.css`) también es del juego.

Un token que valga para cualquier juego entra por `tokens/base.json` y estas guías; uno de un solo juego, por el `tokens.json` de ese juego y sus guías.

## Cómo se instala en un juego

1. Copia esta carpeta en `addons/design_system/`.
2. Crea `design_system.json` en la raíz del juego (abajo).
3. Crea el `tokens.json` del juego (abajo).
4. Genera: `godot --headless --path . --script res://addons/design_system/tools/gen_ui_tokens.gd`. Escribe el `UiTokens` y el `tokens.css` del juego en las rutas de `design_system.json`.
5. El tema del juego hereda de `DsTheme` y le pasa lo suyo con el `Callable` de `apply()`, `ensure()` y `build()`; antes de `apply()` pone `DsTheme.touch` ([Godot](docs/5-godot.md)).
6. El hook: el `.githooks/pre-commit` del juego es una línea, `exec bash addons/design_system/hooks/pre-commit "$@"`, y se activa una vez por clon con `git config core.hooksPath .githooks`.
7. En cada perfil de `export_presets.cfg`, `exclude_filter` añade `addons/design_system/tools/*`, `addons/design_system/hooks/*`, `addons/design_system/docs/*`, `addons/design_system/tokens/*` y `design_system.json`.
8. En la integración continua, después de `--import`: `gen_ui_tokens.gd -- --check` y `check_ui_values.gd`.

## design_system.json

```json
{
 "base": "res://addons/design_system/tokens/base.json",
 "tokens": "res://docs/design-system/tokens.json",
 "gd_out": "res://scripts/ui/ui_tokens.gd",
 "css_out": "res://docs/design-system/tokens.css",
 "docs": ["res://addons/design_system/docs", "res://docs/design-system"],
 "bundles": ["res://addons/design_system/docs/components/bundle.css",
             "res://docs/design-system/components/bundle.css"],
 "scan_roots": ["res://scripts", "res://addons/design_system/runtime"],
 "color_dirs": ["res://scripts/ui/", "res://addons/design_system/runtime/"]
}
```

- `docs`: carpetas con un `2-fundamentos.md` y una carpeta `components/`. **La primera es la del núcleo**; las demás, las del juego.
- `bundles`: los `bundle.css` de las fichas. **El primero es el del núcleo**, que solo puede usar variables del núcleo.
- `scan_roots`: dónde busca `check_ui_values.gd` los `.gd` (sin barra al final).
- `color_dirs`: dónde no puede haber `Color(` (con barra al final). `gd_out` es el único archivo que puede tenerlo.

## El tokens.json del juego

```json
{
 "name": "Mi juego",
 "extends": "res://addons/design_system/tokens/base.json",
 "overrides": [
  {"name": "text-accent", "value": "{oro-300}", "usage": "Títulos y quien habla, en el dorado del juego."}
 ],
 "color": {
  "themes": [
   {"id": "normal", "name": "Normal", "role": "normal"},
   {"id": "alto-contraste", "name": "Alto contraste", "role": "contrast"}
  ],
  "tokens": [
   {"name": "oro-300", "value": "#ffd94d", "usage": "Dorado de acento."}
  ]
 },
 "type": {
  "fonts": [
   {"family": "Mi letra", "godot_path": "res://assets/fonts/MiLetra.ttf", "role": "ui"}
  ],
  "families": {"ui": "\"Mi letra\", system-ui, sans-serif"}
 }
}
```

- **`"overrides"`** da valor, por nombre, a un token del núcleo. Cada campo que lleva, salvo `name`, sustituye al del núcleo.
- **Pisar sin querer es un error:** un token del juego con el nombre de uno del núcleo, fuera de `"overrides"`, hace fallar el generador y dice cuál. Lo mismo un override de un token que el núcleo no tiene.
- **Los temas:** el juego pone los ids. El de `role` `normal` y el de `role` `contrast` dan nombre a los dos diccionarios de `UiTokens` (`alto-contraste` → `ALTO_CONTRASTE`) y al selector `[data-theme="…"]` de `tokens.css`. Un color de dos temas lleva un valor por id.
- **`{nombre}`** apunta a otro color de cualquiera de las dos capas.
- **Las fuentes:** cada una lleva el `role` de una familia del núcleo (`display` o `ui`). Una familia sin fuente usa la letra del motor. `type.families` da la pila CSS de cada familia del núcleo; una familia que el núcleo no tiene es un error.
- Las demás secciones (`spacing`, `radius`, `border`, `outline`, `shadow`, `size`, `opacity`, `layer`) se suman a las del núcleo; `type.groups` añade estilos.

## Como submódulo de git

Hoy el núcleo vive dentro del repositorio del primer juego. Cuando haya un segundo:

1. Se crea su repositorio con `git subtree split --prefix=addons/design_system`, que conserva el historial.
2. En cada juego, la carpeta pasa a ser `git submodule add <url> addons/design_system`.
3. Los flujos de publicación ponen `submodules: true` en su `actions/checkout`; se clona con `--recurse-submodules`.
4. El `.githooks/pre-commit` del juego sigue llamando al hook del submódulo.
5. Un juego nuevo añade el submódulo, copia las dos plantillas de arriba, pone su paleta y sus fuentes y genera.

Un cambio del núcleo son entonces dos commits: uno en su repositorio y otro en el juego, para apuntar a la nueva versión.
