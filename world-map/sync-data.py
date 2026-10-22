"""Run after editing world-data.json to update the standalone HTML."""
import json, pathlib, re
root = pathlib.Path(__file__).resolve().parent
data = json.loads((root / "world-data.json").read_text())
p = root / "index.html"
s = p.read_text()
s, count = re.subn(r"const DATA=.*?;\nconst svg=", lambda _: "const DATA=" + json.dumps(data, ensure_ascii=False) + ";\nconst svg=", s, count=1, flags=re.S)
assert count == 1, "DATA block missing"
p.write_text(s)
