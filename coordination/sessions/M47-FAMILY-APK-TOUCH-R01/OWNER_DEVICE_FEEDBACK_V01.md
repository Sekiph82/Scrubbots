# M47-FAMILY-APK-TOUCH-R01 — Owner Real-Device Feedback V01
Date: 2026-10-10
Repository: `Sekiph82/Scrubbots`
Build: offline first-ten debug APK, GitHub Actions run `38040561355`, built source `857d90330247561bc4bfe8a548cca2f42e7eba55`.

## Direct owner feedback
1. "apk yi acti karim. oyun aciliyor. ama supply daki renk seciminde sikinti var, dokunmatik olmasi lazim. uzerine bir defa tiklayinca supply daki renk batchinin 5li slot sistemine cok kolay aktarilmasi lazim ama olmuyor"
2. "tutup 5li slota dogru ittirmen lazim sanki"

Interpretation: owner reports that a *drag/swipe toward the five-slot strip appears necessary* to make Supply selection work. This is an **observation/hypothesis**, NOT an established input-code root cause, and it is NOT a request to implement drag control.

## Owner acceptance law
- **Single simple finger tap** (touch down + touch up without significant movement) on a valid FRONT/row-0 colored batch, with no dragging, holding, aiming at slot or second tap, must transfer **exactly one** complete batch through the canonical production transaction into the **rightmost EMPTY** execution slot.
- 5-slot normal and legitimate +1 Slot six-slot mode, 3/4/5 Supply-column masters, portrait Android safe areas, uniform shell scale and different phone aspect ratios all preserve hit alignment.
- Row-1/2 previews are not interactive. Empty/exhausted fronts, all full slots, paused/terminal/modal states must remain fail-closed, atomic and without duplicate consumption; there is no transfer when input is invalid.
- User should not have to swipe the batch toward a slot or manually target a destination slot. A drag gesture does not become the recommended or primary input method.
- This is a **blocking Android usability bug** in the first family build; it takes immediate priority over cosmetic follow-ups and the unrelated M55 quiescence QA.

## Verified and unknown
- OWNER-REPORTED: APK was installed on wife's Android phone and game **opens**. Treat `SB-M47-003` install/launch as owner-observed PASS.
- OWNER-REPORTED: Supply → slot one-tap flow **FAIL**. `SB-M47-004` touch acceptance remains OPEN.
- Unknown: phone model/OS, precise swipe reproduction, runtime GUI event delivery, layout/hitbox routing, production transaction outcome. Claude must instrument and prove the specific failure mechanism; do not preselect a diagnosis.
- M47 export/package technical PASS is unchanged, but family gameplay readiness is **CHANGES_REQUIRED / TOUCH-R01** pending a new APK and actual owner device retest.
