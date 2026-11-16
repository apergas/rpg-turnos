class_name GameVersion extends RefCounted
## The game's version, "mayor.menor.parche" (application/config/version): the one this build
## is (current(), which UiTheme.version_label() shows). Pure: no nodes.

const SETTING := "application/config/version"


static func current() -> String:
	return String(ProjectSettings.get_setting(SETTING))
