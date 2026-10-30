"""Isolated extension of the prior integer-clock review engines, not Godot runtime."""
import copy
import importlib.util
import math
import sys
from dataclasses import dataclass
from pathlib import Path
import catalogue as cat

HERE=Path(__file__).resolve().parent

def load_private(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec);sys.modules[name]=module;spec.loader.exec_module(module)
    return module

base=load_private('_progression_clock',HERE.parent/'timed-combat-review/simulate.py')
previous=sys.modules.get('simulate')
try:
    sys.modules['simulate']=base
    energy=load_private('_progression_energy',HERE.parent/'timed-qi-review/sweep.py')
finally:
    if previous is None:sys.modules.pop('simulate',None)
    else:sys.modules['simulate']=previous

CURRENT=None

def install(mode='graded'):
    global CURRENT
    CURRENT=cat.catalogue(mode)
    base.ARTS=copy.deepcopy(CURRENT)
    base.TIMING=copy.deepcopy(cat.TIMINGS)
    base.TACTICS=copy.deepcopy(cat.TACTICS)
    for key,d in CURRENT.items():
        base.TACTICS[key]={k:copy.deepcopy(d[k]) for k in ('attack_offsets','advance','retreat','push')}
        base.TACTICS[key]['action_cost']=0
    base.LABELS.update({key:d['name'] for key,d in CURRENT.items()})
    energy.PAID=set(CURRENT)-{'josik_suwon'}
    energy.footprint.cache_clear()

install()

@dataclass(frozen=True)
class Budget:
    formula:str='floor80_40_2I'
    mid_scale:float=1
    upper_scale:float=1
    cap:int=0  # Interface placeholder; each actor has a distinct cap in this review.

    def capacity(self,inner):return cat.FORMULAS[self.formula](inner)
    def cost(self,art,weapon):
        if art not in CURRENT:return 0
        d=CURRENT[art]
        scale=self.mid_scale if d['grade']=='intermediate' else self.upper_scale if d['grade']=='upper' else 1
        value=math.ceil(d['qi_cost']*scale)
        w=cat.WEAPONS.get(weapon,{})
        discount=w.get('qi_reduction_percent',0) if d['required_weapon_type']==w.get('weapon_type') else 0
        return math.ceil(value*(100-discount)/100)


@dataclass
class Job:
    art:str
    start:int
    direction:int=0
    destination:tuple|None=None
    origin:tuple=(0,0)

    @property
    def impact(self):return self.start+cat.TIMINGS[self.art][0]+(2 if CURRENT.get(self.art,{}).get('advance',0) else 0)
    @property
    def end(self):return self.start+sum(cat.TIMINGS[self.art])


class Combat(energy.EnergyCombat):
    def __init__(self,hero,enemy,budget=Budget(),policy='efficient',**kwargs):
        # Parent needs a scalar during setup; replace only with actor-specific capacities afterward.
        bootstrap=energy.Budget('bootstrap',1000)
        super().__init__(hero,enemy,budget=bootstrap,refill_policy='strike_refill',**kwargs)
        self.budget=budget;self.plan=policy
        self.capacities=[budget.capacity(a.stats['inner']) for a in self.fighters]
        self.completed=[0,0];self.support_ready=[0,0]
        self.support_uses=[0,0];self.special_restored=[0,0]
        for i,a in enumerate(self.fighters):
            a.qi=min(a.stats['inner'],self.capacities[i]);self.peak_qi[i]=a.qi

    def visible(self,observer):
        view=super().visible(observer)
        a=self.fighters[1-observer]
        if view['kind']=='attack' and a.job:
            if a.job.art=='josik_suwon':view['kind']='guard';view['pose']='none'
            elif a.job.art in CURRENT:
                offsets=CURRENT[a.job.art]['attack_offsets']
                view['pose']='wide' if any(o[0]<0 for o in offsets) else 'spread' if any(o[1] for o in offsets) else 'line'
        return view

    def start(self,index,option):
        a=self.fighters[index];art,direction,dest=option
        assert a.job is None and self.t>=a.next_decision
        price=self.budget.cost(art,a.weapon)
        assert a.qi>=price
        before=a.qi
        if art=='wait':a.next_decision=self.t+2
        else:
            assert art=='move' or art in a.arts
            if art=='move':assert self.can_step(index,dest) and base.manhattan(a.pos,dest)==1
            if art=='josik_suwon':
                assert self.completed[index]>=self.support_ready[index]
                # The three OTHER completed actions after this support action must pass.
                self.support_ready[index]=self.completed[index]+4;self.support_uses[index]+=1
            a.qi-=price;a.job=Job(art,self.t,direction,dest,a.pos)
            if art=='move':a.last_move=self.t
        a.actions.append(art);a.previous=art
        self.history[index].append(dict(t=self.t,art=art,qi_before=before,price=price,qi_after=a.qi,origin=a.pos))
        self.log_event('start',actor=index,art=art,direction=direction,destination=dest,qi=a.qi,price=price,
                       impact=a.job.impact if a.job and art not in ('move','basic_defense','josik_suwon') else None,
                       end=a.job.end if a.job else a.next_decision)

    def finish(self):
        for i,a in enumerate(self.fighters):
            if a.job and self.t==a.job.end:
                extra=2*a.stats['inner'] if a.job.art=='josik_suwon' else 0
                before=a.qi
                a.qi=min(self.capacities[i],a.qi+a.stats['inner']+extra)
                actual=a.qi-before
                self.cap_waste[i]+=a.stats['inner']+extra-actual
                self.peak_qi[i]=max(self.peak_qi[i],a.qi)
                a.qi_recovered+=actual
                self.special_restored[i]+=max(0,actual-a.stats['inner'])
                if a.job.art=='move':a.move_qi_recovered+=actual
                self.completed[i]+=1
                self.log_event('finish',actor=i,art=a.job.art,qi=a.qi,hp=a.hp,normal=a.stats['inner'],extra=extra)
                a.job=None

    def resolve_moves(self):
        destinations={}
        for i,a in enumerate(self.fighters):
            j=a.job
            if not j:continue
            prep,active,_=cat.TIMINGS[j.art];d=CURRENT.get(j.art,{})
            if j.art=='move' and self.t==j.start+prep+active:destinations[i]=j.destination
            elif d.get('advance') and self.t==j.start+prep+2:destinations[i]=base.add(a.pos,base.DIRS[j.direction])
            elif d.get('retreat') and self.t==j.start+prep+active:destinations[i]=base.add(a.pos,base.rotate((-1,0),j.direction))
        valid={i:p for i,p in destinations.items() if self.can_step(i,p)}
        if len(valid)==2 and valid[0]==valid[1]:valid={}
        for i,p in destinations.items():self.fighters[i].blocked_step=None if i in valid else p
        for i,p in valid.items():
            self.fighters[i].pos=p;self.log_event('move',actor=i,destination=p)
        assert self.fighters[0].pos!=self.fighters[1].pos

    def resolve_hits(self):
        # Base hit resolver assumes every non-basic-defense job attacks. Temporarily hide support.
        hidden=[]
        for a in self.fighters:
            if a.job and a.job.art=='josik_suwon':hidden.append((a,a.job));a.job=None
        self._support_guard_jobs={id(a):j for a,j in hidden}
        try:super().resolve_hits()
        finally:
            for a,j in hidden:a.job=j
            self._support_guard_jobs={}

    def guard(self,a):
        support=getattr(self,'_support_guard_jobs',{}).get(id(a),a.job)
        if support and support.art=='josik_suwon':
            return 20 if support.start+4<=self.t<support.start+14 else 0
        return super().guard(a)

    def attack_score(self,index,option,punish=False):
        art=option[0];a=self.fighters[index]
        if self.plan=='heavy' and index==0:return base.raw(art,a.stats,a.weapon)
        return base.raw(art,a.stats,a.weapon)/sum(cat.TIMINGS[art])

    def support_choice(self,index):
        a=self.fighters[index]
        if 'josik_suwon' not in a.arts or self.completed[index]<self.support_ready[index]:return None
        if self.visible(index)['kind']=='attack' and self.known_threat(index):return None
        costs=[self.budget.cost(art,a.weapon) for art in a.arts if art in energy.PAID and self.budget.cost(art,a.weapon)<=self.capacities[index]]
        if costs and min(costs)>a.qi and a.stats['inner']>0:
            target=min(costs);recovery=a.stats['inner']
            normal_steps=math.ceil((target-a.qi)/recovery)
            after=min(self.capacities[index],a.qi+3*recovery)
            remaining=math.ceil(max(0,target-after)/recovery)
            if sum(cat.TIMINGS['josik_suwon'])+10*remaining<10*normal_steps:
                return ('josik_suwon',0,None)
        return None

    def choose(self,index):
        if self.t<self.yield_until[index]:return ('wait',0,None)
        recent=self.history[index][-4:]
        if (len(recent)==4 and all(h['art']=='move' for h in recent)
              and len({h['origin'] for h in recent})<=2 and self.t>=self.yield_cooldown[index]
              and self.rngs[index].random()<.5):
            self.yield_until[index]=self.t+10;self.yield_cooldown[index]=self.t+40;self.chase_yields[index]+=1
            return ('wait',0,None)
        support=self.support_choice(index)
        if support:return support
        a=self.fighters[index];options=self.attack_options(index)
        paid=[o for o in options if o[0] in energy.PAID]
        if (index==0 and self.plan=='mobile') or (index==1 and self.enemy_style=='cautious'):
            defensive=self.defense_choice(index,options)
            if defensive:return defensive
        if paid:
            if index==1 and self.enemy_style=='erratic':
                return self.rngs[index].choices(paid,weights=[self.attack_score(index,o) for o in paid])[0]
            return max(paid,key=lambda o:self.attack_score(index,o))
        affordable=[art for art in a.arts if art in energy.PAID and self.budget.cost(art,a.weapon)<=a.qi]
        if affordable:return self.approach(index)
        if index==0 and self.plan=='mobile':return self.recharge_step(index)
        basics=[o for o in options if o[0]=='basic_attack']
        return basics[0] if basics else self.approach(index,'basic_attack')

    def run(self,limit=1200):
        result=super().run(limit)
        result.update(capacity=self.capacities[0],enemy_capacity=self.capacities[1],
                      support_uses=self.support_uses[0],special_restored=self.special_restored[0],
                      art_counts=dict(__import__('collections').Counter(self.fighters[0].actions)))
        return result
