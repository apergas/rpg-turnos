Lista de menú: filas de texto dentro de una Window con un cursor dorado ▶ en la fila elegida.

## Cuándo usarla
Toda elección: comandos de combate, menú de pausa, pantalla de título, Objetos, Equipo.

## Qué aporta quien la usa
Las filas (verbos o nombres cortos, solo mayúscula inicial), cuáles están activas y, para las que no, el motivo.

## Especificación
- Filas en `body`, `text-primary`, alto mínimo `row-height` (`touch-target` y `touch-min-width` en móvil).
- Fila elegida: fondo `surface-selected` con `radius-s` y el cursor (triángulo de `cursor-size` en `border-focus`). Es igual con teclado, ratón y dedo: en móvil también se ve dónde estás (antes desaparecía).
- Fila desactivada: `text-disabled` y el motivo en `caption` del mismo color; sale de la cadena de foco.
- Descripción bajo una fila: `caption` en `text-secondary`, ancho `window-w-m`.
- Ancho mínimo `window-w-s` en combate.
- Las elecciones se ignoran 0,3 s al abrir; mover el cursor suena.

## En Godot
Un `Button` plano con el tema aplicado y un `MenuCursor` por ventana (`godot/menu_cursor.gd`).
