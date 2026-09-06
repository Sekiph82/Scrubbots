# M17 — Owner Movement-Language Decision V01

Status: **OWNER_APPROVED / DESIGN_GATE_RESOLVED**

Date: 2026-09-07

The owner reviewed the M17 Routing Prototype Lab and selected the final SCRUBBOTS movement language.

## Decision

**OWNER_SELECTS_ORGANIZED**

Production direction:

- **Movement language:** Organized/curved.
- **Path-planning backbone:** Grid-aware deterministic planner.
- **Direct route:** rejected as a production movement language; retain only as a debug/baseline comparison tool.
- **Safety rule:** organized/curved routing must never invent reachability. It must derive from a valid grid-aware route and every emitted segment must still pass the shared RouteValidator/access truth.
- **Retargeting:** never.
- **Target identity:** always the already-assigned target.

## Owner tuning preference

The owner also accepts the refinement direction discussed during review:

- reduce overly aggressive diagonal shortcuts;
- keep curves controlled and readable;
- preserve the organized/curved visual language without turning dense scenes into a chaotic web;
- prefer valid, readable bends over visually extreme shortcuts;
- do not sacrifice access correctness for aesthetics.

This is a **production direction**, not permission to over-engineer crossing avoidance or congestion optimization before profiling.

## Design-gate consequence

The M17 owner design gate is resolved.

The missing original SCRUBBOTS movement reference no longer blocks the routing decision. The owner-reviewed Organized/curved direction supersedes the unavailable original-movement comparison for this gate.

M18 may open only after the selected movement language is promoted from experimental M17 prototype code into audited production routing code.
