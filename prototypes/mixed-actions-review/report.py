#!/usr/bin/env python3
"""Rebuild the review from retained numerical results, including failing cases."""
import csv
import hashlib
import html
import json
from collections import Counter
from pathlib import Path
import experiment as e

HERE=e.HERE
ROOT=HERE.parents[1]
FIELDS=('minimum','offset','level','foe','start','seed','information','risk')


def read(name):
    rows=[]
    for row in csv.DictReader((HERE/(name+'.csv')).open(encoding='utf-8-sig')):
        for key,value in row.items():
            if value in ('True','False'):row[key]=value=='True'
            else:
                try:row[key]=int(value)
                except ValueError:
                    try:row[key]=float(value)
                    except ValueError:pass
        rows.append(row)
    return rows


def aggregate(rows):
    result=Counter()
    for value in e.analyse(rows).values():result.update(value)
    return dict(result)


def cases(rows):
    out={}
    for row in rows:out.setdefault(tuple(row[k] for k in FIELDS),{})[row['mask']]=row
    return out


def joint(c):
    return c['full']['actual_mix'] and all(e.practical_better(c['full'],c[m]) for m in ('no_reposition','no_guard','only_A','only_B'))


def outcome(row):
    return {'hero':'승리','boss':'패배','draw':'동시 전멸','timeout':'시간초과'}[row['winner']]


def md_table(headers,rows):
    return '\n'.join(['| '+' | '.join(map(str,headers))+' |','|'+'---|'*len(headers)]+
                     ['| '+' | '.join(map(str,r))+' |' for r in rows])


def record(case):
    r=case['full']
    sim=e.Combat(*e.pair(r['level'],r['foe'],r['start']),budget=e.Budget(minimum=r['minimum'],offset=r['offset']),
                 information=r['information'],risk=r['risk'],horizon=40,seed=r['seed'],reaction=0,
                 enemy_style='pressure' if r['seed']==0 else 'cautious',record=True)
    result=sim.run()
    assert (result['winner'],result['hero_hp'],result['time'])==(r['winner'],r['hp'],r['time'])
    return dict(case=r,comparisons=list(case.values()),frames=sim.frames,events=sim.log)


def run():
    main=read('results');exact=read('exact50');sensitivity=read('sensitivity');probe=read('cost-probe')
    assert len(main)==2016 and len(exact)==252 and len(sensitivity)==336 and len(probe)==504
    standard=[r for r in main if r['minimum']==100]
    grouped=cases(standard)
    coarse=[c for c in grouped.values() if c['full']['information']=='coarse']
    successful=next(c for c in coarse if joint(c))
    repeat=max((c for c in coarse if c['full']['level']==200 and c['full']['winner']=='hero' and not c['full']['actual_mix']),
               key=lambda c:max(c['full']['basic_count'],c['full']['casts_A'],c['full']['casts_B'])/
                   max(1,c['full']['basic_count']+c['full']['casts_A']+c['full']['casts_B']))
    selected=[record(successful),record(repeat)]
    (HERE/'selected-replays.json').write_text(json.dumps(selected,ensure_ascii=False,separators=(',',':')))

    # The two floor candidates must be identical once inner>=30; verify every retained value.
    main_cases=cases(main)
    for key,case in main_cases.items():
        if key[0]!=50 or key[2]<50:continue
        other=main_cases[(100,*key[1:])]
        for mask,row in case.items():
            assert {k:v for k,v in row.items() if k!='minimum'}=={k:v for k,v in other[mask].items() if k!='minimum'}
    for name in ('results','exact50'):
        meta=json.loads((HERE/(name+'.json')).read_text())
        for path,digest in meta['hashes'].items():
            assert hashlib.sha256((HERE.parent/path).read_bytes()).hexdigest()==digest,path

    stage_rows=[]
    for level in e.LEVELS:
        g=aggregate([r for r in standard if r['level']==level and r['information']=='coarse'])
        stage_rows.append([level,e.Budget(minimum=100).capacity(level),g['full_wins'],g['movement_merit'],g['guard_merit'],g['second_art_merit'],g['all_actions_used'],g['joint_practical_merit']])
    totals={info:aggregate([r for r in standard if r['information']==info]) for info in ('committed','coarse')}
    early=[]
    for pool in (exact,[r for r in main if r['minimum']==50 and r['level']==20],[r for r in standard if r['level']==20]):
        g=aggregate([r for r in pool if r['information']=='coarse'])
        early.append([pool[0]['capacity'],g['full_wins'],g['movement_merit'],g['guard_merit'],g['second_art_merit'],g['joint_practical_merit']])
    horizon_rows=[]
    for horizon in (20,40,60):
        pool=([r for r in standard if r['start']==1 and r['seed']==0] if horizon==40 else [r for r in sensitivity if r['horizon']==horizon])
        for info in ('committed','coarse'):
            g=aggregate([r for r in pool if r['information']==info])
            horizon_rows.append([horizon,info,g['full_wins'],g['movement_merit'],g['guard_merit'],g['second_art_merit'],g['joint_practical_merit']])
    comparison=[]
    for c in grouped.values():
        r=c['full']
        comparison.append({k:r[k] for k in FIELDS}|dict(movement=e.practical_better(r,c['no_reposition']),guard=e.practical_better(r,c['no_guard']),
            second_art=all(e.practical_better(r,c[m]) for m in ('only_A','only_B')),joint=joint(c),
            hp_delta_no_guard=r['hp']-c['no_guard']['hp'],time_delta_no_guard=r['time']-c['no_guard']['time']))
    with (HERE/'comparisons.csv').open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(comparison[0]),lineterminator='\n');w.writeheader();w.writerows(comparison)

    headings=['능력치 기준값/내공','최대 내기','승리','이동 이득','방어 이득','두 무공 이득','모두 실제 사용','엄격 결합 통과']
    stages=md_table(headings,stage_rows)
    early_table=md_table(['초반 실제 최대 내기','승리','이동 이득','방어 이득','두 무공 이득','엄격 결합 통과'],early)
    affordable=[]
    for cap in (50,100):
        p=aggregate([r for r in probe if r['minimum']==cap and r['information']=='coarse'])
        affordable.append([cap,p['full_wins'],p['movement_merit'],p['guard_merit'],p['second_art_merit'],p['joint_practical_merit']])
    affordable_table=md_table(['실제 상한/비용70%','승리','이동 이득','방어 이득','두 무공 이득','엄격 결합 통과'],affordable)
    horizon_table=md_table(['예측 길이','정보 조건','승리','이동 이득','방어 이득','두 무공 이득','엄격 결합 통과'],horizon_rows)
    example=successful['full']
    compare_table=md_table(['제한','결과','남은 체력','종료 T'],[[e.LABELS[m],outcome(r),r['hp'],r['time']] for m,r in successful.items()])
    starts=[event for event in selected[0]['events'] if event['kind']=='start' and event['actor']==0 and event['art']!='wait']
    timeline=md_table(['도원 시작 T','실제 선택','소비 직후 내기','동작 완료 예정 T'],[[v['t'],e.eng.base.LABELS.get(v['art'],v['art']),v['qi'],v['end']] for v in starts])
    all_outcomes=Counter(r['winner'] for r in main+exact+sensitivity+probe)
    summary=dict(cases=len(main)+len(exact)+len(sensitivity)+len(probe),outcomes=dict(all_outcomes),standard=totals,stage_rows=stage_rows,early_rows=early,affordable_rows=affordable,
                 horizon_rows=horizon_rows,strict_physical_cases=len({(c['full']['level'],c['full']['foe'],c['full']['start'],c['full']['seed']) for c in grouped.values() if joint(c)}))
    (HERE/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2))
    g=totals['coarse']
    text=f'''# 이동·방어·두 무공을 섞는 것이 유리한가

2026-10-30. **수치 검토 전용. 본게임/실제 무공/저장은 변경하지 않았다.**

검토 결론은 **이동의 이점은 나타나고 두 무공의 이점도 일부 있지만, 방어까지 함께 섞는 구조는 아직 안정적으로 성립하지 않는다**이다. 내기 상한만 바꿔서 해결됐다고 판정하지 않는다. 이 결과는 사람의 재미·최적 전술을 증명하는 것이 아니라 아래 제한된 판단기의 실제 실행 결과다.

## 어떻게 비교했나

실행 완료 총 **{summary['cases']:,}회**: 성장식2,016회 + 초반 실제 상한50의252회 + 예측 길이 민감도336회 + 사용 불가를 제거한 비용 대조504회. 모든 시행의 승패/동시 전멸/시간초과를 원자료에 보존했다. 결과 합계는 {dict(all_outcomes)}이다. 동일 조건의 제한7종이 포함되므로 독립 표본 수나 인간 승률로 해석하지 않는다.

성장 구간의 기준값20/50/100/200을 근력·기민·근골·내공·오성에 배분했다. 초반 주인공만 오성+1이다. 각 구간의 무공 조합은 청풍/유수, 회류/유수, 유하/회류, 유하/천광이다. 테스트 상급2종은 본게임에 등록하지 않았다. 검을 쓰는 주인공과 검·강공 도·긴 사거리 창의 가상 상대3종, 시작 배치3종, 압박/신중 적 AI2종, 정보 조건2종을 비교한다. 실제 퀘스트 적이나 전 무기·빌드의 난이도 검사가 아니다.

동일한 판단기에서 전체 허용/회피·거리조절 제한/기본방어 제한/A만/B만/접근 외 이동·방어 없이 A만/같은 제한 B만의7종을 비교했다. 모든 경우 필수 접근과 기본공격은 가능하다. 검법 수동 방어와 무공 자체 이동도 유지한다. 기본4슬롯+별도 이동,20% 기본방어,기존 검토 위력·시간·비용을 고정하고 다양성 가산점이나 강제 교대는 넣지 않았다.

이득 기준은 ①패배·시간초과→승리, 또는 양쪽 승리에서 ②최대 체력10% 이상 더 남기고 시간 증가50% 이내, 또는 ③체력이 덜 깎이면서 시간20% 이상 감소다. 두 무공 이득은 A 단독/B 단독 **모두**보다 나아야 한다. 엄격 결합 통과는 별도 회피·거리조절 성공, 기본방어 실제 감쇄, A/B 모두 명중에 더해 세 개의 개별 이득을 같은 전투에서 만족해야 한다.

## 최대 내기 최솟값100 조건

성장식은 `max(100,40+내공×2)`이며 시작 내기/행동 전체 완료 때의 회복은 내공 그대로다. 대기는 회복하지 않는다. 다음 표는 **적 현재 기술을 대표 자세로 추정하는 coarse 조건**, 각 행18조건이다.

{stages}

전체72조건에서 이동 이득{g['movement_merit']}, 기본방어 이득{g['guard_merit']}, 두 무공 이득{g['second_art_merit']}였다. 모두 실제 사용은{g['all_actions_used']}이지만 엄격 결합 통과는{g['joint_practical_merit']}뿐이다. 각 기능이 유리한 전투가 서로 다르다는 뜻이며 사용 횟수를 성공으로 바꿔 세지 않았다. 반대로 전체 허용보다 이동 제한판이 유리한 경우도{g['movement_regret']}, 방어 제한판이 유리한 경우도{g['guard_regret']}다. 전체 허용이 항상 최선이라는 보장은 없고, 유한 예측 판단기의 실수도 포함된다.

현재 시작한 적 기술의 정확한 수치를 아는 committed 조건72개에서도 엄격 결합 통과{totals['committed']['joint_practical_merit']}개다. 두 정보 조건의 통과는 **같은 물리적 대전1개**이며 서로 다른 두 장면의 성공으로 부풀리지 않는다. coarse 역시 적 능력치·보유 무공·방향을 아는 가상 판단기다. 실제 UI와 초심자 반응을 검증하지 않았다.

## 50과100의 차이

기존 `40+내공×2` 성장식에서 바닥50/100은 내공30부터 결과가 완전히 같아진다. 내공20에서는 각각 실제 상한80/100이다. 이 사실을 숨기지 않고 **실제 상한50**도 초반 추가 검사했다. 같은 상대·조건이며 표의 각 행18조건(coarse)이다.

{early_table}

실제 상한50에서 승리가 늘어난 것을 좋은 균형으로 해석하면 안 된다. 현재 하급 검토 비용40~70에서 검2종을 제외한6종은 초반 장비 할인까지 반영해도50을 넘는다. 강공/창 상대가 무공을 못 쓰게 되어 쉬워지는 효과가 섞여 있다. **현재 비용 후보를 유지한다면 다음 검토의 최솟값은100을 추천**한다. 이 값은 다양성의 해답이 아니라 기존 무공을 봉쇄하지 않는 출발점이다. 최종 성장식 확정이나 본게임 적용은 하지 않았다.

### 사용 불가 효과를 제거한 추가 대조

위력·범위·시간은 그대로 두고 양쪽 무공의 내기 비용을70%로 낮췄다(올림 후 장비 할인·다시 올림). 모든 하급8종을 실제 상한50에서도 쓸 수 있다. 초반 내공20·실제 상한50/100의 동일18조건(coarse)씩이며 회복은 계속20이다.

{affordable_table}

이 대조군은 비용도 바뀌므로 원래 비용의50과100을 섞어 우열을 단정하지 않는다. 상한50을 쓰려면 비용 재편이 함께 필요하고, 사용 가능성을 해결한 뒤에도 엄격 결합 통과가 보편적으로 발생하지 않는다. 이 추가 대조에서도 상한 변경만으로 전술 다양성을 확정하지 않는다. [원자료](../../prototypes/mixed-actions-review/cost-probe.csv).

## 실제로 함께 사용해 유리했던 대전

기준 능력치50, 내공50/최대 내기140, 체력620, 회류검법·유수검법, 가상 검객(동일 능력치/무공·신중 AI), 시작(1,2) 대(5,2), seed1, coarse 조건이다. 전 구간에서 일반적으로 반복 재현되는 결과가 아니라 **성공 사례1개**다.

{compare_table}

전체 허용은 거리조절 이동{example['tactical_moves']}회, 기본방어 실제 감쇄{example['active_guard_saved']}, 회류 명중{example['hits_A']}회/유수 명중{example['hits_B']}회로 T={example['time']}에 체력{example['hp']}을 남기고 이겼다. 무조건 여러 행동을 넣어서 이긴 것이 아니라, 같은 조건에서 기능을 뺐을 때 승리를 잃는 사례가 존재한다.

도원의 실제 명령 기록(초가 아닌 정수 T, 대기 제외):

{timeline}

상대 명령·명중/빗나감·회복·좌표는 [기록 재생기](../../prototypes/mixed-actions-review/index.html)에서 같은 기록으로 확인할 수 있다. 고단계에서 섞지 않고 이긴 반례도 함께 넣었다.

## 판단기 의존성

동일 시작 배치1/seed0의12조건씩, 예측 길이20/40/60을 비교했다. 적의 미래 명령·실제 미래 난수는 보지 않고 공통 단순 정책으로 예측한다. 상대는 같은 예측기를 사용하지 않는다. 전체 허용이 제한판보다 오히려 나빠지는 경우도 원자료/요약에 남긴다.

{horizon_table}

예측 길이에 따라 두 번째 무공과 방어의 이득이 흔들린다. 따라서 “이 시스템이면 누구나 자연스럽게 네 종류 행동을 섞는다”거나 “현재 판단기가 최적 전술을 찾았다”고 결론내릴 수 없다. 총합 높은 캐릭터의 현재 전투 방식·인간 재미·기민 속도 보정도 이번 결과로 확정하지 않는다.

## 다음에 바꿔 볼 부분 — 미적용/미검증 제안

- 기본방어20%는 공격 기회10을 포기하는 대가에 비해 약하며, 검법 자체20% 방어와 역할도 겹친다. 같은 시간표에서 기본방어40%/60%를 비교하고, 회피100%와 다른 쓰임이 생기는지 검사할 필요가 있다. 회복 시점/회복량은 우선 그대로 둔다.
- 두 무공을 같은 역할의 피해량 차이로 두기보다 빠른 견제/짧은 회수와 느린 파훼/큰 확정 피해로 구분한다. 적이 긴 준비에 들어갈 때와 회수에 들어갈 때 유리한 기술이 달라져야 한다. 강제 교대·반복 벌점은 추가하지 않는다.
- 적의 무공도 짧아 회피가 늦는 공격과 피한 뒤 회수를 노릴 수 있는 큰 공격을 구분한다. 내기 부족 때문에 이동을 반복하게 하는 것과 전술적으로 이동하는 재미는 별개다.

이 세 제안은 이번 실험 결과가 아니며 다음 비교 후보다. 현재 결과에서는 **최소량100을 검토 기준으로 삼되, 방어·무공 역할을 다듬는 작업이 추가로 필요**하다.

재현 명령/가정은 [README](../../prototypes/mixed-actions-review/README.md), 원자료는 [전체](../../prototypes/mixed-actions-review/results.csv), [실제 상한50](../../prototypes/mixed-actions-review/exact50.csv), [예측 길이](../../prototypes/mixed-actions-review/sensitivity.csv), [조건별 비교](../../prototypes/mixed-actions-review/comparisons.csv)다. 입력/소스 SHA256은 결과 JSON과 `manifest.json`에 기록한다.
'''
    (ROOT/'docs/reviews/mixed-actions-merit.md').write_text(text)
    names=dict(e.eng.base.LABELS)
    data=json.dumps(dict(summary=summary,replays=selected,names=names,labels=e.LABELS),ensure_ascii=False,separators=(',',':')).replace('</','<\\/')
    template=(HERE/'viewer.template.html').read_text()
    (HERE/'index.html').write_text(template.replace('__DATA__',data))
    paths=[HERE/'experiment.py',HERE/'sensitivity.py',HERE/'cost_probe.py',HERE/'report.py',HERE/'viewer.template.html']
    paths+=[ROOT/'godot/data'/f'{name}.json' for name in ('basic_martial_arts','alliance_martial_arts','quest_martial_arts','support_martial_arts','martial_tactics','weapons','tutorial_enemy')]
    (HERE/'manifest.json').write_text(json.dumps({str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2))
    print(json.dumps(summary,ensure_ascii=False,indent=2))


if __name__=='__main__':run()
