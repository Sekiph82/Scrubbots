STATUS: READY

# Build: CLAUDE-SLIM — slim CLAUDE.md to §0D + still-valid standing rules

## Spec (light path)
Owner request (Şekip, chat 2026-10-22, "hepsini yap"): simplify CLAUDE.md. Move the superseded §0/§0A/§0B/§0C to an archive, keep §0D and the game rules.
1. Archive current CLAUDE.md byte-for-byte to `docs/migration/legacy-task-trackers/CLAUDE_PRE_SLIM_2026-10-22.md`.
2. Keep §0D verbatim. Replace §0/§0A/§0B/§0C with one short "Still-valid standing rules" section, keeping only rules §0D does not supersede, plus the §0C board color-assist rule and a "Superseded history:" pointer line.
3. Rewrite the ChatGPT-only and prompt-version-log text in §1, §3 rule 16, §5 and §20 as factory-loop pointers. §2, §6–§18 and the Economy section stay byte-identical.

## Summary
Branch commit `be3a7493`. Files changed (only these two):
- `CLAUDE.md`: §0D is unchanged. §0C/§0/§0A/§0B are replaced by `## 0. Still-valid standing rules` (13 lines). It keeps: TASKS.md is the only tracker with no parallel dashboards; no fake ChatGPT/owner/review claims; honest test labels with no fake CI green; owner-work preservation; no secrets; no public store release, R2 production upload or paid spending without the owner (§0D.5); the board color-assist product rule; and the superseded-history pointer. Other edits: the Status line now points at §0D. §1 reading list: `AUDIT_POLICY.md` and the "cycle prompt" items are replaced by the factory SKILL.md. §3.16, §5 (now "Coordination", 3 lines) and the §20 last sentence now point at the factory loop and peer review.
- `docs/migration/legacy-task-trackers/CLAUDE_PRE_SLIM_2026-10-22.md`: new, an exact copy of the previous CLAUDE.md.

## Acceptance criteria
1. [x] Archive byte-identical to origin/main:CLAUDE.md: `git rev-parse origin/main:CLAUDE.md HEAD:docs/.../CLAUDE_PRE_SLIM_2026-10-22.md` gives `a40ed5578d3e42d0696119fd98a9b3d3e658bc2d` for both (same blob).
2. [x] §0D verbatim at top: the edit script only cut from the `## 0C.` heading to the `## 1.` heading. The §0D text appears unchanged at lines 8–15 of the new file.
3. [x] Standing-rules section ≤ ~25 lines including the color-assist rule and the superseded-history line: 13 lines, both present.
4. [x] §1, §3.16, §5 and §20 point at the factory loop: `grep -n "ChatGPT-only\|AUDIT_POLICY\|autonomous delegation 2026-10-15" CLAUDE.md` finds no matches.
5. [x] §2, §6–§18 and Economy are byte-identical: a Python script split old and new files on `^## ` headings and compared the raw bytes of all 15 sections (§2, §6–§18, Economy). Output: `checked 15 sections; mismatches: []` / `OK`.
6. [x] Size: blob 30,692 → 19,016 bytes (30.0 KB → 18.6 KB). Working copy with CRLF: 31,193 → 19,457 bytes.
7. [x] Only CLAUDE.md and the archive changed: `git diff --stat origin/main HEAD` lists 2 files.
8. [x] `git diff --check`: clean for CLAUDE.md (`git diff --check origin/main HEAD -- CLAUDE.md` prints nothing). Over the whole diff it flags one trailing space at archive line 54. That space is in the original §0B paragraph and must stay for criterion 1 (byte-identical archive). The space is gone from the live CLAUDE.md.

## Validation
- Section byte-compare script: PASS.
- Blob-hash archive comparison: PASS.
- `git diff --check` on CLAUDE.md: PASS. On the archive it reports one trailing space, inherited and intentionally kept.
- `git status --porcelain`: empty.
- No code changed, so no Godot suites apply.

## Log
### Round 1
Built the light-path job. TASKS.md has no CLAUDE-SLIM entry and the task limits changes to CLAUDE.md plus the archive, so TASKS.md was not touched. Left for later (not requested): other docs (AGENTS.md, AUDIT_POLICY.md) still describe the ChatGPT-audit flow.
