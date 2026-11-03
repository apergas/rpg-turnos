# Cámara cenital y vegetación: diseño

Fecha: 2026-11-03
Paso: fase 1a de `2026-11-03-ideas-juego-completo.md`. Fase 1 = base visual y de control. La parte 1b (modelos low-poly) tiene su propio diseño.

## Objetivo

- **Cámara:** la del mapa pasa a ser **cenital**: alta, inclinada, de giro fijo y con zoom.
- **Hierba:** la pradera se llena de **hierba alta** que se mueve con el viento. El camino, el claro y la zona del inicio quedan despejados, así que se ve claramente dónde no hay encuentros.
- **Combate:** el escenario de combate también lleva hierba, para que el estilo sea el mismo.

## Decisiones tomadas

El usuario pidió que no se le pregunte, así que todas son la opción recomendada.

| Tema | Decisión |
|---|---|
| Inclinación | 55° hacia abajo (`PITCH_DEG = 55`) |
| Distancia | 14 m del punto que mira (`DISTANCE = 14`); zoom con la rueda entre 9 y 20 m, en pasos de 1,5 m, suavizado |
| Giro | Fijo, con la cámara al sur del héroe mirando al norte. Q y E dejan de hacer nada y desaparece `yaw` |
| Campo de visión | 45° vertical (`FOV = 45`) |
| Movimiento | WASD / flechas en ejes de pantalla: arriba = −Z (norte), derecha = +X |
| Seguimiento | Suave como ahora (`FOLLOW_RATE = 6`); mira a 1 m sobre el héroe |
| Cámara de combate | Sin cambios |
| Ocultación por paredes | No se hace ahora: con 55° solo una casa justo al sur del héroe podría taparlo. Pasa a la fase de mazmorras |
| Hierba | Matas generadas en código (sin recursos externos), con un shader de viento y empuje del héroe |
| Flores | Flores pequeñas de colores repartidas entre la hierba |
| Árboles y arbustos | Fuera de esta parte: llegan con los modelos low-poly (1b) |
| Frecuencia de encuentros | No cambia ahora. La propuesta del listado (15 m y 0,6 %) va con la nueva tabla de EXP en la fase de combate |

## Cámara (`FollowCamera`, reescrita)

- **Posición objetivo:** `target + Vector3(0, 1, 0) + Vector3(0, sin(pitch), cos(pitch)) × distance`. Mira a `target + Vector3(0, 1, 0)`.
  - Con 14 m queda a 11,5 m de altura y 8 m por detrás.
  - Del suelo se ve desde unos 5,5 m al sur del héroe hasta unos 10 m al norte, y unos 21 m de ancho en 16:9.
- **Zoom:** `_unhandled_input` con la rueda del ratón (`MOUSE_BUTTON_WHEEL_UP` acerca, `WHEEL_DOWN` aleja) cambia `_zoom_goal` en ±`ZOOM_STEP` dentro de [`MIN_DISTANCE`, `MAX_DISTANCE`]. `distance` se acerca a `_zoom_goal` con `ZOOM_RATE = 8` por segundo, con suavizado exponencial.
- **`snap()`:** salta a la posición sin suavizar, como ahora.
- **Fuera:** la propiedad `yaw`, `TURN_RATE` y las teclas Q / E.
- `Player` deja de leer la cámara (pierde `camera`) y mueve en ejes fijos. `World.respawn()` deja de tocar `yaw`.

## Hierba (`Vegetation`, `RefCounted`, nueva)

`scripts/world/vegetation.gd` es un constructor estático, como `WorldStage`:

- **`static func build(root: Node3D, area: Rect2, is_free: Callable, seed: int) -> ShaderMaterial`**
  - `area` está en metros sobre el plano XZ.
  - `is_free(Vector3) -> bool` dice si en un punto puede haber hierba.
  - Devuelve el material compartido, para poder moverle el empuje.
- **Matas:**
  - Una sola malla de mata con 5 hojas: triángulos finos de 0,06 m de base y 0,5 m de alto, inclinados hacia fuera en direcciones repartidas.
  - Se hace con `SurfaceTool`. `UV.y` va de 0 en la base a 1 en la punta.
  - Cada mata lleva una escala de 0,8 a 1,3, así que miden de 40 a 65 cm. También llevan un giro aleatorio y un tono aleatorio entre dos verdes, guardado en `INSTANCE_CUSTOM`.
- **Reparto:**
  - Rejilla de 0,65 m con un desplazamiento aleatorio de ±0,3 m. Solo se ponen matas donde `is_free` es cierto.
  - El `RandomNumberGenerator` usa `seed`, así que el reparto es siempre el mismo.
- **Trozos:**
  - Las matas se reparten en `MultiMeshInstance3D` de 12 × 12 m, para que la cámara descarte los trozos que no ve.
  - Sin sombras (`cast_shadow = OFF`).
- **Shader (`shaders/grass.gdshader`):**
  - `cull_disabled`.
  - Color de la base a la punta: el verde oscuro de la base va hacia el tono de la mata.
  - **Viento:** las hojas se balancean según `UV.y²`, con una onda que depende de la posición en el mundo y de `TIME`. La amplitud es de 0,08 m en la punta.
  - **Empuje:** el uniforme `pusher` (`vec3`) aparta las hojas a menos de `PUSH_RADIUS = 0,8 m`, hasta 0,25 m en la punta.
  - Rugosidad 1 y sin especular, como el resto del escenario.
- **Flores:**
  - Otro `MultiMeshInstance3D` con una malla de flor muy simple: una cabeza low-poly de 0,1 m (esfera de 6 lados y 3 anillos) a 0,3-0,45 m de altura, entre las hojas, que tapan el tallo. El color va por instancia.
  - Hay unas 300 por zona de 60 × 60 m, en blanco, amarillo y morado.
  - Siguen la misma regla `is_free` y la misma semilla.
- **`static func set_pusher(material: ShaderMaterial, pos: Vector3)`** pone el uniforme.

## Mapa

- **Exclusiones:** `WorldStage.build()` llama a `Vegetation.build()` con `area = Rect2(-36, -36, 72, 72)`, que cubre más allá de los muros invisibles de ±30 para que el borde no se vea pelado. `is_free` excluye:
  - el camino, el claro y el inicio (`is_on_path`) con 0,3 m de margen;
  - las rocas (un círculo del radio mayor de cada una más 0,2 m).

  Las casas, el pozo, la anciana y el jefe están dentro del claro, así que ya quedan sin hierba.
- **Funciones nuevas en `WorldStage`:**
  - `is_on_path(pos, margin := 0.0)`: el margen se suma a cada radio.
  - `is_grass_free(pos) -> bool`: la regla de arriba.
  - `build()` devuelve ahora el material de la hierba.
- **Empuje:** `World` guarda el material y en cada `_physics_process` llama a `Vegetation.set_pusher(material, player.global_position)`.
- **Suelo:** el verde de la base del suelo se oscurece un poco (`GRASS_FLOOR`). La hierba alta cubre casi todo y entre mata y mata no se ven huecos claros.

## Combate

- `BattleStage.build()` añade hierba con `area = Rect2(-20, -24, 40, 34)` y `seed` fija. `is_free` excluye:
  - una elipse centrada en `(0, 0, -0.3)` con radios 4 m en X y 5,5 m en Z, donde están los luchadores y el primer plano de la cámara;
  - la franja del camino del combate;
  - las rocas del combate.
- El material del combate no tiene empuje: nadie camina.

## Rendimiento

- El objetivo es que la versión web vaya fluida en un portátil normal.
- **Mapa:** en un área de 72 × 72 m salen unas 11.000 matas de 5 hojas, unos 165.000 vértices. Con los trozos de 12 × 12 m y la cámara cenital solo se dibujan unos 6-9 trozos.
- **Si la web no va bien:**
  1. subir la separación de la rejilla a 0,8 m;
  2. reducir las hojas por mata a 4.

## Autoplay

No cambia: la ruta va por puntos del mundo y no depende de la cámara.

## Verificación (sin tests)

- `--check-only` en los scripts tocados y `--import` tras añadir `Vegetation`.
- **Fotogramas** con `--write-movie`. Hay que comprobar:
  - el encuadre cenital;
  - el héroe visible entre la hierba;
  - el camino despejado;
  - el viento;
  - el empuje al pasar;
  - las flores;
  - la hierba en el combate sin tapar a los luchadores.
- **FPS** con `--print-fps` en una ventana normal: el objetivo es 60 en el PC de desarrollo.
- **Versión web:** exportarla sin errores y abrirla en el navegador para comprobar que va fluida.
- **Autoplay** completo sin ERROR ni WARNING nuevos.

## Fuera de alcance

- Modelos low-poly, árboles y arbustos (1b).
- Ocultar las paredes que tapan al héroe (fase de mazmorras).
- Nueva frecuencia de encuentros (fase de combate).
- Minimapa.

## Otros cambios

- `CLAUDE.md`:
  - Layout: `FollowCamera` cenital con zoom, `Vegetation`, `shaders/grass.gdshader`.
  - Controles: Q / E ya no giran la cámara y la rueda hace zoom.
