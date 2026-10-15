extends RefCounted
## GameplayDebugModel — preload (res://scripts/debug/gameplay_debug_model.gd).
##
## M45 (SB-M45-002..011) — DEVELOPER-ONLY read of one built ProductionGameplayHost. Pure:
## it only calls read accessors of the canonical engines (BoardState, ReservationState,
## ScrubbotDispatcher) and engine performance monitors; it never mutates gameplay, economy
## or save state. `meta` carries the catalog identity the host itself does not own
## ({id, difficulty} from the LevelCatalog entry).

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

static func capture(host, meta: Dictionary = {}) -> Dictionary:
	var out := {"built": false, "level_id": String(meta.get("id", "")), "difficulty": String(meta.get("difficulty", "")),
		"width": 0, "height": 0, "cells": 0, "artwork_cells": 0, "active": 0, "cleared": 0,
		"reserved": 0, "active_bots": 0,
		"fps": float(Engine.get_frames_per_second()),
		"frame_ms": float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0}
	if host == null or not is_instance_valid(host) or not host.is_built():
		return out
	var b = host.get_board()
	out["built"] = true
	out["width"] = b.get_width()
	out["height"] = b.get_height()
	out["cells"] = b.get_cell_count()
	out["artwork_cells"] = b.get_artwork_cell_count()
	out["active"] = b.count_cells_by_state(BoardState.CellState.ACTIVE)
	out["cleared"] = b.count_cells_by_state(BoardState.CellState.CLEARED)
	var res = host.get_reservations()
	out["reserved"] = res.get_reservation_count() if res != null else 0
	var disp = host.get_dispatcher()
	out["active_bots"] = disp.get_active_count() if disp != null else 0
	return out

## One-screen text for the HUD (debug copy, not localized player UI).
static func to_text(m: Dictionary) -> String:
	return "LEVEL %s  [%s]\n%dx%d  cells %d (art %d)\nACTIVE %d  CLEARED %d\nRESERVED %d  BOTS %d\nFPS %d  frame %.2f ms" % [
		String(m["level_id"]) if not String(m["level_id"]).is_empty() else "-", String(m["difficulty"]) if not String(m["difficulty"]).is_empty() else "-",
		int(m["width"]), int(m["height"]), int(m["cells"]), int(m["artwork_cells"]),
		int(m["active"]), int(m["cleared"]), int(m["reserved"]), int(m["active_bots"]),
		int(m["fps"]), float(m["frame_ms"])]
