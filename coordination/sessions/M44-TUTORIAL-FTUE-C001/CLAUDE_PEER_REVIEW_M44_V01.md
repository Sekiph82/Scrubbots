# M44 FTUE — CLAUDE_PEER_REVIEW V01

**Label: `CLAUDE_PEER_REVIEW`** (autonomous mode, `CLAUDE.md §0B`). This is NOT a `CHATGPT_INDEPENDENT_AUDIT` and does not replace `CHATGPT_INDEPENDENT_AUDIT_V01.md`.

- Reviewer: a separate fresh-context Claude subagent (general-purpose), launched 2026-10-15 by the M44 builder session.
  - It was read-only: no edits, no local Godot, CI artifacts read in memory via `gh api`.
  - It reviewed source at HEAD `10feab66`; the tested source `dee10572` differs only in the builder log.
- Transcription: the builder session published the findings below in the reviewer's own wording and structure (lightly condensed). Builder remediation notes are marked **[builder]**.

## Verdict (reviewer)
**PASS_WITH_CONCERNS.** The reviewer found no double-grant, no lost durable claim and no owner-rule violation, and confirmed the CI evidence matches the source. The concerns are performance and design edges plus the still-open owner visual gate (SB-M44-018 / 020).

## Per-item (reviewer)
| # | Item | Result | Evidence |
|---|---|---|---|
| 1 | Fresh-profile detection | PASS | `save_service.gd` sets `fresh` only on the defaults path with no primary / `.bak` / `.tmp` / legacy audio cfg. Corrupt → `fresh=false`; future schema blocked; re-checked by `has_any_save_file()`; pre-M44 saves are established. Covered by t01. |
| 2 | Starter grant | PASS | One tx `ftue_starter_boosters:v1`, booster resources only; replay no-op; save failure restores the pre-bootstrap snapshot and retries only while no file exists; strict config. Covered by t02 / t04. |
| 3 | Welcome task | PASS | Index 0, welcome day == today; `task_reward_sb` single source for shown == credited; global `task_sb` unchanged; 3 slots; ScrubBox 3/3; expiry; rollback refused. Covered by t02 / t06 / t07 / t21. |
| 4 | Durable claim rollback | PASS | Snapshot → op → save → restore + refuse on failure. Tx idempotency prevents a second grant. Nested pending-bootstrap retry is correct. No path loses a saved claim (`save()` reports ok only after the final rename). |
| 5 | Tutorial scope | PASS | Config rejects lessons > L3; frontier + exact level-id match; `settle()` closes after L3; economy-call static guard; Skip only sets `skipped`; Help has one CLOSE action; cinematic untouched. |
| 6 | What's New | PASS / CONCERN | Keyed `feature:<id>:<ver>`, CTA-acknowledged only (t17). See D2. |
| 7 | `boot_ftue_override` seam | PASS | Default -1 = ON for the canonical save path; nothing outside tests sets the override statics, so production cannot run with it off. |
| 8 | Test quality | PASS / CONCERN | Real AppState / facade / save / `main.tscn` assertions, not tautologies. Untested: a claim while a bootstrap is pending; L2 tick cost; What's New for future versions on "new" profiles; GOT IT / SKIP overlap over gameplay controls (t18 checks the Home layout only). t06 uses `mark_task_done` directly. The cinematic guard is a weak string check. |
| 9 | CP06 fixed clock | PASS | `dee10572` changes only the AppState clock argument; assertions unchanged. The run-3 failing conjunction compares the full economy snapshot, which holds clock-derived fields; it passed in run 2 on the same M44 code. |
| 10 | Workflow | PASS | Manual dispatch only; default `validation_only`; export `needs: validate` + job-level `build_apk` guard; 34 suites; exact CP06 16/16 + M44 21/21 guards; single `INJECTED` allowlist. |
| 11 | Other risks | CONCERN | D1–D5 below. |

## CI verified by the reviewer (`gh api`, in memory)
| Run | Head | validate | export | Artifact | Result |
|---|---|---|---|---|---|
| 38626611950 | `f567947f` | success | skipped | 11925065328, 19 files, no apk / pck / ipa | 17 suites PASS |
| 38632433821 | `e54b82df` | failure | skipped | 11927706876 | CP06 i05 FAIL; other 33 PASS |
| 38702447218 | `dee10572` | success | skipped | 11957457198, 36 files, no apk / pck / ipa | 34/34 PASS, CP06 16/16, M44 21/21, `import script_diag=0` |

## Defects (reviewer) and builder disposition
- **D1 Medium (performance).**
  - Finding: the 0.2 s coachmark poll rebuilt the step copy every tick. On L2 booster tips that calls `host.booster_legality()` per booster: Selector runs DeadlockClassifier solvability checks per remaining batch, Random runs ≥ 4 classifier probes on scratch engines. Read-only, but unmeasured on a phone.
  - **[builder]** Remediated in `679f2f6d` (`scripts/app/main.gd`): the copy is cached per step id and rebuilt only on a step change or at most every 2 s (`COACH_COPY_REFRESH_MS`). Validated by the 35-suite run listed in `CLAUDE_LOG_V01.md` / the M45 log (shared workflow run).
- **D2 Low-Medium (design, OWNER CALL).**
  - Finding: `whats_new_due()` returns nothing for any `profile == "new"`, whether or not tips are closed or skipped. Every M44+ player would never see a FUTURE What's New entry.
  - The reviewer suggests gating on `tips_active()` instead, and marking current entries seen at bootstrap.
  - **[builder]** Not changed. Recorded as `OWNER_DECISION_NEEDED` (it changes who sees future feature announcements).
- **D3 Low.** Finding: if the cold-boot bootstrap save fails, the restored profile counts as established, so a brand-new player may see the Help & Tips What's New; acknowledging it saves, which retries the bootstrap. **[builder]** Accepted as is (rare double-failure path; no economy effect).
- **D4 Low.** Finding: the imported `welcome_sb` accepts any value ≥ 1 and is not tied to config (local-tamper only). The L3 Hearts copy hardcodes "3" while the threshold lives in `failure_assistance_v1.json` (drift risk; accurate today). **[builder]** Open, low.
- **D5 Low (visual).** Finding: the GOT IT / SKIP row (≤ 820×88, STOP) can sit over non-target gameplay controls (Supply / slots / boosters); only the Home layout is tested. **[builder]** Part of the owner visual gate SB-M44-018 / 020.
- Note (reviewer): the 1380 leaked ObjectDB instances in `m44_ftue.log` match the pattern of other suites (undisposed test AppState graphs). Not M44-specific.

## NOT_RUN (reviewer)
- On-device behaviour, performance and touch overlap: owner visual SB-M44-018 / 020 pending.
- The owner's run-4 chat approval is recorded only in the builder log.
- Laptop disk figures.
- No local Godot run.

## Resulting M44 status (builder, autonomous tracker provenance `CLAUDE_AUTONOMOUS_REVIEW`)
`IMPLEMENTED_CI_PASS_CLAUDE_PEER_REVIEWED_PASS_WITH_CONCERNS` · `AWAITING_EXTERNAL_AUDIT` (optional ChatGPT re-audit) · `PENDING_OWNER_VISUAL` (SB-M44-018 / 020) · `OWNER_DECISION_NEEDED` (D2).
