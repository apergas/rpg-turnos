class_name Device extends RefCounted
## Whether the game runs on a phone or tablet. Only the web build gets there; `--touch` fakes
## it on the desktop, with the mouse acting as a finger, to check the layout. A laptop with a
## touch screen is not one: it keeps the desktop interface. iPads say they are Macs, but Macs
## have no touch screen.

static func is_touch() -> bool:
	if OS.get_cmdline_user_args().has("--touch"):
		return true
	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	return OS.has_feature("web_macos") and DisplayServer.is_touchscreen_available()


static func is_ios() -> bool:
	return OS.has_feature("web_ios") or OS.has_feature("web_macos")
