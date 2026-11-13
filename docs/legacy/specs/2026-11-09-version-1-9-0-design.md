# Versión 1.9.0: ambiente y depuración

Fecha: 2026-11-09. Parte de la 1.8.0. Cubre M-36 (sonido de ambiente y partículas) y M-38 (menú de depuración). M-37 (soporte de mando) queda descartado.

## Objetivo

Que cada zona suene y se mueva un poco más, y una herramienta de desarrollo para saltar a cualquier punto sin la partida automática. El guardado no cambia (sigue en la 13) y las opciones tampoco.

## M-36. Sonido de ambiente y partículas

### Sonido

- Cada zona tiene un ambiente propio, sintetizado en código como la música y los efectos (nada de archivos de audio): `AmbientLibrary` (estática, como `SfxLibrary`) con `build(id)` en caché.

| Ambiente | Zonas | Qué suena |
|---|---|---|
| `meadow` | pradera | Brisa suave (ruido filtrado) y trinos cortos al azar cada 2-6 s |
| `forest` | bosque | Viento entre hojas, más grave, y algún pájaro |
| `mine` | mina | Goteo al azar cada 1-4 s, con eco, sobre un rumor grave |
| `castle` | castillo | Viento que silba, a ráfagas |

- El fondo continuo es un `AudioStreamWAV` en bucle; los sonidos sueltos (trinos, gotas) se lanzan al azar desde `AudioDirector`.
- `ZoneData.ambient` dice el ambiente de cada zona.
- `AudioDirector` gana un reproductor de ambiente: `play_ambient(id)`, `stop_ambient()`, cruce de 1 s al cambiar de zona, silencio en combate y en las escenas que cambian la música, y vuelve al acabar.
- Volumen: el de los efectos por 0,5. No hay control aparte.
- En la partida automática, silencio y la línea `Ambiente: <id>`; en `--headless` y `--write-movie` no se reproduce (como la música).

### Partículas

- `CPUParticles3D` (funciona igual en Compatibility y en la web), alrededor del héroe, en una caja de unos 30 × 20 m que lo sigue.

| Zona | Partículas |
|---|---|
| Pradera | Polen y semillas de diente de león flotando, blancas y amarillas |
| Bosque | Hojas que caen despacio, verdes y ocres |
| Mina | Motas de polvo que brillan cerca del farol |
| Castillo | Copos de niebla violeta que flotan |

- `ZoneData.particles` dice cuáles.
- Con calidad "Baja" no hay partículas. En el móvil con calidad alta, la mitad de cantidad.
- No hay partículas en combate ni en el título.

## M-38. Menú de depuración

Solo para desarrollo. No se ve nunca en una partida normal ni en la web publicada.

- Se activa con `--debug` en la línea de comandos (`OS.get_cmdline_user_args()`), nunca de otra forma. En la web no hay forma de pasarlo.
- Con `--debug`, F1 en el mapa abre un panel por encima de todo (pausa el árbol, como la pausa). Es un `Control` nuevo, `DebugPanel`, con botones normales.
- Lo que hace:
  - **Ir a:** cada zona de `ZoneData.IDS` y su entrada.
  - **Nivel:** −1 / +1 (de 1 a 20, con los hechizos de ese nivel, `Leveling.sync_skills()`).
  - **Oro:** +100 / +1000.
  - **Objetos:** +1 de cada objeto de `Inventory.IDS`.
  - **Curar** todo.
  - **Monstruos:** activar o quitar los grupos del mapa (1.7.0).
  - **Jefes:** marcar vencido cada jefe (pone su bandera y su objeto clave).
  - **Misión de la aldea:** pasar a la etapa siguiente.
  - **Guardar** en la ranura en curso.
- Imprime cada acción en la salida (`Depuración: ...`).
- La partida automática no lo usa. `--autoplay-zone` sigue siendo la forma de probar desde un punto fijo.

## Opciones

- `GameOptions` no gana nada para el ambiente (sigue el volumen de efectos).

## Verificación

- `--check-only` e `--import` (clases nuevas `AmbientLibrary` y `DebugPanel`).
- Escuchar cada ambiente en una partida normal con sonido (pendiente para el usuario: si suena bien).
- Fotogramas de las partículas de cada zona.
- `--debug`: recorrer cada botón del panel y leer la salida.
- Partida automática completa, viaje de ida y vuelta del guardado, exportación web.

## Fuera de esta versión

- Soporte de mando (M-37): descartado por el usuario.
- Partículas en combate.
