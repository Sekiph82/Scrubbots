#!/usr/bin/env python3
"""SB-M59-009 clean-clone check (stdlib only; run with python -I).

  python -I tools/clean_clone_check.py [--godot EXE] [--work DIR] [--keep] [suite ...]

Clones the COMMITTED HEAD of this checkout (git clone --depth 1; nothing untracked or
modified comes along: no .godot cache, no owner-local addon such as addons/godot_ai, no local
project.godot edits) into a temporary directory, imports it headless (exit 0 and no script
diagnostics required), restores project.godot like CI, then runs the smoke suites through the
clone's own tools/run_suites.py (CI PASS/FAIL rule). The source checkout is only read by
git clone; the temporary clone is deleted afterwards unless --keep.
The clone skips the same trees as the CI validate checkout (session evidence, dev-art).
Last line: CLEAN_CLONE_CHECK PASS|FAIL; exit 0 only on PASS.
"""
import argparse
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Same as the validate job checkout in .github/workflows/android-family-first10.yml.
SPARSE = ["/*", "!/coordination/sessions/", "!/assets/art/references/", "!/assets/ui/candidates/", "!/assets/ui/generated/"]
# Settings boot + version label, Results on the real app root, GameFeelFlow + Spark unlock feel.
SMOKE = ["m59_app_version", "m43_c001a_results_foundation", "m43_c005f_phase6_unlock_feel"]
DIAG = re.compile(r"^(ERROR: )?(SCRIPT ERROR|Parse Error|Failed to load script)", re.M)
WINGET_GODOT = os.path.join(
    os.environ.get("LOCALAPPDATA", ""), "Microsoft", "WinGet", "Packages",
    "GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe", "Godot_v4.7.2-stable_win64_console.exe")


def git(*args, cwd=None):
    print("$ git " + " ".join(args), flush=True)
    subprocess.run(["git", *args], cwd=cwd, check=True)


def rmtree(path):
    def force(func, p, _exc):  # git objects are read-only on Windows
        os.chmod(p, stat.S_IWRITE)
        func(p)
    shutil.rmtree(path, onexc=force) if sys.version_info >= (3, 12) else shutil.rmtree(path, onerror=force)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--godot", default=os.environ.get("GODOT") or WINGET_GODOT)
    ap.add_argument("--work", help="empty or new directory for the clone (default: a new temp dir)")
    ap.add_argument("--keep", action="store_true", help="keep the clone afterwards")
    ap.add_argument("suites", nargs="*", default=SMOKE)
    args = ap.parse_args()
    if not os.path.isfile(args.godot):
        print("error: Godot not found: %s (set GODOT or --godot)" % args.godot, file=sys.stderr)
        return 2
    work = os.path.abspath(args.work) if args.work else tempfile.mkdtemp(prefix="scrubbots-clean-clone-")
    if os.path.commonpath([work, ROOT]) == ROOT:
        print("error: --work must be outside the source checkout", file=sys.stderr)
        return 2
    os.makedirs(work, exist_ok=True)
    if os.listdir(work):
        print("error: --work is not empty: %s" % work, file=sys.stderr)
        return 2
    repo = os.path.join(work, "repo")
    ok = False
    try:
        git("clone", "--quiet", "--depth", "1", "--no-checkout", Path(ROOT).as_uri(), repo)
        git("sparse-checkout", "set", "--no-cone", *SPARSE, cwd=repo)
        git("checkout", "--quiet", "HEAD", cwd=repo)
        sha = subprocess.run(["git", "rev-parse", "HEAD"], cwd=repo, capture_output=True, text=True, check=True).stdout.strip()
        print("clean clone of %s at %s" % (sha, repo), flush=True)
        imp = subprocess.run([args.godot, "--headless", "--path", repo, "--import"],
                             stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=3600)
        log = imp.stdout.decode("utf-8", "replace")
        with open(os.path.join(work, "import.log"), "w", encoding="utf-8") as f:
            f.write(log)
        diag = DIAG.findall(log)
        print("import exit=%d script_diag=%d" % (imp.returncode, len(diag)), flush=True)
        for line in log.splitlines():
            if DIAG.search(line):
                print("  " + line)
        git("checkout", "--", "project.godot", cwd=repo)   # the import may rewrite it; test the tracked file
        if imp.returncode == 0 and not diag:
            env = dict(os.environ, GODOT=args.godot)
            ok = subprocess.run([sys.executable, "-I", os.path.join(repo, "tools", "run_suites.py"), "--path", repo, *args.suites],
                                env=env).returncode == 0
    finally:
        if args.keep:
            print("kept: " + work)
        else:
            rmtree(work)
    print("CLEAN_CLONE_CHECK %s" % ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
