# SB-M42 HOME ART PROMOTION — Claude Implementation Log

Prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-ART-PROMOTION.md`
Criteria: `coordination/sessions/M42-C001/audit_criteria/SB-M42-HOME-ART-PROMOTION.md`
Owner authority: `coordination/OWNER_M42_HOME_ART_COMPLETE_APPROVAL_V01.md` + its 10 batch approvals
(BACKGROUND, CENTRAL_WORLD, ENVIRONMENT, HELPER_BOTS, SCRUBBY, TOP_HUD_CURRENCY, GIFT_SHORTCUTS_A,
SHORTCUTS_B, PLAY_REWARD_TRACK, BOTTOM_NAV).

| | SHA |
|---|---|
| Baseline HEAD (clean tracked worktree) | `1cd31e7` |
| Implementation commit | `317b1e1` |

Handoff: `AWAITING_CHATGPT_AUDIT / M42 HOME ART PROMOTION`

## Changed text files (1cd31e7..317b1e1)

- `assets/ui/HOME_ASSET_MANIFEST.json` — 50 entries: `"status": "PLANNED"` -> `"APPROVED"` and one
  `"approved_sha256"` line added per entry. The diff contains only those lines (100 +, 50 -). No id,
  slug, path, provider, reuse relationship or notes changed.
- `tests/m42_assets.gd` — expectations moved to the owner-approved production state (details below).
- `tests/m42_home.gd` — 3 assertions that encoded the pre-approval state (nothing bound) were
  updated to the approved state. Un-approval is now simulated on an in-memory copy instead.
  Needed because production Home now binds the approved art.

`scripts/tools/home_asset_manifest_validator.gd` and `scripts/ui/home/home_art_binder.gd` are
**unchanged**. The SHA-256 pin rule remains authoritative.

## Procedure

1. Every approval row (`| ID | slug | path | blob |`) was parsed from the 10 batch files: 49 rows, no
   duplicates. The ID set equals the 49 IDs listed in the complete approval.
2. Manifest checks: exactly 49 `kind=ART && generation_required=true` entries, and their IDs equal the
   approved set. There are 50 ART entries in total. The only non-generated ART entry is `HOME-087`,
   whose path equals `HOME-042`'s path.
3. Blob verification, before any change: for each row, `git rev-parse HEAD:<path>` ==
   `git hash-object --no-filters <path>` == owner-recorded blob, and each manifest slug/path matched
   its approval row. **49/49 matched, 0 errors.**
4. `approved_sha256` = SHA-256 of the actual PNG bytes. For each file I also confirmed that the SHA-256
   of the HEAD blob content is identical.
5. The manifest was edited in place as text to preserve formatting. HOME-087 received HOME-042's pin.

Promoted entries: **50** (49 unique approved files + the HOME-087 reuse).

## Evidence per file

| ID | Slug | Git blob (owner = HEAD = worktree) | approved_sha256 | Bytes |
|---|---|---|---|---|
| HOME-001 | home_bg_sky | `5aad601e11f4146afb051ab9769e6dfe81597e19` | `d0353c68c944a188b53256e028f483873b4abe23fb4cc76bdddcba8e2803779c` | 1389273 |
| HOME-002 | home_bg_city_far | `dfe608a6f2b71b18b0631e22c49e9c06ea660a20` | `d1ff336dc6d076654c3ff3177b97d86c87b7b74b542403a1cd98f81886fbd1f9` | 1333722 |
| HOME-003 | home_bg_city_mid | `13a4f0e18c6ef01dc89b8a0df1e227d53fe25f67` | `cf8403d29e033594d24d9f1a7b8b1dd1e36804b15dcbb3f4affe8eda299cbd78` | 2525140 |
| HOME-004 | home_bg_street_foreground | `5cf8ff38d2ba244f8a6fd6cb8d0518716db92f9b` | `3b3ef164d5a5945259eb53ef3720f3fb55fae0afcb8410f9d98d11a154bd772d` | 1301742 |
| HOME-006 | home_arch_whispering_park | `b4783fe6f6c15ba93d1a6eb15db5c2bd38114cd9` | `b6cea5f6f16974884c81cbaef0050fddd29ad3965f78ec57fefa096b4d528046` | 1774284 |
| HOME-007 | home_arch_decor | `f94257359f860914d59382d06ae540f1ef232995` | `af4d834a07f926906056a9e0b3a1608d6af285b14a741da4ce53c3fdc85591b2` | 1225643 |
| HOME-010 | home_platform_main | `f490a667a355968a80f9f8163e7f4f2eaf6a09d7` | `61f4b715da49f4bf08a8cf32bfef778168e33689c2f4bf4b5d0eecfc511d7999` | 2112595 |
| HOME-011 | home_platform_top | `91c3897e91424d1230451d5a76c0154bdd9f8962` | `3b0b1187c6d0c32465a67713b31b986730e09ce744e5c669f00bd3f7159f9e70` | 1801797 |
| HOME-013 | home_prop_cleaning_bucket | `d17785d44ca3b72102b4cc8e4e93489db4f3d9d2` | `7681d0adaaa6506da968904bf1262c57301a01446d743a4e3aa69c94c30f7eea` | 1466978 |
| HOME-014 | home_prop_hose | `64a82a0fc84245885d190f06c40841dbe6b0e0f3` | `38c214d93ff8222c0ba71f7a3f0e776dd46940e3873e44427acf32abd263df2a` | 1555110 |
| HOME-015 | home_prop_foam_cluster | `a4d55174fe4b99ec1d2b9235bb532e4a39f2ab62` | `ba69053c78c468326a91bff32abba51f742cd9d75616eb33086e548067bf2aa0` | 1305053 |
| HOME-016 | home_prop_puddles | `eacdaa839ef1354646d4f2d339546b3a9e40831c` | `692271af12062350b412b6e919e4bc24849df2ce0c18023cdcca75cce8c5e124` | 824488 |
| HOME-018 | home_prop_wet_floor_sign | `f686c0a173503b127d1840251139db13d3bbb9ef` | `d59eea2db0e7761500116308723448d5bc24c8bcb039fdc22652c205888803da` | 1219232 |
| HOME-019 | home_prop_keep_clean_sign | `082f66a1a20fe996e258d288081646418c2dfccd` | `6d08b69f0aad74d0fdea9a696ab615a69e11f0796a5a23e0fa858032dcff9baa` | 1020218 |
| HOME-020 | home_prop_cleaning_equipment | `b6fea9e5e9f83c991aea2a475dc88bfc6df87369` | `c83036875ad4f5d4d2ba65c2b3567d39d292f894629a5f64ba7e8f73ac19511d` | 1555215 |
| HOME-021 | home_prop_neon_details | `b9b59419f14655635ef42a9fb230956c354d7a25` | `dcb568463a3a560d950ac35196bcbd722b8d6fc248b767aab86466dafce0a2e5` | 2167940 |
| HOME-022 | helper_bot_floor_cleaner | `21168a0f03c0c59c6e38bbdbee5f2c17162fa50c` | `d0cb14782d36a793c180904f0c61c59be938aa3c897afc342f19e721659a3119` | 956334 |
| HOME-023 | helper_bot_cart | `2e76a3b657c813f5c4c15a362aab2006efd9eec5` | `1f85faf4c52ae20687a7e6667e7ce3162828dce8a4172380c1df0c540406242e` | 1360982 |
| HOME-024 | helper_bot_alt_pose | `a3465ea6ed2c07bdc68d9bd582f4ec1983c8817b` | `27eaa6a3da946991e08cc351bd0175daa4c56a0298dfec3fa85f3bce2c1e51b7` | 1286130 |
| HOME-026 | scrubby_home_pose | `d9c56314191beddcce6c9150e4c941539e82d4d6` | `fc30b992787c644822a6cd02510e481fab9010cd89ab75fc4a9909ca713d5c18` | 1407303 |
| HOME-027 | scrubby_portrait | `13f908f02fc6c68c0343d118e4340bfe39bebe39` | `2b3cf915e93b8bf0e9c51014f2ca7ee8182377a5d4b9cd8ad61996aa9071187c` | 741149 |
| HOME-031 | scrubby_face_blink_layer | `0547df7ad17bc1a337832e3650096a8b36265025` | `a6c6f9c6f4117284d28a4a64ce7665b1807a46c12ad2b78ddf5eb871fc407b92` | 1456169 |
| HOME-032 | scrubby_brush_arm_layer | `b539000b35b65122f19c804af0a407685b128e56` | `bf33c73a26c1368d773774d1ea8bc6e7d9bbeadef18afeb2ce5258c1c52c2521` | 774383 |
| HOME-034 | profile_avatar_frame | `f1a9b33e9f2031615261e51838f1ac9a8a276cae` | `f0bb1b5c6ccec79a407d6f0f6f93283aae7656568628b71e665c99e2fafe35d3` | 882518 |
| HOME-035 | profile_rank_badge | `312a567e1f83a4af072cfe2eb26c1bf53246698d` | `d80e15270972d5b74f82d915e7252f405a040135ec2845f02b4438e3fd7e6617` | 1442327 |
| HOME-042 | icon_currency_scrub_bucks | `d3cbbdd0caa7f25db6de1fad031588379605af34` | `a843e21f429b28f2f2c91e9b5015efee7312e96e9112ce616947035dff68a8ef` | 1177566 |
| HOME-043 | icon_currency_heart | `44269f7c45ca6d4be82c82665f66a4a439ce64d6` | `245721d4166ba6f8bb2c21a907cf27165698a09709476b1dc9f5c7b05c36aad5` | 978806 |
| HOME-051 | gift_meter_emblem | `63a03c0cc91e3da01e08bcb2232fc1273fc5fbe3` | `0ba66f7b48f72b19c8bf4d402ae57553f8f13079728ffe37c66a5aef3e0d3917` | 1283008 |
| HOME-054 | gift_meter_reward_crate | `9961d2c9e8aece6d3798427b51c019d2a8c63385` | `9785ea7c680d9d36d548785ca3041ec489f24f75db1442d933ee0e8ad27f71fc` | 1373783 |
| HOME-062 | icon_shortcut_win_streak | `bed0541757bf50142d30eed324089f4f01518a2f` | `e44be6b876b76644cf390bed6207be20db4ffa10bd7aa12316a5cd4f0738353d` | 1479263 |
| HOME-063 | icon_shortcut_gift_bar | `790698c9df1d6fb5ab586705bd91b3b32f68fa7c` | `3fc1b5e2f859e79f2aafb4e842c0d99950d44f65bd912b44259b0092f7b3d7b9` | 1135904 |
| HOME-064 | icon_shortcut_collection | `21b600e9dfe7ffd69727bbdee078cc9c5af0adde` | `bde7a0442a016c272897e2487a85c2895f4883afbffd07efd5126a54c9d05872` | 1649090 |
| HOME-065 | icon_shortcut_shop | `4554c1beb2c20400d71ad0ad92fa2438bcf6e0af` | `471416cbb6ab7100c0404170a15f49e250b61a03d713b7ec162e8571343864ef` | 1433831 |
| HOME-066 | icon_shortcut_no_ads | `11ff4f5c7e6016d7dc54b4920fba2b8bdd47ef46` | `2a86a0373526adbb2a774d58a6fc08a6f5375a27ad807ad4644255f4d00752ab` | 1344831 |
| HOME-067 | icon_shortcut_daily | `d8482bb66dc5a6e069d36ce03b9a26e8858f6610` | `a01e49ac28f8665443a3c11d9ee2b6f806b5649d4b1456167c36bef7d2044ad7` | 1352996 |
| HOME-068 | icon_shortcut_tasks | `37508315e84f5463358e3564d8c07675c08bdfdd` | `711df18c7df43f3ebc036ac2c3486216334d0a4b403264650a40f5cb22658a00` | 1379430 |
| HOME-069 | icon_shortcut_cards_exchange | `62a45711129451349a39220ca904d7466abd35eb` | `5de717cbe474fdc46bad67e3bcf78cced1272a5f16843fa9b570d5f3ab63cec8` | 1631600 |
| HOME-078 | play_button_frame | `04e9c05767a67824c538bcaf2e4cdda655084b71` | `6a41ee7b2dd9f22736276b99134c85abc2fd27638125fe044592c0c6d5d46d77` | 1224010 |
| HOME-086 | win_streak_reward_badge | `cd7c8e8cf1892ce6df6e9cc03903c0b2391c9ff2` | `52304ff7cb6a1ed276f8139a76dfed3dec1b84de7ee1b5daa9ce7c1b1fb44812` | 1452790 |
| HOME-090 | win_streak_reward_gift_1 | `e35591625c9f9bb96ee1f13c1078e6adad9a4d26` | `3ae3614634dd11105de2e32a3d75185cc918946714918b914351102fba029e25` | 1119397 |
| HOME-091 | win_streak_reward_gift_5 | `cc7e2513ce82c6614c80c5dadbf6b7eb7e373baf` | `b5c7a95bc65a821aadcc95293fae36f7a2124ea02f5cd99df760e991865d918d` | 1335934 |
| HOME-092 | win_streak_reward_gift_10 | `f28d9ed8f7e0f508f9d7c06435fa38338f964048` | `8443069ab6286a51658808ef9e20a5de328a206cd3bea7a35a83d10638f4d209` | 1522054 |
| HOME-093 | win_streak_reward_gift_25 | `431356263a33b1723bf5d4ae0f474888b1b3e75f` | `d22bdcc0369668d19b5885284ab492111d990a1c643f9fd68ba5436964db0ccb` | 1495001 |
| HOME-094 | win_streak_reward_gift_100 | `210e087c85a83b5f59d4a04bf8f03bfc2546c2d9` | `0ce0b75ef56cb08f9c6d144d5109206e738e6b2157dd89935c6179eee171d6e3` | 1415950 |
| HOME-101 | icon_nav_events | `16cf69fa3028cd45785b9bc11f8e369e6599fc2a` | `32fa8f755d6695af29d4583fec8cdeebe16893f26b5dcc969b721ab34545c0fb` | 1206416 |
| HOME-102 | icon_nav_robots | `0f25b5fcc18d7966d8d068fc7be4eddcf2550ec1` | `b069f66152e9e843dcc056eb570af34686b7324aab6172fa1062153df4f34590` | 1154798 |
| HOME-103 | icon_nav_home | `68ee668297429669e84f37969ef6e09efc1e091a` | `2cf852c038f2c66755bb5b132103f11a601cb46903c33bd4f11bd15d74468254` | 878485 |
| HOME-104 | icon_nav_leaderboard | `863fbf0fbd86360f404220f4afac92417f78ad94` | `bf0fc3ff250092db2bf5ee922960e039e95b8e0980289e74e40f34c37e2bc452` | 1031817 |
| HOME-105 | icon_nav_settings | `b814c8f7e5dead261b5845d3fce6809e12568812` | `c8f1981b4c63c3853267b9886ef94200030823c2268a6edff606c1eb0ddfaf04` | 1197785 |
| HOME-087 (reuse of HOME-042 path `assets/ui/final/common/currencies/icon_currency_scrub_bucks.png`) | win_streak_reward_scrub_bucks_icon | same file | `a843e21f429b28f2f2c91e9b5015efee7312e96e9112ce616947035dff68a8ef` | 1177566 |

## Validation results

- `HomeAssetManifestValidator.validate(real manifest)`: ok, errors `[]`. The only declared reuse is
  `HOME-087 -> HOME-042`. The only warning is the existing star-shaped FX warning (HOME-110).
- Every `approved_sha256` is 64-character lowercase and equals `FileAccess.get_sha256` of the file on
  disk. HOME-087's pin equals HOME-042's.
- `HomeArtBinder.summary()` = `{"APPROVED_BOUND": 50}`: no NOT_APPROVED, HASH_MISMATCH or
  MANIFEST_INVALID entries. Every ART texture binds.
- Overwrite protection: `can_write()` is false for every approved final path and true for a new
  candidate path under `assets/ui/generated/`.
- Adversarial coverage kept:
  - APPROVED without `approved_sha256` is rejected.
  - A mismatched `approved_sha256` makes the manifest invalid and nothing binds.
  - A generated/non-final path never binds.
  - Any manifest error blocks all binding.
  - An entry reverted to PLANNED stops binding while the others still bind.
  - The 19 validator mutations are still rejected for their intended reason.

## Tests (clean detached worktree of `317b1e1`)

| Suite | Exit | SCRIPT ERROR | engine ERROR | FAIL lines | Result |
|---|---|---|---|---|---|
| `godot --headless --path . -s res://tests/m42_assets.gd` | 0 | 0 | 0 | 0 | 4/4 PASS |
| `godot --headless --path . -s res://tests/m42_home.gd` | 0 | 0 | 0 | 0 | 19/19 PASS |
| `godot --headless --path . -s res://tests/m42_navigation.gd` | 0 | 0 | 0 | 0 | 12/12 PASS |
| `godot --headless --path . -s res://tests/run_tests.gd` | 0 | 0 | 8 | 0 | 5322 checks, ALL PASS |

The root suite's 8 engine `ERROR:` lines are the pre-existing intentional importer negative tests:
3x `ERR_FILE_CORRUPT`, 3x `Error loading image` (corrupt PNG fixtures) and 2x `Error opening file`
(nonexistent sources). The same 8 appear at baseline, so no new regression. There is no new
engine error in any M42 suite.

`git diff --check`: clean.

## Proof that no PNG changed

- `git diff --name-only 1cd31e7 317b1e1 -- '*.png'` -> 0 files.
- All changed files: `assets/ui/HOME_ASSET_MANIFEST.json`, `tests/m42_assets.gd`, `tests/m42_home.gd`.
- `git rev-parse 317b1e1:<path>` equals the owner-recorded blob for **49/49** approved paths.

## Untouched

Root `TASKS.md`, all `coordination/OWNER_*` approval artifacts and all ChatGPT audit/prompt/criteria
files: 0 changes between `1cd31e7` and `317b1e1` (checked with `git diff --name-only`).
No image was generated, edited, recompressed, resized, renamed, moved or overwritten.

## Gates

- This promotion clears the art-approval dependency for SB-M42-014/016/018 (subject to audit).
- **SB-M42-017 final composed Home visual review stays open.** The owner still needs to see the bound
  Home screen in a running build. Final M42 visual closure is not claimed here.

AWAITING_CHATGPT_AUDIT / M42 HOME ART PROMOTION
