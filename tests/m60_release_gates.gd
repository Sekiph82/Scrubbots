extends SceneTree
## M60 release gates (SB-M60-001..006) + M43 closure gate (SB-M43-170), computed against the REAL
## app root (main.tscn) on throw-away saves and the surface manifest / registry:
##   SB-M60-001 every Home button, BottomNav tab, HUD +, notification deep link, gameplay HUD
##       control (Pause, 2x, boosters) and Results button leads to a live surface; every
##       ui_surface_registry route source is walked and lands on its registry destination; no
##       shipping script reaches the debug harness
##   SB-M60-002 every PLAYER_EXPERIENCE_ASSET_MANIFEST surface is bound (script + live data +
##       existing evidence suite) or explicitly not built with a gap; the registry is covered; no
##       placeholder / dummy / lorem / TODO copy in the shipped English table
##   SB-M60-003 a brand-new save (shipping FTUE + Level Intro policy, no debug / test unlock):
##       first Home, Welcome task claimed through the real TASKS popup, L1 -> L3 played for real
##       (RealPlayDriver human policy on the shipped host) through Results CLEAN NEXT, tutorial
##       window closed at L4
##   SB-M60-004 no ad / store provider: Shop SB packs + No Ads, Home SB +, Life / Rewarded Ads
##       video offers are honestly UNAVAILABLE and pressing them grants or charges nothing
##   SB-M60-005 Events L30 / Ranks L40 gate on real frontier saves, Ranks counts only cleared
##       campaign levels; the owner two-table RANKS (all-time + weekly) is checked for, not assumed
##   SB-M60-006 + SB-M43-170: the results above + the owner-only gates + the M43 closure lists
##       computed from the manifest must equal docs/RELEASE_GATES.json / .md (an edited or stale
##       report fails; regenerate with `-- --write`). A FAIL / BLOCKED / OPEN gate is reported,
##       never turned into a suite failure or a PASS.
##
## Run:        godot --headless --path . -s res://tests/m60_release_gates.gd
## Regenerate: godot --headless --path . -s res://tests/m60_release_gates.gd -- --write

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const NotificationPolicy = preload("res://scripts/economy/notification_policy.gd")
const RewardedAdProvider = preload("res://scripts/economy/rewarded_ad_provider.gd")
const RealPlayDriver = preload("res://scripts/gameplay/solver/real_play_driver.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const PersonalRank = preload("res://scripts/progression/personal_rank.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const MANIFEST := "res://assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json"
const REGISTRY := "res://data/config/ui_surface_registry_v1.json"
const UNLOCKS := "res://data/config/feature_unlocks_v1.json"
const REPORT_JSON := "res://docs/RELEASE_GATES.json"
const REPORT_MD := "res://docs/RELEASE_GATES.md"
const T0 := 1790000000
const BOOSTERS := ["plus_one_slot", "random", "selector", "tornado"]
## ModalStack popup id -> ui_surface_registry id where they differ (Booster Acquire is booster_<id>).
const POPUP_ALIAS := {"daily_login": "daily"}
## Copy that must never ship (whole words, case-insensitive) in the English table.
const PLACEHOLDER := "\\b(placeholder|dummy|lorem|ipsum|todo|tbd|fixme|xxx|test copy)\\b"
## Shipping script roots that must not reach the developer debug harness.
const SHIPPING_DIRS := ["res://scripts/app", "res://scripts/ui", "res://scripts/economy", "res://scripts/progression", "res://scripts/gameplay", "res://scripts/save"]
## Owner-only gates: facts recorded by hand (nothing the suite can observe from inside Godot).
const OWNER_GATES := [
	{"id": "OWNER-SIGNING", "title": "Store signing secrets (Android release keystore, Apple distribution certificate + profile)", "status": "BLOCKED", "blocked_by": "owner",
		"evidence": "`gh secret list` 2026-11-09 shows only ANDROID_DEBUG_KEYSTORE_*; ANDROID_RELEASE_KEYSTORE_* and IOS_DIST_CERT_* / IOS_PROVISIONING_PROFILE_BASE64 / IOS_TEAM_ID are missing (docs/RELEASE_BUILDS.md Owner-only steps). Release runs stop before export until the owner adds them."},
	{"id": "OWNER-STORE-SUBMISSION", "title": "Store submission / public production release", "status": "BLOCKED", "blocked_by": "owner",
		"evidence": "CLAUDE.md 0D.5: a public production store release is owner-only. No workflow uploads to Google Play or the App Store; the release APK is not an AAB (store-release work stays with the owner)."},
	{"id": "OWNER-VISUAL-SIGNOFF", "title": "Owner visual sign-off of the M43 player-facing surfaces", "status": "BLOCKED", "blocked_by": "owner",
		"evidence": "No manifest surface is OWNER_ACCEPTED (see the SB-M43-170 lists below); most still need a visual master first (MASTER_REQUIRED, factory work). Masters approved by Claude under delegated authority are not owner visual review."},
	{"id": "OWNER-DEVICE-TESTS", "title": "Real-device tests (Android Galaxy A10, iPhone)", "status": "BLOCKED", "blocked_by": "owner",
		"evidence": "TASKS.md OWNER rows SB-M42-032, SB-M47-005..010, SB-M47-011..015 wait for the Galaxy A10 to be plugged in; SB-M57-022 sandbox purchases / rewarded ads need a real device and live providers."},
]
## SB-M60-006 regression gate: the M49..M59 rows still open in the TASKS.md queue (by hand).
const REGRESSION_OPEN := "SB-M50-012..018, SB-M54-031/032/037/038, SB-M56-011/017..023, SB-M57-001..016/022, SB-M58-007..014, SB-M59-006..011 are READY (not done); no CI validation run on a release-candidate commit was made for this report (no workflow run in factory 132)."

var EXPECTED_CASES := ["g001_dead_routes", "g002_bound_surfaces", "g003_fresh_save_ftue", "g004_providers_disabled", "g005_events_ranks_policy", "g006_report"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [T0]
var _day := [20000]
## gate id -> {"title", "checks": [[name, ok, evidence]]}
var _gates: Dictionary = {}
var _gate_order: Array = []

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	await _g001()
	_g002()
	await _g003()
	await _g004()
	await _g005()
	_g006()
	_shutdown()
	_cleanup()
	_done()

# ----------------------------------------------------------------- SB-M60-001 --

func _g001() -> void:
	var g := _gate("SB-M60-001", "No dead routes: every Home / BottomNav / HUD + / deep link / gameplay control / Results route leads to a live surface")
	print("[g001 dead routes on the real app root]")
	AppStateScript.test_unlock_all = true   # walk every destination (the L1 gate itself is SB-M60-005 / m44_unlock_gate)
	await _boot("g001")
	var nav = _root.get_navigation()
	var ms = _root.get_modal_stack()
	var home = _root.get_home()
	var reached: Dictionary = {}   # destination -> button
	var dead: Array = []
	var names: Array = []
	for b in home.find_children("*", "BaseButton", true, false):
		if b.is_visible_in_tree() and not b.disabled:
			names.append(home.get_path_to(b))
	for p in names:
		var b = home.get_node_or_null(p)
		if b == null or not b.is_visible_in_tree() or b.disabled:
			continue
		b.pressed.emit()
		await _frames(4)
		var dest := _destination()
		if dest.is_empty():
			dead.append(String(b.name))
		else:
			reached[dest] = String(b.name)
		await _reset_home()
	print("    home buttons -> %s" % str(reached))
	_check(g, "home_buttons", dead.is_empty() and names.size() >= 10, "%d enabled Home buttons pressed, each opened a surface: %s; dead %s" % [names.size(), _sorted_keys(reached), str(dead)])
	var tabs_off: Array = []
	for id in ["events", "robots", "leaderboard"]:
		var nb: Button = home.get_region("Nav_" + id)
		if nb.disabled:
			tabs_off.append(id)
	var home_tab_current: bool = home.get_region("Nav_home").disabled and home.get_region("Nav_home").button_pressed
	_check(g, "nav_tabs_live", tabs_off.is_empty(), "with every feature unlocked no BottomNav tab is disabled / COMING LATER %s" % str(tabs_off))
	var links: Dictionary = {}
	var dead_links: Array = []
	for d in NotificationPolicy.DESTINATIONS:
		var got: String = _root.open_deep_link(d)
		await _frames(4)
		var dest := _destination()
		links[d] = dest
		if got != d or (d != "home" and dest.is_empty()):
			dead_links.append(d)
		await _reset_home()
	_check(g, "deep_links", dead_links.is_empty(), "every notification deep link opens its surface %s; dead %s" % [str(links), str(dead_links)])
	# Zero Hearts: PLAY opens the canonical Life popup and launches nothing.
	var app = _root.get_app_state()
	while app.economy.hearts.hearts() > 0:
		app.economy.hearts.consume()
	home.get_region("PlayButton").pressed.emit()
	await _frames(4)
	var zero := _destination()
	# Gameplay HUD on a new save (full Hearts, no starter charges outside the FTUE bootstrap):
	# Pause, 2x, the four boosters, then Results WON / LOST buttons.
	var hud: Dictionary = {}
	await _boot("g001_play")
	app = _root.get_app_state()
	nav = _root.get_navigation()
	ms = _root.get_modal_stack()
	_root.get_home().get_region("PlayButton").pressed.emit()
	await _frames(6)
	var host = _root.get_gameplay_host()
	var gp_ok: bool = host != null and nav.current() == NavigationController.Route.GAMEPLAY
	if gp_ok:
		host.get_runtime().set_process(false)
		var s = host.get_screen()
		var controls := {"pause": s.get_pause_button(), "speed": s.get_speed_button()}
		for id in BOOSTERS:
			controls["booster_" + id] = s.get_booster_button(id)
		for k in controls:
			controls[k].pressed.emit()
			await _frames(4)
			hud[k] = _destination()
			ms.clear("test")
			await _frames(2)
	var hud_dead: Array = hud.keys().filter(func(k): return String(hud[k]).is_empty())
	_check(g, "gameplay_hud", gp_ok and hud.size() == 6 and hud_dead.is_empty(), "Home PLAY -> GAMEPLAY; HUD controls -> %s; dead %s" % [str(hud), str(hud_dead)])
	# Results through the real completion signal (the established terminal test seam; real wins: g003).
	var res := {}
	var rs = _root.get_results_screen()
	if gp_ok:
		var lv := int(host.progression_level)
		res["won"] = await _terminal(host, &"WON", rs.get_primary_button())
		rs.get_primary_button().pressed.emit()
		await _frames(6)
		host = _root.get_gameplay_host()
		res["clean_next"] = nav.current() == NavigationController.Route.GAMEPLAY and host != null and int(host.progression_level) == lv + 1
		if res["clean_next"]:
			host.get_runtime().set_process(false)
			res["lost"] = await _terminal(host, &"LOST", rs.get_primary_button())
			rs.get_primary_button().pressed.emit()
			await _frames(6)
			host = _root.get_gameplay_host()
			res["retry"] = nav.current() == NavigationController.Route.GAMEPLAY and host != null and int(host.progression_level) == lv + 1
			if res["retry"]:
				host.get_runtime().set_process(false)
				res["lost_again"] = await _terminal(host, &"LOST", rs.get_home_button())
				rs.get_home_button().pressed.emit()
				await _frames(4)
				res["home"] = nav.current() == NavigationController.Route.HOME
	var res_ok: bool = res.size() == 6 and res.values().all(func(v): return v == true)
	_check(g, "results_buttons", res_ok, "WON -> Results, CLEAN NEXT -> next level; LOST -> Results, RETRY -> same level; LOST -> Results, HOME -> Home %s" % str(res))
	# Registry ledger: every route source is walked and lands on its registry destination.
	var reg = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY))
	# Route source -> where its press landed in this walk (Home buttons by node name).
	var landed: Dictionary = {}
	for d in reached:
		landed[reached[d]] = d
	var boosters_landed: Array = BOOSTERS.map(func(b): return hud.get("booster_" + b, ""))
	var observed := {"home.shortcut_shop": landed.get("Shortcut_shop"), "home.shortcut_collection": landed.get("Shortcut_collection"),
		"home.shortcut_tasks": landed.get("Shortcut_tasks"), "home.shortcut_daily": landed.get("Shortcut_daily"),
		"home.scrub_bucks_plus": landed.get("ScrubBucksPlus"), "home.heart_plus": landed.get("HeartsPlus"),
		"home.gift_meter": landed.get("GiftMeterButton"), "home.rewarded_ads": landed.get("RewardedAdsButton"), "home.play": landed.get("PlayButton"),
		"home.profile": landed.get("ProfileButton"), "bottom_nav.events": landed.get("Nav_events"), "bottom_nav.robots": landed.get("Nav_robots"),
		"bottom_nav.home": "home" if home_tab_current else null,   # the current tab ("already here")
		"bottom_nav.ranks": landed.get("Nav_leaderboard"), "bottom_nav.settings": landed.get("SettingsButton"),
		"gameplay.pause": hud.get("pause"), "gameplay.speed_no_entitlement": hud.get("speed"),
		"gameplay.booster_no_charge": boosters_landed[0] if boosters_landed.all(func(x): return x == boosters_landed[0]) else null,
		"attempt.zero_hearts": zero, "results.clean_next": "gameplay" if res.get("clean_next", false) else null,
		"results.retry": "gameplay" if res.get("retry", false) else null, "results.home": "home" if res.get("home", false) else null}
	## Routes not reachable from a plain Home / HUD tap, walked by their own suites.
	var by_suite := {"progression.third_consecutive_fail": "tests/m43_c004_c001_fail_need_a_hand.gd",
		"collection.cards_exchange": "tests/m43_master_c007_collection.gd", "collection.pack_open": "tests/m43_master_c007_collection.gd",
		"reward.robot_unlock": "tests/m43_master_c005_meta_ceremonies.gd", "reward.world_unlock": "tests/m43_master_c005_meta_ceremonies.gd (builder; no live trigger yet, SB-M43-136..141)"}
	var unwalked: Array = []
	var bad_dest: Array = []
	var known: Array = reg["screens"] + reg["popups"]
	for r in reg["routes"]:
		var src := String(r["source"])
		var dst := String(r["destination"]).trim_prefix("popup:")
		if not known.has(dst):
			bad_dest.append(dst)
		if not (observed.get(src) == dst or by_suite.has(src)):
			unwalked.append("%s -> %s (registry %s)" % [src, str(observed.get(src)), dst])
	var unlisted: Array = observed.keys().filter(func(k): return not reg["routes"].any(func(r): return r["source"] == k))
	var walk_unlisted: Array = reached.keys().filter(func(d): return not known.has(d))
	_check(g, "registry_routes", unwalked.is_empty() and unlisted.is_empty() and walk_unlisted.is_empty() and bad_dest.is_empty(),
		"%d ui_surface_registry routes, each walked here or by its suite %s; failing / unwalked %s; walked but not in the registry %s; reached surfaces / route destinations outside the registry %s" % [reg["routes"].size(), str(by_suite.keys()), str(unwalked), str(unlisted), str(walk_unlisted + bad_dest)])
	# A debug surface = a scenes/debug scene or a scripts/debug script that is not a RefCounted
	# helper (the perf probe / fixtures are counters and data, never shown).
	var debug_refs: Array = []
	var re := RegEx.create_from_string("res://(scenes|scripts)/debug/[A-Za-z0-9_/]+\\.(tscn|gd)")
	var helper := RegEx.create_from_string("(?m)^extends RefCounted")
	for f in _scripts(SHIPPING_DIRS):
		for hit in re.search_all(FileAccess.get_file_as_string(f)):
			var dp := hit.get_string()
			if dp.ends_with(".tscn") or helper.search(FileAccess.get_file_as_string(dp)) == null:
				debug_refs.append("%s -> %s" % [f.trim_prefix("res://"), dp])
	_check(g, "no_debug_surface", debug_refs.is_empty(), "no shipping script under %s reaches a debug scene / debug UI script %s" % [str(SHIPPING_DIRS.map(func(d): return d.trim_prefix("res://"))), str(debug_refs)])
	AppStateScript.test_unlock_all = false
	_complete("g001_dead_routes")

## Where the last press landed: top popup id, "settings", "gameplay", a Home popup id, or "".
func _destination() -> String:
	var ms = _root.get_modal_stack()
	if ms.depth() > 0 and ms.top() != null:
		var id := String(ms.top().popup_id)
		return "booster_acquire" if id.begins_with("booster_") else String(POPUP_ALIAS.get(id, id))
	var nav = _root.get_navigation()
	if nav.is_settings_open():
		return "settings"
	if nav.current() == NavigationController.Route.GAMEPLAY:
		return "gameplay"
	var home = _root.get_home()
	for id in ["gift_bar", "cards_exchange", "daily"]:
		var p = home.get_popup(id)
		if p != null and p.visible:
			return "home_popup:" + id
	return ""

func _reset_home() -> void:
	_root.get_modal_stack().clear("test")
	var nav = _root.get_navigation()
	nav.close_settings()
	if nav.current() != NavigationController.Route.HOME:
		nav.go(NavigationController.Route.HOME)
	_root.get_home().close_top_popup()
	await _frames(3)
	_root.get_modal_stack().clear("test")
	await _frames(1)

## Emit the host's completion terminal; true when the app routed to a visible Results with `b`
## pressable and nothing stacked over it (closing any reward / ceremony popup first).
func _terminal(host, status: StringName, b: Button) -> bool:
	host.get_completion().terminal_reached.emit(status, {})
	await _frames(4)
	await _settle(b)
	return _root.get_navigation().current() == NavigationController.Route.RESULTS and _root.get_results_screen().visible

# ----------------------------------------------------------------- SB-M60-002 --

func _g002() -> void:
	var g := _gate("SB-M60-002", "Bound surfaces: every manifest surface is bound to live data or explicitly not built; no placeholder copy")
	print("[g002 bound surfaces + placeholder copy]")
	var m = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var bound: Array = []
	var planned: Array = []
	var bad: Array = []
	for s in m["surfaces"]:
		var i: Dictionary = s["implementation"]
		var scene = i.get("production_scene")
		var ev = i.get("evidence")
		var gap := String(i.get("gap")) if i.get("gap") != null else ""
		var scene_ok: bool = scene != null and FileAccess.file_exists("res://" + String(scene).get_slice(" ", 0))
		var ev_ok: bool = ev != null and FileAccess.file_exists("res://" + String(ev).get_slice(" ", 0))
		if scene_ok and ev_ok and bool(i.get("live_data", false)):
			bound.append(s["id"])
		elif not bool(i.get("live_data", false)) and not gap.is_empty() and (scene == null or scene_ok):
			planned.append("%s (%s)" % [s["id"], gap])
		else:
			bad.append("%s scene=%s evidence=%s live=%s" % [s["id"], str(scene), str(ev), str(i.get("live_data"))])
	_check(g, "manifest_bound", bad.is_empty(), "%d surfaces: %d bound (script + live data + evidence suite exist), %d explicitly not built: %s; unbound / broken %s" % [m["surfaces"].size(), bound.size(), planned.size(), str(planned), str(bad)])
	var reg = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY))
	var covered: Array = []
	for s in m["surfaces"]:
		covered.append(s["id"])
		covered.append_array(s.get("registry_ids", []))
	var missing: Array = (reg["screens"] + reg["popups"]).filter(func(id): return not covered.has(id))
	_check(g, "registry_covered", missing.is_empty(), "every ui_surface_registry screen / popup has a manifest surface; missing %s" % str(missing))
	var re := RegEx.create_from_string("(?i)" + PLACEHOLDER)
	var hits: Array = []
	for k in UiText.EN:
		if re.search(String(UiText.EN[k])) != null:
			hits.append(k)
	_check(g, "no_placeholder_copy", hits.is_empty(), "%d English UiText strings, none contains placeholder / dummy / lorem / TODO / TBD / FIXME copy %s" % [UiText.EN.size(), str(hits)])
	_complete("g002_bound_surfaces")

# ----------------------------------------------------------------- SB-M60-003 --

func _g003() -> void:
	var g := _gate("SB-M60-003", "Fresh-save FTUE: first Home, Welcome task, L1 -> L3 played for real, no debug tools")
	print("[g003 brand-new save: shipping FTUE + Level Intro policy, real play L1..L3]")
	MainScript.boot_ftue_override = 1
	MainScript.boot_level_intro_override = 1
	await _boot("g003")
	var app = _root.get_app_state()
	var nav = _root.get_navigation()
	var home = _root.get_home()
	var ms = _root.get_modal_stack()
	_root.refresh_coachmark()
	var cm = _root.get_coachmarks()
	_check(g, "first_home", nav.current() == NavigationController.Route.HOME and app.economy.ftue.is_new_profile() and app.progression.current_level() == 1
		and cm.get_step_id() == "home_daily" and not AppStateScript.test_unlock_all,
		"fresh profile boots to Home at L1 with the first-Home DAILY tip (route %s, step %s)" % [nav.route_name(), cm.get_step_id()])
	var sb0: int = app.economy.wallet.scrub_bucks()
	home.get_region("Shortcut_tasks").pressed.emit()
	await _frames(3)
	var tp = ms.top()
	var welcome: bool = tp != null and String(tp.popup_id) == "tasks" and app.economy.daily.is_welcome_task(0)
	if welcome:
		tp.get_action_button("task:0").pressed.emit()
		await _frames(3)
	_check(g, "welcome_task", welcome and app.economy.wallet.scrub_bucks() == sb0 + 100,
		"TASKS at first Home shows the Welcome task; CLAIM through the popup button: %d -> %d SB" % [sb0, app.economy.wallet.scrub_bucks()])
	ms.clear("test")
	await _frames(2)
	var cat = LevelCatalog.new()
	cat.load_manifest()
	var entries: Array = cat.get_entries_ordered()
	var prov := RealPlayDriver.load_provenance()
	var steps: Array = []
	var won_all := true
	home.get_region("PlayButton").pressed.emit()
	await _frames(6)
	for n in [1, 2, 3]:
		var host = _root.get_gameplay_host()
		if host == null or nav.current() != NavigationController.Route.GAMEPLAY or int(host.progression_level) != n:
			won_all = false
			steps.append("L%d: not launched (route %s)" % [n, nav.route_name()])
			break
		_root.refresh_coachmark()
		var tip: String = cm.get_step_id() if cm.is_showing() else "-"
		var e = entries[n - 1]
		var r: Dictionary = RealPlayDriver.play_on_host(host, RealPlayDriver.clicks_for(e.id, e.supply_plan_path, prov))
		await _frames(4)
		var to_results: bool = nav.current() == NavigationController.Route.RESULTS
		steps.append("L%d tip %s: %s -> %s" % [n, tip, "WON" if r.get("won", false) else "NOT WON", nav.route_name()])
		if not (r.get("won", false) and to_results):
			won_all = false
			break
		var rs = _root.get_results_screen()
		var b: Button = rs.get_primary_button() if n < 3 else rs.get_home_button()
		await _settle(b)
		b.pressed.emit()
		await _frames(6)
		await _drain_popups()
	_check(g, "l1_l3_real_play", won_all and nav.current() == NavigationController.Route.HOME and app.progression.current_level() == 4 and app.economy.ftue.closed,
		"L1..L3 under the human policy on the shipped host, Results CLEAN NEXT / HOME buttons: %s; at Home L%d, FTUE window closed %s" % [str(steps), app.progression.current_level(), str(app.economy.ftue.closed)])
	_check(g, "no_debug_tools", not AppStateScript.test_unlock_all and app.unlocks.cfg["unlocks"]["robots"] == 25,
		"no test unlock, no debug_set_current_level, no injected terminal: the shipped unlock table and real wins only")
	MainScript.boot_ftue_override = -1
	MainScript.boot_level_intro_override = -1
	_complete("g003_fresh_save_ftue")

## Close every popup a real win puts over Results (gift / pack ceremonies arrive after the reveal)
## until the Results button is pressable with nothing on top.
func _settle(b: Button) -> void:
	var ms = _root.get_modal_stack()
	var quiet := 0
	for _i in range(900):
		if ms.depth() > 0:
			quiet = 0
			await _drain_popups()
		elif not b.disabled and b.is_visible_in_tree():
			quiet += 1
			if quiet >= 30:
				return
		await process_frame

## Close what a real win puts on the stack (pack / ceremony / feedback) through its own button.
func _drain_popups() -> void:
	var ms = _root.get_modal_stack()
	for _i in range(12):
		var t = ms.top()
		if t == null:
			return
		var ids: Array = t.get_action_ids()
		var pick := ""
		for id in ["continue", "claim", "collect", "ok", "close", "done"]:
			if ids.has(id):
				pick = id
				break
		if pick.is_empty() and not ids.is_empty():
			pick = String(ids[0])
		if pick.is_empty():
			t.close("test")
		else:
			t.get_action_button(pick).pressed.emit()
		await _frames(6)

# ----------------------------------------------------------------- SB-M60-004 --

func _g004() -> void:
	var g := _gate("SB-M60-004", "Shop / ads / IAP with no provider: honest UNAVAILABLE states, nothing granted or charged")
	print("[g004 no store / ad provider]")
	await _boot("g004")
	var app = _root.get_app_state()
	var ms = _root.get_modal_stack()
	var home = _root.get_home()
	var e = app.economy
	var prov = e.rewarded.get_provider()
	_check(g, "no_provider", prov != null and prov.get_script() == RewardedAdProvider and not prov.is_available("rewarded_heart"),
		"rewarded provider is the production default RewardedAdProvider (no SDK): every placement unavailable")
	var snap := [e.wallet.scrub_bucks(), e.hearts.hearts()]
	home.get_region("Shortcut_shop").pressed.emit()
	await _frames(3)
	var shop = ms.top()
	var shop_ok: bool = shop != null and String(shop.popup_id) == "shop"
	if shop_ok:
		for pid in ["sb_pack", "no_ads"]:
			var b: Button = shop.get_action_button("buy:" + pid)
			var card = shop.find_child("Item_" + pid, true, false)
			var detail: Label = card.find_child("Detail", true, false) if card != null else null
			shop_ok = shop_ok and b.disabled and b.text == UiText.t("SHOP_UNAVAILABLE") and detail != null and detail.text == UiText.t("SHOP_STORE_LATER")
			b.pressed.emit()
			await _frames(2)
			shop_ok = shop_ok and ms.top() == shop
	_check(g, "shop_store_gated", shop_ok, "Shop SCRUB BUCKS packs + NO ADS: UNAVAILABLE / 'Available when the store opens.', press opens no confirm")
	ms.clear("test")
	await _frames(2)
	home.get_region("ScrubBucksPlus").pressed.emit()
	await _frames(3)
	var sbp = ms.top()
	var sbp_ok: bool = sbp != null and String(sbp.popup_id) == "scrub_bucks" and sbp.get_action_button("sb_pack").disabled
	if sbp_ok:
		sbp.get_action_button("sb_pack").pressed.emit()
		await _frames(2)
		sbp_ok = ms.top() == sbp
	_check(g, "sb_plus_gated", sbp_ok, "Home SB + popup: SB pack UNAVAILABLE and inert")
	ms.clear("test")
	e.hearts.consume()
	var h1: int = e.hearts.hearts()
	_root.open_life("home")
	await _frames(3)
	var life = ms.top()
	var life_ok: bool = life != null and String(life.popup_id) == "life" and life.get_action_button("watch").disabled
	if life_ok:
		life.get_action_button("watch").pressed.emit()
		await _frames(2)
		life_ok = e.hearts.hearts() == h1
	_check(g, "life_video_gated", life_ok, "Life popup FREE video blocked with no provider; press grants no Heart (%d)" % e.hearts.hearts())
	ms.clear("test")
	await _frames(2)
	home.get_region("RewardedAdsButton").pressed.emit()
	await _frames(3)
	var rads = ms.top()
	var rads_ok: bool = rads != null and String(rads.popup_id) == "rewarded_ads"
	var rows: Array = []
	if rads_ok:
		for id in rads.get_action_ids():
			if String(id).begins_with("slot:"):
				var b: Button = rads.get_action_button(id)
				rows.append(b.text)
				if b.text == UiText.t("RADS_NO_VIDEO"):
					rads_ok = rads_ok and b.disabled
				b.pressed.emit()
		await _frames(2)
	rads_ok = rads_ok and rows.any(func(t): return t == UiText.t("RADS_NO_VIDEO"))
	_check(g, "rewarded_ads_gated", rads_ok, "Rewarded Ads: video slots show NO VIDEO and are blocked %s" % str(rows))
	ms.clear("test")
	await _frames(2)
	var after := [e.wallet.scrub_bucks(), e.hearts.hearts()]
	_check(g, "nothing_charged", after[0] >= snap[0] and after[1] == h1, "SB %d -> %d (free daily slot grants only), Hearts %d after the one consumed -> %d: no purchase, no ad reward" % [snap[0], after[0], h1, after[1]])
	_complete("g004_providers_disabled")

# ----------------------------------------------------------------- SB-M60-005 --

func _g005() -> void:
	var g := _gate("SB-M60-005", "Events / Ranks shipping policy (owner: Events L30, Ranks L40, RANKS all-time + weekly)")
	print("[g005 Events L30 / Ranks L40 on real frontier saves]")
	var cfg = JSON.parse_string(FileAccess.get_file_as_string(UNLOCKS))
	_check(g, "unlock_table", int(cfg["unlocks"]["events"]) == 30 and int(cfg["unlocks"]["ranks"]) == 40, "feature_unlocks_v1.json: events %d, ranks %d" % [int(cfg["unlocks"]["events"]), int(cfg["unlocks"]["ranks"])])
	var edges := {}
	for frontier in [29, 30, 39, 40]:
		var path := _path("g005_%d" % frontier)
		var a = AppStateScript.new(path, MainScript.boot_clock_override, MainScript.boot_local_day_override)
		for n in range(1, frontier):
			a.progression.record_win(n)
		a.flush()
		await _boot("g005_%d" % frontier, path)
		var app = _root.get_app_state()
		var home = _root.get_home()
		var ms = _root.get_modal_stack()
		var row := {"level": app.progression.current_level()}
		for pair in [["events", "Nav_events", "events"], ["ranks", "Nav_leaderboard", "leaderboard"]]:
			var nb: Button = home.get_region(pair[1])
			nb.pressed.emit()
			await _frames(3)
			row[pair[0]] = [app.feature_unlocked(pair[0]), not nb.disabled, ms.depth() > 0 and String(ms.top().popup_id) == pair[0]]
			ms.clear("test")
			await _frames(1)
		row["events_link"] = _root.open_deep_link("events")
		ms.clear("test")
		edges[frontier] = row
	var ok: bool = edges[29]["events"] == [false, false, false] and edges[29]["events_link"] == "home" and edges[30]["events"] == [true, true, true] and edges[30]["events_link"] == "events" \
		and edges[39]["ranks"] == [false, false, false] and edges[40]["ranks"] == [true, true, true] and edges[29]["level"] == 29
	_check(g, "unlock_edges", ok, "frontier 29/30/39/40 [unlocked, tab enabled, tap opens]: %s" % str(edges))
	_check(g, "ranks_metric", PersonalRank.METRIC == "campaign_levels_cleared", "Ranks count only cleared campaign levels (PersonalRank.METRIC %s): nothing bought with money or boosters counts" % PersonalRank.METRIC)
	await _boot("g005_ranks", _tmp[_tmp.size() - 1])
	_root.get_home().get_region("Nav_leaderboard").pressed.emit()
	await _frames(3)
	var rp = _root.get_modal_stack().top()
	var two_tables: bool = rp != null and rp.find_child("AllTime*", true, false) != null and rp.find_child("Weekly*", true, false) != null
	_check(g, "ranks_two_tables", two_tables, "owner 2026-10-22 RANKS = all-time (highest level) + weekly (levels this week, Monday 00:00 UTC) tables: %s" % ("built" if two_tables else "NOT built - the live Ranks tab is the personal rank ladder (SB-M43-122); SB-M43-131..133 READY"))
	_root.get_modal_stack().clear("test")
	_complete("g005_events_ranks_policy")

# ----------------------------------------------------------------- SB-M60-006 --

func _g006() -> void:
	print("[g006 report: computed gates == docs/RELEASE_GATES.json / .md]")
	var report := _report()
	var json := JSON.stringify(report, "  ") + "\n"
	var md := _markdown(report)
	if OS.get_cmdline_user_args().has("--write"):
		_write(REPORT_JSON, json)
		_write(REPORT_MD, md)
		print("    wrote %s and %s" % [REPORT_JSON, REPORT_MD])
	_ok(_same(REPORT_JSON, json), "%s equals the computed gates (regenerate with -- --write)" % REPORT_JSON)
	_ok(_same(REPORT_MD, md), "%s equals the computed gates" % REPORT_MD)
	var closure: Dictionary = report["m43_closure_gate"]
	_ok(closure["status"] == "OPEN" or (closure["not_owner_accepted"].is_empty() and closure["not_built"].is_empty() and closure["not_live"].is_empty()), "SB-M43-170 is %s: %d of %d surfaces not OWNER_ACCEPTED" % [closure["status"], closure["not_owner_accepted"].size(), closure["surfaces"]])
	for gt in report["gates"]:
		print("    %s %s" % [gt["status"], gt["id"]])
	_complete("g006_report")

func _report() -> Dictionary:
	var gates: Array = []
	for id in _gate_order:
		var checks: Array = _gates[id]["checks"].map(func(c): return {"check": c[0], "result": "PASS" if c[1] else "FAIL", "evidence": c[2]})
		gates.append({"id": id, "title": _gates[id]["title"], "kind": "automated", "status": "PASS" if checks.all(func(c): return c["result"] == "PASS") else "FAIL", "checks": checks})
	gates.append({"id": "SB-M60-006", "title": "Release build passes the full M49..M58 player-experience, economy, device, compliance and regression gates", "kind": "aggregate",
		"status": "FAIL", "checks": [{"check": "open_rows", "result": "FAIL", "evidence": REGRESSION_OPEN}]})
	for o in OWNER_GATES:
		gates.append({"id": o["id"], "title": o["title"], "kind": "owner", "status": o["status"], "blocked_by": o["blocked_by"], "checks": [{"check": "owner", "result": "BLOCKED", "evidence": o["evidence"]}]})
	var m = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var not_accepted: Array = []
	var master_required: Array = []
	var not_built: Array = []
	var not_live: Array = []
	var by_status := {}
	for s in m["surfaces"]:
		var st := String(s["status"])
		by_status[st] = int(by_status.get(st, 0)) + 1
		if st != "OWNER_ACCEPTED":
			not_accepted.append("%s:%s" % [s["id"], st])
		if st.begins_with("MASTER_REQUIRED"):
			master_required.append(s["id"])
		if s["implementation"]["production_scene"] == null:
			not_built.append(s["id"])
		elif not bool(s["implementation"]["live_data"]):
			not_live.append(s["id"])
	var open: bool = not (not_accepted.is_empty() and not_built.is_empty() and not_live.is_empty())
	return {"schema": "scrubbots.release_gates.v1", "suite": "tests/m60_release_gates.gd",
		"release_ready": gates.all(func(x): return x["status"] == "PASS"),
		"gates": gates,
		"m43_closure_gate": {"task": "SB-M43-170", "status": "OPEN" if open else "CLOSABLE_AFTER_OWNER_REVIEW", "surfaces": m["surfaces"].size(), "by_status": by_status,
			"not_owner_accepted": not_accepted, "master_required": master_required, "not_built": not_built, "not_live": not_live,
			"debug_only": [], "rule": "No M43 program closure while any required surface is missing, visually unreviewed (not OWNER_ACCEPTED), wired to dummy data or reachable only through debug tooling."}}

func _markdown(r: Dictionary) -> String:
	var L: Array = ["# Release gates (SB-M60-001..006, SB-M43-170)", "",
		"Generated by `tests/m60_release_gates.gd -- --write`; the suite fails when this file or `docs/RELEASE_GATES.json` differs from what it computes. PASS / FAIL come from the suite run on the real app root; BLOCKED gates need the owner (CLAUDE.md 0D.5). Nothing here is owner acceptance.", "",
		"Release ready: **%s**" % ("YES" if r["release_ready"] else "NO"), "", "| Gate | Status | Title |", "|---|---|---|"]
	for g in r["gates"]:
		L.append("| %s | %s%s | %s |" % [g["id"], g["status"], (" (" + g["blocked_by"] + ")") if g.has("blocked_by") else "", g["title"]])
	for g in r["gates"]:
		L.append_array(["", "## %s: %s" % [g["id"], g["status"]], ""])
		for c in g["checks"]:
			L.append("- %s `%s`: %s" % [c["result"], c["check"], c["evidence"]])
	var c: Dictionary = r["m43_closure_gate"]
	L.append_array(["", "## SB-M43-170 M43 closure gate: %s" % c["status"], "", c["rule"], "",
		"- surfaces: %d, by status %s" % [c["surfaces"], JSON.stringify(c["by_status"])],
		"- not OWNER_ACCEPTED (%d): %s" % [c["not_owner_accepted"].size(), ", ".join(c["not_owner_accepted"])],
		"- MASTER_REQUIRED (%d): %s" % [c["master_required"].size(), ", ".join(c["master_required"])],
		"- not built (%d): %s" % [c["not_built"].size(), ", ".join(c["not_built"])],
		"- built but not live (%d): %s" % [c["not_live"].size(), ", ".join(c["not_live"])],
		"- reachable only through debug tooling: none (SB-M60-001 `no_debug_surface`)"])
	return "\n".join(L) + "\n"

# ------------------------------------------------------------------ helpers --

func _gate(id: String, title: String) -> String:
	_gates[id] = {"title": title, "checks": []}
	_gate_order.append(id)
	return id

## A gate check: recorded in the report (a FAIL here is a release finding, not a suite failure;
## the report comparison in g006 is what fails the suite).
func _check(g: String, name: String, ok: bool, evidence: String) -> void:
	_gates[g]["checks"].append([name, ok, evidence])
	print("  %s %s/%s: %s" % ["ok:" if ok else "GATE-OPEN", g, name, evidence])

func _sorted_keys(d: Dictionary) -> String:
	var k: Array = d.keys()
	k.sort()
	return str(k)

func _scripts(dirs: Array) -> Array:
	var out: Array = []
	for d in dirs:
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				out.append(d + "/" + f)
		for sub in DirAccess.get_directories_at(d):
			out.append_array(_scripts([d + "/" + sub]))
	return out

func _same(path: String, text: String) -> bool:
	return FileAccess.file_exists(path) and FileAccess.get_file_as_string(path).replace("\r\n", "\n") == text

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text.replace("\n", "\r\n"))
	f.close()

func _path(tag: String) -> String:
	var p := "user://m60_gates_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _boot(tag: String, path := "") -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path if not path.is_empty() else _path(tag)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	AppStateScript.test_unlock_all = false
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
	MainScript.boot_ftue_override = -1
	MainScript.boot_level_intro_override = -1
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("M60 release gates evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
