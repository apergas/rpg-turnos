# Versión 2.5.0: las ideas del registro

Fecha: 2026-11-13. Parte de la 2.4.1. Cubre M-56 a M-61, las seis ideas que el usuario apuntó en `docs/boost/ideas.md` el 2026-11-11. Después de esta versión el registro de ideas queda vacío.

## Objetivo

Seis retoques sin historia nueva:

- Las medallas pequeñas caen de los enemigos en lugar de estar en el suelo, y hay un Coleccionista en cada pueblo.
- Hay más monstruos en las zonas de la v1, y en todas las zonas los grupos vencidos vuelven poco a poco sin salir del mapa.
- El Slime de Metal va a la mitad de velocidad.
- El portal del Ala de viaje, que hoy es un óvalo azul, tiene más detalle.
- La mina y el castillo tienen una misión opcional más cada uno.
- El fuego de antorchas y hogueras parece fuego, y no una bola naranja.

El guardado sigue en la **versión 14**. No hace falta ningún campo nuevo (ver "Guardado").

## M-56. Medallas que caen de los enemigos, y el Coleccionista en cada pueblo

### Lo que pide el usuario

Que las medallas pequeñas no se recojan del suelo: que caigan de los enemigos con una probabilidad muy baja, como las pociones. Y que el Coleccionista esté en todos los pueblos, como la Domadora, la posada o el mercader.

### Decisión

- **Se quitan las doce medallas del suelo.** `Medals.MEDALS` deja de tener zona y posición, y queda como la lista de los doce ids que ya existen, en el mismo orden. `World` ya no construye medallas (`_build_medal()`, `MEDAL_SEEN_RADIUS`, `MEDAL_RADIUS`, `medal_taken`, `remove_medal()` y el aviso "Coger" de una medalla se van). `WorldStage._near_medal()` y el margen de `MonsterGroups` alrededor de una medalla también se van.
- **Caen en combate.** Cada enemigo vencido que no es jefe tira `MEDAL_CHANCE`, el 2 % de partida, mientras el héroe lleve menos de 12. La cifra se ajusta midiendo: el objetivo es que una partida de la v1 jugada a mano (unos 200 combates) reúna entre 8 y 12. El Slime de Metal la deja **siempre** (un premio a cazarlo). El Eco de la Niebla y los jefes no la dejan nunca.
- **Una medalla caída toma el primer id de `Medals.MEDALS` que el héroe no tiene.** Así `GameState.medals` sigue siendo una lista de ids y el guardado no cambia.
- El combate lo dice en la pantalla de victoria, como un objeto: "¡Consigues una Medalla pequeña! (5/12)". Un evento `DROP` con el id `Medals.MEDAL` y su `progress`. La lógica vive en `BattleEngine._win()` (se pasa `medals_carried` antes del combate, como `quest_items`), y `Game` llama a `Medals.take()` con el id que toque tras la victoria.
- **El Coleccionista está en cada pueblo:** Villaclaro (donde está hoy), la aldea del bosque, el refugio de la mina, el campamento del castillo y la Caravana. Es el mismo hombre: lleva la misma cuenta (`medal_prizes`, `collector_met`) y da los mismos cinco premios, una sola vez cada uno, en cualquiera de sus sitios. Su `INTRO` cambia en los pueblos que no son Villaclaro, con una frase de humor ("¿Que si nos hemos visto en Villaclaro? Imposible: allí vive mi hermano gemelo. ...Es broma, soy yo. Viajo mucho."). En la Caravana solo sale tras elegir compañero (`needs` "companero"), como las misiones de la v2. Cada sitio lleva un punto de la ruta automática a menos de 2,5 m, como la Domadora.
- Los textos de "dónde las encontrarás" cambian: `KEY_TEXTS[MEDAL]` dice "Algunos monstruos las llevan encima. El Coleccionista las colecciona." y la ficha del Diario no cambia ("Medallas: n/12").
- `--autoplay-zone=medallas` deja de recorrer rincones. Ahora caza grupos en la pradera con el héroe de `ECHO_START` hasta tener 12, habla con el Coleccionista y termina con `Medallas: 12/12 · premios 5/5`. `Medals.AUTOPLAY_ROUTE` se va.

### Guardado

Sin cambios: `medals` sigue siendo la lista ordenada de ids de `Medals.MEDALS`, y un guardado viejo con medallas recogidas del suelo vale tal cual (sus ids son los mismos). Una Partida nueva + las conserva, como hoy.

## M-57. Más monstruos en las zonas de la v1, y grupos que vuelven solos

### Lo que pide el usuario

Que haya más enemigos. Para las misiones es un rollo tener que salir y volver a entrar para que reaparezcan.

### Decisión

1. **Más grupos en la v1** (la 2.4.0 ya subió los de la v2): pradera de 10 a 16, bosque de 12 a 18, mina de 7 / 7 / 5 a 9 / 9 / 5 (la tercera planta no cabe más: medido en el plan), patio del castillo de 8 a 11 y salón del trono de 5 a 7. La EXP y el oro no cambian de partida. Si la partida automática de la v1 llega a los jefes con más de dos niveles de sobra frente a hoy (Rey Slime 5, Bruja 9, Golem 13, Señor 17), se baja la EXP de los enemigos comunes de esa zona hasta volver a ese ritmo. Lo mismo para la Partida nueva +, que no debe pasar de 0 derrotas a más de 2.
2. **Repoblación lenta, en todas las zonas** (v1 y v2). Mientras un mapa tenga menos grupos que `monster_count`, cada `REFILL_S` segundos de juego en ese mapa (45 s de partida; se miden con el reloj de la simulación de `World`, `_sim_ms`, como los demás tiempos de la partida automática) vuelve un grupo nuevo. Sale donde lo pondría `MonsterGroups.spots()` y además a `REFILL_GAP` 20 m o más del héroe, nunca a la vista inmediata. No vuelve ninguno durante un Incienso, en una escena ni en la Caravana (que no tiene monstruos). Sale con un fundido de 0,5 s. En la partida automática se imprime `Grupo repuesto (n)`.
3. La regla de los grupos que huyen de un héroe muy fuerte (`EncounterMeter.is_shy()`) no cambia.
4. La partida automática ya no necesita reponer el mapa vacío a mano tan a menudo. `_needs_groups()` y el `AUTOPLAY_STALL_S` siguen como red de seguridad.

## M-58. Slime de Metal a la mitad de velocidad

- `slime_metal.tres`: `map_speed` de 3 a 1,5 m/s.
- `MonsterRoam.RUN_SPEED` (cuando huye del héroe) de 4,5 a 2,25 m/s. Solo lo usa el Slime de Metal. El héroe anda a 5 m/s, así que se le alcanza, pero sigue esquivando por las celdas.
- La partida automática no cambia.

## M-59. Un portal más bonito

### Lo que pide el usuario

El portal se ve raro, "un círculo azul extraño". Con un poco más de detalle.

### Cuál es

El del Ala de viaje: `World._build_portal()` (`world.gd:1482`), un aro plano en el suelo y un óvalo azul sin luz que late, con un rótulo "Portal". Es el que se ve en cada pueblo tras usar un Ala. El portal de la ciudad (`PortalRing`) ya tiene piedras, chispas y luz, y no se toca salvo para compartir el shader nuevo.

### Decisión

- Una escena hecha en código, `TravelPortal` (`scripts/world/travel_portal.gd`, `Node3D`), en lugar del óvalo:
  - **Un marco de piedra** de pie: un arco de bloques bajos (los bloques y piedras de KayKit o de Kenney que ya se usan, teñidos con la piedra clara de `PortalRing`) con dos runas que brillan.
  - **Una superficie que gira**: un disco vertical con un shader nuevo, `shaders/portal_swirl.gdshader` (espiral de ruido animada, borde más brillante, centro más oscuro, sin luz y aditivo). Colores azul y blanco para el Ala; `PortalRing` puede usar el mismo shader en rojo y en calma.
  - **Chispas**: `CPUParticles3D` que suben desde el borde (12 en un móvil, 24 en escritorio, ninguna con calidad baja, como `ZoneParticles`).
  - **Una luz** azul suave (`OmniLight3D`, sin sombras) que late con la superficie.
- El aro del suelo que marca el sitio de vuelta (`set_return_mark()`) gana el mismo brillo (un anillo con el shader en plano, sin marco).
- El rótulo "Portal" se queda.
- Coste: unas +4 llamadas de dibujo cuando está en pantalla. Se comprueba con fotogramas en escritorio y con `--touch`.

## M-60. Una misión opcional más en la mina y el castillo

### Lo que pide el usuario

Donde ya hay más de una misión opcional no se toca nada. La mina y el castillo solo tienen una cada uno (además de la principal): añadir otra en cada uno.

### Decisión

Dos misiones de datos (`data/quests/<id>.tres`), con las reglas que ya existen (`QuestData`, `QuestLog`). Ninguna bloquea nada, y su texto tiene algo de gracia, como pidió el usuario en la 2.4.0.

- **`aranas` · "Telarañas en la galería"** (mina). La da la Minera del refugio. `HUNT` de 5 Arañas, en cualquier planta. Se entrega a la Minera. Premio: 150 G y un Éter. Frases: la Minera no puede trabajar con tantas arañas mirándola ("Una me guiñó los ocho ojos. Los ocho.").
- **`olla` · "La olla de la Posadera"** (castillo). La da la Posadera del campamento. `FIND`: la Olla, una figura de `kind` "item" (como la Cantimplora del desierto), en un rincón del patio, fuera de la ruta automática, a 6 m o más de ella y a 5 m o más de los grupos y los cofres. Se entrega a la Posadera (la posada ya entrega antes un aviso que espera, `_figure_with_report()` con `inn`). Premio: 200 G y una Pluma de fénix. La olla es una figura nueva, `POT`, hecha con el modelo de olla de Kenney que ya usa el refugio (`NatureModels`). Frases: la Posadera sospecha que un esqueleto se la llevó "para hacerse un casco".
- El Diario pasa a "Misiones de Villaclaro n/9", y los créditos cuentan las nuevas.
- Una Partida nueva + las vuelve a ofrecer, como todas.
- Los textos finales se escriben en el plan, con el tono del anexo de la 2.4.0.

## M-61. Un fuego más realista

### Lo que pide el usuario

El fuego es un círculo naranja. Que sea más realista.

### Cuál es

`BattleStage.add_flame()` (`battle_stage.gd:504`): una esfera naranja estirada sin luz propia más una `OmniLight3D` fija. La usan las antorchas de la mina y del castillo (`DungeonMap`), las hogueras del campamento y de la Caravana (`WorldStage._add_decor()`) y los fondos de combate de la mina y del castillo.

### Decisión

- `add_flame()` construye una llama de verdad, con la misma firma, así que todos los que la llaman cambian a la vez:
  - **Dos o tres planos cruzados** que siempre miran a la cámara (billboard en Y), con un shader nuevo `shaders/flame.gdshader`: forma de lágrima con ruido que sube, del amarillo blanco en la base al naranja y al rojo en la punta, aditivo, sin luz, que se mueve solo con `TIME` (no cuesta nada a la CPU).
  - **Brasas**: `CPUParticles3D` pequeñas que suben y se apagan (6 por antorcha, 14 por hoguera; la mitad en un móvil; ninguna con calidad baja).
  - **Luz que parpadea**: la `OmniLight3D` cambia su energía con un ruido lento (la antorcha de la mina ya parpadea con `DungeonMap`; se unifica en `add_flame()`).
- `size` sigue escalando la llama (la hoguera es más grande que la antorcha).
- Coste medido: al menos tantas llamadas de dibujo como hoy por llama (un `MultiMesh` no sirve aquí). En la mina, con muchas antorchas a la vista, no deben pasar de +12 llamadas por vista. Si pasan, las antorchas lejanas (más de 20 m) no llevan brasas.
- Se comprueba con fotogramas en la mina, el campamento del castillo, la Caravana y un combate en la mina.

## Lo que no cambia

- El guardado (versión 14).
- La EXP y el oro de la v2.
- Las reglas del combate, salvo el `DROP` de la medalla.

## Comprobación

Sin tests, como siempre. `--check-only` de los scripts cambiados, y estas partidas automáticas (con `APPDATA` apuntando al scratchpad):

- La v1 entera (`--autoplay`, `--quit-after 150000`): niveles a los jefes, tiempo, misiones (n/9 con las nuevas si la ruta pasa por ellas), medallas reunidas.
- `--autoplay-zone=medallas`: llega a `Medallas: 12/12 · premios 5/5`.
- `--autoplay-zone=ngplus`: derrotas.
- `--autoplay-zone=jungla` con un compañero: los grupos repuestos (`Grupo repuesto`), y el tiempo hasta el Jaguar no sube.
- Fotogramas: el portal del Ala en Villaclaro, el fuego de la mina, del campamento del castillo y de la Caravana, la Olla del castillo y el Coleccionista en el refugio.
