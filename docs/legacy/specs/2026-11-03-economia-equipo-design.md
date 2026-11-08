# Economía y equipo: diseño

Fecha: 2026-11-03
Paso: fase 4 de `2026-11-03-ideas-juego-completo.md`. Va después de la fase 3 (combate completo), que ya acumula oro y tiene la tabla `ITEMS`.

## Objetivo

Dar sentido a luchar y explorar en la zona 1:

- **Oro** que se gasta en **tiendas** y en la **posada**.
- **Equipo** en tres ranuras (arma, armadura y escudo) que cambia las estadísticas y se ve en el modelo.
- **Cofres** repartidos por el mapa.

Las tiendas de las zonas 2 a 4 llegan con la fase de mundo, que usa este mismo sistema.

## Decisiones tomadas

El usuario pidió que no se le pregunte, así que todas son la opción recomendada. Precios y cifras vienen de la sección "Equilibrio" del listado de ideas.

| Tema | Decisión |
|---|---|
| Oro inicial | 50 G |
| Oro al perder | Se pierde **la mitad** (redondeando hacia abajo), al estilo clásico. El mensaje de derrota lo dice |
| Ranuras | **Arma** (suma ATK), **armadura** y **escudo** (suman DEF). Al empezar: Palo (+2 ATK), Ropa (+2 DEF) y sin escudo. Sustituyen a las bonificaciones fijas de la fase 3 |
| Catálogo | Una tabla `EQUIPMENT` con id, nombre, ranura, bonificación, precio y zona. La zona 1 tiene **Espada de cobre** +6 ATK por 40 G, **Cota de cuero** +5 DEF por 30 G y **Escudo de madera** +3 DEF por 25 G. Las zonas 2 a 4 ya se apuntan en la tabla con los precios del listado, aunque sus tiendas lleguen más tarde |
| Tienda de Villaclaro | Un **mercader** nuevo junto a la casa de la izquierda, con el aspecto `VILLAGER` en otro color. Al hablarle aparece "¿Comprar o vender?". **Comprar** muestra una lista con precio y la comparación con lo que llevas puesto (▲ verde, ▼ roja, = igual). Si compras equipo, pregunta "¿Te lo equipas ahora?". **Vender** paga la mitad del precio. No se puede vender lo que llevas puesto |
| Objetos en la tienda | Poción 8 G, Antídoto 10 G y Éter 30 G (desde la zona 2; en Villaclaro no se vende) |
| Posada | La anciana sigue curando gratis al hablar, por la misión. La **posada** es otra casa con un posadero: 5 G por dormir, con fundido a negro, curación completa y autoguardado. En Villaclaro la anciana ya cubre la curación, así que la posada sirve de modelo para las otras zonas |
| Cofres | **4 cofres** en la pradera, en sitios apartados del camino: 2 con oro (25 G y 40 G), 1 con un Éter y 1 con el **Escudo de madera**, que así se puede conseguir sin comprarlo. Se abren al acercarte y pulsar Enter, o tocándolos. Cada cofre recuerda que se ha abierto y se guarda en la partida |
| Equipo visible | Arma y escudo se ven en el modelo del caballero: cada pieza muestra su malla de `handslot` (por ejemplo, 1H_Sword para las espadas y Round_Shield para el escudo de madera). Sin escudo, la mano izquierda queda vacía. La armadura no cambia el modelo |
| Menú de pausa | La opción **Equipo** se añade al menú de la fase 2: muestra las tres ranuras y permite cambiar entre el equipo que tengas en la bolsa |
| Estadísticas | `Combatant` separa las estadísticas base de las del equipo: `attack` y `defense` se calculan como base más equipo. Las fórmulas de combate no cambian |
| Interfaz | El oro aparece en la ventana de estado del mapa y del menú de pausa ("Oro 123 G") |
| Equilibrio | Se repite el simulador con el equipo real de la zona 1: los combates normales deben costar un 15-20 % de PV a mitad de zona y el Rey Slime debe ganarse un ~88 % de las veces a nivel 5 con el equipo de la zona |

## Arquitectura

- **`Equipment`** (`RefCounted`, nuevo): la tabla `EQUIPMENT` y sus funciones `bonus(id)`, `slot(id)` y `price(id)`.
- **`Loadout`** (`RefCounted`, nuevo): lo que lleva puesto el héroe. Tiene `equip(id)` (devuelve lo que quitó), `attack_bonus()` y `defense_bonus()`.
- **`Shop`** (`RefCounted`, nuevo):
  - Reglas puras: `can_buy(state, id)`, `buy(state, id)`, `sell(state, id)` y `compare(state, id)`.
  - Las funciones de compra y venta devuelven el resultado y los mensajes.
- **`GameState`:** gana `gold`, `loadout`, `bag_equipment` (equipo que llevas sin poner) y `opened_chests`. `SaveData` los guarda.
- **`World`:**
  - Mercader y cofres, cada uno con su collider.
  - Señales `shop_requested(shop_id)` y `chest_opened(chest_id)`.
  - Los cofres son un modelo hecho en código: caja de madera con una banda dorada y la tapa abierta cuando ya se ha abierto.
- **`ShopWindow`** (`Control`, nuevo): la lista de comprar y vender, con teclado, ratón y toque. Va en `scripts/ui/`.
- **`BattleActor`:** gana `set_equipment(weapon_id, shield_id)`, que muestra u oculta las mallas de `handslot`.

## Verificación (sin tests)

- `--check-only` en los scripts tocados.
- **Autoplay:** compra el equipo de Villaclaro en cuanto tiene el oro, abre los cofres que pilla de camino (la ruta pasa por dos) y completa la misión sin ERROR ni WARNING. Imprime el oro y el equipo.
- **Fotogramas:** la tienda (comprar y la comparación), un cofre cerrado y abierto, y el héroe con la espada de cobre y el escudo.
- **Simulador de equilibrio**, con los resultados en el informe.
- **Guardar y cargar** conserva el oro, el equipo y los cofres abiertos.
- **Versión web:** se exporta.

## Fuera de alcance

- Tiendas de otras zonas (fase 5).
- Rareza, conjuntos, mejorar armas y creación de objetos.
- Regateo y reputación.
