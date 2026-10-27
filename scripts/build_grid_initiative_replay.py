"""Embed the Godot-generated results so the replay works as a standalone local HTML file."""
import json
import re
from pathlib import Path
root = Path(__file__).resolve().parents[1]
folder = root / 'prototypes/grid-initiative-simulation'
data = json.loads((folder / 'data.json').read_text())
payload = json.dumps(data, ensure_ascii=False, separators=(',', ':')).replace('</', '<\\/')
page = folder / 'index.html'
html = page.read_text()
html, count = re.subn(r'(<script id="simulation-data" type="application/json">).*?(</script>)', lambda m: m[1] + payload + m[2], html, count=1, flags=re.S)
assert count == 1
page.write_text(html)
print('GRID_REPLAY_BUILD: PASS')
