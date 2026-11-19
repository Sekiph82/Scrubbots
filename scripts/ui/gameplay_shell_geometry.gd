extends RefCounted
## GameplayShellGeometry — preload (res://scripts/ui/gameplay_shell_geometry.gd).
##
## M28-C002-C002 (OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01) + owner 2026-11-16 amendment
## (SB-GAMEPLAY-BG-2026-11-16) + owner 2026-11-18 amendment (SB-TF-04): the six plaza gameplay
## masters (852x1846), all built from the ONE owner plaza image by
## tools/gameplay_shell_masters.py (Scrubby x1.25, bucket + Caution sign x0.75 beside the Supply
## panel, speech bubble widened behind the slot strip and Supply panel, navy board field lifted to
## BoardPresentation.BOARD_FLOOR, SB-TF-10 / SB-TF-13), and their MEASURED reference coordinates.
## Pure data. Every rect is [x0, y0, x1, y1] in master pixels, measured by pixel analysis of the
## committed masters (factory/jobs/159-gameplay-shell-plaza/measure.py):
##   rail      — centrelines of the baked Railway loop (left/right x, top/bottom y): the measured
##               inner metal opening of the tubes (x 103..746, y 311..947; pixel profiles) grown by
##               26 px on every side, i.e. inside every tube and square enough that the runtime
##               2.5-cell loop keeps even a 59x59 board inside the opening;
##   slots     — interiors of the baked execution-slot frames (navy connected components), left -> right;
##   connector_x — centre x of the glow cap of each baked slot->bottom-rail pipe;
##   cols/rows — Batch Supply cell interiors (navy components; x ranges per column, y ranges per row);
## plus the shared top-bar boxes, the speech-bubble text area to mask, and the booster band
## centred under the supply panel (the bottom banner is screen space,
## HomeStyle.ad_banner, not part of the master).
## Selection is by the two authoritative runtime facts: supply column count (3/4/5) and
## execution-slot capacity (5/6). Anything else fails closed ("").

const SIZE := Vector2(852.0, 1846.0)
const DIR := "res://assets/ui/final/gameplay/master/"

## Locked SHA-256 of each master (coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md §13).
const SHA256 := {
	"5slot_3col": "29f17d564d21d3303c1176d88d9177658facd69e4ab6e66c311a03ce56510c74",
	"5slot_4col": "c8faaaba2d1e23a8f7766bdd30d2387fe57575b35e3b4c6573927a4a49ed5d9a",
	"5slot_5col": "0b92b540389ee2b3ea6fff6c083ee65319ea50c6bf0aab1b0c168badd89e646b",
	"6slot_3col": "f004aa2a61f7bcfda19014c99cbc9d06fc130ee1772adcfb383bbabcf42405f4",
	"6slot_4col": "5b59ea9172ce232e7e7d0df5ee88d50086f3a7c286e085603e80eb6c523dbf09",
	"6slot_5col": "f1ddc4a7ceef9ddb5f8292240f7141635f324d46831fe40d56d12532343b5539",
}

## The rail is the same baked loop in all six masters.
const RAIL := {"left": 80.0, "right": 769.0, "top": 285.0, "bottom": 973.0}
const SLOTS_5 := [[192, 1084, 269, 1159], [290, 1084, 368, 1159], [390, 1084, 468, 1159], [489, 1084, 567, 1159], [588, 1084, 665, 1159]]
const SLOTS_6 := [[143, 1084, 220, 1159], [241, 1084, 319, 1159], [341, 1084, 419, 1159], [440, 1084, 518, 1159], [539, 1084, 617, 1159], [638, 1084, 715, 1159]]
const CONN_5 := [232.0, 331.0, 429.5, 531.0, 629.5]
const CONN_6 := [183.0, 282.0, 380.5, 479.5, 581.0, 679.5]
const COLS_3 := [[297, 373], [394, 471], [491, 568]]
const COLS_4 := [[249, 325], [346, 423], [443, 520], [540, 617]]
const COLS_5 := [[223, 296], [311, 383], [398, 470], [485, 557], [572, 644]]
const ROWS_34 := [[1204, 1279], [1307, 1382], [1409, 1484]]
const ROWS_5 := [[1206, 1277], [1309, 1380], [1411, 1483]]

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
## Live-text area of the speech bubble, below the slot strip and left of every Supply panel
## (the baked sentence is erased in the masters; masked in the bubble fill all the same).
const BUBBLE_TEXT := [28, 1174, 208, 1310]
const BUBBLE_FILL := Color8(253, 247, 231)
## SB-TF-10 (owner 2026-11-19): the four boosters directly under the Supply panel (its baked
## shadow ends at y 1515), centred on the master (= screen) width, same 508x120 band as SB-TF-04;
## they may draw over Scrubby and stay above the tallest bottom banner (112 px) at every viewport.
const BOOSTERS := [172, 1516, 680, 1636]

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
