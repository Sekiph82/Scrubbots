extends RefCounted
## GameplayShellGeometry — preload (res://scripts/ui/gameplay_shell_geometry.gd).
##
## M28-C002-C002 (OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01) + owner 2026-11-16 amendment
## (SB-GAMEPLAY-BG-2026-11-16): the six plaza gameplay masters (852x1846), all cut from the ONE
## owner plaza image (5slot_4col = that image unchanged), and their MEASURED reference coordinates.
## Pure data. Every rect is [x0, y0, x1, y1] in master pixels, measured by pixel analysis of the
## committed masters (factory/jobs/159-gameplay-shell-plaza/measure.py):
##   rail      — centrelines of the baked Railway loop (left/right x, top/bottom y): the measured
##               inner metal opening of the tubes (x 103..746, y 311..947; pixel profiles) grown by
##               26 px on every side, i.e. inside every tube and square enough that the runtime
##               2.5-cell loop keeps even a 59x59 board inside the opening;
##   slots     — interiors of the baked execution-slot frames (navy connected components), left -> right;
##   connector_x — centre x of the glow cap of each baked slot->bottom-rail pipe;
##   cols/rows — Batch Supply cell interiors (navy components; x ranges per column, y ranges per row);
## plus the shared top-bar boxes, the speech-bubble text area to mask, and the
## booster / ad bands reserved on the empty floor below the supply panel.
## Selection is by the two authoritative runtime facts: supply column count (3/4/5) and
## execution-slot capacity (5/6). Anything else fails closed ("").

const SIZE := Vector2(852.0, 1846.0)
const DIR := "res://assets/ui/final/gameplay/master/"

## Locked SHA-256 of each master (coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md).
const SHA256 := {
	"5slot_3col": "9242651d436cd354005b0311a0ff2a43f4ff789123fa5741412d9d39123b0e8d",
	"5slot_4col": "47a8b9f86c74fcda2f94fd144db2d82a42aa9fdc6d2aca83dce6bf3b5722a4d8",
	"5slot_5col": "4c01e2322c41b3b5ce3d2e8742af7a675ae81ea5a2535b20cba6377d4d099026",
	"6slot_3col": "e7502d7e6286fafa7d02254174fad6f1459c75e9d4f62f53792662f1de4d5ddc",
	"6slot_4col": "c042c211fdb76c8177062be460fc2b6a95dd5e2b05718b566633a0086cef0272",
	"6slot_5col": "b796ad4c78a529d8914a9628f2b5837d08664f00370cb3ca14e2492fa1071390",
}

## The rail is the same baked loop in all six masters.
const RAIL := {"left": 80.0, "right": 769.0, "top": 285.0, "bottom": 973.0}
const SLOTS_5 := [[192, 1084, 269, 1159], [290, 1084, 368, 1159], [390, 1084, 468, 1159], [489, 1084, 567, 1159], [588, 1084, 665, 1159]]
const SLOTS_6 := [[143, 1084, 220, 1159], [241, 1084, 319, 1159], [341, 1084, 419, 1159], [440, 1084, 518, 1159], [539, 1084, 617, 1159], [638, 1084, 715, 1159]]
const CONN_5 := [232.0, 331.0, 429.5, 531.0, 629.5]
const CONN_6 := [183.0, 282.0, 380.5, 479.5, 581.0, 679.5]
const COLS_3 := [[297, 373], [394, 471], [491, 568]]
const COLS_4 := [[249, 325], [346, 423], [443, 520], [540, 617]]
const COLS_5 := [[228, 290], [314, 376], [401, 463], [488, 550], [575, 637]]
const ROWS_34 := [[1204, 1279], [1307, 1382], [1409, 1484]]
const ROWS_5 := [[1212, 1272], [1315, 1374], [1417, 1477]]

const SHELLS := {
	"5slot_3col": {"rail": RAIL, "slots": SLOTS_5, "connector_x": CONN_5, "cols": COLS_3, "rows": ROWS_34},
	"5slot_4col": {"rail": RAIL, "slots": SLOTS_5, "connector_x": CONN_5, "cols": COLS_4, "rows": ROWS_34},
	"5slot_5col": {"rail": RAIL, "slots": SLOTS_5, "connector_x": CONN_5, "cols": COLS_5, "rows": ROWS_5},
	"6slot_3col": {"rail": RAIL, "slots": SLOTS_6, "connector_x": CONN_6, "cols": COLS_3, "rows": ROWS_34},
	"6slot_4col": {"rail": RAIL, "slots": SLOTS_6, "connector_x": CONN_6, "cols": COLS_4, "rows": ROWS_34},
	"6slot_5col": {"rail": RAIL, "slots": SLOTS_6, "connector_x": CONN_6, "cols": COLS_5, "rows": ROWS_5},
}

## Shared top bar (interiors of the baked boxes; identical in all six masters).
const PROFILE := [30, 106, 383, 228]
const PAUSE := [592, 112, 693, 211]
const SPEED := [717, 112, 821, 211]
## Obsolete baked instruction text inside the speech bubble (masked; bubble art kept).
const BUBBLE_TEXT := [30, 1162, 204, 1306]
const BUBBLE_FILL := Color8(253, 247, 231)
## Lower floor bands reserved by the owner decision (§4): four boosters on the empty floor
## below the supply panel / Scrubby / caution sign, above the ad region.
const BOOSTERS := [178, 1640, 674, 1738]
const AD := [0, 1762, 852, 1846]

## "<5|6>slot_<3|4|5>col" or "" (fail closed) for the two authoritative facts.
static func shell_id(columns: int, capacity: int) -> String:
	if not (columns in [3, 4, 5]) or not (capacity in [5, 6]):
		return ""
	return "%dslot_%dcol" % [capacity, columns]

static func texture_path(id: String) -> String:
	return DIR + "gameplay_v03_plaza_shell_%s.png" % id if SHELLS.has(id) else ""

static func rect(r: Array) -> Rect2:
	return Rect2(float(r[0]), float(r[1]), float(r[2] - r[0]), float(r[3] - r[1]))

## Reference-space rail loop (centrelines) for a shell.
static func rail_rect(id: String) -> Rect2:
	var r: Dictionary = SHELLS[id]["rail"]
	return Rect2(r["left"], r["top"], r["right"] - r["left"], r["bottom"] - r["top"])

static func slot_rects(id: String) -> Array:
	return SHELLS[id]["slots"].map(func(s): return rect(s))

## Bounding rect of the supply grid plus uniform gaps (the baked grid is regular).
static func supply_grid(id: String) -> Dictionary:
	var cols: Array = SHELLS[id]["cols"]
	var rows: Array = SHELLS[id]["rows"]
	var x0: float = cols[0][0]
	var x1: float = cols[cols.size() - 1][1]
	var y0: float = rows[0][0]
	var y1: float = rows[rows.size() - 1][1]
	var cw: float = 0.0
	for c in cols:
		cw += float(c[1] - c[0])
	cw /= cols.size()
	var ch: float = 0.0
	for r in rows:
		ch += float(r[1] - r[0])
	ch /= rows.size()
	var gx: float = ((x1 - x0) - cw * cols.size()) / float(cols.size() - 1)
	var gy: float = ((y1 - y0) - ch * rows.size()) / float(rows.size() - 1)
	return {"rect": Rect2(x0, y0, x1 - x0, y1 - y0), "gap_x": gx, "gap_y": gy,
		"cells": cols.size(), "cell": Vector2(cw, ch)}

## Reference rect of supply cell (column, row).
static func supply_cell(id: String, column: int, row: int) -> Rect2:
	var c: Array = SHELLS[id]["cols"][column]
	var r: Array = SHELLS[id]["rows"][row]
	return Rect2(c[0], r[0], c[1] - c[0], r[1] - r[0])
