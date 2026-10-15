extends Control
## M45 developer debug harness — scene res://scenes/debug/m45_debug_gameplay.tscn (run with F6
## in the editor). DEVELOPER-ONLY, not reachable from the shipping app.
##
## Runs the REAL ProductionGameplayHost with NO AppState: the host's private economy, no save
## path, so nothing here can touch a player's save, progression or wallet (no player-facing
## level select; the shipping game stays forward-only, M37). Adds:
##   - GameplayDebugOverlay (model text + target / route / grid / effects toggles), SB-M45-001..015;
##   - INSTANT RESET = the host's existing transaction-safe Retry (SB-M45-016);
##   - LEVEL SWITCHER over the production LevelCatalog: rebuilds a fresh host from the entry's
##     level + SupplyPlan (SB-M45-017).

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const GameplayDebugOverlay = preload("res://scripts/debug/gameplay_debug_overlay.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")

var _catalog = null
var _host = null
var _overlay = null
var _entry_id := ""
var _picker: OptionButton
var _reset: Button
var _bar: HBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if not GameplayDebugOverlay.is_allowed():
		return   # exported template build: developer tooling stays inert (SB-M45-018)
	_catalog = LevelCatalog.new()
	_catalog.load_manifest()
	_overlay = GameplayDebugOverlay.new()
	add_child(_overlay)
	_bar = HBoxContainer.new()
	_bar.name = "DebugBar"
	_bar.position = Vector2(8, 300)
	_overlay.add_child(_bar)
	_picker = OptionButton.new()
	_picker.name = "LevelPicker"
	for e in _catalog.get_entries_ordered():
		_picker.add_item("%d %s" % [int(e.order), String(e.id)])
		_picker.set_item_metadata(_picker.item_count - 1, String(e.id))
	_picker.item_selected.connect(func(i): load_entry(String(_picker.get_item_metadata(i))))
	_bar.add_child(_picker)
	_reset = Button.new()
	_reset.name = "InstantReset"
	_reset.text = "RESET"
	_reset.pressed.connect(instant_reset)
	_bar.add_child(_reset)
	var entries: Array = _catalog.get_entries_ordered()
	if not entries.is_empty():
		load_entry(String(entries[0].id))

## Rebuild a fresh host for catalog entry `id`. True when the level is built and showing.
func load_entry(id: String) -> bool:
	var e = _catalog.get_entry_by_id(id) if _catalog != null else null
	if e == null:
		return false
	if _host != null and is_instance_valid(_host):
		remove_child(_host)
		_host.queue_free()
	_host = ProductionGameplayHost.new()
	_host.name = "DebugGameplayHost"
	_host.auto_build = false
	_host.level_path = String(e.level_path)
	_host.supply_plan_path = String(e.supply_plan_path)
	_host.progression_level = int(e.order)
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_host)
	move_child(_host, 0)   # under the overlay
	if not _host.build():
		return false
	_entry_id = id
	_overlay.bind(_host, {"id": String(e.id), "difficulty": String(e.difficulty)})
	return true

## Existing transaction-safe Retry of the same host (fresh attempt, same level).
func instant_reset() -> bool:
	if _host == null or not is_instance_valid(_host):
		return false
	var ok: bool = _host.retry()
	_overlay.refresh()
	return ok

func get_host():
	return _host

func get_overlay():
	return _overlay

func get_entry_id() -> String:
	return _entry_id

func get_catalog():
	return _catalog
