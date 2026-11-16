class_name WebUpdate extends Node
## Node, a piece of Game, and the web build's updates; off the web (available() false) it does
## nothing. Two ways a new deploy reaches a player:
## - The title screen (static, no session): a new service worker installs and waits until
##   every tab is closed, so a player could stay on the old version for good. watch() notices
##   one waiting, is_ready() says so and apply() tells it to take over, which reloads the page.
## - The pause menu's «Buscar actualizaciones» (3.7.0): setup() gets the SessionContext and the
##   PauseMenu and wires both ways (the menu only asks and shows). check() reads VERSION_FILE,
##   which pages.yml writes next to the page, with an HTTPRequest child, and GameVersion.check()
##   compares. install() saves like «Guardar», clears this game's caches (cache_prefix()),
##   unregisters this page's service worker, downloads the new files past the HTTP cache and
##   reloads; the engine installs the worker again on start. Never stores Game or a World.

## A line for the pause menu's message (PauseMenu.show_update_line()).
signal reported(text: String)
## A newer version is published (PauseMenu.show_update_found()).
signal found(version: String)

const VERSION_FILE := "version.json"
## Seconds the server has to answer before the check counts as failed.
const CHECK_TIMEOUT := 10.0
const SEARCHING_TEXT := "Buscando actualizaciones…"
const LATEST_TEXT := "Ya tienes la versión más reciente (v%s)."
const UNKNOWN_TEXT := "No se ha podido comprobar. Mira tu conexión."
const DOWNLOADING_TEXT := "Descargando la versión nueva…"
const DOWNLOAD_FAILED_TEXT := "No se ha podido descargar. Inténtalo más tarde."
const SAVE_FAILED_TEXT := "No se pudo guardar."
## The export names its worker's caches after the first CACHE_NAME_LENGTH characters of
## application/config/name: "Villaclaro: la N-sw-cache-<build>". The origin
## (apergas.github.io) is shared with other projects: only these are ever deleted.
const CACHE_NAME_LENGTH := 16
## Where install()'s JavaScript finds its answer (a JavaScriptBridge callback).
const DONE_NAME := "villaclaroUpdateDone"
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
## install()'s JavaScript, formatted with the cache prefix as a JSON string. The old worker
## keeps answering this page until it reloads and serves index.* from its cache whatever the
## request asks, so its caches go first. It then unregisters the worker only if its scope is
## this page's own directory (the origin is shared). It fetches the files the worker lists one
## after another from the network (cache 'reload' refreshes the HTTP cache too), draining each
## body without keeping it, so no ~45 MB sits in memory; a bad status fails. The old worker
## stores them again, so the caches are cleared once more.
## Answers window.villaclaroUpdateDone(true), or (false) if anything failed.
const INSTALL_JS := """
(function (prefix) {
	var done = window.villaclaroUpdateDone;
	var page = location.href.split('#')[0];
	var files = [page, 'index.html', 'index.js', 'index.wasm', 'index.pck',
		'index.audio.worklet.js', 'index.audio.position.worklet.js', 'index.offline.html'];
	var clear = function () {
		if (!('caches' in window)) { return Promise.resolve(); }
		return caches.keys().then(function (keys) {
			return Promise.all(keys.filter(function (key) {
				return key.indexOf(prefix) === 0;
			}).map(function (key) { return caches.delete(key); }));
		});
	};
	var drain = function (reader) {
		return reader.read().then(function (chunk) {
			return chunk.done ? null : drain(reader);
		});
	};
	var download = function (name) {
		return fetch(new URL(name, page), {cache: 'reload'}).then(function (response) {
			if (!response.ok) { throw new Error(name + ': ' + response.status); }
			return drain(response.body.getReader());
		});
	};
	clear().then(function () {
		if (!('serviceWorker' in navigator)) { return false; }
		return navigator.serviceWorker.getRegistration().then(function (reg) {
			var own = new URL('./', location.href).href;
			return reg && reg.scope === own ? reg.unregister() : false;
		});
	}).then(function () {
		return files.reduce(function (chain, name) {
			return chain.then(function () { return download(name); });
		}, Promise.resolve());
	}).then(clear).then(function () { done(true); }, function (error) {
		console.error('Villaclaro update:', error);
		done(false);
	});
})(%s);
"""

var _ctx: SessionContext
var _request: HTTPRequest
var _checking := false
var _installing := false
## Kept alive: JavaScript calls it when install() ends (JavaScriptBridge.create_callback()).
var _install_done: JavaScriptObject


func setup(ctx: SessionContext, pause: PauseMenu) -> void:
	_ctx = ctx
	pause.update_check_requested.connect(check)
	pause.update_requested.connect(install)
	reported.connect(pause.show_update_line)
	found.connect(pause.show_update_found)


func _ready() -> void:
	# The pause menu pauses the tree, and its answer (and the timeout) must still come.
	process_mode = Node.PROCESS_MODE_ALWAYS


static func available() -> bool:
	return OS.has_feature("web")


static func cache_prefix() -> String:
	return String(ProjectSettings.get_setting("application/config/name")).substr(0,
		CACHE_NAME_LENGTH) + "-sw-cache-"


static func watch() -> void:
	if available():
		JavaScriptBridge.eval(WATCH_JS, true)


## eval() hands a JavaScript boolean back as 1 or 0, which can't be compared with a bool.
static func is_ready() -> bool:
	return available() and int(JavaScriptBridge.eval(FLAG + " ? 1 : 0", true)) == 1


static func apply() -> void:
	if available():
		JavaScriptBridge.eval(APPLY_JS, true)


## Asks for VERSION_FILE; nothing while a check or an install is under way.
func check() -> void:
	if not available() or _checking or _installing:
		return
	if _request == null:
		_request = HTTPRequest.new()
		_request.timeout = CHECK_TIMEOUT
		_request.request_completed.connect(_on_version_read)
		add_child(_request)
	reported.emit(SEARCHING_TEXT)
	if _request.request(_version_url()) != OK:
		reported.emit(UNKNOWN_TEXT)
		return
	_checking = true


## VERSION_FILE next to the page, with the time in its query so no HTTP cache answers for it
## (GitHub Pages sends max-age=600). It is in no list of the worker: the network serves it.
static func _version_url() -> String:
	var page := String(JavaScriptBridge.eval("location.href.split('#')[0].split('?')[0]", true))
	return "%s%s?t=%d" % [page.substr(0, page.rfind("/") + 1), VERSION_FILE,
		int(Time.get_unix_time_from_system() * 1000.0)]


## No answer, an error, a timeout or a body that is not {"version": "x.y.z"}: UNKNOWN.
func _on_version_read(result: int, code: int, _headers: PackedStringArray,
		body: PackedByteArray) -> void:
	_checking = false
	var published := ""
	var json := JSON.new()
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 \
			and json.parse(body.get_string_from_utf8()) == OK and json.data is Dictionary:
		var version: Variant = (json.data as Dictionary).get("version")
		if version is String:
			published = version
	match GameVersion.check(published, GameVersion.current()):
		GameVersion.Check.NEWER:
			found.emit(published.strip_edges())
		GameVersion.Check.LATEST:
			reported.emit(LATEST_TEXT % GameVersion.current())
		_:
			reported.emit(UNKNOWN_TEXT)


## «Actualizar»: saves like «Guardar», then INSTALL_JS; nothing while one is under way. A
## failed save stops it.
func install() -> void:
	if not available() or _installing:
		return
	var saved: Dictionary = _ctx.autosave.call(false)
	if saved.is_empty():
		reported.emit(SAVE_FAILED_TEXT)
		return
	_installing = true
	reported.emit(DOWNLOADING_TEXT)
	if _install_done == null:
		_install_done = JavaScriptBridge.create_callback(_on_install_done)
		JavaScriptBridge.get_interface("window").set(DONE_NAME, _install_done)
	JavaScriptBridge.eval(INSTALL_JS % JSON.stringify(cache_prefix()), true)


## INSTALL_JS's answer: everything new is in the HTTP cache and the old worker and its caches
## are gone, so the reload starts the new version; otherwise the old one goes on running.
func _on_install_done(args: Array) -> void:
	_installing = false
	if not args.is_empty() and bool(args[0]):
		JavaScriptBridge.eval("location.reload();", true)
		return
	reported.emit(DOWNLOAD_FAILED_TEXT)
