Fila de opción: el nombre de un ajuste a la izquierda y su control a la derecha.

## Cuándo usarla
Una página de opciones: volumen (deslizador), velocidades (selector), sí/no (selector de dos).

## Qué aporta quien la usa
El nombre, el tipo de control y su valor.

## Especificación
- Nombre en `body`; el control alineado a la derecha.
- Deslizador: pista `surface-track` de 8 px, parte llena en `border-focus`, valor en `caption` («70 %»), pasos de 10.
- Selector: opciones en `caption`; la activa en `surface-window-solid` sobre `border-focus`. ← → cambian el valor cuando la fila está elegida.
- Se aplica al momento; no hay botón «Aceptar».

## En Godot
El selector es un `Button` con la variación `SELECTOR`; el cursor ▶ va en la fila que lo contiene.
