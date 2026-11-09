#!/usr/bin/env python3
"""SB-M59-001..005 static release/versioning check (stdlib only; run with python -I).

  python -I tools/check_release_versioning.py             # check the repository
  python -I tools/check_release_versioning.py --selftest  # prove the checks catch breakage

Asserts:
  - data/config/app_version.json is the ONE version source (semantic version, repo state
    build 0 / channel debug) and every consumer derives from it: the Android preset only has
    placeholders, both workflows stamp through .github/scripts/app_version.py and feed
    APP_BUILD / APP_VERSION(_NAME) into Android version/code+name and iOS
    CFBundleVersion/short version, the Settings label reads the same JSON;
  - no literal version string anywhere in the workflows / preset;
  - release paths never use a debug key: every step touching the debug keystore is guarded
    `build_type != 'release'`, release keystore/signing steps are guarded `== 'release'`,
    name no debug key and fail fast when a secret is absent; the Android export command
    picks --export-release only for release;
  - outputs go to build/<platform>/<build_type>/ with version+build in the artifact name; iOS
    exports and builds under the fixed basename Scrubbots and is renamed only afterwards;
  - no store upload anywhere;
  - SB-M59-006/007/009 release gate: a release export (Android build_apk or apk_only, iOS) runs only
    after the full validate suites, the content validator (tools/validate_content.gd) and the
    clean-clone check (tools/clean_clone_check.py) succeeded; only debug apk_only skips them;
  - SB-M59-010 export hygiene: every tree in the export exclusions file (tests, tools, editor-only
    addons/godot_ai, ...) is in both presets' exclude_filter and absent from both export
    workspaces; every shipped addon has its licence file in-repo, included in both exports and shown
    by the CREDITS screen; project.godot registers each addon autoload exactly once and never
    loads godot_ai.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION_JSON = "data/config/app_version.json"
ANDROID = ".github/workflows/android-family-first10.yml"
IOS = ".github/workflows/ios-ipa.yml"
PRESET = ".github/android/export_presets_family_first10.cfg"
STAMP = ".github/scripts/app_version.py"
SETTINGS = "scripts/ui/settings_panel.gd"
EXCLUSIONS = ".github/android/family_first10_export_exclusions.txt"
PROJECT = "project.godot"
CREDITS = "scripts/ui/credits_screen.gd"
# Shipped addons: autoload name -> licence file (MIT).
ADDONS = {"GameFeelFlow": "addons/game_feel_flow/LICENSE", "Spark": "addons/saltmire_spark/LICENSE.txt"}
GATE_IF = "!github.event.repository.private && (inputs.mode != 'apk_only' || inputs.build_type == 'release')"
EXPORT_IF = ("always() && !github.event.repository.private && ((inputs.mode == 'apk_only' && inputs.build_type != 'release') || "
             "((inputs.mode == 'build_apk' || inputs.mode == 'apk_only') && needs.validate.result == 'success' && "
             "(inputs.build_type != 'release' || needs.clean_clone.result == 'success')))")
IOS_GATE_IF = "!github.event.repository.private && inputs.build_type == 'release'"
IOS_IPA_IF = "always() && !github.event.repository.private && (inputs.build_type != 'release' || needs.release_gate.result == 'success')"
CONTENT_STEP = "res://tools/validate_content.gd"
CONTENT_PASS = "grep -q '^CONTENT_VALIDATION PASS' content_validation.log"
DEBUG_KEY = re.compile(r"ANDROID_DEBUG_KEYSTORE|GODOT_ANDROID_KEYSTORE_DEBUG|debug_keystore|keytool -genkeypair|androiddebugkey")
UPLOAD = re.compile(r"upload-google-play|r0adkll|altool|notarytool|fastlane|xcrun\s+upload|<string>upload</string>|play.googleapis", re.I)
LITERAL_VERSION = re.compile(r"(version/(code|name)|short_version|application/version)\s*=\s*\"?\d")


def read(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return f.read().replace("\r\n", "\n")


def steps(text):
    """Split a workflow into (name, body) per `- name:` / `- uses:` step."""
    parts = re.split(r"\n(?=      - (?:name|uses):)", text)
    out = []
    for p in parts[1:]:
        m = re.match(r"      - (?:name|uses):\s*(.*)", p)
        out.append((m.group(1).strip(), p))
    return out


def check_signing(text, release_secret_prefix):
    """Errors for the debug-vs-release signing rules of one workflow text."""
    errs = []
    release_steps = 0
    for name, body in steps(text):
        guard = re.search(r"^        if: \$\{\{(.*)\}\}", body, re.M)
        guard = guard.group(1) if guard else ""
        if DEBUG_KEY.search(body) and "build_type != 'release'" not in guard:
            errs.append("step %r uses the debug key without an `inputs.build_type != 'release'` guard" % name)
        if release_secret_prefix in body:
            release_steps += 1
            if "build_type == 'release'" not in guard:
                errs.append("step %r reads release signing secrets without an `inputs.build_type == 'release'` guard" % name)
            if DEBUG_KEY.search(body):
                errs.append("release signing step %r names a debug key" % name)
            if not re.search(r"if \[ -z .*\n\s+echo \"::error::release build needs GitHub Secrets.*\n\s+exit 1", body):
                errs.append("release signing step %r does not fail fast when a secret is absent" % name)
    if release_steps != 1:
        errs.append("expected exactly one release signing step reading %s*, found %d" % (release_secret_prefix, release_steps))
    if UPLOAD.search(text):
        errs.append("store upload found: %r" % UPLOAD.search(text).group(0))
    return errs


def check_android_export(text):
    errs = []
    if text.count("--export-release") != 1 or text.count("--export-debug") != 1 \
            or 'if [ "$BUILD_TYPE" = release ]; then EXPORT=--export-release; else EXPORT=--export-debug; fi' not in text:
        errs.append("Android export must choose --export-release only when BUILD_TYPE = release")
    return errs


def check_ios_basename(ios):
    """Godot derives the Xcode project / scheme / binary / .pck name from the export basename: keep it "Scrubbots"."""
    if not re.search(r"^  APP_NAME: Scrubbots\b", ios, re.M) or 'export_path="${OUT_DIR}/${APP_NAME}.ipa"' not in ios \
            or '--export-release "iOS" "${OUT_DIR}/${APP_NAME}.ipa"' not in ios \
            or 'mv "${APP_NAME}.ipa" "${ARTIFACT}.ipa"' not in ios or re.search(r'export_path="[^"]*ARTIFACT', ios):
        return ["%s must export/build under the fixed basename Scrubbots and rename to ${ARTIFACT}.ipa only afterwards" % IOS]
    return []


def check_inputs(text, wf):
    if not re.search(r"      build_type:\n(?:        .*\n)*?        default: debug\n        options:\n          - debug\n          - release\n", text):
        return ["%s: workflow_dispatch input build_type (choice debug|release, default debug) missing" % wf]
    return []


def job(text, name):
    """The body of one top-level job (`  name:` up to the next job), or ""."""
    m = re.search(r"^  %s:\n(.*?)(?=^  [A-Za-z_]+:\n|\Z)" % re.escape(name), text, re.M | re.S)
    return m.group(1) if m else ""


def job_if(body):
    m = re.search(r"^    if: \$\{\{ (.*?) \}\}", body, re.M)
    return m.group(1) if m else None


def check_gate(android, ios):
    """SB-M59-006/007/009: release exports only after validate + content validator + clean clone."""
    errs = []
    v, cc, ex = job(android, "validate"), job(android, "clean_clone"), job(android, "export")
    if job_if(v) != GATE_IF:
        errs.append("%s validate must run for everything but debug apk_only: if %r" % (ANDROID, GATE_IF))
    for need in ("tools/check_release_versioning.py", CONTENT_STEP, CONTENT_PASS, "for s in "):
        if need not in v:
            errs.append("%s validate does not run %r" % (ANDROID, need))
    if job_if(cc) != GATE_IF or "python3 -I tools/clean_clone_check.py" not in cc:
        errs.append("%s clean_clone job (tools/clean_clone_check.py, if %r) missing" % (ANDROID, GATE_IF))
    if "    needs: [validate, clean_clone]\n" not in ex or job_if(ex) != EXPORT_IF:
        errs.append("%s export must need [validate, clean_clone] with if %r" % (ANDROID, EXPORT_IF))
    g, ipa = job(ios, "release_gate"), job(ios, "ipa")
    if job_if(g) != IOS_GATE_IF:
        errs.append("%s release_gate must run for release: if %r" % (IOS, IOS_GATE_IF))
    for need in ("python3 -I tools/clean_clone_check.py", "python3 -I tools/check_release_versioning.py", CONTENT_STEP, CONTENT_PASS,
                 "python3 -I tools/run_suites.py"):
        if need not in g:
            errs.append("%s release_gate does not run %r" % (IOS, need))
    if "    needs: release_gate\n" not in ipa or job_if(ipa) != IOS_IPA_IF:
        errs.append("%s ipa must need release_gate with if %r" % (IOS, IOS_IPA_IF))
    return errs


def filter_line(text, key):
    m = re.search(r'^\s*%s="([^"]*)"' % key, text, re.M)
    return [x.strip() for x in m.group(1).split(",")] if m else []


def check_hygiene(android, ios, preset, exclusions, project, credits):
    """SB-M59-010: exclusions in both presets + export workspaces, addon licences shipped, autoloads once."""
    errs = []
    trees = [l.strip() for l in exclusions.splitlines() if l.strip() and not l.startswith("#")]
    for must in ("tests", "tools", "addons/godot_ai"):
        if must not in trees:
            errs.append("%s does not exclude %s" % (EXCLUSIONS, must))
    for name, text, ws in ((PRESET, preset, job(android, "export")), (IOS, ios, job(ios, "ipa"))):
        excl, incl = filter_line(text, "exclude_filter"), filter_line(text, "include_filter")
        for t in trees:
            if t + "/*" not in excl:
                errs.append("%s exclude_filter misses %s/*" % (name, t))
            if "            !/%s/\n" % t not in ws:
                errs.append("%s export checkout does not leave out %s" % (name, t))
        for lic in ADDONS.values():
            if lic not in incl:
                errs.append("%s include_filter does not ship %s" % (name, lic))
    for auto, lic in ADDONS.items():
        n = len(re.findall(r"^%s=" % auto, project, re.M))
        if n != 1:
            errs.append("%s registers autoload %s %d times (exactly once)" % (PROJECT, auto, n))
        if not os.path.isfile(os.path.join(ROOT, lic)) or "MIT License" not in read(lic):
            errs.append("%s missing or not an MIT licence" % lic)
        if "res://" + lic not in credits:
            errs.append("%s does not show res://%s" % (CREDITS, lic))
    if "godot_ai" in project:
        errs.append("%s references godot_ai (editor-only, never shipped)" % PROJECT)
    return errs


def check_repo():
    errs = []
    d = json.loads(read(VERSION_JSON))
    if not re.fullmatch(r"\d+\.\d+\.\d+", str(d.get("version"))):
        errs.append("%s version %r is not MAJOR.MINOR.PATCH" % (VERSION_JSON, d.get("version")))
    if d.get("build") != 0 or d.get("channel") != "debug" or not isinstance(d.get("build_offset"), int) or d["build_offset"] < 0:
        errs.append("%s must be committed as build 0 / channel debug / build_offset >= 0 (CI stamps it): %r" % (VERSION_JSON, d))
    android, ios, preset, stamp, settings = read(ANDROID), read(IOS), read(PRESET), read(STAMP), read(SETTINGS)
    if VERSION_JSON not in stamp:
        errs.append("%s does not read %s" % (STAMP, VERSION_JSON))
    if "res://" + VERSION_JSON not in settings:
        errs.append("%s does not read res://%s" % (SETTINGS, VERSION_JSON))
    for wf, text, plat in ((ANDROID, android, "android"), (IOS, ios, "ios")):
        if 'python3 -I %s %s "$BUILD_TYPE" "$GITHUB_RUN_NUMBER" | tee -a "$GITHUB_ENV"' % (STAMP, plat) not in text:
            errs.append("%s does not stamp the version through %s" % (wf, STAMP))
        if LITERAL_VERSION.search(text):
            errs.append("%s has a literal version: %r" % (wf, LITERAL_VERSION.search(text).group(0)))
        if "${{ env.OUT_DIR }}/${{ env.ARTIFACT }}" not in text:
            errs.append("%s does not upload ${OUT_DIR}/${ARTIFACT}" % wf)
        errs += check_inputs(text, wf)
    if not re.search(r'^version/code=@VERSION_CODE@$', preset, re.M) or not re.search(r'^version/name="@VERSION_NAME@"$', preset, re.M) \
            or LITERAL_VERSION.search(preset):
        errs.append("%s version/code + version/name must be the @VERSION_CODE@ / @VERSION_NAME@ placeholders" % PRESET)
    if 'sed -e "s/@VERSION_CODE@/${APP_BUILD}/" -e "s/@VERSION_NAME@/${APP_VERSION_NAME}/"' not in android:
        errs.append("%s does not fill the preset from APP_BUILD / APP_VERSION_NAME" % ANDROID)
    if 'application/short_version="${APP_VERSION}"' not in ios or 'application/version="${APP_BUILD}"' not in ios:
        errs.append("%s does not set CFBundleShortVersionString / CFBundleVersion from APP_VERSION / APP_BUILD" % IOS)
    errs += check_ios_basename(ios)
    if 'print("OUT_DIR=build/%s/%s" % (platform, channel))' not in stamp:
        errs.append("%s no longer emits OUT_DIR=build/<platform>/<channel>" % STAMP)
    errs += check_signing(android, "ANDROID_RELEASE_KEYSTORE_")
    errs += check_signing(ios, "IOS_DIST_CERT_")
    errs += check_android_export(android)
    errs += check_gate(android, ios)
    errs += check_hygiene(android, ios, preset, read(EXCLUSIONS), read(PROJECT), read(CREDITS))
    return errs


def selftest():
    android = read(ANDROID)
    bad = {
        "debug key unguarded": android.replace("        if: ${{ inputs.build_type != 'release' }}\n", "", 1),
        "release step reads debug key": android.replace("RKS_B64: ${{ secrets.ANDROID_RELEASE_KEYSTORE_BASE64 }}",
                                                        "RKS_B64: ${{ secrets.ANDROID_RELEASE_KEYSTORE_BASE64 || secrets.ANDROID_DEBUG_KEYSTORE_BASE64 }}"),
        "release no fail-fast": android.replace("Not signing.\"\n            exit 1", "Not signing.\"", 1),
        "store upload": android + "\n      - uses: r0adkll/upload-google-play@v1\n",
    }
    fails = 0
    if check_signing(android, "ANDROID_RELEASE_KEYSTORE_"):
        print("FAIL selftest: the real workflow does not pass"); fails += 1
    for label, text in bad.items():
        if text == android or not check_signing(text, "ANDROID_RELEASE_KEYSTORE_"):
            print("FAIL selftest: not caught: " + label); fails += 1
        else:
            print("ok selftest: caught " + label)
    if not check_android_export(android.replace("then EXPORT=--export-release; else EXPORT=--export-debug", "then EXPORT=--export-debug; else EXPORT=--export-release")):
        print("FAIL selftest: swapped export not caught"); fails += 1
    else:
        print("ok selftest: caught swapped export")
    ios = read(IOS).replace('export_path="${OUT_DIR}/${APP_NAME}.ipa"', 'export_path="${OUT_DIR}/${ARTIFACT}.ipa"')
    if "fixed basename Scrubbots" not in " ".join(check_ios_basename(ios)):
        print("FAIL selftest: versioned iOS export basename not caught"); fails += 1
    else:
        print("ok selftest: caught versioned iOS export basename")
    fails += selftest_gate_hygiene()
    return fails


def selftest_gate_hygiene():
    android, ios, preset, excl, project, credits = read(ANDROID), read(IOS), read(PRESET), read(EXCLUSIONS), read(PROJECT), read(CREDITS)
    real = (android, ios, preset, excl, project, credits)
    fails = 0
    if check_gate(android, ios) or check_hygiene(*real):
        print("FAIL selftest: the real gate/hygiene does not pass"); fails += 1
    old_export_if = "always() && !github.event.repository.private && ((inputs.mode == 'build_apk' && needs.validate.result == 'success') || inputs.mode == 'apk_only')"
    gate = {
        "validate skipped for release apk_only": (android.replace(GATE_IF, "!github.event.repository.private && inputs.mode != 'apk_only'", 1), ios),
        "release apk_only exports without validate": (android.replace(EXPORT_IF, old_export_if), ios),
        "export does not need clean_clone": (android.replace("needs: [validate, clean_clone]", "needs: validate"), ios),
        "content validator dropped": (android.replace(CONTENT_PASS, "true", 1), ios),
        "clean_clone job dropped": (android.replace("python3 -I tools/clean_clone_check.py", "true"), ios),
        "iOS release without the gate": (android, ios.replace("needs.release_gate.result == 'success'", "true")),
        "iOS gate without the suites": (android, ios.replace("python3 -I tools/run_suites.py", "true")),
    }
    for label, (a, i) in gate.items():
        if (a, i) == (android, ios) or not check_gate(a, i):
            print("FAIL selftest: not caught: " + label); fails += 1
        else:
            print("ok selftest: caught " + label)
    hyg = {
        "godot_ai not excluded by the Android preset": (android, ios, preset.replace("addons/godot_ai/*, ", ""), excl, project, credits),
        "tools tree in the iOS workspace": (android, ios.replace("            !/tools/\n", "", 1), preset, excl, project, credits),
        "licence not shipped by iOS": (android, ios.replace("addons/saltmire_spark/LICENSE.txt\"", "\""), preset, excl, project, credits),
        "duplicate autoload": (android, ios, preset, excl, project.replace("Spark=", "Spark=\"*res://x.gd\"\nSpark=", 1), credits),
        "godot_ai loaded": (android, ios, preset, excl, project + "\nGodotAI=\"*res://addons/godot_ai/x.gd\"\n", credits),
        "credits lacks a licence": (android, ios, preset, excl, project, credits.replace("res://addons/game_feel_flow/LICENSE", "")),
    }
    for label, args in hyg.items():
        if args == real or not check_hygiene(*args):
            print("FAIL selftest: not caught: " + label); fails += 1
        else:
            print("ok selftest: caught " + label)
    return fails


def main():
    if "--selftest" in sys.argv:
        fails = selftest()
        print("RELEASE_VERSIONING_SELFTEST %s" % ("PASS" if fails == 0 else "FAIL"))
        return 1 if fails else 0
    errs = check_repo()
    for e in errs:
        print("FAIL: " + e)
    print("RELEASE_VERSIONING_CHECK %s (%d problems)" % ("PASS" if not errs else "FAIL", len(errs)))
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
