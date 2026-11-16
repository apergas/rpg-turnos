# Versión 3.8.0: nivel 60 y la gente de Brumaclara

Fecha: 2026-11-16. Estado: spec. Cubre M-104, M-105 y M-107 del [documento maestro](../documento-maestro.md). Va después de la [3.7.0](2026-11-16-version-3-7-0-design.md). La partida guardada sigue en la **versión 16**. Solo cambia el nivel máximo que da por válido: una partida de nivel 51 a 60 es válida desde la 3.8.0, y las versiones anteriores la rechazan.

## Objetivo

1. **Nivel máximo 60 en la v3 (M-104).** En Brumaclara el héroe puede subir hasta el nivel 60, no hasta el 50.
2. **La gente de Brumaclara se ve distinta (M-105).** Los habitantes de Brumaclara dejan de parecer gente de la Caravana con otra ropa: tienen la piel de la Niebla, capucha, un cristal que brilla y, los que más se ven, algo propio en las manos o los brazos.
3. **El aura del nivel máximo (M-107).** Cuando el héroe llega al nivel 60, lo rodea un aura dorada suave pero que se nota, como la de un guerrero que ha llegado a lo más alto.

## Decisiones tomadas (2026-11-16)

| Tema | Decisión |
|---|---|
| Los topes de la v1 y la v2 | No cambian: 20 en la v1 y 40 en la Caravana |
| A qué nivel acaba la v3 | La carrera del piloto automático (`brumaclara`) debe acabar entre el **Nv 53 y el 55**, con 0 o 1 derrotas. El 60 se alcanza después del final, con más o menos una hora u hora y media más en la Fuente |
| Cómo se ajusta | Más experiencia en la v3: cada enemigo de la v3 da un 30 % más (de 1,25 a 1,35 según lo medido). La tabla de los niveles 51 a 60 no se toca, el oro tampoco. La v3 queda un poco más fácil, y se acepta |
| Hechizos nuevos | Ninguno entre el 51 y el 60 |
| Niebla a los pies de la gente | No: Brumaclara ya tiene niebla baja, y en el móvil cada partícula cuenta |
| A quién no se toca | Albor, el Coleccionista (viene de la Caravana), los compañeros y el gato Ceniza |

## 1. Nivel máximo 60 (M-104)

- `Leveling.MAX_LEVEL` pasa a 60 y `EXP_TABLE` gana diez entradas, del nivel 51 al 60. La tabla sigue la curva de hoy: cada nivel pide un poco más que el anterior. Las diferencias de los últimos niveles son 2100, 2200, 2300, 2400 y 2500, así que el punto de partida sería +2600, +2700… +3500, lo que da 47200, 49900, 52700, 55600, 58600, 61700, 64900, 68200, 71600 y 75100. Esta tabla es la definitiva: no se ajusta.
- **Por qué hace falta más experiencia.** Hoy, al llegar al tope, la experiencia de más se pierde (`Leveling.clamp_exp()`), y el piloto automático deja de buscar combates en la Fuente al llegar al Nv 50. Con solo subir el tope, la carrera `brumaclara` acabaría con unos 47 900 puntos: el Nv 51. Ninguna tabla que siga creciendo llega al 53 con eso.
- **Más experiencia en la v3.** Cada enemigo que solo sale en la v3 da un 30 % más de experiencia (`exp_reward` × 1,3, redondeado): los de la Ciénaga, las Cuevas, las Ruinas y la Fuente, el Slime de bruma que llama a otro y los cuatro jefes (la Garza de légamo, el Coloso de cuarzo, el Vigía de la bruma y el Eco de Albor). El oro no cambia. La v3 queda un poco más fácil, porque se llega a cada jefe con algo más de nivel, y se acepta.
- **El ajuste.** Con el × 1,3 se mide la carrera `brumaclara` del piloto automático hasta «Juego completado (v3)».
  - Debe acabar entre el **Nv 53 y el 55**. Si no, el multiplicador se mueve entre 1,25 y 1,35, nunca la tabla. Solo si con 1,35 sigue por debajo del 53 se sube el nivel desde el que el piloto automático va a por el Eco de Albor (`autoplay_boss_level` de la Fuente, hoy 50).
  - El 60 llega después del final, con más o menos una hora u hora y media más de combates en la Fuente.
  - Las derrotas deben seguir en 0 o 1. Si el héroe llega demasiado fuerte al Eco de Albor no es un fallo, mientras el combate no dure menos de la mitad que hoy.
  - Lo medido se apunta en la skill `villaclaro-autoplay`, como en cada versión.
- **Lo que cambia solo.** `GameState.level_cap()` devuelve `Leveling.MAX_LEVEL` en la parte 3, la validación de la partida (`SaveData`) acepta hasta `MAX_LEVEL` y el panel de depuración sube hasta `MAX_LEVEL`. Hay que revisar que ningún texto, comentario o doc diga «nivel 50» como tope de la v3: el spec de la v3 ya está en `docs/legacy/` y no se toca, pero sí los comentarios de `leveling.gd`, la guía de QA y la skill.
- Las ventanas «Estado» y el Diario muestran la experiencia que falta para el siguiente nivel con `exp_for_next()`, que ya sabe del tope: no cambian.

## 2. La gente de Brumaclara (M-105)

### Lo que ve el jugador

Toda la gente de Brumaclara se reconoce de lejos, y cada uno sigue siendo quien es:

| Figura | Piel | Capucha | Cristal | Lo suyo |
|---|---|---|---|---|
| Orvalla | De bruma | Sí, azul noche (sustituye al moño) | Colgante | Un farol en la mano, con la luz encendida (solo brillo, sin luz que alumbre) |
| Neblí | De bruma | No: sigue con su coleta rubia | Colgante | — |
| Curandera | De bruma | Sí, azul claro (sustituye a la coleta) | Colgante | Un cuenco de agua de bruma en las manos, que brilla un poco |
| Herrero de cristal | De bruma | No | Colgante | Los antebrazos de cristal, como el de las Cuevas |
| Tendero | De bruma | Sí, de otro tono que la de los vecinos | Colgante | — (hoy comparte aspecto con el Vecino; pasa a tener el suyo) |
| Vecino y Pescador | De bruma | Sí | Colgante | — |
| Vecina | De bruma | Sí (sustituye al moño) | Colgante | — |

- **Piel de bruma:** un gris azulado tirando a lavanda, el de alguien que respira la Niebla. Se ve en la cara y en los brazos.
- **Capucha:** cubre la cabeza y cae un poco por la nuca, del color de la capa de cada uno. Es una pieza facetada como el pelo, así que encaja con el resto del estilo.
- **Cristal:** una piedra pequeña y facetada en el pecho, azul claro, con un brillo suave propio que no alumbra nada.
- **Farol de Orvalla:** pequeño, en la mano derecha, con el cristal amarillo que brilla.
- **Cuenco de la Curandera:** en la mano izquierda, con agua azul clara que brilla un poco.
- **Brazos del Herrero:** de cristal azul claro con un brillo propio, como los cristales de las Cuevas.
- En las escenas (cutscenes) se ven igual, porque usan los mismos aspectos.

### Cómo se hace

- **Las caras:** `scripts/tools/head_textures.gd` gana la piel `bruma` y escribe las cabezas que hacen falta: `head_gris_bruma.png` (Orvalla), `head_rubio_bruma.png` (Neblí), `head_pelirrojo_bruma.png` (Vecina) y `head_castano_bruma.png` (los demás). Después van `--import` y `mipmaps/generate=true` en cada `.import`, como en las cabezas de la Caravana.
- **Los brazos** se tiñen con un tono de piel nuevo, `SKIN_MIST`, igual que hoy con `SKIN_DARK` y `SKIN_PALE`.
- **La capucha** es una pieza más de las que cuelgan del hueso de la cabeza, como el moño, la coleta y la barba (`HAIR_PIECES`), pero en el color de la capa. Cada aspecto pide `hair` o capucha, no las dos.
- **El cristal, el farol y el cuenco** son piezas facetadas que cuelgan de un hueso: el pecho y las manos, con `handslot_r` y `handslot_l` en las manos. Su material brilla (`emission`) y no hay ninguna luz.
- **Los brazos del Herrero:** el material de `Knight_ArmLeft` y `Knight_ArmRight` es el de cristal, con brillo. No llevan el tinte de piel.
- **Dónde va el código:** los aspectos nuevos y sus constantes van en `ActorLooksV3`, porque `actor_looks.gd` ya está en su tope de líneas. Las piezas las monta `CharacterBuilder`. Si con ellas pasa de ~320 líneas, se separan en un constructor propio (por ejemplo `MistDress`), siguiendo la skill `structuring-godot-code`. `brumaclara.tres` cambia el `look` del Tendero por el suyo.
- **El rótulo con el nombre** se queda donde está, en `top`. La capucha no puede subirlo ni taparlo.

## 3. El aura del nivel máximo (M-107)

### Lo que ve el jugador

- Con el héroe en el nivel 60 (`Leveling.MAX_LEVEL`), lo rodea un aura dorada en todas partes: en el mapa, en los combates y en las escenas.
- Los topes de la v1 (20) y de la v2 (40) no la encienden, porque no son el nivel máximo del juego.
- **Cómo es:** una envoltura de luz dorada pálida, un poco más grande que el héroe, más viva abajo y en los bordes y casi transparente por delante, para que se le siga viendo bien la cara y el equipo.
  - Ondula hacia arriba como una llama lenta y respira despacio: sube y baja de intensidad cada 2 s más o menos.
  - Unas pocas chispas doradas suben desde los pies y se apagan a la altura de la cabeza.
  - Es suave, no deslumbra ni tapa nada.
- **Al llegar al 60** en un combate, tras el aviso de subida de nivel, el aura se enciende con un destello breve y desde ese momento se queda. Al cargar una partida que ya está en el 60, el aura ya está puesta.
- Solo el héroe: el compañero y la criatura no la llevan.

### Cómo se hace

- **Una pieza propia:** el aura es un nodo con un solo trabajo, por ejemplo `HeroAura` (`Node3D`), en `scripts/battle/`. La crea el dueño de la figura del héroe y la cuelga de ella: el `Player` en el mapa, la escena de combate en los combates y lo que monte al héroe en las escenas. No crece `battle_actor.gd`, que está en su tope de líneas.
- **La envoltura:** una malla que rodea la figura, con un shader propio (`shaders/hero_aura.gdshader`), aditivo y sin sombras. El borde brilla más que el centro (fresnel), la ondulación sube con ruido y el tiempo, y la respiración es una onda lenta. Tiene que ir en el renderer Compatibility, el de la web y el móvil.
- **Las chispas:** `CPUParticles3D`, que va igual en la web, con pocas partículas (unas 12 a la vez). En el móvil, menos, siguiendo lo que `DisplaySettings` ya rebaja.
- **El color:** dorado pálido, el mismo en el mapa y en combate. Los colores del 3D no van a `UiTokens`, que es solo de la interfaz.
- **Cuándo se pone:** cualquiera que tenga el estado del héroe lo sabe con una regla pura, por ejemplo `Leveling.at_max(hero)`. Al subir al 60 en combate, el destello va después del evento `LEVEL_UP` de ese nivel.

## Verificación

- `--check-only` en los scripts cambiados y las dos herramientas del design system.
- **Capturas de Brumaclara**, con `--write-movie` o en ventana, en las etapas 1 a 5:
  - todos los habitantes de cerca y de lejos;
  - Orvalla, la Curandera y el Herrero de cerca;
  - la escena `brumaclara_llega`.
  
  Lo mismo a 740 × 360 con `--touch`.
- La carrera `brumaclara` del piloto automático hasta el final: el nivel en el margen y las derrotas. Las carreras de la v1 (Nv 18) y la v2 (Nv 40) no cambian de nivel.
- Cargar una partida de la 3.7.0 al Nv 50 en Brumaclara: sigue subiendo al ganar experiencia.
