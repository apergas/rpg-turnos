# Ideas para un juego completo

Fecha: 2026-11-03 (revisado con las respuestas del usuario)
Estado: listado de ideas con el alcance ya decidido. Todavía no es un plan.

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Duración | Unas **2 horas** para terminar la historia |
| Encuentros | **Aleatorios**, solo fuera del camino, como ahora |
| Personajes | **Héroe solo**: no hay grupo, la variedad viene de los hechizos y del equipo |
| Modelos | **Low-poly** con paquetes CC0 (Quaternius, Kenney, KayKit) y animaciones; confirmado |
| Orden | Lo elijo yo: ver "Fases" al final |
| Vegetación | La hierba fuera del camino se ve como vegetación alta, más alta que el camino |
| Cámara | **Cenital**, alta e inclinada, como en los ARPG isométricos de hoy (por ejemplo Diablo 4) |
| Equilibrio | Calculado con una simulación de miles de combates (sección "Equilibrio") |

### ¿Qué es low-poly?

Es un estilo de modelos 3D con **pocos polígonos**. Las caras se ven planas y facetadas y llevan colores lisos o texturas muy simples. Es parecido a lo que hay ahora, pero con formas de verdad: un personaje con brazos y piernas que se doblan, un slime con cara, árboles con la copa tallada a facetas y casas con tejas.

- **Ahora:** los personajes son esferas, cajas y cilindros puestos unos encima de otros.
- **Low-poly:** son modelos hechos en Blender o sacados de paquetes gratuitos con licencia CC0. Por ejemplo Quaternius, Kenney o KayKit, que tienen personajes, monstruos (slimes incluidos), árboles y casas, y muchos traen **animaciones** de caminar, atacar, recibir golpes y morir.
- **Por qué lo recomiendo:**
  - Es el salto visual más grande por el menor esfuerzo.
  - Encaja con el aspecto de cuento de Dragon Quest.
  - Funciona bien en la web porque los modelos son ligeros.
  - Las animaciones reales sustituyen a los tweens de ahora.

---

## Alcance para 2 horas

### Estructura

Hay cuatro zonas, cada una con un pueblo (o un refugio) y un jefe. Los niveles de la tabla son los previstos al llegar a cada parte.

| Zona | Lugar | Nivel del héroe | Combates normales | Jefe | Tiempo |
|---|---|---|---|---|---|
| 1 | Pradera de Villaclaro (lo que ya existe, ampliado) | 1 → 5 | 16 | Rey Slime | 25 min |
| 2 | Bosque y aldea del bosque | 5 → 9 | 15 | Bruja del bosque | 30 min |
| 3 | Mina abandonada (mazmorra de 3 plantas) | 9 → 13 | 14 | Golem de piedra | 30 min |
| 4 | Castillo de la Niebla (mazmorra final) | 13 → 17 | 13 | Señor de la Niebla (2 fases) | 30 min |
| | Introducción, final y créditos | | | | 5 min |

El nivel máximo es 20, para quien quiera subir más.

### Reparto del tiempo (unos 120 min)

| Actividad | Minutos | Cálculo |
|---|---|---|
| Combates normales | 39 | 58 combates × unos 40 s (3 rondas de unos 9 s, más la entrada y el resultado) |
| Jefes | 6 | 4 jefes × unas 8,5 rondas × 9 s, más las escenas |
| Caminar y explorar | 45 | Mapas, cofres y mazmorras |
| Pueblos, tiendas, diálogos y escenas | 20 | |
| Derrotas y repeticiones | 10 | Con un 85-90 % de victorias contra los jefes, alguno se repite |

---

## Equilibrio (cálculos)

### Método

- Escribí un simulador con **las mismas reglas que `BattleEngine`**:
  - 5 % de fallo y 1/16 de crítico (ATK × 1,5, sin contar la DEF).
  - Daño `max(1, ATK − DEF/2) × U(0,875 – 1,125)`.
  - Los hechizos usan su poder con la misma variación y no cuentan la DEF.
  - La iniciativa es `VEL × U(0,5 – 1,5)`.
- El héroe del simulador juega con sentido común:
  - Por debajo del 40 % de PV se cura: con Curar si tiene PM, si no con una poción.
  - Guarda PM para dos curaciones.
  - Usa un hechizo solo cuando hace bastante más daño que un ataque.
  - Si no, ataca al enemigo con menos PV.
- Las estadísticas de los enemigos se ajustaron con una búsqueda automática hasta cumplir los objetivos. Cada resultado sale de **1.500 a 4.000 combates simulados**.

### Objetivos

| Situación | Objetivo |
|---|---|
| Combate normal en mitad de zona | Gana más del 99 % · pierde ~18 % de los PV · ~3 rondas |
| Combate normal al entrar en la zona | Gana ~97-99 % · pierde 20-35 % de los PV: se nota el cambio de zona |
| Jefe al nivel previsto, con 3 pociones | Gana ~85-90 % · 7-10 rondas |
| Jefe con 2 niveles menos | Gana ~50-65 %: compensa subir algún nivel más |

Con un 18 % de PV por combate, el héroe aguanta unos 4 combates seguidos antes de tener que curarse. Así los PM de Curar, las pociones y la posada importan.

### Héroe

- **Estadísticas base a nivel 1:** PV 30 · PM 6 · ATK 10 · DEF 5 · VEL 8.
- **Por nivel (fijo):** PV +6 · PM +3 · ATK +2 · DEF +1 · VEL +1. Los PV y PM actuales suben lo mismo que el máximo, como ahora.
- **Equipo inicial:** Palo (+2 ATK) y Ropa (+2 DEF). Con eso queda igual que el héroe de ahora (ATK 12, DEF 7).
- **A nivel 17 con el mejor equipo:** PV 126 · PM 54 · ATK 70 · DEF 53 · VEL 24.

| Hechizo | Nivel | PM | Efecto |
|---|---|---|---|
| Llama | 1 | 3 | 16 de daño a un enemigo (ya existe) |
| Curar | 3 | 3 | Cura 30 PV |
| Llamarada | 7 | 6 | 28 de daño a todos los enemigos |
| Rayo | 10 | 8 | 70 de daño a un enemigo |
| Curar+ | 11 | 7 | Cura 90 PV |

### Tabla de EXP (total acumulado para alcanzar cada nivel)

Está calculada para que el héroe llegue a cada jefe al nivel previsto haciendo los combates del reparto:

| Nv | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|
| EXP | 12 | 35 | 62 | 96 | 180 | 260 | 340 | 421 | 580 | 740 |

| Nv | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 |
|---|---|---|---|---|---|---|---|---|---|
| EXP | 900 | 1073 | 1550 | 1780 | 2010 | 2244 | 2650 | 3100 | 3600 |

**Comprobación por zona:**
- **Zona 1:** 16 combates × ~6 EXP ≈ 96, nivel 5. El jefe da 40 (136, todavía nivel 5).
- **Zona 2:** 15 × ~19 ≈ 285, en total 421, nivel 9. El jefe da 120 (541).
- **Zona 3:** 14 × ~38 ≈ 532, en total 1073, nivel 13. El jefe da 300 (1373).
- **Zona 4:** 13 × ~67 ≈ 871, en total 2244, nivel 17.

La EXP de cada jefe nunca hace saltar un nivel entero, así que la zona siguiente sigue suponiendo un reto.

### Enemigos normales (valores ajustados)

| Zona | Enemigo | PV | ATK | DEF | VEL | Habilidad | EXP | Oro |
|---|---|---|---|---|---|---|---|---|
| 1 (cerca del inicio) | Slime | 24 | 7 | 3 | 5 | — | 4 | 3 |
| 1 | Murciélago | 26 | 12 | 2 | 12 | — | 5 | 4 |
| 1 | Seta saltarina | 43 | 11 | 5 | 4 | Esporas (2 PM, 10) | 6 | 5 |
| 2 | Lobo | 59 | 17 | 10 | 14 | — | 12 | 10 |
| 2 | Duende | 51 | 14 | 9 | 10 | Llama (3 PM, 12) | 13 | 14 |
| 2 | Planta carnívora | 81 | 19 | 14 | 5 | — | 15 | 12 |
| 3 | Golem de barro | 69 | 27 | 26 | 4 | — | 26 | 24 |
| 3 | Araña | 47 | 26 | 18 | 16 | — | 24 | 22 |
| 3 | Espectro | 43 | 23 | 30 | 12 | Hielo (4 PM, 21) | 28 | 30 |
| 4 | Caballero oscuro | 73 | 36 | 38 | 12 | — | 45 | 40 |
| 4 | Gárgola | 61 | 34 | 32 | 18 | — | 42 | 38 |
| 4 | Hechicero | 55 | 27 | 30 | 14 | Rayo (8 PM, 38) | 48 | 50 |

- **Formaciones:** uno o dos enemigos. Seis formaciones por zona, con más probabilidad de las de uno.
- **Zona de inicio:** cerca del punto de inicio solo salen slimes. Así los primeros combates, con el equipo inicial, cuestan un 10-12 % de los PV.

**Resultados del simulador:**

| Zona | Nivel al entrar | Nivel a mitad | Nivel al salir |
|---|---|---|---|
| 1 | Nv 2: gana 99,4 %, pierde 20 % | Nv 3: 99,9 %, 15 % | Nv 5: 100 %, 10 % |
| 2 | Nv 5: 96,9 %, 33 % | Nv 7: 100 %, 18 % | Nv 9: 100 %, 13 % |
| 3 | Nv 9: 98,8 %, 26 % | Nv 11: 99,5 %, 19 % | Nv 13: 100 %, 13 % |
| 4 | Nv 13: 98,9 %, 22 % | Nv 15: 99,5 %, 18 % | Nv 17: 99,9 %, 15 % |

### Jefes (valores ajustados)

| Jefe | PV | ATK | DEF | VEL | Habilidad | EXP | Oro |
|---|---|---|---|---|---|---|---|
| Rey Slime | 142 | 17 | 8 | 7 | Aplastar (4 PM, 19) · 12 PM | 40 | 60 |
| Bruja del bosque | 183 | 23 | 14 | 12 | Llamarada (6 PM, 23) · 40 PM | 120 | 200 |
| Golem de piedra | 341 | 45 | 34 | 6 | — (golpes fuertes) | 300 | 500 |
| Señor de la Niebla | 353 | 46 | 40 | 14 | Rayo (8 PM, 43) | — | — |

**Probabilidad de ganar con 3 pociones:**

| Jefe | Nivel previsto − 2 | − 1 | Previsto | + 1 | Rondas |
|---|---|---|---|---|---|
| Rey Slime (Nv 5) | 53 % | 72 % | **89 %** | 93 % | ~10 |
| Bruja (Nv 9) | 60 % | 73 % | **88 %** | 99 % | ~8 |
| Golem (Nv 13) | 64 % | 85 % | **89 %** | 90 % | ~8 |
| Señor de la Niebla (Nv 17) | 82 % | 87 % | **88 %** | 92 % | ~9 |

- **Rey Slime:** el de ahora (70 PV, ATK 12) está pensado para el nivel 2-3. En el juego completo se pelea al nivel 5, así que sube a 142 PV y ATK 17.
- **Jefe final:** sus números son la suma de las **dos fases**. Cuando se diseñe con detalle (por ejemplo, la fase 2 empieza al 50 % con ataques más fuertes), hay que repetir la simulación.

### Equipo y precios

Hay tres piezas por tienda: arma, armadura y escudo.

| Tienda | Arma | Armadura | Escudo | Total |
|---|---|---|---|---|
| Villaclaro (zona 1) | Espada de cobre +6 ATK · 40 G | Cota de cuero +5 DEF · 30 G | Escudo de madera +3 DEF · 25 G | 95 G |
| Aldea del bosque (zona 2) | Espada de hierro +12 · 150 G | Cota de malla +10 · 120 G | Escudo de hierro +5 · 90 G | 360 G |
| Refugio de la mina (zona 3) | Espada de acero +20 · 400 G | Armadura de acero +16 · 350 G | Escudo de acero +8 · 220 G | 970 G |
| Campamento del castillo (zona 4) | Espada de platino +28 · 650 G | Armadura de platino +22 · 550 G | Escudo de platino +10 · 300 G | 1500 G |

**Flujo de oro:**
- **Zona 1:** empiezas con 50 G y ganas unos 4,7 G por combate. A mitad de zona tienes unos 90 G y puedes comprar todo; el jefe da 60 G más.
- **Zona 2:** unos 18 G por combate más 2 cofres de 50 G. A mitad de zona puedes comprar la espada y la cota, y al final de la zona el escudo.
- **Zona 3:** unos 38 G por combate, 2 cofres de 120 G y los 200 G de la Bruja suman unos 970 G al final de la zona.
- **Zona 4:** unos 64 G por combate, 2 cofres y los 500 G del Golem suman unos 1.500 G.

El simulador da por hecho que a mitad de cada zona ya llevas el equipo de esa zona. Si no lo compras, el combate es más difícil, como pasa en Dragon Quest.

**Objetos y servicios:**
- **Poción:** 8 G, cura 30 PV.
- **Éter:** 30 G, recupera 15 PM. Se vende a partir de la zona 2.
- **Posada:** 5, 15, 30 y 50 G según la zona.

### Frecuencia de encuentros

- **Ahora:** 5 m de gracia y 8 % por metro. Sale un combate cada ~17 m, unos 3,5 s caminando por la hierba. Para un juego de 2 horas es demasiado.
- **Propuesta:** 15 m de gracia y **0,6 % por metro**. Sale un combate cada ~180 m, unos **36 s caminando por la hierba**. Con ~35 minutos de hierba en todo el juego salen los ~58 combates del reparto.
- En las mazmorras no hay camino seguro, así que la frecuencia es la misma en todas partes.

### Lo que el simulador no cubre

- Defender y Huir.
- Debilidades elementales y estados alterados.
- Escenas de los jefes.

Cuando se diseñen, hay que repetir la simulación. Cada debilidad multiplica el daño por 1,5, así que acorta los combates.

---

## Cámara cenital

- **Ángulo:** cámara alta y muy inclinada, unos **55-60° hacia abajo**, a unos 14 m del héroe. Así se ve mucho terreno alrededor, como en los ARPG isométricos.
- **Giro:** fijo. Q y E dejan de girar la cámara, y WASD siempre mueve en la dirección de la pantalla.
- **Zoom:** con la rueda del ratón entre un mínimo y un máximo. Cuesta poco y es útil.
- **Seguimiento:** suave con un pequeño retraso. Al cambiar de zona el encuadre no salta.
- **Paredes y techos:** en interiores y mazmorras, las paredes y techos que tapan al héroe se vuelven transparentes.
- **En combate:** la cámara de combate sigue siendo la de ahora, de lado, porque es más dramática y más propia de Dragon Quest. Solo cambia la del mapa.

## Vegetación

- **Hierba alta (M):** matas de hierba de unos 40-60 cm repartidas con un `MultiMeshInstance3D` por toda la zona fuera del camino.
  - Se mueven con el viento gracias a un shader sencillo.
  - Tienen colores variados.
- **Camino y claro:** quedan **sin hierba alta**, así que se ve claramente dónde no hay encuentros. Encaja con la regla de encuentros, que solo salen fuera del camino.
- **Al pasar el héroe (S):** la hierba se aparta un poco.
- **Detalles (S):** flores y arbustos dispersos.
- **Árboles low-poly (M):** en el bosque y en los bordes de la pradera.
- **Rendimiento en la web:** limitar el número de matas (unos 15.000-25.000) y quitar las lejanas. Con la cámara cenital el encuadre es acotado, así que se puede dibujar solo lo que hay cerca.

---

## Listado de ideas dentro del alcance

Cada idea lleva una talla aproximada:

- **S:** menos de un día.
- **M:** unos días.
- **L:** una semana o más.
- **XL:** un sub-proyecto entero.

**Ya está** marca lo que ya existe.

### 1. Combate
- **Ya está:** Atacar, Llama, Poción, críticos y fallos, IA con pesos, jefes.
- **Defender (S):** reduce a la mitad el daño de la ronda.
- **Huir (S):** depende de la velocidad. Contra los jefes no se puede.
- **Menú de hechizos (S):** lista con todos los hechizos que se conocen.
- **Menú de objetos (S):** lista con todos los objetos de combate.
- **Combates de 1 o 2 enemigos con elección de objetivo (M).**
- **Hechizo de grupo (S):** Llamarada.
- **Tres elementos:**
  - Fuego, hielo y rayo, con debilidad (×1,5) o resistencia (×0,5). (M)
  - "¡Débil!" o "¡Resiste!" en el número de daño. (S)
- **Tres estados (M):** veneno, sueño y silencio.
- **Jefes con mecánicas (M cada uno):**
  - La Bruja se cura.
  - El Golem carga un golpe y avisa una ronda antes.
  - El jefe final tiene dos fases.
- **Enemigo raro "metálico" (S):** huye, tiene mucha DEF y da mucha EXP.
- **Ataque sorpresa (S):** a veces empieza uno de los dos bandos con ventaja.
- **Velocidad de combate x1 / x2 y mensajes rápidos (S).**
- **Fondos de combate por zona (M):** pradera, bosque, mina y castillo.
- **Animaciones de hechizos propias (M):** llamas, carámbanos, rayos.
- **Transición de encuentro (S):** un remolino o un destello.
- **Rótulo con el nombre del jefe al empezar (S).**

### 2. Héroe y progresión
- **Ya está:** niveles con EXP y Llama.
- **Hasta el nivel 20 con la nueva tabla de EXP (S).**
- **Aprender hechizos al subir de nivel (S).**
- **Nombre del héroe personalizable (S).**
- **Semillas de estadística escondidas (S):** suben una estadística para siempre.

### 3. Objetos y equipo
- **Ya está:** Poción.
- **Objetos nuevos (S):**
  - Éter.
  - Antídoto.
  - Despertador.
  - Ala de viaje (vuelve al último pueblo).
  - Pluma de fénix (revive con la mitad de PV si caes, un solo uso).
- **Usar objetos fuera de combate desde el menú (S).**
- **Objetos clave (S):** llaves y amuletos de la historia.
- **Ranuras de equipo (L):** arma, armadura y escudo, con comparación al comprar.
- **El equipo se ve en el modelo (M).**
- **Equipo especial en cofres (S):** por ejemplo, un anillo antiveneno.

### 4. Enemigos
- **Ya está:** Slime y Rey Slime.
- **12 enemigos normales y 4 jefes (L):** los de las tablas.
- **Variantes de color (S):** slime rojo, más fuerte, en la zona 2.
- **Botín por enemigo (S):** objeto común y objeto raro.
- **Bestiario (M):** enemigos vistos y derrotados, descripción, debilidades y dónde aparecen.

### 5. Mundo y exploración
- **Ya está:** pradera, camino y Villaclaro.
- **Cámara cenital (M):** la de la sección anterior.
- **Hierba alta y vegetación (M):** la de la sección anterior.
- **Ampliar la pradera y añadir 3 zonas (XL):** bosque, mina y castillo.
- **Mazmorras con plantas, llaves, palancas y trampas sencillas (L cada una).**
- **Cofres, jarrones y destellos en el suelo (S).**
- **Mapa de zona y minimapa (M):** con el objetivo marcado.
- **Ciclo de día y noche (M):** opcional, solo en la pradera y el bosque.
- **Correr (S).**
- **Hechizo o ala para volver al pueblo (S).**
- **Estatuas de guardado (S):** en las mazmorras.

### 6. Pueblos y PNJ
- **Ya está:** Villaclaro con la anciana.
- **4 asentamientos (L):**
  - Villaclaro.
  - Aldea del bosque.
  - Refugio de la mina.
  - Campamento del castillo.
- **Tiendas (M):** armas y armaduras, y objetos.
- **Posada (S):** cuesta oro, fundido a negro y curación completa.
- **Iglesia (S):** guardar y decir cuánta EXP falta.
- **PNJ con frases que cambian según el avance (M).**
- **PNJ que pasean y animales (M).**
- **Diálogos con sí o no (M).**
- **Indicadores "!" y "?" sobre los PNJ con misiones (S).**

### 7. Historia y misiones
- **Ya está:** la misión de los slimes.
- **Argumento corto (L):**
  - La niebla del castillo trae a los monstruos.
  - Cada jefe guarda un fragmento de un amuleto.
  - Con los tres fragmentos se puede entrar al castillo.
  - El final tiene un epílogo en Villaclaro.
- **Escenas sencillas con cámara y diálogos (M).**
- **6-8 misiones secundarias (M):** cazar, recoger, entregar y un jefe opcional.
- **Diario de misiones (S).**

### 8. Economía
- **Oro (M):** con las cifras de la sección de equilibrio. Al ser derrotado pierdes la mitad.
- **Vender objetos (S).**
- **Medallas pequeñas escondidas (S):** se canjean por premios únicos con un coleccionista.

### 9. Interfaz y menús
- **Pantalla de título (M):** Nueva partida, Continuar, Opciones y Créditos.
- **Menú de pausa (L):** Objetos, Equipo, Hechizos, Estado, Misiones, Bestiario, Opciones y Guardar.
- **Iconos de objetos, hechizos y estados (M).**
- **Marco de ventanas decorado y fuente propia (S).**
- **Soporte de mando (M).**
- **Controles táctiles para jugar en el móvil (M):** importante porque el juego se publica en la web.
- **Tutoriales de una ventana la primera vez que pasa algo (S).**

### 10. Audio
- **Música (L):** título, pradera, bosque, mina, castillo, pueblo, combate, jefe, victoria, derrota y final. Puede ser música libre de derechos.
- **Efectos (M):** menú, pasos, golpes, crítico, cada hechizo, curar, subir de nivel, cofre, puerta, monedas y encuentro.
- **Fanfarrias cortas (S):** subir de nivel, objeto clave y misión cumplida.
- **Sonido de ambiente (S):** pájaros, viento, goteo en la mina.
- **Volumen de música y de efectos por separado (S).**
- **Pitido de texto con un tono por personaje (S).**

### 11. Visuales
- **Modelos low-poly con animaciones (L):** confirmado; sustituyen a las primitivas del héroe, los enemigos, los PNJ y el escenario.
- **Árboles, arbustos, flores, vallas, puentes y agua (M).**
- **Partículas (M):** polvo al caminar, hojas, chispas de los hechizos.
- **Interfaz animada (S):** ventanas que se abren con rebote.

### 12. Guardado y opciones
- **Guardar partida (M):** 3 ranuras, autoguardado al entrar en un pueblo, y en la web se guarda en el navegador.
- **Exportar e importar la partida como archivo (S).**
- **Opciones (M):** volumen, velocidad del texto y del combate, pantalla completa, calidad.
- **Español e inglés (M).**
- **Estadísticas de la partida en los créditos (S):** tiempo, combates y pasos.

### 13. Dificultad y accesibilidad
- **Fácil / Normal (S):** en Fácil recibes un 30 % menos de daño y ganas un 25 % más de EXP.
- **Textos grandes, desactivar el temblor de cámara y reasignar teclas (M).**

### 14. Contenido final
- **Partida nueva + (M).**
- **Jefe opcional difícil tras el final (M).**

### 15. Publicación
- **Ya está:** la versión web en GitHub Pages.
- **Versiones de escritorio para Windows y Linux (S).**
- **Página en itch.io (S).**
- **Nombre definitivo, logo e icono (S).**

### 16. Herramientas de desarrollo (sin tests)
- **Menú de depuración (M):** teletransporte, objetos, nivel, encuentros y etapa de la misión.
- **Simulador de equilibrio como herramienta local (S):** fuera del juego, para repetir los cálculos cuando cambien las reglas.
- **Autoplay por zona y contra un jefe concreto (S).**

## Fuera del alcance

Lo dejamos fuera por las decisiones de duración, héroe solo y encuentros aleatorios:

- **Grupo, compañeros, combos, clases y monstruos aliados:** el héroe va solo.
- **Enemigos visibles en el mapa:** los encuentros son aleatorios.
- **Barco, montura y vehículo volador:** el mundo de 2 horas no los necesita.
- **Varios finales, casino, pesca, granja, cocina, alquimia y torre aleatoria:** demasiado contenido para 2 horas. Si el juego crece, se pueden recuperar.
- **Reputación, banco y regateo.**

---

## Fases

Las he ordenado yo, como pediste.

| Fase | Contenido | Por qué en este orden |
|---|---|---|
| 1. Base visual y de control | Cámara cenital, hierba alta y vegetación, modelos low-poly | Todo el contenido que venga después (mapas, mazmorras, pueblos) se diseña para esta cámara y este estilo. Si se cambia más tarde, hay que rehacerlo |
| 2. Sensación de juego | Música y efectos, pantalla de título, guardar partida, menú de pausa | Es lo que más mejora la experiencia de juego; el resto se apoya en el guardado y en el menú |
| 3. Combate completo | Defender, Huir, 1-2 enemigos con elección de objetivo, menús de hechizos y objetos, Curar, elementos y estados, nueva tabla de EXP | Es el núcleo del juego; las cifras de equilibrio se aplican aquí |
| 4. Economía y equipo | Oro, tiendas, posada, ranuras de equipo, cofres | Da sentido a luchar y explorar |
| 5. Mundo | Zonas 2, 3 y 4 con sus enemigos, jefes, mazmorras y pueblos | Es el grueso del contenido; con las fases anteriores hechas, cada zona es "solo" contenido |
| 6. Historia | Argumento, escenas, misiones secundarias, diario, final y créditos | Une todas las zonas |
| 7. Pulido y publicación | Opciones, dificultad, accesibilidad, idiomas, táctil, itch.io | Para enseñarlo fuera |

Cada fase pasa por su propio diseño, plan e implementación, como los sub-proyectos anteriores.
