VERDICT: PASS

Checks
- m57_native_providers.gd: "M57 native providers evidence: PASS (8/8 cases, 0 fail)"
- m57_store_products.gd: "M57 store products evidence: PASS (9/9 cases, 0 fail)"
- git diff --check origin/main...HEAD: clean
- Rebase onto origin/main: textual conflict only in android-family-first10.yml (adjacent edits: input list, billing_ads step vs job 168/174 additions). Mechanical, keep both. ios-ipa.yml and docs merge cleanly.

Purchases (verified in code): grant only via StoreService.deliver on outcome purchased with token (tx store:<token>, once); save precedes acknowledge/consume/finish and a failed save leaves it unacknowledged; PENDING/cancel/error grant nothing; launch queryPurchases re-delivers only unacknowledged PURCHASED, idempotent via tx id; restore applies only no_ads; iOS auto-finish off, finish only in acknowledge.
Ads: rewarded completed+verified only if earned callback preceded close, _rw cleared on first close (once); failed show = failed; UMP -> ATT(iOS) -> initialize -> loads; only Google sample ids (3940256099942544) committed, is_real=false; no new placements.
Default builds: providers installed only if singleton exists (plus Admob.gd present); steps gated by inputs.billing_ads (default false). Plugins sha256-pinned, MIT. No secrets echoed.

Notes (non-blocking)
- Rebase onto origin/main before merge; resolve the Android workflow conflict by keeping both sides.
- billing_ads is not wired into the new aab_release path (job 168); a Play AAB would lack the plugins. Needs a follow-up before a real release.
- m57_native_providers is not in the workflow validate test list.
