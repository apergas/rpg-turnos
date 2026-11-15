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
Estructura de carpetas:

Núcleo (igual en todos los juegos, nunca se edita desde un juego):
```
addons/design_system/
├── README.md                  qué es, cómo se instala, cómo se configura
├── tokens/
│   └── base.json              escalas + semánticos genéricos, valores neutros
├── runtime/
│   ├── ds_tokens_base.gd      lectura de tokens que no depende del juego
│   └── ds_theme.gd            base de UiTheme: build(), menu_row(), add_cursor(),
│                              style_label(), style_3d(), ventana, filas, botones, sliders
├── tools/
│   ├── gen_ui_tokens.gd       genera UiTokens + tokens.css desde base.json + el del juego
│   └── check_ui_values.gd     prohíbe colores y tamaños escritos a mano
├── hooks/
│   └── pre-commit             el hook actual, llamando a tools/
└── docs/
    ├── 2-fundamentos.md       escalas y semánticos genéricos
    ├── 3-interaccion.md
    ├── 4-accesibilidad.md
    ├── 5-godot.md
    └── components/
        ├── Window.md, MenuList.md, ChoiceWindow.md, Notice.md, OptionRow.md
        └── bundle.css         estilos de esos componentes para las páginas de docs
```

Capa del juego (Villaclaro):
```
design_system.json             configuración: rutas de tokens, salidas, docs y carpetas de UI a revisar
docs/boost/design-system/      (o design_system/ en la raíz, en un juego nuevo)
├── README.md                  la identidad del juego (azul marino, dorado...)
├── tokens.json                "extends": base.json; paleta, fuentes, tokens propios
├── tokens.css                 GENERADO (base + juego)
├── 1-voz-y-tono.md
├── 2-fundamentos.md           solo lo añadido: stat-*, status-*, map-*, world-*, layer-*
├── 6-migracion.md
└── components/
    ├── BestiaryCard.md, ShopRow.md, HeroPanel.md, QuestMark.md, MapSquare.md...
    └── bundle.css             estilos de esos componentes
scripts/ui/
├── ui_tokens.gd               GENERADO (class_name UiTokens, como ahora)
└── ui_theme.gd                UiTheme extends DsTheme: badge_style(), map_style()...
assets/fonts/                  Baloo 2 y Nunito: las fuentes son del juego, no del núcleo
```
`--check` exige que cada token esté documentado en los docs del núcleo o en los del juego, según de dónde venga.
Estado: Pendiente

## 2026-11-15 · Equipo: el efecto debajo del nombre
en el equipo, sale todo seguido el nombre dle objeto y lo que da. cambialo, poniendo lo que da (ATK +X, inmune a X..) debajo del nombre, tipo en la seccion de "objetos"
Estado: Pendiente

## 2026-11-15 · Combate: deshabilitar el menú al elegir Atacar
en un combate, cuando pulsas atacar, sigue saliendo el menu con atacar, hechizos, objetos... aunque no puedes seleccionar nada (solo puedes pulsar en volver). pon que, si pulsas en el boton de atacar, las otras opciones se pongan en gris clarito o algo asi, para dar a entender que estan deshabilitadas, o simplemente que no aparezcan en el menu, y ya si pulsas en volver ya vuelve a ponerse como de normal
Estado: Pendiente

## 2026-11-15 · Revisar el daño de los hechizos con el nivel
revisar daño de los hechizos. si por ejemplo llamarada hace el mismo daño tengas el nivel que tengas, no estaria bien. esta mejor que, mientras vas subiendo de nivel, que aumente tambien el daño de los hechizos. sin pasarse, pero que no se quede siempre con el mismo daño. con curar no pasa, lo de curar que te cure siempre lo mismo. si realmente ya funciona asi, no hagas nada. es decir primero se comprueba como funciona, y luego si hay que cambiarlo se cambia
Estado: Pendiente

## 2026-11-15 · Separar la tienda y el armero
en la tienda, separarla por el tipo de objeto. un personaje sera el armero, y otro la tienda que tenemos actualmente. en la tienda se podran comprar los objetos consumibles (pociones, eter, ala de viaje, etc) y en el armero los objetos de equipo (arma, armadura, casco etc). vender objetos se podra hacer en los dos
Estado: Pendiente

## 2026-11-15 · El compañero mejora en cada zona
Relacionada con «Revisar el daño de los hechizos con el nivel»: primero se comprueba cómo funciona ahora y solo se cambia si hace falta.
lo mismo que he dicho de los hechizos, vale para el acompañante (a partir de la v2, los animales no). cuando pasas de zona (de jungla a desierto-montaña-etc), en cada cambio de zona, que sea un poco mejor. puedes ir añadiendole objetos tambien, que no tenga siempre el mismo equipo, por ejemplo al cambiar de zona le pones un casco, luego en otra zona le pones una espada mejor, etc
Estado: Pendiente

## 2026-11-15 · Estado: las estadísticas del compañero debajo de su nombre
en estado, donde sale tadeo, pon tambien sus stats debajo de su nombre
Tadeo es un ejemplo: vale para el compañero que se lleve, sea cual sea (las estadísticas que tiene en ese momento, con lo que haya crecido).
Estado: Pendiente

## 2026-11-15 · Barrio del portal: sin portal en el fondo de los combates
cuando llegas al "barrio del portal", en los combates, que no se vea el portal del fondo (cuando estas en una batalla, lo que es el escenario de la batalla)
Excepción: en el combate contra el jefe (el Devorador) el portal sí tiene que verse en el fondo.
Estado: Pendiente

## 2026-11-15 · Combate: los objetos van antes que los ataques
no se si funciona asi, compruebalo, pero los objetos tienen preferencia a los ataques/hechizos, tambien de los enemigos. es decir, aunque un enemigo tenga mas velocidad que tu, al usar un objeto en combate (pocion, eter o lo que sea) siempre va primero. una vez te tomas el pocion o lo que sea ya es el turno del enemigo, compañero o a quien le toque
(tipo pokemon)
Estado: Pendiente

## 2026-11-15 · Portal rojizo entre la Caravana y Brumaclara
cuando finalizas el v2 vas al v3, el portal que sale actualmente es azul. cambialo para que tenga la mismaa forma pero rojizo (para diferenciarlo de los portales del ala de viaje)
Estado: Pendiente
