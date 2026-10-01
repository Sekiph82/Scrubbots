# M42-C003 V03 common animation canvas + pivot

- Canvas: **464x512** RGBA8 animation pixels for all 63 frames (= 1392x1536 HOME texels).
- Common pivot (planted rubber-sole midpoint): **(219, 477)** animation px.
- Storage density: 3 HOME-026 texels per animation pixel; runtime size = canvas x 3 x k (k = screen px per HOME texel of the accepted M42-C002 layout).
- HOME-026 sole root (same detector): (638.5, 1324.0) HOME texels; runtime maps the animation pivot onto that HOME screen point.
- Union of the 63 registered frames relative to the pivot (anim px): [-202.474, -460.544, 213.39, 17.217]; margin 16 px each side; dimensions rounded up to a multiple of 16.
- Resampler: Pillow Image.transform(AFFINE, BICUBIC) on premultiplied RGBa, exact sub-pixel root registration; alpha <= 2 removed before and after.
- Texture memory: 63 x 464x512 x 4 B = 57.1 MiB uncompressed (a 1:1 HOME-texel canvas would be 514 MiB).

## Sequence mapping

- wave (14): wave frames [1, 2, 3, 4, 5, 6, 7, 8, 7, 6, 5, 4, 3, 2]
- bow (15): bow frames [1, 2, 3, 4, 5, 6, 7, 7, 7, 8, 9, 10, 11, 1, 1]
- turn (17): turn_look frames [1, 2, 6, 5, 6, 7, 8, 8, 9, 10, 10, 9, 8, 15, 16, 17, 1]
- full_turn (17): full_turn frames [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]

## Frames

| Gesture | Frame | Source | Source root | Alpha>128 bbox | SHA-256 |
|---|---:|---|---|---|---|
| wave | 01 | wave 01 | [173.0, 350.0] | [24, 27, 372, 478] | `efa8e7c0163354275173a54dde624b9316c7c025584f5880c4057a7ef905a65f` |
| wave | 02 | wave 02 | [208.0, 350.0] | [24, 29, 385, 478] | `2ce33f7b1acb7f03af5da1f54cceee839c873e36be2a61b7fa9148fc1920c153` |
| wave | 03 | wave 03 | [239.0, 350.0] | [26, 24, 389, 478] | `8cbf742fe5dc8ad3664e76e2f481ec356ca1f223c7ffddcf77855cca57fecd43` |
| wave | 04 | wave 04 | [283.5, 350.0] | [26, 24, 369, 478] | `0c045c1893c5aa873b293b43712ac8dc3b8fd7faa3dcc2f059c16f0a3e53405f` |
| wave | 05 | wave 05 | [173.0, 352.0] | [28, 29, 383, 479] | `bee622ab94b729cb931a8aca7a7e16b4a596dba100d5b67c829b241e83b24a89` |
| wave | 06 | wave 06 | [208.0, 352.0] | [28, 29, 375, 479] | `085d548fb6fd6a694ff9cb50d3f8c0b7af174817f3c815750a7db8689c3caab1` |
| wave | 07 | wave 07 | [247.5, 352.0] | [29, 29, 365, 479] | `fffc7b805329711087c8635258e32e0a4e95efc521d74dad9018bda570dcf743` |
| wave | 08 | wave 08 | [283.5, 352.0] | [26, 28, 357, 479] | `8c860575c9dc466dcfb308c267a8417c567ec0ae29d8c47685818d761afa44f4` |
| wave | 09 | wave 07 | [247.5, 352.0] | [29, 29, 365, 479] | `fffc7b805329711087c8635258e32e0a4e95efc521d74dad9018bda570dcf743` |
| wave | 10 | wave 06 | [208.0, 352.0] | [28, 29, 375, 479] | `085d548fb6fd6a694ff9cb50d3f8c0b7af174817f3c815750a7db8689c3caab1` |
| wave | 11 | wave 05 | [173.0, 352.0] | [28, 29, 383, 479] | `bee622ab94b729cb931a8aca7a7e16b4a596dba100d5b67c829b241e83b24a89` |
| wave | 12 | wave 04 | [283.5, 350.0] | [26, 24, 369, 478] | `0c045c1893c5aa873b293b43712ac8dc3b8fd7faa3dcc2f059c16f0a3e53405f` |
| wave | 13 | wave 03 | [239.0, 350.0] | [26, 24, 389, 478] | `8cbf742fe5dc8ad3664e76e2f481ec356ca1f223c7ffddcf77855cca57fecd43` |
| wave | 14 | wave 02 | [208.0, 350.0] | [24, 29, 385, 478] | `2ce33f7b1acb7f03af5da1f54cceee839c873e36be2a61b7fa9148fc1920c153` |
| bow | 01 | bow 01 | [217.5, 412.0] | [29, 33, 319, 481] | `eb42d9ff5c9a2324591fcfc9c76f8eb8ae3a4e0f6cd2a17a5b36c1c845aa6ec2` |
| bow | 02 | bow 02 | [254.0, 420.0] | [32, 35, 324, 478] | `7a1afc579e67a10c636a75e0718dd13a6d4dd6f7afecc25dcdf499709110bf87` |
| bow | 03 | bow 03 | [291.5, 421.0] | [41, 80, 326, 480] | `7f1c5a2e36d8066a40864b4b82c70d96de50752bb0352c1a16600c9dd17cfa4d` |
| bow | 04 | bow 04 | [326.5, 417.0] | [42, 100, 348, 481] | `7ece509eff21dc36fc2896c3eb8f147796c6de29e5e3c62c90b2d0861daf0b06` |
| bow | 05 | bow 05 | [333.0, 396.0] | [44, 130, 363, 481] | `c5485802517456bd7560a5e78b2f09be6108d5a22b5f859a1cb82fd8f23bd85e` |
| bow | 06 | bow 06 | [195.5, 490.0] | [41, 140, 370, 481] | `56179f19f7e3015aac2181c423f032c3530f4b263b6cf1ab5bd9b620cb7f4e8a` |
| bow | 07 | bow 07 | [255.5, 476.0] | [42, 146, 368, 480] | `3e1251646f5bc3c971aa5d3404d4171ea197b59313e27bee39b540b0f7a08629` |
| bow | 08 | bow 07 | [255.5, 476.0] | [42, 146, 368, 480] | `3e1251646f5bc3c971aa5d3404d4171ea197b59313e27bee39b540b0f7a08629` |
| bow | 09 | bow 07 | [255.5, 476.0] | [42, 146, 368, 480] | `3e1251646f5bc3c971aa5d3404d4171ea197b59313e27bee39b540b0f7a08629` |
| bow | 10 | bow 08 | [293.5, 502.0] | [44, 140, 359, 480] | `1cb3a28241da189cc6d1a618511dd8b2d929483fc7e6828a64ba2afa9fd530f8` |
| bow | 11 | bow 09 | [318.0, 495.0] | [38, 92, 355, 480] | `aa946e763671d311adad3ad80a795fceb38e542dd2c50623a8b705d18f229931` |
| bow | 12 | bow 10 | [354.0, 511.0] | [37, 83, 321, 480] | `91dc159903a976e0108cff36ac56e412e5579750ba9d258c0cfb8ddbdc51c9e4` |
| bow | 13 | bow 11 | [217.0, 558.0] | [27, 37, 318, 481] | `ed44d9c94098765377e34c08f6f2f2f247ada9a2bc8b615b2646e6e9ebb447bc` |
| bow | 14 | bow 01 | [217.5, 412.0] | [29, 33, 319, 481] | `eb42d9ff5c9a2324591fcfc9c76f8eb8ae3a4e0f6cd2a17a5b36c1c845aa6ec2` |
| bow | 15 | bow 01 | [217.5, 412.0] | [29, 33, 319, 481] | `eb42d9ff5c9a2324591fcfc9c76f8eb8ae3a4e0f6cd2a17a5b36c1c845aa6ec2` |
| turn | 01 | turn_look 01 | [178.5, 266.0] | [26, 83, 349, 480] | `ac4d8d762391ed6992120dc597381571afbbfdb58ece7e1778c0cb116822974e` |
| turn | 02 | turn_look 02 | [205.5, 269.0] | [30, 72, 338, 479] | `78f63e958cb4306c3d20ef48e7d7b75ce255707bd1617b23eea13cfac8c8daed` |
| turn | 03 | turn_look 06 | [213.0, 264.0] | [35, 90, 329, 481] | `dfc4004b9a236bd4b94aae41b4a6020559772802afc31e5d7b4e62e149f3870c` |
| turn | 04 | turn_look 05 | [195.0, 264.0] | [35, 75, 316, 479] | `6d39d830b23b15379af63d63639b9e3417da0006c2cd13465e9cd8b93a8def5a` |
| turn | 05 | turn_look 06 | [213.0, 264.0] | [35, 90, 329, 481] | `dfc4004b9a236bd4b94aae41b4a6020559772802afc31e5d7b4e62e149f3870c` |
| turn | 06 | turn_look 07 | [217.0, 264.0] | [31, 76, 335, 479] | `03bd68d479dcfb1e12fbea4d3a773a530c3d1a54adf94dcef330bdae3aa0952a` |
| turn | 07 | turn_look 08 | [227.0, 266.0] | [30, 77, 339, 480] | `55cb6023ed9b5c6d41b38f80ce97e42c2cd42265005acc376b33577bd11341c4` |
| turn | 08 | turn_look 08 | [227.0, 266.0] | [30, 77, 339, 480] | `55cb6023ed9b5c6d41b38f80ce97e42c2cd42265005acc376b33577bd11341c4` |
| turn | 09 | turn_look 09 | [147.0, 263.0] | [116, 71, 411, 482] | `6f1b6b9915bcedf456149e073a3bb9a10eacbffe051330bb02ee56722f6772dc` |
| turn | 10 | turn_look 10 | [160.5, 262.0] | [120, 72, 413, 479] | `8a6d79b25997ca91210e9ac01e6aff4b75bb3eed53507a91751161c5ff749e21` |
| turn | 11 | turn_look 10 | [160.5, 262.0] | [120, 72, 413, 479] | `8a6d79b25997ca91210e9ac01e6aff4b75bb3eed53507a91751161c5ff749e21` |
| turn | 12 | turn_look 09 | [147.0, 263.0] | [116, 71, 411, 482] | `6f1b6b9915bcedf456149e073a3bb9a10eacbffe051330bb02ee56722f6772dc` |
| turn | 13 | turn_look 08 | [227.0, 266.0] | [30, 77, 339, 480] | `55cb6023ed9b5c6d41b38f80ce97e42c2cd42265005acc376b33577bd11341c4` |
| turn | 14 | turn_look 15 | [216.5, 259.0] | [28, 83, 335, 479] | `fa7db8e76037be48393f76d20c4c5ab4029946aeb0b87bc17d13732496b68f52` |
| turn | 15 | turn_look 16 | [228.5, 260.0] | [25, 79, 336, 478] | `b2acb7a37ff1f594626185f4330c1ac78a3971b47a1ac7dd937e2f4ec3342c95` |
| turn | 16 | turn_look 17 | [178.5, 266.0] | [26, 83, 349, 480] | `ac4d8d762391ed6992120dc597381571afbbfdb58ece7e1778c0cb116822974e` |
| turn | 17 | turn_look 01 | [178.5, 266.0] | [26, 83, 349, 480] | `ac4d8d762391ed6992120dc597381571afbbfdb58ece7e1778c0cb116822974e` |
| full_turn | 01 | full_turn 01 | [307.0, 476.0] | [39, 35, 379, 478] | `f75df8059e17a03ff0bf385147ab17a59b1b10ddea30618616a7ed8ac52268ab` |
| full_turn | 02 | full_turn 02 | [303.0, 476.0] | [56, 33, 360, 478] | `c6f658e0af85a8128d0e6cd9edc14cf18fadd1994b7a29c35b64119fcab2c352` |
| full_turn | 03 | full_turn 03 | [294.0, 470.0] | [93, 40, 330, 490] | `a64b1e6f81f4b5a9ce3f6090e86f0b0908037165e103163d24673e0927caf5fa` |
| full_turn | 04 | full_turn 04 | [319.0, 478.0] | [87, 35, 298, 480] | `a1ce0df8292a7e652185f4bf0ea6751ca744ecaac382506e8b650d2844393732` |
| full_turn | 05 | full_turn 05 | [282.5, 471.0] | [137, 43, 371, 482] | `8601d565a76b2da53c2e75d3d98fc20ea0a433a96fac94898111190e239108ef` |
| full_turn | 06 | full_turn 06 | [285.0, 476.0] | [62, 43, 400, 479] | `503adca5657aa19568c06fa60bc2eeef37502cefb8b26c6814b46d91bccbb27c` |
| full_turn | 07 | full_turn 07 | [273.0, 472.0] | [101, 52, 402, 479] | `327272507d4fda5b1404d25096b81c9f996bc68cd61a8924a960e7a352dac504` |
| full_turn | 08 | full_turn 08 | [263.5, 469.0] | [114, 50, 409, 478] | `74a1d9a8eb2962247a6747af55f89885f71d59ff9b24fcff8cb62bf6ca187b78` |
| full_turn | 09 | full_turn 09 | [264.0, 455.0] | [113, 54, 421, 478] | `e85d749df3c1070af141ab747abc8201a25d7ca5b8757eae6356425454a11ed5` |
| full_turn | 10 | full_turn 10 | [292.0, 470.0] | [81, 47, 365, 479] | `a3b51ae1d524243efe2b145eeea9b1b30800d3c404bc5b9058c3da8bf420ce64` |
| full_turn | 11 | full_turn 11 | [271.0, 473.0] | [100, 39, 415, 479] | `6fa723fe5ff7f53d7c148dd25ade23c616f124af3994573ed91b191e626e936d` |
| full_turn | 12 | full_turn 12 | [261.0, 477.0] | [121, 36, 428, 479] | `b0316f5e9b136664ec8ce330e38bdfb3c5d2684b8349c399e3de4046ead9d2be` |
| full_turn | 13 | full_turn 13 | [272.0, 408.0] | [91, 34, 408, 478] | `bd7371bfd068aea8a97aaaeedea839d7d54bafc8f123f4bde480f48f9dea0862` |
| full_turn | 14 | full_turn 14 | [280.5, 407.0] | [83, 34, 406, 479] | `16acbe42ead202199625221a8c462b92a488f357bae33f0a96760028c6c5b8d7` |
| full_turn | 15 | full_turn 15 | [335.0, 420.0] | [43, 20, 295, 482] | `993fad7a0eff01a4bee8401f388ad75452c8fa61d083e3557c5688e4dda067e2` |
| full_turn | 16 | full_turn 16 | [319.0, 470.0] | [37, 56, 327, 478] | `75144c602a24d891366ea6ffd6738843e2ece7d75335d55b7700bc1473d17a72` |
| full_turn | 17 | full_turn 17 | [239.5, 467.0] | [27, 63, 342, 481] | `116030bf0dad00179cc8bf40a8e8065d84db2ca1af7671859814d5fe07b6d241` |
