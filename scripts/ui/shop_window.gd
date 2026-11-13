class_name ShopWindow extends Control
## Shop window of the map. run(shop_id) opens it on "¿Comprar o vender?" and returns
## when the player leaves. Comprar lists what the shop sells with its price and, for
## equipment, the comparison with what is worn (green ▲ better, red ▼ worse, = same);
## buying a piece of equipment asks "¿Te lo equipas ahora?". Vender lists what the hero
## carries at half price (what is worn is listed but can't be sold). Rows that can't be
## used now are grey with the reason. Keyboard (↑ / ↓, Enter / Space, Esc goes back),
## mouse and touch. The rules are Shop's; this window only shows them. Emits changed
## after every purchase, sale or change of equipment. Call setup() before adding it.
## With `-- --autoplay` run() buys Shop.autoplay_picks() by itself, equips every piece,
## shows the sell page and prints each message.

signal changed
signal _left

const NAME_WIDTH := 280.0
## Phone: narrower names, so the widest row still fits the screen.
const TOUCH_NAME_WIDTH := 240.0
const PRICE_WIDTH := 90.0
const BULK_WIDTH := 72.0
## Room kept for the reason a row can't be bought ("Falta oro"), so the width never changes.
const WHY_WIDTH := 84.0
## Messages under the list wrap past this width.
const MESSAGE_WIDTH := float(UiTokens.WINDOW_W_XL)
## What the header, the title, a two-line message and the margins leave for the rows.
const ROWS_RESERVED := 220.0
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
var _scroll: ScrollBox
## The Volver button of the lists, outside the part that scrolls.
var _footer: VBoxContainer
var _message: Label


## A small triangle pointing up (green, better) or down (red, worse), drawn so it never
## depends on the font having ▲ / ▼ (the web build has no system fonts).
class Arrow extends Control:
	var up := true
	var color: Color

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
	# A tap outside the window is "Volver".
	var backdrop := Control.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.gui_input.connect(func(event: InputEvent) -> void:
		if UiStyle.is_outside_tap(event) and not _autoplay:
			_back())
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var window := BattleHud.make_window()
	center.add_child(window)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTokens.SPACE_2)
	window.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", UiTokens.SPACE_6)
	box.add_child(header)
	_keeper = _label("", UiTheme.TITLE)
	_keeper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_keeper)
	_gold = _label("", UiTheme.MONEY)
	header.add_child(_gold)
	_title = _label("")
	box.add_child(_title)
	_scroll = ScrollBox.new(ROWS_RESERVED)
	box.add_child(_scroll)
	_rows = _scroll.content
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", UiTokens.SPACE_1)
	_footer = VBoxContainer.new()
	box.add_child(_footer)
	_message = _label("")
	box.add_child(_message)
	UiTheme.add_cursor(window)
	hide()


## Opens the shop of shop_id (a Shop.SHOPS key) and returns when the player leaves.
func run(shop_id: String) -> void:
	_shop_id = shop_id
	_keeper.text = Shop.keeper(shop_id)
	_set_message("")
	show()
	_sfx(SfxLibrary.DIALOGUE)
	# A tamer has one creature to show: no menu, no selling.
	_show_page("buy" if Shop.sells_ally(shop_id) else "menu")
	if _autoplay:
		await _autoplay_run()
	else:
		await _left
	hide()
	_page = ""


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
		_:
			if Shop.sells_ally(_shop_id):
				_page = ""
				_left.emit()
				return
			_set_message("")
			_show_page("menu")


## focus_id puts the cursor back on that item's row when it is still there and usable,
## so buying or selling several in a row needs no walking down the list again.
func _show_page(page: String, focus_id := "") -> void:
	var kept := _scroll.scroll_vertical
	_page = page
	_gold.text = "%d G" % _state.gold
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for child in _footer.get_children():
		_footer.remove_child(child)
		child.queue_free()
	match page:
		"menu":
			_title.text = "¿Comprar o vender?"
			_add_button("Comprar", func() -> void: _open("buy"))
			_add_button("Vender", func() -> void: _open("sell"))
			_add_button("Salir", _back)
		"buy":
			if _shop_id == Shop.COMPANIONS_SHOP:
				_title.text = "Compañeros"
			else:
				_title.text = "Criaturas" if Shop.sells_ally(_shop_id) else "Comprar"
			for id in Shop.stock(_shop_id):
				_add_buy_row(id)
			_add_footer_button("Volver", _back)
		"sell":
			_title.text = "Vender (pago la mitad)"
			var ids := Shop.sell_list(_state)
			for id in ids:
				_add_sell_row(id)
			if ids.is_empty():
				_rows.add_child(_label("No llevas nada que vender."))
			_add_footer_button("Volver", _back)
		"ask":
			_title.text = "¿Te %s equipas ahora?" % Equipment.pronoun(_asking)
			_add_button("Sí", func() -> void: _answer(true))
			_add_button("No", func() -> void: _answer(false))
	_align_names()
	if focus_id == "" or not _focus_id(focus_id):
		_focus_first()
	if focus_id != "":
		_keep_scroll(kept)


## The name column is as wide as the longest name of the list (never less than NAME_WIDTH), so the
## prices line up even with "Armadura de adamantita".
func _align_names() -> void:
	var names: Array[Button] = []
	var widest := TOUCH_NAME_WIDTH if Device.is_touch() else NAME_WIDTH
	for node in _rows.find_children("*", "Button", true, false):
		if node.has_meta("id"):
			names.append(node as Button)
			widest = maxf(widest, (node as Button).get_minimum_size().x)
	for button in names:
		button.custom_minimum_size.x = widest


## The rows were just rebuilt: once they are laid out, the list goes back where it was.
func _keep_scroll(value: int) -> void:
	await get_tree().process_frame
	_scroll.scroll_vertical = value


func _open(page: String) -> void:
	_sfx(SfxLibrary.ACCEPT)
	_set_message("")
	_show_page(page)


## Name and price; for equipment also its bonus and the comparison with what is worn.
func _add_buy_row(id: String) -> void:
	var row := _row()
	var why := Shop.buy_problem(_state, id)
	var button := _button(Shop.display_name(id))
	button.custom_minimum_size.x = TOUCH_NAME_WIDTH if Device.is_touch() else NAME_WIDTH
	button.disabled = why != ""
	button.pressed.connect(_buy.bind(id))
	button.set_meta("id", id)
	row.add_child(button)
	var chosen := Allies.is_companion(id)
	var price := _label("Elegir" if chosen else "%d G" % Shop.price(id),
		UiTheme.REASON if why != "" else (&"" if chosen else UiTheme.MONEY))
	price.custom_minimum_size.x = PRICE_WIDTH
	row.add_child(price)
	if Shop.is_ally(id):
		# Stats with the note under them, so a long note never widens the window.
		var info_box := VBoxContainer.new()
		info_box.add_child(_label(Allies.stats_text(id)))
		if Allies.line(id) != "":
			UiStyle.add_small_text(info_box, Allies.line(id))
		if why != "":
			info_box.add_child(_label(why, UiTheme.REASON))
		if _state.ally_id != "" and why != Shop.HAS_IT and why != Shop.HAS_BETTER \
				and not Allies.is_companion(id):
			info_box.add_child(_label("Sustituye a %s" % Allies.display_name(_state.ally_id),
				UiTheme.REASON))
		row.add_child(info_box)
		return
	var info := Shop.compare(_state, id)
	if not info.is_empty():
		row.add_child(_label("%s +%d" % [info.stat, info.bonus], UiTheme.REASON if why != "" else &""))
		row.add_child(comparison(info.diff))
	else:
		var bulk := _button("×%d" % Shop.BULK)
		bulk.custom_minimum_size.x = BULK_WIDTH
		bulk.alignment = HORIZONTAL_ALIGNMENT_CENTER
		bulk.disabled = not Shop.can_buy_bulk(_state, id)
		bulk.pressed.connect(_buy_bulk.bind(id))
		row.add_child(bulk)
		UiStyle.add_description(row, id)
	# The reason always takes its place, so the window keeps its width after a purchase.
	var why_label := _label(why, UiTheme.REASON)
	why_label.custom_minimum_size.x = WHY_WIDTH
	row.add_child(why_label)


func _buy_bulk(id: String) -> void:
	var result := Shop.buy_bulk(_state, id)
	_say(result.text)
	if not result.ok:
		_sfx(SfxLibrary.CANCEL)
		return
	_sfx(SfxLibrary.ACCEPT)
	changed.emit()
	_show_page("buy", id)


## Name with the count carried, the price paid, and why it can't be sold if so.
func _add_sell_row(id: String) -> void:
	var row := _row()
	var why := Shop.sell_problem(_state, id, _shop_id)
	var count := Shop.sell_count(_state, id)
	var text := Shop.display_name(id) if count <= 1 else "%s ×%d" % [Shop.display_name(id), count]
	var button := _button(text)
	button.custom_minimum_size.x = TOUCH_NAME_WIDTH if Device.is_touch() else NAME_WIDTH
	button.disabled = why != ""
	button.pressed.connect(_sell.bind(id))
	button.set_meta("id", id)
	row.add_child(button)
	var price := _label("%d G" % Shop.sell_price(id, _shop_id),
		UiTheme.REASON if why != "" else UiTheme.MONEY)
	price.custom_minimum_size.x = PRICE_WIDTH
	row.add_child(price)
	if not Shop.is_equipment(id):
		UiStyle.add_description(row, id)
	if why != "":
		row.add_child(_label(why, UiTheme.REASON))


## Green ▲ and +n when better, red ▼ and -n when worse, "=" when the same (also used by
## the Equipo page of the pause menu).
static func comparison(diff: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", UiTokens.SPACE_1)
	if diff == 0:
		box.add_child(_make_label("="))
		return box
	var token := &"text-positive" if diff > 0 else &"text-negative"
	var arrow := Arrow.new(diff > 0, UiTokens.color(token))
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(arrow)
	box.add_child(_make_label("%+d" % diff, UiTheme.POSITIVE if diff > 0 else UiTheme.NEGATIVE))
	return box


func _buy(id: String) -> void:
	var result := Shop.buy(_state, id)
	_say(result.text)
	if not result.ok:
		_sfx(SfxLibrary.CANCEL)
		return
	_sfx(SfxLibrary.ACCEPT)
	changed.emit()
	if Allies.is_companion(id):
		_page = ""
		_left.emit()
	elif Shop.is_equipment(id):
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
	var result := Shop.sell(_state, id, _shop_id)
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
	if Shop.sells_ally(_shop_id):
		return
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


## The line under the list always keeps its place, so a message never moves the rows.
func _set_message(text: String) -> void:
	BattleHud.fit_label(_message, text, MESSAGE_WIDTH)


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTokens.SPACE_3)
	_rows.add_child(row)
	return row


func _add_button(text: String, action: Callable) -> void:
	var button := _button(text)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	_rows.add_child(button)


func _add_footer_button(text: String, pressed: Callable) -> void:
	var button := _button(text)
	button.pressed.connect(pressed)
	_footer.add_child(button)


## The buttons of the page: the rows first, then the footer.
func _page_buttons() -> Array[Node]:
	var buttons := _rows.find_children("*", "Button", true, false)
	buttons.append_array(_footer.find_children("*", "Button", true, false))
	return buttons


func _focus_first() -> void:
	_quiet_focus = true
	for button in _page_buttons():
		if not (button as Button).disabled:
			(button as Button).grab_focus()
			break
	_quiet_focus = false


func _focus_row(text: String) -> void:
	_quiet_focus = true
	for button in _page_buttons():
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
	UiTheme.menu_row(button)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_entered.connect(func() -> void:
		if not _quiet_focus:
			_sfx(SfxLibrary.CURSOR))
	return button


func _label(text: String, variation := &"") -> Label:
	return _make_label(text, variation)


static func _make_label(text: String, variation := &"") -> Label:
	var label := Label.new()
	label.text = text
	if variation != &"":
		label.theme_type_variation = variation
	return label


func _sfx(id: String) -> void:
	if _audio:
		_audio.play_sfx(id)
