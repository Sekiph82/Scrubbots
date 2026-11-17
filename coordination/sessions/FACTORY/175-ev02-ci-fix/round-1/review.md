VERDICT: PASS

- now() is read-only (max of _hw and clock); _stamp() writes _hw. _stamp is called only in on_receipt (after the dedup/apply step), join (stamped joined_at) and claim (after a successful grant). Other _hw uses are snapshot/restore and a read-only max at line 705.
- Anti-rollback: joined_at, rival state and claimed list are persisted on state change, and each change stamps the high-water mark, so a backwards clock cannot reopen a joined event, rewind rivals or double-claim (claim ids are idempotent). Minor: a window that merely read as ended (no join) is not pinned, so a backwards clock can show it open again. That is harmless because it was never joined.
- New ev02 checks: a snapshot taken before and after list/view/active_count/claimable_count at a +1h clock is identical (read-only), and an applied receipt sets snapshot hw == the clock (stamping). Both directly assert the claimed property. The existing backwards-clock checks remain.
- git diff --check: clean.
- ev02_events_v02.gd: "EV02 events service evidence: PASS (10/10 cases, 0 fail)"
- m43_c001a_results_foundation.gd: "M43-C001A results foundation evidence: PASS (11/11 cases, 0 fail)"
