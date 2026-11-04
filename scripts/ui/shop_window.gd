class_name ShopWindow extends Control
## Shop window of the map. run(shop_id) opens it on "¿Comprar o vender?" and returns
## when the player leaves. Comprar lists what the shop sells with its price and, for
## equipment, the comparison with what is worn (green ▲ better, red ▼ worse, = same);
## buying a piece of equipment asks "¿Te lo equipas ahora?". Vender lists what the hero
## carries at half price (what is worn is listed but can't be sold). Rows that can't be
## used now are grey with the reason. Keyboard (↑ / ↓, Enter / Space, Esc goes back),
## mouse and touch. The rules are Shop's; this window only shows them. Emits changed
## after every purchase, sale or change of equipment. ask() puts a yes / no question in
## the same window (the inn). Call setup() before adding it.
## With `-- --autoplay` run() buys Shop.autoplay_picks() by itself, equips every piece,
## shows the sell page and prints each message; ask() answers Sí by itself.

signal changed
signal _left
signal _answered(yes: bool)

const FONT_SIZE := 24
const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const GREY := Color(0.6, 0.6, 0.65)
const BETTER := Color(0.35, 1.0, 0.4)
const WORSE := Color(1.0, 0.35, 0.3)
const NAME_WIDTH := 300.0
const PRICE_WIDTH := 90.0
## Messages under the list wrap past this width.
const MESSAGE_WIDTH := 640.0
## Seconds each step stays on screen on autoplay.
const AUTOPLAY_STEP := 0.7

var _state: GameState
var _audio: AudioDirector
var _shop_id := ""
var _page := ""
var _autoplay := false
## Piece just bought, waiting for the "¿Te lo equipas ahora?" answer.
var _asking := ""
var _quiet_focus := false
var _keeper: Label
var _gold: Label
var _title: Label
var _rows: VBoxContainer
var _message: Label


## A small triangle pointing up (green, better) or down (red, worse), drawn so it never
## depends on the font having ▲ / ▼ (the web build has no system fonts).
class Arrow extends Control:
	var up := true
	var color := Color.WHITE

	func _init(p_up: bool, p_color: Color) -> void:
		up = p_up
		color = p_color
		custom_minimum_size = Vector2(18, 18)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var points := PackedVector2Array([Vector2(w / 2.0, 2), Vector2(w - 1, h - 2),
			Vector2(1, h - 2)]) if up else PackedVector2Array([Vector2(1, 2),
			Vector2(w - 1, 2), Vector2(w / 2.0, h - 2)])
		draw_colored_polygon(points, color)


func setup(state: GameState, audio: AudioDirector) -> void:
	_state = state
	_audio = audio


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var window := BattleHud.make_window()
	center.add_child(window)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	window.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 24)
	box.add_child(header)
	_keeper = _label("", TITLE_COLOR)
	_keeper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_keeper)
	_gold = _label("", StatBar.GOLD)
	header.add_child(_gold)
	_title = _label("", Color.WHITE)
	box.add_child(_title)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	box.add_child(_rows)
	_message = _label("", Color.WHITE)
	_message.hide()
	box.add_child(_message)
	hide()


## Opens the shop of shop_id (a Shop.SHOPS key) and returns when the player leaves.
func run(shop_id: String) -> void:
	_shop_id = shop_id
	_keeper.text = Shop.keeper(shop_id)
	_set_message("")
	show()
	_sfx(SfxLibrary.DIALOGUE)
	_show_page("menu")
	if _autoplay:
		await _autoplay_run()
	else:
		await _left
	hide()
	_page = ""


## Shows speaker and question with Sí / No and returns true for Sí (Esc is No).
func ask(speaker: String, question: String) -> bool:
	_keeper.text = speaker
	_set_message("")
	show()
	_sfx(SfxLibrary.DIALOGUE)
	_show_page("question")
	_title.text = question
	if _autoplay:
		print("%s: %s" % [speaker, question])
		get_tree().create_timer(AUTOPLAY_STEP).timeout.connect(
			func() -> void: _answered.emit(true))
	var yes: bool = await _answered
	hide()
	_page = ""
	return yes


func _unhandled_input(event: InputEvent) -> void:
	if _page == "" or _autoplay:
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_back()


## Esc / Volver: the lists and the question go back to the first page, which leaves.
func _back() -> void:
	_sfx(SfxLibrary.CANCEL)
	match _page:
		"menu":
			_page = ""
			_left.emit()
		"ask":
			_answer(false)
		"question":
			_answered.emit(false)
		_:
			_set_message("")
			_show_page("menu")


## focus_id puts the cursor back on that item's row when it is still there and usable,
## so buying or selling several in a row needs no walking down the list again.
func _show_page(page: String, focus_id := "") -> void:
	_page = page
	_gold.text = "Oro %d G" % _state.gold
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	match page:
		"menu":
			_title.text = "¿Comprar o vender?"
			_add_button("Comprar", func() -> void: _open("buy"))
			_add_button("Vender", func() -> void: _open("sell"))
			_add_button("Salir", _back)
		"buy":
			_title.text = "Comprar"
			for id in Shop.stock(_shop_id):
				_add_buy_row(id)
			_add_button("Volver", _back)
		"sell":
			_title.text = "Vender (pago la mitad)"
			var ids := Shop.sell_list(_state)
			for id in ids:
				_add_sell_row(id)
			if ids.is_empty():
				_rows.add_child(_label("No llevas nada que vender.", Color.WHITE))
			_add_button("Volver", _back)
		"ask":
			_title.text = "¿Te %s equipas ahora?" % Equipment.pronoun(_asking)
			_add_button("Sí", func() -> void: _answer(true))
			_add_button("No", func() -> void: _answer(false))
		"question":
			_add_button("Sí", func() -> void:
				_sfx(SfxLibrary.ACCEPT)
				_answered.emit(true))
			_add_button("No", func() -> void:
				_sfx(SfxLibrary.CANCEL)
				_answered.emit(false))
	if focus_id == "" or not _focus_id(focus_id):
		_focus_first()


func _open(page: String) -> void:
	_sfx(SfxLibrary.ACCEPT)
	_set_message("")
	_show_page(page)


## Name and price; for equipment also its bonus and the comparison with what is worn.
func _add_buy_row(id: String) -> void:
	var row := _row()
	var why := Shop.buy_problem(_state, id)
	var button := _button(Shop.display_name(id))
	button.custom_minimum_size.x = NAME_WIDTH
	button.disabled = why != ""
	button.pressed.connect(_buy.bind(id))
	button.set_meta("id", id)
	row.add_child(button)
	var price := _label("%d G" % Shop.price(id), GREY if why != "" else StatBar.GOLD)
	price.custom_minimum_size.x = PRICE_WIDTH
	row.add_child(price)
	var info := Shop.compare(_state, id)
	if not info.is_empty():
		row.add_child(_label("%s +%d" % [info.stat, info.bonus], Color.WHITE))
		row.add_child(comparison(info.diff))
	if why != "":
		row.add_child(_label(why, GREY))


## Name with the count carried, the price paid, and why it can't be sold if so.
func _add_sell_row(id: String) -> void:
	var row := _row()
	var why := Shop.sell_problem(_state, id)
	var count := Shop.sell_count(_state, id)
	var text := Shop.display_name(id) if count <= 1 else "%s ×%d" % [Shop.display_name(id), count]
	var button := _button(text)
	button.custom_minimum_size.x = NAME_WIDTH
	button.disabled = why != ""
	button.pressed.connect(_sell.bind(id))
	button.set_meta("id", id)
	row.add_child(button)
	var price := _label("%d G" % Shop.sell_price(id), GREY if why != "" else StatBar.GOLD)
	price.custom_minimum_size.x = PRICE_WIDTH
	row.add_child(price)
	if why != "":
		row.add_child(_label(why, GREY))


## Green ▲ and +n when better, red ▼ and -n when worse, "=" when the same (also used by
## the Equipo page of the pause menu).
static func comparison(diff: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	if diff == 0:
		box.add_child(_make_label("=", Color.WHITE))
		return box
	var color := BETTER if diff > 0 else WORSE
	var arrow := Arrow.new(diff > 0, color)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(arrow)
	box.add_child(_make_label("%+d" % diff, color))
	return box


func _buy(id: String) -> void:
	var result := Shop.buy(_state, id)
	_say(result.text)
	if not result.ok:
		_sfx(SfxLibrary.CANCEL)
		return
	_sfx(SfxLibrary.ACCEPT)
	changed.emit()
	if Shop.is_equipment(id):
		_asking = id
		_show_page("ask")
	else:
		_show_page("buy", id)


func _answer(equip: bool) -> void:
	if equip and _state.equip(_asking):
		_sfx(SfxLibrary.ACCEPT)
		_say("Te equipas %s %s." % [Equipment.article(_asking), Equipment.display_name(_asking)])
		changed.emit()
	var bought := _asking
	_asking = ""
	_show_page("buy", bought)


func _sell(id: String) -> void:
	var result := Shop.sell(_state, id)
	_say(result.text)
	if not result.ok:
		_sfx(SfxLibrary.CANCEL)
		return
	_sfx(SfxLibrary.ACCEPT)
	changed.emit()
	_show_page("sell", id)


## Autoplay: shows the first page, buys and equips each pick on the buy page, and shows
## the sell page (selling nothing) before leaving.
func _autoplay_run() -> void:
	await _wait()
	_show_page("buy")
	await _wait()
	for id in Shop.autoplay_picks(_state, _shop_id):
		_focus_row(Shop.display_name(id))
		await _wait()
		_buy(id)
		if _page == "ask":
			await _wait()
			_answer(true)
		await _wait()
	_show_page("sell")
	await _wait()
	_show_page("menu")
	await _wait()


func _wait() -> void:
	await get_tree().create_timer(AUTOPLAY_STEP).timeout


## Shows text under the list; on autoplay also prints it.
func _say(text: String) -> void:
	_set_message(text)
	if _autoplay:
		print(text)


## The line under the list; an empty one takes no room, so the window hugs the rows.
func _set_message(text: String) -> void:
	BattleHud.fit_label(_message, text, MESSAGE_WIDTH)
	_message.visible = text != ""


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_rows.add_child(row)
	return row


func _add_button(text: String, action: Callable) -> void:
	var button := _button(text)
	button.pressed.connect(action)
	_rows.add_child(button)


func _focus_first() -> void:
	_quiet_focus = true
	for button in _rows.find_children("*", "Button", true, false):
		if not (button as Button).disabled:
			(button as Button).grab_focus()
			break
	_quiet_focus = false


func _focus_row(text: String) -> void:
	_quiet_focus = true
	for button in _rows.find_children("*", "Button", true, false):
		if (button as Button).text == text:
			(button as Button).grab_focus()
			break
	_quiet_focus = false


## Focuses the enabled row of that item; false when there is none.
func _focus_id(id: String) -> bool:
	for button in _rows.find_children("*", "Button", true, false):
		if button.get_meta("id", "") == id and not (button as Button).disabled:
			_quiet_focus = true
			(button as Button).grab_focus()
			_quiet_focus = false
			return true
	return false


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.focus_entered.connect(func() -> void:
		if not _quiet_focus:
			_sfx(SfxLibrary.CURSOR))
	return button


func _label(text: String, color: Color) -> Label:
	return _make_label(text, color)


static func _make_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label


func _sfx(id: String) -> void:
	if _audio:
		_audio.play_sfx(id)
