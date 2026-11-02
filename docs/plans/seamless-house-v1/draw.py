"""Specification diagrams, not game code. Uses proposed JSON and existing scale references."""
import os
os.environ.setdefault('MPLCONFIGDIR','/tmp/seamless-house-mpl')
import json, math
from pathlib import Path
from collections import deque
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Circle, Polygon
from matplotlib.font_manager import FontProperties
ROOT=Path(__file__).resolve().parent;REPO=ROOT.parents[2]
S=json.loads((ROOT/'spec.json').read_text());A,B=S['candidates'];P=S['proposed']
FONT=FontProperties(fname='/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc')
COL=dict(bed='#99aecb',table='#caa47e',chair='#cfb998',chest='#ae8b76',urn='#b4a9ba')
def tx(ax,x,y,t,size=10,**kw):return ax.text(x,y,t,fontproperties=FONT,fontsize=size,ha=kw.pop('ha','center'),va=kw.pop('va','center'),clip_on=True,**kw)
def ft(fig,x,y,t,size=11,**kw):return fig.text(x,y,t,fontproperties=FONT,fontsize=size,va='top',**kw)
def box(ax,r,c,**kw):return ax.add_patch(Rectangle(r[:2],r[2],r[3],facecolor=c,**kw))
def pts(r):x,y,w,h=r;return np.array([[x,y],[x+w,y],[x+w,y+h],[x,y+h]])
def proj(p,z=0):u,v=np.asarray(p).T;return np.stack([64*(u-v),32*(u+v)-z],axis=-1)
def arrow(ax,a,b,c='#4b7779',style='<->'):ax.annotate('',b,a,arrowprops=dict(arrowstyle=style,color=c,lw=1.2),annotation_clip=True)
def grid(ax,xlim,ylim,minor=.25):
 ax.set_aspect('equal');ax.set_facecolor('#f8f6ee');ax.set_xticks(np.arange(math.floor(xlim[0]),math.ceil(xlim[1])+1,1));ax.set_yticks(np.arange(math.floor(ylim[0]),math.ceil(ylim[1])+1,1));ax.set_xticks(np.arange(math.floor(xlim[0]),math.ceil(xlim[1])+minor,minor),minor=True);ax.set_yticks(np.arange(math.floor(ylim[0]),math.ceil(ylim[1])+minor,minor),minor=True);ax.grid(which='major',alpha=.32,lw=.6);ax.grid(which='minor',alpha=.13,lw=.3);ax.tick_params(which='minor',length=0);ax.tick_params(labelsize=8);ax.set_xlim(*xlim);ax.set_ylim(ylim[1],ylim[0]);ax.set_axisbelow(True)
def floor(ax,c,detail=False):
 w,h=c['size'];box(ax,[0,0,w,h],'#efeadf',ec='#45505b',lw=1)
 box(ax,c['interior'],'#fffdf3')
 box(ax,c['main_corridor'],'#c2e1df',alpha=.65)
 box(ax,c['inner_arrival'],'#c4e8ba',ec='#6c9b5a',lw=.6);box(ax,c['outer_apron'],'#d9e9c8',ec='#7b9d64',lw=.6)
 if detail:
  for k in ['bed_access','table_access','chair_pullback']:
   box(ax,c[k],'#f0ddb6',ec='#b59254',alpha=.6,ls='--',lw=.8)
  box(ax,c['npc_wait'],'#e0d1ed',ec='#8a659c',lw=.7)
 for r in c['walls']:box(ax,r,'#697476',zorder=5)
 for f in c['furniture']:
  if detail:
   r=f['rect'];box(ax,[r[0]-.15,r[1]-.15,r[2]+.3,r[3]+.3],'none',ec='#b36c6b',ls=':',lw=.8,zorder=4)
  box(ax,f['rect'],COL[f['id']],ec='#695c52',lw=.9,zorder=6);x,y,fw,fh=f['rect'];tx(ax,x+fw/2,y+fh/2,f['label'],9,zorder=7)
 for p,color,label in [(c['hero'],'#2874a0','도원'),(c['npc'],'#8e5caa','NPC')]:
  ax.add_patch(Circle(p,.15,fc=color,ec='white',lw=.8,zorder=8));tx(ax,p[0],p[1]-.3,label,9,color=color,zorder=8)
 for route in c['routes']:
  p=np.array(route);ax.plot(p[:,0],p[:,1],c='#337c84',lw=1.2,ls='--',zorder=3)
 arrow(ax,[w+.9,c['door_center'][1]],[w-.5,c['door_center'][1]],style='->')
 tx(ax,w+.7,c['door_center'][1]-.82,'걸어서 출입',9)
 arrow(ax,[w+.22,c['door'][1]],[w+.22,c['door'][1]+1.2]);tx(ax,w+.48,c['door_center'][1],'1.20',8)
 if detail:
  for k,p in c['approaches'].items():
   ax.scatter(*p,s=15,c='#ad7b39',zorder=7)
  for x,color,label in [(c['enter_plane'],'#2e8b85','진입 확정'),(c['exit_plane'],'#bb7652','퇴장 확정')]:
   ax.plot([x,x],[c['door'][1]-.15,c['door'][1]+1.35],c=color,lw=1.1,ls='--',zorder=8);tx(ax,x,c['door'][1]+1.52,label,8,color=color)

# 1. Candidates at exactly the same axis range, unit size and furniture dimensions.
fig,axs=plt.subplots(1,2,figsize=(13,8.4),dpi=140,facecolor='#fbfaf7');fig.subplots_adjust(left=.06,right=.96,bottom=.19,top=.86,wspace=.20)
for ax,c in zip(axs,S['candidates']):
 grid(ax,(-.4,6.5),(-.4,6.7));floor(ax,c)
 ax.set_title(f"{c['id']} · {c['size'][0]}×{c['size'][1]}칸"+(' — 추천' if c['recommended'] else ' — 소형 하한 후보'),fontproperties=FONT,fontsize=14,pad=12)
 tx(ax,c['size'][0]/2,-.25,f"실내 {c['interior'][2]:.1f}×{c['interior'][3]:.1f}",10)
 ax.set_xlabel('논리 타일 u',fontproperties=FONT)
ft(fig,.06,.97,'심리스 민가 후보 · 같은 축척 / 같은 가구',20)
ft(fig,.06,.15,'공통: 벽 0.20 · 문 유효 폭 1.20 · 침상 1.20×2.20 · 탁자 1.40×0.60 · 의자 0.55×0.55',10)
ft(fig,.06,.105,'A: 면적을 절약하지만 NPC가 대기하면 주요 통로 일부를 공유한다.\nB: 대기 자리를 주 통로와 분리하고 가구 접근·회전 여유를 확보한다. 새 미술/게임 미적용 설계안.',11)
fig.savefig(ROOT/'candidates.png');plt.close(fig)

# 2. Recommended interior: collision, use-space and input-independent thresholds.
fig=plt.figure(figsize=(13,9.5),dpi=140,facecolor='#fbfaf7');ax=fig.add_axes([.065,.13,.58,.74]);grid(ax,(-.4,6.5),(-.4,6.7));floor(ax,B,True)
ft(fig,.06,.965,'추천 B · 5×6 민가의 실내·출입 규격',20)
ft(fig,.69,.85,'물리와 사용 공간',13)
ft(fig,.69,.80,'회색 : 벽·문기둥 충돌\n가구 색 : 실제 가구 점유\n붉은 점선 : 인물 반경 0.15 확장\n청록 : 주요 통로 폭 1.20\n연녹색 : 실내 도착 / 외부 앞자리\n황색 : 가구 사용·의자 후퇴 공간\n보라 : NPC 대기 자리\n갈색 점 : 가구 접근 표본',10,linespacing=1.6)
ft(fig,.69,.47,'표시 전환 제안',13)
ft(fig,.69,.42,'외벽 오른쪽 u=5.00 기준\n진입 확정면 u=4.60\n퇴장 확정면 u=5.30\n\n유효 문 통과 이력으로 판정.\n문턱 완충 구간에서는 이전 표시 유지.\n벽 뒤 접근만으로 실내 전환 금지.\n시각 페이드 중에도 이동은 연속.\n\n충돌·정렬·표시 판정은 별도 데이터.\n실제 게임 동작은 아직 미검증.',10,linespacing=1.6)
ft(fig,.06,.075,'1칸 = 기존 논리 타일 · 도원/NPC 반경 0.15 유지 · 도면 접근 검사만 수행 · 본게임과 시험 씬 변경 없음',10)
fig.savefig(ROOT/'recommended-detail.png');plt.close(fig)

# 3. Schematics use the actual projection; vertical heights are NEW proposals.
fig=plt.figure(figsize=(15,10),dpi=140,facecolor='#fbfaf7');gs=fig.add_gridspec(2,2,height_ratios=[1,.65],left=.04,right=.97,bottom=.08,top=.89,hspace=.18,wspace=.10)
MAN=json.loads((REPO/'godot/prototypes/isometric/assets/manifest.json').read_text())
from PIL import Image
z=.85;center=proj([2.5,3])-np.array([0,72])
def sp(p,height=0):return (proj(p,height)-center)*z+np.array([640,360])
def poly(ax,pp,c,ec='#66685b',alpha=1,zorder=3):ax.add_patch(Polygon(np.array(pp),fc=c,ec=ec,lw=.7,alpha=alpha,zorder=zorder))
def area3(ax,r,height,c,zorder=3):poly(ax,[sp(p,height) for p in pts(r)],c,zorder=zorder)
def wall3(ax,a,b,height,c,base=0):poly(ax,[sp(a,base),sp(b,base),sp(b,height),sp(a,height)],c)
def human(ax,p,kind):
 info=MAN[kind]['front'];src=Image.open(REPO/'godot'/info['texture'].removeprefix('res://'));x,y,w,h=info['region'];im=src.crop((x,y,x+w,y+h));scale=96/MAN[kind].get('canvas_height',h)*z;foot=sp(p);ax.imshow(im,extent=[foot[0]-w*scale/2,foot[0]+w*scale/2,foot[1],foot[1]-h*scale],zorder=10)
for ax,inside in [(fig.add_subplot(gs[0,0]),False),(fig.add_subplot(gs[0,1]),True)]:
 ax.set_xlim(0,1280);ax.set_ylim(720,0);ax.set_aspect('equal');ax.set_facecolor('#f1f1e8');ax.tick_params(left=False,bottom=False,labelleft=False,labelbottom=False)
 area3(ax,[0,0,5,6],0,'#b8b2a4',.5);area3(ax,B['interior'],0,'#eee3ce',.6)
 for u in range(1,5):ax.plot(*np.array([sp([u,0]),sp([u,6])]).T,c='#c6baa5',lw=.5)
 for v in range(1,6):ax.plot(*np.array([sp([0,v]),sp([5,v])]).T,c='#c6baa5',lw=.5)
 wall3(ax,[0,0],[5,0],144,'#d9d6cc');wall3(ax,[0,0],[0,6],144,'#c2c0b4')
 for f in (B['furniture'] if inside else []):
  r=f['rect'];c=COL[f['id']];p=pts(r);wall3(ax,p[1],p[2],f['height'],c);wall3(ax,p[2],p[3],f['height'],c);area3(ax,r,f['height'],c)
 if inside:human(ax,B['hero'],'hero');human(ax,B['npc'],'npc')
 # Camera-near walls are lowered only visually. Door collision does not change.
 near=24 if inside else 144
 wall3(ax,[0,6],[5,6],near,'#999f99')
 wall3(ax,[5,0],[5,4.05],near,'#b0b4a9');wall3(ax,[5,5.25],[5,6],near,'#b0b4a9')
 if not inside:
  wall3(ax,[5,4.05],[5,5.25],144,'#b0b4a9',112)
  # Two roof slopes. Overhang .3 is on ground coordinates; rise 72 is screen vertical.
  poly(ax,[sp([-.3,-.3],144),sp([2.5,-.3],216),sp([2.5,6.3],216),sp([-.3,6.3],144)],'#718a8b',zorder=20)
  poly(ax,[sp([2.5,-.3],216),sp([5.3,-.3],144),sp([5.3,6.3],144),sp([2.5,6.3],216)],'#536d73',zorder=20)
  # Door clear width and height are shown without inventing a painted facade.
  ps=np.array([sp([5,4.05]),sp([5,5.25]),sp([5,5.25],112),sp([5,4.05],112),sp([5,4.05])]);ax.plot(ps[:,0],ps[:,1],c='#f6d68f',lw=1.3,zorder=12)
 tx(ax,640,38,'실내 진입 후: 지붕 숨김·앞벽 24 높이 표시' if inside else '실외: 지붕·외벽 표시',13)
 tx(ax,640,686,'투영 128×64 · 기본 배율 85% · 높이 수치는 새 제안 / 실제 게임 캡처 아님',9)
ax=fig.add_subplot(gs[1,0]);grid(ax,(-.5,5.8),(-.5,6.4),.5);box(ax,[0,0,5,6],'#d3dfcf',ec='#688469');box(ax,[0,0,2,3],'none',ec='#a46a53',lw=2,ls='--');tx(ax,3.4,3,'추천 B 5×6',12);tx(ax,1,1.5,'기존\n2×3',10);ax.set_title('같은 논리 축척의 바닥 면적 비교',fontproperties=FONT,fontsize=11)
ax=fig.add_subplot(gs[1,1]);ax.axis('off');tx(ax,.05,.88,'바닥 5×6 / 실내 4.6×5.6\n처마: 외벽에서 각 방향 0.30칸\n처마 높이 144 / 용마루 높이 216\n문 유효 높이 112 / 인물 캔버스 높이 96\n\n높이는 화면 수직 단위이며 논리 지면 타일이 아님.\n기존 민가 그림을 확대해서 사용하는 제안이 아님.\n단순 도형으로 표시한 분리 구조이며 최종 미술이 아님.',11,ha='left',va='top',linespacing=1.6)
ft(fig,.04,.97,'외벽·실내·지붕 분리와 축척 비교',20);ft(fig,.04,.035,'지붕을 숨겨도 벽/가구 충돌은 유지한다. 실외의 긴 가림은 허용하며 필요 시 기존 위치 표시를 사용한다.',10)
fig.savefig(ROOT/'cutaway-and-scale.png');plt.close(fig)

# 4. Existing Changsha plan: only one small block, no whole-map redesign.
D=json.loads((REPO/'docs/plans/changsha-v2/plan.json').read_text());site=S['recommended_site']
fig,axs=plt.subplots(1,2,figsize=(14,8.2),dpi=140,facecolor='#fbfaf7');fig.subplots_adjust(left=.06,right=.96,bottom=.20,top=.86,wspace=.18)
def road2(ax,points,width,color):
 for a,b in zip(points,points[1:]):
  a,b=np.array(a),np.array(b);v=b-a
  if np.linalg.norm(v)==0:continue
  n=np.array([-v[1],v[0]])/np.linalg.norm(v)*width/2
  ax.add_patch(Polygon([a+n,b+n,b-n,a-n],fc=color,ec='none',zorder=1))
 for p in points[1:-1]:ax.add_patch(Circle(p,width/2,fc=color,ec='none',zorder=1))
for ax,after in zip(axs,[False,True]):
 grid(ax,(17.5,29),(9,23),.5)
 for road in D['roads']:
  if road['id'] in ['spine','house_front','house_rear','door_H1']:continue
  road2(ax,road['points'],road['width'],'#c3c8c4')
 # Replace the spine by an actual logical polygon, not an apparent line width.
 main=site['new_main'] if after else site['original_main']
 road2(ax,main,2.6,'#bcc5c7')
 for b in D['buildings']:
  if b['id']=='H1':continue
  box(ax,b['rect'],'#dccfae' if b['id'].startswith('W') else '#d7d7cd',ec='#8a8b7a',lw=.7,zorder=3)
  x,y,w,h=b['rect'];tx(ax,x+w/2,y+h/2,b['id'],8,zorder=4)
 # Existing warehouse yard boundary, purpose unchanged.

 for edge in [[13,10.4,5.5,.2],[18.4,10.5,.2,8.3],[13,18.7,5.5,.2]]:box(ax,edge,'#8b7b65',zorder=4)
 if after:
  r=site['new_rect'];box(ax,r,'#bcd3b0',ec='#4f774e',lw=1.2,zorder=4);tx(ax,22.1,14,'H1 추천 B\n5×6',11,zorder=6)
  # Interior schematic shares exactly the proposed local-to-world translation.
  for f in B['furniture']:
   q=f['rect'];box(ax,[q[0]+r[0],q[1]+r[1],q[2],q[3]],COL[f['id']],ec='#8a7a64',lw=.5,zorder=5)
  box(ax,site['new_apron'],'#d8e8c4',ec='#67956b',lw=.7,zorder=6)
  p=site['new_npc'];ax.add_patch(Circle(p,.15,fc='#895b9c',zorder=7));tx(ax,p[0],p[1]-.45,'N11 실내',8,zorder=7)
  road2(ax,site['rear_lane'],.9,'#9eb7b4')
  arrow(ax,[18.6,17.2],[19.6,17.2]);tx(ax,19.1,17.75,'외벽 간 1.0',8,zorder=8)
  tx(ax,27.2,17.2,'대로 폭 2.6 유지\n중앙선 국소 우회',9,zorder=7)
  box(ax,site['original_rect'],'none',ec='#a66f61',ls='--',lw=1,zorder=8)
 else:
  box(ax,site['original_rect'],'#b8cdaa',ec='#668862',lw=1,zorder=4);tx(ax,21,13.5,'H1\n2×3',10,zorder=5)
  # Naive larger house with unchanged origin intersects the old main road.
  box(ax,[20,12,5,6],'#ce8f89',ec='#b15c55',alpha=.25,hatch='//',zorder=5);tx(ax,23.7,17,'단순 확대 시\n대로 침범',9,zorder=6,color='#a5403b')
 ax.set_title('추천안 대입 시 국소 조정 제안' if after else '기존 배치와 단순 확대의 충돌',fontproperties=FONT,fontsize=13)
ft(fig,.06,.96,'장사 48×40 제안 · H1 주변만 영향 검토',20)
ft(fig,.06,.15,'H1: (20,12,2,3) → (19.6,12,5,6) / 기존 문 앞길은 제거·재연결 / 뒤 골목 연장 / N11은 실내 대기',10)
ft(fig,.06,.105,'대표 구역만의 대안이다. 전체 도로/다른 민가/NPC를 일괄 변경하지 않았다.\n새 지붕 외형과 실내·실외 가림은 향후 실제 에셋/플레이에서 확인해야 한다.',11)
fig.savefig(ROOT/'changsha-local-impact.png');plt.close(fig)

# Small diagram-only checks, not a runtime test framework.
checks=[]
for c in S['candidates']:
 w,h=c['size'];furn=c['furniture'];obs=c['walls']+[f['rect'] for f in furn]+[[c['npc'][0]-.15,c['npc'][1]-.15,.3,.3]]
 for i,a in enumerate(furn):
  r=a['rect'];assert r[0]>=.2 and r[1]>=.2 and r[0]+r[2]<=w-.2 and r[1]+r[3]<=h-.2
  for b in furn[i+1:]:
   q=b['rect'];assert not(r[0]<q[0]+q[2] and q[0]<r[0]+r[2] and r[1]<q[1]+q[3] and q[1]<r[1]+r[3])
 step=.05;origin=np.array([-.5,-.5]);xx,yy=np.meshgrid(np.arange(-.475,w+1.5,step),np.arange(-.475,h+.5,step));free=np.ones(xx.shape,bool)
 for r in obs:free&=~((xx>r[0]-.15)&(xx<r[0]+r[2]+.15)&(yy>r[1]-.15)&(yy<r[1]+r[3]+.15))
 def cell(p):return tuple(((np.array(p)-origin)/step).astype(int))
 start=cell([w+.65,c['door_center'][1]]);seen={start};queue=deque([start])
 while queue:
  x,y=queue.popleft()
  for a,b in [(x+1,y),(x-1,y),(x,y+1),(x,y-1)]:
   if 0<=a<free.shape[1] and 0<=b<free.shape[0] and free[b,a] and (a,b) not in seen:seen.add((a,b));queue.append((a,b))
 targets={**c['approaches'],'hero_dialogue':c['hero'],'arrival':[w-.75,c['door_center'][1]]}
 errors=[k for k,p in targets.items() if cell(p) not in seen]
 checks.append(dict(candidate=c['id'],footprint_area=w*h,interior_area=round((w-.4)*(h-.4),2),errors=errors,reachable_approaches=list(targets),scope='0.05 logical-tile diagram check only; no engine execution'))
assert [f['rect'][2:] for f in A['furniture']]==[f['rect'][2:] for f in B['furniture']]
(ROOT/'diagram-checks.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(checks,ensure_ascii=False));assert not any(c['errors'] for c in checks)
