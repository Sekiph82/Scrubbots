# Build 189-preexisting-test-fixes
- events_v02_service.gd: ROBOT_NAMES const removed; opponent display name = ROBOTS[i].capitalize() (identical strings). Removes the literal "Spark" an authority script must not contain (m43 feel f07/f08 guards).
- m22_025: EXPECTED_COUNT 10 -> 9 (booster_tutorial_pointer.png deleted as unused in e8a1e874).
- m22_028: thumbnails expect compress/mode 1 (lossy WebP, intentional AAB-size change b3d68b14).
LOCAL_PASS: m43_master_c005f_feel 10/10, m43_c005f_015_e2e_feel 6/6, m43_c005f_phase3_meta_rewards_acquisition 15/15, m22_025 PASS, m22_028 PASS, ev02_events_ui 6/6, ev02_events_v02 10/10, sb_tf03 11/11, sb_tf07 14/14.
