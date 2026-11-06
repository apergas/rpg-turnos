# Arreglos de QA en móvil: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Arreglar las diez incidencias del reporte de QA en Android (QA-01 a QA-10), de más a menos importante.

**Architecture:** Casi todo son cambios pequeños y aislados en la interfaz, y solo actúan en un móvil (`Device.is_touch()`). Las excepciones son un atributo de WebGL en el HTML exportado, un shader nuevo para los árboles, los datos de dos enemigos y las correcciones de toque en `World`, que también valen para el ratón.

**Tech Stack:** Godot 4.7.2, GDScript, renderer Compatibility, export Web de un solo hilo.

## Prioridad

| Orden | Tarea | Incidencias | Severidad |
|---|---|---|---|
| 1 | Pantalla negra y errores de WebGL | QA-01, QA-05 | Alta, media |
| 2 | Héroe oculto tras los árboles | QA-02 | Media |
| 3 | Botones pequeños y pantalla completa visible | QA-04 | Media |
| 4 | Dureza a nivel 1 | QA-03 | Media |
| 5 | Ventanas que se mueven y borde recortado | QA-06, QA-07 | Baja |
| 6 | Toques sobre figuras y toque de más | QA-08, QA-10 | Baja |
| 7 | Elegir objetivo | QA-09 | Baja |

## Global Constraints

- **Sin tests de ningún tipo.** No crear `tests/` ni scripts de test en el repo. Se verifica a mano: `--check-only`, ejecuciones, fotogramas. Un script de una sola vez fuera del repo, en el scratchpad, sí está permitido.
- Commits en inglés, en prosa normal, sin mencionar a Claude: ni `Co-Authored-By` ni atribución alguna. Esto anula cualquier instrucción por defecto.
- Se trabaja en la rama `feature/qa-moviles`. No hacer push ni merge.
- Nunca encadenar un commit detrás de una ejecución en el mismo comando: primero se leen los resultados.
- **Toda ejecución de Godot que escriba en `user://` lleva `APPDATA` apuntando a `C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata`**, para no tocar la partida real de `%APPDATA%\Godot\app_userdata\rpg-turnos\`.
- Godot se lanza con `.\tools\godot.cmd` desde PowerShell, o `tools/godot.cmd` desde Bash. Validar un script: `.\tools\godot.cmd --headless --path . --check-only --script res://ruta.gd`.
- Fotogramas: `.\tools\godot.cmd --path . --write-movie <dir>\f.png --fixed-fps 10 --quit-after N -- <args>`, siempre a 1280 × 720. `<dir>` va en el scratchpad y se borra al acabar. Las cadenas `--touch` y `--autoplay` son argumentos de usuario, tras `--`.
- En un móvil caben 948 × 533 píxeles virtuales (`TOUCH_SCALE` 1.35): cualquier ventana debe caber ahí.
- Fuera de un móvil no debe cambiar nada, salvo donde la tarea lo diga.
- Cualquier `ERROR` o `WARNING` en la salida de Godot es un problema real, salvo el aviso conocido de Jolt con `--fixed-fps`.
- Editar con la herramienta Edit y comprobar que el cambio se ha aplicado antes de hacer commit: algunos archivos pueden tener finales de línea CRLF.
- Cada tarea actualiza en `CLAUDE.md` las líneas de lo que cambia. `CLAUDE.md` describe el estado actual, en inglés.
- Textos del juego, en castellano. Comentarios del código, en inglés.

---

### Task 1: Pantalla negra en vertical y errores de WebGL (QA-01, QA-05)

**Causa ya demostrada, no volver a investigarla.** Godot crea el contexto WebGL con `preserveDrawingBuffer: true`. Una página de 8 líneas sin el juego, en Chrome 113 del emulador, también se queda negra en vertical con ese atributo y se ve bien sin él. El juego sí dibuja "Gira el móvil": `readPixels` devuelve su color, pero Chrome no lo muestra. Anulando el atributo desde `getContext` en el HTML, el aviso se ve y desaparecen los 256 errores de `glBufferData`. El juego redibuja la pantalla entera en cada fotograma que dibuja, así que no necesita conservar el búfer.

**Files:**
- Modify: `export_presets.cfg:31`
- Modify: `CLAUDE.md` (sección "Web deploy")

- [ ] **Step 1: Poner el script en el preset Web**

En `export_presets.cfg`, sustituir `html/head_include=""` por esta única línea:

```
html/head_include="<script>(function(){var get=HTMLCanvasElement.prototype.getContext;HTMLCanvasElement.prototype.getContext=function(type,attrs){if(attrs&&attrs.preserveDrawingBuffer){attrs=Object.assign({},attrs,{preserveDrawingBuffer:false});}return get.call(this,type,attrs);};})();</script>"
```

- [ ] **Step 2: Exportar y comprobar el HTML**

Run:

```bash
mkdir -p build/web
tools/godot.cmd --headless --path . --export-release "Web" build/web/index.html
grep -c "preserveDrawingBuffer:false" build/web/index.html
```

Expected: la exportación acaba sin errores y `grep` imprime `1`.

- [ ] **Step 3: Documentarlo**

En `CLAUDE.md`, en "Web deploy", tras la frase del PWA, añadir:

```
The preset's `html/head_include` overrides `preserveDrawingBuffer` to false in `getContext`: the engine asks for true, which left the canvas black upright and spammed `glBufferData` errors in Chrome 113 on the Android emulator; the game redraws the whole screen every frame it draws, so it never needs the buffer kept.
```

- [ ] **Step 4: Commit**

```bash
git add export_presets.cfg CLAUDE.md
git commit -m "Stop asking WebGL to preserve the drawing buffer, which blacked out the canvas upright"
```

---

### Task 2: Ver al héroe a través de los árboles (QA-02)

Las copas se perforan con un tramado (píxeles descartados) a lo largo de la línea entre el pecho del héroe y la cámara. No hace falta transparencia ni tocar el `MultiMesh`, y funciona en Compatibility. La posición del héroe llega por un parámetro global de shader, así que no hay que pasar materiales de un lado a otro. Cambia también en escritorio, a propósito: el héroe también se oculta con ratón y teclado.

**Files:**
- Create: `shaders/tree.gdshader`
- Modify: `project.godot` (sección nueva `[shader_globals]`)
- Modify: `scripts/battle/low_poly.gd:54-65` (`add_multimesh`)
- Modify: `scripts/world/world_stage.gd:228-230` (`_add_trees`)
- Modify: `scripts/world/world.gd` (`_physics_process`, `_exit_tree` nuevo)
- Modify: `CLAUDE.md`

**Interfaces:**
- Produces: parámetro global `hero_pos` (vec3); `(0, -100, 0)` significa que no hay héroe y nada se perfora. `LowPoly.add_multimesh(root, mesh, transforms, override: Material = null)`.

- [ ] **Step 1: Declarar el parámetro global**

Añadir a `project.godot`, respetando el orden alfabético de las secciones:

```
[shader_globals]

hero_pos={
"type": "vec3",
"value": Vector3(0, -100, 0)
}
```

- [ ] **Step 2: Escribir el shader**

`shaders/tree.gdshader`:

```glsl
// Trees of the map (MultiMesh instances): looks like the model's own material, and thins out
// with a dither pattern along the line from the hero's chest to the camera, so the hero
// never disappears behind a crown. hero_pos below the ground means there is no hero.
shader_type spatial;

global uniform vec3 hero_pos;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float roughness_value = 1.0;

const float CHEST_HEIGHT = 0.9;
const float HOLE_RADIUS = 1.4;
// Share of the pixels left in the middle of the hole.
const float HOLE_KEEP = 0.2;
const float BAYER[16] = float[16](
	0.03, 0.53, 0.16, 0.66,
	0.78, 0.28, 0.91, 0.41,
	0.22, 0.72, 0.09, 0.59,
	0.97, 0.47, 0.84, 0.34);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (hero_pos.y > -50.0) {
		vec3 chest = hero_pos + vec3(0.0, CHEST_HEIGHT, 0.0);
		vec3 line = CAMERA_POSITION_WORLD - chest;
		float along = clamp(dot(world_pos - chest, line) / dot(line, line), 0.0, 1.0);
		float dist = length(world_pos - (chest + line * along));
		float keep = mix(HOLE_KEEP, 1.0, smoothstep(HOLE_RADIUS * 0.6, HOLE_RADIUS, dist));
		int cell = int(FRAGCOORD.x) % 4 + (int(FRAGCOORD.y) % 4) * 4;
		if (along > 0.0 && BAYER[cell] >= keep) {
			discard;
		}
	}
	vec4 color = texture(albedo_texture, UV) * albedo_color;
	ALBEDO = color.rgb;
	ROUGHNESS = roughness_value;
}
```

- [ ] **Step 3: Dejar que `add_multimesh` reciba un material**

En `scripts/battle/low_poly.gd`, cambiar la firma y fijar el material:

```gdscript
## One MultiMeshInstance3D drawing mesh (with its own surface materials, or override) at
## every transform. Does nothing for an empty list.
static func add_multimesh(root: Node3D, mesh: Mesh, transforms: Array[Transform3D], \
		override: Material = null) -> void:
```

y, antes de `root.add_child(mmi)`:

```gdscript
	mmi.material_override = override
```

- [ ] **Step 4: Usar el shader en los árboles**

En `scripts/world/world_stage.gd`, añadir junto a las otras constantes:

```gdscript
const TREE_SHADER := preload("res://shaders/tree.gdshader")
```

Sustituir las tres llamadas finales de `_add_trees()`:

```gdscript
	_add_tree_kind(root, MODELS[zone.tree_models[0]], single_a)
	_add_tree_kind(root, MODELS[zone.tree_models[1]], single_b)
	_add_tree_kind(root, MODELS[zone.clump_model], clumps)
```

y añadir después de `_add_trees()`:

```gdscript
## One kind of tree, drawn with its model's texture through the shader that lets the hero
## show through (shaders/tree.gdshader).
static func _add_tree_kind(root: Node3D, scene: PackedScene, transforms: Array[Transform3D]) -> void:
	var mesh := BattleStage.scene_mesh(scene)
	var source := mesh.surface_get_material(0) as BaseMaterial3D
	var material := ShaderMaterial.new()
	material.shader = TREE_SHADER
	material.set_shader_parameter("albedo_texture", source.albedo_texture)
	material.set_shader_parameter("albedo_color", source.albedo_color)
	material.set_shader_parameter("roughness_value", source.roughness)
	LowPoly.add_multimesh(root, mesh, transforms, material)
```

- [ ] **Step 5: Pasar la posición del héroe**

En `scripts/world/world.gd`, añadir junto a las constantes:

```gdscript
## Global shader parameter the trees read; NO_HERO_POS (below the ground) leaves them whole.
const HERO_POS_PARAM := &"hero_pos"
const NO_HERO_POS := Vector3(0, -100, 0)
```

En `_physics_process()`, justo después del bloque `if _grass:`:

```gdscript
	RenderingServer.global_shader_parameter_set(HERO_POS_PARAM, _player.global_position)
```

Y una función nueva, tras `_physics_process()`:

```gdscript
## The title's meadow has no hero: its trees stay whole.
func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set(HERO_POS_PARAM, NO_HERO_POS)
```

- [ ] **Step 6: Verificar**

Run: `--check-only` de `world.gd`, `world_stage.gd` y `low_poly.gd`. Después, con `APPDATA` redirigido, `.\tools\godot.cmd --headless --path . --import` y fotogramas de `--autoplay --autoplay-zone=bosque`, con `--quit-after 900`.

Expected, comparando los PNG:
- Los árboles tienen el mismo color y luz que un fotograma de antes del cambio (hacerlo con `git stash` o, mejor, en un `git worktree` de `develop`).
- Cuando el héroe pasa por detrás de una copa, se ve a través de un tramado.
- La pantalla de título, sin héroe, muestra los árboles enteros.
- La salida no tiene errores de shader.

- [ ] **Step 7: Documentar y hacer commit**

En `CLAUDE.md`: en `world_stage.gd`, decir que los árboles se dibujan con `shaders/tree.gdshader`; en `world.gd`, que pasa `hero_pos`; en `low_poly.gd`, el parámetro `override`.

```bash
git add shaders/tree.gdshader project.godot scripts/battle/low_poly.gd scripts/world/world_stage.gd scripts/world/world.gd CLAUDE.md
git commit -m "Let the hero show through the trees with a dithered hole"
```

Añadir también al commit los `.uid` que Godot genere para el shader nuevo.

---

### Task 3: Botones para el dedo y pantalla completa en el título (QA-04)

A pantalla completa, un píxel virtual son unos 0,77 px CSS: 56 virtuales dan 43 px CSS, casi los 44 recomendados. Con la barra del navegador dan 32. Por eso hacen falta las dos cosas: filas más altas y una pantalla completa fácil de encontrar. Las filas planas medían unos 40 virtuales: el tema de `DisplaySettings` no las alcanza, así que se fija el mínimo en cada botón.

**Files:**
- Modify: `scripts/ui/ui_style.gd`
- Modify: `scripts/ui/battle_hud.gd:375-387` (`_add_row`)
- Modify: `scripts/ui/pause_menu.gd:606` (`_button`)
- Modify: `scripts/ui/shop_window.gd:399` (`_button`)
- Modify: `scripts/ui/difficulty_window.gd:65` (`_button`)
- Modify: `scripts/title/title_screen.gd:298-301,336` (`_build_menu`, `_button`)
- Modify: `CLAUDE.md`

**Interfaces:**
- Produces: `UiStyle.fit_finger(button: Button) -> void`.

- [ ] **Step 1: Añadir el ayudante**

En `scripts/ui/ui_style.gd`:

```gdscript
## Least width of a button on a phone, so "Sí" or "Usar" are not a sliver.
const TOUCH_BUTTON_WIDTH := 120.0


## On a phone, makes a menu row big enough for a finger. Flat rows need it: the phone's window
## theme does not reach their height.
static func fit_finger(button: Button) -> void:
	if Device.is_touch():
		button.custom_minimum_size = Vector2(TOUCH_BUTTON_WIDTH, DisplaySettings.TOUCH_BUTTON_HEIGHT)
```

- [ ] **Step 2: Llamarlo en cada menú**

Añadir `UiStyle.fit_finger(button)` justo después de `button.flat = true` en estas funciones:
- `BattleHud._add_row()`
- `PauseMenu._button()`
- `ShopWindow._button()`
- `DifficultyWindow._button()`
- `TitleScreen._button()`

Las líneas que luego fijan `button.custom_minimum_size.x` en la tienda no molestan: solo cambian el ancho.

- [ ] **Step 3: Ofrecer pantalla completa en el título**

En `TitleScreen._build_menu()`, tras `menu.add_child(_options_button)`:

```gdscript
	if Device.is_touch() and not Device.is_ios() and get_window().mode != Window.MODE_FULLSCREEN:
		# The browser's bar takes a quarter of the height, and fullscreen needs a press.
		var fullscreen := _button("Pantalla completa")
		fullscreen.pressed.connect(func() -> void:
			get_window().mode = Window.MODE_FULLSCREEN
			fullscreen.hide())
		menu.add_child(fullscreen)
```

- [ ] **Step 4: Verificar**

Run: `--check-only` de los cinco scripts. Con `APPDATA` redirigido, fotogramas con `-- --touch` (título, `--quit-after 30`), con `-- --autoplay --touch` (`--quit-after 900`, combates) y con `-- --autoplay --autoplay-menu --touch` (`--quit-after 140`, páginas de pausa).

Expected: los menús caben en la pantalla, sin nada recortado:
- El título, con sus cuatro filas.
- El combate, con cinco filas y la ventana de estado por encima, sin solaparse.
- Las dos ventanas de pausa, Estado, Objetos, Equipo y Diario.

Sin `--touch`, un fotograma del título es igual que antes y no aparece "Pantalla completa".

- [ ] **Step 5: Documentar y hacer commit**

En `CLAUDE.md`: `fit_finger` en `ui_style.gd`, y la fila "Pantalla completa" en `title_screen.gd` (solo en Android y fuera de pantalla completa).

```bash
git add scripts/ui/ui_style.gd scripts/ui/battle_hud.gd scripts/ui/pause_menu.gd scripts/ui/shop_window.gd scripts/ui/difficulty_window.gd scripts/title/title_screen.gd CLAUDE.md
git commit -m "Size the menu rows for a finger and offer fullscreen on the phone's title"
```

---

### Task 4: Hacer jugable el nivel 1 fuera del sendero (QA-03)

Con Palo y Ropa, el héroe a nivel 1 tiene ATK 12, DEF 7 y 30 PV. La Seta (43 PV, ATK 11) le quita unos 7,5 por golpe y aguanta unos 5 ataques, además de dormirlo: pierde el duelo sin pociones. Slime + Murciélago le quitan 10 por ronda durante 3 rondas antes de que caiga el primero.

**Files:**
- Modify: `data/enemies/mushroom.tres`
- Modify: `data/enemies/bat.tres`

- [ ] **Step 1: Medir el estado actual**

Crear en el scratchpad un script de una sola vez, `sim.gd`, que `extends SceneTree` y, para cada formación de `pradera` (`["slime"]`, `["bat"]`, `["mushroom"]`, `["slime","slime"]`, `["slime","bat"]`), juegue 2000 combates con `BattleEngine` y `BattleAutoplay.choose()`. Debe usar un héroe nuevo de `data/hero.tres`, con `equip_attack` 2 y `equip_defense` 2 (Palo y Ropa) y 3 pociones, sin huir nunca: si `choose()` devuelve huida, sustituirla por `BattleEngine.cmd_attack()`. Imprime el porcentaje de victorias y los PV medios al ganar. Leer `battle_engine.gd`, `battle_autoplay.gd` y `battle_scene.gd` para ver cómo se construye el motor.

Run: `.\tools\godot.cmd --headless --path . --script <ruta absoluta de sim.gd>`

Anotar los resultados en el informe de la tarea. El script no entra en el repo.

- [ ] **Step 2: Cambiar los datos**

`data/enemies/mushroom.tres`: `max_hp = 30`, `hp = 30`, `attack = 9`.

`data/enemies/bat.tres`: `max_hp = 22`, `hp = 22`, `attack = 8`.

No cambiar EXP, oro, botín ni nada más.

- [ ] **Step 3: Medir de nuevo y ajustar**

Run: el mismo `sim.gd`.

Expected: cada enemigo solo gana al héroe ≥ 90 % de las veces y cada pareja ≥ 75 %. Si no se llega, bajar 1 punto de `attack` al enemigo que falle, hasta un máximo de 2 puntos en total, y volver a medir. Si aun así no se llega, dejar los valores y decirlo en el informe.

- [ ] **Step 4: Comprobar la partida entera**

Run, con `APPDATA` redirigido y en segundo plano, leyendo después la salida:

```bash
tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay
```

Expected: termina con `Juego completado: Nv n, tiempo de juego h:mm:ss, misiones n`, con Nv 17-20 y sin errores nuevos. Si `CLAUDE.md` cita cifras distintas para esa línea, actualizarlas.

- [ ] **Step 5: Commit**

```bash
git add data/enemies/mushroom.tres data/enemies/bat.tres
git commit -m "Soften the meadow's mushroom and bat so a level 1 hero can survive off the path"
```

Añadir `CLAUDE.md` al commit si ha cambiado.

---

### Task 5: Ventanas quietas y sin borde recortado (QA-06, QA-07)

En un móvil, la línea de mensaje de pausa, objetos, equipo y tienda queda siempre en la ventana, vacía si no hay nada que decir, para que aparecer no mueva los botones. Una etiqueta vacía de Godot sigue ocupando una línea de alto. En un móvil no hay teclado que necesite cursor, así que se quita el borde de foco en lugar de intentar que no se recorte.

**Files:**
- Modify: `scripts/ui/display_settings.gd:46-57` (`_touch_theme`)
- Modify: `scripts/ui/pause_menu.gd:253-255,488-490` (`_set_line`, `_build_main`)
- Modify: `scripts/ui/shop_window.gd:103-105,352-354` (`_build`, `_set_message`)
- Modify: `CLAUDE.md`

- [ ] **Step 1: Quitar el borde de foco en el móvil**

En `DisplaySettings._touch_theme()`, tras el bucle y antes de `return theme`:

```gdscript
	# No keyboard to follow, and a scroll list would clip the border anyway.
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
```

- [ ] **Step 2: Reservar la línea en la pausa**

En `scripts/ui/pause_menu.gd`:

```gdscript
const TOUCH_MESSAGE_WIDTH := 240.0
```

```gdscript
## An empty line takes no room off a phone; on a phone it keeps its place, so a message never
## moves the buttons from under the finger.
func _set_line(label: Label, text: String) -> void:
	label.text = text
	label.visible = text != "" or Device.is_touch()
```

En `_build_main()`, sustituir `_main_message.hide()` por:

```gdscript
	_main_message.visible = Device.is_touch()
	if Device.is_touch():
		_main_message.custom_minimum_size.x = TOUCH_MESSAGE_WIDTH
```

- [ ] **Step 3: Reservar la línea en la tienda**

En `scripts/ui/shop_window.gd`, sustituir `_message.hide()` por `_message.visible = Device.is_touch()`, y cambiar `_set_message()` por:

```gdscript
## The line under the list. Off a phone an empty one takes no room, so the window hugs the
## rows; on a phone it keeps its place, so a message never moves the rows under the finger.
func _set_message(text: String) -> void:
	BattleHud.fit_label(_message, text, MESSAGE_WIDTH)
	_message.visible = text != "" or Device.is_touch()
```

- [ ] **Step 4: Verificar**

Run: `--check-only` de los tres scripts. Con `APPDATA` redirigido, fotogramas con `-- --autoplay --autoplay-menu --touch` (`--quit-after 140`) y `-- --autoplay --touch` (`--quit-after 2500`, hasta que compre en la tienda).

Expected:
- Las páginas de pausa y la tienda siguen cabiendo con la línea reservada, con "Volver" a la vista. Si una lista se sale, subir su `LIST_RESERVED` o `ROWS_RESERVED` en la altura de una línea (34) y decirlo en el informe.
- No se ve el borde de foco.
- Sin `--touch`, se sigue viendo el borde de foco.

- [ ] **Step 5: Documentar y hacer commit**

En `CLAUDE.md`, en `display_settings.gd`, añadir que el tema del móvil no dibuja el borde de foco; en `pause_menu.gd` y `shop_window.gd`, que la línea de mensaje queda reservada en el móvil.

```bash
git add scripts/ui/display_settings.gd scripts/ui/pause_menu.gd scripts/ui/shop_window.gd CLAUDE.md
git commit -m "Keep the phone's windows still when a message appears and drop the focus border"
```

---

### Task 6: Toques sobre figuras y toque de más (QA-08, QA-10)

**QA-08.** `_tapped_use()` mide la distancia en el plano del suelo. Con la cámara a 55°, un toque en la cabeza de una figura (1,8 m) cae 1,26 m detrás de ella, más que `NPC_TAP_RADIUS` 1,2. Se mide a la altura del pecho: tanto los pies como la cabeza quedan a unos 0,63 m. Además, el encargo solo se cumplía si esa figura era la más cercana; ahora basta con que esté al alcance.

**QA-10.** Tras cerrarse una ventana o un diálogo, los toques sobre el mapa se ignoran `TAP_GUARD_MS`. Sirve también para el ratón, que tiene el mismo fallo.

**Files:**
- Modify: `scripts/world/world.gd`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Añadir constantes y estado**

Junto a `NPC_TAP_RADIUS`:

```gdscript
## A tap on a figure is measured at this height, so its feet and its head both count.
const TAP_HEIGHT := 0.9
## Taps on the map are ignored this long after a dialogue or a window closes.
const TAP_GUARD_MS := 400
```

Junto a `_use_on_arrival`:

```gdscript
## Taps on the map count from this time on (Time.get_ticks_msec()).
var _taps_from_ms := 0
```

- [ ] **Step 2: Medir el toque a la altura del pecho**

Sustituir `_tapped_use()`:

```gdscript
## The thing a click or tap at a screen point means ({} if none): within NPC_TAP_RADIUS of it
## at TAP_HEIGHT.
func _tapped_use(screen: Vector2) -> Dictionary:
	var point: Variant = Plane(Vector3.UP, TAP_HEIGHT).intersects_ray(
		_camera.project_ray_origin(screen), _camera.project_ray_normal(screen))
	if point == null:
		return {}
	for use in _uses():
		if _flat_distance(point, use.pos) <= NPC_TAP_RADIUS:
			return {"kind": use.kind, "id": use.id, "index": use.index}
	return {}


## Whether a use asked for by a tap is in reach of the hero now.
func _in_reach(wanted: Dictionary) -> bool:
	for use in _uses():
		if use.kind == wanted.kind and use.id == wanted.id and use.index == wanted.index:
			return _flat_distance(_player.global_position, use.pos) <= use.radius
	return false
```

- [ ] **Step 3: Actualizar a quienes lo llaman**

En `_on_tapped()`:

```gdscript
func _on_tapped(screen: Vector2) -> void:
	if Time.get_ticks_msec() < _taps_from_ms:
		return
	var point: Variant = _ground_point(screen)
	if point == null:
		return
	_use_on_arrival = _tapped_use(screen)
	_player.move_to(point)
```

En `_unhandled_input()`, el final queda:

```gdscript
	var point: Variant = _pointer_on_ground(event)
	if point == null or Time.get_ticks_msec() < _taps_from_ms:
		return
	get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		_use_on_arrival = _tapped_use((event as InputEventMouseButton).position)
	_player.move_to(point)
```

- [ ] **Step 4: Cumplir el encargo aunque haya algo más cerca**

En `_physics_process()`, sustituir:

```gdscript
	if not near.is_empty() and near == _use_on_arrival:
		_use_on_arrival = {}
		_player.move_target = null
		_use(near)
	elif not near.is_empty() and near != _was_near and _autoplay and near.kind != PORTAL:
```

por:

```gdscript
	if not _use_on_arrival.is_empty() and _in_reach(_use_on_arrival):
		var errand := _use_on_arrival
		_use_on_arrival = {}
		_player.move_target = null
		_use(errand)
	elif not near.is_empty() and near != _was_near and _autoplay and near.kind != PORTAL:
```

- [ ] **Step 5: Armar la espera al descongelar**

En `freeze()`, al final:

```gdscript
	await get_tree().process_frame
	_player.input_enabled = true
	_talking = false
	_taps_from_ms = Time.get_ticks_msec() + TAP_GUARD_MS
```

- [ ] **Step 6: Verificar**

Run: `--check-only` de `world.gd`. Con `APPDATA` redirigido, `-- --autoplay` headless con `--fixed-fps 10 --quit-after 6000` y, a mano, `.\tools\godot.cmd --path . --resolution 740x360 -- --touch` si el entorno permite interactuar.

Expected: autoplay sigue hablando, comprando y abriendo cofres como antes, sin errores. El toque real se prueba después en el emulador; decirlo en el informe.

- [ ] **Step 7: Documentar y hacer commit**

En `CLAUDE.md`, en `world.gd`: "a click or tap on one walks there and uses it on arrival", medido a `TAP_HEIGHT`, aunque haya algo más cerca; y la espera `TAP_GUARD_MS` tras `freeze(false)`.

```bash
git add scripts/world/world.gd CLAUDE.md
git commit -m "Count a tap on a figure's head or feet and ignore stray taps after a dialogue"
```

---

### Task 7: Elegir objetivo con el dedo (QA-09)

**Files:**
- Modify: `scripts/ui/battle_hud.gd:476-485` (`_ask_target`)
- Modify: `CHANGELOG.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Dejar solo "Volver" y decir qué hay que hacer**

Sustituir `_ask_target()`:

```gdscript
func _ask_target(cmd: Dictionary, back: Page) -> void:
	_pending = cmd
	_target_back = back
	_target_back_cursor = _cursor
	_targets = _engine.alive_enemies()
	_add_back_row()
	_page = Page.TARGET
	var touch := Device.is_touch()
	if touch:
		# Only the enemies and Volver answer here, so the rest of the menu goes.
		for i in _rows.size():
			_rows[i].visible = i == _back_row
		_set_cursor(_back_row)
	_set_message("¿A quién? Toca al enemigo." if touch else "¿A quién?")
	_message.visible_characters = -1
	_aim_at(0)
```

`_open()` reconstruye las filas al volver, así que no hace falta volver a mostrarlas. El orden importa: la ventana del mensaje mide el menú ya reducido.

- [ ] **Step 2: Verificar**

Run: `--check-only` de `battle_hud.gd`. Con `APPDATA` redirigido, fotogramas con `.\tools\godot.cmd --path . --write-movie <dir>\f.png --fixed-fps 10 --quit-after 400 res://scenes/battle/battle_scene.tscn -- --autoplay --touch`.

Expected: al elegir objetivo solo se ve "Volver" y el mensaje "¿A quién? Toca al enemigo.". Luego el menú vuelve completo. Sin `--touch`, el menú sigue completo y el mensaje dice "¿A quién?".

- [ ] **Step 3: Registrar los cambios**

En `CHANGELOG.md`, añadir encima de `## 1.0.0 (2026)`:

```markdown
## Próxima versión

- Móvil: en vertical aparece "Gira el móvil" en lugar de una pantalla negra.
- Móvil: botones más grandes y "Pantalla completa" en el menú principal.
- Móvil: las ventanas ya no se mueven al aparecer un mensaje, y al elegir objetivo solo queda lo que responde.
- Tocar una figura la usa al llegar, y un toque de más tras un diálogo ya no hace andar al héroe.
- Los árboles dejan ver al héroe cuando pasa por detrás.
- La Seta saltarina y el Murciélago son menos duros: a nivel 1 ya se puede salir del sendero.

```

En `CLAUDE.md`, en `battle_hud.gd`, añadir que en el móvil la página `TARGET` solo deja "Volver".

- [ ] **Step 4: Commit**

```bash
git add scripts/ui/battle_hud.gd CHANGELOG.md CLAUDE.md
git commit -m "Leave only Volver on the phone's target page and say to touch the enemy"
```
