#!/usr/bin/env python3
"""Run an exported Godot Web build in real headless Chrome and capture runtime proof.

MAINT-HOME-EXPORT-ASSET-GATE-C001. Starts headless Chrome with the DevTools protocol,
loads <url>, records every console message, waits for the opt-in HOME_ASSET_DIAG line
(emitted by HomeScreen only when the build runs with --home-asset-diagnostics), then
waits for Home to be on screen and saves a screenshot.

    python tools/web_export_runtime_probe.py <url> <out_dir> [--chrome PATH]

Writes <out_dir>/console.log, home_asset_diag.json, home_screenshot.png. Exit 0 only when
the diagnostic line was seen.
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import json
import subprocess
import sys
import tempfile
import time
import urllib.request
from pathlib import Path

import websockets

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"


def devtools_ws(port: int, timeout: float = 30.0) -> str:
    end = time.time() + timeout
    while time.time() < end:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{port}/json/list") as r:
                for t in json.load(r):
                    if t.get("type") == "page":
                        return t["webSocketDebuggerUrl"]
        except OSError:
            pass
        time.sleep(0.5)
    raise RuntimeError("Chrome DevTools endpoint not reachable")


async def probe(ws_url: str, url: str, out: Path, diag_timeout: float, settle: float) -> bool:
    lines: list[str] = []
    diag: dict | None = None
    async with websockets.connect(ws_url, max_size=64 * 2**20) as ws:
        seq = 0

        async def send(method: str, params: dict | None = None) -> int:
            nonlocal seq
            seq += 1
            await ws.send(json.dumps({"id": seq, "method": method, "params": params or {}}))
            return seq

        await send("Runtime.enable")
        await send("Log.enable")
        await send("Page.enable")
        await send("Emulation.setDeviceMetricsOverride", {"width": 430, "height": 860, "deviceScaleFactor": 2, "mobile": True})
        await send("Page.navigate", {"url": url})
        t0 = time.time()
        shot_id = None
        deadline = t0 + diag_timeout
        shoot_at = None
        while True:
            now = time.time()
            if shot_id is None and shoot_at is not None and now >= shoot_at:
                shot_id = await send("Page.captureScreenshot", {"format": "png"})
            if shot_id is None and shoot_at is None and now > deadline:
                break
            try:
                msg = json.loads(await asyncio.wait_for(ws.recv(), timeout=1.0))
            except asyncio.TimeoutError:
                continue
            if msg.get("id") == shot_id and "result" in msg:
                (out / "home_screenshot.png").write_bytes(base64.b64decode(msg["result"]["data"]))
                break
            method = msg.get("method")
            if method == "Runtime.consoleAPICalled":
                text = " ".join(str(a.get("value", a.get("description", ""))) for a in msg["params"]["args"])
                lines.append(f"[{now - t0:7.2f}s] console.{msg['params']['type']}: {text}")
                if text.startswith("HOME_ASSET_DIAG ") and diag is None:
                    diag = json.loads(text[len("HOME_ASSET_DIAG "):])
                    shoot_at = time.time() + settle
            elif method == "Log.entryAdded":
                e = msg["params"]["entry"]
                lines.append(f"[{now - t0:7.2f}s] log.{e['level']}: {e.get('text', '')}")
            elif method == "Runtime.exceptionThrown":
                lines.append(f"[{now - t0:7.2f}s] exception: {msg['params']['exceptionDetails'].get('text')}")
    (out / "console.log").write_text("\n".join(lines) + "\n", encoding="utf-8")
    if diag is not None:
        (out / "home_asset_diag.json").write_text(json.dumps(diag, indent=2) + "\n", encoding="utf-8")
    return diag is not None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("url")
    ap.add_argument("out", type=Path)
    ap.add_argument("--chrome", default=CHROME)
    ap.add_argument("--port", type=int, default=9333)
    ap.add_argument("--diag-timeout", type=float, default=300.0)
    ap.add_argument("--settle", type=float, default=40.0, help="seconds after the diagnostic before the screenshot (opening video -> Home)")
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as profile:
        proc = subprocess.Popen([args.chrome, "--headless=new", f"--remote-debugging-port={args.port}",
                                 f"--user-data-dir={profile}", "--no-first-run", "--no-default-browser-check",
                                 "--enable-unsafe-swiftshader", "--autoplay-policy=no-user-gesture-required",
                                 "--window-size=430,860", "about:blank"],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            ok = asyncio.run(probe(devtools_ws(args.port), args.url, args.out, args.diag_timeout, args.settle))
        finally:
            proc.terminate()
            try:
                proc.wait(10)
            except subprocess.TimeoutExpired:
                proc.kill()
    print(f"WEB_RUNTIME_PROBE diag_seen={ok} out={args.out}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
