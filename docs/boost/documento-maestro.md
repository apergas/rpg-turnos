# Documento maestro

Fecha: 2026-11-11. Última versión hecha: **2.1.0** (en `develop`, sin publicar todavía). M-01 a M-38 están hechos (M-17 y M-37, descartados). M-39 a M-47 son la v2 (2.0.0 a 2.3.0), con diseño: la 2.0.0, la 2.0.1 y la 2.1.0 están hechas; 2.2.0 y 2.3.0 esperan su plan. M-48 (la 2.0.1, la decoración con Kenney) está hecho.

Este documento es la base de trabajo a partir de ahora. Reúne:

- las conclusiones de las dos pasadas de QA sobre la 1.0.0 y la 1.1.0 (Héctor y la pasada larga en Chrome);
- lo que queda abierto en el resto de documentos (`estado-proyecto.md`, `ideas-sueltas.md`, `2026-11-03-ideas-juego-completo.md`, los informes de `docs/boost/qa/` y los diseños y planes de la 1.1.0).

Solo recoge lo que tiene sentido hacer. Lo descartado va al final, con el motivo.

**Cómo se usa:**

- Cada punto tiene un ID (`M-nn`). Cuando un punto entra en un diseño o en un plan, se enlaza aquí. Cuando se publica, se marca como hecho con su versión.
- Los demás documentos están en `docs/legacy/` como registro histórico. Si contradicen a este, manda este.

---

## 1. Lectura del feedback

### Lo que ya resuelve la 1.1.0

La pasada larga jugó casi todo en la 1.0.0. Varias cosas que pide ya están en la 1.1.0, pero falta repetir el caso para darlas por buenas.

| Feedback | Qué hay en la 1.1.0 |
|---|---|
| I04: el objetivo principal desaparece tras el Rey Slime | El objetivo principal va siempre primero (`GameState.current_missions()`) |
| I09: árboles y arbustos tapan al héroe | Copas y arbustos se perforan alrededor del héroe |
| I03: no se distingue a quién hablas | Rótulos "Tienda", "Posada" y "Criaturas", y tocar una figura la usa al llegar |
| Héctor: no se sabe dónde comprar | Rótulos y marcas de colores en el mapa |
| B03: el texto de Curar | Curar+ sustituye a Curar y Llama pasa a llamarse Ascuas |

### Lo que el QA leyó mal, aunque deja algo que mejorar

- **B03, "Curar dice PV al máximo":** ese texto no es la descripción del hechizo. Es el motivo por el que la fila sale en gris cuando los PV están llenos. El problema real es otro: las filas de hechizos solo dicen el nombre y los PM, y no qué hacen. Ver M-04.
- **B04, "Huir de un jefe no responde":** el juego dice "¡No puedes huir!" y no gasta el turno (`battle_scene.gd:339`). El mensaje pasa rápido y no se ve venir. Ver M-03.
- **I02, "los cofres no dicen qué dan":** sí lo dicen, pero en un aviso de 2 s arriba en el centro (`World.NOTICE_TIME`), fácil de perder. Ver M-05.
- **I06, "el menú abre a veces en Hechizos":** cada turno empieza en Atacar (`BattleHud.show_menu()`). Al volver de un submenú, el cursor queda en la fila de la que venías. La regla es coherente y no se cambia.
- **I07, "el Granjero no dice cómo voy con las setas":** sí tiene frases de espera ("¿Me traes mis setas?..."), pero no dicen el progreso. Ver M-09.

### Lo que se confirma en el código

- **B01, bestiario incompleto al migrar:** `save_data.gd:148-153` solo marca como vistos los jefes vencidos. El Slime de Metal solo sale mientras su misión lo pide (`encounter_table.gd:17`), así que quien ya la entregó nunca podrá completar el bestiario.
- **B05, teclas mantenidas al entrar en combate:** el menú de combate acepta las repeticiones de tecla (`echo`) para mover el cursor (`battle_hud.gd:291`). Si el jugador sigue pulsando W o S al empezar el combate, el cursor se mueve solo. El guarda de 0,3 s (`MENU_GUARD`) solo protege la confirmación.
- **Héctor, los combates al volver por caminos conocidos:** la regla de encuentros es la misma a cualquier nivel. En la mina no hay sendero seguro fuera de las salas de las escaleras.

### Lo que no se puede reproducir

- **B02, pantalla blanca en la pradera (1.0.0):** una sola vez, sin pasos fijos. Lo más probable es que el navegador perdiera el contexto WebGL, porque el juego no lo trata y se queda congelado. Ver M-01.

---

## 2. Trabajo propuesto

Tallas: **S** menos de un día, **M** unos días, **L** una semana o más.

### Prioridad 1: errores y cosas que confunden

| ID | Qué | Por qué | Propuesta | Talla |
|---|---|---|---|---|
| M-01 | Pantalla blanca o congelada en la web (B02) — **hecho en 1.1.1** | Si pasa, el jugador no sabe que su partida está guardada | En `html/head_include`, escuchar `webglcontextlost` en el canvas y mostrar encima un aviso en HTML: "El navegador ha cortado los gráficos. Recarga la página: tu partida está guardada." con un botón Recargar. Es defensivo: no arregla la causa, pero quita el bloqueo | S |
| M-02 | Bestiario que no se puede completar (B01, E02) — **hecho en 1.1.1** | Una partida migrada o con la misión del Slime de Metal entregada no llega a 17/17 | 1) Al migrar un guardado anterior al bestiario, marcar como vistos los enemigos comunes de cada zona cuyo jefe está vencido, y el Slime de Metal si su misión está cumplida. 2) Con la misión ya cumplida, el Slime de Metal sigue saliendo en la mina, pero raro (un 5 % en lugar del 25 %) | S |
| M-03 | Huir de un jefe (B04) — **hecho en 1.1.1** | El jugador no sabe si está prohibido o si ha fallado | Contra un jefe, la fila "Huir" sale en gris con el motivo "No puedes huir", como las demás filas que no se pueden usar. Desaparece el caso NO_ESCAPE | S |
| M-04 | Qué hace cada hechizo (B03) — **hecho en 1.1.1** | Los objetos lo dicen y los hechizos no | Añadir a `Skill` una descripción corta ("Cura 30 PV.", "Daño de fuego a todos.") y mostrarla en la fila, como hace `ITEMS`. También en la página Estado de la pausa | S |
| M-05 | Botín de los cofres (I02) — **hecho en 1.1.1** | El aviso de 2 s se pierde | El contenido del cofre sale en la ventana de diálogo y espera a Enter o a un toque, como en Dragon Quest: "¡Encuentras 120 monedas de oro!". En la partida automática avanza solo | S |
| M-06 | Teclas mantenidas y confirmaciones rápidas en combate (B05) — **hecho en 1.1.1** | Movimientos y elecciones que el jugador no quería | 1) Ignorar las repeticiones (`echo`) del menú hasta la primera pulsación nueva tras abrirse. 2) Un sonido y un parpadeo del cursor cuando el menú ya acepta órdenes | S |

### Prioridad 2: orientación

La mina fue lo que más costó a los dos QA.

| ID | Qué | Por qué | Propuesta | Talla |
|---|---|---|---|---|
| M-07 | Nombre del lugar — **hecho en 1.2.0** | En la mina no se sabe en qué planta estás | 1) Al entrar en una zona, un rótulo grande unos segundos: "Mina abandonada · Planta 2". 2) Encima del mapa pequeño, una línea fija con el nombre corto. Cada `ZoneData` gana un `display_name` | S |
| M-08 | Mapa grande y marcas de la mazmorra — **hecho en 1.2.0** | Ver una escalera en el mapa pequeño no dice cómo llegar a ella | 1) Página "Mapa" en la pausa (fila nueva en la ventana del héroe), y tocar el mapa pequeño la abre: el mapa explorado de la zona a pantalla casi completa, con la posición del héroe. 2) Marcas nuevas: escalera de subida y de bajada con colores distintos, palanca (otro color cuando ya está bajada), reja (otro color cuando ya está abierta) y llave | M |
| M-09 | Progreso en las frases de espera (I07) — **hecho en 1.2.0** | Una misión de recoger o cazar no dice si avanza | Las frases de espera de una misión `GATHER` o `HUNT` terminan con "Llevas 1 de 3." Así no hace falta abrir el Diario | S |
| M-10 | Nombre en la acción (I03) — **hecho en 1.2.0** | Con dos figuras cerca, no se sabe con quién vas a hablar | La acción dice con quién: "Hablar · Granjero", "Comprar · Mercader". En el móvil, el nombre va en el botón de usar | S |
| M-11 | Objetivo más claro en la mina — **hecho en 1.2.0** | "Vence al Golem de piedra" no dice cómo llegar | Que el objetivo principal cambie según la planta y las banderas: "Baja a la segunda planta", "Busca la palanca", "Busca la llave de la reja", "Vence al Golem de piedra". Sale de `StoryState.goal_text()` con las banderas de la mina | S |

### Prioridad 3: comodidad

| ID | Qué | Por qué | Propuesta | Talla |
|---|---|---|---|---|
| M-12 | Menos combates por zonas ya superadas (Héctor, I08) — **hecho en 1.2.0** | Volver a curarse o a comprar se hace pesado | 1) Si el héroe supera en 4 niveles el nivel de salida de la zona, los encuentros salen a la mitad. Es la regla de Dragon Quest: los débiles no se acercan. 2) Un objeto nuevo, **Incienso** (20 G, en todas las tiendas): sin encuentros durante 200 m. La partida automática no lo compra | S |
| M-13 | Curar fuera de combate (I10) — **hecho en 1.2.0** | Para curarse con PM hay que entrar en una pelea | En la ventana del héroe de la pausa, una fila nueva "Hechizos" con Curar y Curar+ y su coste en PM. Se gasta igual que en combate | S |
| M-14 | Objetivo más visible en combate (Héctor) — **hecho en 1.2.0** | La flecha amarilla se pierde en algunos fondos | Además de la flecha, el enemigo apuntado se ilumina un poco y su nombre sale encima de su barra | S |
| M-15 | Primeros pasos en el móvil (Héctor) — **hecho en 1.2.0** | No queda claro cómo moverse con el dedo | La primera vez que se entra al mapa en un móvil, una línea: "Toca el suelo para ir allí, o arrastra el dedo para andar." Desaparece al andar. Se guarda en las opciones | S |
| M-16 | Datos de la partida en el título (Héctor) — **hecho en 1.2.0** | "Continuar" no dice qué partida vas a cargar | Bajo "Continuar", una línea pequeña: "Rocío · Nv 12 · Mina · 1:05". Sale del propio guardado. En la 1.3.0 pasa a cada ranura (M-20) | S |

### Prioridad 4: cierre y contenido

| ID | Qué | Por qué | Propuesta | Talla |
|---|---|---|---|---|
| M-18 | Resumen de lo que queda (E01) — **hecho en 1.3.0** | Saber qué falta sin inventar porcentajes | En el Diario, un apartado "Colección": historia (terminada o no), misiones n/7, bestiario n/17 y cofres n/total. Por separado, sin un porcentaje total | S |
| M-19 | Fichas del bestiario (E02) — **hecho en 1.3.0** | El álbum solo enseña la figura | Tocar un cromo abre su ficha: zona donde vive, debilidades y resistencias, y si lo has vencido. Pide guardar también los vencidos, con versión nueva de guardado; en un guardado anterior, los vistos cuentan como vencidos | M |
| M-20 | Varias partidas (Héctor) — **hecho en 1.3.0** | Una sola ranura: probar otra dificultad borra la partida | Tres ranuras, con los datos de M-16 en cada una. "Continuar" abre la lista de ranuras; "Nueva partida" pide ranura y pregunta antes de sobrescribir una ocupada. El autoguardado escribe en la ranura en curso. Un guardado antiguo pasa a la ranura 1. Cambia `SaveStore` y el título | M |
| M-21 | Exportar e importar la partida (QAM-08) — **hecho en 1.3.0** | En iOS, la app instalada no ve la partida jugada en Safari | Con un archivo: en la web se descarga y se sube con el selector del navegador; en escritorio, con una ventana de archivo. Se exporta e importa una ranura, y lo importado pasa por `SaveData.is_valid()` | M |
| M-22 | Reto tras el final (E03) — **hecho en 1.4.0** | El equipo final no tiene uso después de los créditos | Tras los créditos, en el salón del trono aparece el **Eco de la Niebla**: una fase, pensado para nivel 20 con el equipo de platino, más duro que el Señor, con un golpe cargado como el del Golem. Premio, una sola vez: el **Yelmo de bruma**, un casco con cuernos de estilo vikingo, DEF +8 y ATK +5, que se pone en el acto en lugar del casco que lleves. Se puede repetir el combate. No cambia los créditos y no entra en el bestiario | L |

### Prioridad 5: ideas que pasan a versiones (2026-11-09)

Las ideas de la sección 4 pasan a puntos con diseño propio. Las decisiones de cada uno están en su spec.

| ID | Qué | Antes | Versión | Talla |
|---|---|---|---|---|
| M-26 | Hechizos sin descripción en combate y en la página Hechizos de la pausa — **hecho en 1.4.1** | I-03 | 1.4.1 | S |
| M-27 | Enemigos iguales sin letra ("Slime" y "Slime") — **hecho en 1.4.1** | I-04 | 1.4.1 | S |
| M-28 | Ataque sorpresa: 1/16 a favor de cada bando, nunca contra jefes — **hecho en 1.5.0** | Ataque sorpresa | 1.5.0 | S |
| M-29 | Pluma de fénix: te levanta sola con la mitad de PV, una por combate — **hecho en 1.5.0** | Pluma de fénix | 1.5.0 | S |
| M-30 | Despertador: evita el sueño hasta el final del combate — **hecho en 1.5.0** | Despertador | 1.5.0 | S |
| M-31 | Cinco enemigos nuevos, variantes de color de figuras que ya existen — **hecho en 1.6.0** | Variantes de color | 1.6.0 | M |
| M-32 | Bestiario por familias con premio, y Accesorio partido en Anillo y Amuleto — **hecho en 1.6.0** | I-02 | 1.6.0 | L |
| M-33 | Monstruos visibles en el mapa en lugar de encuentros aleatorios — **hecho en 1.7.0** | I-01 | 1.7.0 | L |
| M-34 | Doce medallas pequeñas y el Coleccionista de Villaclaro — **hecho en 1.8.0** | Medallas pequeñas | 1.8.0 | M |
| M-35 | Partida nueva + sobre una partida terminada — **hecho en 1.8.0** | Partida nueva + | 1.8.0 | M |
| M-36 | Sonido de ambiente y partículas por zona — **hecho en 1.9.0** | Sonido de ambiente y partículas | 1.9.0 | M |
| M-37 | Soporte de mando — **descartado** (2026-11-10) | Soporte de mando | — | M |
| M-38 | Menú de depuración con `--debug` — **hecho en 1.9.0** | Menú de depuración | 1.9.0 | S |

### Prioridad 6: la v2, la caravana del portal (2026-11-10)

Una segunda parte de unas dos horas sobre una partida terminada: una caravana, un compañero, cuatro tierras y un portal. Todo en un solo diseño, [spec de la v2](specs/2026-11-10-version-2-0-0-design.md), publicado en cuatro versiones.

| ID | Qué | Versión | Talla |
|---|---|---|---|
| M-39 | La caravana llega a Villaclaro tras el final y el héroe parte con ella, sin vuelta al mundo de la v1 — **hecho en 2.0.0** | 2.0.0 | M |
| M-40 | El tramo, calculado de los jefes vencidos; capítulos y objetivos de la v2 — **hecho en 2.0.0** | 2.0.0 | S |
| M-41 | La Caravana: un mapa de base con mercader por tramo y salidas que existen según las banderas — **hecho en 2.0.0** | 2.0.0 | M |
| M-42 | El compañero: uno de tres, elegido una vez, un ALLY cuyos números suben con el tramo — **hecho en 2.0.0** | 2.0.0 | M |
| M-43 | Las cuatro zonas: jungla y desierto abiertas, montaña y ciudad de celdas — jungla hecha en 2.0.0, desierto hecho en 2.1.0 | 2.0.0 a 2.3.0 | L |
| M-44 | Veinte enemigos, cuatro jefes de zona, el Devorador del portal (dos fases) y cuatro familias del bestiario — jungla hecha en 2.0.0, desierto hecho en 2.1.0 | 2.0.0 a 2.3.0 | L |
| M-45 | Nivel máximo 40, Ventisca y Sanación, cuatro niveles de equipo, Poción y Éter grandes — jungla hecha en 2.0.0, desierto hecho en 2.1.0 | 2.0.0 a 2.3.0 | M |
| M-46 | Ocho misiones de datos, dos por tramo, con la bandera `needs` — jungla hecha en 2.0.0, desierto hecho en 2.1.0 | 2.0.0 a 2.3.0 | M |
| M-47 | El final: el cruce, la pantalla del más allá con el pueblo de la v3 y los créditos de la v2 | 2.3.0 | M |

### Prioridad 7: decoración con modelos reales (2026-11-11)

El usuario permitió el Kenney Nature Kit (CC0). Regla suya: la opción más bonita, con todo en el mismo estilo. KayKit sigue siendo la base (árboles, rocas, casas, personajes) y Kenney entra donde encaja: la 2.0.0 ya usa sus palmeras en la jungla.

| ID | Qué | Versión | Talla |
|---|---|---|---|
| M-48 | Decoración Kenney en los mapas que ya existen: arbustos, troncos, tocones, setas, flores, vallas, cultivos y hogueras, teñidos si hace falta para que casen con KayKit — **hecho en 2.0.1** | 2.0.1 | M |

---

## 3. Pendientes heredados

Lo que queda de los informes anteriores y se puede hacer desde aquí, sin un móvil real.

| ID | Qué | Propuesta | Talla |
|---|---|---|---|
| M-23 | En Android, la fila "Pantalla completa" del título no vuelve tras salir de pantalla completa (QAM-21) — **hecho en 1.1.1** | Que la fila mire el modo de la ventana cada vez que se enseña el menú, y no solo al construirlo | S |
| M-24 | Pantalla completa en la web de escritorio — **hecho en 1.1.1** | Hoy solo existe en Android. La misma fila en Opciones también en el navegador de escritorio | S |
| M-25 | En el iPad, el aviso dice "Gira el móvil" — **hecho en 1.1.1** | "Gira la pantalla" en todos los dispositivos | S |

---

## 4. Ideas sin plan

Vienen de `2026-11-03-ideas-juego-completo.md`. Desde el 2026-11-09 todas tienen diseño y plan: son M-26 a M-38 (sección 2, prioridad 5). Se dejan aquí como registro de la idea original.

| Idea | Comentario |
|---|---|
| Ataque sorpresa | Barato y da variedad al combate |
| Pluma de fénix y Despertador | Objetos sencillos con las reglas actuales |
| Variantes de color de los enemigos | Más variedad con poco trabajo |
| Partida nueva + | Encaja con M-22 |
| Medallas pequeñas | Da sentido a explorar; pide un coleccionista y premios |
| Sonido de ambiente y partículas | Ambientación |
| Soporte de mando | Útil en escritorio; en la web depende del navegador |
| Menú de depuración | Solo para desarrollo; `--autoplay-zone` ya cubre lo principal |

### I-01. Monstruos visibles en el mapa

Idea tuya (2026-11-07). Sustituye a los encuentros aleatorios.

- **Visibles:** los monstruos están en la hierba, a la vista. La pelea empieza en cuanto el héroe se acerca a uno.
- **Paso libre:** entre ellos queda sitio para cruzar la zona e ir a la siguiente sin combatir.
- **Movimiento según el monstruo:**
  - Los que andan se mueven alrededor de su sitio. Por ejemplo, el lobo en unos 2 m.
  - Las setas y las plantas carnívoras se quedan quietas.
- **Slime de Metal:** mientras su misión está en curso, recorre toda la zona andando o corriendo. Si huye tras recibir daño, la próxima vez que lo encuentres conserva los PV que le quitaste, como los perros legendarios de Pokémon Oro y Plata.
- **Reaparición:** los monstruos vencidos vuelven al cambiar de zona.

Notas para cuando se diseñe:
- Cambia una decisión de la base del juego: el documento de ideas de 2026-11-03 dejaba fuera los enemigos visibles. Hay que repasar el ritmo de EXP y oro, la partida automática (que hoy anda por la hierba buscando combates) y `EncounterMeter` / `EncounterTable`.
- Deja sin sentido M-12 (encuentros a la mitad e Incienso), que está en el plan de la 1.2.0. Si esta idea entra antes, M-12 se quita.
- Las mazmorras no tienen sendero seguro: los pasillos deben dejar hueco para esquivar.
- Con dos enemigos por combate: lo más sencillo es que cada figura del mapa sea un grupo, ya decidido, y que se vea solo el primero.

### I-02. Grupos en el bestiario con premio

Idea tuya (2026-11-07).

- **Grupos:** el bestiario se ordena por tipos, con 4 o 5 enemigos cada uno, y se añaden enemigos nuevos para llenarlos.
- **Premio por grupo completo**, nunca oro:
  - dos grupos dan un anillo;
  - otros dos dan un amuleto;
  - el de jefes da una espada muy buena.
- **Equipo:** la casilla de Accesorio se parte en **Anillo** y **Amuleto**, así que se pueden llevar los dos a la vez.
- **Jefe extra:** el jefe de después de los créditos queda fuera del bestiario.

Propuesta de grupos, con los 17 de hoy (en cursiva los que habría que crear):

| Grupo | Enemigos | Premio |
|---|---|---|
| Plantas | Seta saltarina, Planta carnívora, *2-3 nuevos* | Anillo |
| Bestias | Murciélago, Lobo, Araña, *1-2 nuevos* | Amuleto |
| Criaturas mágicas | Slime, Slime de Metal, Duende, Golem de barro, *1 nuevo* | Anillo |
| Muertos vivientes | Espectro, Esqueleto guerrero, Esqueleto pícaro, Esqueleto mago, *1 nuevo* | Amuleto |
| Jefes | Rey Slime, Bruja del bosque, Golem de piedra, Señor de la Niebla | Espada |

Notas para cuando se diseñe:
- Hacen falta unos 6 enemigos nuevos, con figura, retrato y sitio en las zonas.
- Hoy hay dos accesorios: el Anillo antiveneno va a Anillo y el Amuleto de velocidad a Amuleto. Un guardado antiguo pasa su accesorio a la casilla que le toque.
- El Eco de la Niebla (1.4.0) ya queda fuera del bestiario, y su premio es un casco: no choca con la partición en Anillo y Amuleto.
- Encaja con las fichas del bestiario (M-19, plan de la 1.3.0): el grupo puede salir en la ficha.

### I-03. Hechizos sin descripción en combate

Idea tuya (2026-11-08).

- **En combate:** la página de Hechizos solo dice el nombre del hechizo y los PM que gasta, por ejemplo "Curar  4 PM".
- **En Estado:** la descripción de lo que hace cada hechizo se queda solo en la página Estado del menú de pausa.

Notas para cuando se diseñe:
- Deshace parte de M-04 (1.1.1), que puso la descripción en las filas de hechizos del combate (`BattleHud`, página `SPELLS`). Estado ya la muestra (`Skill.description`).
- La página Hechizos del menú de pausa (M-14, 1.2.0), donde se lanzan las curas fuera de combate, también la muestra (`pause_menu.gd:714`). Para que quede solo en Estado, se quita también de ahí.
- La fila en gris con su motivo ("Faltan PM", "Silencio") se mantiene.

### I-04. Enemigos iguales sin letra

Idea tuya (2026-11-08).

- **Combate contra dos enemigos iguales:** los dos se llaman igual, por ejemplo "Slime" y "Slime", en vez de "Slime A" y "Slime B".

Notas para cuando se diseñe:
- Hoy la letra se añade en `battle_scene.gd:114-115`; basta con quitarla.
- Los mensajes ("El Slime recibe 5 de daño") ya no dicen a cuál le ha tocado. Lo distinguen la flecha amarilla, el brillo del enemigo apuntado y su barra de vida.
- Al apuntar con "¿A quién?" los dos nombres son iguales, pero la flecha marca cuál se elige.

---

## 5. Descartado

| Propuesta | Motivo |
|---|---|
| Nivel recomendado antes de cada jefe | Lo descartaste en los evolutivos. La Abuela ya sugiere entrenar antes del Rey Slime |
| Avisar de lo que cuesta caer (M-17, I05) | Descartado por ti: la primera derrota lo enseña |
| Límite a la sequía de encuentros (I08) | Choca con lo que pide Héctor, que quiere menos combates. El ritmo ya se ajustó en la 1.0.0 |
| Fijar una misión en la pantalla (I04) | El objetivo principal ya va primero, y en el móvil no cabe más |
| Pruebas de regresión automáticas (E04) | El proyecto no tiene tests, por decisión tuya |
| Inglés | Descartado: el juego es solo en español |
| Soporte de mando (M-37) | Descartado por ti el 2026-11-10 |
| Criatura que sigue al héroe por el mapa | Quedó fuera de la 1.1.0. Se recupera si vuelve a pedirse |

---

## 6. Orden y planes

| Versión | Contenido | Plan | Estado |
|---|---|---|---|
| **1.1.1** | M-01 a M-06 y M-23 a M-25: errores, confusiones y lo heredado | [plan](../legacy/plans/2026-11-07-version-1-1-1.md) | Hecha |
| **1.2.0** | M-07 a M-16: orientación y comodidad | [plan](../legacy/plans/2026-11-07-version-1-2-0.md) | Hecha |
| **1.3.0** | M-18 a M-21: colección y partidas | [plan](../legacy/plans/2026-11-07-version-1-3-0.md) | Hecha |
| **1.4.0** | M-22: el Eco de la Niebla | [plan](../legacy/plans/2026-11-07-version-1-4-0.md) | Hecha |
| **1.4.1** | M-26 y M-27: retoques del combate | [spec](specs/2026-11-09-version-1-4-1-design.md) · [plan](plans/2026-11-09-version-1-4-1.md) | Hecha |
| **1.5.0** | M-28 a M-30: ataque sorpresa, Pluma de fénix y Despertador | [spec](specs/2026-11-09-version-1-5-0-design.md) · [plan](plans/2026-11-09-version-1-5-0.md) | Hecha |
| **1.6.0** | M-31 y M-32: enemigos nuevos y familias del bestiario | [spec](specs/2026-11-09-version-1-6-0-design.md) · [plan](plans/2026-11-09-version-1-6-0.md) | Hecha |
| **1.7.0** | M-33: monstruos a la vista | [spec](specs/2026-11-09-version-1-7-0-design.md) · [plan](plans/2026-11-09-version-1-7-0.md) | Hecha |
| **1.8.0** | M-34 y M-35: medallas pequeñas y Partida nueva + | [spec](specs/2026-11-09-version-1-8-0-design.md) · [plan](plans/2026-11-09-version-1-8-0.md) | Hecha |
| **1.9.0** | M-36 y M-38: ambiente y depuración | [spec](specs/2026-11-09-version-1-9-0-design.md) · [plan](plans/2026-11-09-version-1-9-0.md) | Hecha |
| **2.0.0** | M-39 a M-42 y la jungla: la caravana, el compañero, el nivel 40 | [spec](specs/2026-11-10-version-2-0-0-design.md) · [plan](plans/2026-11-10-version-2-0-0.md) | Hecha |
| **2.0.1** | M-48: decoración Kenney | [spec](specs/2026-11-11-version-2-0-1-design.md) · [plan](plans/2026-11-11-version-2-0-1.md) | Hecha |
| **2.1.0** | El desierto | [spec](specs/2026-11-11-version-2-1-0-design.md) · [plan](plans/2026-11-11-version-2-1-0.md) | Hecha |
| **2.2.0** | La montaña | [spec](specs/2026-11-10-version-2-0-0-design.md) | Diseñada |
| **2.3.0** | La ciudad, el Devorador del portal y el final | [spec](specs/2026-11-10-version-2-0-0-design.md) | Diseñada |

Las versiones 1.1.1 a 1.4.0 están implementadas y publicadas; las pruebas a mano y en móvil real que quedaron pendientes están en sus informes. Las versiones 1.4.1 a 2.0.0 están implementadas en `develop` (2026-11-11) y sin publicar.

Pendiente a mano de 1.4.1 a 2.0.0: escuchar las músicas nuevas (`caravan`, `jungle`) y los ambientes (los WAV de prueba están en `build/ambient/`); jugar en un móvil real los grupos del mapa, la pregunta de partir con la caravana y la lista de compañeros; jugar a mano una partida con los monstruos a la vista; probar F1 con `--debug`; mirar la dificultad de la Partida nueva + con un héroe de Nv 17-18.

Decisiones tomadas al implementar 1.4.1 a 2.0.0, que no estaban en los diseños:

- Una noche en la posada repone los grupos del mapa (1.7.0): sin eso, un jugador que vacía la pradera antes del Rey Slime podía quedarse sin EXP.
- En una partida de la v1 el nivel sigue tope en 20 y la EXP se para ahí; el tope de 40 solo vale tras partir con la caravana, para no romper el ajuste de la Partida nueva +.
- El bestiario cuenta los enemigos de la v2 solo tras partir (n/22 en la v1).
- Un guardado sin la bandera de la caravana no puede tener zonas, misiones, compañero ni nivel de la v2.
- Las palmeras de la jungla son del Kenney Nature Kit, teñidas para casar con KayKit, en lugar de hechas en código.
- La partida automática se salta cualquier punto de la ruta en el que se atasca (paredes de la mina, rejas cerradas).
- Ajuste de la jungla: además de los PV y la EXP, se bajó el ATK de sus cinco enemigos (las derrotas venían de críticos y venenos).

Orden de las nuevas, y por qué:

- **1.4.1** primero: dos retoques pequeños que el usuario ya pidió.
- **1.5.0** antes de los monstruos visibles: el ataque sorpresa y los objetos nuevos se prueban con los encuentros de siempre.
- **1.6.0** antes de la 1.7.0: los cinco enemigos nuevos ya existen cuando se reparten los grupos por el mapa y se fija cómo se mueve cada uno.
- **1.7.0** es la más grande y cambia el ritmo del juego; va sola. Mantiene la idea de M-12 con otra forma: los grupos huyen de un héroe muy fuerte y el Incienso impide que te ataquen.
- **1.8.0** después: las medallas se esconden en rincones que se recorren con los monstruos ya a la vista, y la Partida nueva + usa las familias y las medallas.
- **1.9.0** al final: el ambiente y la herramienta de depuración no cambian reglas y conocen ya todo lo anterior.
- **2.0.0 a 2.3.0** después de todas las 1.x: las zonas nuevas se diseñan con monstruos a la vista, familias del bestiario, Partida nueva + y ambiente ya hechos. Una zona por versión, cada una jugable hasta su jefe; los planes se escriben uno a uno al llegar a cada versión.
- **2.0.1** justo después de la 2.0.0: decorar los mapas que ya existen con Kenney no cambia reglas, y deja el estilo fijado antes de construir el desierto y la montaña.
