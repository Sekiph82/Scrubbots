# Review round 1: 124-localization-en-tr

## Checks
- git diff --check origin/main...HEAD: clean.
- python -I key/placeholder check (EN vs TR, regex over the const dicts): every EN key except the `_ONE` plural forms has a non-empty TR entry; placeholders identical and in the same order. The only diff flagged is SETTINGS_PERCENT `%d%%` vs `%%%d`, which formats to the same "%75" text (a regex artifact, not a bug). The 3 "extra" keys and the empty FTUE_BOOSTER_INTRO_BODY are parser artifacts (trailing comments / EN is "" too).
- tests/m51_localization_readiness.gd: PASS (8/8).
- tests/m41_settings.gd: PASS.
- tests/m43_master_c011_c014.gd: PASS (29/29).
- project.godot restored; only import `.uid` churn is untracked in the worktree (not committed).

## Findings
None.

## Verified
- Language selection: `resolve_language` saved > device > EN. The shipping save follows device/saved. A test save applies only an explicit saved choice.
- Save field: `language` is optional, written only once chosen, strict-validated ("en"/"tr", string type). A missing key means auto, so older saves load unchanged. An unsupported value rejects the candidate, the same as other bad settings.
- Reload on change: `set_language` saves synchronously before the emit. The reload only happens when main is `current_scene`, deferred. Settings is Home-only, so it never runs during gameplay, and there is no economy effect. LaunchSession stops the opening replaying.
- Settings: one LANGUAGE card added after COLOR SYMBOLS; Reduced Effects is unchanged in place. Buttons reuse the existing BasePopup constants; no theme colour changes.
- `tn`: `_ONE` only when n == 1 and EN; TR keeps the singular noun. `num` groups as "1.000" in TR. `data()` falls back to the data file's own copy, so ids and rewards are untouched (only display strings are routed).
- Guard: a narrow allow-list (the "II" glyph) and a self-check with planted violations. The CI check changed 4/4 to 8/8 and matches the test summary string exactly.
- Runtime `to_upper()` is applied only to ASCII ids, so there is no Turkish dotless-i problem.

## Notes (non-blocking)
- The Turkish is natural overall (OYNA, DEVAM, ORTA, "Kalplerin dolu. Bir temizliğe ne dersin?", "Kaçırırsan yalnızca bu seri baştan başlar"). Possible polish for the owner read-through:
  - "Sende x%d" (COLLECTION_OWNED) is fine, though "Adet: x%d" is a bit more standard.
  - "GALİBİYET %s · ŞİMDİ" is a little stiff; "ZAFER" or "%s GALİBİYET" would be shorter.
  - "Seçmeli Güçlendirici" is understandable; "Seçtiğin Güçlendirici" reads more natural.
  - "KULLANILAMAZ" for UNAVAILABLE is OK; "MEVCUT DEĞİL" is an alternative.
  - "Bölüm" for Level and "Kalp" for Heart are consistent and fine.
- Nothing is meaning-wrong.
- SB / Scrub Bucks kept as brand names, as documented.

VERDICT: PASS
