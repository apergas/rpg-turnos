# Adaptar el juego a móviles: diseño

Fecha: 2026-11-06. Va justo después de la fase 7. El usuario no quiere preguntas: se toma siempre la opción recomendada.

## Objetivo

Que la versión web se pueda jugar entera en el navegador de un móvil, con una mano o dos, sin teclado y con un texto que se lea.

## Lo que se ha visto

- El juego ya se puede manejar con el dedo a base de ratón emulado, pero a 360 px de alto una fuente de 24 se queda en 12 px y un botón en 20 px.
- La documentación de Godot avisa: la web en móvil rinde bastante menos que una app nativa, Safari tiene problemas propios con WebGL 2, la pantalla completa solo se puede pedir desde una pulsación, y el audio no suena hasta el primer toque.
- El lienzo web se dibuja a la densidad real de la pantalla: un móvil de densidad 3 pinta más píxeles que un monitor de 1080p. Es el mayor riesgo de rendimiento.
- La plantilla web de Godot ya bloquea el zoom del navegador (`touch-action: none`, `user-scalable=no`).
- La descarga pesa unos 10 MB con compresión: `index.wasm` son 39,5 MB sin comprimir (GitHub Pages comprime; itch.io no) e `index.pck` 3 MB. Reducirla exige compilar plantillas propias: queda fuera.

## Decisiones

| Tema | Decisión | Por qué |
|---|---|---|
| Alcance | Navegador móvil. Sin apps de Android ni iOS | Es lo que ya se publica; las apps necesitan SDK, firmas y tiendas |
| Orientación | Solo apaisado. En vertical, un aviso "Gira el móvil" tapa el juego | Todas las ventanas y el combate están pensados en apaisado; rehacerlos en vertical sería otra interfaz |
| Detección | `Device.is_touch()`: Android o iOS en la web, iPad (dice ser Mac, pero tiene pantalla táctil), o `--touch` para probar | Un portátil táctil sigue con su interfaz normal |
| Tamaño | `content_scale_factor` 1,35 en móvil y 1,6 con textos grandes: 533 y 450 de alto virtual | Mismo mecanismo que los textos grandes de la fase 7 |
| Botones | Tema global con botones de 56 de alto virtual en móvil, unos 38 px reales | Sin tocar cada ventana |
| Rendimiento | En móvil, calidad baja por defecto, 3D a 0,6 de resolución en baja y 0,8 en alta, y 30 FPS en baja | Reduce píxeles, calor y batería; la opción Gráficos sigue mandando |
| Andar | Toque corto: ir a ese punto, como ahora. Arrastrar: palanca flotante nacida donde se apoya el dedo | Ir a un punto se atasca en los pasillos de la mina; la palanca no |
| Zoom | Dos dedos | La rueda no existe en el móvil |
| Usar | El aviso del suelo es un botón grande en móvil ("Hablar", "Abrir"...) | "Enter o toca" no tiene sentido sin teclado, y tocar la figura obliga a acertar |
| Ventana de estado | Compacta en móvil: sin barra de EXP ni pociones (están en Estado), una sola línea de misión, y el mapa pequeño arriba a la derecha | A 533 de alto tapaba más de la mitad de la pantalla |
| Opciones | En móvil no hay Teclas. Pantalla completa aparece en Android, no en iPhone, donde Safari no la permite | Solo lo que funciona |
| Barras del navegador | La web se puede instalar en la pantalla de inicio (PWA), a pantalla completa y en apaisado | Es lo único que quita las barras en iPhone |
| Guardado | Sin cambios: autoguardado tras cada combate y cambio de zona | Si el móvil cierra la pestaña, se pierde como mucho el último paseo |

## Fuera

Apps nativas, plantillas web propias, vibración, modo vertical y mando.

## Comprobación

Sin pruebas automáticas, como siempre. Ventanas en el peor caso con `--touch` a 533 y 450 de alto, partida automática completa, y la exportación web en el navegador integrado a 740 × 360 con toques sintéticos. **Lo que no se puede comprobar aquí y queda para el usuario:** un móvil real, sus FPS, Safari en iPhone, el sonido y la instalación en la pantalla de inicio.
