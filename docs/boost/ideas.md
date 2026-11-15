# Ideas

Registro de ideas para Villaclaro. Cada idea se apunta tal cual llega, con su fecha, sin plan ni compromiso. Cuando una idea pase a hacerse, se mueve al `documento-maestro.md` y aquí se marca como "Pasada al maestro".

Formato de cada entrada:

```
## AAAA-MM-DD · Título corto
Idea en una o pocas frases, con las palabras del usuario.
Estado: Pendiente | Pasada al maestro | Descartada
```

---

## 2026-11-14 · Acompañante visible en el mapa
que el acompañante, ya sea el de la v1 (criatura) como el de la v2 (compañero) se vean en el mapa. que no se pueda interactuar con ellos, pero que se vean. que vayan andando a poca distancia, y que si el personaje esta quieto, esten quietos tambien.
Estado: Pendiente

## 2026-11-15 · Vender sin equipo puesto ni objetos únicos
en el mercader, en la opcion de vender, que las cosas que llevas puesto no aparezcan, y las cosas que no se pueden vender (como la espada del alba o el escudo de medallas) tampoco
Estado: Pendiente

## 2026-11-15 · Rótulo sobre los personajes con función
el coleccionista, al igual que el jefe de la caravana y todos los personajes con los que se pueda interactuar para algo en concreto, que lo ponga encima (como posada, tienda, etc). si son personajes que estan de relleno (como los viajeros) no hace falta
Estado: Pendiente

## 2026-11-15 · Refactor: design system agnóstico para otros juegos de Godot
Posible refactor. Separar el design system en dos capas para poder reutilizarlo en otros juegos hechos en Godot:
- Núcleo reutilizable como addon (`addons/design_system/`): `gen_ui_tokens.gd` y `check_ui_values.gd` con rutas configurables (hoy van fijas a `res://docs/boost/design-system/...` y `res://scripts/ui/ui_tokens.gd`), la base de `UiTheme` (`build()`, `menu_row()`, `add_cursor()`, `style_label()`, `style_3d()`), un `tokens.json` base con escalas (espaciado, radios, bordes, contornos, opacidades, `touch-target`) y semánticos genéricos (`surface-*`, `border-*`, `text-*`, estilos de texto) con valores neutros, el mecanismo de temas (alto contraste), los componentes universales (`Window`, `MenuList`, `ChoiceWindow`, `Notice`, `OptionRow`) y las guías de interacción y accesibilidad.
- Capa de cada juego: su `tokens.json` con la paleta, las fuentes y sus tokens propios (en Villaclaro `stat-*`, `status-*`, `map-*`, `world-*`, `layer-*`, medidas como `enemy-bar-width`), sus componentes (`BestiaryCard`, `ShopRow`, `HeroPanel`...), su voz y tono, y una extensión de `UiTheme` (`badge_style()`, `map_style()`).
Villaclaro pasaría a ser el primer juego que consume el núcleo.
Pasos:
1. Ahora: separarlo dentro de este repo. Mover el núcleo a `addons/design_system/` (`tokens/base.json`, `runtime/`, `tools/`, `hooks/`, `docs/` con los componentes universales), dejar las herramientas con rutas configurables desde un `design_system.json` en la raíz, que el generador fusione `base.json` con el `tokens.json` del juego (dando error si el juego redefine un token sin querer), y que `UiTheme` extienda la base del núcleo. Lo generado (`ui_tokens.gd`, `tokens.css`) sigue en el juego. Excluir `docs/`, `tools/` y `hooks/` del addon en la exportación. Se comprueba con `gen_ui_tokens.gd -- --check`, `check_ui_values.gd`, ejecutando el juego y con capturas.
2. Solo si se hacen más juegos (la carpeta ya queda preparada para ello): crear un repo propio para el addon con `git subtree split --prefix=addons/design_system`, sustituir la carpeta por un `git submodule` en Villaclaro, poner `submodules: true` en el checkout de `pages.yml` y `release.yml`, clonar con `--recurse-submodules` y mantener el hook activándose desde `.githooks`. Un juego nuevo añade el submódulo, copia la plantilla de `design_system.json` y `tokens.json`, pone su paleta y fuentes y genera.
Estado: Pendiente
