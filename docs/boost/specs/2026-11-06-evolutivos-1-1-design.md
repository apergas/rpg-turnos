# Evolutivos para la versión 1.1.0

Fecha: 2026-11-06. Parte de `develop` en `961a22f`.

## Objetivo

Publicar la versión 1.1.0 con doce mejoras pedidas por el usuario y dos añadidos: que el jugador no tenga que volver atrás, que los menús sean más cómodos en el móvil, más cosas que coleccionar y una curva de dificultad que suba de verdad.

Los guardados actuales siguen funcionando. El guardado pasa a la versión 9: lo que no exista en uno antiguo empieza vacío.

## Reglas generales

- Solo en español.
- Sin tests automáticos. Se comprueba a mano: `--check-only`, partidas automáticas completas, fotogramas y el emulador Android.
- Las reglas van en clases puras, como en el resto del proyecto.
- Lo que es solo del móvil pregunta a `Device.is_touch()`.

## Bloque 1: cambios pequeños y textos

### 1.1. Misiones sin volver atrás

**Regla:** una misión se puede cumplir en su zona o en una posterior, nunca en una anterior.

| Misión | Recorrido | Estado |
|---|---|---|
| Carta para la Leñadora | Pradera → bosque | Correcta: va hacia delante |
| Setas, Lobos, Gato, Explorador | Misma zona | Correctas |
| El Slime de Metal | Tablón de la mina → pradera | **Incumple la regla** |

**Cambio:** el Slime de Metal pasa a ser encuentro raro de la mina (`rare_enemy` y `rare_chance` 0,25 en `mina_1`, `mina_2` y `mina_3`) y deja de serlo de la pradera. Su premio no cambia.

Volver a zonas anteriores sigue siendo posible; solo deja de ser necesario. Una misión ya aceptada en un guardado antiguo sigue en curso y se cumple en la mina.

### 1.2. Ascuas

"Llama" pasa a llamarse "Ascuas", tanto en el héroe (`llama.tres`) como en el Duende (`llama_duende.tres`). Los identificadores internos no cambian, para no romper los guardados.

### 1.3. Hechizos que sustituyen a otros

- Curar+ sustituye a Curar.
- Llamarada sustituye a Ascuas.
- Rayo se queda: es de otro elemento.

Al final el héroe tiene 3 hechizos. Cada `Skill` puede nombrar el hechizo al que sustituye, y `Leveling.apply()` y `sync_skills()` lo quitan, también al cargar. Al aprenderlo se dice: "¡%s aprende %s! Sustituye a %s."

### 1.4. Vender Palo y Ropa

Si no los llevas puestos, se venden por 1 G. Los accesorios de misión siguen sin venderse, y su motivo pasa de "No vale nada" a "No se vende".

### 1.5. Posada sin pregunta

Al usar al posadero:

1. Dice "Descansa un poco."
2. Fundido a negro (`INN_NIGHT_TIME`), con PV y PM al máximo.
3. Autoguardado, sin más diálogo.

Con PV y PM llenos dice "Se te ve en forma." y no hay fundido.

### 1.6. Etiquetas de interacción

Desaparece "Enter o toca:". Queda solo la acción, igual en escritorio y móvil:

| Qué | Etiqueta |
|---|---|
| Abuela Rosa y aldeanos | Hablar |
| Tendero | Comprar |
| Posadero | Descansar |
| Cofre, reja | Abrir |
| Palanca | Tirar |
| Llave | Coger |
| Portal | Volver |
| Tablón | Leer |
| Pozo | Beber |

### 1.7. Textos

Se aplican los de la sección "Propuesta de textos" que el usuario apruebe.

## Bloque 2: cambios medianos

### 2.1. Tocar fuera cierra

Tocar o hacer clic fuera de la ventana equivale a pulsar "Volver".

| Dónde | Qué hace |
|---|---|
| Subpáginas de pausa | Vuelve a la página principal de la pausa |
| Principal de pausa | Cierra el menú |
| Listas de tienda | Vuelve a "¿Comprar o vender?" |
| "¿Comprar o vender?" | Sale de la tienda |
| Preguntas Sí/No | Cuenta como No |
| Opciones y Bestiario | Vuelve atrás, y Opciones guarda |
| Combate: Hechizos, Objetos, Objetivo | Vuelve al menú de combate |
| Combate: menú principal | Nada |
| Diálogos, nombre, dificultad | Nada |

- Deslizar para mover una lista no cierra nada: solo cuenta un toque corto.
- Tocar un enemigo al elegir objetivo sigue eligiéndolo.
- El toque que cierra no hace andar al héroe (`TAP_GUARD_MS` ya lo cubre).

### 2.2. Casco

Nueva casilla "Casco", vacía al empezar, en el orden Arma, Casco, Armadura, Escudo, Accesorio.

| Casco | DEF | Precio | Tienda |
|---|---|---|---|
| Casco de cobre | +2 | 20 G | Villaclaro |
| Casco de hierro | +3 | 70 G | Aldea del bosque |
| Casco de acero | +5 | 180 G | Mina |
| Casco de platino | +7 | 260 G | Campamento |

La figura muestra la malla `Knight_Helmet`, que hoy está oculta, teñida según el material. Se ve en el mapa y en combate.

### 2.3. Bestiario

Nueva fila "Bestiario" en la pausa, con contador (5/17). Es una cuadrícula con desplazamiento, como un álbum de cromos.

- **Contenido:** los 17 enemigos de `EnemyLibrary`, por zonas y jefes incluidos. Las dos fases del Señor de la Niebla son un solo cromo.
- **Visto:** figura y nombre.
- **Sin ver:** silueta oscura y "???".
- **Cuándo se desbloquea:** cuando el enemigo aparece en un combate, también si llega pidiendo ayuda, y aunque huyas.
- **Imágenes:** un PNG por enemigo en `assets/bestiary/`, generado una sola vez con una herramienta que no se exporta. La silueta es la misma imagen en oscuro. Se descarta renderizar 17 escenas 3D en directo por su coste en el móvil.
- **Guardado antiguo:** los jefes ya vencidos aparecen vistos, lo demás no.

Queda fuera, para más adelante: grupos por tipo y fichas con datos.

### 2.4. Pozos

Un pozo de vida y otro de maná por mapa (14 en total). Están lejos de la aldea, fuera del sendero y separados entre sí, para que llegar tenga riesgo.

- **Efecto:** el de vida llena los PV y el de maná los PM.
- **Recarga:** tras usarlo se queda seco y se llena tras 10 combates ganados o perdidos. Se descarta recargar al salir del mapa porque subir y bajar escaleras lo explotaría.
- **Aspecto:** los modelos de pozo del proyecto, con agua roja o azul brillante, sin agua cuando está seco.
- **Textos:** "Bebes del pozo. PV al máximo.", "Bebes del pozo. PM al máximo.", "Se te ve en forma." y "El pozo está seco. Volverá a llenarse."
- **Datos:** `ZoneData.wells` (id, posición, tipo) y `GameState.well_charge` (id → combates que faltan), en el guardado.

### 2.5. Marcas en el mapa

Añadido aceptado. El mapa de lo explorado marca, en cuanto se revela su celda, tienda, posada, pozos y salidas, con puntos de color. Un pozo seco se ve gris. El mapa sigue sin recibir toques.

### 2.6. Comprar varias de golpe

Añadido aceptado. Los consumibles tienen en su fila un botón "×5" además de la compra normal, activo si hay oro. Con teclado se llega a él con la flecha derecha.

## Bloque 3: criaturas

Una Domadora nueva en cada aldea vende una criatura con la ventana de la tienda. Solo se lleva una, y una nueva sustituye a la anterior sin devolver dinero, avisándolo antes de comprar. No se puede comprar una de nivel inferior a la que ya tienes.

| Zona | Criatura | PV | ATK | DEF | VEL | Precio | Figura |
|---|---|---|---|---|---|---|---|
| Pradera | Gallina de combate | 25 | 9 | 3 | 12 | 70 G | Nueva, low-poly en código |
| Bosque | Lobezno | 45 | 17 | 10 | 14 | 250 G | `WOLF`, más pequeño |
| Mina | Golem pequeño | 70 | 26 | 30 | 4 | 650 G | `MUD_GOLEM`, más pequeño |
| Castillo | Esqueleto leal | 90 | 38 | 28 | 12 | 1000 G | `SKELETON_WARRIOR`, teñido |

Con esos valores hace alrededor del 40 % del daño del héroe. Son orientativos: se ajustan en el bloque 4.

**En combate:**

- Actúa sola en su turno, según su VEL, y ataca al enemigo con menos PV.
- Cada ataque de un enemigo a un solo objetivo va al 30 % a la criatura y al 70 % al héroe. Los hechizos a todos alcanzan a los dos.
- Tiene su barra de PV junto a la del héroe.
- No recibe estados, no gana EXP y no se le pueden usar objetos.
- Si cae, el combate sigue. Vuelve curada en el combate siguiente.
- Si cae el héroe, se pierde igual.

**Motor:** `BattleEngine` gana un luchador `BattleEvent.ALLY` y `BattleScene` lo muestra junto al héroe. Es el cambio más delicado: hoy el motor solo conoce al héroe contra los enemigos.

**Autoplay:** compra la criatura de la zona después del equipo. La criatura se guarda por id.

Queda fuera, para más adelante: que la criatura siga al héroe por el mapa, y que tenga habilidades propias.

## Bloque 4: equilibrio y publicación

Va al final, porque casco, pozos y criatura también dan ventaja al héroe.

### Situación actual

Calculado con las fórmulas, con el equipo completo de cada zona y al nivel previsto:

| Jefe (nivel) | Golpe, % de PV del héroe | Hechizo o carga | Golpes para vencerlo |
|---|---|---|---|
| Rey Slime (5) | 16 % | 35 % | 7 |
| Bruja (9) | 12 % | 29 % | 7 |
| Golem (13) | 27 % | 54 % | 8 |
| Señor de la Niebla (17) | 12-15 % | 32 % | 8 |

Los enemigos comunes quitan un 8-9 % por golpe en bosque, mina y castillo, así que la dificultad no sube.

### Cambios de partida

| Quién | Ahora | Después |
|---|---|---|
| Bruja | 170 PV, ATK 23, Llamarada 23 | 150 PV, ATK 21, Llamarada 20 |
| Rey Slime | 128 PV, ATK 17, Aplastar 19 | 115 PV, ATK 16, Aplastar 17 |
| Comunes de la mina | ATK según datos | ATK +10-15 % |
| Comunes del castillo | ATK según datos | ATK +15-20 % |
| Señor de la Niebla | ATK 42 / 46 | Unos 52 / 56 |

El Golem no se toca de entrada: ya es el más duro y el Señor debe superarlo.

### Cómo se cierra

Se ajustan los valores con combates simulados por un script fuera del repositorio, con y sin criatura, y al nivel y equipo previstos. Referencias:

- Golpe común: 10-12 % de los PV en la mina y 12-15 % en el castillo.
- El Señor de la Niebla no es más fácil que el Golem.
- Partida automática completa, en Normal y en Fácil, sin errores y con un tiempo de juego similar al actual.

No se añade ninguna indicación de nivel recomendado: el jugador lo descubre probando.

### Publicación

- Se incorporan los fallos que encuentre el análisis de QA con otros modelos, si ya ha terminado.
- `application/config/version` pasa a 1.1.0, con `CHANGELOG.md` actualizado.
- `CLAUDE.md` se actualiza en cada tarea.
- El brief de QA se actualiza con las mecánicas nuevas.

## Fuera de alcance

- Indicación de nivel recomendado: descartada por el usuario.
- Grupos y debilidades en el bestiario.
- Criaturas que siguen al héroe por el mapa.
- La banda negra a pantalla completa: se investiga aparte.

## Propuesta de textos

Pendiente de aprobar. Lo no listado se queda como está: el tono y el humor de los diálogos funcionan.

### A. Errores

| # | Dónde | Ahora | Propuesta | Por qué |
|---|---|---|---|---|
| A1 | `inventory.gd:119` | "Fuera de combate" | "Solo fuera de combate" | Se lee como "derrotado", y sobre todo junto a "Solo en combate" |
| A2 | `mina.tres:12` | "Ah, no eres un esqueleto." | "Ah, no eres un espectro." | En la mina no hay esqueletos: están en el castillo |
| A3 | `inventory.gd:70` y `game.gd:80`, `mina_3.tres:45` | "reja" y "puerta" para lo mismo | "reja" en los tres: "Abre la reja...", "Abres la reja con la %s.", "La reja está cerrada con llave." | Es una reja de hierro y debe llamarse igual |
| A4 | `game.gd:74` | "¡Villaclaro está a salvo! La niebla del norte se disipa..." | "¡Villaclaro está a salvo! La niebla deja libre el camino del norte." | La niebla sigue ahí hasta el final del juego |
| A5 | `stat_bar.gd:30`, `battle_hud.gd:116` | "Héroe lvl 3" | "Héroe Nv 3" | "lvl" es inglés |
| A6 | `slime_metal.tres` | Nombra la pradera | "Se busca: Slime de Metal, visto por las galerías de la mina. Muy rápido y muy duro." · "Derrota al Slime de Metal, que se deja ver por la mina. Huye en cuanto puede." · "Slime de Metal (mina)" | Consecuencia del punto 1.1 |

### B. Claridad

| # | Dónde | Ahora | Propuesta | Por qué |
|---|---|---|---|---|
| B1 | `battle_scene.gd:197` | "¡Una Araña salvaje aparece!" | "¡Aparece una Araña!" | "Esqueleto salvaje" o "Espectro salvaje" no encajan, y coincide con "¡Aparecen %s y %s!" |
| B2 | `battle_scene.gd:367` | "¡Has caído...!" | "Has caído..." | Los signos de exclamación chocan con los puntos suspensivos |
| B3 | `battle_scene.gd:414` | "¡Es muy eficaz contra %s!" | "¡%s es débil a esto!" | Más sencillo, y hace pareja con "¡%s lo resiste!" |
| B4 | `inventory.gd:34`, `:52`, `battle_result.gd:66` | "Te lleva al último pueblo...", "Ya estás en un pueblo", "Volverás al pueblo." | "Te lleva al último lugar seguro y deja un portal para volver una vez.", "Ya estás en un lugar seguro", "Volverás al último lugar seguro." | El refugio y el campamento no son pueblos |
| B5 | `story_state.gd:37-39` | "Objetivo: la Bruja del bosque" | "Objetivo: vence a la Bruja del bosque" (igual con el Golem y el Señor) | Hoy no dice qué hacer. Hay que comprobar que cabe en el móvil |
| B6 | `options_panel.gd:54-61` | "Texto", "Combate", "Temblor" | "Velocidad del texto", "Velocidad de combate", "Temblor de cámara" | Sueltas no se entienden. Hay que comprobar que caben en el móvil |
| B7 | `title_screen.gd:294` | "Continuar (terminada)" | "Continuar (partida terminada)" | Más claro |
| B8 | `setas.tres:16` | "Consigue 3 setas de las Setas saltarinas de la pradera para el Granjero." | "Consigue 3 setas de las que saltan por la pradera, para el Granjero." | Repite "setas" |
| B9 | `carta.tres:17` | "Vive en la aldea del bosque, en cuanto se pueda pasar al norte." | "Vive en la aldea del bosque, al norte, cuando se pueda pasar." | Frase enredada |
| B10 | `explorador.tres:21` | "Entró en el patio y hacia el oeste, y hasta ahí sé." | "Entró en el patio, tiró hacia el oeste, y hasta ahí sé." | Frase enredada |
| B11 | `lobos.tres:20` | "¡Por fin se oye el bosque! Y mis árboles." | "¡Por fin se oye el bosque, y sin aullidos!" | "Y mis árboles" no se entiende |
| B12 | `slime_metal.tres:14` | "Solo la magia le hace daño" | "Solo la magia le hace daño de verdad" | Los golpes le quitan 1 PV |
| B13 | `game.gd:641` | "Música y efectos generados por el juego" (bajo "Música y sonido") | "Generados por el propio juego" | Repite el título |

### C. Opcionales

| # | Dónde | Ahora | Propuesta | Por qué |
|---|---|---|---|---|
| C1 | `pause_menu.gd:246`, `shop_window.gd:172`, `world.gd:709` | "Oro 50 G" | "50 G" | La G ya dice que es oro. El color también lo indica |
