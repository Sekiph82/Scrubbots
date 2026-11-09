# Review round 1: 135-privacy-consent

Ran (LOCAL_PASS): m58_privacy_consent 7/7, m41_settings PASS, m59_credits 3/3, m60_release_gates 6/6 (its SB-M60-006 aggregate row prints FAIL by design while owner gates are BLOCKED; suite verdict PASS).

Checked and OK:
- Consent switch default OFF, wired only to AnalyticsService.set_consent in privacy_screen.gd (no other caller in scripts/), persisted, test covers relaunch.
- Single CheckButton; ADS is a text line only, no fake toggle. Copy states nothing is sent anywhere.
- Docs marked DRAFT for owner/legal; no compliance or submission claims; 13+ is a recommendation routed to the owner.
- Receipts never pruned, rationale is exactly-once/idempotent delivery.
- Settings: card order unchanged (Reduced Effects in place), PRIVACY shares the CLOSE row after CREDITS, 1080x1920 fit tested.
- EN/TR natural. AGENTS.md change is a one-clause pointer. CI suite plus 7/7 guard present. Diff scope matches the task.

Notes (non-blocking):
- PRIVACY_POLICY_DRAFT Part B says users can delete the cloud copy in Settings -> PRIVACY; that feature does not exist yet. It is in draft Part B (added only when cloud save ships), so acceptable.
- Importing left untracked addons/game_feel_flow .uid/.import files in the worktree (not removable by me; git clean was denied). Delete the worktree at job end.

No must-fix items.

VERDICT: PASS
