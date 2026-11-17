#!/usr/bin/env python3
"""SB-CAMPAIGN-L11-L30 / L31-L200: import owner release-pool levels as campaign levels.

Batch l11-l30 (2026-10-30): 20 Level Factory Studio release-pool levels as L11..L30.
Batch l31-l200 (2026-11-17): 170 Pixel Art Generator "Release Pool/Ready" levels as L31..L200.

Reads the owner's release pool (READ ONLY), verifies every entry file's sha256, and
writes this repo's level JSON, supply plan, metadata and preview, then replaces the catalog
entries from the batch's first order on. Format/metadata only: cells, palette, width, height
and version are copied verbatim; only id, name, difficulty (campaign slot class) and the
plan's levelId/batchId labels change. Re-running with the same pool rewrites identical bytes.

The Studio's own "SOLVED + replay WIN" is Studio evidence only. The shippability gate is the
in-repo real-play check (SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE): after writing, the importer
runs tools/real_play_verify.gd --levels <imported> --regen through Godot, which replays every
imported plan through the real runtime under the human policy and regenerates only the
intendedColumnClicks of a plan that fails (so a re-import deterministically recreates the same
plans and provenance). Godot comes from --godot or env GODOT; without it the import fails.
Exits non-zero if any imported level is unwinnable under real play.

Batch l31-l200 gate (jobs 159/163 changed the gameplay shell after the pool was verified):
tools/real_play_file.gd --canonical-only on every imported level + plan, 4 Godot processes in
parallel; a level that is not WON_CANONICAL goes through real_play_verify.gd --regen (the same
clicks reordered) and is re-checked. Per level verdict, frames and game commit go to
tools/real_play_gate_l31_l200.json, and a provenance record to real_play_provenance_v1.json.

    python tools/import_release_pool_levels.py [--batch l11-l30|l31-l200] [--studio <pool root>] [--godot <Godot exe>]
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

from PIL import Image

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STUDIO = "C:/Users/sekip/Desktop/Scrubbots - Pixel Art Generator/Release/ScrubBots Factory Studio"
POOL = "level_factory/output/studio-extensions/release-pool"
BUILDER = "SB-CAMPAIGN-L11-L30/release-pool-import/v1"
GENERATOR = "C:/Users/sekip/Desktop/Scrubbots - Pixel Art Generator"
GATE_REPORT = "tools/real_play_gate_l31_l200.json"
PROVENANCE = "data/levels/supply/real_play_provenance_v1.json"

# (order, slug, display name, campaign class, release-pool entry file)
LEVELS = [
    (11, "duckling", "Duckling", "EASY", "candidate-owner-4b8be03dd9f14c7f9f17ca5ae8544b9ef1c1e1a9ec7cce8f-pipeline-67ee53b660f157f92af4ced9"),
    (12, "ladybug", "Ladybug", "EASY", "candidate-owner-e52e80741f9a937574ecd97b3ce93523f4c07476885e64d2-pipeline-5420f3206975c7014bf650f8"),
    (13, "goldfish", "Goldfish", "MEDIUM", "candidate-owner-72efef1425ad6891884c39bdfc04aef1ef7641bf03bbb953-pipeline-7d7c1386d48afef670d6c857"),
    (14, "goose", "Goose", "EASY", "candidate-owner-e26b81cc6cc364364e3bb1b5eefbb79b88556c49aabbb5d8-pipeline-74ffa95db6ebf8601deffee4"),
    (15, "octopus", "Octopus", "HARD", "candidate-owner-896ddd7df33ad6ffcdbcdb1edaaaece8c3d9b1f116143aeb-pipeline-234c0379f9f9e45d01c0d7d7"),
    (16, "teddy_bear", "Teddy Bear", "EASY", "candidate-owner-a8cf6769a3053bac6b224b7d00cfaca28015043ae309ec06-pipeline-a51f853dd2189f09a5270cec"),
    (17, "ninja", "Ninja", "EASY", "candidate-owner-9375e5168ad6f9de7fcf94aaa95d641e0d95006b329c1ef6-pipeline-01a5676386a08fe43eceaffa"),
    (18, "wizard", "Wizard", "MEDIUM", "candidate-owner-6907c866ca9ff627edbf2c1ab2001f96b40587644291c9a2-pipeline-c79f580b657a020138cd9875"),
    (19, "whale", "Whale", "EASY", "candidate-owner-ba551e0efaa6ed9a39c187e76cae9a727b3f042e00140826-pipeline-091740762f8c0ca86cce69d1"),
    (20, "detective", "Detective", "VERY_HARD", "candidate-owner-ef2362240f3c7350571967d62dd9eaf2aa6e3bf2ff1d1f30-pipeline-c2194b4eb78f3563278ae25d"),
    (21, "bunny", "Bunny", "EASY", "candidate-owner-ed46768409271c2327082df3f24ec579d07e58b33fe18e5a-pipeline-d8463b48bd4b4170d04625cd"),
    (22, "crab", "Crab", "EASY", "candidate-owner-36ca9b4074ba991b52c6e5b5b89ee2acce581fa009fdf6c7-pipeline-9df7671ea2e45a5b8ca3429e"),
    (23, "bumblebee", "Bumblebee", "MEDIUM", "candidate-owner-bd3e8a5ad70fdfedf3d306fac0a1c717e8ab9802f79c1a18-pipeline-ba49de24c709c5af354be2af"),
    (24, "chef", "Chef", "EASY", "candidate-owner-0351429db11137e3d9932cd903972ec4409b8b020e5751e2-pipeline-fc7e8c79c88ed3e9cfb1d259"),
    (25, "knight", "Knight", "HARD", "candidate-owner-d68e000911dd22702458edc828fa817548a28c61df38ffec-pipeline-26a43c3082b8d2eb7df05a6f"),
    (26, "sheep", "Sheep", "EASY", "candidate-owner-905e719b10b3a1972dc8e82f9585483f4f361a6bc9711541-pipeline-3341c1d49f0f8d9633b3f744"),
    (27, "black_cat", "Black Cat", "EASY", "candidate-owner-89a8f149b5e5e3aa2b28d7b93b3f57c91ebb046bd48b5b22-pipeline-aca16f227fcfb9baaf6c6a0d"),
    (28, "squirrel", "Squirrel", "MEDIUM", "candidate-owner-70956566050ab939404dee4390f2006845d29f822804315e-pipeline-6f30c6a717aacdaa9d69f4f8"),
    (29, "turtle", "Turtle", "EASY", "candidate-owner-9aa5c74f056274ccad4eb61e98dfd3df98bb70f1d4ab9642-pipeline-4e44655ed09a290d081af297"),
    (30, "clown", "Clown", "VERY_HARD", "candidate-owner-df41c344b1980aa18dcfef6ada5b6e9a7cdea8a42d40142c-pipeline-ee8096aba3e2a8be4c7b7c44"),
]

# SB-CAMPAIGN-L31-L200 (all 56x56): EASY slots use the lowest-score MEDIUM entries, VERY_HARD slots the
# highest-score HARD entries (the pool has 9 EASY and no VERY_HARD entries).
LEVELS_L31_L200 = [
    (31, "cricket", "Cricket", "EASY", "candidate-owner-a97c905677d60edd293f9a2ef2447aeac9ae8465af9d1e13-pipeline-dbc4450aadae80b8353199ae"),
    (32, "longhorn_beetle", "Longhorn Beetle", "EASY", "candidate-owner-1133ef53824d5e195a86bc53aa66d7c88b8246f5ab5317a6-pipeline-4af0cecc5e4359ce49e556ab"),
    (33, "fire_jellyfish", "Fire Jellyfish", "MEDIUM", "candidate-owner-68d309b8dd0af5efa2ebb242950e59368b3c6498576092d8-pipeline-598541a346e123fcba21f818"),
    (34, "stag_beetle", "Stag Beetle", "EASY", "candidate-owner-593f7e9e7f0d9cfa61a4bc43ee6af1d2c898575cce39b7ff-pipeline-ad99e95bb858fd370553c730"),
    (35, "mop_bucket", "Mop Bucket", "HARD", "candidate-owner-e038e72de47089912a342fc26afaadfd855d25040d98bf47-pipeline-0e6cf67bf4b7beafff07c420"),
    (36, "lobster", "Lobster", "EASY", "candidate-owner-75378f1608d13a2abd70ca640f9c694da92a5bfff91b317c-pipeline-54ed44f15cb61335e827a567"),
    (37, "weevil", "Weevil", "EASY", "candidate-owner-1d97b0cdd3673c22e1a5933de3d4b31a7eb58d907dcb153c-pipeline-0a20078f5344702caeb60a3e"),
    (38, "scarab", "Scarab", "MEDIUM", "candidate-owner-6f55348b603dafc610bc6af5371ea7af6fe03b83b6b2c359-pipeline-130d84240b09aecb7eb74ebb"),
    (39, "mantis", "Mantis", "EASY", "candidate-owner-1529c155d8b7c92e4a635e795eb0b6575a713b9bae176b7c-pipeline-9074c4d240f2061b1792eb4a"),
    (40, "sweeper_bot", "Sweeper Bot", "VERY_HARD", "candidate-owner-11ca24e26a1613d1cf38b870991958ad34f7cf6c351b6eea-pipeline-5f60c9c52ba666c3d25b2a3d"),
    (41, "spirit_stag", "Spirit Stag", "EASY", "candidate-owner-991f3e0b0b0a9bc3b8bb020b52cb9500cf073a88b40ae5fe-pipeline-7001c22cf10b3310dc890319"),
    (42, "drone", "Drone", "EASY", "candidate-owner-b8635f4e48534058d2e0810c96bc1fe8580bfe7d76b249e8-pipeline-48e71e9687608961d80b30ca"),
    (43, "storm_cloud", "Storm Cloud", "MEDIUM", "candidate-owner-72973de0fa2c9f9b647a5d5860fd61546038c7a6817d610f-pipeline-9c60e94963205728d86ad825"),
    (44, "sea_dragon", "Sea Dragon", "EASY", "candidate-owner-4de9fa8de52458c82b1873ba1d4d0890341636b7496067ee-pipeline-c6bfebb901f6a5d2ae69b6a0"),
    (45, "dark_drake", "Dark Drake", "HARD", "candidate-owner-04805b4609e7f898f65217b0ce6c72aa33995fabc73fc6eb-pipeline-993c63c10ad4d28167a10488"),
    (46, "rose_wasp", "Rose Wasp", "EASY", "candidate-owner-d509fa9fbcb4f01155fa78bb7b743dc05e2642ed97ffd5b9-pipeline-08a1339f6d2572a9fde46047"),
    (47, "claw_bot", "Claw Bot", "EASY", "candidate-owner-4ed0b84407eb87857dd6ea83f58dfe7e2f1996c338f3926b-pipeline-f20dd1be8439d24a0b67ce5f"),
    (48, "robo_hound", "Robo Hound", "MEDIUM", "candidate-owner-5ff86b87f2d8ad12c044afc00e33639e2e122d524c5c4b30-pipeline-937c34cb19f417704ad3743a"),
    (49, "spider", "Spider", "EASY", "candidate-owner-7a27413ca497185bd22752e601eb674a26945a6ad6af2068-pipeline-e736504d8d44db641dffbba9"),
    (50, "jade_knight", "Jade Knight", "VERY_HARD", "candidate-owner-de747fd405034dbb31169ae1886a7bc0d07095eb407b8c03-pipeline-021e6a7f1228559a425d1c7a"),
    (51, "dragonfly", "Dragonfly", "EASY", "candidate-owner-656c0440228a68147fc36fbf1ce8705a9fe4f7941f021f81-pipeline-60763d0fd7b0729e6d84d5ee"),
    (52, "orchid_mantis", "Orchid Mantis", "EASY", "candidate-owner-46cda5cae5f548ae6a2bd488b56052c4f0d9c5e30aa18beb-pipeline-3944e84fb4a20935967e5a4c"),
    (53, "rhino_beetle", "Rhino Beetle", "MEDIUM", "candidate-owner-f979758a755b5cf8e8f8bb1abee58e681313aeff07d4f5c4-pipeline-55629e4c2016272def8a3e86"),
    (54, "lava_salamander", "Lava Salamander", "EASY", "candidate-owner-6de6ec35f56ca85096f8d82d8c545c2d82f9ffc5a8a5716c-pipeline-902381c89f7490782d322708"),
    (55, "swamp_slime", "Swamp Slime", "HARD", "candidate-owner-5f6b2ee803680eb42e7b3bfe099e2825cfb818b0af625603-pipeline-8f87eff81597f52ba79c4b24"),
    (56, "moon_jellyfish", "Moon Jellyfish", "EASY", "candidate-owner-3b755f245dfd8828be2cb4f96154d5253f3aed4918f0929d-pipeline-952d9f055ee10d47cd77635c"),
    (57, "shrimp", "Shrimp", "EASY", "candidate-owner-d1c6f65c5d9d4d28c98fc4e0f958a98dfed71cce153c8720-pipeline-48a77179ea959ab471e917be"),
    (58, "centaur", "Centaur", "MEDIUM", "candidate-owner-55748795da0b4d6de0f756a06a92283f533677118eb70db3-pipeline-9ae684c924b2420c57a04e5d"),
    (59, "fawn", "Fawn", "EASY", "candidate-owner-ce8f26a85684e5e7387637fb36cbd46ad7a632574946c31e-pipeline-c89898c33a82c2268cbdb8a0"),
    (60, "roller_bot", "Roller Bot", "VERY_HARD", "candidate-owner-0be1bb8688a96b51bf1c66fcca1416fe0763704630d79dc1-pipeline-b5c8eb1ba76c08cefe51e094"),
    (61, "scorpion", "Scorpion", "EASY", "candidate-owner-f9c1736d9204de303e2bfdfae595637af4146a1d6596e7e7-pipeline-8d0789794ff90b881f59a2c4"),
    (62, "hornet", "Hornet", "EASY", "candidate-owner-4260c8beab3bbacda842f224fa16fc03fd41d8b52ab4d615-pipeline-5f40e0a6836db826414a6d33"),
    (63, "sea_serpent", "Sea Serpent", "MEDIUM", "candidate-owner-b677f870bdd0919fbc955dff9863a9bc0e8544502f8c5072-pipeline-3a3884633f0706d955c1a5ed"),
    (64, "amber_dragonfly", "Amber Dragonfly", "EASY", "candidate-owner-daaa146666ce4819548b02713141d9d3aaed27ef2c07ecc5-pipeline-0193a4a2ccaa32bbc88c4be5"),
    (65, "robo_piranha", "Robo Piranha", "HARD", "candidate-owner-27493c00dfdd0f70433b4da80c67a205417e2c119f9bc679-pipeline-35520c4a617767a5a9e98251"),
    (66, "skeleton", "Skeleton", "EASY", "candidate-owner-57f4334cf4a306680663316b143f625161cbb14eac6ded5f-pipeline-e36b717d34aa81f7a6c05f91"),
    (67, "golden_stag_beetle", "Golden Stag Beetle", "EASY", "candidate-owner-d8ab82ac1bec9c9d535fb79ca3f5d63c4f6c599a823cf776-pipeline-f14ee5fafc8f84f2219cafbc"),
    (68, "seahorse", "Seahorse", "MEDIUM", "candidate-owner-72273b3a45bbc1f0ce3aba1d07e24504cea7504c748a7ba5-pipeline-30bf2575c530f6f2019af377"),
    (69, "fire_spirit", "Fire Spirit", "EASY", "candidate-owner-af099f99b61cdc029d537373660957d2533811f101c6a9d3-pipeline-16f5d6ae12c2100b62c295df"),
    (70, "fire_drake", "Fire Drake", "VERY_HARD", "candidate-owner-c06597c4ef886c2f23c32b4eddc0d54522f1e8bf965bb684-pipeline-ff7627c3b2532ea18c1dc31a"),
    (71, "speckled_weevil", "Speckled Weevil", "EASY", "candidate-owner-6635f24554cdf5d811879fbfcb124987bf961e0a8eb3dfe7-pipeline-a3f00a36dea24059d57d515d"),
    (72, "moth", "Moth", "EASY", "candidate-owner-e014bbfa2006fb2016ef8281947ad2308fd976815b30228d-pipeline-d48e8d03450a57df634e4c98"),
    (73, "sentry_eye", "Sentry Eye", "MEDIUM", "candidate-owner-1feb20f646abafd933318520cd4f5ce71ae9e5f5e75615ff-pipeline-28d95b16df4bed8d5edd66de"),
    (74, "firefly", "Firefly", "EASY", "candidate-owner-4d716af31ce9202031bb7747eed914c8af28319a12c00733-pipeline-302b0fef6039dbaef5811332"),
    (75, "repair_bot", "Repair Bot", "HARD", "candidate-owner-70968877563e2f9aa89649f739d0f98239489c202ad7fc85-pipeline-0d2503c4ca37fdb501b31065"),
    (76, "spirit_bird", "Spirit Bird", "EASY", "candidate-owner-8db796861fe1ace354e49daa4e35fb975e33e66a418b105b-pipeline-08f8f5cba7cae56b156b2732"),
    (77, "stick_mantis", "Stick Mantis", "EASY", "candidate-owner-dbdef5747af3cc72619c9341445f98d1833728a072392cf5-pipeline-71eea91f71a0785657f021db"),
    (78, "azure_dragonfly", "Azure Dragonfly", "MEDIUM", "candidate-owner-df0d027d3a4ee8cc50de272686bfdc5cdfcec5ac40517f08-pipeline-15a32286fbaf6721f69a10f8"),
    (79, "forest_spirit", "Forest Spirit", "EASY", "candidate-owner-89519e20bf6e13ae0252646c1c34973290b3988a4cbde7fb-pipeline-7933a7da0f1b3ede6012a5d8"),
    (80, "pufferfish", "Pufferfish", "VERY_HARD", "candidate-owner-27f96429be180f8b14cf2574f0d5ba2cc36384313592c32a-pipeline-ed9e383dd5683e79696d2c1b"),
    (81, "jewel_beetle", "Jewel Beetle", "EASY", "candidate-owner-05182ce5d56b1dd0d0166865f2896f2b1060e7d284e678a1-pipeline-53a6d6e9cd3786a5f1253ca2"),
    (82, "anglerfish", "Anglerfish", "EASY", "candidate-owner-8eabaa5458973cc0c697afdf7b944b69ab37720f2c68a879-pipeline-68d9df14dcd0e257289c7ce4"),
    (83, "shadow_wolf", "Shadow Wolf", "MEDIUM", "candidate-owner-d7852e16b9e5172eaf8d7ee6e43c6c2285047afa60f0139e-pipeline-032fb5e9608ba6d43e3103e0"),
    (84, "tiger_bug", "Tiger Bug", "EASY", "candidate-owner-aa008bebb9100820c87a9a75a48a07cb50d40b2bbb18a23f-pipeline-56fed879bd4e632e473b2097"),
    (85, "nautilus", "Nautilus", "HARD", "candidate-owner-617ce621856d26e0a555947e6fb808519bf5771d6123620a-pipeline-737b3f325b129dc8084afcdd"),
    (86, "shadow_wisp", "Shadow Wisp", "EASY", "candidate-owner-3f6922502acca7764d7ce1449204c8788a110796298e0c5c-pipeline-8e4c7df5e38aada01d01b61b"),
    (87, "flying_fish", "Flying Fish", "EASY", "candidate-owner-b92b35ad9864f1ebe1161c84dca267e3b49fe488185cbb0c-pipeline-0ec46f2e78284384e7585ff4"),
    (88, "lava_spider", "Lava Spider", "MEDIUM", "candidate-owner-1f61e928ca4112816d569e36d137611fb10264985fbaa520-pipeline-424e0ae0fbd2b0c8cded74e6"),
    (89, "isopod", "Isopod", "EASY", "candidate-owner-3c5ddfca65287b283f8dedfa94b9e7748dccb4c819840aeb-pipeline-f3b4802d1b32f83aa32b1c03"),
    (90, "fire_tortoise", "Fire Tortoise", "VERY_HARD", "candidate-owner-cd5dbc4f232bff626c1f3220107af665e671c4a8262afc7a-pipeline-609436ceaaa903d0d485e030"),
    (91, "smoky_lobster", "Smoky Lobster", "EASY", "candidate-owner-44367e52da81127352563428fcf8e0d6a16d0f065bc16009-pipeline-8efdc3a19784c41332747dc7"),
    (92, "tiger_moth", "Tiger Moth", "EASY", "candidate-owner-de5db5724373d81baf38eb0b34d28362a6d8e31bbb040ce8-pipeline-442b45dcafa46b7edc3db33e"),
    (93, "clownfish", "Clownfish", "MEDIUM", "candidate-owner-e115288b3616e939629252a38676ef0805c51bf2712d5122-pipeline-06ec52aa132927f78ddecb4b"),
    (94, "fire_dragon", "Fire Dragon", "EASY", "candidate-owner-ad8d7059d8894628849def12b2a913ec00ca4400a0ebd8ac-pipeline-bbd65abcd41d29f41f4ccb03"),
    (95, "bell_mushroom", "Bell Mushroom", "HARD", "candidate-owner-7ec671530d9cd02fffc8ac02a26434667bec9748fae4501e-pipeline-3aa4292e1e0610f5e8568ffc"),
    (96, "bronze_beetle", "Bronze Beetle", "EASY", "candidate-owner-a0edce081776adfb5585fed17e1a4be5f68b84d149a69b2f-pipeline-03fb955e922d258d7941283f"),
    (97, "star_spirit", "Star Spirit", "EASY", "candidate-owner-443c04c7b15853a056a6d903fb714bd12e50df51ad2bb348-pipeline-4dc78447cc87b93c1e10fccb"),
    (98, "ghost", "Ghost", "MEDIUM", "candidate-owner-1e4d23d55f2bcae2b8848fa581524206e31c840b753f5fd5-pipeline-95aab096d9eb6c824a5f3357"),
    (99, "goblin", "Goblin", "EASY", "candidate-owner-736bedff580b9229cf5494e493f13566a91e13bd76df8433-pipeline-66295da498570b53cf459510"),
    (100, "larva", "Larva", "VERY_HARD", "candidate-owner-91094b2b5d99bc5358b408292d9c62ffb8170fed2808ff19-pipeline-d713dbeb38de93c45803ad9b"),
    (101, "painted_beetle", "Painted Beetle", "EASY", "candidate-owner-ce1bec9a104525acde101b0125b9914f2d8b8b85e2ab2cc5-pipeline-7fe54fcebe66b329b9080abf"),
    (102, "shark", "Shark", "EASY", "candidate-owner-8d26330698dd0ed8ca5ffa93f8d875a9d924c7ccaa5e0be2-pipeline-c99e729836439d8aca9ed2a0"),
    (103, "fishfolk", "Fishfolk", "MEDIUM", "candidate-owner-5d8fe1c5ec483918dcb2e2212dd583a2b20628e03b706107-pipeline-a3995d86342a66f48a23f52d"),
    (104, "arctic_fox", "Arctic Fox", "EASY", "candidate-owner-69502dd7db729758301c57dc1b4287fcbbb04cd47ce481e6-pipeline-57a6953eb05a1ef6e3dd356f"),
    (105, "hover_bot", "Hover Bot", "HARD", "candidate-owner-cdfd28e35f5473abe41da2bbd6080815b6af92b848d9cd43-pipeline-3ca96cbe537f099c117efdd5"),
    (106, "wasp", "Wasp", "EASY", "candidate-owner-1a7f9cf12622036a934424dee14454258de86bba308f8216-pipeline-5e9611a073be3cf50191084f"),
    (107, "fire_fairy", "Fire Fairy", "EASY", "candidate-owner-8f8fd69d23ef5707a54218b46aa5a688bd26eb4ff88ee260-pipeline-1a7074a265619dfa1bb40082"),
    (108, "zombie", "Zombie", "MEDIUM", "candidate-owner-ac5296835fb9b36a70b8461636bdebd8dd8c844db44240ea-pipeline-ed310b9977433db9be1bab96"),
    (109, "bubble_spirit", "Bubble Spirit", "EASY", "candidate-owner-7d07ad943bcdb3234e82dd0718a689c0956aa5df24715d67-pipeline-c5c42c3d869f2a117d314a95"),
    (110, "geode_beast", "Geode Beast", "VERY_HARD", "candidate-owner-8d6cb601d546cccd7aa9ef76858e6c7baf6fb5ee59816758-pipeline-d4f6e38c59ab092250fc7b35"),
    (111, "mist_spirit", "Mist Spirit", "EASY", "candidate-owner-c3329d7c577371e7f74a62e56c642861ccae17773f5b22ce-pipeline-24685040803d9cd0d66ae263"),
    (112, "crayfish", "Crayfish", "EASY", "candidate-owner-8ff24ecc889cf7f6f75108c85a684a38807c534a64777b49-pipeline-40aae940625f6864f739f364"),
    (113, "teal_scarab", "Teal Scarab", "MEDIUM", "candidate-owner-d33705561e4abd3fdb2e509738fa106c6d26a7c2ee9d9b29-pipeline-a843af60363af2ffe7984086"),
    (114, "starfish", "Starfish", "EASY", "candidate-owner-6bb15f61b3b4310514bbdb5c9c32088cee1e55e43eed2a67-pipeline-7ad609fbffb7e705335dce52"),
    (115, "magma_golem", "Magma Golem", "HARD", "candidate-owner-d274c17bcc93c6ce5709aa01be49aef7f1c524cf2892c715-pipeline-d04bb049c73f521096a753ea"),
    (116, "phoenix", "Phoenix", "EASY", "candidate-owner-7deb1d370838ee7739b2c6b90dc4c88ef0e57279e805da91-pipeline-5bfaacb4fce3fda84bb46b42"),
    (117, "white_wolf", "White Wolf", "EASY", "candidate-owner-a6e2216719177b44ac9d5b1f17399ec80641a44819328bd6-pipeline-7dc14f9ba483334e497aec23"),
    (118, "water_spirit", "Water Spirit", "MEDIUM", "candidate-owner-d16245a2bec4e256a1ad2d0a6467fab6b42f30762026bd75-pipeline-3801c055668d26a3eceb3922"),
    (119, "ember_stag", "Ember Stag", "EASY", "candidate-owner-b29273bab0485abb234e4869923125b3495d41e41f76928e-pipeline-069ce8f2ea16a1c2856f8d36"),
    (120, "drill_bot", "Drill Bot", "VERY_HARD", "candidate-owner-f8c6b626a471cdcab74442d5b434be634c99d71a4274f86a-pipeline-d65f0c9af5c9da22388dac49"),
    (121, "fire_imp", "Fire Imp", "EASY", "candidate-owner-a3fc23ab995ab5286cf34691aade9e0706ddd5e9c5acc13d-pipeline-26a2c0e5031a8f8597d9812d"),
    (122, "brazier", "Brazier", "EASY", "candidate-owner-f6a6c4c86405448b7688ab72c5d63d7485491e614514f3f9-pipeline-f17d99874e7ccfa12aa2bcb9"),
    (123, "sky_shark", "Sky Shark", "MEDIUM", "candidate-owner-23c362da129d42f07e0eadf312d75963194a4bb2f7710211-pipeline-56b5427e6870be469d306335"),
    (124, "dung_beetle", "Dung Beetle", "EASY", "candidate-owner-a868a570fd5c1990ceedfaab7eeeb6165a148cd7b057baf9-pipeline-1cd2387ed0d5270dd51e57fc"),
    (125, "blue_slime", "Blue Slime", "HARD", "candidate-owner-1ec76425bc4438b7a2f79b505d79e02c58c63712a7b90f50-pipeline-9e9408b35679bc4f43d54692"),
    (126, "sprout", "Sprout", "EASY", "candidate-owner-f09066badc48b7df987ebb11d50cb6c963b43d3727cc8b95-pipeline-1b43980e8cb7a715ad00df43"),
    (127, "pine_tree", "Pine Tree", "EASY", "candidate-owner-753409e78071bf2fceabb2015050794e3eb3668becf34887-pipeline-62f6e8a97f998c55408dd9f4"),
    (128, "roadrunner", "Roadrunner", "MEDIUM", "candidate-owner-57f317706d5e4c8fd6e8f1e2e3a13ef1e83793e5ae20eb0b-pipeline-e16097fee5e4bc48e8e37a20"),
    (129, "hoopoe", "Hoopoe", "EASY", "candidate-owner-61663a3eca477eb0eb309b20d183bd04a577cb504c11e705-pipeline-a094bfaac4e7e421d6848cf0"),
    (130, "moss_monster", "Moss Monster", "VERY_HARD", "candidate-owner-719deda12b0a44e5d386728753584434feca99a3300f96b9-pipeline-7079065a9810a8e936713026"),
    (131, "ember_stump", "Ember Stump", "EASY", "candidate-owner-6361f60c2f84855d293b56076a7b0f01dc353e598817a5b3-pipeline-d4d920f19809173e99977df0"),
    (132, "spider_bot", "Spider Bot", "EASY", "candidate-owner-8fbb3b7aeb5a5b4e516b251524da48bdcaaf432fd2973255-pipeline-dbad07e62b9d6b7e5121df2e"),
    (133, "manta_ray", "Manta Ray", "MEDIUM", "candidate-owner-c6912f53e390e716d1fc32685b846cbc2f91e3d31c9d70d2-pipeline-96c95f077b648aae23207310"),
    (134, "leafy_sea_dragon", "Leafy Sea Dragon", "EASY", "candidate-owner-7cf92d9bfcadaede83b5d59a633c39747c2c833112a20c49-pipeline-8e89d4537ca608649bf13748"),
    (135, "grim_reaper", "Grim Reaper", "HARD", "candidate-owner-c0fb86b3891532397c06b05e74ee0c687cc44e0820dfa775-pipeline-39f8fc8f285f9a20efd9822e"),
    (136, "water_serpent", "Water Serpent", "EASY", "candidate-owner-80894cc3fa9ff31279ef1d48c7f04cb0189155615b9cf2bd-pipeline-58fbb5c8d8a008ca80735dd2"),
    (137, "dryad", "Dryad", "EASY", "candidate-owner-10ed0146d324ec802aed1b7eeaa95ed6b1cffa2e35fd4896-pipeline-df1b1861398662798347f8dd"),
    (138, "scrub_racer", "Scrub Racer", "MEDIUM", "candidate-owner-970972bd4b8d56af9e7ee000f77422c9a9002dc46caa3eb6-pipeline-4153c422ef3bb2017d9f8a67"),
    (139, "glow_firefly", "Glow Firefly", "EASY", "candidate-owner-e72a9fd9dc6ae004b16f077fbb33e19312ad1647c0dc031e-pipeline-39b31c6d26f54dffb6fdfae7"),
    (140, "tank_bot", "Tank Bot", "VERY_HARD", "candidate-owner-497d078d94f2842c2b4ea71cbc14116eda8af85956018744-pipeline-9c115216939dce4c8db6ed10"),
    (141, "diving_beetle", "Diving Beetle", "EASY", "candidate-owner-cfa6713d37e310e0f18087cbf6c4cef571ed24b4c85ab3b3-pipeline-df80a64457e152982c18aa42"),
    (142, "red_wasp", "Red Wasp", "EASY", "candidate-owner-c3c2c9d2189690bd482ae046b7bf7a5ad13ddc7a30872262-pipeline-5c746717a5a779beb3962a04"),
    (143, "frost_stag", "Frost Stag", "MEDIUM", "candidate-owner-2c2b477b7656744d0d2fbebdd0c15a002c83907496675879-pipeline-127706d1867aa56ae0fc7ddb"),
    (144, "swamp_dragon", "Swamp Dragon", "EASY", "candidate-owner-b4352af9cc37b2b059a09b90a0155aa8409967bb14f4729a-pipeline-0a70aac94377f6064a4cc4a5"),
    (145, "mushroom", "Mushroom", "HARD", "candidate-owner-6e0703797aa011b59d9e27d79463f0d0446219d07d565485-pipeline-ef7d456d2be116d50bc04ed2"),
    (146, "lantern_ghost", "Lantern Ghost", "EASY", "candidate-owner-0a30a047025c9a18d0ab2084aa03b48e25c9b0ddffd9b1c5-pipeline-60142e3c1573baec0c8382f8"),
    (147, "flame_lizard", "Flame Lizard", "EASY", "candidate-owner-db94d9c10b5cc2781360e1e79e7c402e69b0906fc60eaba0-pipeline-bbfa264e288b3bdc580cd61e"),
    (148, "blue_jay", "Blue Jay", "MEDIUM", "candidate-owner-6f66b498837cda9e3678f5583fe6008c9618a29c55d7aea2-pipeline-54ac7ca2991ea79aa5dcce92"),
    (149, "robo_beetle", "Robo Beetle", "EASY", "candidate-owner-eba9330ed6d84ec1572a7b55548f1b57fa1d75dc9471d940-pipeline-cf3bcf8d46b77baf239401fa"),
    (150, "mimic", "Mimic", "VERY_HARD", "candidate-owner-406505e5f2ec897d951d34b7e11c6ec5d838c1570d983a34-pipeline-9321cc8e35a23104f2c62020"),
    (151, "sunbird", "Sunbird", "EASY", "candidate-owner-595cb4b527247e179f021d8ec2ac90e9f2bd9684818eae57-pipeline-bd250720a793acee451c036e"),
    (152, "night_beetle", "Night Beetle", "EASY", "candidate-owner-565d118858ad25a4f537fea2030590c13cc4f6586f46d2b6-pipeline-98b4c43e8fc2e44413a70963"),
    (153, "glider_fish", "Glider Fish", "MEDIUM", "candidate-owner-9829a3fd580cddcfde122cfc759581d2d388e5c3a452a052-pipeline-427671117dfd355e4397e23d"),
    (154, "stalactite", "Stalactite", "EASY", "candidate-owner-49c0036495dcf1589eec588118265f2dd4429ef817ac944e-pipeline-c565251990838ab9e07ba623"),
    (155, "skull_druid", "Skull Druid", "HARD", "candidate-owner-9896ea5e5a8204da9ab90f5c144f08fdd5c2c008fa9ef3de-pipeline-d9d7e4b139b5c73b5cbd59f1"),
    (156, "sun_spirit", "Sun Spirit", "EASY", "candidate-owner-660c74d0718c17ab6e0f7716866945e575a5dd386f7b7acd-pipeline-47ecf6837e9cf9fb7ac0ecbd"),
    (157, "tv_bot", "TV Bot", "EASY", "candidate-owner-6863c14d49beff0a46ccd124cfe6c9e7bd409f128b01aab2-pipeline-b03db7af6c4eb9ece08cadce"),
    (158, "bog_slime", "Bog Slime", "MEDIUM", "candidate-owner-6742e2640eb1ab90adad43a4e3583b0cc882f014ee85f6bc-pipeline-643f18301f6aa52b9624eacc"),
    (159, "swamp_tree", "Swamp Tree", "EASY", "candidate-owner-f2ad7cd91799490af90877669a246880e7fe9cc62efe57d3-pipeline-caebf54f458a9e1a114e081b"),
    (160, "sphinx", "Sphinx", "VERY_HARD", "candidate-owner-59c8bd0e55d2539c4417b72c2659fcc05c9de0ba34a3f43a-pipeline-f0badda056cefecc80139dd6"),
    (161, "radio_bot", "Radio Bot", "EASY", "candidate-owner-64c28231dedffc5a56ac1188042f39b674d4a427163482cb-pipeline-e17e54c47cbb60b750f715da"),
    (162, "shadow_mage", "Shadow Mage", "EASY", "candidate-owner-abc354e427cf08a4000e7ba47674263e35fd8e21228653aa-pipeline-78886af5f2bc1f3a3c32ac4a"),
    (163, "grub", "Grub", "MEDIUM", "candidate-owner-d05a0d2937b6276b2bb8fb0b9ef64574305cc5b77657dde7-pipeline-776f413467d9bd3200c68766"),
    (164, "tesla_coil", "Tesla Coil", "EASY", "candidate-owner-0ab772688e820dc45e77fbcb013c1e98cfa80cf6e932d05d-pipeline-32bbbac9f938a0d7dcdd3069"),
    (165, "monitor_bot", "Monitor Bot", "HARD", "candidate-owner-f51cd6e6ec9cdb95719baf11cfbfa1784de4cf9c74e25529-pipeline-820d5704ddb572075abcfff0"),
    (166, "moss_wolf", "Moss Wolf", "EASY", "candidate-owner-b3da60d2daf1d26acbc3ef2c476a9548f9fc1b2dc34553f7-pipeline-2f67ebe17b3b9e281ad716db"),
    (167, "ice_dragonfly", "Ice Dragonfly", "EASY", "candidate-owner-7063efbbe4f33ccf6c0d15aface404276cf01cbd0e8e4ccd-pipeline-5c17df8054045fb636545a66"),
    (168, "fire_golem", "Fire Golem", "MEDIUM", "candidate-owner-b5486f273e6af672c03e09066074e30e70b931562d11e867-pipeline-efc75bbb280a7690a26da653"),
    (169, "glue_bottle", "Glue Bottle", "EASY", "candidate-owner-38449bf67d378b1fd72f5687c9dd4664c4648dd383d36f93-pipeline-40d8ce8be23ae65f93161450"),
    (170, "lamp_bot", "Lamp Bot", "VERY_HARD", "candidate-owner-81a88c8d68884606bb5b2778bb0631f4ced91f34042ec4c1-pipeline-a1db55760f3b9a91ebe641a7"),
    (171, "parrot", "Parrot", "EASY", "candidate-owner-525aa0d1182c85de2a0bff0e090812521eee9ebd8539d897-pipeline-f24c890e415fd8e2bf60d1ef"),
    (172, "teal_ghost", "Teal Ghost", "EASY", "candidate-owner-d84ba2c2c8f10df9190c73020c9efef492da6f2e30e20b54-pipeline-a13e30ab7d4c51f6cb30c69e"),
    (173, "unicorn", "Unicorn", "MEDIUM", "candidate-owner-cd67557da421864b0618126aad803170bb0ed470be3d4151-pipeline-c286909aeeda06fa90c8e8d7"),
    (174, "emerald_beetle", "Emerald Beetle", "EASY", "candidate-owner-cc21235280bfe206b3676ce3813db700df191ecbb58986be-pipeline-5ef79b12b9d86bd29fd07e94"),
    (175, "wave_spirit", "Wave Spirit", "HARD", "candidate-owner-a1ef8c5e413698138f108b959d24bb3f5859d6e5b1375900-pipeline-178231df2b591694df1cd616"),
    (176, "mandrake", "Mandrake", "EASY", "candidate-owner-9d69d2b66e9222482302ec346e3dec12c12e908266a708fc-pipeline-3acd607402d6f9c5364fd54a"),
    (177, "harbor_seal", "Harbor Seal", "EASY", "candidate-owner-3c8edb97a67c42f763806208191e255f5268600756ff554a-pipeline-f683bb9be9f64e2f336b5921"),
    (178, "mop_bot", "Mop Bot", "MEDIUM", "candidate-owner-45ec7e73b9c07a1825076798b5e1f63fdb4c598ca552d632-pipeline-a17b4f9dbde6f7b1bb3ec2f9"),
    (179, "gremlin", "Gremlin", "EASY", "candidate-owner-48aba83cd6e98f2dfc51217a2a39beb2875147861fdee6df-pipeline-ddcab0404c0ad5cbe750b8c4"),
    (180, "dome_bot", "Dome Bot", "VERY_HARD", "candidate-owner-68fe92a68965ade866d05fcb0ba03f40841c1cc2bc3441a8-pipeline-ffcdc1aa4dadb3aa51173384"),
    (181, "lightning_spirit", "Lightning Spirit", "EASY", "candidate-owner-48cf492b4cd935dc33ef4cdd2340c176375c6c10fbf1e8ac-pipeline-dd15c69cbe0d40f0e7234a42"),
    (182, "red_demon", "Red Demon", "EASY", "candidate-owner-45ee8b21de72d637843f402a9f1de39c1cf8c6533fabf7fa-pipeline-882ee7720f176add8a39dfe0"),
    (183, "flower_spirit", "Flower Spirit", "MEDIUM", "candidate-owner-5926da03eb32d346fb4f524556130d09ca2c91d7d25949b5-pipeline-862c95a9f082e1f8ff04068e"),
    (184, "cyclops", "Cyclops", "EASY", "candidate-owner-c85da54ce94c5c80f9d5b849c3381d48f2060331b7f21d70-pipeline-24018e3a166d36c1d67a909b"),
    (185, "washer_bot", "Washer Bot", "HARD", "candidate-owner-f68bf797fa6441032cbe12e7a25592ebed2c52c93bbc8c46-pipeline-d85348bc2c2bf4ece48d065e"),
    (186, "cactus", "Cactus", "EASY", "candidate-owner-b8e3952cd301e4182f5b7b55b1d6dcd77c87f8dca2fbedd1-pipeline-8b367bd0aa72d4e555a59cdc"),
    (187, "pixie", "Pixie", "EASY", "candidate-owner-325a60b00153601e29326635d495484f525575d8e9e799d8-pipeline-90ed19a03ce40ec8e65fe590"),
    (188, "jade_scarab", "Jade Scarab", "MEDIUM", "candidate-owner-265c09ef2fcb3a6fba3989e32f986cd64832aa8c35d9057e-pipeline-a378f2211570d09cf3d0c541"),
    (189, "rock_monster", "Rock Monster", "EASY", "candidate-owner-f01452df88f03c92e031275546e20e69dea1bea548b7c1c4-pipeline-1707670879420fc75982e8c8"),
    (190, "crawler_bot", "Crawler Bot", "VERY_HARD", "candidate-owner-df909d6b2db9038153c58a78b3eeae4d604b5a06c8221bd0-pipeline-f127a82eb967e7abade9b491"),
    (191, "frost_wraith", "Frost Wraith", "EASY", "candidate-owner-3a824769b50006f93d2b3804be41490f1b6f4857dbb9111b-pipeline-017584f85998548ff6cdadbf"),
    (192, "merman", "Merman", "EASY", "candidate-owner-fd986ed2b6a7091f7bdb2b21732f02134bc62b68a4fbfedd-pipeline-075e3f96a50a523815ef1205"),
    (193, "spray_bottle", "Spray Bottle", "MEDIUM", "candidate-owner-87130d54e9474937928a5e83b7b6f33fbbd29b2ad2c55b36-pipeline-b5367a2245a30c61d61fedd7"),
    (194, "ent", "Ent", "EASY", "candidate-owner-26f9388ac3c4060591a47fac4a59faec9879d704b9e97993-pipeline-ef25d545a1431a1f3424836b"),
    (195, "clay_golem", "Clay Golem", "HARD", "candidate-owner-ec94c4b46c92a9297e7d50c1925543635d7cf841749b3f6d-pipeline-ab767148367ce4058e7935c6"),
    (196, "sea_star", "Sea Star", "EASY", "candidate-owner-e4541879eef90f48571b647dbbe08cec58079727557db39d-pipeline-dd36471012e9109d9eb44bda"),
    (197, "eye_bot", "Eye Bot", "EASY", "candidate-owner-fe90a6e88a2d4d3f8a8555d737b4b7553ce8e09e23c4c9a8-pipeline-d79a58b14ea91eb4706bb3cc"),
    (198, "goo_ghoul", "Goo Ghoul", "MEDIUM", "candidate-owner-eecd0137cb3885227c00b896e5d13dd91d2f1de2bd262c3b-pipeline-d61fb8d112465c0174586c09"),
    (199, "seal", "Seal", "EASY", "candidate-owner-4c7dbdc458993da8ae4d270281fbd6d9ee3cc21ba4596b28-pipeline-250d15f8ab489ad783feadf9"),
    (200, "sea_wyrm", "Sea Wyrm", "VERY_HARD", "candidate-owner-f8b09bed55b75dcb07e68f182c1175d642c06f32b161e661-pipeline-338a891908e6f34fb1fe20cd"),
]

# Per batch: levels, default pool root, entry folder, builder, Studio acceptance, sha256-checked roles.
BATCHES = {
    "l11-l30": (LEVELS, STUDIO, POOL, BUILDER, ("SOLVED", "WIN"), ("level", "supply_plan", "artwork")),
    "l31-l200": (LEVELS_L31_L200, GENERATOR, "data/Release Pool/Ready", "SB-CAMPAIGN-L31-L200/release-pool-import/v1",
                 ("WON_CANONICAL", "WON_CANONICAL"), ("level", "supply_plan", "artwork", "real_play_result")),
}


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def studio_path(studio, p):
    return p if os.path.isabs(p) else os.path.join(studio, p)


def write_json(rel, data, sort_keys):
    # Repo style: tab indent, trailing newline, LF in the index (core.autocrlf handles CRLF).
    with open(os.path.join(REPO, rel), "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(data, indent="\t", sort_keys=sort_keys, ensure_ascii=False) + "\n")


def import_level(batch, studio, cids, order, slug, name, klass, entry_name):
    _, _, pool, builder, accept, roles = batch
    entry_file = os.path.join(studio, pool, entry_name + "-ready.json")
    with open(entry_file, encoding="utf-8") as f:
        entry = json.load(f)
    cand = entry["candidate"]
    lineage = cand["source_lineage"]
    assert entry["schema"] == "scrubbots-release-pool-entry/v1", entry_name
    assert entry["candidate_id"].startswith("candidate-owner-"), entry_name
    assert lineage["derivation"] == "EXACT_LOGICAL_OWNER_UPLOAD_TO_CANONICAL_CANDIDATE", entry_name
    acc = entry["pipeline"]["primary"]["acceptance"]
    # Studio evidence only (its own ProofKernel-timing solver + replay); shippability is the
    # real-play gate run after the import (tools/real_play_verify.gd).
    assert (acc["solver_status"], acc["replay"]) == accept, entry_name
    files = {}
    for role in roles:
        p = studio_path(studio, entry["files"][role]["path"])
        assert sha256(p) == entry["files"][role]["sha256"], "%s %s sha256 mismatch" % (entry_name, role)
        files[role] = p
    with open(files["level"], encoding="utf-8") as f:
        src = json.load(f)
    with open(files["supply_plan"], encoding="utf-8") as f:
        plan = json.load(f)

    level_id = "level_%03d_%s" % (order, slug)
    level_rel = "data/levels/%s.json" % level_id
    plan_rel = "data/levels/supply/%s_supply_v1.json" % level_id
    meta_rel = "data/levels/metadata/%s.metadata.json" % level_id
    preview_rel = "assets/art/levels/previews/%s.png" % level_id

    level = {"cells": src["cells"], "difficulty": klass, "height": src["height"], "id": level_id,
             "name": name, "palette": src["palette"], "version": src["version"], "width": src["width"]}
    write_json(level_rel, level, True)

    old_id = plan["levelId"]
    plan["levelId"] = level_id
    prefix = "L%03d" % order
    for col in plan["columns"]:
        for b in col:
            assert b["batchId"].startswith(old_id + "-"), b["batchId"]
            b["batchId"] = prefix + b["batchId"][len(old_id):]
    write_json(plan_rel, plan, False)

    # Preview reconstructed from the final cells; VOID (-1) is transparent. Must equal the artwork.
    w, h = src["width"], src["height"]
    rgba = []
    for c in src["cells"]:
        if c == -1:
            rgba.append((0, 0, 0, 0))
        else:
            hx = src["palette"][c]
            rgba.append(tuple(int(hx[i:i + 2], 16) for i in (1, 3, 5, 7)))
    img = Image.new("RGBA", (w, h))
    img.putdata(rgba)
    px = Image.open(files["artwork"]).convert("RGBA").load()
    art = [px[x, y] if px[x, y][3] else (0, 0, 0, 0) for y in range(h) for x in range(w)]
    assert art == rgba, "%s: cells do not reproduce the artwork" % entry_name
    img.save(os.path.join(REPO, preview_rel), optimize=True)

    counts, first_seen = {}, []
    for c in src["cells"]:
        if c == -1:
            continue
        cid = cids[src["palette"][c][:7].upper()]
        if cid not in counts:
            first_seen.append(cid)
        counts[cid] = counts.get(cid, 0) + 1
    voids = src["cells"].count(-1)
    md = {
        "builderVersion": builder,
        "cellCount": w * h,
        "cellReferenceCounts": counts,
        "difficulty": klass,
        "firstSeenColorOrder": first_seen,
        "height": h,
        "normalizedColorOrder": [cids[p[:7].upper()] for p in src["palette"]],
        "outputPath": "res://" + level_rel,
        "paletteAuthority": "res://data/palettes/scrubbots_palette_v3.json",
        "previewPath": "res://" + preview_rel,
        "sourcePath": os.path.relpath(files["artwork"], studio).replace("\\", "/"),
        "sourceSha256": entry["files"]["artwork"]["sha256"],
        "usedColorCount": len(src["palette"]),
        "width": w,
        "releasePool": {
            "entryFile": pool + "/" + entry_name + "-ready.json",
            "entryDigest": entry["entry_digest"],
            "candidateId": entry["candidate_id"],
            "pipelineRunId": entry["pipeline_run_id"],
            "derivation": lineage["derivation"],
            "ownerSourceSha256": lineage["source_sha256"],
            "artworkSha256": entry["files"]["artwork"]["sha256"],
            "levelSha256": entry["files"]["level"]["sha256"],
            "supplyPlanSha256": entry["files"]["supply_plan"]["sha256"],
            "poolDifficultyClass": entry["difficulty_class"],
            "challengeScore": entry["challenge_score"],
            "sessionLoad": entry["session_load"],
            # Studio pipeline winnability evidence (its own solver + replay; not re-run here).
            "studioSolverStatus": acc["solver_status"],
            "studioReplay": acc["replay"],
        },
    }
    if voids:
        md["artworkCellCount"] = w * h - voids
        md["voidCellCount"] = voids
    if pool != POOL:
        # L31+: digest of the verbatim source cells ("c0,c1,..."), re-checked by tests/campaign_l31_l200.gd.
        md["releasePool"]["cellsSha256"] = hashlib.sha256(",".join(str(c) for c in src["cells"]).encode()).hexdigest()
    write_json(meta_rel, md, True)
    return {"id": level_id, "order": order, "level_path": "res://" + level_rel,
            "metadata_path": "res://" + meta_rel, "preview_path": "res://" + preview_rel,
            "supply_plan_path": "res://" + plan_rel}


def real_play_file(godot, entry):
    out = subprocess.run([godot, "--headless", "--path", REPO, "-s", "res://tools/real_play_file.gd", "--",
                          "--level-file", os.path.join(REPO, entry["level_path"][len("res://"):]),
                          "--plan-file", os.path.join(REPO, entry["supply_plan_path"][len("res://"):]), "--canonical-only"],
                         capture_output=True, text=True, encoding="utf-8", errors="replace")
    lines = [l for l in out.stdout.splitlines() if l.startswith("REAL_PLAY_RESULT ")]
    return json.loads(lines[-1][len("REAL_PLAY_RESULT "):]) if lines else {"verdict": "NO_RESULT"}


def gate_row(entry, r, regenerated):
    dt = (r.get("perDt") or {}).get("1/60", {})
    print("REAL_PLAY_FILE L%d %s %s frames=%s%s" % (entry["order"], entry["id"], r["verdict"], dt.get("frames"),
                                                    " (after --regen)" if regenerated else ""))
    return {"order": entry["order"], "levelId": entry["id"], "verdict": r["verdict"], "frames": dt.get("frames"),
            "gameCommit": r.get("gameCommit"), "planSha256": r.get("planSha256"), "levelSha256": r.get("levelSha256"),
            "runId": r.get("runId"), "regenerated": regenerated}


def gate_l31_l200(godot, entries):
    """real_play_file.gd on every imported level (4 in parallel), --regen the failures, write the report."""
    with ThreadPoolExecutor(4) as ex:
        results = list(ex.map(lambda e: real_play_file(godot, e), entries))
    with open(os.path.join(REPO, PROVENANCE), encoding="utf-8") as f:
        prov = json.load(f)
    records = [r for r in prov["records"] if r["order"] < entries[0]["order"]]
    report, failed = [], []
    for e, r in zip(entries, results):
        report.append(gate_row(e, r, False))
        if r["verdict"] != "WON_CANONICAL":
            failed.append(e)
            continue
        records.append({"canonicalDt": "1/60", "clicks": r["planClicks"], "framesAtCanonical": report[-1]["frames"],
                        "levelId": e["id"], "model": r["model"], "nodeBudget": 400, "order": e["order"],
                        "planSha256": r["planSha256"], "regenerated": False, "searchNodes": 0, "status": "WON"})
    prov["records"] = records
    write_json(PROVENANCE, prov, True)
    if failed:
        # Same clicks reordered by the real-play search; rewrites those plans' clicks and provenance records.
        subprocess.run([godot, "--headless", "--path", REPO, "-s", "res://tools/real_play_verify.gd", "--",
                        "--levels", ",".join(str(e["order"]) for e in failed), "--regen"])
        for e in failed:
            report[e["order"] - entries[0]["order"]] = gate_row(e, real_play_file(godot, e), True)
    write_json(GATE_REPORT, {"schema": "scrubbots.real_play_gate_report.v1",
                             "tool": "tools/real_play_file.gd --canonical-only", "levels": report}, False)
    return [row for row in report if row["verdict"] != "WON_CANONICAL"]


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--batch", choices=sorted(BATCHES), default="l11-l30")
    ap.add_argument("--studio", help="release-pool root (default: the batch's owner folder)")
    ap.add_argument("--godot", default=os.environ.get("GODOT", ""),
                    help="Godot 4.7.2 console executable for the real-play gate (default: env GODOT)")
    args = ap.parse_args()
    if not args.godot:
        sys.exit("import_release_pool_levels: no Godot given (--godot or env GODOT); the real-play gate "
                 "tools/real_play_verify.gd must run on the imported levels, refusing to import without it")
    with open(os.path.join(REPO, "data/palettes/scrubbots_palette_v3.json"), encoding="utf-8") as f:
        cids = {c["hex"].upper(): c["id"] for c in json.load(f)["colors"]}
    cat_rel = "data/levels/catalog/production_catalog_v1.json"
    with open(os.path.join(REPO, cat_rel), encoding="utf-8") as f:
        cat = json.load(f)
    batch = BATCHES[args.batch]
    levels = batch[0]
    entries = [e for e in cat["entries"] if e["order"] < levels[0][0]]
    for row in levels:
        entries.append(import_level(batch, args.studio or batch[1], cids, *row))
        print("imported", entries[-1]["id"])
    cat["entries"] = entries
    write_json(cat_rel, cat, False)
    if args.batch == "l31-l200":
        bad = gate_l31_l200(args.godot, entries[levels[0][0] - 1:])
        if bad:
            sys.exit("import_release_pool_levels: real-play gate: not WON_CANONICAL after --regen: %s"
                     % ", ".join("L%d" % r["order"] for r in bad))
        return
    orders = ",".join(str(row[0]) for row in levels)
    gate = subprocess.run([args.godot, "--headless", "--path", REPO, "-s", "res://tools/real_play_verify.gd",
                           "--", "--levels", orders, "--regen"])
    if gate.returncode != 0:
        sys.exit("import_release_pool_levels: real-play gate failed (exit %d); see the LEVEL/UNWINNABLE lines above"
                 % gate.returncode)


if __name__ == "__main__":
    main()
