#!/usr/bin/env python3
"""Ablation study of movement, active guard and two martial arts; REVIEW ONLY.

Same short-horizon controller for every action mask. No rotation bonus, forced
alternation, repetition penalty, balance edits or live Godot mutations.
"""
from __future__ import annotations

import argparse
import copy
import csv
import hashlib
import json
import math
import random
import statistics
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'progression-combat-review'))
import catalogue as cat
import engine as eng
import benchmark as previous

eng.install('graded')
LEVELS=(20,50,100,200)
PAIRS={20:('cheongpung','yusu'),50:('hoeryu','yusu'),100:('yuha','hoeryu'),200:('yuha','cheongwang')}
# movement flag means optional reposition/dodge, not mandatory approach.
MASKS={
 'full':(True,True,'AB'),
 'no_reposition':(False,True,'AB'),
 'no_guard':(True,False,'AB'),
 'only_A':(True,True,'A'),
 'only_B':(True,True,'B'),
 'simple_A':(False,False,'A'),
 'simple_B':(False,False,'B'),
}
LABELS={'full':'모두 허용','no_reposition':'회피·거리조절 이동 제한','no_guard':'기본방어 제한',
        'only_A':'무공A만','only_B':'무공B만','simple_A':'단순A','simple_B':'단순B'}


@dataclass(frozen=True)
class Budget(eng.Budget):
    minimum:int=100
    offset:int=40
    def capacity(self,inner):return max(self.minimum,self.offset+2*inner)


def pair(level,foe,start):
    a,b=PAIRS[level]
    stats=previous.profile(level)
    stats['insight']+=level==20
    tier=1 if level==20 else 2 if level==50 else 3
    hero=eng.base.Fighter('도원',stats,previous.weapon('sword',tier),['basic_attack','basic_defense',a,b],eng.base.STARTS[start][0])
    if foe=='duelist':
        weapon=previous.weapon('sword',tier)
        skills=PAIRS[level]
    elif foe=='heavy':
        weapon=previous.weapon('saber',tier)
        skills=('danseok','hoepung') if level==20 else ('paak','swaerang') if level<=100 else ('bunag','ildodangang')
    else:
        weapon=previous.weapon('spear',tier)
        skills=('gwanpung','yeonhwan') if level==20 else ('gwanak','yeonhwan') if level==50 else ('pajin','gwanak')
    enemy=eng.base.Fighter('가상 상대 · '+foe,previous.profile(level),weapon,['basic_attack','basic_defense',*skills],eng.base.STARTS[start][1])
    return hero,enemy


class Combat(eng.Combat):
    def __init__(self,*args,mask='full',information='committed',risk=1.3,horizon=40,**kwargs):
        super().__init__(*args,policy='efficient',**kwargs)
        self.mask_name=mask;self.allow_move,self.allow_guard,self.art_mask=MASKS[mask]
        self.pair_ids=tuple(self.fighters[0].arts[2:])
        chosen=self.pair_ids if self.art_mask=='AB' else (self.pair_ids[0 if self.art_mask=='A' else 1],)
        self.fighters[0].arts=['basic_attack']+(['basic_defense'] if self.allow_guard else [])+list(chosen)
        self.information=information;self.risk=risk;self.horizon=horizon;self.forecasting=False
        self.tactical_moves=0;self.active_guard_saved=0;self.hit_by_art=Counter();self.damage_by_art=Counter()
        self.move_labels={}

    def approach_distance(self,p):
        a=self.fighters[0]
        # Mandatory approach must still permit closing to a free basic attack
        # when the longer-range paid art is currently unaffordable.
        return min(self.ideal_distance(0,p,art) for art in a.arts
                   if art!='basic_defense' and self.budget.cost(art,a.weapon)<=a.qi)

    def moves(self):
        a=self.fighters[0];old=self.approach_distance(a.pos)
        result=[]
        for direction,delta in enumerate(eng.base.DIRS):
            p=eng.base.add(a.pos,delta)
            if self.can_step(0,p) and (self.allow_move or self.approach_distance(p)<old):
                result.append(('move',direction,p))
        return result

    def candidates(self):
        result=list(self.attack_options(0))
        # Also permit intercepting an already visible one-cell movement.
        enemy=self.fighters[1]
        if enemy.job and enemy.job.art=='move' and self.phase(enemy)!='recover':
            predicted=enemy.job.destination
            hero=self.fighters[0]
            for art in hero.arts:
                if art=='basic_defense' or self.budget.cost(art,hero.weapon)>hero.qi:continue
                for direction in range(4):
                    origin=hero.pos
                    if eng.CURRENT.get(art,{}).get('advance'):
                        origin=eng.base.add(origin,eng.base.DIRS[direction])
                        if not self.can_step(0,origin):continue
                    candidate=(art,direction,None)
                    if predicted in self.targets(0,art,direction,origin) and candidate not in result:result.append(candidate)
        result+=self.moves()
        if self.allow_guard:result.append(('basic_defense',0,None))
        result.append(('wait',0,None))
        return result

    def start(self,index,option):
        if index==0 and option[0]=='move':
            self.move_labels[self.t]=self.approach_distance(option[2])>=self.approach_distance(self.fighters[0].pos)
        return super().start(index,option)

    def resolve_moves(self):
        a=self.fighters[0];j=a.job;before=a.pos
        super().resolve_moves()
        if j and j.art=='move' and self.t==j.start+8 and a.pos!=before and self.move_labels.get(j.start,False):
            self.tactical_moves+=1

    def resolve_hits(self):
        a,b=self.fighters;j=a.job
        old_guard=a.guard_saved;old_hits=a.hit_count;old_damage=b.damage_taken
        active=j is not None and j.art=='basic_defense' and self.guard(a)>0
        super().resolve_hits()
        if active:self.active_guard_saved+=a.guard_saved-old_guard
        if j and a.hit_count>old_hits:
            self.hit_by_art[j.art]+=a.hit_count-old_hits
            self.damage_by_art[j.art]+=b.damage_taken-old_damage

    def fork(self):
        sim=object.__new__(type(self));sim.__dict__=self.__dict__.copy()
        sim.fighters=copy.deepcopy(self.fighters)
        for field in ('capacities','completed','support_ready','support_uses','special_restored','cap_waste','peak_qi','yield_until','yield_cooldown','chase_yields'):
            setattr(sim,field,list(getattr(self,field)))
        sim.history=[copy.deepcopy(h[-4:]) for h in self.history]
        sim.log=[];sim.frames=[];sim.record=False;sim.forecasting=True
        sim.hit_by_art=Counter(self.hit_by_art);sim.damage_by_art=Counter(self.damage_by_art);sim.move_labels=dict(self.move_labels)
        # Independent common random numbers for hypothetical futures, not the real RNG state.
        sim.rngs=[random.Random(1009+31*self.t),random.Random(2003+37*self.t)]
        sim.enemy_style='pressure'
        if self.information=='coarse':sim.mask_current_action()
        return sim

    def mask_current_action(self):
        enemy=self.fighters[1];j=enemy.job
        if not j or j.art in ('move','basic_defense'):return
        visible=self.visible(0)
        weapon=cat.WEAPONS.get(enemy.weapon,{}).get('weapon_type','none')
        level=self.fighters[0].stats['inner']
        if weapon=='saber':guess='hoepung' if visible['pose']=='wide' else 'danseok' if level==20 else 'paak' if level<=100 else 'bunag'
        elif weapon=='spear':guess='gwanpung' if level==20 else 'gwanak' if level==50 else 'pajin'
        else:guess='cheongpung' if level==20 else 'hoeryu' if level==50 else 'yuha'
        prep,active,recovery=cat.TIMINGS[guess];impact=prep+(2 if eng.CURRENT[guess].get('advance') else 0)
        phase=self.phase(enemy)
        if phase=='prepare':
            remaining=max(2,impact-visible['elapsed']);start=self.t+remaining-impact
        elif phase=='release':start=self.t-prep-1
        else:start=self.t-(prep+active+max(0,recovery//2))
        enemy.job=eng.Job(guess,start,j.direction,None,j.origin)

    def prior(self):
        options=self.candidates();attacks=[o for o in options if o[0] not in ('move','basic_defense','wait')]
        if attacks:return max(attacks,key=lambda o:self.attack_score(0,o))
        moves=[o for o in options if o[0]=='move']
        if moves:return min(moves,key=lambda o:(self.approach_distance(o[2]),eng.base.manhattan(o[2],self.fighters[1].pos)))
        return ('basic_defense',0,None) if self.allow_guard else ('wait',0,None)

    def evaluate(self,option):
        sim=self.fork();initial=[a.hp for a in self.fighters];start=self.t;deadline=start+self.horizon
        enemy=sim.fighters[1]
        # Both inputs use the old state when both actors are ready at this timestamp.
        enemy_command=eng.Combat.choose(sim,1) if enemy.job is None and start>=enemy.next_decision else None
        sim.start(0,option)
        if enemy_command is not None:sim.start(1,enemy_command)
        for t in range(start+1,deadline+1):
            sim.t=t;sim.resolve_moves();sim.resolve_hits()
            if any(a.hp<=0 for a in sim.fighters):break
            sim.finish()
            commands=[]
            for i,a in enumerate(sim.fighters):
                if a.job is None and t>=a.next_decision:
                    commands.append((i,sim.prior() if i==0 else eng.Combat.choose(sim,1)))
            for i,command in commands:sim.start(i,command)
        a,b=sim.fighters;ma=eng.base.health(a.stats);mb=eng.base.health(b.stats)
        elapsed=sim.t-start
        if a.hp<=0:return -2000+(300 if b.hp<=0 else 0)+.2*elapsed
        if b.hp<=0:return 2000+self.risk*100*a.hp/ma-.2*elapsed
        dealt=(initial[1]-b.hp)/mb;received=(initial[0]-a.hp)/ma
        paid=[art for art in a.arts if art not in ('basic_attack','basic_defense')]
        unit=max(1,min((self.budget.cost(art,a.weapon) for art in paid),default=a.stats['inner']))
        energy_value=4*(min(a.qi/unit,2)-min(self.fighters[0].qi/unit,2))
        position_value=1.5*(self.approach_distance(self.fighters[0].pos)-sim.approach_distance(a.pos))
        unfinished=.15*max(0,a.job.end-deadline) if a.job else 0
        return 100*dealt-self.risk*100*received+energy_value+position_value-unfinished

    def choose(self,index):
        if index==1:return eng.Combat.choose(self,index)
        if self.forecasting:return self.prior()
        choices=self.candidates()
        return max(choices,key=self.evaluate)

    def run(self,limit=500):
        r=super().run(limit)
        a,b=self.pair_ids
        r.update(tactical_moves=self.tactical_moves,active_guard_saved=self.active_guard_saved,
                 hits_A=self.hit_by_art[a],hits_B=self.hit_by_art[b],damage_A=self.damage_by_art[a],damage_B=self.damage_by_art[b],
                 actual_mix=self.tactical_moves>0 and self.active_guard_saved>0 and self.hit_by_art[a]>0 and self.hit_by_art[b]>0,
                 max_hp=eng.base.health(self.fighters[0].stats),
                 basic_count=r['actions'].get('basic_attack',0),guard_count=r['actions'].get('basic_defense',0),
                 move_count=r['actions'].get('move',0),wait_count=r['actions'].get('wait',0),
                 casts_A=r['actions'].get(a,0),casts_B=r['actions'].get(b,0))
        return r


def practical_better(a,b):
    if a['winner']=='hero' and b['winner']!='hero':return True
    if a['winner']!=b['winner'] or a['winner']!='hero':return False
    return ((a['hp']-b['hp']>=.1*a['max_hp'] and a['time']<=1.5*b['time'])
            or (a['hp']>=b['hp'] and a['time']<=.8*b['time']))

def analyse(rows):
    by_case={}
    for r in rows:
        key=tuple(r[k] for k in ('minimum','offset','level','foe','start','seed','information','risk'))
        by_case.setdefault(key,{})[r['mask']]=r
    aggregates={}
    for key,cases in by_case.items():
        full=cases['full'];group=f"{full['minimum']}/{full['offset']}/{full['level']}/{full['information']}/{full['risk']}"
        g=aggregates.setdefault(group,dict(n=0,full_wins=0,all_actions_used=0,all_actions_and_won=0,joint_practical_merit=0,
                  movement_merit=0,guard_merit=0,second_art_merit=0,practical_over_both_simple=0,
                  movement_regret=0,guard_regret=0))
        g['n']+=1;g['full_wins']+=full['winner']=='hero';g['all_actions_used']+=full['actual_mix'];g['all_actions_and_won']+=full['actual_mix'] and full['winner']=='hero'
        movement=practical_better(full,cases['no_reposition']);guard=practical_better(full,cases['no_guard'])
        second=practical_better(full,cases['only_A']) and practical_better(full,cases['only_B'])
        simple=practical_better(full,cases['simple_A']) and practical_better(full,cases['simple_B'])
        g['movement_merit']+=movement;g['guard_merit']+=guard;g['second_art_merit']+=second;g['practical_over_both_simple']+=simple
        g['movement_regret']+=practical_better(cases['no_reposition'],full);g['guard_regret']+=practical_better(cases['no_guard'],full)
        g['joint_practical_merit']+=full['actual_mix'] and movement and guard and second
    return aggregates


def run(pilot=False,exact50=False):
    rows=[];replays=[]
    floors=(50,) if exact50 else (100,) if pilot else (50,100)
    levels=(20,) if exact50 else (50,) if pilot else LEVELS
    offset=0 if exact50 else 40
    infos=('committed',) if pilot else ('committed','coarse')
    for minimum in floors:
        for level in levels:
            for foe in ('duelist','heavy','longreach'):
                for start in ((1,) if pilot else (0,1,3)):
                    for seed in ((0,) if pilot else (0,1)):
                        for info in infos:
                            for mask in MASKS:
                                record=not pilot and info=='committed' and seed==0 and start==1 and mask=='full'
                                sim=Combat(*pair(level,foe,start),budget=Budget(minimum=minimum,offset=offset),mask=mask,information=info,
                                           risk=1.3,horizon=40,enemy_style='pressure' if seed==0 else 'cautious',reaction=0,seed=seed,record=record)
                                result=sim.run()
                                row={k:result[k] for k in ('winner','time','tactical_moves','active_guard_saved','hits_A','hits_B','damage_A','damage_B','actual_mix','max_hp',
                                          'basic_count','guard_count','move_count','wait_count','casts_A','casts_B')}
                                row.update(minimum=minimum,offset=offset,level=level,foe=foe,start=start,seed=seed,information=info,risk=1.3,mask=mask,
                                           hp=result['hero_hp'],enemy_hp=result['boss_hp'],capacity=result['capacity'],art_A=PAIRS[level][0],art_B=PAIRS[level][1])
                                rows.append(row)
                                if record:replays.append(dict(case=row,frames=sim.frames,events=sim.log,history=sim.history))
                print('progress',minimum,level,foe,len(rows),flush=True)
    prefix='exact50' if exact50 else 'pilot' if pilot else 'results'
    with (HERE/(prefix+'.csv')).open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');w.writeheader();w.writerows(rows)
    output=dict(status='REVIEW ONLY — causal action-mask comparison under a finite-horizon controller',cases=len(rows),
                outcomes=dict(Counter(r['winner'] for r in rows)),pairs=analyse(rows),
                hashes={str(p.relative_to(HERE.parent)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [HERE/'experiment.py',
                        HERE.parent/'progression-combat-review/engine.py',HERE.parent/'progression-combat-review/catalogue.py',
                        HERE.parent/'progression-combat-review/benchmark.py',HERE.parent/'timed-qi-review/sweep.py',
                        HERE.parent/'timed-combat-review/simulate.py']})
    (HERE/(prefix+'.json')).write_text(json.dumps(output,ensure_ascii=False,indent=2))
    if replays:(HERE/(prefix+'-replays.json')).write_text(json.dumps(replays,ensure_ascii=False,separators=(',',':')))
    print('COMPLETE',prefix,len(rows),output['outcomes'],flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--pilot',action='store_true');parser.add_argument('--exact50',action='store_true')
    args=parser.parse_args();run(args.pilot,args.exact50)
