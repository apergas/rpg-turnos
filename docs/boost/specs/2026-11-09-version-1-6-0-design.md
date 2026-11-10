# Versión 1.6.0: familias del bestiario

Fecha: 2026-11-09. Parte de la 1.5.0. Cubre M-31 (variantes de color) y M-32 (antes I-02, grupos del bestiario con premio).

## Objetivo

Que completar el bestiario tenga un premio. El álbum se ordena por familias, cinco enemigos nuevos (variantes de color de figuras que ya existen) llenan las familias cortas y cada familia completa da una pieza de equipo única. Para poder llevar dos accesorios a la vez, la casilla de Accesorio se parte en Anillo y Amuleto.

El guardado pasa a la **versión 11**.

## M-31. Cinco enemigos nuevos

Todos reutilizan una figura de `BattleActor` con otro color (y, si hace falta, otra escala). Cada uno tiene su `data/enemies/<id>.tres`, su retrato en `assets/bestiary/<id>.png` (con `scripts/tools/bestiary_shots.gd`, sin `--headless`) y su sitio en las formaciones.

| id | Nombre | Figura | Zona | Familia | Rasgo |
|---|---|---|---|---|---|
| `slime_rojo` | Slime rojo | `SLIME`, rojo | bosque | Criaturas mágicas | Un slime de la zona 2: más PV y ATK, débil al rayo (el héroe no tiene hielo) |
| `seta_venenosa` | Seta venenosa | `MUSHROOM`, sombrero morado | bosque | Plantas | Su golpe envenena (`attack_status` poison, 25 %) |
| `hongo_cueva` | Hongo de cueva | `MUSHROOM`, azul pálido, ×1,2 | mina (las tres plantas) | Plantas | Esporas de sueño más fuertes; débil al fuego |
| `murcielago_cripta` | Murciélago de la cripta | `BAT`, rojo oscuro | castillo (patio y trono) | Bestias | Rápido; débil al rayo |
| `espectro_escarcha` | Espectro de escarcha | `SPECTER`, azul hielo | castillo (patio y trono) | Muertos vivientes | Hechizo de hielo a todos; resiste el hielo, débil al fuego |

- Sus números se ajustan a los enemigos de su zona: a medio camino entre el más débil y el más fuerte. El plan los fija con los demás `.tres` delante, y la partida automática completa debe seguir terminando en el mismo nivel y tiempo, más o menos (Nv 18-19, 0:57-1:16 en Normal).
- Entran en `zone.formations` como una formación más, sin quitar ninguna. No entran en `start_formations`: el principio de cada zona no se vuelve más duro.
- Las bajas cuentan para el bestiario como cualquier enemigo.

## M-32. Familias y premios

### Las familias

`BestiaryPage.ORDER` pasa a ser una lista de familias, cada una con sus enemigos en orden:

| Familia | Enemigos | Premio |
|---|---|---|
| Criaturas mágicas | Slime, Slime rojo, Duende, Golem de barro, Slime de Metal | Anillo de cristal |
| Plantas | Seta saltarina, Planta carnívora, Seta venenosa, Hongo de cueva | Anillo de savia |
| Bestias | Murciélago, Lobo, Araña, Murciélago de la cripta | Amuleto de colmillo |
| Muertos vivientes | Espectro, Espectro de escarcha, Esqueleto guerrero, Esqueleto pícaro, Esqueleto mago | Amuleto de hueso |
| Jefes | Rey Slime, Bruja del bosque, Golem de piedra, Señor de la Niebla | Espada del alba |

22 enemigos en total. El Eco de la Niebla sigue fuera del bestiario.

### Cuándo se completa

- Una familia se completa cuando **todos sus enemigos están vencidos** (`GameState.defeated_enemies`), no solo vistos.
- Se comprueba después de cada combate ganado y después de cargar una partida. La regla es pura: `Bestiary` (clase nueva, `RefCounted`) con `FAMILIES`, `family_of(id)`, `is_complete(state, family)` y `new_rewards(state)` (familias completas cuyo premio aún no se ha dado).
- El premio se da una sola vez. Se apunta con la bandera del mundo `familia_<id>` (como `eco_niebla`), así que no hace falta otro campo en el guardado.
- Al darlo se abre la ventana de diálogo: "¡Has completado la familia Plantas del bestiario! Recibes un Anillo de savia." En la partida automática avanza sola y se imprime.
- La pieza se pone en el acto si su casilla está vacía; si no, va a la bolsa (`QuestRewards`, como los premios de misión).
- Una partida terminada que se carga con los cuatro jefes vencidos recibe la Espada del alba en cuanto se carga.

### Los premios

| id | Nombre | Casilla | Efecto |
|---|---|---|---|
| `anillo_cristal` | Anillo de cristal | Anillo | VEL +2 · ATK +2 |
| `anillo_savia` | Anillo de savia | Anillo | Inmune al sueño |
| `amuleto_colmillo` | Amuleto de colmillo | Amuleto | VEL +1 · ATK +4 |
| `amuleto_hueso` | Amuleto de hueso | Amuleto | Inmune al silencio |
| `espada_alba` | Espada del alba | Arma | ATK +34 (la de platino da +28) |

Todos son de la zona −1, precio 0, "No se vende", como el Yelmo de bruma. El ATK de un anillo o un amuleto usa la clave `attack` que ya tiene el Yelmo (`Equipment.extra_attack()`); la inmunidad, la clave `immune`. La inmunidad al sueño y al silencio debe funcionar en `BattleEngine` como la del veneno: el estado no se pone y sale el mensaje de que no le afecta.

La Espada del alba usa la malla de una espada de `Knight.glb` con un tinte dorado claro.

### Anillo y Amuleto

- `Equipment.ACCESSORY` desaparece. Entran `RING` ("Anillo") y `AMULET` ("Amuleto") en `SLOTS`, en ese orden, al final.
- El Anillo antiveneno pasa a `RING`; el Amuleto de velocidad, a `AMULET`.
- `Loadout.speed_bonus()` y `immunities()` suman las dos casillas.
- La página Equipo de la pausa tiene seis casillas. Debe caber en el móvil: ya está en un `ScrollBox`.
- El combate de la página Estado lista las dos.

### El bestiario en la pausa

- El álbum enseña cada familia con su título y su cuenta ("Plantas 3/4"), y debajo sus cromos. Con la familia completa, el título dice también el premio ("Plantas 4/4 · Anillo de savia").
- La ficha de un enemigo gana una línea: "Familia: Plantas".
- La fila de la ventana del héroe dice "Bestiario n/22".
- El apartado "Colección" del Diario dice "Bestiario n/22" y una línea nueva "Familias n/5".
- En el móvil, las familias van en `TOUCH_HERO_COLUMNS` columnas como hoy.

## Guardado (versión 11)

- `loadout`: en un guardado anterior a la 11, lo que haya en `accessory` pasa a la casilla que diga su pieza (`Equipment.slot()`); las dos casillas nuevas empiezan vacías si no había nada.
- Las banderas `familia_<id>` se guardan con las demás banderas del mundo.
- Un guardado de la 11 con una pieza en una casilla que no le corresponde no es válido (`is_valid()`).
- `SaveData.summary_line()` no cambia.

## Partida automática

- Compra y se pone lo de siempre. Si recibe un premio de familia y su casilla está vacía, se lo pone (por la regla general de `QuestRewards`).
- Al acabar imprime una línea más: `Familias completas: n/5`.

## Verificación

- `--check-only` de todo lo tocado e `--import` (clase nueva `Bestiary`).
- Retratos nuevos generados y mirados uno a uno.
- Script del scratchpad: un `GameState` con todos los enemigos de una familia vencidos menos uno; vencer al último da el premio una sola vez.
- Cargar un guardado de la versión 10 con el Anillo antiveneno puesto: queda en Anillo. Cargar uno terminado: recibe la Espada del alba.
- Fotogramas del bestiario, de una ficha y de la página Equipo, en escritorio y con `--resolution 740x360 -- --touch` (también con textos grandes).
- Partida automática completa sin errores, viaje de ida y vuelta del guardado, exportación web.

## Fuera de esta versión

- Descripciones escritas de cada enemigo: la ficha sigue con zona, debilidades, resistencias y si está vencido.
- Más familias o premios de oro: el usuario pidió premios que no fueran oro.
