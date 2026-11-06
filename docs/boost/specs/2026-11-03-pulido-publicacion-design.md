# Pulido y publicación: diseño

Fecha: 2026-11-03
Paso: fase 7 de `2026-11-03-ideas-juego-completo.md`, la última. Va después de la fase 6 (historia).

## Objetivo

Dejar el juego listo para enseñarlo fuera:

- Opciones completas, dificultad y accesibilidad.
- ~~Inglés además de español.~~ Descartado por el usuario (2026-11-06): el juego queda solo en español.
- Controles táctiles completos.
- Versiones de escritorio.
- Página en itch.io.

## Decisiones tomadas

El usuario pidió que no se le pregunte, así que todas son la opción recomendada.

| Tema | Decisión |
|---|---|
| Opciones | Se amplía la ventana de la fase 2 con: velocidad de combate (x1, x2, mensajes instantáneos), pantalla completa (solo en escritorio), calidad gráfica (**alta**: hierba completa y sombras; **baja**: la mitad de hierba, sin sombras y sin SSAO) y temblor de cámara (sí / no). Por defecto: x1, ventana, alta y temblor |
| Dificultad | **Fácil** o **Normal**, al empezar una partida y también desde Opciones. Fácil: un 30 % menos de daño recibido y un 25 % más de EXP. Se guarda en la partida |
| Accesibilidad | Textos grandes (+25 % en todas las ventanas), quitar el temblor y **reasignar teclas** (moverse, aceptar, cancelar y pausa). Quitar los encuentros aleatorios **no** se incluye, porque rompe el equilibrio |
| Idiomas | Todo el texto pasa por el sistema de traducción de Godot (`tr()` y un CSV en `i18n/`). Español (`es`) e inglés (`en`). Elección en Opciones, y en la web se detecta el idioma del navegador al empezar |
| Táctil | En el móvil (pantalla táctil detectada): zoom de la cámara con dos dedos, botones más grandes en los menús y una mano en el aviso de hablar ("Toca para hablar"). El movimiento con toque ya existe |
| Escritorio | Presets de exportación **Windows** y **Linux**: un ejecutable con los datos dentro. El workflow de GitHub crea los dos y los sube como artefactos de cada versión (tag `v*`) |
| Versión | Pantalla de título con el número de versión (`1.0.0`) en una esquina. Archivo `CHANGELOG.md` en español |
| itch.io | Se prepara la página: `docs/itch/descripcion.md`, capturas (5 fotogramas elegidos), icono y portada (630 × 500, hecha con el propio juego: el héroe en la pradera con el título). La **subida** la hace el usuario o se automatiza con `butler` y su clave; publicar necesita su permiso explícito |
| Nombre definitivo | **"Villaclaro: la Niebla del Norte"**. El nombre corto "Villaclaro" queda para el título y el icono |
| Icono | Hecho con el propio juego: la cara del slime sobre fondo verde, en 256 × 256, exportado a `icon.png`. También se usa en la web y en Windows |
| Rendimiento | Revisión final en el móvil y en la web: la calidad baja tiene que dar 30 FPS o más en un móvil medio; si no, se reduce la hierba |
| Cierre | Repaso de los mensajes por erratas, de los textos que se salen de las ventanas en los dos idiomas, y de todos los "fuera de alcance" de las fases anteriores. Se apunta en `ideas-sueltas.md` lo que no entre |

## Arquitectura

- **`Options`** (`RefCounted`): todas las opciones, y `SaveStore` las guarda. Las escenas leen de ahí: `BattleHud` la velocidad, `FollowCamera` el zoom táctil, `Vegetation` la densidad de la calidad y `BattleScene` el temblor.
- **`Difficulty`**: los multiplicadores que aplica `BattleEngine` (el daño al héroe) y la EXP de la victoria.
- **Teclas:** las acciones de teclado del proyecto (`move_up`, `move_down`, `move_left`, `move_right`, `accept`, `cancel`, `pause`) sustituyen a las teclas fijas de `Player`, `BattleHud` y los menús. Así se pueden reasignar con `InputMap`.
- **Traducciones:** `i18n/textos.csv` con columnas `keys,es,en`. Las claves son los textos actuales en español, para no tener que reescribir todo.

## Verificación (sin tests)

- `--check-only` en los scripts tocados.
- **Autoplay completo** en cada idioma y en cada dificultad, sin ERROR ni WARNING.
- **Fotogramas** de cada ventana en inglés, para buscar textos que se salgan.
- **Exportaciones** web, Windows y Linux sin errores. El ejecutable de Windows se arranca a mano en este PC.
- **Web en un móvil:** lo prueba el usuario.

## Fuera de alcance

- Consolas.
- Logros en plataformas.
- Más idiomas.
