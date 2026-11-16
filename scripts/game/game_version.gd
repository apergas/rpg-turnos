class_name GameVersion extends RefCounted
## The game's version, "mayor.menor.parche" (application/config/version): the one this build
## is (current(), which UiTheme.version_label() shows) and how a published one compares with it
## (check(), for WebUpdate). Pure: no nodes.

## check()'s answer: the published version is not newer, it is newer, or one of the two can't
## be read.
enum Check { LATEST, NEWER, UNKNOWN }

const SETTING := "application/config/version"
const DIGITS := "0123456789"


static func current() -> String:
	return String(ProjectSettings.get_setting(SETTING))


## The three numbers of text ("3.10.0" -> [3, 10, 0]; spaces around it are ignored), or [] if
## it is not three whole numbers, digits only, joined by dots.
static func parse(text: String) -> Array[int]:
	var numbers: Array[int] = []
	var parts := text.strip_edges().split(".")
	if parts.size() != 3:
		return numbers
	for part in parts:
		if part.is_empty() or part.lstrip(DIGITS) != "":
			numbers.clear()
			return numbers
		numbers.append(part.to_int())
	return numbers


## Compares published with mine number by number, so 3.10.0 is newer than 3.9.2: NEWER only if
## published is greater, LATEST if it is the same or older, UNKNOWN if either can't be read.
static func check(published: String, mine: String) -> Check:
	var theirs := parse(published)
	var ours := parse(mine)
	if theirs.is_empty() or ours.is_empty():
		return Check.UNKNOWN
	for i in theirs.size():
		if theirs[i] != ours[i]:
			return Check.NEWER if theirs[i] > ours[i] else Check.LATEST
	return Check.LATEST
