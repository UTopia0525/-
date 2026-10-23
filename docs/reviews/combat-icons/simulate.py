"""Read current game data; compare review-only rules. Does not write game assets or saves."""
from pathlib import Path
import json, math
ROOT=Path(__file__).resolve().parents[3]
ARTS=json.loads((ROOT/'godot/data/basic_martial_arts.json').read_text())
WEAPONS=json.loads((ROOT/'godot/data/weapons.json').read_text())
def damage(raw,g,weapon_pct=0,guard_pct=0):
    return math.floor(max(0,raw-g)*100/(100+g)*(1-weapon_pct/100)*(1-guard_pct/100)+1e-9)
def options(s,kit,weapon,qi,defense,sword):
    found=[]
    for name in kit:
        if not name: continue
        if name=='basic_attack': found.append((name,sum(s[x] for x in ['strength','agility','inner']),0,0));continue
        if name=='basic_defense': found.append((name,0,0,defense));continue
        a=ARTS[name]
        if a['required_weapon_type']!=weapon['weapon_type'] or qi<a['qi_cost']:continue
        raw=sum(s[k]*v for k,v in a['damage_coefficients'].items())*(1+weapon['attack_bonus_percent']/100)
        found.append((name,raw,a['qi_cost'],sword if a['weapon_style']=='sword' else 0))
    return found
STATES=[
 dict(id='tutorial',name='시작 캐릭터·기존 튜토리얼 적',stats=dict(strength=10,agility=10,constitution=10,inner=10,insight=10),kit=['basic_attack','basic_defense','samjae',''],weapon='plain_iron_sword',hp=150,g=5,pattern=[('보통 공격',40)]),
 dict(id='grown_fixed',name='실측 성장·기존 우두머리 공격',stats=dict(strength=25,agility=25,constitution=25,inner=19,insight=10),kit=['basic_attack','basic_defense','samjae','swaeam'],weapon='refined_sword',hp=240,g=15,pattern=[('보통 공격',70)]),
 dict(id='grown_intent',name='실측 성장·예고 패턴 가정',stats=dict(strength=25,agility=25,constitution=25,inner=19,insight=10),kit=['basic_attack','basic_defense','samjae','swaeam'],weapon='refined_sword',hp=240,g=15,pattern=[('견제',55),('강공',125),('축기',0)]),
 dict(id='quest_plan',name='의뢰 보상 연결 후 성장안·예고 패턴 가정',stats=dict(strength=12,agility=14,constitution=12,inner=14,insight=55),kit=['basic_attack','basic_defense','samjae','cheongpung'],weapon='refined_sword',hp=240,g=15,pattern=[('견제',55),('강공',125),('축기',0)]),
 dict(id='stress',name='검토용 내구성 스트레스 적·게임 미적용',stats=dict(strength=25,agility=25,constitution=25,inner=19,insight=10),kit=['basic_attack','basic_defense','samjae','swaeam'],weapon='refined_sword',hp=420,g=15,pattern=[('견제',55),('강공',125),('축기',0)])]
def battle(c,defense=60,sword=20,policy='attack'):
    s=c['stats'];w=WEAPONS[c['weapon']];hp=300;enemy=c['hp'];qi=s['inner'];trace=[]
    for turn in range(1,41):
        intent,raw_enemy=c['pattern'][(turn-1)%len(c['pattern'])]
        acts=options(s,c['kit'],w,qi,defense,sword)
        attacks=[a for a in acts if a[1]>0]
        best=max(attacks,key=lambda a:(a[1],-a[2]))
        # Always take a guaranteed kill instead of guarding a dead opponent.
        guard=policy=='guard_heavy' and intent=='강공' and damage(best[1],c['g'])<enemy
        a=next(x for x in acts if x[0]=='basic_defense') if guard else best
        qi-=a[2];out=damage(a[1],c['g']);enemy=max(0,enemy-out)
        incoming=damage(raw_enemy,s['constitution'],w['damage_reduction_percent'],a[3]) if enemy>0 else 0
        hp=max(0,hp-incoming)
        trace.append(dict(turn=turn,intent=intent,action=a[0],dealt=out,received=incoming,hp=hp,enemy_hp=enemy,qi=qi,guard=a[3]))
        if enemy==0 or hp==0: return dict(win=enemy==0,turns=turn,hp=hp,trace=trace)
        qi=min(500,qi+s['inner'])
    return dict(win=False,turns=40,hp=hp,trace=trace)
def optimal(c,defense,sword=20,max_turns=12):
    s=c['stats'];w=WEAPONS[c['weapon']]
    frontier={(c['hp'],s['inner']):(300,[])};wins=[]
    for turn in range(1,max_turns+1):
        nxt={};intent,raw_enemy=c['pattern'][(turn-1)%len(c['pattern'])]
        for (enemy,qi),(hp,path) in frontier.items():
            for name,raw,cost,guard in options(s,c['kit'],w,qi,defense,sword):
                ehp=max(0,enemy-damage(raw,c['g']));newpath=path+[name]
                if ehp==0:
                    wins.append(dict(turns=turn,hp=hp,actions=newpath));continue
                ph=hp-damage(raw_enemy,s['constitution'],w['damage_reduction_percent'],guard)
                if ph<=0:continue
                key=(ehp,min(500,qi-cost+s['inner']))
                if key not in nxt or ph>nxt[key][0]:nxt[key]=(ph,newpath)
        frontier=nxt
    fastest=min(wins,key=lambda w:(w['turns'],-w['hp'])) if wins else None
    safest=max(wins,key=lambda w:(w['hp'],-w['turns'])) if wins else None
    return dict(fastest=fastest,safest=safest)
results=[]
for c in STATES:
    row={'id':c['id'],'name':c['name'],'stats':c['stats'],'enemy_hp':c['hp'],'pattern':c['pattern'],'attack_without_sword_guard':battle(c,60,0,'attack'),'attack':battle(c,60,20,'attack'),'variants':{}}
    for pct in [50,60,70]:row['variants'][str(pct)]={'reactive':battle(c,pct,20,'guard_heavy'),'optimal':optimal(c,pct)}
    results.append(row)
report={'scope':'검토 전용. 적 예고 패턴·기본방어·검법 방어는 실제 게임 미적용. 의뢰 성장안은 일반6종 완료 연결을 가정한다.','formula':'floor(max(0,D-G)*100/(100+G)*(1-weapon/100)*(1-guard/100))','one_hit_comparison':{str(p):damage(70,25,3,p) for p in [0,20,50,60,70]},'scenarios':results}
Path(__file__).with_name('simulation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
for r in results:
    print(r['id'],'attack',r['attack']['turns'],r['attack']['hp'])
    for p,v in r['variants'].items():
        a=v['reactive'];o=v['optimal'];print(' defense',p,'reactive',(a['turns'],a['hp']),'optimal',o)
