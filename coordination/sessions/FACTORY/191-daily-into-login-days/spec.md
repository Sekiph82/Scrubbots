# 191-daily-into-login-days (SB-TF-11) — owner 2026-11-19
Owner: "Home'daki Daily odullerini Profildeki Login Days tablosuna aktar. Login Days 2 yaziyor ya, oradan bahsediyorum profildeki. Ard arda giris icin verilecek oduller buradan verilsin."
1. Remove the Daily activity button from Home (and the automatic Daily "Day N" / ScrubBox popups shown on Home/app open, if any).
2. Profile's "Login Days" stat/card becomes the place for consecutive-login rewards: tapping it opens the existing daily-reward ladder (same rewards, same DailyService/economy rules, same claim idempotency and tx ids); the card shows a claimable badge/dot when today's reward is unclaimed. The claim plays the shared reward reveal (main.request_reward_reveal) like today.
3. Do not change reward amounts, streak rules or save format beyond what is needed; migrations must keep existing streaks.
Acceptance: updated tests that pin the Home Daily button / Profile layout (sb_tf03_home_profile and daily suites) pass; new test: Profile Login Days opens the ladder, claim works once per day, badge clears; evidence PNGs EN+TR Profile with badge + opened ladder under factory/jobs/191-daily-into-login-days/evidence/.
