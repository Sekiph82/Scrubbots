"""Factory dashboard server: static files + owner answers.

python factory/server.py  ->  http://127.0.0.1:8765/dashboard.html

GET  /questions  open lines under "## Questions for Şekip" in origin/main TASKS.md
POST /answer     {"question": "...", "answer": "..."} -> appended to factory/answers.md
The factory loop moves answers.md entries into TASKS.md at the start of each job.
"""
import datetime
import functools
import http.server
import json
import pathlib
import subprocess

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
ANSWERS = HERE / "answers.md"


def parse_questions(text: str) -> list[str]:
    out, inside = [], False
    for line in text.splitlines():
        if line.startswith("## "):
            inside = line.startswith("## Questions for")
        elif inside and line.startswith("- "):
            out.append(line[2:].strip())
    return out


def questions():
    return parse_questions(subprocess.run(["git", "-C", str(REPO), "show", "origin/main:TASKS.md"],
                                          capture_output=True, encoding="utf-8").stdout)


class Handler(http.server.SimpleHTTPRequestHandler):
    def send_json(self, obj, code=200):
        body = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/questions":
            answers = ANSWERS.read_text(encoding="utf-8") if ANSWERS.exists() else ""
            return self.send_json({"questions": questions(), "answers": answers})
        super().do_GET()

    def do_POST(self):
        if self.path != "/answer":
            return self.send_error(404)
        n = int(self.headers.get("Content-Length", 0))
        if n > 20000:
            return self.send_error(413)
        try:
            data = json.loads(self.rfile.read(n) or b"{}")
        except ValueError:
            data = None
        if not isinstance(data, dict):
            return self.send_error(400, "JSON object required")
        q = " ".join(str(data.get("question", "")).split())
        a = " ".join(str(data.get("answer", "")).split())
        if not q or not a:
            return self.send_error(400, "question and answer required")
        stamp = datetime.datetime.now().isoformat(timespec="minutes")
        with ANSWERS.open("a", encoding="utf-8") as f:
            f.write(f"- [{stamp}] Q: {q}\n  A: {a}\n")
        self.send_json({"ok": True})


if __name__ == "__main__":
    # localhost only: the answer endpoint writes files
    http.server.ThreadingHTTPServer(
        ("127.0.0.1", 8765), functools.partial(Handler, directory=str(HERE))).serve_forever()
