STATUS: READY

# Build: verify-close SB-UI-017..019

## Summary
TASKS.md only: ticked SB-UI-017 and SB-UI-018 with evidence; SB-UI-019 left unticked and added to the "Not queued (standing rules)" comment; queue row set to DONE.

## Acceptance criteria
1. [x] SB-UI-017: scripts/ui/popup/base_popup.gd exists; reused by popups.gd and 14 screen scripts (grep). CI run 39828088266: m43_c003_c001_acquisition, m43_r15_owner_remediation, m50_accessibility_audit exit=0 PASS (all in the workflow suite list).
2. [x] SB-UI-018: popups.gd sets title/body/actions at runtime (set_title/add_action with UiText.t); base_popup header states chrome art is promoted frames and every title/value/CTA is a live Label/Button. No violations found in sampled popups.
3. [x] SB-UI-019: not ticked; moved to standing rules comment.

## Validation
git diff --check clean (CRLF warning only). Tree clean after commit.

## Log
### Round 1
Done as above. Note: m43_c002_c001_popup_modal_pause is not in the CI suite list (only the three suites above cover BasePopup in CI).
