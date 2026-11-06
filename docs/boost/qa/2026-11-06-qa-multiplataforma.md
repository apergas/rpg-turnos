# Informe de QA multiplataforma: iPhone, Android y Chrome de escritorio

- **Fecha:** 2026-11-06, con un tramo final el 2026-11-07. La sesión se canceló antes de que acabaran los agentes.
- **Versión probada:** `https://apergas.github.io/rpg-turnos/`, rama `main` (`307209b`), título v1.0.0. Caché del service worker: `CACHE_VERSION 1793982045|2603560`, `Last-Modified: Fri, 06 Nov 2026 16:27:44 GMT`.
- **Método:** un orquestador y tres agentes de QA independientes, uno por plataforma, todos siguiendo `docs/boost/qa/brief-qa-agentes.md`. El orquestador era la sesión principal de Claude Code; los agentes, Claude Opus 5.5.
- **Máquina:** MacBook con M3 Pro, 18 GB de RAM, macOS (Darwin 25.6). No hay Godot en este Mac: todo se probó contra la web publicada.

| Agente | Entorno | Estado al cancelar |
|---|---|---|
| iPhone | Simulador iPhone 17, iOS 26.5, Safari 26.5. Vistazo en iPad Air 11" (M4) | Terminado, con informe completo |
| Android | Emulador Medium_Phone (Android API 37); Chrome 145, que se actualizó solo a 156 | Cortado por el límite de uso y luego cancelado. Solo dejó un borrador |
| Chrome escritorio | Chrome 156 en macOS, con el perfil real del usuario, 1920 × 1080 a DPR 2 | Terminó la primera ronda. La segunda (jugar hasta el final) se cortó por el límite de uso y se canceló sin resultados nuevos |

## Resumen

El juego **funciona en las tres plataformas** en los flujos probados: título, nombre, prólogo, mapa, combate, tienda, posada, cofres, pausa, opciones, guardado y carga. En el móvil se juega con el dedo en apaisado, también en Safari de iPhone con la barra visible. El arreglo de "Gira el móvil" (QA-01) se confirma en Chrome Android 156 y en Safari iOS. La banda negra a pantalla completa no se reprodujo en Android.

**Lo más grave:** "Nueva partida" borra sin aviso la partida guardada. Pasó de verdad durante la prueba con la partida del usuario, que se restauró de una copia.

Para un jugador nuevo, además:
- El objetivo principal desaparece de la pantalla en cuanto hay una misión secundaria.
- Nada sugiere subir de nivel antes del primer jefe.

En el móvil los problemas son de espacio: botones pequeños, sobre todo en Safari de iPhone y con "Textos grandes".

**Nadie jugó la partida completa.** Del bosque en adelante solo se vio con guardados inyectados.

| Severidad | Cantidad |
|---|---|
| Crítica | 0 |
| Alta | 1 |
| Media | 8 |
| Baja | 13 |

## Hallazgos

Los IDs `QAM-nn` son de este informe consolidado. Entre paréntesis va el ID del informe de cada agente: `WEB-` para Chrome, `IOS-` para iPhone y `AND-` para Android.

### Alta

#### QAM-01. "Nueva partida" sobrescribe la partida guardada sin pedir confirmación (WEB-01)

- **Evidencia:** reproducido en Chrome escritorio y confirmado en el código.
- **Pasos:** con una partida guardada, de hecho la real del usuario (nivel 20, terminada, 1:54 h), pulsar "Nueva partida", escribir un nombre, elegir dificultad y pasar el prólogo.
- **Obtenido:** no hay ningún aviso. A los 50 s, el autoguardado de después del prólogo escribe la partida nueva en el único hueco y la anterior se pierde.
- **Causa:** `scripts/title/title_screen.gd:287-289`. El botón emite `new_game` sin comprobar `SaveStore.has_save()`.
- **Sugerencia:** si hay partida guardada, preguntar Sí / No antes de abrir la ventana del nombre. Más adelante, quizá un segundo hueco.

### Media

#### QAM-02. El objetivo principal desaparece de la pantalla con cualquier misión secundaria (WEB-02)

- **Evidencia:** reproducido en pradera, bosque, mina y castillo, y deducido del código.
- **Obtenido:** en el bosque, con "carta" y "setas" aceptadas, la ventana de estado y la pausa solo muestran "Misión: carta a la Leñadora" y "Misión: setas 0 / 3". Nada habla de la Bruja. En el castillo pasa lo mismo con el Señor de la Niebla. Solo el Diario lo dice.
- **Causa:** `scripts/game/game_state.gd:71-75`. `goal_text()` solo se usa si `status_lines()` está vacío.
- **Sugerencia:** poner siempre primero la línea del objetivo principal y las secundarias debajo.

#### QAM-03. Con un guardado ilegible, el aviso llega tarde y se saltan el nombre y la dificultad (WEB-03)

- **Evidencia:** reproducido 2 de 2 veces, con JSON roto y con archivo vacío.
- **Obtenido:** "Continuar" sale activo. Al pulsarlo arranca el prólogo de un minuto sin ventana de nombre ni de dificultad: el héroe se llama "Héroe" y la dificultad es Normal. "No se pudo cargar la partida. Empiezas de nuevo." sale solo al final del prólogo, durante unos 2 s. El autoguardado sobrescribe el archivo roto.
- **Sugerencia:** comprobar el guardado en el título, desactivando "Continuar" o avisando allí, o avisar antes del prólogo y pasar por el nombre y la dificultad.

#### QAM-04. La Abuela Rosa manda contra el Rey Slime a nivel 2 sin pista de nivel (WEB-04)

- **Evidencia:** reproducido 1 vez.
- **Obtenido:** tras 2 combates, a nivel 2, la Abuela dice "estoy segura de que puedes con él" y el jefe aparece al instante. El agente, jugando como un jugador nuevo, perdió; le dejó un tercio de vida, y el jefe llamó a un Slime en su ayuda. La derrota funcionó bien: de 22 G a 11 G, curado y de vuelta en Villaclaro. El nivel orientativo es 5 y nada lo indica.
- **Sugerencia:** una pista de la Abuela o del Diario ("entrena un poco en la pradera antes"), o un "Nv recomendado" en el Diario. Vale para cada jefe.

#### QAM-05. En el móvil, con "Textos grandes", el menú de combate tapa la barra de PM (IOS-01)

- **Evidencia:** reproducido 4 de 4 combates con textos grandes y 0 de 3 sin ellos, en iPhone con Safari a 750 × 292 px CSS.
- **Obtenido:** la ventana de comandos se monta sobre la de estado y corta la barra de PM. En la pausa, en Equipo, la línea "ATK 16 DEF 11 VEL 9" queda cortada en el borde del desplazamiento.
- **Causa probable:** con 292 px CSS × `TOUCH_LARGE_SCALE` 1,6 no caben la ventana de estado y 5 filas de 56 px.
- **Sugerencia:** con textos grandes en el móvil, compactar la ventana de estado, con PV y PM en una sola fila, o ponerla al lado del menú.

#### QAM-06. Safari en iPhone deja un área de juego mínima y controles por debajo de 44 pt (IOS-02)

- **Evidencia:** reproducido y medido. Aporta datos nuevos al problema abierto "Botones con la barra del navegador".
- **Obtenido:**
  - Viewport en apaisado de 750 × 292 CSS, con la barra de direcciones y la de pestañas, más 62 pt de zona segura a cada lado.
  - Filas del menú de combate de unos 30 pt, teclas del nombre de unos 30 × 34 pt, "Sí / No" de unos 67 × 30 pt y ☰ de unos 34 × 34 pt.
  - El botón de uso de abajo a la derecha llega a la franja del indicador de inicio.
- **Contexto:** Safari de iPhone no tiene la API Fullscreen para el canvas. La única forma de ganar alto es instalarlo como app (PWA), que deja 750 × 340.
- **Sugerencia:** en iOS, proponer "Añadir a pantalla de inicio" la primera vez, después de arreglar QAM-08 y QAM-13. Que "Sí" y "No" ocupen todo el ancho de su ventana.

#### QAM-07. Los botones de Opciones miden 13-20 pt de ancho (IOS-03)

- **Evidencia:** reproducido en el título y en la pausa, en iPhone.
- **Obtenido:** "Sí" de Temblor y de Textos grandes unos 13 pt; "No", "x1" y "x2" unos 17-20 pt; "Alta" / "Baja" unos 28 pt. Todos de unos 30 pt de alto, y los contiguos quedan pegados.
- **Causa probable:** se dimensionan al texto. `UiStyle.fit_finger()` no se aplica a estos botones. Está deducido de lo visto, sin revisar el código.
- **Sugerencia:** aplicarles el mismo ancho mínimo.

#### QAM-08. La app instalada en iOS no ve la partida jugada en Safari (IOS-04)

- **Evidencia:** reproducido 1 de 1.
- **Obtenido:** la app abre con "Continuar" desactivado. iOS da a cada app web instalada su propio almacenamiento. El jugador puede creer que ha perdido la partida.
- **Sugerencia:** el juego no puede evitarlo. Avisar en la página de itch o en el juego, o permitir exportar e importar el guardado.

#### QAM-09. Dentro del arbolado no se ve al héroe: los arbustos no se perforan (IOS-05)

- **Evidencia:** reproducido 2 de 2 veces en el borde arbolado del oeste de la pradera, en iPhone con calidad Baja. La causa es deducida. Es seguimiento de QA-02, que quedó arreglado solo en parte.
- **Obtenido:** solo se ve el arma del héroe. El cuerpo queda bajo un arbusto y bajo el tramado de la copa, que en una pantalla de iPhone parece casi opaco. En Chrome de escritorio, en la pradera, las copas sí se perforan bien.
- **Causa probable:** los arbustos se dibujan con `LowPoly.add_multimesh(...)` sin el shader de los árboles (`scripts/world/world_stage.gd:278`).
- **Sugerencia:** perforar también los arbustos, o dibujar la silueta del héroe cuando queda tapado.

### Baja

| ID | Hallazgo | Origen | Prueba o causa |
|---|---|---|---|
| QAM-10 | La tienda se ensancha al comprar, porque aparece "Falta oro" en las filas (problema ya abierto, confirmado en escritorio e iOS). En el móvil, el "Volver" de la lista de compra solo aparece al desplazar | WEB-10, IOS-07 | Reservar el ancho desde el principio y dejar "Volver" fuera de la zona que se desplaza |
| QAM-11 | El guardado acepta oro negativo, 0 PV y cantidades negativas. Con -500 G, perder un combate da oro (pasa a -250 G). Un objeto inventado se ignora | WEB-05 | `scripts/game/save_data.gd:146-182`: `is_valid()` comprueba tipos, no rangos |
| QAM-12 | La interfaz dice "lvl" en vez de "Nv." o "Nivel". Las teclas salen en inglés: "Up", "Down", "Space", "Escape", "Backspace", "Kp Enter" | WEB-06, WEB-07 | `scripts/ui/stat_bar.gd:30` y `scripts/game/key_map.gd:84-85` (`OS.get_keycode_string`) |
| QAM-13 | En la app instalada en iOS queda una banda negra fija de 62 pt arriba en apaisado: se pierde el 15 % del alto. El nombre del icono sale cortado ("Villaclaro:laNiebl…") | IOS-06, IOS-08 | Al viewport le falta `viewport-fit=cover` (en `html/head_include`) y a `index.manifest.json` le falta `short_name` |
| QAM-14 | Textos del Diario. Con el Rey Slime ya pedido, "Qué hacer ahora" dice "Objetivo: ayuda a la Abuela Rosa". "Consigue 3 setas de las Setas saltarinas…" repite "setas" | WEB-08, IOS-10 | `scripts/story/story_state.gd:36`, `data/quests/setas.tres:16` |
| QAM-15 | En escritorio, "Partida guardada." ensancha la ventana de sistema y mueve los botones de la pausa. El arreglo QA-06 solo se aplicó al móvil | WEB-09 | Reservar la línea también en escritorio |
| QAM-16 | Una versión nueva no llega a quien ya tenía el juego abierto. El service worker nuevo queda en espera, F5 no lo activa y el jugador sigue con la versión vieja | WEB-11 | Si hay un service worker en espera, mostrar en el título "Hay una versión nueva. Recargar", que mande `'update'` |
| QAM-17 | Un clic en la punta del sombrero de un aldeano no lo usa (1 de 2), aunque en el cuerpo sí | WEB-12 | QA-08 mide a 0,9 m y el sombrero del modelo Mage es más alto |
| QAM-18 | Abuela, Granjero, Mercader y Posadero son el mismo modelo con otro tono: cuesta encontrar la tienda. Fue la primera duda del jugador nuevo, hacia los 2:30 | WEB-13 | Un rótulo o icono "Tienda" / "Posada", como ya se hace con "!" y "?" |
| QAM-19 | En las escenas, la Minera (mina) y el Soldado (castillo) se acercan hasta meterse dentro del héroe | WEB-14 | Paso `approach` de las escenas |
| QAM-20 | Safari muestra en cada carga 4 avisos `Image format RGBAFloat not supported by hardware, converting to RGBAHalf` como `console.error`, y uno de `WEBGL_polygon_mode` | IOS-09 | Alguna textura interna del motor. No viene de `scripts/` |
| QAM-21 | En Android, la fila "Pantalla completa" del título no vuelve tras salir de pantalla completa | AND (borrador) | Sin detalle: el agente no llegó a escribirlo |
| QAM-22 | Chrome de Android tarda unos 46 s en mostrar el título tras recargar, con la caché llena | AND (borrador) | Seguramente es el emulador, que dibuja el 3D por software. Medirlo en un móvil real antes de darlo por bueno |

## Comprobado que funciona

**Arreglos anteriores**

| Arreglo | Resultado |
|---|---|
| QA-01 y 05 | OK en Chrome Android 156 y en Safari iOS 26.5. "Gira el móvil" sale al cargar en vertical y al girar, también en mitad del mapa, y al volver a apaisado el juego sigue donde estaba. Sin errores de WebGL. En iPad también sale |
| QA-02 | Parcial (QAM-09). Las copas se perforan, pero los arbustos no |
| QA-04 | Sigue por debajo de 44 pt en iPhone (QAM-06, QAM-07) |
| QA-06 | OK en el móvil; en escritorio no (QAM-15) |
| QA-08 | OK en Android con la Abuela (cabeza), el Granjero (cabeza), el Posadero (cabeza) y el tablón. En iOS, OK con el tablón, el Mercader (sombrero), el Posadero y un cofre. En escritorio, un fallo con el sombrero (QAM-17) |
| QA-09 | OK en iOS: con dos enemigos solo quedan "Volver" y "¿A quién? Toca al enemigo.". Un toque pone la flecha y el segundo confirma |
| QA-10 | No se pudo comprobar en iOS: AXe tarda más de 0,6 s entre toques |
| Banda negra a pantalla completa | No se reprodujo en Android: 11 ciclos desde Opciones y 4 con recarga y 11 pestañas abiertas. El problema sigue abierto pero sin nuevos casos. En iPhone no aplica |

**Batería, en resumen**

- **Arranque y título:** versión visible, "Continuar" según haya guardado, "Continuar (terminada)" carga en Villaclaro y se puede pasear.
- **Nueva partida:** el nombre admite como mucho 8 letras, con ñ y tildes, que salen bien en los diálogos. El prólogo se avanza con Enter, con clic o con toques y termina con "Misión: slimes 0 / 3".
- **Mapa:** se anda con WASD, con clic, tocando el suelo y con la palanca flotante. El mapa explorado se conserva al recargar.
- **Combate:**
  - Todos los comandos funcionan, y Volver o Esc no gastan el turno.
  - Las filas que no se pueden usar salen en gris con el motivo ("Faltan PM", "PV al máximo") y no gastan el turno.
  - EXP, oro y subida de nivel cuadran con la sección 3 del brief (PV +6, PM +3, ATK +2, DEF +1, VEL +1).
  - No se puede huir del jefe, y no se pierde el turno.
  - Derrota: pierde la mitad del oro, se cura y vuelve a la aldea.
  - Pulsar o tocar muy rápido durante las animaciones no provoca dobles acciones ni bloqueos (200 Enter seguidos y ráfagas de 7 toques).
- **Economía:** "Falta oro" en gris, la comparación con lo que se lleva puesto es correcta, "¿Te lo equipas ahora?", y se vende a la mitad sin dejar vender lo puesto ni lo que no vale nada. La posada es gratis y cura PV y PM. El cofre da su contenido y equipa el escudo si el hueco está libre.
- **Guardado:** guardar, recargar y "Continuar" conserva posición, nivel, inventario, oro, misiones y mapa. Un guardado de versión 4 carga como "Héroe" en la pradera. Una zona inexistente se rechaza y empieza de nuevo. Los archivos corruptos no cuelgan el juego (pero ver QAM-03).
- **Opciones:** se aplican al momento y se guardan. Reasignar teclas funciona: una tecla pertenece a una sola acción y nunca deja una acción sin tecla ("Esa tecla es la única de «Abajo»."). Calidad Baja reduce la hierba en el siguiente mapa.
- **Audio en iOS:** el contexto de audio se crea en pausa y arranca con el primer toque. Al ir a Inicio se suspende y al volver se reanuda.
- **iPad:** recibe la interfaz táctil, que funciona.
- **Consola:** escritorio sin errores ni avisos en 11 cargas y unos 20 minutos. iOS sin errores de WebGL en unos 40 minutos (salvo QAM-20). En Android solo avisos de autoplay del audio, que son normales.

## Métricas

| Métrica | Valor | Dónde |
|---|---|---|
| Descarga sin caché | Unos 13,2 MB transferidos: `index.wasm` 39,5 MB que se comprimen a 10,25 MB, `index.pck` 2,9 MB, `index.js` 280 KB que se comprimen a 70 KB | Chrome escritorio y Android |
| Carga desde la caché del service worker | Evento `load` en 246-462 ms y título en menos de 3 s | Chrome escritorio |
| Carga sin caché con 3G simulado | El `index.pck` tardó unos 35 s. No hay más datos: el agente no llegó a escribir el resultado | Android |
| Título tras recargar | Unos 46 s, poco fiable por el 3D por software | Android emulador |
| FPS | 75 estables (tope de la pantalla) y peor fotograma de 14-15 ms, en título, pradera con calidad alta y baja, 2560 px de ancho y castillo. No separa calidad alta de baja | Chrome escritorio |
| Memoria del heap de JS | 23 MB en el título, 87-111 MB en el mapa y 45 MB en el castillo tras recargar | Chrome escritorio |
| Viewport en apaisado | Safari 750 × 292 CSS, app instalada 750 × 340, Chrome Android 866 × 308 con barra (dato del informe anterior) | iPhone y Android |
| Jugador nuevo, Normal | Prólogo de unos 50 s. Primera duda hacia los 2:30 (dónde está la tienda). Primer combate a los 3:52. Nivel 2 tras 2 combates. Rey Slime a los 8 minutos, a nivel 2, perdido | Chrome escritorio |
| Tiempo de juego hasta los jefes, oro por zona, porcentaje de derrotas | No medido: nadie jugó la partida completa | |

## Sin probar

- **La partida completa:** los jefes Bruja, Golem y Señor de la Niebla (sus dos fases y la carga del Golem frente a Defender), las 8 escenas en orden, los créditos y "Fin".
- **La mina:** palanca, llave y puertas, y que sigan abiertas tras recargar. El agente de Android las estaba probando (hay capturas de "Tirar" y de recargar con la palanca), pero no escribió el resultado.
- **Ala de viaje y portal, morir con el portal abierto, semillas, las 6 misiones secundarias y perder contra cada jefe.**
- **La duración de "unas dos horas" que promete la página.**
- **El sonido real:** ningún agente podía oír. Solo se comprobó el estado del contexto de audio.
- **Rendimiento, calor y memoria en un móvil real:** los simuladores no los representan.
- **El pellizco con dos dedos:** AXe no hace multitoque en iOS. En Android se intentó con CDP, sin resultado escrito.
- **La app instalada sin conexión** (Android e iOS) y la primera carga con red móvil real.
- **Llamadas, bloqueo de pantalla y cerrar la pestaña en mitad de un combate o una escena.**
- **Fácil frente a Normal en combate, partida de 30 minutos o más, y T-23** (la guarda de 0,4 s tras un diálogo).

## Opiniones de diseño, por prioridad

1. **Confirmar "Nueva partida"** (QAM-01). Es lo único que hace perder progreso.
2. **Mostrar siempre el objetivo principal** (QAM-02).
3. **Una pista de nivel antes de cada jefe** (QAM-04).
4. **Distinguir a los comerciantes** con un rótulo o icono (QAM-18).
5. **Ancho mínimo para todos los botones en el móvil,** incluidos los de Opciones y Sí / No (QAM-06, QAM-07).
6. **Aviso de versión nueva en el título** (QAM-16).
7. **Una fila "Volver" visible en los submenús de combate en escritorio.** Hoy solo se vuelve con Esc o con un clic fuera, y un jugador no lo sabe.
8. **"Volver" en la dificultad debería ir al nombre y no al título.** Hoy se pierde el nombre escrito.
9. **En iOS, proponer la instalación como app,** después de arreglar QAM-08 y QAM-13.
10. **En iPad, el aviso podría decir "Gira la pantalla"** o permitir el vertical, que tiene 820 × 1180 pt.
11. **Una opción de pantalla completa en el escritorio web.** Hoy solo existe en Android; F11 funciona, pero nadie lo sabe.
12. **El patio del castillo se ve lavado:** violeta plano, con poco contraste entre muros y suelo. Opinión con una sola captura.
13. **El tablón acepta la misión de las setas solo con leerlo.** Es coherente con que ninguna misión bloquea, pero sorprende.
14. **Comprobar que la calidad "Baja" es la que se quiere por defecto en el móvil.** En iPhone salió así sin tocar nada.

## Lecciones del montaje con agentes

- **El reparto por plataforma y riesgo funciona.** Los agentes no se pisan si cada uno usa solo su dispositivo: iOS con `xcrun simctl` y AXe, Android con `adb` y CDP, y escritorio con la extensión Claude in Chrome.
- **Jugar con capturas va lento y gasta mucho:** unos 300 000 tokens y unos 25-45 minutos por agente para cubrir la primera zona. Jugar el juego entero así no es realista. Para las zonas avanzadas hay que inyectar guardados (ver más abajo).
- **El límite de uso de 5 horas cortó a los dos agentes a la vez.** Conviene repartir el presupuesto o lanzarlos en momentos distintos.
- **La extensión de Chrome usa el perfil real del usuario,** con su partida y su service worker. El agente de Chrome sobrescribió la partida real (QAM-01) y además la dejó sustituida al cortarse. Se restauró desde la copia de seguridad, con el hash comprobado. **Para la próxima:** un perfil de Chrome aparte, o copia y restauración obligatorias al empezar y al terminar.
- **En iOS:**
  - En este Xcode no existe Simulator.app. Para girar, el agente escribió una herramienta en Swift que manda el evento de orientación. Para leer la consola, un cliente en Python del inspector web del simulador (`webinspectord_sim`).
  - Con DeviceHub abierto, AXe deja de mandar toques, y cerrarlo apagó el simulador.
  - AXe no hace multitoque y tarda más de 0,6 s entre toques.
- **En Android:**
  - El emulador Medium_Phone con API 37 no compone WebGL en pantalla, ni con el juego ni con una página mínima, tanto con SwiftShader como con lavapipe o la GPU del Mac. El agente lo resolvió con un espejo (`readPixels` del framebuffer de Godot copiado a un canvas 2D), que además ralentiza la carga.
  - Chrome se actualizó solo de 145 a 156 al reiniciar el emulador.
- **El guardado de la web** vive en IndexedDB: base `/userfs`, almacén `FILE_DATA`, clave `/userfs/Godot/app_userdata/rpg-turnos/save.json`. El contenido es un `Int8Array` con el JSON. En el mismo navegador había también una ruta antigua en minúsculas, `/userfs/godot/...`, de una versión anterior. Con esto se pueden inyectar guardados para probar zonas avanzadas.

## Material generado

Todo está en el scratchpad de la sesión, **fuera del repositorio y temporal**: `/private/tmp/claude-502/-Users-axelperezgaspar-rpg-turnos/0416f6dd-8793-47bd-995d-3b103c3f3628/scratchpad/`.

- `reports/ios.md`: informe completo del agente de iPhone, con la batería prueba a prueba.
- `reports/chrome.md`: informe completo del agente de Chrome de escritorio.
- `reports/android.md`: borrador del agente de Android.
- `capturas-ios/`: 44 capturas citadas en `ios.md`. `capturas-android/`: más de 100 capturas.
- `saves/`: los guardados de prueba.
  - Corrupto, vacío y datos falsos.
  - Versión 4 y zona inexistente.
  - Bosque nivel 6, mina nivel 10 y castillo nivel 14.
  - La copia de la partida del usuario, `save_original_usuario_backup.json`, con SHA-256 `a511b26f…29301`.
- `tools/`: las herramientas del agente de iOS para girar y leer la consola. `cdp/`: los scripts de CDP del agente de Android.

Si se quieren conservar, hay que copiarlos al repositorio antes de que se borre el scratchpad.
