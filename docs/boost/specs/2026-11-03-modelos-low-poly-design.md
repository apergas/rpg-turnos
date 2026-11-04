# Modelos low-poly: diseño

Fecha: 2026-11-03
Paso: fase 1b de `2026-11-03-ideas-juego-completo.md`. Va después de 1a (cámara cenital y vegetación, en `2026-11-03-camara-vegetacion-design.md`).

## Objetivo

Sustituir las primitivas por **modelos low-poly con animaciones**: el héroe, la anciana, los slimes, el Rey Slime, las casas, el pozo, las rocas, y además árboles y arbustos nuevos. Se usan paquetes gratuitos con licencia **CC0**: se pueden usar en un juego comercial sin pedir permiso ni citar al autor, aunque citarlos en los créditos queda bien.

## Decisiones tomadas

El usuario pidió que no se le pregunte, así que todas son la opción recomendada.

| Tema | Decisión |
|---|---|
| Paquetes | Descargados de GitHub con permiso del usuario: **KayKit – Adventurers 1.0**, **KayKit – Medieval Hexagon 1.0** y **KayKit – Skeletons 1.0** (para enemigos de fases posteriores). Los tres son CC0. Forest y los de Quaternius solo se bajan desde itch.io, así que se cambian por estos, que cubren lo mismo |
| Dónde están | Paquetes enteros en `assets_src/`, ignorado por git y por Godot (`.gdignore`). A `assets/` solo se copia lo que se usa |
| Héroe | `Knight.glb`: 76 animaciones dentro del propio modelo (`Idle`, `Walking_A`, `Running_A`, `1H_Melee_Attack_Slice_Diagonal`, `Spellcast_Shoot`, `Hit_A`, `Dodge_Backward`, `Death_A`, `Cheer`…). Muestra solo `1H_Sword` y `Round_Shield`; oculta el resto de armas y escudos |
| Anciana | `Mage.glb` con el bastón (`2H_Staff`); oculta el libro y la varita |
| Slime y Rey Slime | Ningún paquete descargable tiene slime, así que se hace en código con **estilo low-poly**: una malla facetada (pocas caras, sombreado plano) con ojos. El Rey Slime es el mismo slime a escala 1,6 con la corona dorada |
| Pueblo | Del Medieval Hexagon, versión roja: `building_home_A_red` y `building_home_B_red` (las dos casas) y `building_well_red` (el pozo). Escala ~3,5, porque el paquete es en miniatura (una casa mide 0,8 m) |
| Naturaleza | Del Medieval Hexagon: `tree_single_A/B` y `trees_A_medium` (árboles, escala ~4), y `rock_single_A–E` (rocas, escala ~8-10). Todos comparten la textura `hexagons_medieval.png` |
| Escala de los personajes | Los modelos de KayKit miden unas 2,4 unidades; se escalan para que el héroe mida ~1,6 m, como ahora. El valor exacto se mide en Godot |
| Qué entra en el repositorio | Solo los modelos que se usan, copiados a `assets/` con su licencia; nunca los paquetes enteros |
| Créditos | `assets/CREDITS.md` con cada paquete, su autor, el enlace y la licencia |

## Arquitectura

- **`BattleActor`** deja de construir primitivas para los personajes. Sigue siendo el único punto de entrada y mantiene:
  - el enum `Look` (`HERO`, `SLIME`, `VILLAGER`, `KING_SLIME`);
  - la orientación hacia −Z;
  - las funciones esperables `play_attack`, `play_hit`, `play_dodge`, `play_defeat`, `play_cast`, `play_burn`, `play_heal`, `play_stagger` y `reset`.

  `BattleScene`, `World` y `Player` no cambian su forma de usarlo.
- **Tabla `LOOKS`** dentro de `BattleActor`, una entrada por `Look`:
  - escena del modelo;
  - escala;
  - nombres de las animaciones de reposo, caminar, atacar, lanzar hechizo, recibir golpe, morir y celebrar;
  - adornos (la corona del Rey Slime).

  Los nombres exactos de las animaciones se sacan al abrir los paquetes. Se listan con un script de Godot en el primer paso del plan de 1b.
- **Animaciones y tweens:** cada `play_*` lanza la animación del modelo con `AnimationPlayer` y conserva los tweens que siguen teniendo sentido: el desplazamiento al atacar, el destello, los números flotantes, las bolas de fuego y la curación. Las funciones devuelven el control cuando acaban la animación y el tween.
- **Reposo:** sustituye al bote de ahora con la animación de reposo. El slime conserva su bote si su animación de reposo ya lo hace.
- **Mapa:** `Player` usa la animación de caminar mientras se mueve y la de reposo cuando para. Se quita el bote de `Player`.
- **`WorldStage` y `BattleStage`:**
  - colocan las casas, el pozo, las rocas, los árboles y los arbustos a partir de escenas importadas;
  - los árboles se reparten fuera del camino con una semilla fija, más densos hacia los bordes de la pradera;
  - las colisiones son cajas y cilindros puestos a mano, como ahora, porque los modelos no traen colisiones en la versión gratuita.
- **Materiales:** los de los paquetes se dejan como vienen. Si alguno queda muy brillante con el renderizador Compatibility, se baja su energía o se pone rugosidad 1 en la importación.

## Tamaño de la versión web

- Solo se exportan los modelos que hay en `assets/`. El objetivo es que la exportación web crezca **menos de 15 MB**.
- Si un modelo pesa mucho, se usa una textura más pequeña al importarlo.

## Verificación (sin tests)

- `--import` tras copiar los recursos, y `--check-only` en los scripts tocados.
- **Fotogramas** con `--write-movie`, en el mapa y en el combate:
  - el héroe camina con su animación;
  - la anciana, los slimes y el Rey Slime con su corona;
  - las casas, los árboles y las rocas;
  - en combate, las animaciones de ataque, hechizo, golpe y muerte.
- **Autoplay** completo sin ERROR ni WARNING nuevos.
- **Versión web:** se exporta sin errores, se mide cuánto crece y se abre en el navegador.

## Plan

El plan de 1b se escribe cuando los paquetes estén descargados. Sin abrirlos no se pueden saber los nombres de los archivos ni de las animaciones, y un plan sin esos datos tendría huecos.

## Fuera de alcance

- Modelos para las zonas 2 a 4 y sus enemigos: se añaden en la fase del mundo, con los mismos paquetes.
- Interiores de las casas.
- Equipo visible en el modelo: fase de economía y equipo.
