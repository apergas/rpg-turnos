# Interacción

## Selección y foco

- La fila elegida lleva siempre fondo `surface-selected` y el cursor ▶ en `border-focus`, igual con teclado, ratón o dedo.
- El ratón o el dedo mueven la selección al pasar o tocar; el teclado, con ↑/↓.
- Las filas desactivadas salen de la cadena de foco: el cursor nunca se queda en una.

## Entrada

- **Teclado**: ↑/↓ mueven; Intro o Espacio aceptan; Esc vuelve atrás. Un juego puede añadir más teclas para lo mismo.
- **Ratón y dedo**: tocar una fila la elige; tocar fuera de la ventana es «volver».
- Al abrir un menú, las elecciones se ignoran 0,3 s, para que una pulsación de antes no elija nada, y la fila parpadea una vez cuando ya acepta órdenes.

## Móvil

- Toda fila mide al menos `touch-target` × `touch-min-width`.
- Los diseños deben caber en un móvil apaisado (740 × 360).

## Estados de un control

| Estado | Aspecto |
| --- | --- |
| Normal | `text-primary` sin fondo |
| Elegido | fondo `surface-selected` + cursor `border-focus` |
| Pulsado | texto `text-accent` durante el sonido de aceptar |
| Desactivado | `text-disabled` + motivo en `caption` |

## Sonido

- Mover el cursor suena, salvo cuando el código mueve el foco por su cuenta.
- Aceptar y cancelar tienen su propio sonido.
