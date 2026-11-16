# Versión 3.7.0: Salir, buscar actualizaciones y sin Incienso

Fecha: 2026-11-16. Estado: spec. Cubre M-101, M-102 y M-103 del [documento maestro](../documento-maestro.md). Va después de la 3.6.2. La partida guardada sigue en la **versión 16**: no gana ni pierde campos.

## Objetivo

1. **Salir y buscar actualizaciones (M-101).** En el menú de pausa, «Volver al título» pasa a llamarse «Salir», y justo debajo hay una opción nueva, «Buscar actualizaciones». Esta opción mira si hay una versión más nueva del juego en la web: si la hay, la instala, y si no, avisa de que ya tienes la más reciente.
2. **La versión en el menú (M-102).** Con el menú de pausa abierto se ve el número de versión, en el mismo sitio y con el mismo estilo que en la pantalla del título.
3. **Sin Incienso (M-103).** Como los monstruos se ven en el mapa, el Incienso ya no hace falta: deja de existir.
4. **Equipo sin totales (M-106).** La página «Equipo» del menú de pausa deja de mostrar la línea «ATK · DEF · VEL» con los totales del héroe, porque ya se ven en «Estado».

## Decisiones tomadas (2026-11-16)

| Tema | Decisión |
|---|---|
| Dónde sale «Buscar actualizaciones» | Solo en la web, que es lo que se actualiza solo. En Windows y Linux la opción no aparece, porque esas versiones se descargan a mano desde itch.io |
| Qué pasa antes de actualizar | Se pregunta primero. Si aceptas, se guarda la partida como con «Guardar» y el juego se recarga con la versión nueva |
| Dónde se ve la versión | En todas las páginas del menú de pausa, abajo a la derecha, mientras el menú está abierto |
| El Incienso que lleve una partida | Al cargarla desaparece, y cada Incienso se convierte en su precio de venta en oro, sin aviso |

## 1. Salir y buscar actualizaciones (M-101)

### Lo que ve el jugador

- En la ventana de sistema del menú de pausa, las filas quedan así: «Guardar», «Opciones», «Salir», «Buscar actualizaciones» (solo en la web) y «Cerrar».
- **«Salir»** abre la misma página de confirmación de hoy, que ahora se titula «Salir». Mantiene el texto «Lo que no esté guardado se perderá.» y los botones «Sí, salir» y «No». Salir lleva a la pantalla del título, como antes.
- **«Buscar actualizaciones»** pone «Buscando actualizaciones…» en el mensaje de la ventana, el mismo sitio donde sale «Partida guardada.», y pregunta a la web qué versión está publicada. Hay tres resultados posibles:
  - **Ya tienes la última** (la publicada es igual o más antigua que la tuya): «Ya tienes la versión más reciente (v3.7.0).»
  - **No se puede comprobar** (no hay conexión, el servidor no responde en 10 s o la respuesta no se entiende): «No se ha podido comprobar. Mira tu conexión.»
  - **Hay una más nueva:** se abre una página «Actualizar» con el texto «Hay una versión nueva: v3.7.1. Se guardará la partida y el juego se recargará.» y los botones «Actualizar» y «Ahora no». «Ahora no» vuelve a la ventana principal.
- **«Actualizar»:**
  1. Guarda la partida, igual que «Guardar».
  2. Pone «Descargando la versión nueva…».
  3. Borra la copia del juego que guarda el navegador y descarga los archivos nuevos.
  4. Recarga la página. El jugador vuelve a la pantalla del título con la versión nueva y continúa su partida desde la ranura.
  
  Si la descarga falla, se queda en el menú con «No se ha podido descargar. Inténtalo más tarde.» y la versión vieja sigue funcionando.
- Mientras busca o descarga, las filas del menú siguen funcionando. Pulsar otra vez «Buscar actualizaciones» con una búsqueda en curso no hace nada.

### Cómo funciona

- **La versión publicada.** `.github/workflows/pages.yml`, después de exportar, escribe `build/web/version.json` con el número de `application/config/version` de `project.godot`: `{"version": "3.7.0"}`. Ese archivo no está en las listas del service worker, así que siempre se pide a la red. Para que tampoco lo sirva la caché HTTP del navegador (GitHub Pages pone `max-age=600`), la petición lleva `?t=<marca de tiempo>`.
- **La comparación.** La versión es `mayor.menor.parche` y se compara número a número: 3.10.0 es más nueva que 3.9.2. Una versión que no se entiende cuenta como «No se ha podido comprobar».
- **La pieza.** La búsqueda y la instalación son una pieza nueva de `Game`, `WebUpdate`: un `Node` hijo de `Game` con `SessionContext`, como las demás. Hace la petición con un `HTTPRequest` hijo suyo y avisa del resultado con una señal. El menú de pausa solo emite «buscar» o «actualizar» y muestra lo que le devuelven. La regla de la comparación es pura y va en una función estática que no toca nodos.
- **La instalación** se hace con `JavaScriptBridge.eval()`, solo en la web. Hace tres cosas:
  1. Borra las cachés del service worker de este juego, las que empiezan por el `CACHE_PREFIX` de la exportación (`Villaclaro`…`-sw-cache-`), y nunca otras: el origen `apergas.github.io` lo comparten otros proyectos.
  2. Quita el registro del service worker de esta página y descarga `index.html`, `index.js`, `index.wasm` e `index.pck` con `cache: 'reload'`. Así la caché HTTP también queda con los archivos nuevos.
  3. Recarga con `location.reload()`. Al arrancar, el motor vuelve a instalar el service worker, igual que hoy.
  
  Para devolver a GDScript si la descarga salió bien o mal, el JavaScript usa un callback de `JavaScriptBridge.create_callback()`.
- **El resto de plataformas.** La fila solo se crea si `OS.has_feature("web")`. El piloto automático no usa el menú de pausa, así que no cambia.

## 2. La versión en el menú (M-102)

- Es la misma etiqueta de la pantalla del título: «v» y el número de `application/config/version`, con el estilo `caption`, `text-primary` y el contorno `OUTLINE_S` en `text-outline-warm`. Está anclada abajo a la derecha con el margen `SPACE_3`.
- Está en la capa del menú de pausa, así que se ve en todas sus páginas y se va al cerrarlo. No tapa ninguna ventana: el menú no usa esa esquina, y se comprueba con capturas a 1280 × 720 y a 740 × 360.
- Para que el título y el menú no la escriban cada uno a su manera, la etiqueta sale de un único constructor de UI (por ejemplo `UiTheme.version_label()`) que usan los dos.

## 3. Sin Incienso (M-103)

- El Incienso (`incienso`) sale de `Inventory.ITEMS` y de todas las listas de `Shop.SHOPS`. Con él se va su efecto `repel`, y todo lo que existía solo para él:
  - `GameState.repel_m` y su cuenta de metros en `Game`;
  - el aviso «El incienso se ha consumido.»;
  - `World.set_repel()` y lo que monta en `MapMonsters` (`_repelled`, `is_repelled()`);
  - el caso `"repel"` del menú de pausa;
  - las menciones en los comentarios.
- Los monstruos siguen viéndose medio transparentes cuando acabas de huir de ellos: eso no era del Incienso.
- **Partidas con Incienso.** Al cargar, `SaveData` quita `incienso` del inventario y suma al oro su precio de venta (`Shop.sell_price()`) por cada unidad. No hace falta otra versión de guardado. Una partida con Incienso sigue siendo válida.
- La guía de QA (`docs/legacy/qa/brief-qa-agentes.md`) y los textos que lo nombren se actualizan.

## 4. Equipo sin totales (M-106)

- La página «Equipo» se queda con la lista de las seis ranuras, cada una con lo que da su pieza debajo. La línea fija de debajo, «ATK %d   DEF %d   VEL %d», desaparece: se borran `_equip_stats` en `pause_menu.gd`, su creación en `_build_equipment()` y su relleno en `_fill_equipment()`.
- La comparación junto a cada pieza de la bolsa, al elegir una ranura, se queda como está.
- «Estado» sigue mostrando la línea «ATK · DEF · VEL» con los totales, sin cambios.

## Verificación

- `--check-only` en los scripts cambiados, `gen_ui_tokens.gd -- --check` y `check_ui_values.gd`.
- Capturas del menú de pausa con la versión, a 1280 × 720 y a 740 × 360 (`--touch`), en escritorio, donde no sale «Buscar actualizaciones».
- La web exportada a `build/web` y servida en local, con un `version.json` escrito a mano:
  - igual a la versión del juego → «Ya tienes la versión más reciente»;
  - más nuevo → la página «Actualizar», y al aceptar se guarda, se recarga y el título sale bien;
  - sin `version.json` → «No se ha podido comprobar».
- Cargar una partida con Incienso: desaparece y el oro sube lo que valía.
- Las carreras completas del piloto automático de la v1, la v2 y la v3 terminan sin errores nuevos.
