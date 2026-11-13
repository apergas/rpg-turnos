Barra de dato: PV, PM o EXP como barra con su texto encima («PV 42/42»).

## Cuándo usarla
Siempre que se muestre PV, PM o EXP con su máximo: ventana de estado, combate, Estado, posada.

## Qué aporta quien la usa
El tipo, el valor y el máximo.

## Especificación
- `bar-width` × `bar-height`; parte vacía `surface-track`.
- Relleno: PV `stat-hp`, PM `stat-mp`, EXP `stat-exp`. Es la regla de color del héroe: nunca se cambian ni se reutilizan.
- Texto `label` en `text-on-fill` con contorno `outline-s`.
- PV críticos (menos del 25 %): el texto pasa a `text-danger` y la barra late suave (1 s). Así el peligro se ve sin leer números.
- El oro no es barra: «50 G» en `text-money`.
