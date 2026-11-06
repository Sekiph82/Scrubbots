#!/usr/bin/env python3
"""SB-M59-004/005: stamp data/config/app_version.json for one CI export.

The JSON is the single version source. `version` (semantic, owner-bumped) never
changes here; CI writes `build` = GitHub run_number + build_offset (monotonic per
workflow) and `channel` (debug | release), then prints GITHUB_ENV lines:

  APP_VERSION       0.1.0                 (iOS CFBundleShortVersionString)
  APP_BUILD         123                   (Android version/code, iOS CFBundleVersion)
  APP_VERSION_NAME  0.1.0-debug | 0.1.0   (Android version/name)
  OUT_DIR           build/<platform>/<channel>
  ARTIFACT          ScrubBots-<Platform>-<channel>-v<version>-b<build>

Usage: python3 -I .github/scripts/app_version.py <android|ios> <debug|release> <run_number>
"""
import json
import re
import sys

PATH = "data/config/app_version.json"


def main(argv):
    if len(argv) != 4 or argv[1] not in ("android", "ios") or argv[2] not in ("debug", "release") or not argv[3].isdigit():
        sys.exit("usage: app_version.py <android|ios> <debug|release> <run_number>")
    platform, channel, run = argv[1], argv[2], int(argv[3])
    with open(PATH, encoding="utf-8") as f:
        d = json.load(f)
    if not re.fullmatch(r"\d+\.\d+\.\d+", str(d.get("version", ""))):
        sys.exit("error: %s version must be MAJOR.MINOR.PATCH, got %r" % (PATH, d.get("version")))
    build = run + int(d["build_offset"])
    if build < 1:
        sys.exit("error: build number must be >= 1, got %d" % build)
    d["build"] = build
    d["channel"] = channel
    with open(PATH, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=2)
        f.write("\n")
    name = d["version"] + ("" if channel == "release" else "-debug")
    print("APP_VERSION=%s" % d["version"])
    print("APP_BUILD=%d" % build)
    print("APP_VERSION_NAME=%s" % name)
    print("OUT_DIR=build/%s/%s" % (platform, channel))
    print("ARTIFACT=ScrubBots-%s-%s-v%s-b%d" % ("Android" if platform == "android" else "iOS", channel, d["version"], build))


if __name__ == "__main__":
    main(sys.argv)
