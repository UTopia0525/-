#!/usr/bin/env python3
"""Stage/grade/capacity verification, with loss and resource-lock accounting."""
import argparse
import copy
import csv
import hashlib
import json
import math
import statistics
from collections import Counter
from pathlib import Path
import catalogue as cat
import engine as eng

HERE=Path(__file__).resolve().parent
LEVELS=(10,20,50,100,150,200)
STYLES=('sword','saber','spear','fist','palm')
POLICIES=('efficient','heavy','mobile')
STARTS=(0,1,3)
FORMULAS=tuple(cat.FORMULAS)

def profile(level,kind='balanced'):
    stats=dict(strength=level,agility=level,constitution=level,inner=level,insight=level)
    if kind=='inner':
        delta=min(level//2,200-level)
        stats['inner']+=delta;stats['strength']-=(delta+1)//2;stats['constitution']-=delta//2
    elif kind=='strength':
        delta=min(level//2,200-level)
        stats['strength']+=delta;stats['inner']-=(delta+1)//2;stats['constitution']-=delta//2
    assert sum(stats.values())==5*level
    assert all(0<=v<=200 for v in stats.values())
    return stats

def can_learn(art,stats):
    d=eng.CURRENT.get(art)
    if not d:return True
    req=d.get('requirements',{})
    return sum(stats.values())>=req.get('minimum_total',0) and all(stats[k]>=v for k,v in req.get('stats',{}).items())

def weapon(style,tier):
    return {'sword':['refined_sword','blue_steel_sword','hundredfold_sword'],
            'saber':['thickback_saber','forged_saber','heavy_steel_saber'],
            'spear':['balanced_spear','willow_spear','flowing_cloud_spear'],
            'fist':['none']*3,'palm':['none']*3}[style][tier-1]

def kit(style,kind):
    arts=cat.STYLE_ARTS[style]
    if kind=='intro':return ['basic_attack','basic_defense','samjae']
    if kind=='low':return ['basic_attack','basic_defense',arts['low']]+(['samjae'] if style=='sword' else [])
    if kind=='mid':return ['basic_attack','basic_defense',arts['mid'],arts['low']]
    if kind=='upper':return ['basic_attack','basic_defense',arts['upper'],arts['mid']]
    if kind=='support':return ['basic_attack','basic_defense',arts['upper'],'josik_suwon']
    if kind=='finisher':return ['basic_attack','basic_defense',arts['upper'],arts['finisher']]
    raise ValueError(kind)

def make_fighters(level,style,kind,start,tier=None,build='balanced',opponent='sword'):
    tier=tier or (1 if level<=20 else 2 if level<=50 else 3)
    hero=eng.base.Fighter('도원',profile(level,build),weapon(style,tier),kit(style,kind),eng.base.STARTS[start][0])
    if level==20:hero.stats['insight']+=1
    # A story-taught middle art can be used without inventing learning conditions.
    # An unavailable optional low-art fallback does not silently become learned.
    hero.arts=[art for i,art in enumerate(hero.arts) if i==2 or can_learn(art,hero.stats)]
    if level==10:
        data=json.loads((cat.DATA/'tutorial_enemy.json').read_text())
        enemy=eng.base.Fighter(data['name'],data['stats'],data['weapon'],['basic_attack','basic_defense','samjae'],eng.base.STARTS[start][1])
    elif level==20:
        data=eng.base.BOSS
        enemy=eng.base.Fighter(data['name'],copy.deepcopy(data['stats']),data['weapon'],['basic_attack','basic_defense','danseok','hoepung'],eng.base.STARTS[start][1])
    else:
        # Hypothetical equal-stat swordsman, not an edit to any named story NPC.
        opponent_arts=cat.STYLE_ARTS[opponent]
        skills=['basic_attack','basic_defense',opponent_arts['mid'],opponent_arts['low']] if level==50 else ['basic_attack','basic_defense',opponent_arts['upper'],opponent_arts['mid']]
        enemy=eng.base.Fighter('가상 동급 무인 · '+opponent,profile(level),weapon(opponent,tier),skills,eng.base.STARTS[start][1])
    assert len(hero.arts)<=4 and len(enemy.arts)<=4
    return hero,enemy

def resource_cycle(cap,cost,recovery,total):
    if cost>cap or (recovery==0 and cost>0):return None
    seen={};qi=min(cap,recovery);time=hits=free=0
    while qi not in seen:
        seen[qi]=(time,hits,free)
        if qi>=cost:
            qi=min(cap,qi-cost+recovery);time+=total;hits+=1
        else:
            qi=min(cap,qi+recovery);time+=10;free+=1
    first_time,first_hits,first_free=seen[qi]
    cycles=hits-first_hits
    return dict(time_per_cast=(time-first_time)/cycles,free_per_cast=(free-first_free)/cycles)

def price_grid():
    rows=[]
    for mode in ('current','graded'):
        eng.install(mode)
        for formula in FORMULAS:
            for level in (10,20,28,50,80,100,150,200):
                stats=profile(level)
                for tier in (1,2,3):
                    for art,d in eng.CURRENT.items():
                        style=d['weapon_style']
                        style='fist' if style=='support' else style
                        w=weapon(style,tier);budget=eng.Budget(formula)
                        cap=budget.capacity(level);cost=budget.cost(art,w)
                        raw=eng.base.raw(art,stats,w) if art!='josik_suwon' else 0
                        dealt=eng.base.damage(raw,stats,weapon('sword',tier)) if raw else 0
                        cycle=resource_cycle(cap,cost,level,sum(cat.TIMINGS[art])) if raw else None
                        rows.append(dict(mode=mode,formula=formula,inner=level,tier=tier,art=art,cap=cap,cost=cost,
                            raw=round(raw,4),damage=dealt,total=sum(cat.TIMINGS[art]),
                            chain=eng.energy.max_chain(cap,cost,level) if raw else None,
                            time_per_cast=round(cycle['time_per_cast'],4) if cycle else None,
                            sustained_damage=round(dealt/cycle['time_per_cast'],4) if cycle else None,
                            free_per_cast=round(cycle['free_per_cast'],4) if cycle else None,
                            first_free_actions=max(0,math.ceil((cost-level)/level)) if cost<=cap else None,
                            usable=cost<=cap))
    return rows

def summary(rows):
    groups={}
    for r in rows:
        key='/'.join(str(r[k]) for k in ('mode','formula','mid_scale','upper_scale','level','build','tier','style','kit','policy'))
        groups.setdefault(key,[]).append(r)
    result={}
    for key,group in groups.items():
        result[key]=dict(n=len(group),wins=sum(r['winner']=='hero' for r in group),losses=sum(r['winner']=='boss' for r in group),
            draws=sum(r['winner']=='draw' for r in group),timeouts=sum(r['winner']=='timeout' for r in group),
            median_hp=statistics.median(r['hp'] for r in group),median_time=statistics.median(r['time'] for r in group),
            median_support=statistics.median(r['support'] for r in group),median_upper=statistics.median(r['upper_casts'] for r in group))
    return result

def write_csv(path,rows):
    with path.open('w',encoding='utf-8-sig',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');writer.writeheader();writer.writerows(rows)

def run(stage):
    rows=[];locked=[];replays=[]
    settings=[]
    if stage=='formula':
        for mode in ('current','graded'):
            for formula in FORMULAS:settings.append((mode,formula,1.,1.,'balanced',None))
    else:
        for mid,upper in ((.85,1.),(1.,.85),(1.,1.),(1.15,1.),(1.,1.15)):
            for build in ('balanced','inner','strength'):
                settings.append(('graded','floor80_40_2I',mid,upper,build,None))
        # The maximum spear discount must be tested, not assumed to be the starting weapon's10%.
        for tier in (1,2):settings.append(('graded','floor80_40_2I',1.,1.,'balanced',tier))
    for mode,formula,mid,upper,build,gear in settings:
        eng.install(mode)
        for level in LEVELS:
            for style in STYLES if level>10 else ('sword',):
                kinds=('low','mid','upper','support') if level>10 else ('intro',)
                if level>=100 and style in ('sword','saber'):kinds+=('finisher',)
                for kind in kinds:
                    budget=eng.Budget(formula,mid,upper)
                    hero,_=make_fighters(level,style,kind,0,gear,build)
                    primary=hero.arts[2]
                    # Expose resource locks separately, even when a fallback basic attack might win.
                    resource_target=hero.arts[3] if kind=='finisher' else primary
                    if not can_learn(primary,hero.stats) or budget.cost(resource_target,hero.weapon)>budget.capacity(hero.stats['inner']):
                        locked.append(dict(mode=mode,formula=formula,mid_scale=mid,upper_scale=upper,level=level,build=build,
                            tier=gear or (1 if level<=20 else 2 if level<=50 else 3),style=style,kit=kind,art=resource_target,
                            cost=budget.cost(resource_target,hero.weapon),cap=budget.capacity(hero.stats['inner']),
                            reason='learning' if not can_learn(primary,hero.stats) else 'capacity'))
                        continue
                    for policy in POLICIES:
                        for start in STARTS:
                            for enemy_style in ('pressure','cautious'):
                                record=stage=='formula' and mode=='graded' and formula=='floor80_40_2I' and level in (20,100,200) and kind in ('mid','upper','support') and policy=='efficient' and start==0 and enemy_style=='pressure'
                                sim=eng.Combat(*make_fighters(level,style,kind,start,gear,build),budget=budget,policy=policy,
                                               enemy_style=enemy_style,reaction=3,seed=start,record=record)
                                r=sim.run()
                                row=dict(mode=mode,formula=formula,mid_scale=mid,upper_scale=upper,level=level,build=build,
                                    tier=gear or (1 if level<=20 else 2 if level<=50 else 3),style=style,kit=kind,policy=policy,
                                    start=start,enemy_style=enemy_style,winner=r['winner'],hp=r['hero_hp'],time=r['time'],
                                    capacity=r['capacity'],enemy_capacity=r['enemy_capacity'],qi=r['hero_qi'],enemy_qi=r['enemy_qi'],
                                    support=r['support_uses'],upper_casts=sum(v for k,v in r['art_counts'].items() if k in cat.UPPER),
                                    primary_casts=r['art_counts'].get(primary,0),paid_chain=r['paid_chain'])
                                rows.append(row)
                                if record:replays.append(dict(mode=mode,formula=formula,level=level,style=style,kit=kind,result=row,
                                                               frames=sim.frames,events=sim.log,history=sim.history))
        print(stage,mode,formula,mid,upper,build,gear,'cumulative',len(rows),flush=True)
    artifact=dict(status='REVIEW ONLY — generic stage opponents, not live game balance',cases=len(rows),
        outcomes=dict(Counter(r['winner'] for r in rows)),locked=locked,summary=summary(rows),
        hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [HERE/'catalogue.py',HERE/'engine.py',HERE/'benchmark.py']},
        source_hashes={name:hashlib.sha256((cat.DATA/(name+'.json')).read_bytes()).hexdigest() for name in cat.FILES})
    (HERE/f'{stage}-summary.json').write_text(json.dumps(artifact,ensure_ascii=False,indent=2))
    write_csv(HERE/f'{stage}-results.csv',rows)
    if replays:(HERE/'replays.json').write_text(json.dumps(replays,ensure_ascii=False,separators=(',',':')))
    print('COMPLETE',stage,len(rows),artifact['outcomes'],flush=True)

def crossmatch():
    rows=[];locked=[]
    for mode in ('current','graded'):
        eng.install(mode)
        budget=eng.Budget()
        for level in (50,100,150,200):
            for style in STYLES:
                for kind in ('mid','upper','support'):
                    hero,_=make_fighters(level,style,kind,0)
                    if budget.cost(hero.arts[2],hero.weapon)>budget.capacity(hero.stats['inner']):
                        locked.append(dict(mode=mode,level=level,style=style,kit=kind));continue
                    for opponent in STYLES:
                        for policy in POLICIES:
                            for start in STARTS:
                                sim=eng.Combat(*make_fighters(level,style,kind,start,opponent=opponent),policy=policy,reaction=3,seed=start)
                                r=sim.run()
                                rows.append(dict(mode=mode,level=level,style=style,kit=kind,opponent=opponent,policy=policy,start=start,
                                    winner=r['winner'],hp=r['hero_hp'],time=r['time'],upper_casts=sum(v for k,v in r['art_counts'].items() if k in cat.UPPER),
                                    support=r['support_uses']))
        print('crossmatch',mode,len(rows),flush=True)
    artifact=dict(cases=len(rows),outcomes=dict(Counter(r['winner'] for r in rows)),locked=locked,
        hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [HERE/'catalogue.py',HERE/'engine.py',HERE/'benchmark.py']})
    (HERE/'crossmatch-summary.json').write_text(json.dumps(artifact,ensure_ascii=False,indent=2))
    write_csv(HERE/'crossmatch-results.csv',rows)
    print('COMPLETE crossmatch',len(rows),artifact['outcomes'],flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--stage',choices=('formula','sensitivity','analytical','crossmatch'),default='formula')
    args=parser.parse_args()
    if args.stage=='analytical':write_csv(HERE/'analytical.csv',price_grid());print('Analytical grid complete')
    elif args.stage=='crossmatch':crossmatch()
    else:run(args.stage)
