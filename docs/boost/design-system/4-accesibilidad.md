# Accesibilidad

## Contraste

Todo texto llega al menos a 4,5:1 sobre su fondo en el tema `juego`, y a 7:1 en `alto-contraste` (4,5:1 para el texto de las barras, que es grande y grueso). Pares comprobados en `juego`:

| Texto | Sobre | Contraste |
| --- | --- | --- |
| `text-primary` | `surface-window-solid` | 19,5:1 |
| `text-secondary` | `surface-window-solid` | 10:1 |
| `text-disabled` | `surface-window-solid` | 5,1:1 |
| `text-accent` | `surface-window-solid` | 14,2:1 |
| `text-negative` | `surface-window-solid` | 7,2:1 |
| blanco | `stat-hp` / `stat-mp` / `stat-exp` | 5,4 / 4,9 / 5,4:1 |
| blanco | insignias | 6,1–7,1:1 |
| cursor `border-focus` | `surface-selected` | 12,8:1 |

Cambio respecto al juego actual: el verde de la barra de EXP pasa de #2e9e42 (3,5:1 con blanco, solo legible gracias al contorno) a `green-600` #237a33 (5,4:1).

## Tema «Alto contraste»

Una opción nueva propuesta para Opciones, junto a «Texto grande»:
- ventanas opacas;
- texto secundario y desactivado más claros;
- separadores visibles (7:1);
- insignias más oscuras.

Usa los mismos tokens, así que no hace falta tocar ninguna pantalla.

## Nunca solo color

- Estados: insignia con la palabra.
- Comparaciones: ▲/▼ con su signo.
- Marcas del mapa: leyenda en la página Mapa.
- PV críticos: texto naranja y latido.
- Avisos: palabra de tono («Misión cumplida», «Guardado»).

## Otras opciones que ya existen y se mantienen

Texto grande (×1,25), velocidad del texto, velocidad del combate, temblor de cámara y teclas reasignables.
