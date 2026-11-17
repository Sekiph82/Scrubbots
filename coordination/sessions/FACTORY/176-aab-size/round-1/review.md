VERDICT: PASS

Checks: git diff --check clean; *.png diff empty (only .import/.ogv/md/tests/tools changed); ui_vis_006 "UI-VIS-006 ASSET QA: PASS"; "M42 opening evidence: PASS"; "M22-029 TEXTURE COLD/WARM: PASS"; merge-tree with origin/main (jobs 174/175) clean, no conflicts.
Visual safety: rule is limited to assets/ui/final, >=100 KiB, excluding boosters/, gameplay/effects/, branding/; assets/art/levels untouched. Sampled .import files are illustrated art (poses, card thumbs, heroes, home worlds), none pixel-exact. Keyed video sheets and Home/Collection/Robots screenshots show clean keying, no visible halo or banding.
Hashes: PROVENANCE sha256 matches files; m42_opening hash matches the opening. Home keyed videos not in the diff.
Notes: AAB/IPA sizes are estimates (aab_release not dispatched).
