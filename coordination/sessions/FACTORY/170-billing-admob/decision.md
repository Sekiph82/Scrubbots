# 170-billing-admob decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Owner: connect real purchases and ads ("bagla"), free tools only.

- Merged branch factory/170-billing-admob-r3 @ 36b1f64a (rebased on 4658c2f8; code a5be51a5 + workflow/doc commits): Play Billing / StoreKit / AdMob providers behind workflow input billing_ads (default off = previous builds), grants only on verified purchase saved before acknowledge/finish, rewarded only on earned-before-close, UMP + ATT. Real AdMob ids only for billing_ads + release from GitHub Secrets (never committed/echoed); debug keeps Google TEST ids. Android release package com.sekiphayit.scrubbots (com.sekiph82.scrubbots taken on Play). aab_release supports billing_ads. Summary-step `|| true` fix for the job-168 regression.
- CI: validation_only 44134603570 success (M57-NATIVE 9/9 in the guarded list); apk_only debug+billing_ads 44134628219 success; iOS debug+billing_ads 44126671386 success.
- Not yet exercised: release builds with real ids; device consent/ATT/test ads/sandbox purchase.
