"""Export the approved Markdown speech into runtime scene data (stdlib only)."""
import json
import re
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'docs/story/chapter-00-dialogues.md').read_text()
chunks = re.split(r'^#{2,4} (.+)\n', source, flags=re.M)
sections = list(zip(chunks[1::2], chunks[2::2]))
start = next(i for i, (name, _) in enumerate(sections) if name.startswith('1. 나루'))
end = next(i for i, (name, _) in enumerate(sections) if name.startswith('구현 시'))
ids = ['opening', 'captain', 'sailor', 'apothecary', 'clerk', 'boarding', 'deck_heading', 'deck', 'victory', 'drowning', 'choice_notes', 'treasure_escape', 'treasure_shelter', 'rescue_escape', 'rescue_shelter', 'dissolution', 'treasure_documents', 'rescue_documents', 'treasure_delivery', 'rescue_delivery', 'departure_heading', 'treasure_night', 'rescue_farewell', 'arrival', 'treasure_arrival', 'rescue_arrival', 'free_roam']
actors = {'주인공':'hero', '서문길':'captain', '허만복':'sailor', '진소옥':'apothecary', '육승':'clerk', '흑린채 수적':'pirate', '수령인':'recipient'}
def speech(body):
    result = []
    for match in re.finditer(r'^\*\*(.+?):\*\* (.+)$', body, re.M):
        who, text = match.groups()
        name, _, mode = who.partition(', ')
        result.append([actors[name], text, mode])
    return result
assert len(sections[start:end]) == len(ids)
result = {}
for id, (heading, body) in zip(ids, sections[start:end]):
    if id.endswith('_heading') or id == 'choice_notes':
        continue
    result[id] = {'title': heading, 'lines': speech(body)}
    if id == 'treasure_delivery':
        before, after = body.split('*보수 **3,000문**', 1)
        result[id]['lines'] = speech(before)
        result['treasure_paid'] = {'title':'인도 확인 · 보수 3,000문 수령', 'lines':speech(after)}
# The final conversation now takes place at Changsha's port, per the latest request.
titles = {
    'opening':'나루의 아침', 'captain':'첫 표행', 'sailor':'배 위의 일상',
    'apothecary':'약재 상자', 'clerk':'인도 서류', 'boarding':'맡긴 물건의 무게',
    'deck':'흑린채의 습격', 'victory':'부서지는 갑판', 'drowning':'한쪽으로만 뻗을 수 있는 손',
    'treasure_escape':'대답 없는 이름', 'treasure_shelter':'기슭 · 돌아오지 않은 사람',
    'rescue_escape':'살아남은 사람의 무게', 'rescue_shelter':'기슭 · 잃어버린 것',
    'dissolution':'돌아갈 곳이 사라지다', 'treasure_documents':'마지막 인도 서류',
    'rescue_documents':'전해야 할 소식', 'treasure_delivery':'장사 항구 · 마지막 인도',
    'treasure_paid':'장사 항구 · 보수 삼천 문', 'rescue_delivery':'장사 항구 · 실패 보고',
    'treasure_night':'장사 항구 · 남겨진 무게', 'rescue_farewell':'장사 항구 · 다음을 기약하며',
    'arrival':'장사 항구 · 각자의 길', 'treasure_arrival':'장사 항구 · 받은 것과 잃은 것',
    'rescue_arrival':'장사 항구 · 남은 사람', 'free_roam':'장사 항구 · 새로운 길',
}
for scene_id, title in titles.items():
    result[scene_id]['title'] = title
result['free_roam']['lines'] = [['hero', '장사 항구인가. 우선 시내로 들어가 보자. 맡을 만한 일거리라도 있겠지.', '']]
(ROOT / 'godot/data/prologue_dialogues.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
print(f'Exported {len(result)} scenes, {sum(len(s["lines"]) for s in result.values())} dialogue lines')
