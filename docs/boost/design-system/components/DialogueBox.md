Caja de diálogo: abajo en el centro, el nombre de quien habla en dorado y su frase escribiéndose letra a letra.

## Cuándo usarla
Conversaciones, escenas y mensajes de objeto encontrado. El narrador no lleva nombre.

## Qué aporta quien la usa
Quién habla ("" para el narrador) y la lista de frases. Cada una avanza con Intro, Espacio o un toque.

## Especificación
- Una Window tan ancha como su frase más larga, hasta `window-w-max`.
- Nombre en `title-s` / `text-accent`; frase en `body` / `text-primary`.
- Indicador de «sigue» al terminar de escribirse: un triángulo `border-focus` abajo a la derecha que parpadea. Así se sabe cuándo se puede avanzar.
- Velocidad de escritura según la opción del jugador (0,05 / 0,025 / 0,008 s por letra).
