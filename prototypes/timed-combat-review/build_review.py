"""Embed real recorded results so index.html works when opened via file://."""
import csv
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
results = json.loads((HERE / 'results.json').read_text())
replays = json.loads((HERE / 'replays.json').read_text())
# Keep full outcomes reviewable without hundreds of thousands of pretty-printed lines.
header = json.dumps({k: v for k, v in results.items() if k != 'rows'}, ensure_ascii=False, indent=2)
compact_rows = ',\n'.join(json.dumps(row, ensure_ascii=False, separators=(',', ':')) for row in results['rows'])
(HERE / 'results.json').write_text(header[:-2] + ',\n  "rows": [\n' + compact_rows + '\n  ]\n}\n')
payload = replays | {'summary': results['primary_summary'], 'arts': [key.split('/')[1] for key in results['primary_summary'] if key.startswith('single/') and key.endswith('/main_spam')]}
template = (HERE / 'replay.template.html').read_text()
embedded = json.dumps(payload, ensure_ascii=False, separators=(',', ':')).replace('<', '\\u003c')
(HERE / 'index.html').write_text(template.replace('__DATA__', embedded))
fields = ['group', 'art', 'policy', 'start', 'enemy_style', 'reaction', 'seed', 'winner', 'time', 'hero_hp', 'boss_hp', 'attack_share', 'unique_attacks', 'longest_attack_streak', 'hero_hits', 'hero_misses', 'boss_misses', 'guard_saved', 'move_qi_recovered']
with (HERE / 'results.csv').open('w', encoding='utf-8-sig', newline='') as file:
    writer = csv.DictWriter(file, fieldnames=fields, extrasaction='ignore', lineterminator='\n')
    writer.writeheader(); writer.writerows(results['rows'])
print('Built offline replay and CSV from', len(results['rows']), 'recorded cases')

policies = [('main_spam', '주력 우선'), ('efficient', '공격 효율'), ('reactive', '이동·방어 대응'), ('read_counter', '관망 후 대응')]
labels = replays['labels']
def cell(s):
    return f"{s['wins']} / {s['losses']} / {s['draws']} / {s['timeouts']}"
table = ['| 하급 무공 | 주력 우선 | 공격 효율 | 이동·방어 대응 | 관망 후 대응 | 관망형 최다 공격 비중 중앙값 |',
         '|---|---:|---:|---:|---:|---:|']
for art in payload['arts']:
    sums = [results['primary_summary'][f'single/{art}/{p}'] for p, _ in policies]
    table.append('| ' + labels[art] + ' | ' + ' | '.join(cell(s) for s in sums) + f" | {sums[-1]['median_top_attack_share']:.0%} |")
diagnostics = ['| 구성 | 표본 | 승/패/무/초과 | 시간 중앙값 | 최다 공격 비중 중앙값 |', '|---|---:|---:|---:|---:|']
for group, art, policy in [('dual', 'cheongpung', 'reactive'), ('dual', 'danseok', 'reactive'), ('dual', 'gwanpung', 'reactive'),
                           ('hp_double', 'cheongpung', 'efficient'), ('hp_double', 'danseok', 'efficient'), ('hp_double', 'gwanpung', 'efficient'),
                           ('clock', 'cheongpung', 'reactive'), ('clock', 'gwanpung', 'reactive')]:
    s = results['summary'][f'{group}/{art}/{policy}']
    group_name = {'dual': '같은 무기 하급2종', 'hp_double': '가상 체력2배', 'clock': '시간10당 내기 회복'}[group]
    diagnostics.append(f"| {group_name} · {labels[art]} · {dict(policies)[policy]} | {s['cases']} | {cell(s)} | {s['median_time']} | {s['median_top_attack_share']:.0%} |")
totals = {key: sum(r['winner'] == key for r in results['rows']) for key in ['hero', 'boss', 'draw', 'timeout']}
report = f'''# 장사 우두머리 · 시간제 전투 검토

2026-10-30. **본게임 미적용, 별도 Python 검토 엔진의 실제 계산 결과.** 준비·출수·회수와7×5 위치·양측 독립 행동을 계산했다. 현재 Godot 전투나 사람의 플레이를 실행한 결과는 아니다.

판단: **클리어는 가능하지만, 이번 시간 배정만으로 핵심 무공 반복이 해결됐다고 볼 수 없다.** 특히2회 명중으로 끝나는 도/창/맨손에서는 맞교환하며 같은 무공을 반복하는 방침이 강하다. 검의 접근·후퇴가 일부 역할을 만들지만, 삼재검법이 접전의 반복 주력이 되는 사례도 나온다. 재미의 향상은 이 자료만으로 검증하지 못했다.

## 입력 조건

- 우두머리: 근력16/기민16/근골12/내공12/오성14, 합계70, 체력328, 후배도. 기존 회풍도법에 하급 단석도법을 임시 추가하고 기본공격·기본방어도 사용한다. 두 하급 무공 모두 해당 적의 학습 조건을 만족한다.
- 도원: 장사 의뢰9종의1,250문/오성18을 받은 뒤의 구성.0장 귀물 보수는 필요하지 않다. 영약6알·하급 무공1종·300문 무기면1,250문이다. 맨손은 무기값300문이 남으며 이를 추가 성장에 쓰지는 않았다.
- 일반 분배: 근력18/기민18/근골20/내공20/오성28, 총합104(이류), 체력374. 웅력환1·경신환1·고골환2·양기단2로 실제 도달한다.
- 운기장법만 학습 조건을 맞춰 양기단6알:16/16/16/28/28, 총합104, 체력348. 다른 무기와 같은 능력치의 순수 무기 비교가 아니다.
- 편성4칸 유지: 기본공격·기본방어·선택한 하급1종, 검은 삼재검법도 편성. 이동은 별도다. 각 무공 학습 가능/소비 내기/장비 조건을 검사한다.
- 피해·체력·장비는 현재 데이터와 공통식을 옮겨 계산했다. 기민의 새 시간 보정은 아직 미정이므로 이번에는 미반영이다.

## 시간표와 판정

| 행동 | 준비 | 출수/유지 | 회수 | 총시간 |
|---|---:|---:|---:|---:|
| 이동 | 3 | 5 | 2 | 10 |
| 기본방어 | 2 | 6 | 2 | 10 |
| 기본공격 | 3 | 2 | 5 | 10 |
| 삼재검법 | 5 | 2 | 5 | 12 |
| 청풍검법 | 6 | 4 | 5 | 15 |
| 유수검법 | 5 | 3 | 8 | 16 |
| 단석도법 | 9 | 3 | 9 | 21 |
| 회풍도법 | 10 | 5 | 10 | 25 |
| 관풍창법 | 7 | 2 | 8 | 17 |
| 연환창법 | 9 | 5 | 8 | 22 |
| 철산권법 | 6 | 3 | 8 | 17 |
| 운기장법 | 8 | 4 | 8 | 20 |

공격은 출수 시작에1회 판정한다. 청풍만 출수 첫2에 전진한 뒤 판정한다. 유수는 판정 후 출수 끝에 후퇴한다. 기본방어는 준비 완료부터 출수 끝 직전까지20%, 검은 출수부터 회수 종료 직전까지20% 감소한다. 일반 피격 경직/회수 취소는 없으며 같은 시각의 양쪽 공격은 함께 처리한다. 공격 방향은 시작 때 고정한다. 상세한 추가 가정은 [실험 README](../../prototypes/timed-combat-review/README.md)를 따른다.

## 비교 방식

- 주력 우선: 선택한 하급을 가능한 한 반복. 사거리 밖에서는 접근, 내기가 부족하거나 전진 경로가 막히면 가능한 기본공격으로 대체한다.
- 공격 효율: 현재 맞힐 수 있는 공격의 위력/총시간이 높은 것을 선택. 능동 방어·회피는 하지 않는다.
- 대응형: 보이는 공격 준비에 이동/방어/유수 후퇴를 고려하고, 출수 뒤에는 공격을 선택한다. 늦어서 성립하지 않을 방어는 고르지 않도록 동작별 대표 시간을 추정한다. 상대의 정확한 미래 명중 시각/내기/새 입력을 읽지 않는다. 최적 정책은 아니다.
- 관망형: 적이 아직 공격을 시작하지 않았고 가까이 있다면 시간2만큼 기다린 뒤 위 대응을 한다. 대기로 내기를 회복하지 않는다. 동시 준비 후 맞교환만 비교하지 않기 위한 별도 정책이다. 적 정책에는 같은 관망/허초 전략이 없으므로 관망형의 성적을 최종 게임 난이도로 해석하지 않는다.
- 적은 공세형·대응형·가중 무작위형3정책. 플레이어와 별도 난수열을 사용한다. 고정된 대본을 순서대로 재생하지 않는다.
- 대표표는 시작 위치6 × 적 정책3 × 시드3 = 구성당54조건. 관찰 지연3 고정. 별도로 관찰 지연0/6, 기본공격만, 같은 무기 하급2종, 내기 회복 변경, 양측 기본방어 선택 제외, 가상 체력2배를 검사했다.
- 전체 {len(results['rows']):,}시행: 도원 승{totals['hero']:,}/패{totals['boss']:,}/동시 사망{totals['draw']:,}/시간초과{totals['timeout']:,}. 서로 다른 조건을 합한 숫자이므로 게임의 승률로 해석하지 않는다. 동일 정책에 무관한 감도 조건이 반복되는 경우도 있다.

## 대표 결과

각 칸은 **승리 / 패배 / 동시 사망 / T=800 시간초과**. 최다 공격 비중은 기본공격을 포함한 공격 선택만을 분모로 하며 이동/방어/대기는 제외한다.

{chr(10).join(table)}

공격 종류가 여러 개라는 것과 전술이 다양하다는 것은 다르다. 검의2종 사용도 접근용 청풍1회 후 삼재 반복인 사례가 있다. 비검 무공1종 구성의100%는 다른 공격 무공을 편성하지 않은 영향도 있으므로, 아래2종 편성을 추가 확인했다.

## 실제 기록: 관풍창법 반복

첫 배치/공세형/시드0/관찰 지연3. 도원374, 우두머리328에서 시작한다.

| T | 도원 | 우두머리 | 결과 |
|---:|---|---|---|
| 0 | 접근 시작 | 접근 시작 | 각각T=8 도착/T=10 행동 가능 |
| 10 | 관풍 준비, 명중17/종료27 | 단석 준비, 명중19/종료31 | 각자 독립적으로 선택 |
| 17 | 관풍 적중 | 단석 준비 중 | 우두머리328→111 |
| 19 | 회수 중 | 단석 적중 | 도원374→237 |
| 27 | 관풍 다시 시작, 명중34 | 아직 회수 중 | 별도 방어나 회피 없이 반복 |
| 31 | 관풍 준비 중 | 이동 시작, 도착39 | 내기가16이어서 단석 비용20 부족 |
| 34 | 관풍 적중 | 이동 도착 전 | 우두머리0, 전투 종료 |

이 사례에서는 이동으로 얻은 내기까지 포함해 관풍2회가 성립한다. 단석도 같은 조건에서2회로T=40에 끝난다. 이는 정수 시간 규칙을 넣었다고 자동으로 다양한 선택이 유리해지는 것은 아니라는 반례다.

## 추가 원인 분리 검사

{chr(10).join(diagnostics)}

- 같은 무기2종도4칸 제한을 유지한다. 검은 삼재를 빼고 청풍/유수를 넣는 변경이며, 도·창은 빈칸에 다른 하급을 넣는다. 추가350문은0장 귀물 보수500문을 받은 경우 지출 가능하다. 스탯을 더 올리지는 않았다. 맨손2종은 학습 조건 때문에 분배도 바뀌므로 순수 기술 추가 비교로 해석하지 않는다.
- 체력2배는 능력치는 그대로 두고656으로 만든 가상 진단이다. 원래 체력식을 지키는 본표와 구별한다. 길이를 늘리는 것만으로는 별도 무공의 역할을 만들 수 없다.
- 시간10당 내기 회복은 양쪽 모두에 적용한 별도 가정이다. 한쪽만 바꾼 인과 검사가 아니며, 이 결과를 근거로 즉시 채택하지 않는다.

## 확인된 문제와 권고

1. **전투가2회 명중으로 끝나는 구성이 많다.** 적의 회수에 맞춰 여러 수를 엮기 전에 맞교환으로 승리한다. 적 체력만 늘리기보다3~5번의 의미 있는 공방 동안 방어·사거리·반격의 필요가 생기는지 확인할 필요가 있다. 구체 체력 상향은 미확정이다.
2. **기본방어의 이득이 작다.** 이 구성에서 적 단석은 정련검 도원에게133,20%방어 시106이다. 줄이는27과 그동안 포기한 공격/위치를 비교해야 한다. 올바른 방어를 선택하면 다음 공세의 유리한 위치나 빈틈을 얻는 방향을 검토할 수 있다. 이번에 방어율은 바꾸지 않았다.
3. **시간만 달라도 최적 반복은 남는다.** 삼재가 짧은 시간에 충분한 피해를 내면 접전에서는 계속 삼재를 쓰게 된다. 파훼/대응/거리 유지처럼 다른 기술이 해결하는 상황을 적에게 마련해야 한다. 강제 순환이나 반복 벌점은 넣지 않았다.
4. **기존 행동당 내기 회복은 난사를 허용한다.** 내공20이면 삼재10·청풍12·유수14·단석20·철산20은 완료할 때 내기가 유지되거나 늘어난다. 관풍도 이동으로40을 만든 뒤 비용27을 두 번 낼 수 있다. 회복 주기를 다시 설계해야 한다.
5. **추격 교착이 남는다.** 일부 시작 배치에서 자동 정책이 서로 따라 움직이며 T=800까지 공격하지 못한다. 시간초과를 패배에서 제외하거나 성공으로 처리하지 않았다. 이는 현 검토 AI의 경로/대치 해소 한계이며, 사람이 반드시 같은 교착에 빠진다는 뜻은 아니다. 이동만 반복해 내기500을 만드는 문제도 함께 관찰된다.
6. **관망도 자동 정답은 아니다.** 관망형은 방어 횟수와 감소시킨 피해가 늘어도 공격 기회를 포기해 일부 구성의 승리 수/잔여 체력이 줄었다. 이는 기다리면 재미가 없다는 증거가 아니라, 이번 정책과20% 방어만으로 안전한 반격의 대가를 충분히 제공하지 못했다는 신호다. 최적 반격 정책을 증명한 검사는 아니다.

재미에 대한 판단은 **잠재력은 있지만 현재안만으로 개선을 입증하지 못함**이다. 다음 작은 실험에서는 적의 방어를 깨는 수단·회피 후 반격 기회·거리별 대응을 추가하고, 사람이 직접 판단할 수 있는 조작형 전투로 확인하는 편이 낫다. 아직 본게임 전투 교체/수치 확정은 하지 않았다.

## 재현·자료

- [오프라인 시간별 재생기](../../prototypes/timed-combat-review/index.html): 다운로드 후 브라우저로 연다. 준비/출수/회수, 위치, 체력/내기, 실제 사건을T단위로 확인한다.
- [계산 코드](../../prototypes/timed-combat-review/simulate.py) · [전체 CSV](../../prototypes/timed-combat-review/results.csv) · [전체 JSON](../../prototypes/timed-combat-review/results.json)
- [검사 코드](../../prototypes/timed-combat-review/test_simulate.py): 시간 경계·이동/전진/후퇴·학습/가격·방어·동시 명중·공용 공식·정보 제한·대기 내기 회복 금지 검사.

이 결과는14개 기본 동작 검사를 통과한 별도 엔진의 결과다. Godot 통합·조작감·연출·사람이 느끼는 재미까지 통과했다는 뜻은 아니다.
'''
(HERE.parents[1] / 'docs/reviews/timed-combat-changsha.md').write_text(report)
print('Built review report with complete loss/draw/timeout accounting')
