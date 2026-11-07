# Reporte de QA: Android en emulador

Fecha: 2026-11-06. Versión probada: 1.0.0, la publicada en `https://apergas.github.io/rpg-turnos/` (`main` en `55f9be2`).

## Estado de los arreglos

Arreglos fusionados en `develop` y publicados en `main` (`307209b`), comprobados con toques reales en el mismo emulador (build local, antes de publicar).

| Incidencia | Arreglo | Comprobado |
|---|---|---|
| QA-01 | El juego ya no pide `preserveDrawingBuffer` a WebGL. Una página mínima, sin el juego, reproducía la pantalla negra con ese atributo | Sale "Gira el móvil" al girar, a pantalla completa y al cargar ya en vertical (`capturas/fix-vertical.png`) |
| QA-05 | La misma causa que QA-01 | 0 errores de WebGL en la consola |
| QA-02 | Las copas se perforan con un tramado entre el héroe y la cámara | Se ve al héroe dentro del bosque (`capturas/fix-arboles.png`) |
| QA-03 | Seta: 43 → 30 PV, ATK 11 → 9. Murciélago: 26 → 22 PV, ATK 10 → 8 | En 2000 combates simulados a nivel 1, con 3 pociones: Slime + Murciélago pasa de 64,5 % a 93,3 % de victorias. Falta jugarlo |
| QA-04 | Todas las filas miden 56 px virtuales, "Sí" y "No" son más anchos y "Pantalla completa" está en el título | Unos 43-48 px CSS a pantalla completa y unos 32 con la barra del navegador, por debajo de los 44 recomendados (`capturas/fix-combate.png`) |
| QA-06 | La línea de mensaje queda reservada | "Partida guardada." ya no mueve los botones de pausa. Comprar puede ensanchar la ventana de la tienda si la lista cambia |
| QA-07 | Sin borde de foco en el móvil | No aparece en ningún menú visitado |
| QA-08 | El toque se mide a la altura del pecho y basta con estar al alcance | Tocar el sombrero del Mercader abre la tienda al llegar. Solo probado con esa figura |
| QA-09 | Al elegir objetivo solo queda "Volver", con "¿A quién? Toca al enemigo." | Correcto, y el menú vuelve completo (`capturas/fix-objetivo.png`) |
| QA-10 | Los toques se ignoran 0,4 s tras cerrarse un diálogo o una ventana | Un toque de más al acabar un diálogo no mueve al héroe. Un toque posterior a esos 0,4 s sí lo mueve |

**Nuevo y sin resolver: banda negra a pantalla completa, vista 1 vez de 4.** Tras activar la pantalla completa, los 273 px superiores se quedaron negros y cortaban la ventana de nombre. Siguió igual después de girar el móvil y volver, hasta recargar. Pasó en la primera carga de la prueba, con 15 pestañas abiertas en el emulador, y no se repitió en las tres siguientes, ya con una sola pestaña. La causa está sin determinar, y no se sabe si tiene que ver con el cambio de QA-01.

**Sigue sin probar** lo mismo que indica "Sin probar" más abajo, sobre todo un móvil real y Safari. El cambio de QA-01 está comprobado solo en Chrome 113 del emulador.

## Resultado

**El juego se puede jugar con el dedo en apaisado: todos los flujos probados funcionan.** Hay un fallo importante: en vertical la pantalla se queda negra, sin el aviso "Gira el móvil". Además hay tres problemas de jugabilidad y varios detalles menores.

La prueba cubre la **primera zona** y los menús, no la partida entera.

| Severidad | Incidencias |
|---|---|
| Alta | 1 |
| Media | 4 |
| Baja | 5 |

## Entorno

| Dato | Valor |
|---|---|
| Dispositivo | Pixel 6 virtual, 2400 × 1080, Android 14, gráfica del PC |
| Navegador | Chrome 113 |
| Área de juego con barra del navegador | 866 × 308 px CSS |
| Área de juego a pantalla completa | 866 × 412-436 px CSS |
| Método | Toques reales con `adb`; el pellizco, con eventos táctiles por JavaScript; consola registrada por el puerto de depuración de Chrome |

## Incidencias

### Alta

**QA-01. En vertical la pantalla se queda negra, sin "Gira el móvil".**
- **Pasos:** girar a vertical en cualquier momento, o cargar la página ya en vertical.
- **Esperado:** el aviso "Gira el móvil" sobre fondo azul oscuro.
- **Obtenido:** negro total. Se repite 3 de 3 veces: a pantalla completa, con barra del navegador y con carga limpia. Al volver a apaisado el juego sigue donde estaba, sin perder nada.
- **Causa:** sin determinar. En el navegador integrado de esta sesión (más moderno) el aviso sí salió a 360 × 740, así que puede depender de esta versión de Chrome o del emulador. Un indicio: la consola registra una vez `BackFramebuffer::Create: GL_INVALID_VALUE`, aunque no he comprobado que coincida con el giro.
- **Por qué importa:** quien abra el juego con el móvil en vertical verá una pantalla negra y puede pensar que no funciona.
- **Evidencia:** `capturas/59.png`.

### Media

**QA-02. El héroe queda oculto detrás de los árboles.**
- **Pasos:** andar hacia el borde arbolado del mapa.
- **Obtenido:** el héroe desaparece detrás de las copas y solo se intuye por un trocito. Si además se ha quedado atascado, no se sabe dónde está. Las paredes de mina y castillo ya se vuelven transparentes; los árboles no.
- **Evidencia:** `capturas/18.png`.

**QA-03. A nivel 1, salir del sendero es muy peligroso.**
- **Observado en 3 combates:** derrota contra una sola Seta (dormido casi todo el combate), huida contra Slime + Murciélago tras bajar a 1 PV, aun gastando una poción, y victoria contra dos Slimes con 18/30 PV.
- **Datos:** el héroe tiene 30 PV. Una Seta tiene 43 PV y ATK 11: le quita unos 7 por golpe y aguanta unos 5 ataques, además de poder dormirlo.
- **Contexto:** es poca muestra y la partida automática sí acaba el juego, pero hoy hemos subido la frecuencia de combates, así que esto se notará más. Conviene jugarlo y decidir.
- **Evidencia:** `capturas/26.png`.

**QA-04. Con la barra del navegador, los botones se quedan pequeños.**
- **Medido a 308 px CSS de alto:** filas del menú de combate unos 23 px de separación y filas de tienda unos 26 px. El botón "Sí" de "¿Te lo equipas ahora?" mide unos 24 px de ancho, porque los botones no ocupan todo el ancho de la ventana. La referencia habitual es 44 px.
- **A pantalla completa:** unos 35 px, mejor, pero tampoco llega.
- **Causa:** el diseño calculó 38 px para 360 px de alto, y la barra de Chrome deja solo 308. Esa barra se come un 25 % de la altura y no se oculta sola.
- **Sugerencia:** ofrecer la pantalla completa en el título, porque hoy está escondida en Opciones, y ensanchar "Sí" y "No".
- **Evidencia:** `capturas/70.png`.

**QA-05. Errores de WebGL en la consola en cada carga.**
- **Obtenido:** `GL_INVALID_VALUE: glBufferData`, 256 veces por carga, hasta que Chrome deja de mostrarlos. Empiezan justo tras arrancar.
- **Efecto visible:** ninguno en apaisado. No sé si también pasa en un móvil real, ni si guarda relación con QA-01.

### Baja

**QA-06. Las ventanas cambian de tamaño y se mueven al pulsar.** Al usar una poción aparece un mensaje, la ventana crece y "Volver" se desplaza: mi siguiente toque, en su posición anterior, no hizo nada. Lo mismo pasa en pausa con "Partida guardada.", que desplaza las dos ventanas. Evidencia: `capturas/45.png`.

**QA-07. El borde de selección sale recortado.** Se ve cortado en "Usar", en la primera fila de Equipo, en "Comprar", en "Sí" y en "Volver" al final de una lista.

**QA-08. Tocar una figura no siempre la usa al llegar.** Con el Mercader, el héroe llegó a su lado y no se abrió la tienda; hubo que pulsar "Comprar". Con el Granjero y el Posadero sí funcionó. Parece depender de en qué parte de la figura caiga el toque.

**QA-09. Al elegir objetivo, el menú parece activo pero no responde.** Con "¿A quién?" siguen a la vista Atacar, Hechizos y demás. Toqué "Hechizos" y no pasó nada; solo responden los enemigos y "Volver". Nada indica que hay que tocar al enemigo.

**QA-10. Un toque de más al acabar un diálogo hace andar al héroe.** Mis toques sobrantes tras la última frase lo llevaron a la hierba y a un combate. Se puede repetir con facilidad si se toca deprisa.

## Flujos probados

| Flujo | Resultado |
|---|---|
| Carga, con la caché del service worker | Correcto, 7 s |
| Título: Nueva partida, Continuar y Opciones | Correcto |
| Nombre: letras, mayúscula y minúsculas, Borrar, Aceptar | Correcto |
| Dificultad: Normal y Volver | Correcto |
| Prólogo avanzando con toques | Correcto |
| Mapa: palanca | Correcto, se suelta y se para |
| Mapa: tocar el suelo para ir | Correcto |
| Mapa: zoom con dos dedos | Correcto |
| Botón de usar ("Comprar") | Correcto |
| Mapa de lo explorado y marcas "!" | Correcto |
| Combate: Atacar, Objetos, Hechizos y Volver | Correcto |
| Combate: dos enemigos, elegir objetivo tocándolo | Correcto |
| Combate: Huir | Correcto; falla por azar, según las reglas |
| Victoria: EXP, oro y misión (slimes 2/3) | Correcto |
| Derrota: pierde 25 G, vuelve al pueblo curado | Correcto |
| Tienda: comprar, equipar, deslizar lista, vender | Correcto |
| Pausa: Estado, Objetos, Equipo, Diario | Correcto |
| Usar poción fuera de combate | Correcto |
| Guardar y Volver al título con confirmación | Correcto |
| Recargar la página y Continuar | Correcto, conserva partida y opciones |
| Opciones: deslizadores, velocidad x2, textos grandes | Correcto |
| Pantalla completa: activar y desactivar | Correcto |
| Salir a la pantalla de inicio y volver | Correcto, conserva el estado sin recargar |
| Girar a vertical | **Falla** (QA-01) |

## Sin probar

- **Rendimiento real:** Chrome daba 30 fotogramas por segundo, pero con la gráfica del PC. No dice nada del calor ni de los FPS en un móvil.
- **Sonido:** no se puede oír desde aquí. Chrome bloquea el audio hasta el primer toque, y no he comprobado que después suene.
- **Primera descarga:** los 7 s son con caché.
- **Instalar en la pantalla de inicio.**
- **El resto del juego:** bosque, mina, castillo, jefes, escenas, misiones secundarias y portal. Solo los recorren las partidas automáticas de escritorio, sin toques.
- **Otras opciones:** velocidad instantánea, textos grandes en combate y calidad alta.
- **Otros dispositivos:** un móvil real, otras pantallas, otros navegadores y Safari en iPhone.

## Prioridad recomendada

1. **QA-01:** es lo primero que puede ver un jugador. Hay que averiguar si pasa en Chrome actual y, sea como sea, evitar la pantalla negra.
2. **QA-02 y QA-04:** afectan a todo el rato de juego.
3. **QA-03:** decidir tras jugarlo.
4. **QA-05:** investigarlo junto con QA-01.
5. **QA-06 a QA-10:** cuando se pueda.
