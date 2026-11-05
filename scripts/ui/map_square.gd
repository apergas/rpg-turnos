class_name MapSquare extends PanelContainer
## The small translucent square under the map's status window: what the hero has seen of
## this zone (ExploredMap) and a marker on the hero. follow() runs every physics tick but
## the image only changes, cell by cell, when new cells are seen, so it costs next to
## nothing on the web build. It takes no clicks: the ground under it can still be tapped.

const SIDE := 150.0
const BACK := Color(0.04, 0.04, 0.12, 0.45)
const BORDER := Color(1.0, 1.0, 1.0, 0.7)
const ALPHA := 0.8
const MARKER_SIZE := 7.0
const MARKER_COLOR := Color.WHITE

var _map: ExploredMap
var _image: Image
var _texture: ImageTexture
var _picture: TextureRect
var _marker: ColorRect
## Pixels per cell, and where the grid starts inside the square.
var _scale := 1.0
var _origin := Vector2.ZERO


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = BACK
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(SIDE, SIDE)
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inside := Control.new()
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(inside)
	_picture = TextureRect.new()
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_picture.modulate.a = ALPHA
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(_picture)
	_marker = ColorRect.new()
	_marker.color = MARKER_COLOR
	_marker.size = Vector2.ONE * MARKER_SIZE
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(_marker)


## Shows map: paints every cell already seen, once.
func set_map(map: ExploredMap) -> void:
	_map = map
	_image = Image.create(map.size.x, map.size.y, false, Image.FORMAT_RGBA8)
	for y in map.size.y:
		for x in map.size.x:
			if map.is_seen(Vector2i(x, y)):
				_image.set_pixel(x, y, map.color_of(Vector2i(x, y)))
	_texture = ImageTexture.create_from_image(_image)
	_picture.texture = _texture
	_scale = floorf(SIDE / maxi(map.size.x, map.size.y))
	var drawn := Vector2(map.size) * _scale
	_origin = ((Vector2.ONE * SIDE - drawn) / 2.0).floor()
	_picture.position = _origin
	_picture.size = drawn


## The hero at pos: reveals what they see from there and moves the marker.
func follow(pos: Vector3) -> void:
	var fresh := _map.reveal(pos)
	if not fresh.is_empty():
		for cell in fresh:
			_image.set_pixelv(cell, _map.color_of(cell))
		_texture.update(_image)
	var at := (_origin + _map.grid_point(pos) * _scale - Vector2.ONE * MARKER_SIZE / 2.0).floor()
	if at != _marker.position:
		_marker.position = at
