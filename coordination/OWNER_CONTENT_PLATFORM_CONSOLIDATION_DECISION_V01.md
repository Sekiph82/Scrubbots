# CONTENT PLATFORM CONSOLIDATION PLAN V01

Status: **DRAFT / NON-DESTRUCTIVE INTEGRATION PLAN — NO TRACKER AUTHORITY MOVED**
Date: 2026-09-14
Owner direction: Şekip

## Corrected decision

The owner wants `Sekiph82/ScrubBots-Level-Factory` to evolve so it can eventually implement/operate the Level Factory and Content/Update Platform program planned in the main SCRUBBOTS roadmap.

This does **not** mean the existing Level Factory roadmap is replaced, reset, or discarded.

This does **not** mean the 224 `SB-LF*` + `SB-CP*` rows are immediately canonicalized in the Level Factory root `TASKS.md`.

Until an explicit mapping/audit migration is completed and owner-approved:

- the main `Sekiph82/Scrubbots` `TASKS.md` retains its existing LF/CP roadmap rows and their current role;
- `Sekiph82/ScrubBots-Level-Factory/TASKS.md` retains its existing PAG/SP roadmap, completion states and active cycle;
- no existing completed/active Level Factory task may be reset because of the proposed integration;
- no imported LF/CP task may be marked open/completed solely because of migration.

## Integration target

The desired future architecture remains:

`Level Factory / Studio -> canonical Factory Core -> validated declarative level/campaign content -> packaging/publishing -> Scrubbots runtime`

The two repositories remain separate implementation domains:

### `Sekiph82/ScrubBots-Level-Factory`

Candidate future responsibilities include generation, semantic art, solver/difficulty tooling, QA, campaign sequencing, Factory Studio, packaging and publisher/control-plane tooling.

### `Sekiph82/Scrubbots`

Remains the shipping Godot game/client and owns gameplay plus runtime content consumption, download/cache/activation/offline behavior when those milestones open.

## Required migration process

Before tracker ownership changes:

1. Inventory both current roadmaps without altering them.
2. Map all 224 LF/CP rows to existing Level Factory tasks/evidence and implementation repositories.
3. Preserve all existing `[x]`, `[~]`, `[ ]`, audit and active-cycle state.
4. Determine overlap, partial coverage, missing work and conflicts through independent audit.
5. Propose an **additive** integration structure, not a replacement tracker.
6. Obtain owner approval for any actual tracker restructuring.
7. Only then update tracker authority/status through the normal audit workflow.

## Parallel development

Claude may continue the main game while Codex continues the existing Level Factory roadmap. Integration planning must not interrupt or silently supersede either active implementation cycle.

## Safety rule

Tracker migration itself never creates or removes completion credit. Existing evidence and existing work remain first-class project truth.
