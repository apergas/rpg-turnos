Carta del bestiario: el retrato de un enemigo con su nombre debajo, en una cuadrícula por familia.

## Cuándo usarla
La página Bestiario del menú de pausa, una carta por enemigo de cada familia.

## Qué aporta quien la usa
El enemigo y su estado: no visto, visto o vencido.

## Especificación
- Tamaño: `CARD_SIDE` 96 px de lado (84 px en el móvil); nombre en `NOTE` centrado, con el mismo ancho.
- **No visto**: sin retrato; «??» en `title-m` / `text-disabled` y el mismo «??» como nombre. No se puede pulsar ni enfocar.
- **Visto**: retrato desaturado y aclarado (se desatura `opacity-portrait-desaturate` y se mezcla con el color `portrait-seen`; los sprites oscuros quedan más claros, nunca más oscuros) y el nombre en `NOTE`. Se puede pulsar y abre su ficha.
- **Vencido**: el retrato tal cual, sin tinte, y el nombre en `NOTE`. Se puede pulsar.
- El premio de la familia solo llega cuando todas sus cartas están vencidas: ver una no basta. El título de la familia cuenta los vencidos («Plantas 3/4»).
