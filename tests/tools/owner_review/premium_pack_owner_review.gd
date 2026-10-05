extends Control
## Premium Pack OWNER REVIEW harness (SB-M43-065) — REVIEW-ONLY TOOLING, not shipping.
## Open res://tests/tools/owner_review/premium_pack_owner_review.tscn and press F6.
##
## Mounts the real shipping PremiumPackCeremony on a real ModalStack with a deterministic
## committed 5-card fixture (card 0 always Rare-or-better) and leaves it in IDLE. Every
## ceremony step (both taps, frames, timings, cards, destinations, routing) is the production
## ceremony's own; this harness never taps, animates or re-implements anything.
##
## Keys (harness only): R restart · E toggle FULL / Reduced Effects + restart ·
## 1 mixed NEW/DUPLICATE · 2 all NEW · 3 repeated duplicates · 4 duplicate-heavy (all DUPLICATE,
## EXTRAS x2 / x1 / x5 / x3 / x10).
## Fixtures are read-only models; nothing opens a pack, grants, saves or navigates.

const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const Fx = preload("res://tests/support/premium_pack_fixtures.gd")

const FIXTURES := {KEY_1: "mixed", KEY_2: "all_new", KEY_3: "repeat", KEY_4: "all_duplicate"}
const BG01 := Color(0.125, 0.145, 0.2)   ## gameplay background Midnight Slate

var _stack
var _ceremony
var _fixture := "mixed"
var _reduced := false
var _run := 0
var _note: Label

func _ready() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = BG01
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# Review-only note, shown only after a ceremony completes (never over a running one).
	_note = Label.new()
	_note.name = "ReviewNote"
	_note.set_anchors_preset(Control.PRESET_FULL_RECT)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_note.add_theme_font_size_override("font_size", 40)
	_note.visible = false
	add_child(_note)
	_stack = ModalStack.new()
	add_child(_stack)
	restart()

## Fresh shipping Premium ceremony in IDLE for the current fixture / effects mode.
func restart() -> void:
	_stack.clear("review_restart")
	_note.visible = false
	_run += 1
	_ceremony = PremiumPackCeremony.create_premium(_model("prem_review_%s_%d" % [_fixture, _run]), _reduced)["popup"]
	_ceremony.closed.connect(_on_closed)
	_stack.push(_ceremony)

func _model(pid: String) -> Dictionary:
	match _fixture:
		"all_new":
			return Fx.all_new(pid)
		"repeat":
			return Fx.repeat(pid)
		"all_duplicate":
			return Fx.all_duplicate(pid)
	return Fx.mixed(pid)

func _on_closed(reason: String) -> void:
	if reason != "complete":
		return
	_note.text = "Review complete (%s · %s)\nR replay · E Full/Reduced · 1 mixed · 2 all new · 3 repeat · 4 all duplicate" % [_fixture, "REDUCED" if _reduced else "FULL"]
	_note.visible = true

func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_R:
		restart()
	elif k.keycode == KEY_E:
		_reduced = not _reduced
		restart()
	elif FIXTURES.has(k.keycode):
		_fixture = FIXTURES[k.keycode]
		restart()
	else:
		return
	get_viewport().set_input_as_handled()

# ------------------------------------------------------------ inspection (tests) --

func get_ceremony():
	return _ceremony

func get_stack():
	return _stack

func fixture_name() -> String:
	return _fixture

func is_reduced() -> bool:
	return _reduced

func get_review_note() -> Label:
	return _note
