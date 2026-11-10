# Versión 1.4.1: retoques del combate

Fecha: 2026-11-09. Parte de `develop` en la 1.4.0 publicada. Cubre M-26 y M-27 del documento maestro (antes ideas I-03 e I-04).

## Objetivo

Dos retoques pequeños pedidos por el usuario que limpian las ventanas del combate. No hay datos nuevos ni cambia el guardado (sigue en la versión 10).

## M-26. Hechizos sin descripción en combate

**Regla:** la descripción de un hechizo (`Skill.description`) solo se ve en la página Estado del menú de pausa.

- **Combate, página `SPELLS` de `BattleHud`:** cada fila dice el nombre y los PM, por ejemplo "Curar  4 PM". Desaparece la descripción que añadió M-04 (1.1.1).
- **Pausa, página Hechizos** (donde se lanzan las curas fuera de combate): igual, nombre y PM, sin descripción.
- **Pausa, página Estado:** sin cambios. Sigue listando cada hechizo con sus PM y lo que hace.
- **Filas en gris:** siguen diciendo su motivo ("Faltan PM", "Silencio", "PV al máximo"). El motivo no es una descripción y se queda.
- Los objetos no cambian: sus filas siguen diciendo qué hacen.

El ancho de las ventanas se calcula con el texto, así que la ventana de hechizos queda más estrecha. Debe seguir cabiendo en el móvil (1096 × 533 virtual y 925 × 450 con "Textos grandes"), con botones de dedo.

## M-27. Enemigos iguales sin letra

**Regla:** dos enemigos iguales en un combate se llaman igual: "Slime" y "Slime".

- Se quita la letra que añade `battle_scene.gd` al preparar el combate (`display_name += " A"` / `" B"`).
- Los mensajes ("El Slime recibe 5 de daño") no dicen a cuál le ha tocado. Lo distinguen la flecha amarilla, el brillo del enemigo apuntado y su barra de vida.
- "¿A quién?" muestra el mismo nombre sobre las dos barras; la flecha marca cuál se elige.
- Un enemigo que pide ayuda y trae otro igual (los slimes del Rey Slime, por ejemplo) tampoco lleva letra.
- Hay que comprobar que nada del código usa el nombre para distinguir a los enemigos (el bestiario, las misiones y los objetivos usan el `id`; los mensajes de la partida automática pueden repetir el nombre sin problema).

## Verificación

- `--check-only` de los scripts tocados.
- El combate de prueba (`battle_scene.tscn`) contra dos enemigos iguales (cambiando el combate de prueba solo en un script del scratchpad, o con la partida automática de la pradera, donde salen parejas de slimes): nombres sin letra, flecha y brillo correctos.
- Fotogramas de la página Hechizos en combate y en la pausa, en escritorio y con `--resolution 740x360 -- --touch`, también con textos grandes.
- Partida automática completa sin errores y viaje de ida y vuelta del guardado.

## Fuera de esta versión

Nada.
