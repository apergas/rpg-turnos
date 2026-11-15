# Accesibilidad en Villaclaro

Las reglas generales (4,5:1 en el tema normal, 7:1 en el de alto contraste, nunca solo color) están en la [accesibilidad del núcleo](../../../addons/design_system/docs/4-accesibilidad.md). Aquí, los pares comprobados con los valores de Villaclaro y lo que hace su tema de alto contraste.

## Contraste

Pares comprobados en `juego`:

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

El verde de la barra de EXP pasó de #2e9e42 (3,5:1 con blanco, solo legible gracias al contorno) a `green-600` #237a33 (5,4:1).

## Tema «Alto contraste»

La opción de Opciones, junto a «Texto grande»: ventanas opacas (`navy-950`), texto secundario y desactivado más claros, separadores visibles (7:1) e insignias más oscuras.

## Nunca solo color

- Estados: insignia con la palabra.
- Comparaciones: ▲/▼ con su signo.
- Marcas del mapa: leyenda en la página Mapa.
- PV críticos: texto naranja y latido.
- Avisos: palabra de tono («Misión cumplida», «Guardado»).

## Otras opciones

Texto grande (×1,25), velocidad del texto, velocidad del combate, temblor de cámara y teclas reasignables.
