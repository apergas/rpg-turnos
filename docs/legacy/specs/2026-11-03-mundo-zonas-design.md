# Mundo, zonas 2 a 4: diseño

Fecha: 2026-11-03
Paso: fase 5 de `2026-11-03-ideas-juego-completo.md`. Va después de las fases 3 (combate completo) y 4 (economía y equipo). Usa sus sistemas sin cambiarlos.

## Objetivo

Pasar de una pradera a **cuatro zonas** que se recorren en unas 2 horas:

1. **Pradera de Villaclaro** (ya existe).
2. **Bosque** con la **aldea del bosque**.
3. **Mina abandonada**, una mazmorra de 3 plantas con un refugio a la entrada.
4. **Castillo de la Niebla**, la mazmorra final, con un campamento delante.

Cada zona tiene sus enemigos, su jefe, su tienda y sus cofres, con las cifras de la sección "Equilibrio" del listado.

## Decisiones tomadas

El usuario pidió que no se le pregunte, así que todas son la opción recomendada.

| Tema | Decisión |
|---|---|
| Estructura | **Un mapa por zona**, y uno más por cada planta de mazmorra. Se pasa de uno a otro por **salidas** en los bordes: un arco o una puerta con un rótulo ("Al bosque →"). Fundido a negro al cambiar. Volver atrás siempre se puede |
| Bloqueos | La salida a la zona 2 se abre al derrotar al Rey Slime ("La niebla del norte se disipa…"). La mina se abre al vencer a la Bruja y el castillo al vencer al Golem. Antes de eso, la salida muestra una barrera de niebla y un aviso |
| Datos de zona | `ZoneData` (`Resource`, en `data/zones/*.tres`): tamaño, semilla, colores del suelo y de la hierba, si hay hierba, camino, rocas, árboles, edificios, salidas, PNJ, cofres, formaciones de encuentros, música, y la luz y la niebla (la mina es oscura y el castillo neblinoso). `WorldStage` pasa a construir cualquier zona a partir de su `ZoneData` |
| Zona 2: Bosque (Nv 5-9) | 60 × 80 m con muchos árboles (`trees_A/B`) y claros. La **aldea del bosque** es un claro con 3 casas, una tienda (Espada de hierro 150 G, Cota de malla 120 G, Escudo de hierro 90 G, Poción, Antídoto y Éter), una posada (15 G) y una PNJ. Enemigos: **Lobo**, **Duende** y **Planta carnívora**, con los valores del listado. Jefe: **Bruja del bosque** en un claro al fondo |
| Zona 3: Mina (Nv 9-13) | **Refugio** a la entrada (tienda de acero: 400, 350 y 220 G; posada 30 G). Tres plantas de pasillos y salas hechas con bloques de roca en una rejilla de 4 m, dibujadas a mano en `ZoneData` como texto ASCII (`#` roca, `.` suelo, `S` subida, `B` bajada, `C` cofre, `L` palanca, `D` puerta cerrada, `K` llave). Puzles: una **palanca** abre una puerta en la planta 2 y una **llave** abre la sala del jefe en la planta 3. Oscura, con antorchas (luces puntuales). Sin hierba: encuentros en todo el suelo de la mina. Enemigos: **Golem de barro**, **Araña** y **Espectro**. Jefe: **Golem de piedra** |
| Zona 4: Castillo (Nv 13-17) | **Campamento** delante (tienda de platino: 650, 550 y 300 G; posada 50 G). Dos plantas: el **patio** con la niebla y la **sala del trono**. Muros y suelos con las piezas `wall_*` del Medieval Hexagon donde encajen y bloques en el resto. Enemigos: **Esqueleto guerrero**, **Esqueleto pícaro** y **Esqueleto mago** (KayKit Skeletons, con sus animaciones). Sustituyen al Caballero oscuro, la Gárgola y el Hechicero del listado con las mismas estadísticas, porque sí hay modelos para ellos. Jefe final: **Señor de la Niebla**, con 2 fases (ver abajo) |
| Modelos de enemigos | Esqueletos: KayKit Skeletons. Bruja: la `Mage` con túnica y sombrero morados oscuros. El resto se hace en código, en estilo low-poly facetado como el slime: **lobo** (cuerpo y cabeza en cuña con patas), **duende** (como un slime pequeño verde con orejas puntiagudas y gorro), **planta carnívora** (tallo con cabeza de dos mandíbulas que se abre al atacar), **golem de barro** y **golem de piedra** (bloques facetados; el de piedra es más grande y gris), **araña** (cuerpo y ocho patas) y **espectro** (gota translúcida que flota con aura azul) |
| Señor de la Niebla | `Skeleton_Mage` a escala 1,6 con aura morada. Las estadísticas totales del listado se reparten en dos fases. **Fase 1:** 200 PV, ATK 42, Rayo 40. **Fase 2**, al llegar a 0 en la fase 1: la niebla lo envuelve, recupera **180 PV**, ATK 50, usa **Niebla** (todos los objetivos, 30 de daño y 30 % de silencio) y deja de tambalearse. Se simula de nuevo para que gane un 85-90 % al nivel 17 |
| Jefes | **Bruja:** se cura 40 PV una vez por debajo del 40 % y lanza Llamarada. **Golem de piedra:** "carga" una ronda (aviso "El Golem acumula fuerza…") y al siguiente golpea por ×2; Defender lo reduce. **Señor de la Niebla:** dos fases. Todos sin poder huir |
| Fragmentos | Cada jefe de las zonas 2 a 4 da un **fragmento del amuleto**, un objeto clave. La historia los usa en la fase 6 |
| Encuentros | Por zona, con las formaciones y pesos de `ZoneData`, y la misma regla de 15 m y 0,6 %. En las mazmorras no hay camino seguro, pero las salas con escaleras sí lo son |
| Viaje rápido | **Ala de viaje** (objeto, 25 G): te lleva a la entrada del último pueblo o refugio que hayas visitado. No hay hechizo de regreso |
| Guardado | Guarda la zona actual, la posición, las salidas abiertas, los cofres, las palancas y las llaves |
| Cámara | La cenital de siempre. En las mazmorras, los bloques de roca o de muro que quedan entre la cámara y el héroe se vuelven transparentes (pasa del "fuera de alcance" de la fase 1a a esta fase) |
| Rendimiento | Cada mapa construye solo lo suyo y libera el anterior. La hierba solo está en la pradera y el bosque |

## Arquitectura

- **`ZoneData`** (`Resource`) y `data/zones/pradera.tres`, `bosque.tres`, `mina_1.tres`, `mina_2.tres`, `mina_3.tres`, `castillo_patio.tres` y `castillo_trono.tres`.
- **`WorldStage.build(root, zone)`:** construye a partir de los datos. La pradera actual pasa a ser `pradera.tres`, conservando sus posiciones.
- **`World`:**
  - Recibe una `ZoneData`.
  - Gestiona las salidas (señal `exit_requested(zone_id, entry_id)`), los PNJ genéricos (diálogos en `ZoneData`), las palancas, las llaves y las puertas.
- **`Game`:**
  - Cambia de zona con un fundido.
  - Lleva la zona actual y el progreso (`GameState.world_flags`).
  - Elige la música de la zona.
- **`EnemyLibrary`:** las enemigas pasan a `data/enemies/*.tres`. Los modelos de código se añaden a `LowPoly` / `BattleActor` como nuevos `Look`.
- **`BattleStage`:** recibe el fondo de la zona: pradera, bosque (árboles cerca), mina (roca y antorchas) o castillo (muros y niebla).

## Verificación (sin tests)

- `--check-only` en los scripts tocados.
- **Autoplay por zona:** la opción `--autoplay-zone=<id>` empieza en esa zona con el nivel y el equipo previstos. Recorre una ruta por la zona, pelea y va al jefe. Hay que pasarlo en las cuatro zonas sin ERROR ni WARNING.
- **Autoplay completo:** empieza desde el principio y llega al Señor de la Niebla. Hay que medir la duración real y compararla con los ~2 horas previstos (con `--fixed-fps` y el tiempo de juego impreso).
- **Simulador de equilibrio** con los enemigos y jefes reales de cada zona.
- **Fotogramas** de cada zona, cada mazmorra, cada enemigo y cada jefe.
- **Versión web:** se exporta, con medida del tamaño y de los FPS en el navegador.

## Fuera de alcance

- Historia, escenas, misiones secundarias y final (fase 6).
- Ciclo de día y noche, clima y minimapa.
