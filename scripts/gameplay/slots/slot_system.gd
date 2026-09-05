extends RefCounted
## SlotSystem — preload this script
## (res://scripts/gameplay/slots/slot_system.gd) rather than relying on
## global class_name lookup (AL-001).
##
## Owns exactly five SlotState instances. Slot count is a locked invariant.
## No dispatch, no target selection, no routing, no UI dependency.

const SlotState = preload("res://scripts/gameplay/slots/slot_state.gd")

const SLOT_COUNT := 5

var _slots: Array = []
var _configured: bool = false

func _init() -> void:
	for i in SLOT_COUNT:
		_slots.append(SlotState.new(i))

func get_slot_count() -> int:
	return SLOT_COUNT

func is_configured() -> bool:
	return _configured

func get_slot(slot_id: int):
	if slot_id < 0 or slot_id >= SLOT_COUNT:
		return null
	return _slots[slot_id]

## Configure all five slots with palette IDs. Requires exactly five entries.
## Each palette ID must be >= 0 and < palette_size.
## Duplicate palette IDs are allowed.
## On failure: returns error dict, prior state preserved.
func configure(palette_ids: Array, palette_size: int) -> Dictionary:
	if palette_ids.size() != SLOT_COUNT:
		return {"ok": false, "error": "wrong_count",
			"message": "expected %d palette IDs, got %d" % [SLOT_COUNT, palette_ids.size()]}
	for i in palette_ids.size():
		var pid = palette_ids[i]
		if not (pid is int) or pid < 0:
			return {"ok": false, "error": "invalid_palette_id",
				"message": "palette ID at index %d is invalid: %s" % [i, str(pid)]}
		if pid >= palette_size:
			return {"ok": false, "error": "palette_id_out_of_range",
				"message": "palette ID %d at index %d >= palette_size %d" % [pid, i, palette_size]}
	for i in SLOT_COUNT:
		_slots[i].set_palette_id(palette_ids[i])
	_configured = true
	return {"ok": true, "error": "", "message": ""}

func set_slot_available(slot_id: int, value: bool) -> Dictionary:
	if slot_id < 0 or slot_id >= SLOT_COUNT:
		return _invalid_slot(slot_id)
	_slots[slot_id].set_available(value)
	return {"ok": true, "error": "", "message": ""}

func set_slot_active(slot_id: int, value: bool) -> Dictionary:
	if slot_id < 0 or slot_id >= SLOT_COUNT:
		return _invalid_slot(slot_id)
	_slots[slot_id].set_active(value)
	return {"ok": true, "error": "", "message": ""}

func get_slot_palette_id(slot_id: int) -> int:
	if slot_id < 0 or slot_id >= SLOT_COUNT:
		return -1
	return _slots[slot_id].get_palette_id()

func is_slot_available(slot_id: int) -> bool:
	if slot_id < 0 or slot_id >= SLOT_COUNT:
		return false
	return _slots[slot_id].is_available()

func is_slot_active(slot_id: int) -> bool:
	if slot_id < 0 or slot_id >= SLOT_COUNT:
		return false
	return _slots[slot_id].is_active()

func get_slots_by_palette_id(palette_id: int) -> Array:
	var result := []
	for slot in _slots:
		if slot.get_palette_id() == palette_id:
			result.append(slot.get_id())
	return result

func _invalid_slot(slot_id: int) -> Dictionary:
	return {"ok": false, "error": "invalid_slot_id",
		"message": "slot ID %d is out of range [0, %d)" % [slot_id, SLOT_COUNT]}
