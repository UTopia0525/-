#!/usr/bin/env python3
"""Early-game affordable-cap control: identical power/time, all low arts fit50."""
import csv
import json
import math
from dataclasses import dataclass
from collections import Counter
import experiment as e


@dataclass(frozen=True)
class AffordableBudget(e.Budget):
    def cost(self,art,weapon):
        if art not in e.eng.CURRENT:return 0
        d=e.eng.CURRENT[art]
        price=math.ceil(d['qi_cost']*.7)
        w=e.cat.WEAPONS.get(weapon,{})
        discount=w.get('qi_reduction_percent',0) if d['required_weapon_type']==w.get('weapon_type') else 0
        return math.ceil(price*(100-discount)/100)


def run():
    rows=[]
    for cap in (50,100):
        for foe in ('duelist','heavy','longreach'):
            for start in (0,1,3):
                for seed in (0,1):
                    for info in ('committed','coarse'):
                        for mask in e.MASKS:
                            budget=AffordableBudget(minimum=cap,offset=0)
                            sim=e.Combat(*e.pair(20,foe,start),budget=budget,mask=mask,information=info,
                                         enemy_style='pressure' if seed==0 else 'cautious',seed=seed,reaction=0,risk=1.3,horizon=40)
                            assert all(budget.cost(art,a.weapon)<=budget.capacity(20) for a in sim.fighters for art in a.arts)
                            result=sim.run()
                            row={k:result[k] for k in ('winner','time','tactical_moves','active_guard_saved','hits_A','hits_B','damage_A','damage_B',
                                         'actual_mix','max_hp','basic_count','guard_count','move_count','wait_count','casts_A','casts_B')}
                            row.update(minimum=cap,offset=0,level=20,foe=foe,start=start,seed=seed,information=info,risk=1.3,mask=mask,
                                       hp=result['hero_hp'],enemy_hp=result['boss_hp'],capacity=result['capacity'],art_A='cheongpung',art_B='yusu',cost_scale=.7)
                            rows.append(row)
            print('progress affordable',cap,foe,len(rows),flush=True)
    with (e.HERE/'cost-probe.csv').open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');w.writeheader();w.writerows(rows)
    (e.HERE/'cost-probe.json').write_text(json.dumps(dict(cases=len(rows),outcomes=dict(Counter(r['winner'] for r in rows)),pairs=e.analyse(rows)),ensure_ascii=False,indent=2))
    print('COMPLETE affordable',len(rows),flush=True)


if __name__=='__main__':run()
