#!/usr/bin/env python3
"""Run the CI headless Godot suites locally with the CI PASS/FAIL rule.

The suite list and the exact-summary guards are read from the `validate` job of
.github/workflows/android-family-first10.yml (the single source of truth).
See docs/TESTING_CONVENTIONS.md.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys

WORKFLOW = ".github/workflows/android-family-first10.yml"
DIAG = re.compile(r"^(ERROR: )?(SCRIPT ERROR|Parse Error|Failed to load script)")
# Mirrors the workflow's INJECTED exception: only this suite's documented plugin-throw line is tolerated.
INJECTED_SUITE = "m43_c005f_phase4_terminal_home_micro"
INJECTED = "SCRIPT ERROR: Invalid call. Nonexistent function 'explode' in base 'Nil'."
WINGET_GODOT = os.path.join(
    os.environ.get("LOCALAPPDATA", ""), "Microsoft", "WinGet", "Packages",
    "GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe", "Godot_v4.7.2-stable_win64_console.exe")


def read_workflow(path):
    with open(os.path.join(path, WORKFLOW), encoding="utf-8") as f:
        text = f.read()
    m = re.search(r"for s in (.*?); do", text.replace("\\\n", " "))
    if not m:
        sys.exit("error: cannot find the 'for s in ...; do' suite loop in " + WORKFLOW)
    suites = m.group(1).split()
    guards = {s: line for line, s in re.findall(r"grep -qxF '([^']*)' validate_logs/(\w+)\.log", text)}
    return suites, guards


def evaluate(suite, exit_code, log, guard=None):
    """Return (status, diag, last) using the workflow's PASS/FAIL rule."""
    lines = log.splitlines()
    diag = sum(1 for l in lines if DIAG.search(l) and not (suite == INJECTED_SUITE and l == INJECTED))
    hits = [l for l in lines if re.search("PASS|FAIL|RESULT", l)]
    last = hits[-1] if hits else ""
    ok = exit_code == 0 and diag == 0 and "PASS" in last and "FAIL" not in last
    if guard is not None and guard not in lines:
        ok = False
    return ("PASS" if ok else "FAIL"), diag, last


def selftest():
    good = "x\nFoo evidence: PASS (2/2 cases, 0 fail)\n"
    guard = "Foo evidence: PASS (2/2 cases, 0 fail)"
    assert evaluate("a", 0, good, guard)[0] == "PASS"
    assert evaluate("a", 1, good, guard)[0] == "FAIL"
    assert evaluate("a", 0, "SCRIPT ERROR: boom\n" + good)[0:2] == ("FAIL", 1)
    assert evaluate("a", 0, "ERROR: Parse Error: x\n" + good)[0] == "FAIL"
    assert evaluate("a", 0, good + "RESULT done\n")[0] == "FAIL"
    assert evaluate("a", 0, good + "case 3 FAIL\n")[0] == "FAIL"
    assert evaluate("a", 0, "nothing\n")[0] == "FAIL"
    assert evaluate("a", 0, "Foo evidence: PASS (1/2 cases, 0 fail)\n", guard)[0] == "FAIL"
    assert evaluate("a", 0, "  " + guard + "\n", guard)[0] == "FAIL"  # whole-line match only
    assert evaluate(INJECTED_SUITE, 0, INJECTED + "\n" + good)[0:2] == ("PASS", 0)
    assert evaluate("a", 0, INJECTED + "\n" + good)[0] == "FAIL"
    assert evaluate(INJECTED_SUITE, 0, "SCRIPT ERROR: other\n" + good)[0] == "FAIL"
    print("selftest PASS")


def find_godot():
    for cand in (os.environ.get("GODOT"), shutil.which("godot_console"), shutil.which("godot"), WINGET_GODOT):
        if cand and os.path.isfile(cand):
            return cand
    return None


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--path", default=root, help="checkout to test (default: this repo)")
    ap.add_argument("--timeout", type=int, default=1500, help="seconds per suite (CI: 1500)")
    ap.add_argument("--list", action="store_true", help="print the workflow suites and exit")
    ap.add_argument("--selftest", action="store_true", help="check the PASS/FAIL rule on fake logs")
    ap.add_argument("suites", nargs="*", help="suite names without .gd (default: all)")
    args = ap.parse_args()
    if args.selftest:
        selftest()
        return 0
    path = os.path.abspath(args.path)
    suites, guards = read_workflow(path)
    if args.list:
        print("\n".join(suites))
        return 0
    unknown = [s for s in args.suites if s not in suites]
    if unknown:
        print("error: not in the workflow suite list: " + " ".join(unknown), file=sys.stderr)
        return 2
    selected = args.suites or suites
    godot = find_godot()
    if not godot:
        print("error: Godot not found; set GODOT (see AGENTS.md 'Local Godot')", file=sys.stderr)
        return 2
    logs = os.path.join(path, "validate_logs")
    os.makedirs(logs, exist_ok=True)
    passed = 0
    for s in selected:
        if not os.path.isfile(os.path.join(path, "tests", s + ".gd")):
            print(f"{s} MISSING tests/{s}.gd status=FAIL", flush=True)
            continue
        try:
            p = subprocess.run([godot, "--headless", "--path", path, "-s", f"res://tests/{s}.gd"],
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=args.timeout)
            ec, out = p.returncode, p.stdout
        except subprocess.TimeoutExpired as e:
            ec, out = 124, e.stdout or b""
        log = out.decode("utf-8", "replace")
        with open(os.path.join(logs, s + ".log"), "w", encoding="utf-8", newline="") as f:
            f.write(log)
        st, diag, last = evaluate(s, ec, log, guards.get(s))
        passed += st == "PASS"
        print(f"{s} status={st} exit={ec} diag={diag} | {last}", flush=True)
    agg = "PASS" if passed == len(selected) else "FAIL"
    print(f"aggregate={agg} ({passed}/{len(selected)})")
    return 0 if agg == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
