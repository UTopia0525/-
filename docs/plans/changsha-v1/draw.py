"""Render a cheap schematic from planning data. Does not use or modify game assets."""
import os
os.environ.setdefault('MPLCONFIGDIR','/tmp/changsha-plan-mpl')
import json
from pathlib import Path
from collections import deque
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Polygon
from matplotlib.path import Path as MPath
from matplotlib.font_manager import FontProperties

ROOT=Path(__file__).resolve().parent
D=json.loads((ROOT/'plan.json').read_text(encoding='utf-8'))
FONT=FontProperties(fname='/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc')
plt.rcParams['font.family']=FONT.get_name()
plt.rcParams['axes.unicode_minus']=False
COLORS=dict(warehouse='#d9bd6b',market='#f1ab65',office='#b79acb',martial='#db8987',inn='#7ca9cb',workshop='#bb977b',house='#98bf94')
fig=plt.figure(figsize=(14.5,11.5),facecolor='#fbfaf7')
ax=fig.add_axes([.055,.085,.735,.825]);ax.set_aspect('equal');ax.set_xlim(0,100);ax.set_ylim(0,100);ax.set_facecolor('#e9e4d7')
def text(x,y,s,size=9,**kw):return ax.text(x,y,s,fontproperties=FONT,fontsize=size,ha=kw.pop('ha','center'),va='center',zorder=12,**kw)
def rect(r,color,**kw):return ax.add_patch(Rectangle(r[:2],r[2],r[3],facecolor=color,**kw))
def line(points,color,width,z=5):ax.plot(*zip(*points),color=color,lw=width,solid_capstyle='butt',solid_joinstyle='miter',zorder=z)
# Ground and water are planned before facilities.
rect([22,16,70,68],'#f3f0e5',zorder=0)
ax.add_patch(Polygon(D['river'],facecolor='#94c9e0',edgecolor='#5c9db7',zorder=1))
for points in [[[25,90],[31,89],[33,93],[32,97],[25,97]],[[33,89],[43,90],[44,97],[34,97]]]:
 ax.add_patch(Polygon(points,facecolor='#a8d3b5',edgecolor='#688f72',zorder=2))
for points in [[[58,89],[65,90],[65,97],[58,97]],[[66,90],[75,89],[76,97],[67,97]]]:
 ax.add_patch(Polygon(points,facecolor='#d1cf91',edgecolor='#a39b5c',zorder=2))
text(35,94,'논',11);text(67,94,'밭·채소',10)
# Meaningful unbuilt spaces; also used for inexpensive connectivity sanity checks.
areas=[([26,53,17,7],'#e7dcc0','하역마당',(33,57)),([55,51,21,16],'#f6e6cd','',(0,0)),([35,28,6.5,14],'#e8d4bf','공동\n작업장',(38.3,34)),([39,18,6,8],'#dfe9ed','',(0,0)),([56,72,16,9],'#f0dddd','',(0,0)),([64,73,7,7],'#e7c8c4','연무장',(67.5,77)),([77,72,11,4],'#e6dfed','관아 앞마당',(82.5,73.5)),([56,20,34,22],'#e8eedf','',(0,0)),([68,34,9,7],'#dae6cf','',(0,0)),([26,75,17,6],'#e7e0cb','장날 대기마당',(34.5,78)),([77,88,3,8],'#e9dfc7','',(0,0)),([14.5,50,7,5.5],'#dac9ab','',(0,0)),([11.5,43,8.5,6],'#c2a582','',(0,0))]
for r,c,label,p in areas:
 rect(r,c,zorder=2)
 if label:text(*p,label,8)
# Irrigation connects to the river; it crosses the bank path through a culvert.
line([[13.6,95],[24,95],[24,88],[45,88]],'#4b9fae',1.6,3)
line([[24,92],[25,92]],'#4b9fae',1.3,3);line([[24,95],[34,95]],'#4b9fae',1.3,3)
rect([13.5,94,1.2,2],'#438c9c',edgecolor='#276574',zorder=7)
text(16,98,'취수·통수로',7,ha='left')
# A grid unit's screen size is kept fixed within this figure.
fig.canvas.draw();unit=ax.get_window_extent().width/100*72/fig.dpi
for road in D['roads']:
 color={'stone':'#c3c5c4','dirt':'#d4bea0','wood':'#bd9b72'}[road['kind']]
 line(road['points'],color,road['width']*unit,4)
rect([16.1,94.5,1.8,1],'#d0c5ad',edgecolor='#458d9f',lw=.8,zorder=7)
# Walls have drawn gate openings rather than arbitrary breaks.
def walls(plot):
 x,y,w,h=plot['rect'];color='#647479' if plot['kind']=='city' else '#8a8174';width=3.4 if plot['kind']=='city' else 1.3
 for side,start,end in [('S',x,x+w),('N',x,x+w),('W',y,y+h),('E',y,y+h)]:
  intervals=sorted((g['at']-g['width']/2,g['at']+g['width']/2) for g in plot['gates'] if g['side']==side)
  segments=[];cursor=start
  for a,b in intervals:segments.append((cursor,a));cursor=b
  segments.append((cursor,end))
  for a,b in segments:
   pts=[[a,y if side=='S' else y+h],[b,y if side=='S' else y+h]] if side in ['S','N'] else [[x if side=='W' else x+w,a],[x if side=='W' else x+w,b]]
   line(pts,color,width,8)
  for a,b in intervals:
   for v in [a,b]:
    px,py=(v,y if side=='S' else y+h) if side in ['S','N'] else (x if side=='W' else x+w,v)
    rect([px-.35,py-.35,.7,.7],color,zorder=9)
for plot in D['plots']:walls(plot)
for b in D['buildings']:
 rect(b['rect'],COLORS[b['kind']],edgecolor='#555b54',linewidth=.85,zorder=6)
 x,y,w,h=b['rect'];label=b['name']
 if b['kind']=='warehouse':label=label.replace('곡물창고','곡물\n창고')
 text(x+w/2,y+h/2,label,8)
 dx,dy=b['door'];vx,vy={'N':(0,1),'S':(0,-1),'E':(1,0),'W':(-1,0)}[b['facing']]
 rect([dx-(.2 if vx else .75),dy-(.75 if vx else .2),.4 if vx else 1.5,1.5 if vx else .4],'white',edgecolor='#444',lw=.6,zorder=9)
 ax.annotate('',xy=(dx+vx*1.9,dy+vy*1.9),xytext=(dx,dy),arrowprops=dict(arrowstyle='->',color='#444',lw=.8),zorder=10)
# Well, district labels and geographical destinations.
rect([76.5,28,1.2,1.2],'#70b3b7',edgecolor='#3a7377',zorder=7)
text(73,28.8,'공동우물',7)
for p,s in [((8,68),'상강\n흐름 ↑'),((17,40),'나루'),((35,71.5),'창고 구역'),((66,64.2),''),((65,50.7),'상점가'),((35,43),'공방거리'),((85,41.4),'주거골목'),((50,59),'남북 대로'),((72,46),'동서 운송로'),((53,4),'남문·남쪽 육로'),((56,99),'북문·농촌'),((96,64),'동문\n북동 육로')]:
 if s:text(*p,s,9,rotation=90 if s=='남북 대로' else 0,ha='left' if s in ['북문·농촌','남문·남쪽 육로'] else 'center')
# Main cargo flow: dock -> city gate -> warehouse yard, never through private housing.
ax.annotate('',xy=(35,55),xytext=(35,46),arrowprops=dict(arrowstyle='->',lw=1.4,color='#a86530'),zorder=10)
ax.annotate('',xy=(35,46),xytext=(18,46),arrowprops=dict(arrowstyle='->',lw=1.4,color='#a86530'),zorder=10)
for n in D['npcs']:
 x,y=n['position'];ax.scatter([x],[y],s=27,c='#212b30',edgecolors='white',linewidths=.8,zorder=15)
 text(x+.65,y+.65,n['id'][1:],7,ha='left',color='#202a2f',bbox=dict(fc='white',ec='none',alpha=.75,pad=.4))
ax.set_xticks(np.arange(0,101,10));ax.set_yticks(np.arange(0,101,10));ax.set_xticks(np.arange(0,101),minor=True);ax.set_yticks(np.arange(0,101),minor=True)
ax.grid(which='minor',color='#47534f',alpha=.12,lw=.3);ax.grid(which='major',color='#47534f',alpha=.35,lw=.65);ax.set_axisbelow(False)
ax.tick_params(which='minor',length=0);ax.tick_params(labelsize=8);ax.set_xlabel('검토 좌표 X → 동쪽',fontproperties=FONT,fontsize=10);ax.set_ylabel('검토 좌표 Y → 북쪽',fontproperties=FONT,fontsize=10)
fig.text(.08,.965,'장사 · 간이 배치도 v1',fontproperties=FONT,fontsize=22,weight='bold')
fig.text(.08,.935,'100×100 계획격자(성 안·밖 포함)  |  배치 검토용 · 실제 타일/축척 미확정',fontproperties=FONT,fontsize=11)
legend=fig.add_axes([.81,.09,.18,.81]);legend.axis('off')
def lt(y,s,size=10):legend.text(0,y,s,fontproperties=FONT,fontsize=size,va='top',transform=legend.transAxes)
lt(.99,'시설 색상',13)
for i,(kind,label) in enumerate([('market','상점'),('office','관아'),('martial','무관'),('workshop','공방'),('inn','객잔'),('house','민가·농가'),('warehouse','창고')]):
 y=.94-i*.043;legend.add_patch(Rectangle((0,y-.022),.08,.022,facecolor=COLORS[kind],edgecolor='#777',transform=legend.transAxes));legend.text(.12,y,label,fontproperties=FONT,fontsize=10,va='top',transform=legend.transAxes)
lt(.60,'기호',13);lt(.55,'검은 점 + 번호 : NPC 예정 위치\n흰 틈 + 화살표 : 건물 문·정면\n굵은 회색 선 : 성곽\n가는 갈색 선 : 용도별 담장\n회색 길 : 성 안 돌/판석\n갈색 길 : 성 밖 흙길\n주황 화살표 : 주 하역 동선',9)
lt(.345,'NPC 예정점 (이름·의뢰 미정)',11)
for i,n in enumerate(D['npcs']):lt(.307-i*.021,f'{n["id"][1:]}  {n["role"]}',9)
fig.text(.08,.025,'미술·게임 미적용 제안안  ·  검토 후 수정할 것은 색 블록·좌표뿐  ·  사용자 확인 뒤 대표 구역 제작',fontproperties=FONT,fontsize=10,color='#554f43')
fig.savefig(ROOT/'layout.png',dpi=140,facecolor=fig.get_facecolor());fig.savefig(ROOT/'layout.svg',facecolor=fig.get_facecolor());plt.close(fig)
# Cheap geometry checks: footprints, NPC occupancy, and reachability. Not an art or physics test.
x,y=np.meshgrid(np.arange(100)+.5,np.arange(100)+.5);pts=np.column_stack([x.ravel(),y.ravel()])
water=MPath(D['river']).contains_points(pts).reshape(100,100);blocked=water.copy();walk=np.zeros((100,100),bool)
for r,_,_,_ in areas:walk|=(x>=r[0])&(x<=r[0]+r[2])&(y>=r[1])&(y<=r[1]+r[3])
for road in D['roads']:
 for a,b in zip(road['points'],road['points'][1:]):
  a=np.array(a);v=np.array(b)-a;t=np.clip(((pts-a)@v)/(v@v),0,1);distance=np.linalg.norm(pts-a-t[:,None]*v,axis=1).reshape(100,100)
  walk|=distance<=road['width']/2+.08
for i,b in enumerate(D['buildings']):
 r=b['rect'];occupied=(x>r[0])&(x<r[0]+r[2])&(y>r[1])&(y<r[1]+r[3]);assert not np.any(blocked&occupied),b['id'];blocked|=occupied
 for other in D['buildings'][i+1:]:
  q=other['rect'];assert not (r[0]<q[0]+q[2] and q[0]<r[0]+r[2] and r[1]<q[1]+q[3] and q[1]<r[1]+r[3]),(b['id'],other['id'])
for plot in D['plots']:
 r=plot['rect']
 for side in ['S','N','W','E']:
  edge=(np.abs(y-(r[1] if side=='S' else r[1]+r[3]))<.6)&(x>=r[0])&(x<=r[0]+r[2]) if side in ['S','N'] else (np.abs(x-(r[0] if side=='W' else r[0]+r[2]))<.6)&(y>=r[1])&(y<=r[1]+r[3])
  for gate in plot['gates']:
   if gate['side']==side:edge&=np.abs((x if side in ['S','N'] else y)-gate['at'])>gate['width']/2
  blocked|=edge
free=walk&~blocked;seen={(23,46)};queue=deque(seen)
while queue:
 a,b=queue.popleft()
 for c,e in [(a+1,b),(a-1,b),(a,b+1),(a,b-1)]:
  if 0<=c<100 and 0<=e<100 and free[e,c] and (c,e) not in seen:seen.add((c,e));queue.append((c,e))
for b in D['buildings']:
 v={'N':(0,1),'S':(0,-1),'E':(1,0),'W':(-1,0)}[b['facing']];point=(int(b['door'][0]+v[0]),int(b['door'][1]+v[1]));assert point in seen,('unreachable door',b['id'],point)
for n in D['npcs']:
 a,b=map(int,n['position']);assert not blocked[b,a] and (a,b) in seen,('unreachable/occupied NPC',n['id'])
(ROOT/'checks.json').write_text(json.dumps(dict(building_count=len(D['buildings']),npc_points=len(D['npcs']),overlapping_footprints=0,all_door_approaches_connected=True,all_npc_points_connected=True,scope='schematic grid checks only; no engine collision, art or final scale validation'),indent=2)+'\n')
print('PLAN_OK',len(D['buildings']),'buildings,',len(D['npcs']),'NPC points')
