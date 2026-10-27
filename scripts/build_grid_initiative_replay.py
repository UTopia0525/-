"""Build a self-contained, editable browser simulator from source and Godot catalogues."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
folder = root / 'prototypes/grid-initiative-simulation'
data = json.loads((folder / 'data.json').read_text(encoding="utf-8"))
data['catalog'] = json.loads((folder / 'catalog.json').read_text(encoding="utf-8"))
payload = json.dumps(data, ensure_ascii=False, separators=(',', ':')).replace('</', '<\\/')
html = (folder / 'editor.template.html').read_text(encoding="utf-8")
for token, content in {
    '__CSS__': (folder / 'editor.css').read_text(encoding="utf-8"),
    '__DATA__': payload,
    '__ENGINE__': (folder / 'engine.js').read_text(encoding="utf-8").replace('</script', '<\\/script'),
    '__UI__': (folder / 'editor.js').read_text(encoding="utf-8").replace('</script', '<\\/script'),
}.items():
    assert html.count(token) == 1
    html = html.replace(token, content)
(folder / 'index.html').write_text(html, encoding='utf-8')
print('GRID_EDITOR_BUILD: PASS / self-contained HTML')
