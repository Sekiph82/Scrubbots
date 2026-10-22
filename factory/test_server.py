"""Self-check for server.parse_questions: python factory/test_server.py"""
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import server  # noqa: E402

SAMPLE = """# TASKS
- before
## Questions for Şekip
<!-- one line per question -->
- SB-1 — first?
not a question
-  SB-2 — second?\t
## Project Status
- after
"""

assert server.parse_questions(SAMPLE) == ["SB-1 — first?", "SB-2 — second?"]
assert all("<!--" not in q for q in server.parse_questions(SAMPLE))
assert server.parse_questions("# T\n- a\n## Project Status\n- b\n") == []
assert server.parse_questions("## Questions for Şekip\n<!-- c -->\n\n## Next\n- x\n") == []

real = server.parse_questions((HERE.parent / "TASKS.md").read_text(encoding="utf-8"))
assert isinstance(real, list) and all(real), real

print("PASS test_server")
