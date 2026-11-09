APPROVE

Orchestrator decision (one reviewer, owner rule). Round-1 review PASS: m47_touch_r01_mobile_ux 14/14 exit 0 twice, m43_c005f_phase4_terminal_home_micro 19/19 exit 0; negative control (reset removed) segfaults (exit 139). Root cause of CI run 42689938795 exit-crashes: test lambdas left in main.gd static boot_*_override Callables outlived the test script once factory 144 let main.gd free at exit. All assigning tests now reset them. Linux not reproduced locally (WSL virtualization off); next CI run is the Linux check.
