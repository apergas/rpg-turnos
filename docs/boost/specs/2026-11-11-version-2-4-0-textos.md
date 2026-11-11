# Versión 2.4.0: los textos de la v2

Fecha: 2026-11-11. Anexo de `2026-11-11-version-2-4-0-design.md` (M-54). Son los textos nuevos, listos para pegar. Solo la v2: Villaclaro, el bosque, la mina y el castillo no cambian.

## Reglas

- **Una broma de vez en cuando, no en cada frase.** El humor va en cuatro sitios: lo primero que dice el Jefe de caravana en cada capítulo, la llegada a cada zona (una frase del compañero), las frases de misión cumplida y alguna frase suelta de la Viajera, el Viajero y la Curandera. Las ofertas de misión, las frases de espera, los objetivos y las escenas de los jefes siguen siendo normales: dicen qué hacer y dónde. Algunas entregas y frases de compañero van sin broma a propósito (`centinelas`, Ulma): ese es el "no siempre" que pide el usuario.
- **Pocos camellos.** Solo tres frases los nombran: la de `caravana_campamento`, el tablón y la de los escorpiones.
- Tono: ligero, tonto, cariñoso, para toda la familia, castellano de España. Nada de memes ni de cosas que no existan en ese mundo.
- Etiquetas: `{nombre}` (el héroe) y `{compañero}` (en las escenas) se mantienen donde estaban.
- Largo: en el escritorio cada frase cabe en una línea (`DialogueBox.MAX_WIDTH` 1000 px). En el móvil la ventana deja unos 470 px (unos 38 caracteres por línea, unos 30 con letra grande): una frase de hasta 110 caracteres ocupa **hasta 3 líneas**, como las que ya hay en el juego (que llegan a 128). Ninguna frase nueva pasa de 110 caracteres.
- Las entregas al Jefe de caravana (M-50) ya están en estos textos.

## 1. El Jefe de caravana

### Qué dice en cada caso (M-50)

En la Caravana, con el compañero ya elegido:

1. **Con entregas listas:** las frases de entrega (`done_lines`) de cada una, en el orden de `QuestLog.QUESTS`, cada una seguida de su pago ("Recibes ..."). No dice nada más.
2. **Sin entregas y con alguna misión suya en curso:** primero sus frases del capítulo (abajo), y después la primera frase de espera (`wait_lines[0]`) de la primera misión en curso, con "Llevas n de m." detrás si es de cazar o de recoger varias. Ejemplo en el capítulo 7 con `escorpiones` en 2 de 6: "El desierto está al norte. Busca la ruina: dicen que algo enorme vive bajo la arena." · "Lleva agua... bueno, pociones. En el desierto el agua se evapora antes de llegar a la boca." · "¿Seis escorpiones? Los verás entre las dunas, con la cola en alto." · "Llevas 2 de 6."
3. **Sin nada en curso:** sus frases del capítulo.

### Frases de capítulo (`data/zones/caravana.tres`)

`lines` (capítulo 6, la jungla):

1. "La jungla está al norte. Cuando estés listo, sal por allí."
2. "Y si un mono te roba algo, no lo persigas. Llevo veinte años persiguiendo a uno."

`lines_by_chapter`:

| Capítulo | Frases |
|---|---|
| 7 (desierto) | "El desierto está al norte. Busca la ruina: dicen que algo enorme vive bajo la arena." · "Lleva agua... bueno, pociones. En el desierto el agua se evapora antes de llegar a la boca." |
| 8 (montaña) | "La montaña está al norte. En la cumbre anida un grifo enorme." · "Busca la palanca de los viejos pastores: abre la reja de la subida." · "Y abrígate. La última vez se me congeló la barba y tardó tres días en volver a rizarse." |
| 9 (ciudad) | "La ciudad abandonada está al norte. Dicen que un guardián de bronce vigila su plaza mayor." · "Detrás de la ciudad está el portal. Llega hasta él, y la caravana irá detrás." |
| 10 (fin) | "Cruzaste el portal y volviste para contarlo. Lo que hay al otro lado... ya habrá tiempo." · "La caravana se queda aquí una temporada. Descansa, {nombre}. Te lo has ganado, y yo también." |

En `ciudad_2` (`lines`, tras el Devorador): "La caravana te esperará aquí. He traído sillas."

En `pradera` no cambia nada: hablar con él lleva siempre a las dos preguntas de partir (`_ask_departure()`), así que sus `lines` de allí no se oyen nunca.

### `Game._choose_companion()`

- Sin elegir: "Piénsalo bien. Te espero aquí, que yo no tengo prisa."
- Elegido: "%s irá contigo. La jungla está al norte." (sin cambios: es la orden de salida).

`Game.JOIN_QUESTION` y `LEAVE_QUESTION` no cambian: son las dos preguntas serias del viaje.

### La escena `caravana_campamento`

El `say` del Jefe queda, entero:

```
["say", "Jefe de caravana", ["Nadie cruza la jungla solo. Ni siquiera yo, y eso que tengo un camello muy valiente.", "Tres de los míos se han ofrecido a ir contigo.", "Elige a uno. Irá a tu lado en cada combate, hasta el portal."]]
```

El `say` del narrador de antes no cambia.

## 2. La Viajera y el Viajero (`caravana.tres`)

Viajera:

- `lines`: "Llevo tres caravanas encima. Esta es la primera que va hacia el portal." · "Las otras dos iban a por queso. Esta me gusta más."
- Capítulo 10: "Dicen que al otro lado del portal hay un pueblo bajo un sol negro. Yo no pienso ir a verlo." · "Con un sol negro no hay manera de secar la ropa."

Viajero (sin broma en el 9: es la frase de la ciudad):

- `lines`: "Crucé ese desierto de joven. De día quema y de noche hiela." · "Por eso tengo esta cara."
- Capítulo 9: "De niño oí que en esa ciudad vivía un rey. Ahora solo quedan piedras y esqueletos."
- Capítulo 10: "Si vuelves a cruzar ese portal, tráeme algo de recuerdo. Algo pequeño. Que no muerda."

## 3. Nara y el Superviviente en la Caravana (nuevos, M-50)

Figuras `npc` de `caravana.tres` que salen cuando su misión está cumplida (`needs` `nara_vuelve` / `superviviente_vuelve`):

- **Nara** (`lines`): "Gracias otra vez. El mono no me deja: dice mi hermana que ahora tengo mascota." · "Si ves a uno que chilla mucho, salúdalo de mi parte."
- **Superviviente** (`lines`): "Gracias por sacarme de aquí. Ya voy por el tercer plato de sopa." · "¿Crees que me darán un cuarto?"

Las frases de la Exploradora en `jungla.tres` y del Superviviente en `ciudad_1.tres` no cambian: no se oyen nunca.

## 4. El tablón y la Curandera

- Tablón de la Caravana (`lines`, sin misión que ofrecer): "Nada nuevo en el tablón. Alguien ha dibujado un camello con sombrero."
- La Curandera (posada `caravana`, `Inn.LINES`, solo esa posada; las de la v1 siguen con `Inn.REST` / `Inn.FULL`):
  - Para descansar: "Túmbate un rato. Esto no duele... casi nada."
  - Con PV y PM llenos: "Estás más sano que una pera. Vuelve cuando te duela algo."

## 5. La llegada a cada zona (nuevo: una frase del compañero)

La primera vez que el héroe llega a la zona, tras el rótulo del lugar, el compañero dice su frase (`Allies.arrival_line(id, zone)`). Una por compañero y zona.

| Zona | Brena | Tadeo | Ulma |
|---|---|---|---|
| `jungla` | "Qué calor. Si algo se mueve entre las hojas, le pego. Si no se mueve, también." | "Huele a lluvia, a flores y a algo que nos quiere comer. Por ese orden." | "Mantente detrás de mi escudo. Y no toques las ranas azules: no son caramelos." |
| `desierto` | "Arena en las botas, arena en el pelo... Hasta en el desayuno había arena." | "Si ves un lago a lo lejos, no corras. Es mentira. Lo sé por experiencia." | "Mi escudo quema al sol. Ahora sirve también de sartén." |
| `montana_1` | "¡Por fin fresquito! En la jungla sudaba hasta la espada." | "Me castañetean los dientes. No es miedo: es ritmo." | "He traído dos mantas. Una es para mí y la otra también." |
| `ciudad_1` | "Qué silencio. No me gustan los sitios donde nadie se queja." | "Mira esas casas. Seguro que alguna tenía una despensa llena." | "Esqueletos de guardia. Ponte detrás de mí y no hagas ruido." |

## 6. Las misiones de la v2 (`data/quests/*.tres`)

Todas se entregan al Jefe de caravana (`turn_in` "Jefe de caravana", `turn_in_zone` "caravana"). Los campos que no salen aquí no cambian.

### `pieles_mono` (Pieles para el frío)

- `objective`: "Reúne 4 Pieles de mono en la jungla y llévaselas al Jefe de caravana."
- `report`: "pieles al Jefe de caravana"
- `offer_lines`: "SE BUSCAN: pieles de mono aullador, cuatro. Para el frío de las montañas. Se entregan al Jefe de caravana."
- `wait_lines`: "¿Pieles? Las de los monos aulladores, los que no se callan nunca. Cuatro."
- `done_lines`: "¡Cuatro pieles, y buenas! Con esto nadie se congela en la montaña." · "El Mercader quería hacerse un gorro. Le he dicho que a la cola." · "Toma, te lo has ganado."

### `explorador_perdido` (La exploradora perdida)

- `objective`: "Busca a Nara, la exploradora de la caravana, en un claro del oeste de la jungla."
- `report`: "vuelve con el Jefe de caravana"
- `offer_lines` (la Viajera; la primera no cambia): "Mi hermana Nara salió a explorar la jungla hace dos días y no ha vuelto." · "Dijo que iría hacia el oeste, a un claro con piedras. ¿La buscarías? El Jefe te dará algo de nuestra parte."
- `found_lines`: "¡Por fin alguien! Me torcí el tobillo huyendo de un mono que no paraba de chillar." · "Ya puedo andar. Vuelvo a la caravana: dile al Jefe que voy detrás."
- `wait_lines` (el Jefe): "¿Has visto a Nara? La Viajera dice que fue al oeste, a un claro con piedras."
- `done_lines`: "¡Nara ha vuelto! Cojeando, pero entera, y con un mono en la cabeza." · "No se lo quita. Dice que ahora son amigos." · "Ten, de parte de las dos hermanas. Y gracias."
- `done_flag`: `nara_vuelve`.

### `escorpiones` (Escorpiones en las dunas)

- `wait_lines`: "¿Seis escorpiones? Los verás entre las dunas, con la cola en alto."
- `done_lines`: "¡Seis escorpiones! Los camellos ya duermen tranquilos." · "Bueno, uno ronca. Pero eso no es culpa tuya." · "Toma tu paga, y esta pluma: en el desierto nunca sobra."

### `cantimplora` (La cantimplora del Jefe)

Sin cambios: ya se entrega al Jefe y ya tiene su broma ("ese viajero chismoso").

### `cabras` (Cabras en la subida)

- `wait_lines`: "¿Cinco cabras? Las oirás antes de verlas: embisten contra las rocas."
- `done_lines`: "¡Cinco cabras! Las mulas ya suben tranquilas." · "Una de las cabras nos sigue desde ayer. Creo que te ha cogido cariño." · "Toma tu paga, y estos éteres: allá arriba hacen falta."

### `cristales_hielo` (Cristales de hielo)

- `objective`: "Reúne 3 Cristales de hielo de los golems de la montaña y llévaselos al Jefe de caravana."
- `report`: "cristales al Jefe de caravana"
- `offer_lines` (la Viajera): "Los golems de hielo de la montaña llevan cristales dentro. Dicen que no se derriten nunca." · "Llévale tres al Jefe. Él me los guarda, y yo tengo algo para los valientes."
- `wait_lines` (el Jefe): "¿Tres cristales? Los golems de hielo los sueltan al romperse."
- `done_lines`: "¡Tres cristales, y ni una gota de agua! La Viajera dará saltos." · "Pienso usar uno para enfriar la limonada. No se lo digas." · "Toma esta semilla, de su parte. Te hará más duro que el hielo."

### `centinelas` (Los centinelas de la ciudad)

Sin broma: es el último paso antes del portal.

- `wait_lines`: "¿Seis centinelas? Cuidado: cuando uno cae, llama a otro."
- `done_lines`: "¡Seis centinelas! El camino del portal queda libre." · "Esos esqueletos llevaban siglos de guardia. Ya era hora de que descansaran." · "Toma tu paga, y estas plumas: donde vas a ir, nunca sobran."

### `superviviente` (El superviviente)

- `report`: "vuelve con el Jefe de caravana"
- `offer_lines` (el Viajero): "Anoche vi una luz en la ciudad abandonada. Alguien sigue vivo allí dentro, escondido en una casa." · "Dicen que las calles del sur aún se tienen en pie. ¿Lo buscarías? El Jefe te dará algo de mi parte."
- `found_lines`: "¡No me hagas daño! ...Ah, eres de la caravana." · "Llevo semanas escondido de los centinelas. Iré con vosotros: dile al Jefe que voy detrás."
- `wait_lines` (el Jefe): "¿Has encontrado a alguien en la ciudad? El Viajero dice que busques en las casas de la calle del sur."
- `done_lines`: "¡Ha llegado! Flaco y asustado, pero vivo. Ya va por el segundo plato de sopa." · "Toma estas semillas, de parte del Viajero. Las guardaba para un día como hoy."
- `done_flag`: `superviviente_vuelve`.

## 7. Lo que no se toca

- Las escenas (`caravana_llega`, `caravana_parte`, `jaguar`, `gusano`, `grifo`, `guardian`, `cruce`): son el hilo de la historia. De `caravana_campamento` solo cambia el `say` del Jefe (arriba).
- Los compañeros en `ciudad_2` ("Voy contigo."): el momento serio antes del portal.
- Los objetivos (`StoryState`), los textos de los objetos, la tienda, las descripciones de los compañeros (`Allies.line()`) y los créditos.
