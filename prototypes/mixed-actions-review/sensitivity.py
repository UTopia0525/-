#!/usr/bin/env python3
"""Common-controller horizon sensitivity. REVIEW ONLY; no parameter tuning."""
import csv
import json
from collections import Counter
import experiment as e


def run():
    rows=[];groups={}
    for horizon in (20,60):
        part=[]
        for level in e.LEVELS:
            for foe in ('duelist','heavy','longreach'):
                for info in ('committed','coarse'):
                    for mask in e.MASKS:
                        sim=e.Combat(*e.pair(level,foe,1),budget=e.Budget(minimum=100),mask=mask,
                                     information=info,horizon=horizon,risk=1.3,enemy_style='pressure',reaction=0,seed=0)
                        result=sim.run()
                        r={k:result[k] for k in ('winner','time','tactical_moves','active_guard_saved','hits_A','hits_B',
                             'damage_A','damage_B','actual_mix','max_hp','basic_count','guard_count','move_count','wait_count','casts_A','casts_B')}
                        r.update(minimum=100,offset=40,level=level,foe=foe,start=1,seed=0,information=info,risk=1.3,
                                 mask=mask,hp=result['hero_hp'],enemy_hp=result['boss_hp'],capacity=result['capacity'],
                                 art_A=e.PAIRS[level][0],art_B=e.PAIRS[level][1],horizon=horizon)
                        part.append(r)
            print('progress horizon',horizon,'level',level,flush=True)
        groups[str(horizon)]=e.analyse(part);rows.extend(part)
    with (e.HERE/'sensitivity.csv').open('w',encoding='utf-8-sig',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');writer.writeheader();writer.writerows(rows)
    (e.HERE/'sensitivity.json').write_text(json.dumps(dict(cases=len(rows),outcomes=dict(Counter(r['winner'] for r in rows)),pairs=groups),ensure_ascii=False,indent=2))
    print('COMPLETE sensitivity',len(rows),flush=True)


if __name__=='__main__':run()
