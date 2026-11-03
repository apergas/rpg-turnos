# Sensación de juego: diseño

Fecha: 2026-11-03
Paso: fase 2 de `2026-11-03-ideas-juego-completo.md`. Va después de la fase 1 (cámara, hierba y modelos low-poly).

## Objetivo

Que el juego se sienta completo al arrancarlo:

- **Música y efectos de sonido.**
- **Pantalla de título.**
- **Guardar y cargar partida**, también en la web.
- **Menú de pausa** con el estado del héroe y los objetos, que también se puede abrir en el móvil.

## Decisiones tomadas

El usuario pidió que no se le pregunte, así que todas son la opción recomendada.

| Tema | Decisión |
|---|---|
| Origen del audio | **Generado en código**, sin descargar nada: melodías originales tipo chiptune y efectos tipo sfxr. Las ondas se calculan al arrancar en `AudioStreamWAV` y se guardan para reutilizarlas. Funciona igual en la web y no necesita licencias |
| Música | Una pista corta en bucle (20-40 s) por situación: **título**, **mapa**, **pueblo** (en el claro de Villaclaro), **combate**, **jefe**, **victoria** (fanfarria corta, sin bucle) y **derrota** (sin bucle). Melodía en onda cuadrada, bajo en triángulo y percusión de ruido; tempo y tonalidad propios para cada una |
| Composición | Las melodías son **originales**: notas escritas en tablas dentro de `MusicLibrary`. No se copia ninguna melodía de juegos existentes |
| Efectos | Cursor del menú, aceptar, cancelar, golpe, golpe crítico, fallo, hechizo de fuego, curación, subir de nivel, encuentro, poción, pasos (suaves, solo en el mapa), abrir el diálogo, guardar |
| Reproductor | `Audio` **no es un autoload** (regla del proyecto): `Game` crea un nodo `AudioDirector` y se lo pasa a quien lo necesita. Tiene `play_music(id)` con un fundido cruzado de 0,5 s y `play_sfx(id)`. Los volúmenes de música y efectos van por separado y se guardan en las opciones |
| Pantalla de título | Nombre del juego (provisional: **"Villaclaro"**) sobre la pradera vista desde la cámara cenital, que se mueve despacio. Botones **Nueva partida**, **Continuar** (desactivado si no hay partida guardada) y **Opciones**. Funciona con teclado, ratón y toque |
| Guardado | **Un archivo**, `user://save.json`: en la web Godot lo guarda en el navegador (IndexedDB). Guarda el héroe (nivel, PV, PM, EXP y estadísticas), el inventario, la misión, la posición en el mapa y el tiempo jugado. Hay un número de versión para poder migrar el formato más adelante |
| Cuándo se guarda | **Autoguardado** al hablar con la anciana (que ya cura) y después de cada combate ganado. También **a mano** desde el menú de pausa. No se guarda en medio de un combate |
| Derrota | Sigue igual: vuelves al inicio curado. El autoguardado posterior guarda esa situación |
| Menú de pausa | Esc o P en el teclado, y un **botón ☰** en la esquina superior derecha para el ratón y el móvil. Opciones: **Estado** (nivel, PV, PM, ATK, DEF, VEL, EXP y lo que falta para el siguiente nivel), **Objetos** (lista; la poción se puede usar fuera de combate), **Guardar**, **Opciones** (volumen de música y de efectos, velocidad del texto) y **Volver al título**. Mientras está abierto, el mapa se pausa |
| Opciones | Se guardan aparte, en `user://options.json`: volumen de música (0-100 %, por defecto 70 %), volumen de efectos (por defecto 80 %) y velocidad del texto (lenta, normal o rápida) |
| Reglas puras | `SaveData` (`RefCounted`) convierte el estado en un `Dictionary` y al revés, sin tocar nodos ni archivos. `SaveStore` lee y escribe los archivos. Así la conversión se puede revisar sin ejecutar el juego |

## Arquitectura

- **`scripts/audio/music_library.gd` (`MusicLibrary`):**
  - Tablas de notas por pista.
  - `static func build(id) -> AudioStreamWAV`, con caché.
  - Síntesis: cuadrada al 25 o 50 %, triángulo y ruido, con una envolvente sencilla, a 22.050 Hz y 16 bits mono para que ocupe poco.
- **`scripts/audio/sfx_library.gd` (`SfxLibrary`):** cada efecto es un `Dictionary` de parámetros: onda, frecuencia inicial y final, duración, decaimiento y ruido. `static func build(id) -> AudioStreamWAV`, con caché.
- **`scripts/audio/audio_director.gd` (`AudioDirector`, `Node`):**
  - Dos `AudioStreamPlayer` para la música, que permiten el fundido cruzado.
  - Un grupo de 6 reproductores para los efectos.
  - `set_volumes(music, sfx)`.
  - En `--autoplay` y `--headless` funciona igual pero no suena.
- **`scripts/game/save_data.gd` (`SaveData`):** `static func from_state(state, player_pos, play_time) -> Dictionary` y `static func apply(state, data) -> Dictionary`. El segundo devuelve la posición, el tiempo jugado y si el formato era válido.
- **`scripts/game/save_store.gd` (`SaveStore`):** `has_save()`, `save(data)`, `load() -> Dictionary` (vacío si falta o está roto) y lo mismo para las opciones.
- **`scenes/title/title.tscn` + `scripts/title/title_screen.gd` (`TitleScreen`):** pasa a ser la escena principal (`run/main_scene`). Emite `new_game` o `continue_game`, y `Game` se crea desde ahí.
- **`scripts/ui/pause_menu.gd` (`PauseMenu`, `Control`):** la ventana con las opciones de arriba. Reutiliza `BattleHud.make_window()`.
- **Cambios en `Game`:**
  - Recibe si es una partida nueva o cargada.
  - Crea el `AudioDirector` y cambia de música según la situación: mapa, pueblo al entrar en el claro, combate, jefe, victoria y derrota.
  - Hace los autoguardados.
  - Abre el menú de pausa.
- **Música y efectos de otras clases:** `World`, `BattleScene`, `BattleHud` y `DialogueBox` reciben el `AudioDirector` (`set_audio(director)`) para los efectos. Si no lo tienen, no suenan; es lo que pasa en las escenas sueltas.
- **Autoplay:**
  - Arranca directamente en una partida nueva, sin pasar por el título.
  - Para probar el guardado existe la opción `--autoplay-save`: la partida automática guarda, vuelve al título y continúa desde el guardado, imprimiendo los valores antes y después.

## Verificación (sin tests)

- `--check-only` en cada script nuevo y cambiado; `--import`.
- **Autoplay completo:** la misión entera sin ERROR ni WARNING. Con `--autoplay-save`, los valores impresos antes y después del guardado deben coincidir.
- **Audio:**
  - Una partida con ventana y sonido, comprobada a mano.
  - Un script de un solo uso que genere cada pista y efecto, imprima la duración y compruebe que ninguna muestra satura.
- **Fotogramas:** título, menú de pausa (Estado y Objetos) y opciones.
- **Versión web:**
  - Se exporta y arranca en el navegador.
  - Se guarda, se recarga la página y "Continuar" carga la partida.
  - En la web, el audio solo empieza después del primer clic o toque. Es un límite de los navegadores, y la pantalla de título lo cumple de forma natural.

## Fuera de alcance

- Varias ranuras de guardado (con una basta para un juego de 2 horas).
- Exportar o importar la partida como archivo.
- Idiomas.
- Reasignar teclas.
