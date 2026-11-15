# Accesibilidad

## Contraste

Todo texto llega al menos a 4,5:1 sobre su fondo en el tema normal y a 7:1 en el de alto contraste (4,5:1 para el texto sobre barras, que es grande y grueso). Cada juego comprueba en sus guías los pares de sus valores: `text-primary`, `text-secondary`, `text-disabled` y `text-accent` sobre `surface-window-solid`, el cursor `border-focus` sobre `surface-selected` y `text-on-fill` sobre sus barras e insignias.

## Tema de alto contraste

- Ventanas opacas.
- Texto secundario y desactivado más claros.
- Separadores visibles.
- Rellenos de color más oscuros, para que el texto encima pase 7:1.

Usa los mismos tokens con otros valores, así que no hace falta tocar ninguna pantalla: `UiTokens.color()` devuelve el del tema que esté puesto.

## Nunca solo color

Lo que dice un color también lo dice una palabra, una forma o un signo: un estado lleva su nombre, una comparación su ▲/▼ y su signo, un aviso su palabra de tono.

## Tamaño

El juego puede escalar el lienzo entero (texto grande, móvil); los tokens no cambian.
