"""Produce a self-contained parameter explorer and a complete numerical review."""
import json
from pathlib import Path
import sweep

HERE=Path(__file__).resolve().parent
coarse=json.loads((HERE/'coarse-summary.json').read_text())
refined=json.loads((HERE/'refined-summary.json').read_text())
replays=json.loads((HERE/'replays.json').read_text())
payload=dict(coarse=coarse,refined=refined,replays=replays,labels=sweep.base.LABELS,
             configs=coarse['configs'],arts=sweep.ART_IDS,policies=sweep.POLICIES,policyLabels=sweep.POLICY_LABELS)
embedded=json.dumps(payload,ensure_ascii=False,separators=(',',':')).replace('<','\\u003c')
(HERE/'index.html').write_text((HERE/'explorer.template.html').read_text().replace('__DATA__',embedded))

def stat(config,art,policy):return refined['summary'][f'refined/{config}/{art}/{policy}']
def show(s):return f"{s['wins']}/{s['n']} · {s['median_hp']} · {s['median_time']}"

price_table=['| 무공 | 기존 | A | B | C | D | D·현재 장비 실제 소모 |', '|---|---:|---:|---:|---:|---:|---:|']
for art in ['samjae']+sweep.ART_IDS:
    hero,_=sweep.base.make_fighters('cheongpung' if art=='samjae' else art)
    values=[str(sweep.base.ARTS[art]['qi_cost'])]+[str(sweep.PRICE_TABLES[t][art]) for t in 'ABCD']
    price_table.append('| '+sweep.base.LABELS[art]+' | '+' | '.join(values)+f" | {sweep.Budget('D',80,table='D').cost(art,hero.weapon)} |")
comparison=['| 무공·D/상한80 | 기본공격 회복형 | 이동 회복형 | 방어 회복형 | 최대 축적형 |', '|---|---|---|---|---|']
for art in sweep.ART_IDS:
    comparison.append('| '+sweep.base.LABELS[art]+' | '+' | '.join(show(stat('D-cap80',art,p)) for p in sweep.POLICIES)+' |')
range_table=['| 비용안/상한 | 사용 가능 하급 | 이동 순환 이득 사례 | 이동형 승리 증가/감소 | 축적형이 이동형을 지배한 사례 |', '|---|---:|---:|---:|---:|']
for config in ['baseline','x3-cap120','B-cap70','B-cap75','B-cap80','C-cap80','D-cap70','D-cap75','D-cap80','D-cap85','D-cap90']:
    pairs=[v for k,v in refined['pairs'].items() if k.startswith(f'refined/{config}/')]
    vals={k:sum(v[k] for v in pairs) for k in ['n','useful_cycles','move_win_gain','move_win_loss','bank_dominates']}
    range_table.append(f"| {config} | {len(pairs)}/8 | {vals['useful_cycles']}/{vals['n']} | +{vals['move_win_gain']} / −{vals['move_win_loss']} | {vals['bank_dominates']} |")
chains=['| D/상한80 | 실제 소모 C | 회복 R | 꽉 채워 연속 사용 가능한 횟수 | 다음 연속2회가 가능해지는 상한 |', '|---|---:|---:|---:|---:|']
for art in ['samjae']+sweep.ART_IDS:
    e=next(e for e in refined['analytical'] if e['config']=='D-cap80' and e['art']==art)
    chains.append(f"| {sweep.base.LABELS[art]} | {e['cost']} | {e['recovery']} | {e['maximum_chain']} | {2*e['cost']-e['recovery']} |")

example=next(r for r in replays if r['config']=='D-cap80' and r['art']=='danseok' and r['policy']=='move_refill')
events=['| T | 도원의 행동 | 소비 전 → 소비 후 내기 |', '|---:|---|---:|']
for h in example['history'][0]:
    events.append(f"| {h['t']} | {sweep.base.LABELS[h['art']]} | {h['qi_before']} → {h['qi_after']} |")

total=coarse['cases']+refined['cases']
def total_pairs(config,field):
    return sum(v[field] for k,v in refined['pairs'].items() if k.startswith(f'refined/{config}/'))
report=f'''# 내기 비용·상한 변화와 이동/공격 순환 검토

2026-10-30. **본게임 미적용.** 회복은 기존처럼 모든 행동의 회수 종료 시 내공만큼, 대기는0이다. 비용은 시작 때 지불한다. 이동3/5/2와 기존 위력·범위·체력·장비를 유지했다. 양쪽 모두 같은 비용표·상한을 적용한다.

목표는 이동을 강제로 끼워 넣는 것이 아니라, 기본공격/방어로 회복하거나 한 번에 모아 난사하는 것보다 이동과 공격을 섞는 선택이 이득인 구간이 있는지 찾는 것이다. 재미/사람의 승률을 검증한 자료는 아니다.

검토 후보는 **D 비용표·상한70~80, 우선 비교점80**이다. 상한80에서 강한 도/창/권/장은 가득 모아도 유료 기술1회 후 회복 행동이 필요하고, 값싼 검은 짧은 연속 공격을 남긴다. 상한85는 내공28의 운기장법2연속을 자원상 허용하므로 이번 목표의 상한 후보에서 뒤로 둔다. 실제 연속 명중에는 사거리/밀침도 영향을 준다. D/80은 동일432조건에서 이동 순환 이득 기준을 {total_pairs('D-cap80','useful_cycles')}회 충족했고 기존 비용 대조는 {total_pairs('baseline','useful_cycles')}회였다. 그러나 이동형의 승리 증가/감소는 +{total_pairs('D-cap80','move_win_gain')}/−{total_pairs('D-cap80','move_win_loss')}로, 모든 구성에서 더 강한 전략이 됐다는 뜻은 아니다.

## 입력·실행 범위

- 이전 [시간제 검토](timed-combat-changsha.md)의 엔진을 수정하지 않고 상속한 별도 비용/상한 실험이다. 본게임 Godot 전투를 실행한 결과가 아니다.
- 장사 의뢰1250문으로 가능한 총합104·체력374 구성, 운기장법은 학습 조건 때문에 내공28·체력348. 우두머리16/16/12/12/14, 체력328, 후배도/단석·회풍을 유지한다. 기민의 새 시간 보정은 아직 미반영이다.
- 초기 내기는 내공, 최대량을 넘으면 상한으로 제한. 삼재 포함 모든 유료 무공 비용을 올리고 기본공격·방어·이동의 비용0/내기 회복은 유지한다.
- 1차: 기존 비용×2/3/4/5/6, 상한40/60/80/100/120/160/200/240. 개별 비용표A/B/C/D는 상한60/65/70/75/80/85/90/100/120. 기존500도 대조군이다. 전체{len(coarse['configs'])}조합.
- 1차는 시작 위치6×적 정책3×시드1, 정밀 검사는 시드3으로 늘린 구성당54조건이다. 관찰 지연3 고정. 비용표/상한 외의 능력치·위력·시간은 결과를 맞추려고 조절하지 않았다.
- 1차{coarse['cases']:,}회 + 정밀{refined['cases']:,}회 = **{total:,}회**. 각 시행의 패배·동시 사망·시간초과를CSV에 모두 남겼다. 비용이 상한보다 큰 무공은 사전에 사용 불가로 별도 기록했고, 기본공격만으로 이겼다고 적합한 조합으로 세지 않았다.
- 정밀 검사는1차의 일부 조합과 시드0을 포함한다. 총 시행 수는 서로 독립적인 사람이나 독립 확률 표본 수가 아니다.
- 기존 자동 정책의 동시 왕복 추격은 자신의 최근 이동4회를 보고 확률적으로10만큼 대기해 해소하도록 보완했다. 양측/모든 비용 조합에 같은 처리를 썼으며 대기에 내기를 지급하지 않는다. 이전 검토와의 승률 변화 전체를 내기 변경만의 효과로 해석하지 않는다. 변경 후 조합끼리 비교한다.

## 비교 정책과 이득 기준

1. **기본공격 회복형:** 가능한 유료 무공을 쓰고, 내기가 모자라면 기본공격으로 회복하며 피해도 준다.
2. **이동 회복형:** 가능한 유료 무공을 쓰고, 내기가 모자라면 거리를 벌리거나 공격 범위 밖으로 이동해 회복한다. 내기가 충분하지만 사거리 밖이면 접근한다. 한 번씩 강제 교대하지 않는다.
3. **방어 회복형:** 내기가 모자라면 기본방어로 회복한다.
4. **최대 축적형:** 최대까지 이동하며 모은 다음 가능한 유료 무공을 이어 쓰고, 부족해지면 다시 모은다.

이동형이 기본공격 회복형보다 이겼거나, 양쪽 승리일 때 체력이 최대치의10% 이상 더 남고 시간이1.5배 이하인 경우를 이득으로 분류했다. 그 사이 유료 공격 사이에 실제 이동이 있어야 순환 이득으로 센다. 이 임계값은 분석 기준이며 인간의 재미 점수가 아니다. 체력/시간 중앙값만 다른 사례끼리 빼지 않고 동일 시작·적·시드끼리 비교했다.

## 시험한 비용표

표의 A/B/C/D는 장비 절감 전 가격이다. D의 마지막 열은 현재 균형창10% 절감을 반영했다.

{chr(10).join(price_table)}

## 구간 비교

{chr(10).join(range_table)}

‘축적형 지배’는 축적형이 이기고 이동형이 못 이겼거나, 양쪽 승리에서 체력이 더 낮지 않고 시간도 더 길지 않으면서 적어도 하나가 더 좋은 경우다. 이 수치가0이어야 한다는 뜻은 아니다.

## D안·최대80의 전체 무공 비교

각 칸은 **승리/54 · 잔여 체력 중앙값 · T 중앙값**이다. 잔여 체력은 패배의0도 포함한다. 무공마다 같은 통계 조건을 사용한다.

{chr(10).join(comparison)}

이동이 더 많아졌다는 이유로 성공으로 해석하지 않는다. 모든 무기에서 이동형이 다른 회복형을 지배하는 구간은 확인하지 못했다. 같은 시간10을 써도 기본공격은 내기 회복과 피해를 함께 얻으므로, 적의 강공을 피하거나 다음 공격 위치를 잡을 때 이동의 이득이 생긴다.

## 연속 공격을 막는 경계

최대내기M, 소비C, 행동 종료 회복R일 때, **가득 모은 상태에서 같은 무공을 두 번 연속 쓰려면 M≥2C−R**이어야 한다. 비용이 회복보다 큰 서로 다른 두 기술은 M≥C1+C2−R이 필요하다. C≤R이면 상한 안에서 한 번 사용할 수 있는 순간 계속 사용할 수 있다.

C>R이면 연속 사용 상한은 `1 + floor((M−C)/(C−R))`이다. C>M이면 사용 불가다. 비용/회복만의 계산이며, 사거리·후퇴·적의 방해 때문에 실제 연속 횟수는 더 적을 수 있다.

{chr(10).join(chains)}

- 단순 배수안은 창의 큰 비용을 허용하려고 상한을 높이면 삼재의 여러 번 연속 사용을 허용한다. 무공별 가격 차이도 함께 좁히는 이유다.
- D의 경우 상한80에서 강한 도/창/권/장은 자원만으로도 한 번 후 회복 행동이 필요하다. 값싼 삼재/검은 짧은 연속 공격을 남긴다.
- D 운기장법은 내공28 때문에 **상한82부터 두 번 연속 사용**이 가능하다. D 단석/철산은90부터, 관풍은88부터다.80은 이 경계 아래다. 내공이나 장비가 달라지면 경계도 바뀐다.
- R만 남은 상태에서 다음 비용을 마련하는 데 필요한 무료 행동 수는 `max(0, ceil(C/R)−1)`이다. 남은 내기를 가져가면 실제 필요한 이동 횟수는 매번 달라진다. 대기는 이 회복 행동에 포함되지 않는다.

## 실제 도원 기록: D/최대80·단석·이동 회복형

첫 시작 위치/공세형/시드0으로 고정한 기록이다. 성공한 장면만 골라 만든 대본이 아니다. 각 행은 행동 시작 때의 내기이며, 회복은 해당 행동이 끝나야 지급된다.

{chr(10).join(events)}

최종 {example['result']['winner']}, T={example['result']['time']}, 도원 체력{example['result']['hero_hp']}. 같은 조건의 기본공격/방어/최대 축적형도 재생기에 함께 들어 있다.

## 해석의 한계

- 모든 전략의 최적 플레이를 탐색한 결과가 아니다. 이동 회복형은 안전거리 우선 휴리스틱으로, 장거리에서 불필요하게 돌아가는 경우도 있다. 실제 플레이의 승률이나 재미를 보장하지 않는다.
- 적도 비용 인상 영향을 받는다. 내공12인 우두머리가 유료 기술을 덜 쓰고 기본공격을 늘리면 난도가 낮아질 수 있다. 이 때문에 높은 승리 수를 전술적 재미 향상의 증거로 사용하지 않는다. 정책별 적의 유료 기술 횟수도 요약에 기록했다.
- 비용만으로 이동을 항상 정답으로 만들지는 못했다. 기본공격/방어도 같은 시점에 같은 양을 회복한다. 이동이 유리한 전황을 남기되, 별도의 무공 조합 다양성은 후속 검토가 필요하다.
- 내공이 오르면 C−R이 줄고 연속 사용이 늘어난다. 이번 수치 추천 범위는 내공20~28의 장사 단계이며, 내공200까지의 보편 최종 균형안이 아니다.

## 재현·원자료

- [독립 실험 안내](../../prototypes/timed-qi-review/README.md)
- [수치 탐색/실제 기록 재생](../../prototypes/timed-qi-review/index.html): 다운로드 후 브라우저에서 연다.
- [1차CSV](../../prototypes/timed-qi-review/coarse-results.csv) · [정밀CSV](../../prototypes/timed-qi-review/refined-results.csv)
- [1차 요약](../../prototypes/timed-qi-review/coarse-summary.json) · [정밀 요약](../../prototypes/timed-qi-review/refined-summary.json)

검사: 기존 회복 시점/이동 회복/대기 무회복/상한/새 가격/장비 올림/연속 사용 수식/원래 비용 대조/양측 추격 대기를 확인한다. 수치는 게임에 적용하지 않았다.
'''
(sweep.base.ROOT/'docs/reviews/timed-qi-budget.md').write_text(report)
print('Built qi explorer/report:',total,'cases;',len(replays),'replays')
