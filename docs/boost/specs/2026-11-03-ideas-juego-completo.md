# Ideas para un juego completo

Fecha: 2026-11-03
Estado: lluvia de ideas para revisar juntos. Nada de esto está decidido.

## Cómo leer este documento

- Recoge todo lo que podría tener un RPG por turnos en 3D con aspecto de Dragon Quest, pensado como si fuera un juego publicable.
- Cada idea lleva una talla aproximada:
  - **S**: menos de un día.
  - **M**: unos días.
  - **L**: una semana o más.
  - **XL**: un sub-proyecto entero.
- **Ya está** marca lo que ya existe en el vertical slice. Se incluye para dar contexto.
- Al final hay una propuesta de fases. Sirve para empezar a hablar, no es un plan.

---

## 1. Combate

### 1.1 Órdenes básicas
- **Ya está:** Atacar, un hechizo y Poción.
- **Defender (S):** reduce a la mitad el daño de esa ronda y recupera un poco de PM.
- **Huir (S):** la probabilidad depende de la velocidad de cada bando. Contra los jefes no se puede. Si falla, los enemigos atacan gratis.
- **Menú Hechizos (S):** una lista con todos los hechizos que se conocen, no solo el primero.
- **Menú Objetos (S):** una lista con todos los objetos que se pueden usar en combate.
- **Cambiar equipo en combate (M):** cuesta el turno.
- **Analizar (S):** muestra los PV, las debilidades y una descripción del enemigo, y lo apunta en el bestiario.

### 1.2 Combates con varios enemigos
- **Grupos de enemigos (L):** 1 a 4 enemigos por combate, con elección de objetivo.
- **Hechizos de grupo (M):** de área, de línea o de todos los enemigos.
- **Formaciones fijas por zona (S):** por ejemplo "3 slimes" o "2 murciélagos y 1 golem".
- **Enemigos que piden ayuda (M):** llaman a un compañero si quedan pocos.
- **Ataques sorpresa y emboscadas (S):** a veces empiezas tú con ventaja, a veces el enemigo.

### 1.3 Profundidad del sistema
- **Elementos (M):** fuego, hielo, rayo, viento, tierra, luz y sombra. Los enemigos pueden ser débiles, resistentes, inmunes o absorber cada uno.
- **Estados alterados (M):** veneno, sueño, parálisis, confusión, silencio (sin hechizos), ceguera (falla más), miedo y petrificación.
- **Mejoras y debilitamientos (M):** subir o bajar ATK, DEF o VEL durante unas rondas, con iconos en el HUD.
- **Barra de "tensión" o carga (M):** cargar varias rondas para dar un golpe más fuerte.
- **Combos entre compañeros (L):** ataques dobles cuando dos miembros del grupo lo tienen preparado.
- **Habilidades físicas (M):** técnicas de espada que gastan PM, como "Golpe doble" o "Tajo giratorio".
- **Críticos que dependen de la suerte (S):** con una estadística SUE nueva.
- **Contraataques (S):** algunos enemigos o equipos devuelven parte del golpe.
- **Resucitar en combate (S):** con un hechizo o con una pluma.
- **IA con patrones (M):** el jefe cambia de fase al bajar del 50 % de PV y algunos enemigos se curan entre ellos.
- **Velocidad de combate configurable (S):** x1, x2, x4 y mensajes instantáneos.
- **Modo automático para el grupo (M):** órdenes tácticas como "Ataca sin parar", "Cúrate primero" o "No gastes PM".

### 1.4 Presentación del combate
- **Fondos por zona (M):** pradera, bosque, cueva, desierto, nieve, castillo y volcán.
- **Animaciones de hechizos propias (M):** bola de fuego, carámbanos, rayos, tornado.
- **Cámara dinámica (M):** planos cortos en los críticos y paneo al aparecer un jefe.
- **Números de daño con estilo (S):** con colores por elemento, "¡Débil!" y "¡Resiste!".
- **Entrada de jefe con rótulo (S):** su nombre en grande al empezar.
- **Transición de encuentro (S):** un remolino o un fundido con destello, como en los clásicos.
- **Ganar experiencia por acción (S):** un cartel de botín al final del combate.

---

## 2. Grupo y personajes

- **Grupo de hasta 4 personajes (XL):** se unen por la historia.
  - **Héroe:** espadas y magia de luz.
  - **Maga:** magia elemental y poco aguante.
  - **Guerrero:** mucho ATK y DEF, y es lento.
  - **Sacerdote o curandera:** cura y quita estados.
  - **Ladrona:** rápida, roba objetos y encuentra cofres ocultos.
- **Caravana o reserva (L):** más personajes de los que caben en el grupo y cambio entre combates.
- **Clases o vocaciones (XL):** cambiar de clase al llegar a un nivel o en un templo, conservando algunas habilidades aprendidas.
- **Árbol de habilidades (L):** puntos por nivel en ramas como Espada, Escudo, Magia o Coraje.
- **Personalidad (M):** modifica un poco cómo crecen las estadísticas.
- **Monstruos aliados (XL):** algunos enemigos derrotados piden unirse al grupo. Cada uno tiene su propio crecimiento.
- **Conversaciones del grupo (M):** se habla con los compañeros en cualquier momento y comentan lo que pasa.
- **Nombre del héroe personalizable (S):** con una pantalla de nombre al empezar.
- **Aspecto del héroe (M):** colores de pelo, de ropa y de piel.
- **Peso de la historia de cada personaje (L):** una misión personal para cada uno.

---

## 3. Progresión

- **Ya está:** niveles del 1 al 10 con EXP fija.
- **Más niveles (S):** hasta 50 o 99, con una curva ajustada.
- **Crecimiento distinto por personaje (S):** con tablas propias.
- **Aprender hechizos al subir de nivel (S):** con el mensaje "¡Héroe aprende Hielo!".
- **Semillas de estadística (S):** objetos raros que suben una estadística para siempre.
- **Oro y EXP repartidos entre el grupo (S).**
- **Bonificación por combate perfecto (S):** por ganar sin recibir daño.
- **Títulos (M):** se ganan con logros y dan pequeñas bonificaciones.

---

## 4. Objetos y equipo

### 4.1 Objetos
- **Ya está:** Poción.
- **Variedad (S cada una):**
  - Poción grande (cura más).
  - Éter (recupera PM).
  - Antídoto, despertador y pomada para los estados.
  - Pluma de fénix (resucita).
  - Ala de viaje (vuelve al último pueblo).
  - Bomba (daño a un grupo).
  - Agua sagrada (aleja a los enemigos débiles un rato).
- **Objetos de uso fuera de combate (S):** curar en el mapa desde el menú.
- **Objetos clave (S):** llaves, cartas, amuletos de la historia. No se pueden vender.
- **Límite de inventario por personaje (M):** al estilo clásico, con una bolsa compartida aparte.
- **Ordenar el inventario (S):** de forma automática o a mano.

### 4.2 Equipo
- **Ranuras (L):** arma, escudo, casco, armadura y accesorio.
- **Comparación al comprar o equipar (M):** flechas verdes y rojas para cada estadística.
- **El equipo se ve en el modelo 3D (M):** espadas, escudos y cascos distintos.
- **Equipo con efectos (M):** espada de fuego, anillo antiveneno, botas rápidas.
- **Equipo maldito (S):** no se puede quitar sin ayuda del templo.
- **Conjuntos (M):** bonificación por llevar varias piezas del mismo set.
- **Rareza (M):** normal, raro, épico y legendario, con un color en el nombre.

### 4.3 Creación
- **Caldero o forja de alquimia (L):** combinar objetos para obtener otros con recetas que se descubren.
- **Mejorar armas (M):** +1, +2, +3 con materiales.
- **Materiales de recolección (M):** hierbas, minerales y escamas que sueltan los enemigos o hay en el mapa.

---

## 5. Enemigos y jefes

- **Ya está:** Slime y Rey Slime.
- **Bestiario por zona (L):** 4 a 6 enemigos por zona, con variantes de color (slime rojo, slime metálico).
- **Enemigo raro "metálico" (S):** huye enseguida, tiene mucha DEF y da muchísima EXP.
- **Jefes de zona (L cada uno):** cada uno con mecánicas propias. Por ejemplo:
  - Un golem que se repara solo.
  - Una bruja que se multiplica.
  - Un dragón con dos fases.
- **Jefe final con varias fases (L):** con su propio escenario y música.
- **Enemigos visibles en el mapa (L):** en lugar de encuentros aleatorios, o combinados con ellos. Se pueden esquivar y algunos persiguen.
- **Monstruos de élite (M):** más fuertes, con un aura en el mapa y botín especial.
- **Botín por enemigo (S):** con tablas de objetos comunes y raros.
- **Enemigos que roban o huyen con el botín (S).**
- **Bestiario con modelos 3D (M):** se pueden girar e incluye la descripción, las debilidades y dónde aparece.

---

## 6. Mundo y exploración

### 6.1 Mapa
- **Ya está:** una pradera de 60 × 60 m con un camino y un pueblo.
- **Mapa del mundo grande (XL):** varias regiones unidas: pradera, bosque, montaña, desierto, costa, nieve y tierra maldita.
- **Mazmorras (L cada una):** cuevas, una torre, unas ruinas y un castillo. Tienen varias plantas, puzles sencillos (palancas, bloques que se empujan, llaves de colores), trampas y salas de jefe.
- **Cofres y objetos escondidos (S):** cofres visibles, barriles y jarrones que se rompen, y destellos en el suelo.
- **Puntos de vista bonitos (S):** miradores con una cámara especial.
- **Ciclo día y noche (M):** de noche hay enemigos distintos y algunos PNJ duermen.
- **Clima (M):** lluvia, niebla y nieve, con efectos visuales y algún efecto en el combate.
- **Mapa y minimapa (M):** el mapa se va descubriendo al explorar e incluye marcadores de misiones.
- **Brújula o indicador del objetivo (S).**

### 6.2 Movimiento
- **Correr (S):** con un botón o de forma automática al mantener la dirección.
- **Saltar o trepar en sitios marcados (M).**
- **Barco (L):** desbloquea el mar y las islas.
- **Montura (M):** un animal que se mueve más deprisa y evita los encuentros débiles.
- **Vehículo volador al final (L):** se viaja libremente por todo el mundo.
- **Teletransporte entre pueblos visitados (S):** con el hechizo "Regreso".
- **Puntos de guardado y descanso (S):** estatuas o fogatas.

### 6.3 Encuentros
- **Tasa de encuentros por terreno (S):** más en el bosque y menos en el camino.
- **Opción para bajar o quitar los encuentros (S):** en accesibilidad, o con un objeto.
- **Combates evitables si superas mucho al enemigo (S):** los enemigos débiles huyen solos.

---

## 7. Pueblos y PNJ

- **Ya está:** Villaclaro con la anciana.
- **Varios pueblos (L cada uno):** cada uno con su estilo, por ejemplo un pueblo de pescadores, una ciudad con murallas, una aldea en la nieve o un oasis.
- **Tiendas (M):**
  - Armas.
  - Armaduras.
  - Objetos.
  - Una tienda de magia que vende pergaminos.
  - Un mercader ambulante con stock aleatorio.
- **Posada (S):** pagas oro, duermes con un fundido a negro y se cura todo el grupo.
- **Iglesia o templo (S):**
  - Guardar.
  - Resucitar.
  - Quitar maldiciones.
  - Decir cuánta EXP falta para el siguiente nivel.
- **Banco (S):** guarda oro para no perderlo al morir.
- **Muchos PNJ con frases (M):** cambian según el avance de la historia.
- **PNJ que se mueven (M):** pasean, tienen rutinas de día y de noche, y hay animales sueltos.
- **Casas en las que se puede entrar (L):** interiores con muebles y cofres.
- **Diálogos con opciones (M):** sí o no, y respuestas que cambian algo.
- **Retratos de los PNJ en el diálogo (M).**
- **Reputación por pueblo (M):** ayudar sube los descuentos y desbloquea misiones.

---

## 8. Historia y misiones

### 8.1 Historia principal
- **Argumento completo (XL):** un villano, un objeto mágico dividido en piezas (una por región), una traición a mitad de juego y un final con epílogo.
- **Prólogo jugable (M):** una pequeña introducción antes de llegar a Villaclaro.
- **Escenas con cámara (L):** movimientos de cámara, personajes que caminan solos y diálogos encadenados.
- **Narrador o textos de transición entre capítulos (S).**
- **Varios finales (L):** según decisiones o según si se completa todo.

### 8.2 Misiones secundarias
- **Ya está:** una misión de caza.
- **Tablón de misiones en cada pueblo (M).**
- **Tipos de misión (S a M cada uno):**
  - Cazar.
  - Recoger.
  - Entregar.
  - Escoltar.
  - Encontrar a alguien.
  - Derrotar a un jefe opcional.
  - Puzles.
  - Fotografiar.
- **Cadenas de misiones (M):** una lleva a otra.
- **Diario de misiones (M):** activas y completadas, con el objetivo actual.
- **Recompensas variadas (S):** oro, equipo único, recetas, monstruos aliados o títulos.

---

## 9. Economía

- **Oro (M):** lo sueltan los enemigos y lo tienen los cofres. Se pierde la mitad al ser derrotado, al estilo clásico, salvo lo que está en el banco.
- **Vender objetos (S).**
- **Precios que dependen de la reputación o de un regateo (S).**
- **Moneda especial (M):** medallas pequeñas escondidas por el mundo que se canjean con un coleccionista por premios únicos.
- **Casino o salón de juegos (L):** fichas y premios.

---

## 10. Minijuegos y actividades

- **Pesca (M):** peces raros por zona y concursos.
- **Carreras (M):** de monturas o de slimes.
- **Arena de combates (M):** rondas contra enemigos cada vez más fuertes, con premios.
- **Cartas o tablero (L):** un juego propio dentro del juego.
- **Cocina (M):** platos que dan efectos temporales.
- **Granja o huerto en el pueblo (L):** cultivos que crecen con el tiempo de juego.
- **Búsqueda del tesoro (M):** mapas con pistas y tesoros enterrados.
- **Coleccionables (S):** libros de historia, figuras o partituras.
- **Ruleta y tragaperras del casino (M).**

---

## 11. Interfaz y menús

- **Pantalla de título (M):** logo, "Nueva partida", "Continuar", "Opciones" y "Créditos", con el mundo de fondo.
- **Menú de pausa en el mapa (L):**
  - Objetos.
  - Equipo.
  - Hechizos.
  - Estado.
  - Misiones.
  - Bestiario.
  - Mapa.
  - Opciones.
  - Guardar.
- **Pantalla de estado detallada (M):** estadísticas, equipo, resistencias y una barra de EXP.
- **Ventanas con estilo propio (S):** un marco con esquinas decoradas y una fuente pixelada o de cuento.
- **Iconos para objetos, hechizos y estados (M).**
- **Soporte completo de mando (M):** con indicaciones de botones que cambian según el dispositivo.
- **Soporte táctil para móvil en la web (M):** botones en pantalla y un joystick virtual.
- **Velocidad del texto configurable (S).**
- **Historial de mensajes (S):** ver las últimas líneas del diálogo.
- **Tutoriales cortos (S):** una ventana la primera vez que pasa algo.
- **Indicadores en el mapa (S):** "!" sobre los PNJ con misión y "?" para entregarla.

---

## 12. Audio

- **Música por situación (L):**
  - Título.
  - Mapa (una por región).
  - Pueblo.
  - Mazmorra.
  - Combate normal.
  - Combate de jefe.
  - Victoria.
  - Derrota.
  - Posada.
  - Final.
- **Efectos de sonido (M):**
  - Menú (moverse, aceptar, cancelar).
  - Pasos según el suelo.
  - Golpes y críticos.
  - Cada elemento de magia.
  - Curación.
  - Subir de nivel.
  - Abrir un cofre.
  - Puertas.
  - Monedas.
  - El aviso de un encuentro.
- **Fanfarrias cortas (S):** subir de nivel, conseguir un objeto clave, completar una misión.
- **Sonido de ambiente (S):** pájaros, viento, agua y fuego.
- **Volumen por canal (S):** música, efectos y voces.
- **"Voces" de texto (S):** un pitido por letra con un tono distinto para cada personaje.

---

## 13. Visuales y efectos

- **Modelos con más detalle (L):** siguen hechos con primitivas o pasan a modelos low-poly hechos en Blender, con animaciones de caminar, atacar y lanzar hechizos.
- **Árboles, hierba alta, flores, vallas, puentes y ríos (M).**
- **Agua con shader (M):** reflejos y orillas.
- **Partículas (M):** polvo al caminar, hojas, chispas y luciérnagas de noche.
- **Sombras y luz por hora del día (M).**
- **Filtro o postprocesado opcional (S):** un aspecto "retro" con píxeles grandes o con contornos.
- **Cámara mejorada (M):** se acerca en los interiores, evita las paredes y hace zoom con la rueda.
- **Interfaz animada (S):** las ventanas se abren con un rebote y el cursor late.
- **Pantalla de carga con consejos (S).**

---

## 14. Guardado y sistema

- **Guardar partida (M):** varias ranuras, cada una con la hora jugada, el nivel y el lugar. En la web se guarda en el navegador.
- **Autoguardado (S):** al entrar en un pueblo o antes de un jefe.
- **Exportar e importar la partida como archivo (S):** útil en la web para no perderla.
- **Estadísticas de la partida (S):** tiempo jugado, combates, pasos y oro ganado.
- **Opciones (M):**
  - Volumen.
  - Velocidad del texto.
  - Velocidad del combate.
  - Invertir la cámara.
  - Pantalla completa.
  - Calidad gráfica.
  - Idioma.
- **Idiomas (M):** traducir los textos con el sistema de traducción de Godot (español e inglés para empezar).
- **Logros (M):** propios, con una pantalla dentro del juego.

---

## 15. Dificultad y accesibilidad

- **Niveles de dificultad (S):** Fácil, Normal y Difícil, que cambian el daño recibido y la EXP.
- **Modos de desafío (M):** sin tiendas, sin huir, nivel bajo o un modo "hardcore" con una sola vida.
- **Accesibilidad (M):**
  - Textos grandes.
  - Alto contraste.
  - Modo para daltónicos en los colores de los elementos.
  - Reasignar los botones.
  - Desactivar el temblor de cámara.
  - Quitar los encuentros aleatorios.

---

## 16. Contenido final y rejugabilidad

- **Partida nueva + (M):** se empieza de nuevo conservando el nivel y el equipo, con enemigos más fuertes.
- **Mazmorra opcional muy difícil tras el final (L).**
- **Superjefe secreto (M).**
- **Compendio al 100 % (M):** bestiario, objetos y misiones, con un premio por completarlo.
- **Torre de pisos aleatorios (L):** una mazmorra que cambia en cada visita.
- **Créditos con un resumen de la partida (S).**

---

## 17. Web, plataformas y publicación

- **Ya está:** la versión web en GitHub Pages.
- **Versiones de escritorio (S):** Windows, Linux y Mac desde el mismo proyecto.
- **Versión para móvil (L):** controles táctiles y una interfaz adaptada.
- **Página en itch.io (S):** capturas, descripción y descarga.
- **Icono, nombre definitivo, logo y tráiler (M).**
- **Pantalla de "versión" y novedades (S).**
- **Enviar opiniones desde el juego (M):** un formulario sencillo.

---

## 18. Herramientas de desarrollo (sin tests)

Sirven para comprobar las cosas a mano más deprisa, de acuerdo con la regla del proyecto: nada de tests automáticos.

- **Menú de depuración (M):**
  - Teletransportarse.
  - Dar objetos.
  - Subir de nivel.
  - Activar o quitar encuentros.
  - Ir a cualquier combate.
  - Cambiar la etapa de la misión.
- **Datos en recursos o tablas (M):** enemigos, objetos, tiendas y diálogos en `.tres` o JSON, para añadir contenido sin tocar el código.
- **Editor de diálogos sencillo (L):** archivos de texto con un formato propio.
- **Autoplay ampliado (S):** recorre mazmorras y prueba jefes concretos.
- **Hoja de equilibrio (S):** una tabla con las estadísticas de todos los enemigos por zona y el nivel esperado del héroe.

---

## 19. Propuesta de fases para empezar a hablar

| Fase | Contenido | Por qué en este orden |
|---|---|---|
| 1. Sensación de juego | Sonido y música, pantalla de título, guardar partida, menú de pausa con estado y objetos | Es lo que más cambia la impresión al jugar; el resto se apoya en el guardado y en el menú |
| 2. Combate completo | Defender, Huir, varios enemigos con elección de objetivo, elementos, estados, más hechizos y objetos | Es el corazón del juego; conviene cerrarlo antes de crear mucho contenido |
| 3. Economía y equipo | Oro, tiendas, posada, ranuras de equipo, botín | Da motivo para luchar y explorar |
| 4. Grupo | Segundo y tercer personaje con sus papeles | Multiplica las decisiones en combate |
| 5. Mundo | Segunda región y primera mazmorra con su jefe; mapa y cofres | Primer "capítulo" largo |
| 6. Historia | Argumento, escenas, varios pueblos, misiones secundarias y diario | Une todo lo anterior |
| 7. Pulido y publicación | Opciones, accesibilidad, idiomas, itch.io, versiones de escritorio | Para enseñarlo fuera |
| 8. Extra | Minijuegos, monstruos aliados, alquimia, contenido final | Lo que más alarga la vida del juego |

## Preguntas para la revisión

- ¿Qué tamaño de juego queremos? ¿Unas 2 horas, unas 10 o más de 20?
- ¿Encuentros aleatorios clásicos, enemigos visibles en el mapa o ambos?
- ¿Un héroe solo o un grupo?
- ¿Modelos hechos con primitivas o pasamos a modelos low-poly?
- ¿Qué fase empezamos primero?
