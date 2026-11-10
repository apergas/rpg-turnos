# Versión 1.7.0: monstruos a la vista

Fecha: 2026-11-09. Parte de la 1.6.0. Cubre M-33 (antes I-01).

## Objetivo

Quitar los encuentros aleatorios. Los monstruos están en el mapa, a la vista, y el combate empieza cuando el héroe toca a uno. Entre ellos queda sitio para cruzar una zona sin pelear. Es el cambio más grande desde la 1.0.0: toca el ritmo de EXP y oro, la partida automática y las dos clases de encuentros.

El guardado pasa a la **versión 12** (solo por los PV del Slime de Metal).

## Reglas

### Los grupos del mapa

- Cada zona con `formations` tiene un número fijo de **grupos** en el mapa (`ZoneData.monster_count`). Cada grupo es una formación de `zone.formations`, elegida al construir el mapa con la semilla de la zona y el reloj (no siempre la misma).
- Del grupo solo se ve el primer enemigo, con su figura de `BattleActor` a escala de mapa (la misma que usa `World` para el jefe). Al tocarlo empiezan todos los enemigos del grupo.
- Cerca del inicio de la zona (`start_pos`, `start_radius`) los grupos salen de `start_formations`, como hoy los encuentros.
- Números de partida, que el plan ajusta con la partida automática para que el juego dure lo de hoy (Nv 18-19, 0:57-1:16 en Normal):

| Zona | Grupos |
|---|---|
| Pradera | 10 |
| Bosque | 12 |
| Cada planta de la mina | 7 |
| Patio del castillo | 8 |
| Salón del trono | 5 |

### Dónde se ponen

- Solo donde hoy hay encuentros: sobre hierba en la pradera y el bosque, fuera del sendero, de los discos seguros, del pueblo (`village_radius`), de las salidas, de los cofres, de los pozos y del jefe. Así el sendero queda siempre libre para cruzar.
- En la mina y el castillo, solo en celdas de sala: una celda de suelo cuyas ocho vecinas también son suelo. Los pasillos de una celda de ancho quedan siempre libres. Nunca en las salas de las escaleras (`near_stairs`) ni en el campamento.
- Entre dos grupos, al menos 8 m.

### Movimiento

`Combatant` gana `map_roam` (metros; 0 = quieto) y `map_speed` (m/s):

| Enemigo | Movimiento |
|---|---|
| Setas, plantas, hongos | Quietos |
| Golems | Quietos, se balancean |
| Slimes | Saltan en 1,5 m alrededor de su sitio |
| Lobo, Araña, Duende | Andan en 2 m |
| Murciélagos, Espectros | Flotan en 2,5 m |
| Esqueletos | Andan en 2 m |

- Andan de un punto al azar a otro dentro de su radio, paran un poco y siguen. No persiguen al héroe.
- La lógica de dónde van es pura (`MonsterRoam`, `RefCounted`: siguiente punto, si ha llegado, con su `rng`). `World` solo mueve las figuras. En las mazmorras el punto debe caer en suelo.

### El contacto

- El combate empieza cuando el héroe está a menos de 1,3 m de un grupo. Es la señal que hoy da un encuentro aleatorio (`encounter_triggered`), ahora con la formación del grupo.
- **Victoria:** el grupo desaparece del mapa hasta que se cambie de zona.
- **Huida:** el grupo se queda, pero no puede volver a empezar un combate hasta que el héroe se aleje 4 m (la misma regla que el jefe tras su combate, `BOSS_REARM_RADIUS`). Mientras, se ve medio transparente.
- **Derrota:** el héroe vuelve al pueblo como hoy.
- Al volver de un combate hay 1,5 s sin contactos, para que otro grupo cercano no salte encima.

### Reaparición

Todos los grupos vuelven al construir otra vez el mapa: al cambiar de zona, al volver por el portal o tras una derrota. No se guarda qué grupos estaban vencidos.

### Lo que pasa con M-12 (encuentros a la mitad e Incienso)

La idea de M-12 se mantiene con otra forma:

- **Monstruos que se apartan:** si el héroe supera en `EncounterMeter.LEVEL_GAP` (4) niveles el `exit_level` de la zona, los grupos que se mueven huyen de él cuando está a menos de 5 m, a su velocidad, sin salirse de su radio más que el doble. Los quietos se quedan. Se pueden seguir tocando.
- **Incienso:** mientras dura (los mismos 200 m), tocar un grupo no empieza combate y todos los grupos se ven medio transparentes. El texto del objeto pasa a "Los monstruos no te atacan durante 200 m."

### El Slime de Metal

- Mientras su misión está en curso (`wanted_enemies()`), cada planta de la mina tiene un Slime de Metal además de sus grupos. No tiene radio: recorre toda la planta. Va de celda en celda (un camino por las celdas de suelo, puro) hacia una celda al azar; anda a 3 m/s y, si el héroe está a menos de 6 m, corre a 4,5 m/s alejándose (el héroe anda a 5 m/s: se le puede alcanzar acorralándolo).
- **PV que se conservan:** si el Slime de Metal huye del combate (`help`/huida suya) o el héroe huye, sus PV se guardan en `GameState.metal_slime_hp`. El próximo combate contra él empieza con esos PV. Al vencerlo, vuelve a 0 (sin dato).
- Con la misión ya cumplida (`hunted_enemies()`), cada planta tiene un 5 % de traer uno al construirse (la regla de M-02). Ese también conserva sus PV.
- Contra el Slime de Metal no hay ataque sorpresa (1.5.0).

### Lo que desaparece

- Los encuentros al andar por la hierba: `EncounterMeter` deja de tirar dados. Se queda solo `level_rate()` y `LEVEL_GAP`, o la regla pasa a otra clase si se queda vacía.
- `encounter_grace` y `encounter_chance` de `ZoneData` dejan de usarse y se quitan de los `.tres`.
- `EncounterTable.pick()` pasa a elegir la formación de un grupo al construir el mapa (`pick_group(zone, pos, rng)`); `rare_chance()` se queda para el Slime de Metal.

### Jefes

Sin cambios: el jefe sigue en su sitio y su combate empieza igual.

## Partida automática

- Anda su ruta como hoy. Si un grupo está a menos de `AUTOPLAY_HUNT_RADIUS` (12 m) del héroe y el héroe está por debajo de `zone.autoplay_boss_level`, deja la ruta, va a por él y luego vuelve al punto de la ruta más cercano.
- Ya en el nivel del jefe, sigue la ruta sin buscar grupos (puede tocar alguno sin querer, y pelea).
- El reparto de huidas y defensas de `BattleScene` en autoplay no cambia.
- Debe seguir completando la partida (`Juego completado: ...`) con cifras parecidas a las de hoy. Si salen muy distintas, se ajusta `monster_count`.
- Imprime `Grupos: n` al entrar en una zona y `Grupo vencido (quedan n)` tras cada victoria.

## Rendimiento

- Las figuras de los grupos son `BattleActor` normales: 10-12 a la vez en el mapa. En el móvil con calidad baja, deben seguir yendo los 30 fps; si no, los grupos lejanos (más de 30 m) dejan de animarse.
- Los grupos se mueven en `_physics_process` del `World`, sin física propia: no chocan con nada, solo se quedan en su radio.

## Guardado (versión 12)

- `metal_slime_hp`: entero, 0 si no hay dato. En un guardado anterior, 0. Un valor negativo o mayor que los PV máximos del Slime de Metal no es válido.
- `Incienso` sigue sin guardarse (como hoy `repel_m`).

## Verificación

- `--check-only` de todo e `--import` (clase nueva `MonsterRoam`).
- Fotogramas de la pradera, el bosque, una planta de la mina y el patio con los grupos, en escritorio y en el móvil.
- Script del scratchpad para `MonsterRoam` y el camino del Slime de Metal (una planta de la mina, imprime las celdas).
- Partida automática completa con las cifras del final, y una con `--autoplay-zone=mina_1` con la misión del Slime de Metal en curso: debe salir, huir y conservar sus PV (se ve en la salida).
- Viaje de ida y vuelta del guardado, exportación web.
- Pendiente para el usuario: jugar a mano una zona y decir si se puede cruzar sin pelear.

## Fuera de esta versión

- Monstruos que persiguen al héroe: la idea pedía que no.
- Guardar qué grupos estaban vencidos: reaparecen al cambiar de zona, como pide la idea.
