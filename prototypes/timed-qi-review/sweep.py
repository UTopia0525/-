#!/usr/bin/env python3
"""Review-only qi cost/cap sweep; unchanged recovery timing and combat timings.

Imports the previous review engine without rewriting its source, catalog, or results.
Every actor pays the same price table and obeys the same maximum qi.
"""
from __future__ import annotations

import argparse
import copy
import csv
import hashlib
import json
import math
import statistics
import sys
from collections import Counter
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / 'timed-combat-review'))
import simulate as base

ART_IDS = [k for k, v in base.ARTS.items() if v['grade'] == 'low']
PAID = set(base.ARTS)
POLICIES = ('strike_refill', 'move_refill', 'guard_refill', 'bank_burst')
POLICY_LABELS = {'strike_refill': '기본공격으로 회복', 'move_refill': '이동하며 회복',
                 'guard_refill': '방어하며 회복', 'bank_burst': '최대까지 모아 연속 공격'}
# Provisional absolute costs BEFORE the existing weapon discount.
PRICE_TABLES = {
    'A': dict(samjae=30, cheongpung=40, yusu=45, danseok=55, hoepung=65,
              gwanpung=70, yeonhwan=80, cheolsan=50, ungi=65),
    'B': dict(samjae=35, cheongpung=40, yusu=45, danseok=50, hoepung=60,
              gwanpung=65, yeonhwan=75, cheolsan=50, ungi=55),
    'C': dict(samjae=40, cheongpung=45, yusu=50, danseok=60, hoepung=70,
              gwanpung=75, yeonhwan=85, cheolsan=55, ungi=70),
    'D': dict(samjae=35, cheongpung=40, yusu=45, danseok=55, hoepung=60,
              gwanpung=60, yeonhwan=70, cheolsan=55, ungi=55),
}


@dataclass(frozen=True)
class Budget:
    name: str
    cap: int
    multiplier: int = 1
    table: str = ''

    def cost(self, art, weapon):
        if art not in PAID: return 0
        definition = base.ARTS[art]
        price = PRICE_TABLES[self.table][art] if self.table else definition['qi_cost'] * self.multiplier
        w = base.WEAPONS.get(weapon, {})
        discount = w.get('qi_reduction_percent', 0) if definition['required_weapon_type'] == w.get('weapon_type') else 0
        return math.ceil(price * (100 - discount) / 100)


def max_chain(cap, price, recovery):
    """Maximum paid casts from a FULL bar, including recovery after each cast."""
    if price > cap: return 0
    if price <= recovery: return 'unlimited'
    return 1 + (cap - price) // (price - recovery)


@lru_cache(maxsize=16384)
def footprint(art, direction, origin):
    return frozenset(base.add(origin, base.rotate(o, direction)) for o in base.offsets(art))


class EnergyCombat(base.Combat):
    def __init__(self, *args, budget, refill_policy='strike_refill', **kwargs):
        super().__init__(*args, policy='efficient', **kwargs)
        self.budget = budget
        self.refill_policy = refill_policy
        self.banking = True
        self.history = [[], []]
        self._distance_cache = {}
        self.cap_waste = [0, 0]
        self.peak_qi = [0, 0]
        self.yield_until = [0, 0]
        self.yield_cooldown = [0, 0]
        self.chase_yields = [0, 0]
        for i, a in enumerate(self.fighters):
            a.qi = min(a.qi, budget.cap)
            self.peak_qi[i] = a.qi

    def targets(self, index, art, direction, origin=None):
        return footprint(art, direction, self.fighters[index].pos if origin is None else origin)

    def ideal_distance(self, index, p, preferred=None):
        key = (index, p, preferred, self.fighters[1-index].pos)
        if key not in self._distance_cache:
            self._distance_cache[key] = super().ideal_distance(index, p, preferred)
        return self._distance_cache[key]

    def attack_options(self, index):
        a, b = self.fighters[index], self.fighters[1-index]
        options = []
        for art in a.arts:
            if art == 'basic_defense' or a.qi < self.budget.cost(art, a.weapon): continue
            for direction in range(4):
                origin = a.pos
                if base.TACTICS[art].get('advance', 0):
                    origin = base.add(origin, base.DIRS[direction])
                    if not self.can_step(index, origin): continue
                if b.pos in self.targets(index, art, direction, origin):
                    options.append((art, direction, None))
        return options

    def start(self, index, option):
        a = self.fighters[index]
        art = option[0]
        price = self.budget.cost(art, a.weapon)
        assert a.qi >= price
        before = a.qi
        # Base validates movement/learning and pays the old price. Replace only that price.
        super().start(index, option)
        if art != 'wait': a.qi -= price - base.cost(art, a.weapon)
        assert 0 <= a.qi <= self.budget.cap
        self.history[index].append(dict(t=self.t, art=art, qi_before=before, price=price, qi_after=a.qi, origin=a.pos))
        self.log_event('qi_spend', actor=index, art=art, price=price, qi=a.qi)

    def finish(self):
        # Recovery amount AND timing stay identical: inner power, after complete recovery phase.
        for i, a in enumerate(self.fighters):
            if a.job and self.t == a.job.end:
                before = a.qi
                a.qi = min(self.budget.cap, a.qi + a.stats['inner'])
                actual = a.qi - before
                self.cap_waste[i] += a.stats['inner'] - actual
                self.peak_qi[i] = max(self.peak_qi[i], a.qi)
                a.qi_recovered += actual
                if a.job.art == 'move': a.move_qi_recovered += actual
                self.log_event('finish', actor=i, art=a.job.art, qi=a.qi, hp=a.hp)
                a.job = None

    def recharge_step(self, index=0):
        a, b = self.fighters[index], self.fighters[1-index]
        options = [('move', d, base.add(a.pos, delta)) for d, delta in enumerate(base.DIRS)
                   if self.can_step(index, base.add(a.pos, delta))]
        alternatives = [o for o in options if o[2] != a.blocked_step]
        if alternatives: options = alternatives
        if not options: return ('basic_defense', 0, None)
        # Flee a visible threat; otherwise keep distance while qi is insufficient.
        def score(o):
            p = o[2]
            return (not self.known_threat(index, p), base.manhattan(p, b.pos), -self.ideal_distance(index, p))
        best = max(map(score, options))
        return self.rngs[index].choice([o for o in options if score(o) == best])

    def choose(self, index):
        if self.refill_policy == 'legacy': return super().choose(index)
        if self.t < self.yield_until[index]: return ('wait', 0, None)
        # Symmetric observable-history correction: stop chasing a previous square forever.
        # Yield one movement duration so the other fighter can finish an approach.
        recent = self.history[index][-4:]
        if (len(recent)==4 and all(h['art']=='move' for h in recent)
                and len({h['origin'] for h in recent})<=2 and self.t>=self.yield_cooldown[index]
                and self.rngs[index].random()<.5):
            self.yield_until[index]=self.t+10;self.yield_cooldown[index]=self.t+40
            self.chase_yields[index]+=1
            return ('wait',0,None)
        if index == 1: return super().choose(index)
        a = self.fighters[index]
        options = self.attack_options(index)
        paid = [o for o in options if o[0] in PAID]
        # Unaffordable and out-of-range are separate. Never kite just because an attack is distant.
        affordable = [art for art in a.arts if art in PAID and self.budget.cost(art, a.weapon) <= a.qi]
        if self.refill_policy == 'bank_burst':
            if self.banking and a.qi < self.budget.cap: return self.recharge_step()
            self.banking = False
            if not affordable:
                self.banking = True
                return self.recharge_step()
        if paid: return max(paid, key=lambda o: self.attack_score(index, o))
        if affordable: return self.approach(index)
        if self.refill_policy in ('move_refill', 'bank_burst'): return self.recharge_step()
        if self.refill_policy == 'guard_refill': return ('basic_defense', 0, None)
        basics = [o for o in options if o[0] == 'basic_attack']
        return basics[0] if basics else self.approach(index, 'basic_attack')

    def run(self, limit=800):
        result = super().run(limit)
        history = self.history[0]
        paid_indices = [i for i, h in enumerate(history) if h['art'] in PAID]
        gaps = [history[a+1:b] for a, b in zip(paid_indices, paid_indices[1:])]
        streak = longest = 0
        for h in history:
            streak = streak + 1 if h['art'] in PAID else 0
            longest = max(longest, streak)
        result.update(paid_casts=len(paid_indices), paid_chain=longest,
                      move_gaps=sum(any(h['art'] == 'move' for h in gap) for gap in gaps),
                      free_gaps=sum(bool(gap) for gap in gaps),
                      precharge_moves=sum(h['art'] == 'move' for h in history[:paid_indices[0] if paid_indices else len(history)]),
                      peak_qi=self.peak_qi[0], cap_waste=self.cap_waste[0],
                      chase_yields=self.chase_yields[0],
                      enemy_paid_casts=sum(h['art'] in PAID for h in self.history[1]),
                      enemy_qi=self.fighters[1].qi)
        return result


def configs():
    result = [Budget('baseline', 500)]
    for multiplier in (2, 3, 4, 5, 6):
        for cap in (40, 60, 80, 100, 120, 160, 200, 240):
            result.append(Budget(f'x{multiplier}-cap{cap}', cap, multiplier))
    for table in PRICE_TABLES:
        for cap in (60, 65, 70, 75, 80, 85, 90, 100, 120):
            result.append(Budget(f'{table}-cap{cap}', cap, table=table))
    return result


def aggregate(rows):
    return dict(n=len(rows), wins=sum(r['winner']=='hero' for r in rows),
                losses=sum(r['winner']=='boss' for r in rows), draws=sum(r['winner']=='draw' for r in rows),
                timeouts=sum(r['winner']=='timeout' for r in rows),
                median_hp=statistics.median(r['hero_hp'] for r in rows),
                median_time=statistics.median(r['time'] for r in rows),
                median_casts=statistics.median(r['paid_casts'] for r in rows),
                median_chain=statistics.median(r['paid_chain'] for r in rows),
                median_move_gaps=statistics.median(r['move_gaps'] for r in rows),
                median_enemy_casts=statistics.median(r['enemy_paid_casts'] for r in rows),
                median_precharge=statistics.median(r['precharge_moves'] for r in rows),
                total_move_gaps=sum(r['move_gaps'] for r in rows))


def measure(budgets, seeds, stage):
    rows, rejected, replays = [], [], []
    for budget in budgets:
        before = len(rows)
        for art in ART_IDS:
            hero, _ = base.make_fighters(art)
            if budget.cost(art, hero.weapon) > budget.cap:
                rejected.append(dict(stage=stage, config=budget.name, art=art, price=budget.cost(art,hero.weapon), cap=budget.cap))
                continue
            for policy in POLICIES:
                for start in range(6):
                    for style in ('pressure', 'cautious', 'erratic'):
                        for seed in seeds:
                            record = stage=='refined' and budget.name in ('B-cap70','D-cap80') and art in ('danseok','gwanpung','ungi','cheongpung') and start==0 and style=='pressure' and seed==0
                            sim = EnergyCombat(*base.make_fighters(art, start), budget=budget, refill_policy=policy,
                                               enemy_style=style, reaction=3, seed=seed, record=record)
                            r = sim.run()
                            row = {k:r[k] for k in ('winner','time','hero_hp','boss_hp','hero_max_hp','hero_qi','paid_casts','paid_chain',
                                'move_gaps','free_gaps','precharge_moves','peak_qi','cap_waste','chase_yields','enemy_paid_casts','enemy_qi','boss_misses')}
                            row.update(stage=stage, config=budget.name, art=art, policy=policy, start=start, style=style, seed=seed,
                                       moves=r['actions'].get('move',0), basics=r['actions'].get('basic_attack',0), guards=r['actions'].get('basic_defense',0))
                            rows.append(row)
                            if record:
                                replays.append(dict(config=budget.name,art=art,policy=policy,result=r,history=sim.history,events=sim.log,frames=sim.frames))
        print(f'{stage} {budget.name}: {len(rows)-before} cases', flush=True)
    return rows, rejected, replays


def summarise(rows):
    groups = {}
    for r in rows:
        key = '/'.join((r['stage'],r['config'],r['art'],r['policy']))
        groups.setdefault(key,[]).append(r)
    return {key:aggregate(value) for key,value in groups.items()}


def write_csv(rows, file):
    if not rows: return
    with file.open('w',encoding='utf-8-sig',newline='') as output:
        writer=csv.DictWriter(output, fieldnames=list(rows[0]), lineterminator='\n')
        writer.writeheader();writer.writerows(rows)


def analyze_pairs(rows):
    lookup = {(r['stage'],r['config'],r['art'],r['start'],r['style'],r['seed'],r['policy']):r for r in rows}
    groups = {}
    for r in rows:
        if r['policy'] != 'move_refill': continue
        key=(r['stage'],r['config'],r['art'],r['start'],r['style'],r['seed'])
        strike=lookup[key+('strike_refill',)]
        bank=lookup[key+('bank_burst',)]
        wins_better = r['winner']=='hero' and strike['winner']!='hero'
        safety_better = r['winner']==strike['winner']=='hero' and r['hero_hp']-strike['hero_hp']>=.1*r['hero_max_hp'] and r['time']<=1.5*strike['time']
        # A successful attack/recharge cycle must actually occur, not just a single opening attack.
        useful = (wins_better or safety_better) and r['move_gaps']>=1
        bank_dominates = bank['winner']=='hero' and (r['winner']!='hero' or (bank['hero_hp']>=r['hero_hp'] and bank['time']<=r['time'] and (bank['hero_hp']>r['hero_hp'] or bank['time']<r['time'])))
        gkey='/'.join(key[:3]);g=groups.setdefault(gkey,dict(n=0,move_win_gain=0,move_win_loss=0,safety_gain=0,useful_cycles=0,bank_dominates=0))
        g['n']+=1;g['move_win_gain']+=wins_better;g['move_win_loss']+=r['winner']!='hero' and strike['winner']=='hero'
        g['safety_gain']+=safety_better;g['useful_cycles']+=useful;g['bank_dominates']+=bank_dominates
    return groups


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--stage',choices=('coarse','refined'),default='coarse')
    parser.add_argument('--configs',default='')
    args=parser.parse_args()
    available=configs()
    if args.configs:
        requested=set(args.configs.split(','));available=[b for b in available if b.name in requested]
        assert {b.name for b in available}==requested
    elif args.stage=='refined':
        requested={'baseline','B-cap65','B-cap70','B-cap75','B-cap80','C-cap80','C-cap85','C-cap90','x3-cap120',
                   'D-cap70','D-cap75','D-cap80','D-cap85','D-cap90'}
        available=[b for b in available if b.name in requested]
    rows,rejected,replays=measure(available,(0,) if args.stage=='coarse' else (0,1,2),args.stage)
    analytical=[]
    for b in available:
        for art in ['samjae']+ART_IDS:
            hero,_=base.make_fighters('cheongpung' if art=='samjae' else art)
            price=b.cost(art,hero.weapon);recovery=hero.stats['inner']
            analytical.append(dict(config=b.name,art=art,cost=price,recovery=recovery,cap=b.cap,
                maximum_chain=max_chain(b.cap,price,recovery),
                free_actions_if_only_recovery_remains=max(0,math.ceil(price/recovery)-1),
                can_use=price<=b.cap))
    metadata=dict(status='REVIEW ONLY; recovery after full action unchanged; no Godot edits',
        configs=[b.__dict__ for b in available],cost_tables=PRICE_TABLES,
        source_hashes={name:hashlib.sha256((base.ROOT/'godot/data'/f'{name}.json').read_bytes()).hexdigest() for name in base.FILES},
        engine_sha256=hashlib.sha256(Path(base.__file__).read_bytes()).hexdigest(),
        sweep_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        cases=len(rows),outcomes=dict(Counter(r['winner'] for r in rows)),rejected=rejected,
        summary=summarise(rows),pairs=analyze_pairs(rows),analytical=analytical)
    (HERE/f'{args.stage}-summary.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2))
    write_csv(rows,HERE/f'{args.stage}-results.csv')
    if replays:(HERE/'replays.json').write_text(json.dumps(replays,ensure_ascii=False,separators=(',',':')))
    print('COMPLETE',args.stage,len(rows),metadata['outcomes'],flush=True)


if __name__=='__main__':main()
