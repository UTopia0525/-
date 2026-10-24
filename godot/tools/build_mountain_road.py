"""Deterministic NPC-free route. Run from repository root."""
import json,random,math
from pathlib import Path
points=[[80,2350],[360,2350],[720,2350],[720,2140],[600,1900],[735,1650],[630,1400],[760,1150],[650,900],[760,650],[700,390],[740,80]]
d={'name':'장사–무창 산길','art_size':[1024,2560],'world_size':[4096,10240],'spawn':[125,2350],'walk_bounds':[0,0,1024,2560],'route':points,'half_width':49,'ground_script':'res://scripts/mountain_road_ground.gd','ground_texture':'res://assets/maps/changsha-wuchang/ground.png','npcs':[],'objects':[],'districts':[
 {'name':'장사 방면 · 동쪽 고갯길','rect':[0,2200,1024,360],'label':[410,2460]},
 {'name':'남쪽 굽잇길','rect':[0,1750,1024,450],'label':[710,2050]},
 {'name':'바위 능선길','rect':[0,1200,1024,550],'label':[710,1500]},
 {'name':'청풍 고개','rect':[0,650,1024,550],'label':[720,1000]},
 {'name':'무창 방면 · 북쪽 내리막','rect':[0,0,1024,650],'label':[700,260]}],
 'prefabs':{'rock':{'texture':'res://assets/maps/changsha-wuchang/rock.png','source':[0,0,1536,1024],'kind':'rock','footprints':[[.12,.55,.76,.39]]}}}
# Borders of the route are physically closed. Props remain separate and outside foot corridor.
rng=random.Random(511)
def segment_distance(point,a,b):
 dx,dy=b[0]-a[0],b[1]-a[1]
 t=max(0,min(1,((point[0]-a[0])*dx+(point[1]-a[1])*dy)/(dx*dx+dy*dy)))
 return math.dist(point,(a[0]+t*dx,a[1]+t*dy))
for i in range(105):
 y=rng.uniform(60,2490);x=rng.uniform(70,965)
 distance=min(segment_distance((x,y),a,b) for a,b in zip(points,points[1:]))
 if distance<115:continue
 prefab='rock' if i%3==0 else 'tree'
 w=rng.uniform(82,130) if prefab=='rock' else rng.uniform(58,92);h=w*(.72 if prefab=='rock' else 1.08)
 d['objects'].append({'id':f'{prefab}_{i}','prefab':prefab,'rect':[round(x-w/2,1),round(y-h,1),round(w,1),round(h,1)]})
# Deliberate rock cuts at bends keep relief visible from the player's camera.
for i,rect in enumerate([[460,1325,130,92],[730,1430,150,104],[430,1820,145,104],[810,1580,145,104],[520,300,145,104],[350,2190,140,100]]):
 d['objects'].append({'id':f'road_cut_{i}','prefab':'rock','rect':rect})
# Halve north/south distances, preserving sprite dimensions and the path width.
d['art_size'][1]=1280;d['world_size'][1]=5120;d['walk_bounds'][3]=1280
d['spawn'][1]/=2
for point in d['route']:point[1]/=2
# Keep the northern round end fully inside the map and arrivals away from the exit.
d['route'][-1][1]=64
for district in d['districts']:
 district['rect'][1]/=2;district['rect'][3]/=2;district['label'][1]/=2
for obj in d['objects']:
 x,y,w,h=obj['rect'];obj['rect'][1]=round((y+h)/2-h,1)
Path('godot/assets/maps/changsha-wuchang/layout.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
print(len(d['objects']),'mountain props')
