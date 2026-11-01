"""Cheap diagrams and existing-sprite projection study; never runs or edits the game."""
import os
os.environ.setdefault('MPLCONFIGDIR','/tmp/changsha-plan-mpl')
import json, math
from pathlib import Path
from collections import deque
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Polygon, Circle
from matplotlib.path import Path as MPath
from matplotlib.font_manager import FontProperties
ROOT=Path(__file__).resolve().parent; REPO=ROOT.parents[2]
D=json.loads((ROOT/'plan.json').read_text());MAN=json.loads((REPO/'godot/prototypes/isometric/assets/manifest.json').read_text())
FP='/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc';FONT=FontProperties(fname=FP)
COL=dict(warehouse='#d7b85e',market='#eeb075',house='#a5c19a',office='#b7a1c8',martial='#d38e8c',workshop='#b6957b',inn='#81abc7')
NORMAL=dict(E=(1,0),W=(-1,0),N=(0,-1),S=(0,1))
def project(p):u,v=np.array(p);return np.array([64*(u-v),32*(u+v)])
def unproject(p):x,y=np.array(p);return np.array([x/128+y/64,y/64-x/128])
def corners(r):x,y,w,h=r;return np.array([[x,y],[x+w,y],[x+w,y+h],[x,y+h]])
def segments(f):
 x,y,w,h=f['rect'];out=[];t=f['thickness']
 for side,lo,hi in [('N',x,x+w),('S',x,x+w),('W',y,y+h),('E',y,y+h)]:
  gaps=sorted((g['at']-g['width']/2,g['at']+g['width']/2) for g in f['gates'] if g['side']==side);cursor=lo
  for a,b in gaps+[(hi,hi)]:
   if a>cursor:
    out.append([cursor,(y if side=='N' else y+h)-t/2,a-cursor,t] if side in ['N','S'] else [(x if side=='W' else x+w)-t/2,cursor,t,a-cursor])
   cursor=b
 return out
OBST=[b['rect'] for b in D['buildings']]+[r for f in D['fences'] for r in segments(f)]
# Slot below is a real gate's two 0.25-deep posts plus a 1.20 clear opening.
GATE=dict(id='warehouse_gate',rect=[12.9,12.4,.2,1.7],colliders=[[12.9,12.4,.2,.25],[12.9,13.85,.2,.25]],art='warehouse_gate')
OBST+=GATE['colliders']
def text(ax,x,y,s,size=9,**kw):return ax.text(x,y,s,fontproperties=FONT,fontsize=size,ha=kw.pop('ha','center'),va='center',clip_on=True,**kw)
def fill(ax,r,color,**kw):ax.add_patch(Rectangle(r[:2],r[2],r[3],facecolor=color,**kw))
def sprite_info(b):
 r=b['rect'];info=MAN['buildings'][b['art']];scale=64*(r[2]+r[3])/info.get('ground_width',info['region'][2]);origin=project([r[0]+r[2],r[1]+r[3]])-np.array(info['pivot'])*scale
 if info.get('post_pixels'):
  a,bp=np.array(info['post_pixels']);ta,tb=[project([r[0]+r[2]/2,r[1]+.125]),project([r[0]+r[2]/2,r[1]+r[3]-.125])]
  scale=np.linalg.norm(ta-tb)/np.linalg.norm(a-bp);origin=(ta+tb)/2-(a+bp)/2*scale
 return info,scale,origin

def base(ax,detail=False):
 ax.set_aspect('equal');ax.set_facecolor('#e9e5d8');fill(ax,[9,7,35,28],'#f1f0e9',zorder=0)
 ax.add_patch(Polygon(D['river'],fc='#9cc9db',ec='#6599ac',zorder=1))
 for p in D['paddies']:ax.add_patch(Polygon(p,fc='#aed1b4',ec='#749a7b',zorder=2))
 for p in D['dry_fields']:ax.add_patch(Polygon(p,fc='#d5cc94',ec='#a69c62',zorder=2))
 for z in D['zones']:
  c={'work':'#e4d2b6','public':'#e3dce8','common':'#e8e5cd'}.get(z['kind'],'#e8e5cd');fill(ax,z['rect'],c,alpha=.65,zorder=2)
 fig=ax.figure;fig.canvas.draw();unit=ax.get_window_extent().width/(ax.get_xlim()[1]-ax.get_xlim()[0])*72/fig.dpi
 for r in D['roads']:
  p=np.array(r['points']);ax.plot(p[:,0],p[:,1],c={'stone':'#c4c7c6','wood':'#bd9e75','dirt':'#cdb594'}[r['kind']],lw=r['width']*unit,solid_capstyle='butt',solid_joinstyle='miter',zorder=3)
 for f in D['fences']:
  for r in segments(f):fill(ax,r,'#67777d' if f['id']=='city' else '#827768',zorder=6)
  x,y,w,h=f['rect']
  for g in f['gates']:
   for t in [g['at']-g['width']/2,g['at']+g['width']/2]:
    px,py=(t,y if g['side']=='N' else y+h) if g['side'] in ['N','S'] else (x if g['side']=='W' else x+w,t)
    fill(ax,[px-.13,py-.13,.26,.26],'#645647',zorder=7)
 for b in D['buildings']:
  fill(ax,b['rect'],COL[b['kind']],ec='#555d57',lw=.7,zorder=5);x,y,w,h=b['rect']
  text(ax,x+w/2,y+h/2,b['id']+('\n'+b['name'] if detail else ''),8 if detail else 7,zorder=8)
  p=np.array(b['door']);n=np.array(NORMAL[b['facing']]);perp=np.array([-n[1],n[0]])*.28
  ax.plot([p[0]-perp[0],p[0]+perp[0]],[p[1]-perp[1],p[1]+perp[1]],c='white',lw=2.7,zorder=8)
  ax.annotate('',p+n*.75,p,arrowprops=dict(arrowstyle='->',lw=.8,color='#424b48'),zorder=8)
 for n in D['npcs']:
  p=n['position'];ax.scatter(*p,s=22,c='#27343a',ec='white',lw=.7,zorder=10);text(ax,p[0]+.35,p[1]-.35,n['id'][1:],7,ha='left',zorder=10)
 ax.set_xticks(np.arange(0,49,5));ax.set_yticks(np.arange(0,41,5));ax.set_xticks(np.arange(0,49),minor=True);ax.set_yticks(np.arange(0,41),minor=True)
 ax.grid(which='minor',alpha=.2,lw=.4,c='#7f8880');ax.grid(which='major',alpha=.4,lw=.7,c='#7f8880');ax.set_axisbelow(False);ax.tick_params(which='minor',length=0);ax.tick_params(labelsize=8)
 ax.set_xlabel('논리 좌표 u → 동쪽(계획상)',fontproperties=FONT);ax.set_ylabel('논리 좌표 v → 남쪽(계획상)',fontproperties=FONT)

# Overview: no schematic stretching; one minor square is exactly one logical tile.
fig=plt.figure(figsize=(14,11),dpi=140,facecolor='#fbfaf7');ax=fig.add_axes([.055,.10,.73,.80]);ax.set_xlim(0,48);ax.set_ylim(40,0);base(ax)
water=np.array(D['irrigation']);ax.plot(water[:,0],water[:,1],c='#4d9da9',lw=2,zorder=5);fill(ax,[6.4,2.7,1.2,.6],'#bbb098',ec='#478997',zorder=7)
text(ax,2.2,26,'상강\n북쪽으로 흐름 ↑',9);text(ax,16.7,3,'논',10);text(ax,31,3,'밭',10);text(ax,7.1,22.5,'나루',9)
for x,y,t in [(16,19,'창고·하역'),(32.5,21.8,'상점가'),(32,8,'무관'),(39.5,8,'관아'),(14,22.5,'공방거리'),(21.5,31,'객잔'),(35,29,'주거골목'),(21.2,23.5,'장날 대기'),(25,37.4,'남문 / 남쪽 육로'),(45.5,22.5,'동문\n북동 육로')]:text(ax,x,y,t,8,zorder=11)
# Cargo route, actor sample, and representative crop.
p=np.array([[7,20],[11.5,20],[11.5,13.25],[15.25,13.25]])
ax.plot(p[:,0],p[:,1],c='#b36b37',lw=1.4,zorder=8);ax.annotate('',p[-1],p[-2],arrowprops=dict(arrowstyle='->',color='#b36b37'),zorder=8)
fill(ax,D['detail_bounds'],'none',ec='#aa5170',lw=1.5,ls='--',zorder=12);text(ax,19,21.7,'확대 구역',8,color='#93405c',zorder=12)
fig.text(.065,.957,'장사 · 논리 타일 배치도 v2',fontproperties=FONT,fontsize=21)
fig.text(.065,.922,'48×40칸 · 1칸 = 기존 논리 타일 1개 · 성 안팎 포함 · 미술/게임 미적용',fontproperties=FONT,fontsize=11)
leg=fig.add_axes([.81,.105,.18,.79]);leg.axis('off')
def lt(y,t,size=10):leg.text(0,y,t,fontproperties=FONT,fontsize=size,va='top')
lt(.99,'시설 / 건물 20동',12)
for i,(k,t) in enumerate([('market','상점 4'),('office','관아 1'),('martial','무관 1'),('workshop','공방 2'),('inn','객잔 1'),('house','민가·농가 8'),('warehouse','창고·나루 관리 3')]):
 y=.94-i*.042;leg.add_patch(Rectangle((0,y-.022),.08,.022,fc=COL[k],ec='#777'));leg.text(.12,y,t,fontproperties=FONT,fontsize=10,va='top')
lt(.62,'기호',12);lt(.57,'검은 점·번호 : NPC 예정점\n흰 선·화살표 : 문·정면\n굵은 선 : 성곽 / 가는 선 : 담장\n회색 : 성 안 돌 포장\n갈색 : 성 밖 흙길 / 목재 나루\n주황선 : 물자 운반 경로\n분홍 점선 : 대표 구역 확대',9)
lt(.365,'NPC 12곳 (예정 역할)',11)
for i,n in enumerate(D['npcs']):lt(.325-i*.023,f'{n["id"][1:]}  {n["role"]}',9)
fig.text(.065,.035,'바닥 점유는 기존 시험 축척 기준. 관아·무관·객잔 등 새 그림 필요 시설의 높이/가림은 미확정.',fontproperties=FONT,fontsize=10)
fig.savefig(ROOT/'overview.png');plt.close(fig)

# Detailed logical plan: safe corridors and projected art envelopes, not new assets.
fig=plt.figure(figsize=(15,10),dpi=140,facecolor='#fbfaf7');ax=fig.add_axes([.06,.12,.69,.75]);x,y,w,h=D['detail_bounds'];ax.set_xlim(x,x+w);ax.set_ylim(y+h,y);base(ax,True);ax.set_xlim(x,x+w);ax.set_ylim(y+h,y)
for b in D['buildings']:
 if b['art'] and b['id'] in ['H1','W1','W2']:
  info,s,o=sprite_info(b);rw,rh=np.array(info['region'][2:])*s;poly=np.array([unproject(o+t) for t in [[0,0],[rw,0],[rw,rh],[0,rh]]]);ax.add_patch(Polygon(poly,fc='#c28aa4',ec='#a36680',alpha=.11,hatch='///',ls='--',zorder=4))
# Exact post footprints at the 1.2 tile opening.
for r in GATE['colliders']:fill(ax,r,'#634a86',ec='white',lw=.5,zorder=12)
text(ax,12.45,13.25,'대문\n유효 폭 1.20',9,ha='right',color='#634a86',zorder=12)
for n in D['npcs']:
 if n['route']:
  p=np.array(n['route']);ax.plot(p[:,0],p[:,1],ls='--',lw=1.4,c='#477fa0',zorder=8)
# Human collision radius is to scale. Visible body height belongs to isometric panel.
for c in D['representative_cases']:
 p=c['position'];ax.add_patch(Circle(p,.15,fc='#1d77bd',ec='white',lw=.6,zorder=13));text(ax,p[0],p[1]-.48,{'front':'A','rear':'B','side':'C','gate':'D'}[c['id']],9,color='#165f94',zorder=13)
# B label is explicitly fixed rather than taking the initial of rear.
# Camera extent is a ground-plane projection only; real roofs project above it.
center=project([21.5,14]);delta=np.array([[ -1280/1.7,-720/1.7],[1280/1.7,-720/1.7],[1280/1.7,720/1.7],[-1280/1.7,720/1.7]])
cam=np.array([unproject(center+p) for p in delta]);ax.add_patch(Polygon(cam,fill=False,ec='#3b94a4',lw=1.3,ls=':',zorder=11))
# Dimension annotations on straight clear stretches.
ax.annotate('',(10.9,18.5),(12.1,18.5),arrowprops=dict(arrowstyle='<->',color='#3f6b69'));text(ax,11.5,19,'골목 1.20',8,color='#3f6b69')
ax.annotate('',(23.7,21),(26.3,21),arrowprops=dict(arrowstyle='<->',color='#3f6b69'));text(ax,25,21.6,'대로 2.60',8,color='#3f6b69')
fig.text(.06,.955,'대표 구역 확대 · 바닥 점유와 이동',fontproperties=FONT,fontsize=20)
fig.text(.06,.914,'같은 논리 좌표 · 인물 반경 0.15칸 · 그림 범위와 충돌 범위를 분리',fontproperties=FONT,fontsize=11)
fig.text(.78,.85,'도면 읽기',fontproperties=FONT,fontsize=13)
fig.text(.78,.80,'실선 색 블록 : 건물 충돌 바닥\n분홍 사선 : 기존 그림의 화면 점유\n               범위를 지면에 역투영\n               (지붕·벽·투명 여백 포함)\n파란 원 : 도원 발밑 반경 0.15\n파란 점선 : 짐꾼 왕복 예정 경로\n보라 블록 : 대문 기둥 충돌\n청록 점선 : 1280×720 / 85%의\n               지면상 화면 범위',fontproperties=FONT,fontsize=10,linespacing=1.5,va='top')
fig.text(.78,.44,'통행 폭 검토',fontproperties=FONT,fontsize=13)
fig.text(.78,.39,'대로 2.60 / 일반 골목 1.20\n뒤 골목 0.90 / 대문 1.20\n인물 충돌 지름 0.30\n\n폭은 그림 너비와 다르다.\n문 안·밖에는 대기 공간을 둔다.\n짐꾼은 길목에 상시 정지시키지 않는다.\n사람·수레 동시 통행 AI는 미검증.',fontproperties=FONT,fontsize=10,linespacing=1.5,va='top')
fig.text(.06,.035,'가림은 오른쪽 아래 방향의 높이 투영까지 고려해야 한다. 분홍 범위는 충돌 영역이 아니며 정밀 지붕 마스크도 아니다.',fontproperties=FONT,fontsize=10)
fig.savefig(ROOT/'detail.png');plt.close(fig)

# Grid geometry checks at .10 logical tile, actor clearance included conservatively.
STEP=.1;W,H=D['size'];gx,gy=np.meshgrid(np.arange(STEP/2,W,STEP),np.arange(STEP/2,H,STEP));pts=np.c_[gx.ravel(),gy.ravel()]
water=MPath(D['river']).contains_points(pts).reshape(gx.shape);blocked=water.copy();walk=np.zeros(gx.shape,bool);rad=D['actor_radius']
for r in OBST:
 x,y,w,h=r;blocked|=(gx>x-rad)&(gx<x+w+rad)&(gy>y-rad)&(gy<y+h+rad)
for z in D['zones']:
 x,y,w,h=z['rect'];walk|=(gx>=x+rad)&(gx<=x+w-rad)&(gy>=y+rad)&(gy<=y+h-rad)
for r in D['roads']:
 for a,b in zip(r['points'],r['points'][1:]):
  a=np.array(a);v=np.array(b)-a
  if not v@v:continue
  t=np.clip((pts-a)@v/(v@v),0,1);dist=np.linalg.norm(pts-a-t[:,None]*v,axis=1).reshape(gx.shape);walk|=dist<=r['width']/2-rad
free=walk&~blocked
def cell(p):return tuple((np.array(p)/STEP).astype(int))
start=cell([25,34]);seen={start};q=deque([start])
while q:
 x,y=q.popleft()
 for a,b in [(x+1,y),(x-1,y),(x,y+1),(x,y-1)]:
  if 0<=a<free.shape[1] and 0<=b<free.shape[0] and free[b,a] and (a,b) not in seen:seen.add((a,b));q.append((a,b))
errors=[]
for i,b in enumerate(D['buildings']):
 r=b['rect']
 for c in D['buildings'][i+1:]:
  s=c['rect']
  if r[0]<s[0]+s[2] and s[0]<r[0]+r[2] and r[1]<s[1]+s[3] and s[1]<r[1]+r[3]:errors.append('building overlap '+b['id']+'/'+c['id'])
 if cell(b['approach']) not in seen:errors.append('door disconnected '+b['id'])
for n in D['npcs']:
 if cell(n['position']) not in seen:errors.append('NPC disconnected '+n['id'])
 for a,b in zip(n['route'],n['route'][1:]):
  for p in np.linspace(a,b,math.ceil(np.linalg.norm(np.array(b)-a)/STEP)+1):
   if cell(p) not in seen:errors.append('route disconnected '+n['id']+' '+str(np.round(p,2)));break
for c in D['representative_cases']:
 if cell(c['position']) not in seen:errors.append('case disconnected '+c['id'])
result=dict(size=D['size'],grid_step=STEP,actor_radius=rad,buildings=len(D['buildings']),npc_points=len(D['npcs']),errors=errors,scope='proposed geometry only, not Godot physics or playtest')
(ROOT/'checks.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False));

# Four static views, same projection/scale/anchor rules as the existing prototype.
# This is a planning composite, not a Godot screenshot or a physics/animation test.
ZOOM=.85;VIEW=np.array([1280,720]);CENTER=project([18,14.5]);frames=[];observations=[]
def screen(p):return (np.array(p)-CENTER)*ZOOM+VIEW/2
def put_text(image,p,t,size=19,color='#24343d',bg=None):
 draw=ImageDraw.Draw(image);font=ImageFont.truetype(FP,size);bounds=draw.textbbox(p,t,font=font)
 if bg:draw.rectangle((bounds[0]-6,bounds[1]-3,bounds[2]+6,bounds[3]+3),fill=bg)
 draw.text(p,t,font=font,fill=color)
def shape(image,poly,color,outline=None):ImageDraw.Draw(image).polygon([tuple(screen(p)) for p in poly],fill=color,outline=outline)
def prop_layer(b):
 info,s,o=sprite_info(b);src=Image.open(REPO/'godot'/info['texture'].removeprefix('res://')).convert('RGBA');x,y,w,h=info['region'];src=src.crop((x,y,x+w,y+h));s*=ZOOM
 img=src.resize((max(1,round(w*s)),max(1,round(h*s))),Image.Resampling.LANCZOS);p=screen(o);layer=Image.new('RGBA',tuple(VIEW));layer.paste(img,tuple(np.round(p).astype(int)),None)
 return layer

def actor_layer(p,hero=True):
 data=MAN['hero' if hero else 'npc'];info=data['front'];src=Image.open(REPO/'godot'/info['texture'].removeprefix('res://')).convert('RGBA');x,y,w,h=info['region'];src=src.crop((x,y,x+w,y+h));scale=96/data.get('canvas_height',h)*ZOOM
 img=src.resize((round(w*scale),round(h*scale)),Image.Resampling.NEAREST);pos=screen(project(p))-np.array([img.width/2,img.height]);layer=Image.new('RGBA',tuple(VIEW));layer.paste(img,tuple(np.round(pos).astype(int)));return layer

def before(a,b):
 r,s=a['rect'],b['rect'];ab=r[0]+r[2]<=s[0] or r[1]+r[3]<=s[1];ba=s[0]+s[2]<=r[0] or s[1]+s[3]<=r[1];return ab and not ba

def order_nodes(nodes):
 edges={n['id']:[] for n in nodes};degree={n['id']:0 for n in nodes};lookup={n['id']:n for n in nodes}
 for i,a in enumerate(nodes):
  for b in nodes[i+1:]:
   aa,bb=a,b
   # Matches the existing special case: actor within gate footprint draws behind upper gate art.
   actor=a if a.get('person') else b if b.get('person') else None;gate=b if actor is a else a
   inside=False
   if actor and gate['id']=='warehouse_gate':
    x,y,w,h=gate['rect'];p=actor['position'];inside=x<=p[0]<=x+w and y<=p[1]<=y+h
   if inside:aa,bb=actor,gate
   elif before(b,a):aa,bb=b,a
   elif not before(a,b):continue
   edges[aa['id']].append(bb['id']);degree[bb['id']]+=1
 out=[];remaining=set(lookup)
 while remaining:
  ready=[lookup[k] for k in remaining if degree[k]==0]
  if not ready:raise AssertionError('projection study depth cycle')
  n=min(ready,key=lambda n:(sum(n['rect'][:2])+sum(n['rect'][2:])/2,n['id']));out.append(n);remaining.remove(n['id'])
  for k in edges[n['id']]:degree[k]-=1
 return out

for case in D['representative_cases']:
 image=Image.new('RGBA',tuple(VIEW),'#eeece1');draw=ImageDraw.Draw(image)
 # Draw all local ground diamonds at true tile dimensions, no perspective stretching.
 for u in range(8,29):
  for v in range(8,24):
   shape(image,[project(p) for p in corners([u,v,1,1])],'#eeece1','#d0d0c3')
 for r in D['roads']:
  for a,b in zip(r['points'],r['points'][1:]):
   a,b=np.array(a),np.array(b);v=b-a
   if not np.linalg.norm(v):continue
   normal=np.array([-v[1],v[0]])/np.linalg.norm(v)*r['width']/2
   shape(image,[project(p) for p in [a+normal,b+normal,b-normal,a-normal]],'#ced0cb')
 # Ground obstacles and boundaries stay flat here, so the study does not invent wall art.
 for b in D['buildings']:
  if b['id'] in ['W1','W2','H1']:shape(image,[project(p) for p in corners(b['rect'])],'#ddcbac','#7a7b68')
 for f in D['fences']:
  if f['id']=='warehouse_yard':
   for r in segments(f):shape(image,[project(p) for p in corners(r)],'#9c8f78','#645a4c')
 nodes=[dict(b) for b in D['buildings'] if b['id'] in ['W1','W2','H1']]+[GATE]
 p=case['position'];nodes.append(dict(id='hero',rect=[p[0]-.15,p[1]-.15,.3,.3],position=p,person=True))
 for idx,pos in [('npc6',[11.5,18.4]),('npc11',[23,15.0])]:nodes.append(dict(id=idx,rect=[pos[0]-.15,pos[1]-.15,.3,.3],position=pos,person=True))
 ordered=order_nodes(nodes);layers={};passed=False;front_alpha=np.zeros((720,1280),np.uint8)
 for n in ordered:
  layer=actor_layer(n['position'],n['id']=='hero') if n.get('person') else prop_layer(n);layers[n['id']]=layer
  if passed:front_alpha=np.maximum(front_alpha,np.array(layer.getchannel('A')))
  if n['id']=='hero':passed=True
  image=Image.alpha_composite(image,layer)
 for pos,label in [([11.5,18.4],'06 짐꾼'),([23,15.0],'11 주민')]:
  foot=screen(project(pos));put_text(image,(foot[0]-30,foot[1]+10),label,17,'#56674c',bg='#ffffffdc')
 hero_alpha=np.array(layers['hero'].getchannel('A'));hero_pixels=hero_alpha>51;covered=hero_pixels&(front_alpha>51);ratio=float(covered.sum()/max(1,hero_pixels.sum()))
 # Foot locator/name is an always-visible HUD, not a change to character Z order.
 foot=screen(project(p));draw=ImageDraw.Draw(image);x,y=foot;draw.ellipse((x-19,y-8,x+19,y+8),outline='#147dbc',width=2)
 put_text(image,(x-25,y+12),'도원',18,'#145e9b',bg='#ffffffdc')
 if ratio>.05:
  tip=(int(x-52),int(y-114));draw.line([tuple(foot),(tip[0]+30,tip[1]+25)],fill='#147dbc',width=2);put_text(image,tip,'도원 · 가림',19,'#145e9b',bg='#ffffffdc')
 # Overlay collision outlines for the gate; never obscure the art with a filled collision.
 if case['id']=='gate':
  for r in GATE['colliders']:
   ps=[tuple(screen(project(p))) for p in corners(r)];ImageDraw.Draw(image).line(ps+[ps[0]],fill='#8b459f',width=3)
 put_text(image,(24,18),case['label'],25,bg='#fffffff0')
 put_text(image,(24,57),f'1280×720 · 배율 85% · 인물 높이 기준 96 · 가려진 인물 픽셀 {ratio:.0%}',18,bg='#fffffff0')
 put_text(image,(24,675),'기존 에셋·코드 축척의 정적 투영 검토 / 실제 게임 캡처 아님',18,bg='#fffffff0')
 image.convert('RGB').save(ROOT/('view-'+case['id']+'.png'))
 frames.append(image.convert('RGB'));observations.append(dict(case=case['id'],position=p,covered_actor_alpha_fraction=round(ratio,4),depth_order=[n['id'] for n in ordered]))
board=Image.new('RGB',(2560,1440),'white')
for i,im in enumerate(frames):board.paste(im,((i%2)*1280,(i//2)*720))
board.save(ROOT/'occlusion.png')
(ROOT/'projection-checks.json').write_text(json.dumps(dict(note='existing texture alpha overlap and prototype depth rules in offline planning composite; not engine screenshots',cases=observations),ensure_ascii=False,indent=2)+'\n')
print('PROJECTION_OK',[(o['case'],o['covered_actor_alpha_fraction']) for o in observations])
assert not errors,errors
