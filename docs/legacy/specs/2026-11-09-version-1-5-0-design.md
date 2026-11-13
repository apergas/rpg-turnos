# Versión 1.5.0: sorpresas y objetos de combate

Fecha: 2026-11-09. Parte de la 1.4.1. Cubre M-28, M-29 y M-30 del documento maestro.

## Objetivo

Dar algo más de variedad a los combates con reglas que ya existen: a veces un bando empieza con ventaja, y dos objetos nuevos protegen de la derrota y del sueño. El guardado no cambia de versión: los objetos nuevos son entradas más del inventario, que ya se guarda como `id → cantidad`.

## M-28. Ataque sorpresa

**Regla:** al empezar un combate normal se tira una vez:

| Resultado | Probabilidad | Mensaje | Efecto |
|---|---|---|---|
| Ventaja del héroe | 1/16 (6,25 %) | "¡Pillas desprevenidos a los monstruos!" (uno solo: "¡Pillas desprevenido al Lobo!") | La primera ronda solo actúan el héroe y su criatura. Los enemigos no hacen nada |
| Ventaja de los monstruos | 1/16 (6,25 %) | "¡Los monstruos te atacan por sorpresa!" (uno solo: "¡El Lobo te ataca por sorpresa!") | Antes de que se abra el menú, los enemigos juegan una ronda entera. El héroe y su criatura no actúan en ella |
| Nada | el resto | — | Como hoy |

- Nunca contra un jefe (`has_boss()`), ni contra el Eco de la Niebla, ni en el combate del Slime de Metal cuando trae PV de antes (ver 1.7.0; en esta versión no existe todavía).
- La ronda de sorpresa es una ronda normal: el veneno y el sueño cuentan al final, como siempre, y un enemigo que cae en ella da su EXP al acabar el combate.
- Huir sigue siendo posible en la primera ronda normal tras una sorpresa de los monstruos.
- La regla va en `BattleEngine` (puro): una tirada al empezar con su `rng`, `ambush` (`NONE` / `HERO` / `ENEMY`), y la ronda de sorpresa como una variante de `resolve_round()` que deja fuera a un bando. `BattleScene` dice el mensaje después del de aparición y antes del primer menú.
- La partida automática no cambia sus decisiones; solo debe imprimir el mensaje.
- En la línea de `--autoplay` se ve "Sorpresa: héroe" o "Sorpresa: monstruos" para poder contar cuántas salen.

## M-29. Pluma de fénix

**Regla:** si el héroe cae en combate y lleva una Pluma de fénix, se gasta sola y el héroe se levanta con la mitad de sus PV máximos (redondeando hacia arriba). El combate sigue.

- Objeto nuevo en `Inventory.ITEMS`: `pluma_fenix`, "Pluma de fénix" ("una"), efecto nuevo `revive`, valor 0,5, precio 150 G, ni de combate ni de campo: no se puede usar a mano. Su texto: "Si caes en combate, te levanta con la mitad de PV."
- Solo una por combate: si el héroe vuelve a caer en el mismo combate, pierde, aunque lleve más.
- Mensaje: "¡La Pluma de fénix arde! {nombre} se levanta." con el efecto de curar.
- No revive a la criatura aliada.
- Se vende en las tiendas del bosque, de la mina y del castillo (no en Villaclaro). Se puede vender a mitad de precio como los demás objetos.
- En la página Objetos de la pausa sale en gris con el motivo "Se usa sola".
- En el combate, en la página Objetos, sale en gris con el mismo motivo.
- La partida automática no la compra (como el Incienso); así el ritmo medido de la partida no cambia.
- Un evento nuevo de `BattleEvent` (`revive`) para que `BattleScene` lo reproduzca.

## M-30. Despertador

**Regla:** usado en combate, el héroe ya no se puede dormir hasta el final de ese combate.

- Objeto nuevo `despertador`, "Despertador" ("un"), efecto nuevo `wake_guard`, precio 12 G, solo en combate. Texto: "Evita el sueño hasta el final del combate."
- Si el héroe ya está dormido no puede elegir nada, así que no puede usarlo: el Despertador previene, no cura.
- Un hechizo de sueño contra un héroe protegido falla con el mensaje "{nombre} no se duerme." (como hoy pasa con una inmunidad del equipo, si existe ese mensaje; si no, se añade).
- Usarlo con la protección ya puesta sale en gris con "Ya estás protegido".
- Se vende en todas las tiendas. La partida automática no lo compra.
- La protección es estado del combate, no del héroe: se borra al acabar el combate como los estados.

## Interfaz

- Las filas de los objetos nuevos siguen la regla de siempre: nombre, cantidad, qué hacen y, si no se pueden usar, el motivo en gris.
- Nada nuevo en el móvil más allá de que las filas quepan.

## Verificación

- `--check-only` de los scripts tocados.
- Un script del scratchpad que cree un `BattleEngine` con una semilla fija y compruebe a mano (imprimiendo) las tres ramas de la sorpresa, la Pluma de fénix (un héroe con 1 PV y una pluma) y el Despertador contra las Esporas.
- Partida automática completa: debe imprimir algunas líneas "Sorpresa:" y acabar como antes (`Juego completado`).
- Fotogramas de la tienda del bosque y de la página Objetos con los dos objetos, en escritorio y en el móvil.

## Fuera de esta versión

- Ataque sorpresa en función de la velocidad: se queda fijo en 1/16 para que sea fácil de entender.
- Una Pluma que se use a mano fuera de combate: no hay forma de caer fuera de combate.
