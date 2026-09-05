---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-prompt
cycleId: META-C004
version: 2
createdAt: 2026-09-05T22:55:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V02.md
triggerAudit: CHATGPT_AUDIT_V01.md
---

# SCRUBBOTS — META-C004 Narrow Canonical-Truth Correction V02

## FIRST ACTION

Repository:

`C:\Users\sekip\Desktop\ScrubBots`

Canonical branch:

`main`

Fetch origin and inspect:

- local branch;
- local HEAD full SHA;
- origin/main full SHA;
- full `git status --short`.

Safely synchronize only if all pre-existing owner/local work can be preserved.

Do not use:

- git restore;
- reset;
- clean;
- rebase;
- force push;
- destructive checkout;
- checkout-from-origin to erase owner work.

Known owner/tool paths may include:

- tracked local `project.godot`;
- `docs/logs/`;
- Godot `*.import`;
- Godot `*.gd.uid`;
- Claude scratch temp.

Classify and preserve the paths that actually exist now.

Do not create any Desktop/local handoff log.

## Read

1. Audit V01:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CHATGPT_AUDIT_V01.md
2. V02 criteria:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CHATGPT_AUDIT_CRITERIA_V02.md
3. V01 Claude log:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CLAUDE_LOG_V01.md
4. tasks.md
5. docs/00_PROJECT_BRIEF.md
6. current ACTIVE/CLEARED canonical docs
7. CLAUDE.md
8. coordination/AUDIT_INDEX.md
9. coordination/VERSIONED_LOG_POLICY.md

Create and maintain only:

`coordination/sessions/META-C004/CLAUDE_LOG_V02.md`

for Git-tracked Claude evidence.

## Preserve accepted implementation

Do not rewrite accepted V01 gameplay code.

The following are already accepted:

- BoardState ACTIVE/CLEARED;
- transparent CLEARED renderer;
- removal of dirty preset module;
- ColorCandidateIndex rename/API/semantics;
- M13 cache behavior;
- canonical M15/M16 separation;
- Level Factory migration.

This V02 is a narrow docs/tasks/evidence correction.

## Fix F-META4-001 — M48

Update M48 in `tasks.md` without adding, deleting or renumbering any task ID.

Preserve the existing 13 IDs, but make the relevant wording explicitly
represent the new gameplay law.

At minimum M48 must require:

- correct ACTIVE source-color/opaque presentation where applicable;
- correct CLEARED alpha-0 transparency/background visibility;
- solvability under ACTIVE-blocker / CLEARED-open access semantics;
- fully enclosed matching-color ACTIVE cells are not currently targetable;
- no routing pathology under those semantics.

A suggested mapping without new IDs:

- SB-M48-006 Recognizable ACTIVE source artwork.
- SB-M48-008 Correct CLEARED transparency/background visibility.
- SB-M48-009 Solvable under canonical ACTIVE-blocker/CLEARED-open reachability.
- SB-M48-010 No routing pathology; blocked matching-color ACTIVE targets must
  remain untargetable until access opens.

Use precise wording, not necessarily these exact words.

Do not implement M48.

## Fix F-META4-002 — Project Brief

Replace the stale phrase:

`Each level presents the player with an obscured pixel-art image`

with current truth:

the player sees a visible pixel-art image whose cells begin ACTIVE at original
source palette colors.

Scan the rest of the Project Brief for any equivalent implication that the
artwork starts hidden/obscured under grime.

Do not change legitimate statements about background becoming visible through
CLEARED holes.

## Semantic scan

Run a current non-historical semantic scan including at least:

Identifiers:

- DIRTY
- CLEAN
- DirtyCleanPresets
- dirty_clean
- EligibleTargetIndex
- get_eligible
- count_eligible

Conceptual stale language:

- obscured
- hidden artwork
- artwork underneath
- reveal artwork
- under grime
- grime layer
- hidden second artwork
- clean-colored state

Classify hits:

1. current stale -> fix;
2. current explicit supersession/negative statement -> valid;
3. historical evidence -> preserve;
4. unrelated English clean -> preserve.

Do not blindly replace ordinary uses such as:

- clean checkout;
- clean machine;
- clean schema;
- clean clone;
- clean silhouette.

## Git evidence correction — AL-025

The V01 log claimed a receipt that does not exist. Do not try to repair V01.

For V02:

### Before commit

CLAUDE_LOG_V02.md must include:

- exact starting local HEAD;
- exact origin/main;
- equality/divergence;
- full pre-work status;
- classification of every existing owner/tool local path;
- exact changed-file list intended for V02;
- evidence production gameplay files are unchanged;
- semantic scan result;
- unique task total = 943;
- completed task total = 207;
- `git diff --check`;
- full status immediately before commit;
- statement that final exact SHA will be placed in external GitHub receipt,
  not written back into the tracked log.

### Commit

Create exactly one focused V02 correction commit.

Expected changed files should be limited to:

- tasks.md;
- docs/00_PROJECT_BRIEF.md;
- coordination/sessions/META-C004/CLAUDE_LOG_V02.md;
- SESSION_INDEX;
- required H!ve derived tracking files.

Do not modify CHATGPT_AUDIT files.
Do not modify AUDIT_INDEX.
Do not modify production gameplay code/tests unless a blocking reason exists;
if one appears, stop and report rather than expanding scope.

Push safely to origin/main without force.

### POST-PUSH RECEIPT

After push, DO NOT edit/amend/commit the tracked log again.

Post exactly one **GitHub commit comment on the V02 commit** headed:

`## META-C004 V02 POST-PUSH RECEIPT`

It must contain:

- V02 full commit SHA;
- exact final origin/main full SHA;
- explicit proof the two are equal;
- exact prior V01 implementation SHA
  `030bbb3d1ead6caf42fae5e9c29d422f1afc3823`;
- full final `git status --short`;
- classification/reminder of every remaining tracked/untracked owner/tool path;
- progress 207/943 and main+UI 207/719;
- M10-005..011 still open;
- M14 NOT_STARTED;
- no production gameplay code/test changes;
- no LF00/CP00/Magnific;
- confirmation no commit was created after the receipt-proven main head.

Do not create another commit after posting the receipt.

## Mandatory validation

Record each separately in CLAUDE_LOG_V02.md:

1. safe fetch/sync evidence
2. local HEAD full SHA
3. origin/main full SHA
4. full pre-work status
5. classify every owner/tool local path
6. prove none restored/reset/overwritten/staged
7. verify V01 implementation head exists
8. verify current BoardState remains ACTIVE/CLEARED
9. verify renderer remains CLEARED alpha-0
10. verify ColorCandidateIndex path/API remains
11. verify old dirty preset file remains absent
12. verify no M14+ implementation exists
13. inspect M48 before correction
14. correct M48 semantics without task-ID change
15. inspect Project Brief stale phrase
16. correct Project Brief
17. run expanded semantic scan
18. classify every remaining scan hit
19. prove current stale conceptual terms are zero
20. prove historical/supersession references were not erased
21. prove ordinary English clean was not corrupted
22. recompute unique SB IDs = 943
23. recompute completed = 207
24. main+UI = 207/719
25. LF = 0/112
26. CP = 0/112
27. M10-005..011 open
28. M02-017 open
29. all M14 tasks open
30. M15/M16/M17 implementation open
31. production gameplay source diff = none
32. tests diff = none
33. `git diff --check`
34. update SESSION_INDEX
35. update ACTIVE_CYCLES
36. update ARTIFACT_MAP
37. update PROGRESS_SNAPSHOT
38. update PROJECT_DASHBOARD
39. full status before staging
40. exact staged-file list
41. verify unrelated owner/tool paths not staged
42. exactly one focused V02 commit
43. safe non-force push
44. verify commit visible on GitHub
45. verify CLAUDE_LOG_V02 visible on GitHub
46. post exactly one V02 POST-PUSH RECEIPT commit comment
47. verify receipt full V02 SHA == final origin/main
48. full final status in receipt
49. no commit after receipt
50. set META-C004 AWAITING_AUDIT and stop

## Stop

Do not start M14.
Do not start M15/M16/M17.
Do not change production gameplay code.
Do not generate Magnific assets.
Do not implement LF00/CP00.
Do not create/modify any CHATGPT_AUDIT file.
