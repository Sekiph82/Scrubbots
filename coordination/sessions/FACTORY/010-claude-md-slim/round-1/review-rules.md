VERDICT: PASS

## Findings
None.

## Notes
- Archive blob equals origin/main:CLAUDE.md (a40ed557...), checked by git rev-parse.
- Section byte-compare (own script, split on "## " headings): section 0D, 2, 4, 6-19 and Economy are byte-identical. Only sections 1, 3 (rule 16), 5 and 20 differ, as the spec allows. The old 0, 0A, 0B and 0C are replaced by the new "0. Still-valid standing rules".
- Only CLAUDE.md and the archive changed (git diff --stat).
- The standing rules keep: TASKS.md as only tracker, honest CHATGPT/owner/review labels, honest test labels, owner-work preservation, no secrets, 0D.5 owner gates (store release, R2 production, spending), and the 0C board color-assist symbol rule in full.
- Dropped and judged obsolete or covered elsewhere: the 20 MiB TEMP rule and Actions zero-spend (retired by 0D), master-prompt V01/V02 and the one-master-prompt style, "compare newest remote main before tracker edits" (factory loop), and the TASKS.md permission-checker "do not bypass" note. Section 3 rules 12-13 and section 4 still cover force-push and owner work.
- The new 0D.5 bullet does not repeat "deleting owner-original art or user saves", but it points at 0D.5, which states it.
