# Interacción

## Selección y foco

- La fila elegida lleva siempre fondo `surface-selected` y el cursor ▶ en `border-focus`.
- Antes, en escritorio se veía un recuadro gris del motor y en móvil no se veía nada. Ahora es igual en todas partes.
- El ratón o el dedo mueven la selección al pasar o tocar; el teclado, con ↑/↓.
- Las filas desactivadas salen de la cadena de foco.

## Entrada

- **Teclado**: ↑/↓ (o W/S) mueven; Intro, Espacio o E aceptan; Esc, Q, Retroceso o X vuelven atrás.
- **Ratón y dedo**: tocar una fila la elige; tocar fuera de la ventana es «volver».
- Al abrir un menú, las elecciones se ignoran 0,3 s y la fila parpadea una vez cuando ya acepta órdenes.
- En combate: A/D o ←/→ apuntan; un toque en un enemigo apunta y otro confirma.

## Móvil

- Toda fila mide al menos `touch-target` × `touch-min-width` (56 × 120).
- La acción cercana es un botón grande (InteractionPrompt).
- Los diseños deben caber en 740 × 360.

## Estados de un control

| Estado | Aspecto |
| --- | --- |
| Normal | `text-primary` sin fondo |
| Elegido | fondo `surface-selected` + cursor `border-focus` |
| Pulsado | texto `text-accent` durante el sonido de aceptar |
| Desactivado | `text-disabled` + motivo en `caption` |

## Sonido

- Mover el cursor: sonido de cursor (salvo cuando el código mueve el foco por su cuenta).
- Aceptar y cancelar tienen su propio sonido.
- Abrir un diálogo: sonido de diálogo.
