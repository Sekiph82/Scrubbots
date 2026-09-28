extends "res://scripts/ui/popup/base_popup.gd"
## SpeedAcquisitionPopup — preload (res://scripts/ui/speed_acquisition_popup.gd).
##
## M43-C003 (SB-M43-045/046) canonical 2x Acquire popup. Converged into the M43-C002
## BasePopup / ModalStack family (replaces the M52-C001-R01 plain PanelContainer; no
## parallel modal). Presentation only: shows the live Economy V1 offers, balance and
## entitlement state it is given and emits offer_chosen(kind, seconds); the gameplay host
## purchases through ProductionActionFacade and reports back via show_status()/refresh().
## Exactly the four paid products (current level / 15m / 30m / 60m). No rewarded 2x.

signal offer_chosen(kind: String, seconds: int)
signal cancelled

const SPEED_ART := "res://assets/ui/final/shop/shop_speed_2x_icon.png"

var _offers: Array = []

func _init() -> void:
	super("speed_acquire")
	set_frame("medium")
	set_title(UiText.t("SPEED_TITLE"))
	var row := HBoxContainer.new()
	row.name = "Summary"
	row.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	get_content().add_child(row)
	var icon := HomeStyle.art("SpeedIcon")
	icon.texture = load(SPEED_ART)
	icon.custom_minimum_size = Vector2(150, 150)
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(col)
	for n in ["Entitlement", "Balance"]:
		var l := body_label("", UiTokens.FONT_BODY)
		l.name = n
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		col.add_child(l)
	add_body_line(UiText.t("SPEED_EXPLAIN"), "Explain", INK, 26)
	add_body_line("", "Status")
	action_selected.connect(_on_selected)
	closed.connect(func(r):
		if not String(r).begins_with("action:offer") and r != "purchased":
			cancelled.emit())

## offers: [{key, kind ("level"|"timed"), seconds, label, price_sb}] (canonical config).
## state: {scrub_bucks, level_active, timed_remaining}
func open(offers: Array, state: Dictionary) -> void:
	if _offers.is_empty():
		_offers = offers.duplicate(true)
		for i in range(_offers.size()):
			var o: Dictionary = _offers[i]
			add_action(String(o["key"]), "", "offer", false, "r%d" % (i / 2))
		add_action("cancel", UiText.t("CONFIRM_CANCEL"), "secondary", true)
	refresh(state)

func refresh(state: Dictionary) -> void:
	var level_active := bool(state.get("level_active", false))
	var rem := int(state.get("timed_remaining", 0))
	var ent := UiText.t("SPEED_NONE")
	if rem > 0:
		ent = UiText.t("SPEED_TIMED_ACTIVE", [_hms(rem)])
	elif level_active:
		ent = UiText.t("SPEED_LEVEL_ACTIVE")
	(find_child("Entitlement", true, false) as Label).text = ent
	(find_child("Balance", true, false) as Label).text = UiText.t("ACQ_BALANCE", [UiText.num(int(state.get("scrub_bucks", 0)))])
	for o in _offers:
		var b: Button = get_action_button(String(o["key"]))
		var active: bool = o["kind"] == "level" and level_active
		# While timed 2x runs, a timed purchase EXTENDS it (SpeedEntitlementService).
		var label: String = ("+" + String(o["label"])) if o["kind"] == "timed" and rem > 0 else String(o["label"])
		b.text = UiText.t("SPEED_OFFER_ACTIVE", [label]) if active else UiText.t("SPEED_OFFER", [label, UiText.num(int(o["price_sb"]))])
		# An already-owned current-level entitlement is never offered again.
		set_action_blocked(String(o["key"]), active)

func show_status(text: String) -> void:
	(find_child("Status", true, false) as Label).text = text

func get_status_text() -> String:
	return (find_child("Status", true, false) as Label).text

func get_offer_button(key: String) -> Button:
	return get_action_button(key)

func get_cancel_button() -> Button:
	return get_action_button("cancel")

func get_offer_keys() -> Array:
	return _offers.map(func(o): return String(o["key"]))

func _on_selected(id: String, _ctx: Dictionary) -> void:
	for o in _offers:
		if String(o["key"]) == id:
			offer_chosen.emit(String(o["kind"]), int(o["seconds"]))
			return

static func _hms(seconds: int) -> String:
	var s := maxi(seconds, 0)
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s % 3600) / 60, s % 60]
	return "%02d:%02d" % [s / 60, s % 60]
