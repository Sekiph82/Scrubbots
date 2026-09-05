---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-prompt
cycleId: META-C002
version: 2
createdAt: 2026-09-05T13:09:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V02.md
triggerAudit: CHATGPT_AUDIT_V01.md
pr: 3
branch: feature/master-ui-magnific-pipeline
---

# SCRUBBOTS - META-C002 Visual Truth & Merge Reconciliation V02

## FIRST ACTION — synchronize before all other work

Repository:
`C:\Users\sekip\Desktop\ScrubBots`

Work on:

`feature/master-ui-magnific-pipeline` / PR #3

Before implementation:

1. fetch origin;
2. confirm the local feature branch and preserve all owner work;
3. safely synchronize with `origin/feature/master-ui-magnific-pipeline`;
4. safely integrate the latest `origin/main`, including the final M12 audit;
5. do not rewrite published branch history;
6. do not use reset --hard, clean -fd, force push or destructive checkout.

Do not create any Desktop/local handoff log. All durable V02 evidence belongs
only in:

https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V02.md

## Read first

- Audit V01:
  https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V01.md
- Audit criteria V02:
  https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_CRITERIA_V02.md
- V01 prompt/log:
  https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_PROMPT_V01.md
  https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V01.md
- Final M12 audit on main:
  https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_V02.md
- Governance:
  https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/CLAUDE.md
- tasks.md
- assets/art/references/README.md
- assets/art/references/inventory.json
- assets/art/references/_owner_inbox/README.md
- ASSET_GENERATION_MANIFEST.json
- docs/MASTER_UI_SYSTEM.md
- docs/07_UI_ASSET_PIPELINE_DECISIONS.md
- coordination/AUDIT_INDEX.md
- H!ve tracking files

## Objective

Close F-META-001..004 without changing the accepted UI architecture or
starting broad/final Magnific generation.

## 1. Preserve migration integrity

After integrating current main, prove:

- every canonical SB task from current main exists exactly once;
- exactly 95 UI/Magnific tasks from the appendix remain added exactly once;
- no checkbox truth from main regressed.

Do not resurrect `docs/UI_TASKS_APPENDIX.md`.

## 2. Build durable owner-reference inventory

The 51 imported files already exist in:

`assets/art/references/_owner_inbox/`

Do not re-copy them unnecessarily and never modify/delete Desktop originals.

Extend the canonical machine-readable inventory non-destructively so every
imported file records at least:

- repository path;
- original relative source path/filename;
- SHA-256;
- image width and height;
- classification category;
- provenance/source class;
- approval state;
- canonical/non-canonical/owner-required state;
- notes for duplicate, external-inspiration or ChatGPT-generated provenance.

Use actual file inspection. Do not infer dimensions from screenshots or names.

Where:
`C:\Users\sekip\Desktop\ScrubBots Gorselleri`
is available, calculate source SHA-256 and prove it matches the repository
copy. This is read-only verification. Do not write any Desktop log.

Preserve existing M07 historical inventory entries rather than deleting
history. Update/supersede their current availability truth cleanly.

## 3. Correct classification

Do not classify every owner-supplied file as OWNER_ORIGINAL.

Examples already identified:

- Playing Motors reference is external inspiration.
- similar-game level screenshots are reference/external material, not
  production SCRUBBOTS level source.
- the file explicitly named "made by chatgpt" must retain that provenance.
- duplicate cleaning-crew files remain preserved and marked duplicate.

Do not close M07 production-level-art tasks from external/reference screenshots.

## 4. Durable canonical reference registry

Record repository paths for:

- gameplay canonical: `Game Screens/deneme 3 OK.png`;
- Home canonical: `Game Screens/main screen.png`;
- level-intro popup: `Game Screens/level ekran acilisi.png`;
- life popup: `Additionals/life screens.png`;
- help popup: `Additionals/need a hand.png`.

Scrubby master remains:

`OWNER_REQUIRED`

with the two documented candidate sources, unless the owner separately makes
a choice. Do not choose one yourself.

## 5. Manifest truth

Update `ASSET_GENERATION_MANIFEST.json` so it no longer says reference
intake is pending.

It must distinguish:

- intake complete;
- gameplay/Home/popup canonical references selected;
- Scrubby master selection owner-blocked;
- Scrubby-dependent generated assets still blocked.

Do not start generation.

## 6. Reconcile tasks.md with actual evidence

After inventory/hash/canonical records pass, review and close only directly
proven tasks.

Expected candidates include, if evidence really satisfies them:

- SB-M07-008 Scrubbot character visuals inventory;
- SB-M07-009 gameplay-screen references inventory;
- SB-M07-010 five-slot visual references inventory;
- SB-M07-014 pixel-construction reference inventory;
- SB-UI-005 owner reference import;
- SB-UI-006 source preservation + inventory;
- SB-UI-007 classification;
- SB-UI-009 gameplay canonical selection;
- SB-UI-010 Home canonical selection;
- SB-UI-011 popup/intro canonical selection;
- SB-UI-012 conflicting/outdated reference classification.

Keep SB-UI-008 open as `OWNER_REQUIRED`.

Keep SB-UI-013 open unless its entire manifest-reference condition is actually
satisfied despite the unresolved Scrubby owner gate.

Do not close M08 or production level-art tasks from reference screenshots.

Update old "all categories missing" notes so they are historical/superseded,
not current falsehoods.

## 7. Correct progress counting

Do not reuse the V01 166/778 figure.

Before V02 task closures, independent audit found:

- feature branch canonical tasks: 943;
- completed: 185;
- remaining: 758;
- completion: 19.62%.

Recalculate again from the final V02 `tasks.md` using unique canonical SB
task IDs.

Record:

- ecosystem completed/total/remaining/percentage;
- main mobile-game + SB-UI completed/total;
- Level Factory completed/total;
- Content Pipeline completed/total.

Update PROGRESS_SNAPSHOT and PROJECT_DASHBOARD to match exactly.

Do not rewrite CLAUDE_LOG_V01 to hide the old miscount. Record the correction
in CLAUDE_LOG_V02.

## 8. Validation

Record each separately in CLAUDE_LOG_V02.md:

1. feature branch safe sync
2. latest origin/main safely integrated
3. M12 final audit visible on feature after integration
4. no current-main task ID lost
5. exactly 95 migrated UI tasks present exactly once
6. all 51 inbox files enumerated
7. all 51 repository SHA-256 values recorded
8. all 51 dimensions recorded from actual files
9. source-vs-repo hashes match where Desktop source available
10. category/provenance classification complete
11. duplicate/external/ChatGPT-generated provenance preserved
12. inventory category summaries no longer falsely MISSING
13. reference README current-availability truth updated
14. gameplay canonical repo path recorded
15. Home canonical repo path recorded
16. popup canonical repo paths recorded
17. Scrubby remains OWNER_REQUIRED with candidate paths
18. manifest intake status corrected
19. Scrubby-dependent generation remains blocked
20. task truth reconciled conservatively
21. M08/production level-art tasks remain unclosed unless independently proven
22. final unique-ID task count recalculated
23. H!ve progress matches tasks.md
24. project.godot/UI foundation parse/startup validation
25. full Godot regression suite
26. BoardRenderer/WHAT-vs-HOW boundaries unchanged
27. no broad/final Magnific generation
28. no Higgsfield dependency
29. git diff --check
30. final scope/binary/temp inspection
31. SESSION_INDEX update
32. ACTIVE_CYCLES update
33. ARTIFACT_MAP update
34. PROGRESS_SNAPSHOT update
35. PROJECT_DASHBOARD update
36. PR #3 updated with corrected counts/truth
37. PR #3 remains draft/unmerged
38. focused correction commit(s)
39. safe non-force push
40. verify CLAUDE_LOG_V02 and correction commit visible on GitHub
41. final git status

## Stop

Set META-C002 to `AWAITING_AUDIT` and stop.

Do not merge PR #3.
Do not start M13.
Do not start broad/final Magnific generation.
Do not create or modify CHATGPT_AUDIT files.
