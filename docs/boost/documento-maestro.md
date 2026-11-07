# Documento maestro

Fecha: 2026-11-07. Versión publicada: **1.1.0**.

Este documento es la base de trabajo a partir de ahora. Reúne:

- las conclusiones de las dos pasadas de QA sobre la 1.0.0 y la 1.1.0 (Héctor y la pasada larga en Chrome);
- lo que queda abierto en el resto de documentos (`estado-proyecto.md`, `ideas-sueltas.md`, `2026-11-03-ideas-juego-completo.md`, los informes de `docs/boost/qa/` y los diseños y planes de la 1.1.0).

Solo recoge lo que tiene sentido hacer. Lo descartado va al final, con el motivo.

**Cómo se usa:**

- Cada punto tiene un ID (`M-nn`). Cuando un punto entra en un diseño o en un plan, se enlaza aquí. Cuando se publica, se marca como hecho con su versión.
- Los demás documentos se quedan como registro histórico. Si contradicen a este, manda este.

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
| M-01 | Pantalla blanca o congelada en la web (B02) | Si pasa, el jugador no sabe que su partida está guardada | En `html/head_include`, escuchar `webglcontextlost` en el canvas y mostrar encima un aviso en HTML: "El navegador ha cortado los gráficos. Recarga la página: tu partida está guardada." con un botón Recargar. Es defensivo: no arregla la causa, pero quita el bloqueo | S |
| M-02 | Bestiario que no se puede completar (B01, E02) | Una partida migrada o con la misión del Slime de Metal entregada no llega a 17/17 | 1) Al migrar un guardado anterior al bestiario, marcar como vistos los enemigos comunes de cada zona cuyo jefe está vencido, y el Slime de Metal si su misión está cumplida. 2) Con la misión ya cumplida, el Slime de Metal sigue saliendo en la mina, pero raro (un 5 % en lugar del 25 %) | S |
| M-03 | Huir de un jefe (B04) | El jugador no sabe si está prohibido o si ha fallado | Contra un jefe, la fila "Huir" sale en gris con el motivo "No puedes huir", como las demás filas que no se pueden usar. Desaparece el caso NO_ESCAPE | S |
| M-04 | Qué hace cada hechizo (B03) | Los objetos lo dicen y los hechizos no | Añadir a `Skill` una descripción corta ("Cura 30 PV.", "Daño de fuego a todos.") y mostrarla en la fila, como hace `ITEMS`. También en la página Estado de la pausa | S |
| M-05 | Botín de los cofres (I02) | El aviso de 2 s se pierde | El contenido del cofre sale en la ventana de diálogo y espera a Enter o a un toque, como en Dragon Quest: "¡Encuentras 120 monedas de oro!". En la partida automática avanza solo | S |
| M-06 | Teclas mantenidas y confirmaciones rápidas en combate (B05) | Movimientos y elecciones que el jugador no quería | 1) Ignorar las repeticiones (`echo`) del menú hasta la primera pulsación nueva tras abrirse. 2) Un sonido y un parpadeo del cursor cuando el menú ya acepta órdenes | S |

### Prioridad 2: orientación

La mina fue lo que más costó a los dos QA.

| ID | Qué | Por qué | Propuesta | Talla |
|---|---|---|---|---|
| M-07 | Nombre del lugar | En la mina no se sabe en qué planta estás | 1) Al entrar en una zona, un rótulo grande unos segundos: "Mina abandonada · Planta 2". 2) Encima del mapa pequeño, una línea fija con el nombre corto. Cada `ZoneData` gana un `display_name` | S |
| M-08 | Mapa grande y marcas de la mazmorra | Ver una escalera en el mapa pequeño no dice cómo llegar a ella | 1) Página "Mapa" en la pausa (fila nueva en la ventana del héroe), y tocar el mapa pequeño la abre: el mapa explorado de la zona a pantalla casi completa, con la posición del héroe. 2) Marcas nuevas: escalera de subida y de bajada con colores distintos, palanca (otro color cuando ya está bajada), reja (otro color cuando ya está abierta) y llave | M |
| M-09 | Progreso en las frases de espera (I07) | Una misión de recoger o cazar no dice si avanza | Las frases de espera de una misión `GATHER` o `HUNT` terminan con "Llevas 1 de 3." Así no hace falta abrir el Diario | S |
| M-10 | Nombre en la acción (I03) | Con dos figuras cerca, no se sabe con quién vas a hablar | La acción dice con quién: "Hablar · Granjero", "Comprar · Mercader". En el móvil, el nombre va en el botón de usar | S |
| M-11 | Objetivo más claro en la mina | "Vence al Golem de piedra" no dice cómo llegar | Que el objetivo principal cambie según la planta y las banderas: "Baja a la segunda planta", "Busca la palanca", "Busca la llave de la reja", "Vence al Golem de piedra". Sale de `StoryState.goal_text()` con las banderas de la mina | S |

### Prioridad 3: comodidad

| ID | Qué | Por qué | Propuesta | Talla |
|---|---|---|---|---|
| M-12 | Menos combates por zonas ya superadas (Héctor, I08) | Volver a curarse o a comprar se hace pesado | 1) Si el héroe supera en 4 niveles el nivel de salida de la zona, los encuentros salen a la mitad. Es la regla de Dragon Quest: los débiles no se acercan. 2) Un objeto nuevo, **Incienso** (20 G, en todas las tiendas): sin encuentros durante 200 m. La partida automática no lo compra | S |
| M-13 | Curar fuera de combate (I10) | Para curarse con PM hay que entrar en una pelea | En la ventana del héroe de la pausa, una fila nueva "Hechizos" con Curar y Curar+ y su coste en PM. Se gasta igual que en combate | S |
| M-14 | Objetivo más visible en combate (Héctor) | La flecha amarilla se pierde en algunos fondos | Además de la flecha, el enemigo apuntado se ilumina un poco y su nombre sale encima de su barra | S |
| M-15 | Primeros pasos en el móvil (Héctor) | No queda claro cómo moverse con el dedo | La primera vez que se entra al mapa en un móvil, una línea: "Toca el suelo para ir allí, o arrastra el dedo para andar." Desaparece al andar. Se guarda en las opciones | S |
| M-16 | Datos de la partida en el título (Héctor) | "Continuar" no dice qué partida vas a cargar | Bajo "Continuar", una línea pequeña: "Rocío · Nv 12 · Mina · 1:05". Sale del propio guardado. En la 1.3.0 pasa a cada ranura (M-20) | S |
| M-17 | Avisos de derrota (I05) | La primera derrota sorprende: pierdes la mitad del oro y apareces en otro sitio | Una frase de la Abuela Rosa o del Diario antes del Rey Slime: "Si caes, despiertas en el último lugar seguro, pero pierdes la mitad del oro." No se da un nivel recomendado: eso lo descartaste | S |

### Prioridad 4: cierre y contenido

| ID | Qué | Por qué | Propuesta | Talla |
|---|---|---|---|---|
| M-18 | Resumen de lo que queda (E01) | Saber qué falta sin inventar porcentajes | En el Diario, un apartado "Colección": historia (terminada o no), misiones n/7, bestiario n/17 y cofres n/total. Por separado, sin un porcentaje total | S |
| M-19 | Fichas del bestiario (E02) | El álbum solo enseña la figura | Tocar un cromo abre su ficha: zona donde vive, debilidades y resistencias, y si lo has vencido. Pide guardar también los vencidos, con versión nueva de guardado; en un guardado anterior, los vistos cuentan como vencidos | M |
| M-20 | Varias partidas (Héctor) | Una sola ranura: probar otra dificultad borra la partida | Tres ranuras, con los datos de M-16 en cada una. "Continuar" abre la lista de ranuras; "Nueva partida" pide ranura y pregunta antes de sobrescribir una ocupada. El autoguardado escribe en la ranura en curso. Un guardado antiguo pasa a la ranura 1. Cambia `SaveStore` y el título | M |
| M-21 | Exportar e importar la partida (QAM-08) | En iOS, la app instalada no ve la partida jugada en Safari | Con un archivo: en la web se descarga y se sube con el selector del navegador; en escritorio, con una ventana de archivo. Se exporta e importa una ranura, y lo importado pasa por `SaveData.is_valid()` | M |
| M-22 | Reto tras el final (E03) | El equipo final no tiene uso después de los créditos | Tras los créditos, en el salón del trono aparece el **Eco de la Niebla**: una fase, pensado para nivel 20 con el equipo de platino, más duro que el Señor, con un golpe cargado como el del Golem. Premio, una sola vez: la **Corona de bruma**, accesorio único con ATK +5 y DEF +5. Se puede repetir el combate. No cambia los créditos | L |

---

## 3. Pendientes heredados

Lo que queda de los informes anteriores y se puede hacer desde aquí, sin un móvil real.

| ID | Qué | Propuesta | Talla |
|---|---|---|---|
| M-23 | En Android, la fila "Pantalla completa" del título no vuelve tras salir de pantalla completa (QAM-21) | Que la fila mire el modo de la ventana cada vez que se enseña el menú, y no solo al construirlo | S |
| M-24 | Pantalla completa en la web de escritorio | Hoy solo existe en Android. La misma fila en Opciones también en el navegador de escritorio | S |
| M-25 | En el iPad, el aviso dice "Gira el móvil" | "Gira la pantalla" en todos los dispositivos | S |

---

## 4. Ideas sin plan

Vienen de `2026-11-03-ideas-juego-completo.md`. Las dejo ordenadas por lo que creo que aportan. Ninguna es urgente.

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

---

## 5. Descartado

| Propuesta | Motivo |
|---|---|
| Nivel recomendado antes de cada jefe | Lo descartaste en los evolutivos. La Abuela ya sugiere entrenar antes del Rey Slime, y M-17 avisa de lo que cuesta caer |
| Límite a la sequía de encuentros (I08) | Choca con lo que pide Héctor, que quiere menos combates. El ritmo ya se ajustó en la 1.0.0 |
| Fijar una misión en la pantalla (I04) | El objetivo principal ya va primero, y en el móvil no cabe más |
| Pruebas de regresión automáticas (E04) | El proyecto no tiene tests, por decisión tuya |
| Inglés | Descartado: el juego es solo en español |
| Criatura que sigue al héroe por el mapa | Quedó fuera de la 1.1.0. Se recupera si vuelve a pedirse |

---

## 6. Orden y planes

| Versión | Contenido | Plan |
|---|---|---|
| **1.1.1** | M-01 a M-06 y M-23 a M-25: errores, confusiones y lo heredado | [plan](plans/2026-11-07-version-1-1-1.md) |
| **1.2.0** | M-07 a M-17: orientación y comodidad | [plan](plans/2026-11-07-version-1-2-0.md) |
| **1.3.0** | M-18 a M-21: colección y partidas | [plan](plans/2026-11-07-version-1-3-0.md) |
| **1.4.0** | M-22: el Eco de la Niebla | [plan](plans/2026-11-07-version-1-4-0.md) |

Cada plan da por hecho el anterior. Las ideas de la sección 4 no tienen plan hasta que se elija alguna.
