class_name WebUpdate extends RefCounted
## A new deploy of the web build: its service worker installs and waits until every tab is
## closed, so a player can stay on the old version for good. This notices one waiting and
## tells it to take over, which reloads the page. Off the web it does nothing.

const FLAG := "window.villaclaroUpdate"
const WATCH_JS := """
window.villaclaroUpdate = false;
if ('serviceWorker' in navigator) {
	navigator.serviceWorker.getRegistration().then(function (reg) {
		if (!reg) { return; }
		var mark = function () { if (reg.waiting) { window.villaclaroUpdate = true; } };
		var follow = function () {
			if (reg.installing) { reg.installing.addEventListener('statechange', mark); }
		};
		mark();
		follow();
		reg.addEventListener('updatefound', follow);
		reg.update();
	});
}
"""
const APPLY_JS := """
navigator.serviceWorker.getRegistration().then(function (reg) {
	if (reg && reg.waiting) { reg.waiting.postMessage('update'); }
});
"""


static func watch() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(WATCH_JS, true)


## eval() hands a JavaScript boolean back as 1 or 0, which can't be compared with a bool.
static func is_ready() -> bool:
	return OS.has_feature("web") and int(JavaScriptBridge.eval(FLAG + " ? 1 : 0", true)) == 1


static func apply() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(APPLY_JS, true)
