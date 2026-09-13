# M21-C001 V03 — ChatGPT Independent Strict Audit

Date: 2026-09-13
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited implementation commit: `3a0953ad8b327a8e979341c27d44890ab3a7c779`
Implementation parent / tracker-start commit: `af3a33b7a7c34f66e3efef1ed817cccc03968c95`
Claude evidence: `coordination/sessions/M21-C001/CLAUDE_LOG_V03.md`
Criteria: `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V03.md`

## Verdict

**CHANGES_REQUIRED / V03_PRODUCTION_CORRECTION_ACCEPTED / V04_OWNER_PLAYTEST_INTEGRATION_REQUIRED**

V03 successfully closes the production-art path-identity residual that motivated the pass. The new `_resolve_physical()` contract is shared by alias identity, destination preflight, planning and actual writes; the V03 tests directly cover bare-relative `res://` basing, equivalent aliases, later-artifact conflicts, metadata-directory rejection and no-partial-write behavior. The frozen V01 findings F-M21-STRICT-001/002/004 remain closed. The owner-approved source and protected M20 production blobs remain unchanged.

M21 is **not** finally closed in V03 for two independent reasons:

1. One V03 direct-evidence cell remains incomplete: criterion 49 requires directory-at-preview rejection to be directly proven under both `overwrite=false` and `overwrite=true`. Existing V02 evidence directly covers the preview-directory case with `overwrite=true`; V03 covers both modes for output and metadata, but does not add the missing preview-directory `overwrite=false` assertion. The production source strongly indicates the behavior is safe because `_preflight_destination()` rejects directory destinations before consulting overwrite, so this is classified as an **evidence-only residual**, not a discovered production defect.
2. After V03 implementation, the owner manually ran the M21 Godot vertical slice and exposed new authoritative playtest requirements. The board/selection/clearing behavior works, but the current target priority is top-first row-major, the moving Scrubbot is not visibly presented on the scaled board, and the five-slot model is not visibly represented in the playable scene. These are new owner/runtime facts and therefore legitimately extend the final M21 acceptance surface.

Accordingly V04 must preserve the accepted V03 corrections while implementing the owner playtest decisions and closing the one evidence-only residual.

---

## 1. Scope and commit integrity

`3a0953ad...` is exactly one implementation commit ahead of the V03 tracker-start commit `af3a33b...`.

Changed files in the V03 implementation commit:

- `TASKS.md`
- `coordination/sessions/M21-C001/CLAUDE_LOG_V03.md`
- `scripts/tools/production_art_level_builder.gd`
- `tests/run_tests.gd`

No M19/M20 production gameplay file changed. No `difficulty_rules.gd`, `production_level_validator.gd`, generic M09 importer, source artwork, canonical M21 LevelData/preview/metadata or reference composite changed in the V03 implementation commit.

This matches the authorized V03 correction surface.

---

## 2. Locked-identity recheck

Independent GitHub reads at audited commit confirm:

- Owner source blob: `b565743ba52699899007882b750b7c8e7cdd00f9` — unchanged.
- M20 `CompleteClearingLoop` blob: `06391839523cbc27e88a4b3ef12b730012cd45fa` — unchanged.
- M20 `ScrubbotDispatcher` blob: `eee10149e4f116af6706beec832042352bf3a6dd` — unchanged.

No protected accepted gameplay subsystem was opportunistically rewritten.

---

## 3. F-M21-STRICT-003 path-resolution residual

### Result: ACCEPTED

The V02 residual was real: alias comparison and destination preflight could interpret a bare-relative path against different bases. V03 now introduces one explicit physical resolver:

```text
_resolve_physical(path)
  res:// / user:// -> ProjectSettings.globalize_path
  bare relative    -> explicitly base at res://, then globalize
  absolute         -> preserve as absolute
  all              -> simplify lexical . / ..
```

`_canon()` builds comparison identity from that resolved physical path and applies Windows case-folding only for comparison. The physical I/O path keeps its case.

The same resolver now feeds:

- source/destination alias identity,
- destination/destination alias identity,
- destination object/parent preflight,
- existing-content planning,
- final output/preview/metadata writes.

This closes the AL-013 split-identity problem. A destination is no longer checked as one physical path and written as another.

### Direct evidence accepted

V03 adds direct tests for:

- legitimate bare-relative output/preview/metadata written to the equivalent `res://` physical location;
- deterministic rerun reporting all three artifacts `UNCHANGED`;
- bare-relative source-equivalent alias rejection;
- bare-relative vs `res://` destination alias rejection;
- bare-relative vs absolute destination alias rejection;
- dot-segment alias rejection;
- source alias rejection even with `overwrite=true`;
- existing-different preview rejection before output/metadata mutation;
- existing-different metadata rejection before output/preview mutation;
- metadata-directory rejection under both overwrite modes before earlier writes;
- output-directory rejection under both overwrite modes;
- non-directory parent rejection;
- a bare-relative later-preview missing-parent failure that proves the earlier output is not written;
- owner-source immutability across the cases.

The tests are load-bearing with respect to the V02 root cause because the successful bare-relative case would fail if preflight returned to process-CWD semantics, and the equivalent-path alias cases would fail if alias identity and write identity diverged again.

---

## 4. Frozen V01 findings

### F-M21-STRICT-001 — one difficulty identity

**CLOSED / not reopened.**

V03 does not modify the accepted V02 implementation. Explicit compatibility difficulty must equal `raw.difficulty`, TEST/unknown/empty values reject, and successful production normalization continues through production validation.

### F-M21-STRICT-002 — arbitrary Variant fail-closed

**CLOSED / not reopened.**

The exact-LevelData boundary remains in place before raw field dereference.

### F-M21-STRICT-004 — reproducible reference evidence

**CLOSED / not reopened.**

The deterministic reference-composite generator remains unchanged by V03 and Claude reports two unchanged reruns.

---

## 5. Fresh real-art direct evidence

### Result: ACCEPTED

V03 adds a fresh real bundle and directly asserts the exact candidate populations:

- C01 = 30
- C03 = 5
- C08 = 298
- C11 = 11
- C16 = 56

The blocked non-C08 call proves exact zero gameplay side effects across BoardState, all five candidate buckets, reservation count, dispatcher count and clear count.

The first real C08 success now directly observes the actual returned assignment identity before and after arrival:

- target is C08 and ACTIVE before arrival;
- target↔owner reservation exists;
- dispatcher owns the assignment;
- real agent reports MOVING;
- arrival increments cleared count by exactly one;
- exact target becomes CLEARED;
- candidate index removes that target;
- reservation is released in both directions;
- dispatcher ownership and active count are cleaned up;
- renderer alpha for the exact cleared target becomes 0.

The fresh run then continues through the real production path until an initially blocked non-C08 color opens and clears, with no forced target or fault seam.

This is strong direct observability for the M21 gameplay chain.

---

## 6. Runtime evidence

Claude records the following E1/E2 runtime results:

- Godot `4.7.1.stable.official.a13da4feb`.
- Root suite: **4534 / 4534 PASS**, V02 baseline 4475 retained.
- Dedicated M21 real-art smoke: PASS, 400 clears / 5 colors / final clean state.
- Required M20 queue-free and lifecycle smokes: PASS.
- M21 debug scene headless boot: clean, zero SCRIPT/Parse errors.
- Canonical M21 level builder rerun: output/preview/metadata all unchanged.
- Reference-composite generator x2: unchanged / unchanged.
- `git diff --check`: clean apart from explicitly documented pre-existing line-ending advisories.

This auditor did not independently execute the local Godot binary; runtime command results above are Claude execution evidence and are cross-checked against the committed tests/source rather than treated as independent execution.

---

## 7. Residual evidence finding

### F-M21-V03-EVIDENCE-001 — preview-directory false-mode direct assertion missing

**Severity:** LOW / evidence-only

V03 criterion 49 requires an existing directory at the preview destination to reject under both `overwrite=false` and `overwrite=true` before output mutation.

Committed evidence currently provides:

- V02: preview-directory rejection with `overwrite=true` and proof output was not written;
- V03: output-directory rejection under false+true;
- V03: metadata-directory rejection under false+true.

The direct `preview-directory + overwrite=false` cell is not present.

Source inspection shows `_preflight_destination(path, _overwrite)` rejects `DirAccess.dir_exists_absolute(real)` before any overwrite-dependent behavior, and `_overwrite` is intentionally unused. Therefore I do **not** classify this as a production-safety defect. V04 must add the missing direct assertion so the strict matrix is complete.

---

## 8. New owner manual-playtest findings / decisions

These are new facts discovered after the V03 implementation and therefore are not retroactive implementation failures by Claude. They become V04 requirements.

### F-M21-OWNER-PLAYTEST-001 — target priority must be bottom-most, then left-most

Current `TargetSelector` explicitly chooses the first targetable candidate in ascending row-major candidate order. With canonical index `y * width + x`, that produces top-first behavior in the live M21 board.

The owner now locks the intended rule:

> For a requested slot/color, eligibility remains unchanged: valid + ACTIVE + matching color + unreserved + currently targetable/reachable. **Among eligible targets, choose the bottom-most target first (largest board `y`); if multiple eligible targets share that row, choose the left-most (smallest board `x`).**

This is a TargetSelector WHAT-policy change. It is **not** a RoutingSystem HOW change. Routing remains responsible only for travel to the already-selected target.

Unreachable bottom/left cells must never be selected merely because of their position. If the highest-priority geometric candidate is blocked, selection proceeds to the next targetable candidate in the same deterministic priority order.

### F-M21-OWNER-PLAYTEST-002 — Scrubbot must be visibly transformed with the board

The owner manually observed clearing without a visible moving Scrubbot.

Source inspection explains the presentation mismatch: the board is rendered by a `TextureRect` scaled to a multi-hundred-pixel board region, while the `ScrubbotAgent` moves in board-local cell units and draws only a ~0.3-cell debug circle. In the current M21 debug scene the dispatcher defaults its agent parent to itself at root scale, so the agent does not share the board's display transform.

V04 must introduce a presentation-only shared transform / AgentLayer so board-local route coordinates map to the exact same on-screen board origin and cell scale as `BoardRenderer`. Do not corrupt ScrubbotAgent's canonical board-local movement truth to compensate.

### F-M21-OWNER-PLAYTEST-003 — five visible slots are required now

`SlotSystem` correctly owns five logical slots, but the M21 live scene does not render them. The owner wants the five-slot system visible immediately rather than waiting for later polish.

V04 must pull forward the minimum production slot presentation needed to make the vertical slice understandable and manually playable:

- five visible slot controls/components;
- each slot visibly communicates its bound level-palette color;
- slot activation dispatches that slot's real color through the existing CompleteClearingLoop;
- the dispatch origin used for route movement corresponds to the visible slot/spawn presentation;
- active/in-flight state is visibly distinguishable without baking gameplay truth into artwork;
- native Godot UI/components, not a flattened screenshot;
- keep final decorative art / booster generation outside this correction unless already required by the existing M22 task contract.

The SPACE-key debug step may remain as a developer fallback, but it is no longer sufficient as the only visible interaction path for final M21 owner playtest acceptance.

---

## 9. V03 criteria conclusion

The V03 production correction is accepted. Criteria 24–48 and 50–100 are materially satisfied by committed E3 source/test evidence plus the recorded runtime evidence. Criterion 49 is only partially direct-evidenced as described in F-M21-V03-EVIDENCE-001.

Because the owner manual playtest surfaced new movement-presentation and slot-visibility requirements and explicitly changed target-selection priority, **M21 remains open** and proceeds to V04 rather than final closure.

V04 is not permission to rewrite routing, reservations, dispatcher, M20 clearing semantics, Difficulty V1, PixelLab/Art Intelligence, or unrelated future UI. It is a focused owner-playtest integration pass plus the one evidence reconciliation cell.

## Final state

**V03 production correction: ACCEPTED**

**M21 final closure: NOT YET**

**Next: M21-C001 V04 — owner playtest integration + target-priority amendment + visible AgentLayer + five-slot playable presentation + final strict closure validation.**
