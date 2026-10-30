VERDICT: PASS

## Findings
None.

## Notes
- The badge count is the existing meta_ui NEW truth (owned and not yet viewed). Nothing in `scripts/` marks a card seen when a pack opens (only the set detail does), so a fresh pack card shows on its set until the player views it. That matches the owner request.
- The economy lock holds. `_show_set` calls only `mark_seen` and `app.mark_dirty`, and both are presentation-only. There is no grant, spend or claim path. The build log says k18 and k19 compare SB, Bot Parts and the collection snapshot before and after, but I did not run the tests myself.
- No new art, currency, timer or mechanic. The badge reuses the Home shortcut badge through `make_badge`, and the arrows are native Buttons.
- Touch targets are 88 px (`UiTokens.TOUCH_MIN`).
- The new strings go through `UiText` (`COLLECTION_PREV_SET` / `COLLECTION_NEXT_SET`), like the other keys. The "<" and ">" glyphs are untranslated by design.
- The TASKS.md diff is two inserted lines, both for this task. They use LOCAL_PASS, name no CI run, and claim no owner acceptance. I did not verify the CRLF line endings.
- I did not re-run the suites. This review covers rules only, from the diff and the build log.
