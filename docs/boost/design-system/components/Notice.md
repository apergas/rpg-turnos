Aviso: una ventana breve arriba en el centro que confirma algo y se va sola.

## Cuándo usarlo
«Partida guardada.», «Misión cumplida: …», «Has vuelto a Villaclaro.», «El incienso se ha consumido.». Nunca para algo que el jugador deba decidir (para eso, ChoiceWindow).

## Qué aporta quien lo usa
El texto y su tono: info, éxito o peligro.

## Especificación
- Window con ancho máximo `window-w-xl`, centrada a `space-6` del borde superior.
- Una palabra de tono en `label` con su color (`text-info`, `text-positive`, `text-danger`) y el texto en `body`. El tono siempre se dice con palabras, no solo con color.
- Aparece con un fundido de 0,2 s, dura 4 s y se va con otro fundido.
- Uno a la vez; uno nuevo sustituye al anterior.
