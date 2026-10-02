# Focused test summary

All run individually with Godot 4.7.2 headless. The table run preceded the final addition of two read-only diagnostic fields (`raw_source_png_present`, `strict_mode_valid_here`); the suites touching HomeScreen were re-run afterwards (last paragraph).

| Suite | Result |
|---|---|
| `maint_home_export_asset_gate_c001` | maint_home_export_asset_gate_c001: 11/11 cases, 0 failures |
| `m42_assets` | M42 assets evidence: PASS |
| `m42_home` | M42 home evidence: PASS |
| `m42_home_composition` | m42_home_composition: 9/9 cases, 0 failures |
| `m42_home_v04` | m42_home_v04: 18/18 cases, 0 failures |
| `m42_home_v05` | m42_home_v05: 13/13 cases, 0 failures |
| `m42_home_v06` | m42_home_v06: 13/13 cases, 0 failures |
| `m42_home_v07_safe_area` | m42_home_v07_safe_area: 9/9 cases, 0 failures |
| `m42_c002_scrubby_scale` | m42_c002_scrubby_scale: 7/7 cases, 0 failures |
| `m42_c003_scrubby_animation` | m42_c003_scrubby_animation: 18/18 cases, 0 failures |
| `m42_navigation` | M42 navigation evidence: PASS |
| `m42_opening` | M42 opening evidence: PASS |
| `run_tests` | RESULT: ALL PASS |

Root `tests/run_tests.gd`: Total checks: 5323, Failures: 0.

After the final diagnostic-field addition, re-run: maint_home_export_asset_gate_c001 11/11, m42_home PASS, m42_c003_scrubby_animation 18/18, m42_assets PASS. Additional Home-adjacent suites: m28_c002_c003_r01_remediation 24/24, m28_c002_c003_final_gate 22/22, m43_c002_c001_popup_modal_pause 23/23, m40_v04_bootstrap PASS.
