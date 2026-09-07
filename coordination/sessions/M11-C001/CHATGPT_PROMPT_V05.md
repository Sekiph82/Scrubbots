# M11-C001 — Frozen Full-Surface Session-Core Closure V05

Status: **ISSUED — FROZEN FINDING SET**

This supersedes all older M11 correction prompts. Execute this V05 only.

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/sessions/M11-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md
- prior M11 V01-V04 artifacts
- this prompt + V05 criteria

Fix ONLY the frozen M11 finding set.
Do not implement M12+ gameplay features.

## 1. Own immutable LevelData source truth

After successful LevelLoader result:
- create/store an internally owned detached LevelData copy;
- duplicate all packed collection fields;
- BoardState must be created from that internal source copy.

get_level_data():
- return null when uninitialized;
- otherwise return a detached LevelData snapshot/copy;
- caller mutation of width/height/id/difficulty/palette/cells must not mutate the session's internal source.

Do not expose an internal LevelData reference by another getter.

Required adversarial sequence:
1. load valid level;
2. get snapshot;
3. mutate snapshot width/height/palette/cells;
4. mutate its packed arrays in-place;
5. call reset;
6. new BoardState dimensions/color ids must match ORIGINAL loaded source;
7. a new get_level_data snapshot must also still match original source.

Failed replacement load:
- prior internal source remains unchanged;
- prior BoardState identity/state remains unchanged.

## 2. Safe renderer binding

Renderer binding contract:
- null explicitly unbinds;
- non-null must be a live real BoardRenderer;
- scalar/junk/partial object rejected without configure call;
- invalid replacement must not replace a currently valid renderer binding.

You may change bind_renderer() to return bool if useful; existing callers may ignore the return value.

Direct malformed inputs:
- int
- String
- Vector2
- RefCounted.new()
- partial object exposing configure but not a real BoardRenderer

No runtime fault.

## 3. Renderer size contract

Define finite positive available_size.

Reject (or deterministic safe-sanitize, but document one policy consistently):
- NaN x/y;
- +INF/-INF;
- zero x/y;
- negative x/y.

Preferred:
- invalid bind returns false and preserves the prior valid renderer/size;
- null unbind remains explicit.

No invalid geometry may reach BoardRenderer.configure.

## 4. Freed/stale renderer lifecycle

Before any configure:
- renderer must still be instance-valid and a real BoardRenderer;
- if it was freed externally, clear the stored presentation binding and continue session lifecycle headlessly.

Direct tests:
- bind valid renderer -> load -> free renderer -> reset succeeds, READY, fresh BoardState;
- bind valid renderer -> free renderer -> load a valid replacement level succeeds;
- no call is attempted on freed instance.

## 5. Presentation cannot alias source palette

Every renderer.configure call receives a detached duplicate of the internal LevelData palette.

Prove session source palette remains original across:
- initial configure;
- reset reconfigure;
- renderer rebind.

Do not pass the LevelData object to renderer.

## 6. Full M11 regression matrix

Preserve:
- UNINITIALIZED initial truth;
- valid load -> READY;
- missing/malformed load failure;
- atomic failed replacement;
- fresh BoardState on reset;
- all cells ACTIVE after reset;
- dimensions/color IDs preserved;
- independent sessions;
- READY->ACTIVE->PAUSED->ACTIVE;
- invalid transitions non-mutating;
- reset from READY/ACTIVE/PAUSED/COMPLETED;
- reset from UNINITIALIZED rejected;
- explicit ACTIVE->COMPLETED;
- repeated complete rejected/non-corrupting;
- all cells CLEARED does not auto-complete;
- valid renderer follows current BoardState;
- renderer follows NEW BoardState after reset;
- rectangular board;
- 59x59;
- no slot/target/routing/agent responsibility added to M11;
- no win/lose/timer/move-limit invention.

## Governance

Do NOT modify:
- tasks.md
- .hiveai/*
- coordination/SESSION_INDEX.md
- coordination/AUDIT_INDEX.md
- any ChatGPT audit/re-audit file
- strict sequence/queue controllers

Run:
- godot --version
- full headless suite
- git diff --check

Write:
`coordination/sessions/M11-C001/CLAUDE_LOG_V05.md`

Commit/push safely.

Return:
`AWAITING_AUDIT`

Then STOP.
