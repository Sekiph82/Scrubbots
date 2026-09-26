extends PanelContainer
## SpeedAcquisitionPopup — preload (res://scripts/ui/speed_acquisition_popup.gd).
##
## M52-C001-R01 FUNCTIONAL production 2x acquisition UI (live Godot Controls). Opened when
## the player presses the 2x control without a manual 2x entitlement, so the control never
## silently does nothing (OWNER_PARALLEL_SLOT_DISPATCH_AND_DEPARTURE_COUNT_V01 §6).
## Presentation only: it lists the canonical Economy V1 offers it is given and emits the
## player's choice; the host performs the purchase through ProductionActionFacade and
## reports the outcome back via show_status(). Final art/layout is PENDING the M43 visual
## master/polish — this is intentionally plain.

signal offer_chosen(kind: String, seconds: int)
signal cancelled

var _status: Label
var _offer_box: VBoxContainer
var _buttons: Dictionary = {}   # offer key -> Button
var _cancel: Button

func _init() -> void:
	name = "SpeedAcquisitionPopup"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	var title := Label.new()
	title.name = "Title"
	title.text = "2x SPEED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	_offer_box = VBoxContainer.new()
	_offer_box.name = "Offers"
	col.add_child(_offer_box)
	_status = Label.new()
	_status.name = "Status"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_status)
	_cancel = Button.new()
	_cancel.name = "Cancel"
	_cancel.text = "Cancel"
	_cancel.pressed.connect(_on_cancel)
	col.add_child(_cancel)

## offers: Array of {key, kind ("level"|"timed"), seconds, label, price_sb}.
func open(offers: Array, scrub_bucks: int) -> void:
	for c in _offer_box.get_children():
		c.queue_free()
	_buttons.clear()
	for o in offers:
		var b := Button.new()
		b.name = "Offer_%s" % o["key"]
		b.text = "%s — %d SB" % [o["label"], int(o["price_sb"])]
		var kind: String = o["kind"]
		var seconds: int = int(o["seconds"])
		b.pressed.connect(func(): offer_chosen.emit(kind, seconds))
		_offer_box.add_child(b)
		_buttons[o["key"]] = b
	_status.text = "Scrub Bucks: %d" % scrub_bucks
	visible = true
	_center()

func show_status(text: String) -> void:
	_status.text = text

func get_status_text() -> String:
	return _status.text

func get_offer_button(key: String) -> Button:
	return _buttons.get(key, null)

func get_cancel_button() -> Button:
	return _cancel

func close() -> void:
	visible = false

func _on_cancel() -> void:
	close()
	cancelled.emit()

func _center() -> void:
	var p := get_parent()
	if p is Control:
		reset_size()
		position = ((p as Control).size - size) * 0.5
