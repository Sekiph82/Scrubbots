extends RefCounted
## GameplayShellGeometry — preload (res://scripts/ui/gameplay_shell_geometry.gd).
##
## M28-C002-C002 (OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01): the six owner-locked static
## gameplay masters and their MEASURED reference coordinates (887×1774 master pixels).
## Pure data. Every rect is [x0, y0, x1, y1] in master pixels, measured from the exact
## owner files (pixel analysis + ruler crops; see the C002 matrix):
##   rail      — centrelines of the baked Railway loop (left/right x, top/bottom y);
##   slots     — interiors of the baked execution-slot frames, left -> right;
##   connector_x — centre x of each baked slot->bottom-rail connector;
##   cols/rows — Batch Supply cell interiors (x ranges per column, y ranges per row);
## plus the shared top-bar boxes, the speech-bubble text area to mask, and the
## booster / ad bands reserved in the lower floor area.
## Selection is by the two authoritative runtime facts: supply column count (3/4/5) and
## execution-slot capacity (5/6). Anything else fails closed ("").

const SIZE := Vector2(887.0, 1774.0)
const DIR := "res://assets/ui/final/gameplay/master/"

## Locked SHA-256 of each owner master (coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md).
const SHA256 := {
	"5slot_3col": "4ee6712df6aedb3ee48d5cf2e2971356bd9df14363e777965c7e4691ca3121da",
	"5slot_4col": "dcf92b4fe163d0c5e6543f90943528ea064c08b31ed11d5c26c158265a9a8fac",
	"5slot_5col": "c520c5055caff58f5a9a1ff7eb7ceb98ce5873b9abf86e03b183a8442afc7636",
	"6slot_3col": "75c148266a4d0aec20a0eb5c299d00a2840e13d8cc10ae6ec60731f0823f8f06",
	"6slot_4col": "d3d01b697d14fbb8896b70594c5768dd1be7606a6519aec2aa71770a5fa38a55",
	"6slot_5col": "5ad162d288e8c8d33c5e40d0bb3caedb32939165853a602d868a4caa6428c12b",
}

const SLOTS_5 := [[192, 1087, 276, 1166], [298, 1087, 383, 1166], [405, 1087, 489, 1166], [511, 1087, 595, 1166], [617, 1087, 702, 1166]]

const SHELLS := {
	"5slot_3col": {
		"rail": {"left": 76.5, "right": 811.0, "top": 210.0, "bottom": 960.5},
		"slots": SLOTS_5, "connector_x": [234.0, 340.5, 447.5, 558.0, 663.0],
		"cols": [[298, 381], [403, 485], [506, 589]],
		"rows": [[1219, 1296], [1329, 1407], [1440, 1517]],
	},
	"5slot_4col": {
		"rail": {"left": 77.5, "right": 810.5, "top": 210.0, "bottom": 960.5},
		"slots": SLOTS_5, "connector_x": [234.0, 341.0, 448.0, 558.0, 663.0],
		"cols": [[246, 328], [351, 433], [456, 537], [560, 643]],
		"rows": [[1220, 1297], [1329, 1405], [1438, 1515]],
	},
	"5slot_5col": {
		"rail": {"left": 77.5, "right": 810.5, "top": 210.0, "bottom": 961.0},
		"slots": SLOTS_5, "connector_x": [234.0, 341.0, 448.0, 557.5, 663.0],
		"cols": [[229, 306], [320, 396], [410, 486], [500, 576], [590, 666]],
		"rows": [[1200, 1278], [1292, 1370], [1384, 1462]],
	},
	"6slot_3col": {
		"rail": {"left": 77.5, "right": 810.0, "top": 210.0, "bottom": 962.0},
		"slots": [[132, 1088, 217, 1168], [240, 1088, 325, 1168], [348, 1088, 433, 1168], [455, 1088, 540, 1168], [562, 1088, 649, 1168], [671, 1088, 756, 1168]],
		"connector_x": [172.0, 281.5, 389.5, 496.5, 606.5, 716.0],
		"cols": [[297, 381], [402, 486], [506, 590]],
		"rows": [[1218, 1297], [1328, 1407], [1439, 1520]],
	},
	"6slot_4col": {
		"rail": {"left": 77.5, "right": 810.0, "top": 210.5, "bottom": 961.5},
		"slots": [[148, 1086, 232, 1167], [249, 1086, 333, 1167], [352, 1086, 435, 1167], [452, 1086, 536, 1167], [553, 1087, 636, 1167], [655, 1086, 739, 1167]],
		"connector_x": [188.5, 288.5, 392.5, 493.5, 595.5, 697.0],
		"cols": [[244, 331], [351, 438], [457, 545], [564, 654]],
		"rows": [[1216, 1295], [1319, 1398], [1425, 1505]],
	},
	"6slot_5col": {
		"rail": {"left": 77.5, "right": 809.5, "top": 210.5, "bottom": 961.5},
		"slots": [[154, 1089, 235, 1167], [253, 1089, 335, 1167], [353, 1089, 433, 1167], [451, 1089, 531, 1167], [549, 1088, 630, 1167], [648, 1089, 729, 1167]],
		"connector_x": [194.5, 294.5, 394.5, 492.5, 592.5, 692.0],
		"cols": [[230, 307], [320, 396], [410, 486], [499, 575], [589, 664]],
		"rows": [[1202, 1278], [1291, 1368], [1381, 1458]],
	},
}

## Shared top bar (interiors of the baked boxes; identical across the six masters ±1 px).
const PROFILE := [46, 30, 407, 157]
const PAUSE := [626, 34, 725, 130]
const SPEED := [747, 34, 850, 130]
## Obsolete baked instruction text inside the speech bubble (masked; bubble art kept).
const BUBBLE_TEXT := [30, 1196, 195, 1324]
const BUBBLE_FILL := Color8(250, 243, 236)
## Lower floor bands reserved by the owner decision (§4): four boosters above the ad region.
const BOOSTERS := [196, 1582, 691, 1680]
const AD := [0, 1690, 887, 1774]

## "<5|6>slot_<3|4|5>col" or "" (fail closed) for the two authoritative facts.
static func shell_id(columns: int, capacity: int) -> String:
	if not (columns in [3, 4, 5]) or not (capacity in [5, 6]):
		return ""
	return "%dslot_%dcol" % [capacity, columns]

static func texture_path(id: String) -> String:
	return DIR + "gameplay_v02_shell_%s.png" % id if SHELLS.has(id) else ""

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
