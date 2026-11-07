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
		mark();
		reg.addEventListener('updatefound', function () {
			if (reg.installing) { reg.installing.addEventListener('statechange', mark); }
		});
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


static func is_ready() -> bool:
	return OS.has_feature("web") and JavaScriptBridge.eval(FLAG + " === true", true) == true


static func apply() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(APPLY_JS, true)
